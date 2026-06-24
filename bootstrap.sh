#!/usr/bin/env bash
set -euo pipefail

mkdir -p \
  .github/workflows \
  .moon/tasks \
  .changeset \
  apps/web/src \
  services/api/src \
  packages/ui/src \
  packages/types/src \
  packages/config/src \
  packages/sdk/src \
  packages/testing/src \
  infra/docker \
  infra/helm/api/templates \
  infra/helm/web/templates \
  infra/argocd \
  infra/external-secrets \
  infra/observability \
  docs/adr \
  docs/architecture \
  docs/runbooks \
  scripts \
  tooling/policies

cat > package.json <<'JSON'
{
  "name": "enterprise-bun-mono",
  "private": true,
  "type": "module",
  "packageManager": "bun@latest",
  "workspaces": [
    "apps/*",
    "services/*",
    "packages/*",
    "tooling/*"
  ],
  "scripts": {
    "dev": "moon run :dev",
    "build": "moon run :build",
    "test": "moon run :test",
    "typecheck": "moon run :typecheck",
    "lint": "moon run :lint",
    "format": "moon run :format",
    "check": "bunx biome check .",
    "check:write": "bunx biome check --write .",
    "deps:check": "bunx syncpack list-mismatches",
    "deps:fix": "bunx syncpack fix-mismatches",
    "deadcode": "bunx knip",
    "arch": "bunx depcruise . --config .dependency-cruiser.cjs",
    "security:secrets": "gitleaks detect --source . --verbose",
    "security:fs": "trivy fs .",
    "sbom": "syft . -o cyclonedx-json=sbom.cdx.json",
    "verify": "bun run check && bun run deps:check && bun run deadcode && bun run arch && moon run :typecheck :test :build"
  },
  "devDependencies": {
    "@biomejs/biome": "latest",
    "@changesets/cli": "latest",
    "@commitlint/cli": "latest",
    "@commitlint/config-conventional": "latest",
    "@moonrepo/cli": "latest",
    "@playwright/test": "latest",
    "@types/bun": "latest",
    "dependency-cruiser": "latest",
    "knip": "latest",
    "lefthook": "latest",
    "syncpack": "latest",
    "typescript": "latest",
    "vitest": "latest"
  }
}
JSON

cat > .gitignore <<'EOF_GIT'
node_modules
dist
build
coverage
.moon/cache
.env
.env.*
!.env.example
.DS_Store
sbom.cdx.json
playwright-report
test-results
EOF_GIT

cat > .editorconfig <<'EOF_EDITOR'
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 2
insert_final_newline = true
trim_trailing_whitespace = true
EOF_EDITOR

cat > .mise.toml <<'EOF_MISE'
[tools]
bun = "latest"
node = "lts"

[tasks.install]
description = "Install workspace dependencies"
run = "bun install"

[tasks.verify]
description = "Run the full local verification gate"
run = "bun run verify"

[tasks.dev]
description = "Run all dev tasks through moon"
run = "bun run dev"
EOF_MISE

cat > biome.json <<'JSON'
{
  "$schema": "https://biomejs.dev/schemas/latest/schema.json",
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  },
  "files": {
    "ignoreUnknown": false,
    "includes": [
      "**",
      "!node_modules",
      "!dist",
      "!build",
      "!coverage",
      "!.moon/cache"
    ]
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true
    }
  },
  "organizeImports": {
    "enabled": true
  }
}
JSON

cat > tsconfig.base.json <<'JSON'
{
  "compilerOptions": {
    "target": "ES2023",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "lib": ["ES2023", "DOM"],
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "isolatedModules": true,
    "verbatimModuleSyntax": true,
    "skipLibCheck": true,
    "types": ["bun-types"],
    "baseUrl": ".",
    "paths": {
      "@repo/ui": ["packages/ui/src/index.ts"],
      "@repo/types": ["packages/types/src/index.ts"],
      "@repo/config": ["packages/config/src/index.ts"],
      "@repo/sdk": ["packages/sdk/src/index.ts"],
      "@repo/testing": ["packages/testing/src/index.ts"]
    }
  }
}
JSON

