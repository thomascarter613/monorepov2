import { existsSync } from "node:fs";
import { readdir, readFile } from "node:fs/promises";
import { join } from "node:path";

type Project = {
  root: "apps" | "services" | "packages";
  name: string;
  path: string;
};

const PROJECT_ROOTS = ["apps", "services", "packages"] as const;

const REQUIRED_FILES = [
  "package.json",
  "tsconfig.json",
  "moon.yml",
  "README.md",
  "AGENTS.md",
  "catalog-info.yaml",
  "src/index.ts",
];

async function listProjects(): Promise<Project[]> {
  const projects: Project[] = [];

  for (const root of PROJECT_ROOTS) {
    if (!existsSync(root)) {
      continue;
    }

    const entries = await readdir(root, { withFileTypes: true });

    for (const entry of entries) {
      if (!entry.isDirectory()) {
        continue;
      }

      const path = join(root, entry.name);

      if (!existsSync(join(path, "package.json"))) {
        continue;
      }

      projects.push({
        root,
        name: entry.name,
        path,
      });
    }
  }

  return projects;
}

async function readJson<T>(path: string): Promise<T> {
  return JSON.parse(await readFile(path, "utf8")) as T;
}

async function checkProject(project: Project): Promise<string[]> {
  const errors: string[] = [];

  for (const file of REQUIRED_FILES) {
    const fullPath = join(project.path, file);

    if (!existsSync(fullPath)) {
      errors.push(`${project.path}: missing ${file}`);
    }
  }

  const packageJsonPath = join(project.path, "package.json");

  if (existsSync(packageJsonPath)) {
    const packageJson = await readJson<{
      name?: string;
      scripts?: Record<string, string>;
    }>(packageJsonPath);

    if (!packageJson.name?.startsWith("@repo/")) {
      errors.push(`${project.path}: package name must start with @repo/`);
    }

    for (const script of ["build", "test", "typecheck"]) {
      if (!packageJson.scripts?.[script]) {
        errors.push(`${project.path}: missing package.json script "${script}"`);
      }
    }
  }

  const moonPath = join(project.path, "moon.yml");

  if (existsSync(moonPath)) {
    const moon = await readFile(moonPath, "utf8");

    for (const required of ["layer:", "stack:", "owner:", "maintainers:"]) {
      if (!moon.includes(required)) {
        errors.push(`${project.path}: moon.yml missing ${required}`);
      }
    }
  }

  const catalogPath = join(project.path, "catalog-info.yaml");

  if (existsSync(catalogPath)) {
    const catalog = await readFile(catalogPath, "utf8");

    for (const required of [
      "apiVersion: backstage.io/",
      "kind: Component",
      "metadata:",
      "spec:",
      "owner: platform",
      "system: monorepo-platform",
    ]) {
      if (!catalog.includes(required)) {
        errors.push(`${project.path}: catalog-info.yaml missing ${required}`);
      }
    }
  }

  return errors;
}

async function main(): Promise<void> {
  const projects = await listProjects();

  if (projects.length === 0) {
    throw new Error("No projects found.");
  }

  const errors = (await Promise.all(projects.map((project) => checkProject(project)))).flat();

  if (errors.length > 0) {
    console.error("Catalog check failed:");
    for (const error of errors) {
      console.error(`- ${error}`);
    }
    process.exit(1);
  }

  console.log(`Catalog check passed for ${projects.length} projects.`);
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
