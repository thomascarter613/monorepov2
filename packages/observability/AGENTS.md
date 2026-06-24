# Agent Instructions: @repo/observability

## Scope

This file applies to `packages/observability`.

## Allowed changes

- `src/**`
- `package.json`
- `tsconfig.json`
- `moon.yml`
- `README.md`
- `catalog-info.yaml`

## Required checks

```bash
moon run packages-observability:typecheck
moon run packages-observability:test
moon run packages-observability:build
bun run arch
```

## Architecture rules

- Do not import from apps unless this project is itself an app-level integration.
- Prefer dependencies through public package exports.
- Do not reach into another package's private source files.
