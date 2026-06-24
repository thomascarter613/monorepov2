import { expect, test } from "vitest";
import { runtimeConfig } from "./index";

test("runtimeConfig exposes an environment", () => {
  expect(runtimeConfig.environment).toBeTypeOf("string");
});
