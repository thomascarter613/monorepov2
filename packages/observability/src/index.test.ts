import { expect, test } from "vitest";
import { observabilityProject } from "./index";

test("@repo/observability exposes project metadata", () => {
  expect(observabilityProject.name).toBe("@repo/observability");
  expect(observabilityProject.kind).toBe("package");
});
