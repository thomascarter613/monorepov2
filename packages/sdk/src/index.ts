import { runtimeConfig } from "@repo/config";
import type { ServiceHealth } from "@repo/types";

export function createHealthResult(service: string): ServiceHealth {
  return {
    ok: true,
    service: `${service}:${runtimeConfig.environment}`,
  };
}
