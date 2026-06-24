# Project Catalog

Every project under `apps/*`, `services/*`, and `packages/*` must include:

- `package.json`
- `tsconfig.json`
- `moon.yml`
- `README.md`
- `AGENTS.md`
- `catalog-info.yaml`
- `src/index.ts`

The catalog gate is enforced by:

```bash
bun run catalog:check
```

