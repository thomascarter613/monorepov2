# Agent Instructions: @repo/web

## Scope

This file applies to `apps/web`.

## Allowed changes

* `src/**`
* `package.json`
* `tsconfig.json`
* `moon.yml`
* `README.md`
* `catalog-info.yaml`

## Required checks

```bash
moon run apps-web:typecheck
moon run apps-web:test
moon run apps-web:build
bun run arch
bun run catalog:check
```

## Architecture rules

* Import other projects only through public package exports.
* Do not reach into another package's private source files.
* Keep package dependencies reflected in both `package.json` and `tsconfig.json` references when needed.
  