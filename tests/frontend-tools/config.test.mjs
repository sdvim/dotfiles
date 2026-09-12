import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { test } from "node:test";

const source = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../..",
);
const execute = (command, args, options = {}) => {
  const result = spawnSync(command, args, { encoding: "utf8", ...options });
  assert.equal(result.status, 0, result.stderr || result.stdout);
  return result.stdout;
};
const fromToml = (input) =>
  JSON.parse(
    execute(
      "chezmoi",
      [
        "execute-template",
        "--source",
        source,
        "--with-stdin",
        "{{ .chezmoi.stdin | fromToml | toJson }}",
      ],
      { input },
    ),
  );
const merge = (input) =>
  execute(
    "chezmoi",
    [
      "execute-template",
      "--source",
      source,
      "--with-stdin",
      "--file",
      path.join(source, "dot_codex/modify_config.toml"),
    ],
    { input },
  );

test("MCP merge preserves existing settings and hook trust; second application is stable", () => {
  const old =
    'model = "existing-model"\n[features]\nhooks = true\n[mcp_servers.figma]\nurl = "https://mcp.figma.com/mcp"\n[hooks.state."user.Stop.0"]\ntrusted_hash = "opaque-hash"\n[projects."/tmp/repo.with.dots"]\ntrust_level = "trusted"\n';
  const rendered = merge(old);
  const result = fromToml(rendered);
  const before = fromToml(old);
  for (const key of Object.keys(before)) {
    if (key !== "mcp_servers") assert.deepEqual(result[key], before[key]);
  }
  assert.deepEqual(result.mcp_servers.figma, before.mcp_servers.figma);
  assert.match(
    result.mcp_servers["chrome-devtools"].command,
    /codex-helium-mcp$/,
  );
  assert.match(result.mcp_servers.maestro.command, /codex-maestro-mcp$/);
  assert.equal(merge(rendered), rendered);
  assert.equal(Object.keys(fromToml(merge("")).mcp_servers).length, 2);
});

test("malformed TOML is rejected instead of replacing settings", () => {
  const result = spawnSync(
    "chezmoi",
    [
      "execute-template",
      "--source",
      source,
      "--with-stdin",
      "--file",
      path.join(source, "dot_codex/modify_config.toml"),
    ],
    { input: "[broken", encoding: "utf8" },
  );
  assert.notEqual(result.status, 0);
});

function fixture(t) {
  const temporary = fs.realpathSync(
    fs.mkdtempSync(path.join(os.tmpdir(), "frontend tools ")),
  );
  t.after(() => fs.rmSync(temporary, { recursive: true, force: true }));
  const home = path.join(temporary, "home");
  const bin = path.join(home, ".local/bin");
  const root = path.join(temporary, "repo");
  fs.mkdirSync(bin, { recursive: true });
  fs.mkdirSync(root);
  fs.mkdirSync(path.join(root, "nested"));
  execute("git", ["init", "-q", root]);
  fs.cpSync(
    path.join(source, "dot_config/frontend-tools"),
    path.join(home, ".config/frontend-tools"),
    { recursive: true },
  );
  const tool = path.join(bin, "mock-tool");
  fs.writeFileSync(
    tool,
    `#!${process.execPath}\nconsole.log(JSON.stringify({args:process.argv.slice(2),java:process.env.JAVA_HOME}));\n`,
    { mode: 0o755 },
  );
  fs.writeFileSync(
    path.join(bin, "mise"),
    `#!${process.execPath}\nconsole.log(process.argv[3]==='node'?${JSON.stringify(process.execPath)}:${JSON.stringify(tool)});\n`,
    { mode: 0o755 },
  );
  const launcher = path.join(bin, "frontend-browser");
  fs.copyFileSync(
    path.join(source, "dot_local/bin/executable_frontend-browser"),
    launcher,
  );
  fs.chmodSync(launcher, 0o755);
  const env = { HOME: home, PATH: "/usr/bin:/bin", FRONTEND_SESSION: "one" };
  const run = (args, cwd = root, overrides = {}) =>
    execute(launcher, args, { cwd, env: { ...env, ...overrides } });
  return { home, root, run };
}

test("minimal-PATH browser launcher isolates worktrees and sessions and writes artifacts outside source", (t) => {
  const f = fixture(t);
  const first = JSON.parse(f.run(["open", "about:blank"]));
  const nested = JSON.parse(
    f.run(["open", "about:blank"], path.join(f.root, "nested")),
  );
  assert.equal(first.args[0], nested.args[0]);
  const second = JSON.parse(
    f.run(["open", "about:blank"], f.root, { FRONTEND_SESSION: "two" }),
  );
  assert.notEqual(first.args[0], second.args[0]);
  const other = path.join(path.dirname(f.root), "other-worktree");
  execute("git", ["init", "-q", other]);
  assert.notEqual(
    first.args[0],
    JSON.parse(f.run(["open", "about:blank"], other)).args[0],
  );
  const config = first.args[first.args.indexOf("--config") + 1];
  assert.ok(
    config.startsWith(path.join(f.home, ".cache/frontend-verification")),
  );
  const settings = JSON.parse(fs.readFileSync(config));
  assert.equal(settings.browser.isolated, true);
  assert.equal(settings.browser.launchOptions.headless, false);
  assert.match(settings.browser.launchOptions.executablePath, /Helium.app/);
  assert.equal(execute("git", ["status", "--porcelain"], { cwd: f.root }), "");
});

test("browser launcher preserves explicit session and config arguments including spaces", (t) => {
  const f = fixture(t);
  const args = [
    "-s=custom",
    "open",
    "http://localhost:3000/path?q=two words",
    "--config",
    "/tmp/custom config.json",
  ];
  assert.deepEqual(JSON.parse(f.run(args)).args, args);
  const result = JSON.parse(f.run(["screenshot", "--filename=/tmp/a b.png"]));
  assert.equal(result.args.at(-1), "--filename=/tmp/a b.png");
  assert.ok(!result.args.includes("--config"));
});
