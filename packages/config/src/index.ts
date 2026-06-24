export const runtimeConfig = {
  environment: process.env.NODE_ENV ?? "development",
} as const;
