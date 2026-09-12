import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

let failures = 0;
const check = (label, fn) => {
  try {
    console.log(`PASS ${label}: ${fn()}`);
  } catch (error) {
    failures++;
    console.error(`FAIL ${label}: ${error.message}`);
  }
};
const run = (command, args) => {
  const result = spawnSync(command, args, {
    encoding: "utf8",
    timeout: 30_000,
  });
  if (result.status !== 0)
    throw new Error(
      (
        result.stderr ||
        result.error?.message ||
        result.stdout ||
        "command failed"
      ).trim(),
    );
  return (result.stdout || result.stderr).trim();
};
const home = process.env.HOME;
check("Node", () => process.version);
for (const [name, spec] of [
  ["chrome-devtools-mcp", "npm:chrome-devtools-mcp@1.9.0"],
  ["playwright-cli", "npm:@playwright/cli@0.1.18"],
]) {
  check(name, () =>
    run(run("mise", ["which", name, "--tool", spec]), ["--version"]),
  );
}
check("Helium", () => {
  fs.accessSync(
    "/Applications/Helium.app/Contents/MacOS/Helium",
    fs.constants.X_OK,
  );
  return "dedicated isolated profiles";
});
check(
  "Java",
  () =>
    run(path.join(process.env.JAVA_HOME, "bin/java"), ["-version"]).split(
      "\n",
    )[0],
);
check("Maestro", () => run("/opt/homebrew/bin/maestro", ["--version"]));
check("Xcode", () => run("xcode-select", ["-p"]));
check("iOS simulators", () => {
  const devices = Object.values(
    JSON.parse(
      run("xcrun", ["simctl", "list", "devices", "available", "--json"]),
    ).devices,
  ).flat();
  if (!devices.length) throw new Error("Install an iOS runtime in Xcode");
  return `${devices.length} available; ${devices.filter((device) => device.state === "Booted").length} booted (app readiness requires a live check)`;
});
check("Codex MCP registration", () => {
  const servers = JSON.parse(run("codex", ["mcp", "list", "--json"]));
  for (const [name, binary] of [
    ["chrome-devtools", "codex-helium-mcp"],
    ["maestro", "codex-maestro-mcp"],
  ]) {
    const server = servers.find((item) => item.name === name);
    if (
      !server?.enabled ||
      server.transport?.command !== path.join(home, ".local/bin", binary)
    )
      throw new Error(
        `Missing managed ${name}; apply dotfiles and restart Codex`,
      );
  }
  if (!servers.some((item) => item.name === "figma" && item.enabled))
    throw new Error(
      "Figma is not configured; add the official Figma MCP and authenticate",
    );
  return "Figma, chrome-devtools and Maestro configured; /mcp verifies live connections";
});
check("Skills", () => {
  for (const name of ["frontend-verify", "playwright-cli"])
    fs.accessSync(path.join(home, ".codex/skills", name, "SKILL.md"));
  return "frontend-verify and playwright-cli";
});
console.log(
  "Configuration checks are not visual verification. Run the app, inspect screenshots, and exercise the changed behavior.",
);
process.exitCode = failures ? 1 : 0;
