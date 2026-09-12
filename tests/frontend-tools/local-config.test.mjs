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
function fixture(t) {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), "local-config-"));
  t.after(() => fs.rmSync(home, { recursive: true, force: true }));
  const directory = path.join(home, ".config/dotfiles-local");
  fs.mkdirSync(directory, { recursive: true });
  return {
    write(value) {
      fs.writeFileSync(path.join(directory, "agent-hooks.json"), value);
    },
    render(document, engine = "codex") {
      return spawnSync(
        "chezmoi",
        [
          "execute-template",
          "--source",
          source,
          "--with-stdin",
          `{{ includeTemplate "local-hooks.tmpl" (dict "engine" "${engine}" "home" "${home}" "document" (fromJson .chezmoi.stdin)) }}`,
        ],
        { encoding: "utf8", input: JSON.stringify(document) },
      );
    },
  };
}
const parse = (result) => {
  assert.equal(result.status, 0, result.stderr);
  return JSON.parse(result.stdout);
};
const group = (command, timeout = 10) => ({
  hooks: [{ type: "command", command, timeout }],
});

test("missing local configuration preserves all existing settings", (t) => {
  const f = fixture(t);
  const before = {
    enabledPlugins: { example: true },
    hooks: { Stop: [group("unrelated")] },
  };
  assert.deepEqual(parse(f.render(before)), before);
  assert.deepEqual(parse(f.render({})), {});
});

test("local merge updates matching commands and preserves other handlers idempotently", (t) => {
  const f = fixture(t);
  f.write(
    JSON.stringify({ codex: { hooks: { Stop: [group("local-check", 65)] } } }),
  );
  const before = {
    enabledPlugins: { example: true },
    hooks: {
      Start: [group("unrelated")],
      Stop: [
        {
          matcher: "*",
          hooks: [...group("local-check").hooks, ...group("another").hooks],
        },
      ],
    },
  };
  const after = parse(f.render(before));
  assert.deepEqual(after.enabledPlugins, before.enabledPlugins);
  assert.deepEqual(after.hooks.Start, before.hooks.Start);
  assert.deepEqual(after.hooks.Stop, [
    { matcher: "*", ...group("another") },
    group("local-check", 65),
  ]);
  assert.deepEqual(parse(f.render(after)), after);
  assert.deepEqual(parse(f.render(before, "claude")), before);
});

test("malformed local JSON fails instead of returning replacement settings", (t) => {
  const f = fixture(t);
  f.write("{broken");
  assert.notEqual(f.render({}).status, 0);
});
