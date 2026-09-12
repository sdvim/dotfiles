import assert from "node:assert/strict";
import { test } from "node:test";
import {
  inspectIos,
  parseOptions,
  resultCode,
} from "../../dot_config/frontend-tools/ios-doctor.mjs";

const udid = "00000000-0000-4000-8000-000000000001";
const options = {
  device: udid,
  environment: "development",
  port: "8081",
  cwd: "/repo/apps/mobile",
  env: { HOME: "/user", FRONTEND_SESSION: "pilot" },
};
function fixture(overrides = {}) {
  const calls = [];
  const bundle = "com.example.app.dev";
  const native = {
    objects: {
      target: {
        isa: "PBXNativeTarget",
        productType: "com.apple.product-type.application",
        buildConfigurationList: "configs",
      },
      configs: { buildConfigurations: ["debug", "release"] },
      debug: { buildSettings: { PRODUCT_BUNDLE_IDENTIFIER: bundle } },
      release: { buildSettings: { PRODUCT_BUNDLE_IDENTIFIER: bundle } },
    },
  };
  const deps = {
    realpath: (name) => name,
    read: (name) => {
      assert.equal(name, "/repo/apps/mobile/package.json");
      return '{"name":"example-mobile","dependencies":{"expo":"*"}}';
    },
    list: (name) => {
      assert.equal(name, "/repo/apps/mobile/ios");
      return ["Example.xcodeproj"];
    },
    status: async (port) => {
      assert.equal(port, "8081");
      return "packager-status:running";
    },
    run(command, args, config) {
      calls.push([command, args, config]);
      const key = [command, ...args].join(" ");
      if (key === "git rev-parse --show-toplevel")
        return config.cwd.startsWith("/other") ? "/other" : "/repo";
      if (key === "git rev-parse HEAD") return "abc123";
      if (key === "git branch --show-current") return "feature";
      if (key === "git status --porcelain") return "";
      if (key === "yarn exec expo config --json --type public") {
        assert.equal(config.env.APP_ENV, options.environment);
        assert.equal(config.cwd, "/repo/apps/mobile");
        return JSON.stringify({ ios: { bundleIdentifier: bundle } });
      }
      if (command === "plutil") {
        if (args.at(-1) === "-") return config.input;
        assert.deepEqual(args, [
          "-convert",
          "json",
          "-o",
          "-",
          "/repo/apps/mobile/ios/Example.xcodeproj/project.pbxproj",
        ]);
        return JSON.stringify(native);
      }
      if (key === "xcrun simctl list devices available --json")
        return JSON.stringify({
          devices: { iOS: [{ udid, name: "Test phone", state: "Booted" }] },
        });
      if (key === `xcrun simctl listapps ${udid}`)
        return JSON.stringify({ [bundle]: { CFBundleIdentifier: bundle } });
      if (key === "lsof -nP -iTCP:8081 -sTCP:LISTEN -t") return "42";
      if (key === "lsof -a -p 42 -d cwd -Fn") return "p42\nn/repo/apps/mobile";
      throw new Error(`Unexpected command: ${key}`);
    },
    ...overrides,
  };
  return { deps, calls, native };
}
const status = (results, label) =>
  results.find((item) => item.label === label)?.status;

test("inspection uses read-only operations and keeps screen readiness separate", async () => {
  const f = fixture();
  const results = await inspectIos(options, f.deps);
  assert.equal(resultCode(results), 0);
  assert.equal(status(results, "Screen readiness"), "INFO");
  assert.match(
    results.find((item) => item.label === "Artifacts").detail,
    /\/user\/\.cache\/frontend-verification\/[a-f0-9]{16}\/[a-f0-9]{16}$/,
  );
  assert.ok(f.calls.length > 8);
  assert.ok(
    f.calls.every(
      ([, args]) =>
        !args.some((arg) =>
          [
            "boot",
            "shutdown",
            "erase",
            "install",
            "launch",
            "prebuild",
            "run:ios",
          ].includes(arg),
        ),
    ),
  );
});

test("wrong Metro checkout fails even when its status endpoint is healthy", async () => {
  const f = fixture();
  const original = f.deps.run;
  f.deps.run = (cmd, args, config) =>
    args.includes("cwd")
      ? "p42\nn/other/apps/mobile"
      : original(cmd, args, config);
  assert.equal(
    status(await inspectIos(options, f.deps), "Metro checkout"),
    "FAIL",
  );
});