cat > tsconfig.json <<'JSON'
{
  "files": [],
  "references": [
    { "path": "./apps/web" },
    { "path": "./services/api" },
    { "path": "./packages/ui" },
    { "path": "./packages/types" },
    { "path": "./packages/config" },
    { "path": "./packages/sdk" },
    { "path": "./packages/testing" }
  ]
}
JSON

cat > .moon/toolchains.yml <<'YAML'
javascript:
  packageManager: 'bun'

bun: {}
YAML

cat > .moon/workspace.yml <<'YAML'
projects:
  globFormat: 'source-path'
  globs:
    - 'apps/*'
    - 'services/*'
    - 'packages/*'
    - 'tooling/*'

vcs:
  provider: 'github'
  defaultBranch: 'main'

codeowners:
  sync: true
  globalPaths:
    '*': ['@thomas.carter']
    '/.github/': ['@thomas.carter']
    '/infra/': ['@thomas.carter']
    '/docs/adr/': ['@thomas.carter']

constraints:
  enforceLayerRelationships: true

pipeline:
  installDependencies: false
  cacheLifetime: '7 days'

experiments:
  asyncAffectedTracking: true
  asyncGraphBuilding: true
  nativeFileHashing: true
  casOutputsCache: true
YAML

cat > .moon/tasks/all.yml <<'YAML'
fileGroups:
  sources:
    - 'src/**/*'
    - 'package.json'
    - 'tsconfig.json'
  tests:
    - 'src/**/*.test.ts'
    - 'tests/**/*'
  configs:
    - '*.config.*'
    - 'moon.yml'

tasks:
  lint:
    command: 'bunx biome check .'
    inputs:
      - '@group(sources)'
      - '@group(configs)'

  format:
    command: 'bunx biome check --write .'
    inputs:
      - '@group(sources)'
      - '@group(configs)'

  typecheck:
    command: 'bunx tsc --noEmit'
    inputs:
      - '@group(sources)'
      - '@group(configs)'

  test:
    command: 'bunx vitest run --passWithNoTests'
    inputs:
      - '@group(sources)'
      - '@group(tests)'
    outputs:
      - 'coverage'

  build:
    command: 'bun run build'
    deps:
      - '^:build'
    inputs:
      - '@group(sources)'
      - '@group(configs)'
    outputs:
      - 'dist'
YAML

cat > .dependency-cruiser.cjs <<'JS'
module.exports = {
  forbidden: [
    {
      name: "no-circular",
      severity: "error",
      comment: "Circular imports make large monorepos difficult to reason about.",
      from: {},
      to: {
        circular: true
      }
    },
    {
      name: "no-app-to-app",
      severity: "error",
      comment: "Applications must not import from other applications.",
      from: {
        path: "^apps/[^/]+/src"
      },
      to: {
        path: "^apps/[^/]+/src"
      }
    },
    {
      name: "no-service-to-app",
      severity: "error",
      comment: "Services must not depend on UI applications.",
      from: {
        path: "^services/[^/]+/src"
      },
      to: {
        path: "^apps/"
      }
    },
    {
      name: "no-infra-to-runtime-code",
      severity: "error",
      comment: "Infrastructure code should not import application runtime code.",
      from: {
        path: "^infra/"
      },
      to: {
        path: "^(apps|services|packages)/"
      }
    }
  ],
  options: {
    doNotFollow: {
      path: "node_modules"
    },
    exclude: {
      path: "node_modules|dist|build|coverage"
    },
    tsPreCompilationDeps: true,
    tsConfig: {
      fileName: "tsconfig.base.json"
    }
  }
};
JS

cat > knip.json <<'JSON'
{
  "$schema": "https://unpkg.com/knip@latest/schema.json",
  "workspaces": {
    "apps/*": {},
    "services/*": {},
    "packages/*": {}
  },
  "ignore": [
    "dist/**",
    "build/**",
    "coverage/**",
    "infra/**"
  ]
}
JSON

cat > .syncpackrc.json <<'JSON'
{
  "source": [
    "package.json",
    "apps/*/package.json",
    "services/*/package.json",
    "packages/*/package.json",
    "tooling/*/package.json"
  ],
  "dependencyTypes": [
    "prod",
    "dev",
    "peer",
    "resolutions"
  ]
}
JSON

