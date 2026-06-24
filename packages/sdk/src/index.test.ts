import { expect, test } from "vitest";
import { createHealthResult } from "./index";

test("createHealthResult returns healthy service status", () => {
  const result = createHealthResult("sdk");

  expect(result.ok).toBe(true);
  expect(result.service).toContain("sdk");
});
