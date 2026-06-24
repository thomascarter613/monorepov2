import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join, relative } from "node:path";

type ProjectKind = "app" | "service" | "package";

type ProjectConfig = {
  kind: ProjectKind;
  name: string;
  directory: string;
  packageName: string;
  layer: "application" | "library";
  stack: string;
};

const VALID_KINDS = new Set(["app", "service", "package"]);

function usage(): never {
  console.error(`
Usage:
  bun run create app <name> [stack]
  bun run create service <name> [stack]
  bun run create package <name> [stack]

Examples:
  bun run create app admin frontend
  bun run create service worker backend
  bun run create package observability backend
`);
  process.exit(1);
}

function normalizeName(input: string): string {
  const normalized = input
    .trim()
    .replace(/([a-z0-9])([A-Z])/g, "$1-$2")
    .replace(/[^a-zA-Z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .toLowerCase();

  if (!normalized) {
    throw new Error("Project name cannot be empty.");
  }

  return normalized;
}

function getProjectConfig(): ProjectConfig {
  const [, , rawKind, rawName, rawStack] = process.argv;

  if (!rawKind || !rawName) {
    usage();
  }

  if (!VALID_KINDS.has(rawKind)) {
    usage();
  }

  const kind = rawKind as ProjectKind;
  const name = normalizeName(rawName);
  const stack =
    rawStack ?? (kind === "app" ? "frontend" : kind === "service" ? "backend" : "unknown");

  const baseDirectory = kind === "app" ? "apps" : kind === "service" ? "services" : "packages";

  return {
    kind,
    name,
    directory: join(baseDirectory, name),
    packageName: `@repo/${name}`,
    layer: kind === "package" ? "library" : "application",
    stack,
  };
}

async function exists(path: string): Promise<boolean> {
  try {
    await readFile(path);
    return true;
  } catch {
    return false;
  }
}

async function write(path: string, content: string): Promise<void> {
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, content);
}

async function readJson<T>(path: string): Promise<T> {
  return JSON.parse(await readFile(path, "utf8")) as T;
}

async function writeJson(path: string, value: unknown): Promise<void> {
  await writeFile(path, `${JSON.stringify(value, null, 2)}\n`);
}

async function updateRootTsconfig(projectDirectory: string): Promise<void> {
  const path = "tsconfig.json";
  const root = await readJson<{
    files?: string[];
    references?: Array<{ path: string }>;
  }>(path);

  root.files ??= [];
  root.references ??= [];

  const referencePath = `./${projectDirectory}`;

  const hasReference = root.references.some((reference) => reference.path === referencePath);

  if (!hasReference) {
    root.references.push({ path: referencePath });
    root.references.sort((a, b) => a.path.localeCompare(b.path));
  }

  await writeJson(path, root);
}

async function updateRootPackageJson(): Promise<void> {
  const path = "package.json";
  const root = await readJson<{
    scripts?: Record<string, string>;
  }>(path);

  root.scripts ??= {};
  root.scripts.create = "bun run tooling/create-project/src/index.ts";
  root.scripts = Object.fromEntries(
    Object.entries(root.scripts).sort(([a], [b]) => a.localeCompare(b)),
  );

  await writeJson(path, root);
}

function packageJson(config: ProjectConfig): string {
  return `${JSON.stringify(
    {
      name: config.packageName,
      private: true,
      type: "module",
      main: "./src/index.ts",
      exports: {
        ".": "./src/index.ts",
      },
      scripts: {
        build: "tsc -b --pretty false",
        lint: "biome check .",
        test: "vitest run --passWithNoTests",
        typecheck: "tsc -b --pretty false",
      },
      dependencies: {},
      devDependencies: {},
    },
    null,
    2,
  )}\n`;
}

function tsconfigJson(): string {
  return `${JSON.stringify(
    {
      extends: "../../tsconfig.base.json",
      compilerOptions: {
        composite: true,
        declaration: true,
        declarationMap: true,
        outDir: "dist",
        rootDir: "src",
        tsBuildInfoFile: "dist/tsconfig.tsbuildinfo",
      },
      include: ["src"],
    },
    null,
    2,
  )}\n`;
}

function moonYml(config: ProjectConfig): string {
  return `layer: '${config.layer}'
stack: '${config.stack}'

project:
  title: '${config.packageName}'
  description: '${config.packageName} project'
  owner: 'platform'
  maintainers:
    - '@thomas.carter'

tags:
  - '${config.stack}'
`;
}

function indexTs(config: ProjectConfig): string {
  const exportName = config.name.replace(/-([a-z])/g, (_, char: string) => char.toUpperCase());

  return `export const ${exportName}Project = {
  name: "${config.packageName}",
  kind: "${config.kind}",
  stack: "${config.stack}"
} as const;
`;
}

function indexTestTs(config: ProjectConfig): string {
  const exportName = config.name.replace(/-([a-z])/g, (_, char: string) => char.toUpperCase());

  return `import { expect, test } from "vitest";
import { ${exportName}Project } from "./index";

test("${config.packageName} exposes project metadata", () => {
  expect(${exportName}Project.name).toBe("${config.packageName}");
  expect(${exportName}Project.kind).toBe("${config.kind}");
});
`;
}

function readmeMd(config: ProjectConfig): string {
  return `# ${config.packageName}

## Purpose

Describe what this ${config.kind} owns.

## Commands

\`\`\`bash
moon run ${config.directory.replace("/", "-")}:typecheck
moon run ${config.directory.replace("/", "-")}:test
moon run ${config.directory.replace("/", "-")}:build
\`\`\`

## Ownership

Owner: platform
`;
}

function agentsMd(config: ProjectConfig): string {
  return `# Agent Instructions: ${config.packageName}

## Scope

This file applies to \`${config.directory}\`.

## Allowed changes

- \`src/**\`
- \`package.json\`
- \`tsconfig.json\`
- \`moon.yml\`
- \`README.md\`
- \`catalog-info.yaml\`

## Required checks

\`\`\`bash
moon run ${config.directory.replace("/", "-")}:typecheck
moon run ${config.directory.replace("/", "-")}:test
moon run ${config.directory.replace("/", "-")}:build
bun run arch
\`\`\`

## Architecture rules

- Do not import from apps unless this project is itself an app-level integration.
- Prefer dependencies through public package exports.
- Do not reach into another package's private source files.
`;
}

function catalogInfoYml(config: ProjectConfig): string {
  const backstageType =
    config.kind === "app" ? "website" : config.kind === "service" ? "service" : "library";

  return `apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: ${config.name}
  description: ${config.packageName}
  annotations:
    backstage.io/techdocs-ref: dir:.
spec:
  type: ${backstageType}
  lifecycle: experimental
  owner: platform
  system: monorepo-platform
`;
}

async function main(): Promise<void> {
  const config = getProjectConfig();

  if (await exists(join(config.directory, "package.json"))) {
    throw new Error(`Project already exists: ${config.directory}`);
  }

  await write(join(config.directory, "package.json"), packageJson(config));
  await write(join(config.directory, "tsconfig.json"), tsconfigJson());
  await write(join(config.directory, "moon.yml"), moonYml(config));
  await write(join(config.directory, "src/index.ts"), indexTs(config));
  await write(join(config.directory, "src/index.test.ts"), indexTestTs(config));
  await write(join(config.directory, "README.md"), readmeMd(config));
  await write(join(config.directory, "AGENTS.md"), agentsMd(config));
  await write(join(config.directory, "catalog-info.yaml"), catalogInfoYml(config));

  await updateRootPackageJson();
  await updateRootTsconfig(config.directory);

  console.log(`Created ${config.kind}: ${config.packageName}`);
  console.log(`Path: ${relative(process.cwd(), config.directory)}`);
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
