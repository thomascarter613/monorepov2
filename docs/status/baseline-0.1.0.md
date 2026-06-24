# Baseline 0.1.0

## Status

Known-good monorepo baseline.

## Passing gates

- Bun workspace install/runtime
- Biome check
- Syncpack dependency/manifest check
- Knip dead-code check
- dependency-cruiser architecture boundary check
- Moon task graph
- TypeScript project references
- Vitest task execution

## Architecture doctrine

This repository is Bun-native and Moon-governed.

Bun owns:

- workspaces
- dependency installation
- lockfile
- runtime
- script execution

Moon owns:

- project graph
- task graph
- task inheritance
- affected execution
- repo orchestration

## Next layer

CI hardening, repository governance, security scanning, and real service scaffolding.
