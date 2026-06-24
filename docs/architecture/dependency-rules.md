
# Dependency Rules

## Core rules

* Apps may depend on packages.
* Services may depend on packages.
* Packages should expose public APIs through `src/index.ts`.
* Projects must not import from another project's private internals.
* Architecture boundaries are checked with dependency-cruiser.

## Verification

```bash
bun run arch
bun run catalog:check
```