cat > lefthook.yml <<'YAML'
pre-commit:
  parallel: true
  commands:
    biome:
      run: bunx biome check --write {staged_files}
      stage_fixed: true
    gitleaks:
      run: gitleaks protect --staged --verbose

pre-push:
  parallel: false
  commands:
    verify:
      run: bun run verify

commit-msg:
  commands:
    commitlint:
      run: bunx commitlint --edit {1}
YAML

cat > commitlint.config.cjs <<'JS'
module.exports = {
  extends: ["@commitlint/config-conventional"]
};
JS

cat > renovate.json <<'JSON'
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:recommended"
  ],
  "labels": [
    "dependencies"
  ],
  "rangeStrategy": "bump",
  "dependencyDashboard": true,
  "packageRules": [
    {
      "matchDepTypes": ["devDependencies"],
      "groupName": "dev dependencies"
    },
    {
      "matchPackageNames": ["@biomejs/biome", "@moonrepo/cli", "typescript"],
      "groupName": "toolchain core"
    }
  ]
}
JSON

cat > .changeset/config.json <<'JSON'
{
  "$schema": "https://unpkg.com/@changesets/config@latest/schema.json",
  "changelog": "@changesets/cli/changelog",
  "commit": false,
  "fixed": [],
  "linked": [],
  "access": "restricted",
  "baseBranch": "main",
  "updateInternalDependencies": "patch",
  "ignore": []
}
JSON

cat > CODEOWNERS <<'EOF_CODEOWNERS'
* @thomas.carter
/.github/ @thomas.carter
/infra/ @thomas.carter
/docs/adr/ @thomas.carter
EOF_CODEOWNERS

cat > docs/adr/0001-bun-native-moon-governed-monorepo.md <<'MD'
# ADR-0001: Bun-native, Moon-governed monorepo

## Status

Accepted

## Context

The repository needs a fast JavaScript/TypeScript runtime, workspace package linking, task orchestration, dependency governance, and CI-friendly project graph behavior.

## Decision

Use Bun for workspaces, dependency installation, lockfile ownership, runtime execution, script execution, and package linking.

Use Moon for project graph, task graph, task inheritance, project metadata, constraints, ownership, and affected CI behavior.

## Consequences

- There is one package manager: Bun.
- There is one lockfile: bun.lock.
- Repository orchestration goes through Moon.
- All projects must have package metadata and moon metadata.
MD

cat > docs/architecture/README.md <<'MD'
# Architecture

This repository uses a Bun-native, Moon-governed monorepo architecture.

## Core layers

```mermaid
flowchart TD
  apps[apps/*] --> packages[packages/*]
  services[services/*] --> packages
  apps --> sdk[packages/sdk]
  sdk --> contracts[API contracts]
  services --> contracts
  infra[infra/*] -. deploys .-> apps
  infra -. deploys .-> services
```

## Governance

* ADRs live in `docs/adr`.
* CODEOWNERS defines review ownership.
* Moon defines project/task graph.
* dependency-cruiser enforces import boundaries.
* Knip detects unused files, dependencies, and exports.
* Syncpack detects dependency version drift.
MD

create_ts_project() {
  local dir="$1"
  local name="$2"
  local layer="$3"
  local stack="$4"
  local deps="${5:-}"

cat > "$dir/package.json" <<JSON
{
  "name": "$name",
  "private": true,
  "type": "module",
  "main": "./src/index.ts",
  "exports": {
    ".": "./src/index.ts"
  },
  "scripts": {
    "build": "tsc --noEmit",
    "test": "vitest run --passWithNoTests",
    "typecheck": "tsc --noEmit",
    "lint": "biome check ."
  },
  "dependencies": {
    $deps
  },
  "devDependencies": {}
  }
JSON

cat > "$dir/tsconfig.json" <<'JSON'
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "composite": true,
    "rootDir": "src",
    "outDir": "dist"
  },
  "include": ["src"]
}
JSON

cat > "$dir/moon.yml" <<YAML
layer: '$layer'
stack: '$stack'

