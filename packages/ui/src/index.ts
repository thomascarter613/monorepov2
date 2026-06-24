import type { ServiceHealth } from "@repo/types";

export function renderHealthBadge(health: ServiceHealth): string {
  return health.ok ? `${health.service}: healthy` : `${health.service}: unhealthy`;
}
