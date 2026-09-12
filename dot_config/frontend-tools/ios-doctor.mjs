import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import fs from "node:fs";
import path from "node:path";

const usage =
  "frontend-doctor ios --device <UDID> --environment <name> --port <port> [--project <path>] [--env-var <name>]";
export function parseOptions(args) {
  if (args[0] !== "ios" || args.length < 7 || args.length % 2 !== 1)
    throw new Error(usage);
  const options = {};
  for (let i = 1; i < args.length; i += 2) {
    const key = args[i].slice(2);
    if (
      !args[i].startsWith("--") ||
      !["device", "environment", "port", "project", "env-var"].includes(key) ||
      Object.hasOwn(options, key) ||
      !args[i + 1]
    )
      throw new Error(usage);
    options[key] = args[i + 1];
  }
  if (
    !/^[0-9a-f-]{36}$/i.test(options.device || "") ||
    !/^[a-z0-9_-]+$/i.test(options.environment || "") ||
    !/^[a-z_][a-z0-9_]*$/i.test(options["env-var"] || "APP_ENV") ||
    !/^\d+$/.test(options.port || "") ||
    Number(options.port) < 1 ||
    Number(options.port) > 65535
  )
    throw new Error(usage);
  return options;
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    encoding: "utf8",
    timeout: 15000,
    maxBuffer: 4 * 1024 * 1024,
    ...options,
  });
  // Config/command output can contain credentials; only report the operation.
  if (result.status !== 0) throw new Error(`${command} inspection failed`);
  return result.stdout.trim();
}

const defaults = {
  run,
  read: (name) => fs.readFileSync(name, "utf8"),
  list: (name) => fs.readdirSync(name),
  realpath: (name) => fs.realpathSync(name),
  status: async (port) => {
    const response = await fetch(`http://127.0.0.1:${port}/status`, {
      signal: AbortSignal.timeout(3000),
      redirect: "error",
    });
    if (!response.ok) throw new Error("HTTP status check failed");
    return response.text();
  },
};

