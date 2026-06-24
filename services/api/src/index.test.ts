import { expect, test } from "vitest";
import { health } from "./index";

test("health returns api status", () => {
  const result = health();

  expect(result.ok).toBe(true);
  expect(result.service).toContain("api");
});
