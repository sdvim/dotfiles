import { spawn, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import fs from "node:fs";
import path from "node:path";

const args = process.argv.slice(2);
const hash = (value) =>
  createHash("sha256").update(value).digest("hex").slice(0, 16);
const git = spawnSync("git", ["rev-parse", "--show-toplevel"], {
  encoding: "utf8",
});
const root = fs.realpathSync(
  git.status === 0 ? git.stdout.trim() : process.cwd(),
);
const session =
  process.env.FRONTEND_SESSION || process.env.CODEX_THREAD_ID || "manual";
const name = `frontend-${hash(root)}-${hash(session)}`;
const directory = path.join(
  process.env.XDG_CACHE_HOME || path.join(process.env.HOME, ".cache"),
  "frontend-verification",
  hash(root),
  hash(session),
);
fs.mkdirSync(directory, { recursive: true, mode: 0o700 });
const configFile = path.join(directory, "playwright.json");
const config = {
  browser: {
    browserName: "chromium",
    isolated: true,
    launchOptions: {
      headless: false,
      executablePath: "/Applications/Helium.app/Contents/MacOS/Helium",
    },
  },
  outputDir: directory,
};
fs.writeFileSync(configFile, JSON.stringify(config, null, 2) + "\n", {
  mode: 0o600,
});
if (args[0] === "artifacts") {
  console.log(directory);
} else {
  const mise = spawnSync(
    process.env.FRONTEND_MISE || "mise",
    ["which", "playwright-cli", "--tool", "npm:@playwright/cli@0.1.18"],
    { encoding: "utf8" },
  );
  if (mise.status !== 0) {
    console.error("Run: mise install npm:@playwright/cli@0.1.18");
    process.exit(1);
  }
  const hasSession = args.some(
    (arg) =>
      arg === "-s" ||
      arg.startsWith("-s=") ||
      arg === "--session" ||
      arg.startsWith("--session="),
  );
  const hasConfig = args.some(
    (arg) => arg === "--config" || arg.startsWith("--config="),
  );
  const child = spawn(
    mise.stdout.trim(),
    [
      ...(hasSession ? [] : [`-s=${name}`]),
      ...args,
      ...(args.includes("open") && !hasConfig ? ["--config", configFile] : []),
    ],
    { stdio: "inherit" },
  );
  for (const signal of ["SIGINT", "SIGTERM"])
    process.on(signal, () => child.kill(signal));
  child.on("error", (error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
  child.on("exit", (code, signal) => {
    process.exitCode = code ?? (signal ? 130 : 1);
  });
}
