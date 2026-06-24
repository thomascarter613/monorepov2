
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
