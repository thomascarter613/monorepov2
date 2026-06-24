import { createHealthResult } from "@repo/sdk";
import { renderHealthBadge } from "@repo/ui";

export function render() {
  return renderHealthBadge(createHealthResult("web"));
}
