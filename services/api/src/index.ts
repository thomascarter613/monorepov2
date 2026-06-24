import { runtimeConfig } from "@repo/config";
import type { ServiceHealth } from "@repo/types";

export function health(): ServiceHealth {
  return {
    ok: true,
    service: `api:${runtimeConfig.environment}`,
  };
}
