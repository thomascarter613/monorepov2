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