project:
  title: '$name'
  description: '$name project'
  owner: 'platform'
  maintainers:
  - '@thomas.carter'

tags:
  * '$stack'
YAML

cat > "$dir/src/index.ts" <<TS
export const name = "$name";
TS
}

create_ts_project "packages/types" "@repo/types" "library" "unknown"
create_ts_project "packages/config" "@repo/config" "library" "unknown"
create_ts_project "packages/testing" "@repo/testing" "library" "unknown"
create_ts_project "packages/ui" "@repo/ui" "library" "frontend" '"@repo/types": "workspace:*"'
create_ts_project "packages/sdk" "@repo/sdk" "library" "frontend" '"@repo/types": "workspace:*", "@repo/config": "workspace:*"'
create_ts_project "apps/web" "@repo/web" "application" "frontend" '"@repo/ui": "workspace:*", "@repo/sdk": "workspace:*"'
create_ts_project "services/api" "@repo/api" "application" "backend" '"@repo/types": "workspace:*", "@repo/config": "workspace:*"'

cat > services/api/src/index.ts <<'TS'
import { name as configName } from "@repo/config";

export function health() {
  return {
    ok: true,
    service: "@repo/api",
    configPackage: configName
  };
}
TS

cat > apps/web/src/index.ts <<'TS'
import { name as uiName } from "@repo/ui";

export function render() {
  return `web using ${uiName}`;
}
TS

cat > vitest.config.ts <<'TS'
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    coverage: {
      reporter: ["text", "json", "html"]
    }
  }
});
TS

cat > playwright.config.ts <<'TS'
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./tests/e2e",
  retries: process.env.CI ? 2 : 0,
  use: {
    trace: "on-first-retry"
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] }
    }
  ]
});
TS

mkdir -p tests/e2e
cat > tests/e2e/example.spec.ts <<'TS'
import { expect, test } from "@playwright/test";

test("placeholder", async () => {
  expect(true).toBe(true);
});
TS

cat > .github/workflows/ci.yml <<'YAML'
name: ci

  on:
    pull_request:
      push:
        branches:
        - main

  permissions:
    contents: read
    security-events: write
    actions: read

jobs:
  verify:
    name: verify
    runs-on: ubuntu-latest

steps:
  - name: Checkout
    uses: actions/checkout@v4

  - name: Setup Bun
    uses: oven-sh/setup-bun@v2

  - name: Install dependencies
    run: bun install --frozen-lockfile

  - name: Biome
    run: bun run check

  - name: Dependency consistency
    run: bun run deps:check

  - name: Dead code
    run: bun run deadcode

  - name: Architecture boundaries
    run: bun run arch

  - name: Moon tasks
    run: bunx moon run :typecheck :test :build

security:
name: security
runs-on: ubuntu-latest

permissions:
  contents: read
  security-events: write

steps:
  - name: Checkout
    uses: actions/checkout@v4

  - name: Secret scan
    uses: gitleaks/gitleaks-action@v2

  - name: Filesystem vulnerability scan
    uses: aquasecurity/trivy-action@master
    with:
      scan-type: fs
      scan-ref: .
      severity: HIGH,CRITICAL
      exit-code: "1"
      ignore-unfixed: true

sbom:
name: sbom
runs-on: ubuntu-latest

permissions:
  contents: read

steps:
  - name: Checkout
    uses: actions/checkout@v4

  - name: Generate SBOM
    uses: anchore/sbom-action@v0
    with:
      path: .
      format: cyclonedx-json
      output-file: sbom.cdx.json

  - name: Upload SBOM
    uses: actions/upload-artifact@v4
    with:
      name: sbom
      path: sbom.cdx.json

YAML

cat > infra/docker/Dockerfile.bun-service <<'DOCKER'
FROM oven/bun:1 AS deps
WORKDIR /repo

COPY package.json bun.lock ./
COPY apps ./apps
COPY services ./services
COPY packages ./packages
COPY tsconfig.json tsconfig.base.json ./

RUN bun install --frozen-lockfile

FROM deps AS build
RUN bunx moon run services-api:build

FROM oven/bun:1-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production

COPY --from=deps /repo /app

USER bun
CMD ["bun", "run", "services/api/src/index.ts"]
DOCKER

