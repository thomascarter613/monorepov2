module.exports = {
  forbidden: [
    {
      name: "no-circular",
      severity: "error",
      comment: "Circular imports make large monorepos difficult to reason about.",
      from: {},
      to: {
        circular: true,
      },
    },
    {
      name: "no-app-to-app",
      severity: "error",
      comment: "Applications must not import from other applications.",
      from: {
        path: "^apps/[^/]+/src",
      },
      to: {
        path: "^apps/[^/]+/src",
      },
    },
    {
      name: "no-service-to-app",
      severity: "error",
      comment: "Services must not depend on UI applications.",
      from: {
        path: "^services/[^/]+/src",
      },
      to: {
        path: "^apps/",
      },
    },
    {
      name: "no-infra-to-runtime-code",
      severity: "error",
      comment: "Infrastructure code should not import application runtime code.",
      from: {
        path: "^infra/",
      },
      to: {
        path: "^(apps|services|packages)/",
      },
    },
  ],
  options: {
    doNotFollow: {
      path: "node_modules",
    },
    exclude: {
      path: "node_modules|dist|build|coverage",
    },
    tsPreCompilationDeps: true,
    tsConfig: {
      fileName: "tsconfig.base.json",
    },
  },
};