export async function inspectIos(options, deps = defaults) {
  const cwd = options.cwd || process.cwd();
  const env = options.env || process.env;
  const results = [];
  const add = (status, label, detail) =>
    results.push({ status, label, detail });
  const probe = async (label, fn) => {
    try {
      await fn();
    } catch {
      add("UNKNOWN", label, "Inspection unavailable; no verification credit.");
    }
  };
  let root, app, expected;
  await probe("Checkout", () => {
    const project = deps.realpath(path.resolve(cwd, options.project || "."));
    root = deps.realpath(
      deps.run("git", ["rev-parse", "--show-toplevel"], { cwd: project }),
    );
    const manifest = JSON.parse(deps.read(path.join(project, "package.json")));
    if (!manifest.dependencies?.expo && !manifest.devDependencies?.expo) {
      throw new Error("Select an Expo project");
    }
    app = project;
    add("PASS", "Checkout", root);
  });
  if (!root || !app) return results;
  await probe("Revision", () => {
    const head = deps.run("git", ["rev-parse", "HEAD"], { cwd: root });
    const branch = deps.run("git", ["branch", "--show-current"], { cwd: root });
    const dirty = deps.run("git", ["status", "--porcelain"], { cwd: root });
    add(
      "INFO",
      "Revision",
      `${branch || "detached"} ${head}; ${dirty ? "dirty (record changed files)" : "clean"}`,
    );
  });
  const hash = (value) =>
    createHash("sha256").update(value).digest("hex").slice(0, 16);
  add(
    "INFO",
    "Artifacts",
    path.join(
      env.XDG_CACHE_HOME || path.join(env.HOME, ".cache"),
      "frontend-verification",
      hash(root),
      hash(env.FRONTEND_SESSION || env.CODEX_THREAD_ID || "manual"),
    ),
  );
  await probe("Requested Expo bundle", () => {
    const config = JSON.parse(
      deps.run(
        "yarn",
        ["exec", "expo", "config", "--json", "--type", "public"],
        {
          cwd: app,
          env: {
            ...env,
            [options["env-var"] || "APP_ENV"]: options.environment,
          },
        },
      ),
    );
    expected = config.ios?.bundleIdentifier;
    if (!expected || !/^[a-z0-9.-]+$/i.test(expected)) {
      expected = undefined;
      throw new Error("Missing bundle");
    }
    add(
      "PASS",
      "Requested Expo bundle",
      `${options.environment}: ${expected} (requested config, not running JS)`,
    );
  });
  await probe("Generated native bundle", () => {
    if (!expected) throw new Error("Unknown expected bundle");
    const projects = deps
      .list(path.join(app, "ios"))
      .filter((name) => name.endsWith(".xcodeproj"));
    if (projects.length !== 1) throw new Error("Ambiguous native project");
    const file = path.join(app, "ios", projects[0], "project.pbxproj");
    const { objects } = JSON.parse(
      deps.run("plutil", ["-convert", "json", "-o", "-", file]),
    );
    const targets = Object.values(objects).filter(
      (value) =>
        value.isa === "PBXNativeTarget" &&
        value.productType === "com.apple.product-type.application",
    );
    if (targets.length !== 1) throw new Error("Ambiguous app target");
    const configs =
      objects[targets[0].buildConfigurationList].buildConfigurations;
    const bundles = configs.map(
      (id) => objects[id].buildSettings?.PRODUCT_BUNDLE_IDENTIFIER,
    );
    if (
      !bundles.length ||
      bundles.some((id) => !id || !/^[a-z0-9.-]+$/i.test(id))
    )
      throw new Error("Unresolved build setting");
    add(
      bundles.every((id) => id === expected) ? "PASS" : "FAIL",
      "Generated native bundle",
      [...new Set(bundles)].join(", "),
    );
  });
  let booted = false;
  await probe("Simulator", () => {
    const { devices } = JSON.parse(
      deps.run("xcrun", ["simctl", "list", "devices", "available", "--json"]),
    );
    const device = Object.values(devices)
      .flat()
      .find((item) => item.udid.toLowerCase() === options.device.toLowerCase());
    booted = device?.state === "Booted";
    add(
      booted ? "PASS" : "FAIL",
      "Simulator",
      device
        ? `${device.name}: ${device.state}`
        : "Selected device not available",
    );
  });
  await probe("Installed app", () => {
    if (!booted || !expected) throw new Error("Cannot inspect app");
    const listing = deps.run("xcrun", ["simctl", "listapps", options.device]);
    const apps = JSON.parse(
      deps.run("plutil", ["-convert", "json", "-o", "-", "-"], {
        input: listing,
      }),
    );
    if (!apps[expected]) {
      add("FAIL", "Installed app", `${expected} is not installed`);
      return;
    }
    const bundle = apps[expected].CFBundleIdentifier;
    if (!bundle) throw new Error("Missing installed identity");
    add(bundle === expected ? "PASS" : "FAIL", "Installed app", bundle);
  });
  await probe("Metro status", async () => {
    try {
      const body = await deps.status(options.port);
      add(
        body.trim() === "packager-status:running" ? "PASS" : "FAIL",
        "Metro status",
        body.trim() === "packager-status:running"
          ? `Listening on ${options.port}`
          : "Endpoint is not Metro",
      );
    } catch {
      add("FAIL", "Metro status", `Unreachable on ${options.port}`);
    }
  });
  await probe("Metro checkout", () => {
    const pids = [
      ...new Set(
        deps
          .run("lsof", ["-nP", `-iTCP:${options.port}`, "-sTCP:LISTEN", "-t"])
          .split(/\s+/)
          .filter(Boolean),
      ),
    ];
    if (pids.length !== 1 || !/^\d+$/.test(pids[0]))
      throw new Error("Ambiguous listener");
    const output = deps.run("lsof", ["-a", "-p", pids[0], "-d", "cwd", "-Fn"]);
    const directories = output
      .split("\n")
      .filter((line) => line.startsWith("n"))
      .map((line) => line.slice(1));
    if (directories.length !== 1) throw new Error("Unknown cwd");
    const directory = deps.realpath(directories[0]);
    const owner = deps.realpath(
      deps.run("git", ["rev-parse", "--show-toplevel"], { cwd: directory }),
    );
    add(
      owner === root ? "PASS" : "FAIL",
      "Metro checkout",
      `PID ${pids[0]}: ${directory}`,
    );
  });
  add(
    "INFO",
    "Screen readiness",
    "Not inspected: use Maestro for runtime environment, authentication, and the target screen. Device ownership is task-recorded, not inferred.",
  );
  return results;
}

export function resultCode(results) {
  return results.some((item) => item.status === "FAIL")
    ? 1
    : results.some((item) => item.status === "UNKNOWN")
      ? 2
      : 0;
}

export async function iosMain(args) {
  try {
    const results = await inspectIos(parseOptions(args));
    for (const { status, label, detail } of results)
      console.log(`${status} ${label}: ${detail}`);
    return resultCode(results);
  } catch (error) {
    console.error(
      error.message === usage
        ? usage
        : "iOS inspection unavailable; no verification credit.",
    );
    return 2;
  }
}
