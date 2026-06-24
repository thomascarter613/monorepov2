# Agent Instructions: @repo/api

## Scope

This file applies to `services/api`.

## Allowed changes

* `src/**`
* `package.json`
* `tsconfig.json`
* `moon.yml`
* `README.md`
* `catalog-info.yaml`

## Required checks

```bash
moon run services-api:typecheck
moon run services-api:test
moon run services-api:build
bun run arch
bun run catalog:check
```

## Architecture rules

* Import other projects only through public package exports.
* Do not reach into another package's private source files.
* Keep package dependencies reflected in both `package.json` and `tsconfig.json` references when needed.
  