cat > infra/helm/api/Chart.yaml <<'YAML'
apiVersion: v2
name: api
description: API service Helm chart
type: application
version: 0.1.0
appVersion: "0.1.0"
YAML

cat > infra/helm/api/values.yaml <<'YAML'
image:
repository: ghcr.io/OWNER/REPO/api
tag: latest
pullPolicy: IfNotPresent

replicaCount: 1

service:
port: 3000

resources:
requests:
cpu: 100m
memory: 128Mi
limits:
cpu: 500m
memory: 512Mi
YAML

cat > infra/helm/api/templates/deployment.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
name: {{ .Chart.Name }}
spec:
replicas: {{ .Values.replicaCount }}
selector:
matchLabels:
app.kubernetes.io/name: {{ .Chart.Name }}
template:
metadata:
labels:
app.kubernetes.io/name: {{ .Chart.Name }}
spec:
containers:
- name: api
image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
imagePullPolicy: {{ .Values.image.pullPolicy }}
ports:
- containerPort: {{ .Values.service.port }}
resources:
{{- toYaml .Values.resources | nindent 12 }}
YAML

cat > infra/helm/api/templates/service.yaml <<'YAML'
apiVersion: v1
kind: Service
metadata:
name: {{ .Chart.Name }}
spec:
selector:
app.kubernetes.io/name: {{ .Chart.Name }}
ports:
- port: {{ .Values.service.port }}
targetPort: {{ .Values.service.port }}
YAML

cat > infra/argocd/api-app.yaml <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
name: api
namespace: argocd
spec:
project: default
source:
repoURL: [https://github.com/OWNER/REPO.git](https://github.com/OWNER/REPO.git)
targetRevision: main
path: infra/helm/api
destination:
server: [https://kubernetes.default.svc](https://kubernetes.default.svc)
namespace: api
syncPolicy:
automated:
prune: true
selfHeal: true
syncOptions:
- CreateNamespace=true
YAML

cat > .sops.yaml <<'YAML'
creation_rules:

* path_regex: infra/secrets/.*.ya?ml$
  encrypted_regex: '^(data|stringData|password|token|secret|key)$'
  age: AGE_PUBLIC_KEY_GOES_HERE
  YAML

mkdir -p infra/secrets
cat > infra/external-secrets/example-external-secret.yaml <<'YAML'
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
name: api-secrets
spec:
refreshInterval: 1h
secretStoreRef:
name: example-secret-store
kind: SecretStore
target:
name: api-secrets
creationPolicy: Owner
data:
- secretKey: DATABASE_URL
remoteRef:
key: api/database-url
YAML

cat > infra/observability/README.md <<'MD'

# Observability

Recommended signal flow:

```mermaid
flowchart LR
  app[Apps and services] --> otel[OpenTelemetry SDK]
  otel --> collector[OpenTelemetry Collector]
  collector --> prometheus[Prometheus metrics]
  collector --> tempo[Tempo traces]
  app --> loki[Loki logs]
  prometheus --> grafana[Grafana]
  tempo --> grafana
  loki --> grafana
```

Minimum production requirements:

* RED metrics: request rate, errors, duration
* USE metrics: utilization, saturation, errors
* structured JSON logs
* trace IDs in logs
* SLO dashboard
* paging alert rules
MD

cat > README.md <<'MD'

# Enterprise Bun Monorepo

A Bun-native, Moon-governed monorepo.

## Core commands

```bash
bun install
bun run verify
bun run dev
bun run build
bun run test
```

## Architecture

* Bun owns workspaces, installs, lockfile, runtime, and scripts.
* Moon owns project graph, task graph, task inheritance, constraints, and affected CI.
* Biome owns formatting/linting.
* dependency-cruiser owns import boundaries.
* Knip owns unused files/dependencies/exports.
* Syncpack owns dependency version consistency.
* GitHub Actions owns CI.
* ArgoCD owns GitOps deployment.
MD

bun install
bunx lefthook install

echo
echo "Bootstrap complete."
echo "Next:"
echo "  bun run verify"
echo "  git add ."
echo "  git commit -m 'chore: initialize bun-native moon-governed monorepo'"
