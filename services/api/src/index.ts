import { name as configName } from "@repo/config";

export function health() {
  return {
    ok: true,
    service: "@repo/api",
    configPackage: configName,
  };
}
