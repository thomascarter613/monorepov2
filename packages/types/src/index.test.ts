import { expect, test } from "vitest";
import type { ServiceHealth } from "./index";

test("ServiceHealth shape accepts healthy service status", () => {
  const health: ServiceHealth = {
    ok: true,
    service: "test",
  };

  expect(health.ok).toBe(true);
  expect(health.service).toBe("test");
});
