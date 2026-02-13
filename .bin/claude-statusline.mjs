#!/usr/bin/env node
import { execSync } from "node:child_process";

const chunks = [];
for await (const chunk of process.stdin) {
  chunks.push(chunk);
}
const data = JSON.parse(
  Buffer.concat(chunks).toString("utf8").replace(/^\uFEFF/, ""),
);

const model = data.model?.display_name ?? "Unknown";
const cwd = data.workspace?.current_dir ?? process.cwd();
const dirName = cwd.replace(/\\/g, "/").split("/").pop();

let branch = "";
let dirty = "";
let ahead = 0;
let behind = 0;

try {
  branch = execSync("git rev-parse --abbrev-ref HEAD", {
    cwd,
    stdio: ["ignore", "pipe", "ignore"],
    encoding: "utf8",
  }).trim();

  const status = execSync("git status --porcelain", {
    cwd,
    stdio: ["ignore", "pipe", "ignore"],
    encoding: "utf8",
  }).trim();
  if (status.length > 0) {
    dirty = "*";
  }

  const ab = execSync("git rev-list --left-right --count HEAD...@{upstream}", {
    cwd,
    stdio: ["ignore", "pipe", "ignore"],
    encoding: "utf8",
  }).trim();
  const parts = ab.split(/\s+/);
  ahead = parseInt(parts[0], 10) || 0;
  behind = parseInt(parts[1], 10) || 0;
} catch {
  // not a git repo or no upstream — silently ignore
}

const yellow = "\x1b[33m";
const cyan = "\x1b[36m";
const reset = "\x1b[0m";

let line = `${yellow}[${model}]${reset} ${dirName}`;
if (branch) {
  line += ` ${cyan}${branch}${reset}${dirty}`;
}
const arrows = [];
if (ahead > 0) arrows.push(`\u2191${ahead}`);
if (behind > 0) arrows.push(`\u2193${behind}`);
if (arrows.length > 0) {
  line += ` ${arrows.join("")}`;
}

process.stdout.write(line);