test("unreachable port fails without launching a server", async () => {
  const f = fixture({
    status: async () => {
      throw new Error("connection refused");
    },
  });
  assert.equal(
    status(await inspectIos(options, f.deps), "Metro status"),
    "FAIL",
  );
});

test("missing app fails without installing it", async () => {
  const f = fixture();
  const original = f.deps.run;
  f.deps.run = (cmd, args, config) =>
    args.includes("listapps") ? "{}" : original(cmd, args, config);
  assert.equal(
    status(await inspectIos(options, f.deps), "Installed app"),
    "FAIL",
  );
});

test("a mismatched Release bundle fails even if Debug matches", async () => {
  const f = fixture();
  f.native.objects.release.buildSettings.PRODUCT_BUNDLE_IDENTIFIER =
    "com.example.app";
  assert.equal(
    status(await inspectIos(options, f.deps), "Generated native bundle"),
    "FAIL",
  );
});

test("unresolved native settings and inaccessible process cwd are unknown", async () => {
  const f = fixture();
  f.native.objects.debug.buildSettings.PRODUCT_BUNDLE_IDENTIFIER =
    "$(APP_BUNDLE)";
  const original = f.deps.run;
  f.deps.run = (cmd, args, config) => {
    if (args.includes("cwd")) throw new Error("permission denied");
    return original(cmd, args, config);
  };
  const results = await inspectIos(options, f.deps);
  assert.equal(status(results, "Generated native bundle"), "UNKNOWN");
  assert.equal(status(results, "Metro checkout"), "UNKNOWN");
  assert.equal(resultCode(results), 2);
});

test("shutdown device fails without booting or resetting it", async () => {
  const f = fixture();
  const original = f.deps.run;
  f.deps.run = (cmd, args, config) =>
    args.includes("devices")
      ? JSON.stringify({
          devices: { iOS: [{ udid, name: "Test", state: "Shutdown" }] },
        })
      : original(cmd, args, config);
  const results = await inspectIos(options, f.deps);
  assert.equal(status(results, "Simulator"), "FAIL");
  assert.equal(status(results, "Installed app"), "UNKNOWN");
});

test("invalid arguments cannot select an implicit device, environment or port", () => {
  const valid = [
    "ios",
    "--device",
    udid,
    "--environment",
    "development",
    "--port",
    "8081",
  ];
  assert.equal(parseOptions(valid).port, "8081");
  assert.equal(
    parseOptions(
      valid.map((item) => (item === "development" ? "staging" : item)),
    ).environment,
    "staging",
  );
  assert.throws(() => parseOptions(["ios"]));
  assert.throws(() =>
    parseOptions(valid.map((item) => (item === "development" ? "" : item))),
  );
  assert.throws(() =>
    parseOptions(valid.map((item) => (item === "8081" ? "0" : item))),
  );
  assert.throws(() => parseOptions([...valid.slice(0, 5), "--device", udid]));
  assert.throws(() => parseOptions([...valid, "--env-var", "bad-name"]));
  assert.throws(() => parseOptions([...valid, "--project"]));
});

test("project and environment variable are configurable without company defaults", async () => {
  const f = fixture();
  const original = f.deps.run;
  f.deps.run = (cmd, args, config) => {
    if (cmd === "yarn") {
      assert.equal(config.env.EXAMPLE_ENV, "staging");
      assert.equal(config.env.APP_ENV, undefined);
      assert.equal(config.cwd, "/repo/apps/mobile");
      return JSON.stringify({
        ios: { bundleIdentifier: "com.example.app.dev" },
      });
    }
    return original(cmd, args, config);
  };
  assert.equal(
    resultCode(
      await inspectIos(
        {
          ...options,
          cwd: "/repo",
          project: "apps/mobile",
          environment: "staging",
          "env-var": "EXAMPLE_ENV",
        },
        f.deps,
      ),
    ),
    0,
  );
});

test("a non-Expo project stops inspection before native commands", async () => {
  const f = fixture({ read: () => '{"name":"example"}' });
  const results = await inspectIos(options, f.deps);
  assert.equal(resultCode(results), 2);
  assert.deepEqual(
    f.calls.map(([command]) => command),
    ["git"],
  );
});
