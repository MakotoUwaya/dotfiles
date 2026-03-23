#!/usr/bin/env node
import { execFileSync } from "node:child_process";

const chunks = [];
for await (const chunk of process.stdin) {
  chunks.push(chunk);
}
const data = JSON.parse(
  Buffer.concat(chunks).toString("utf8").replace(/^\uFEFF/, ""),
);

const cwd = data.workspace?.current_dir ?? process.cwd();
const dirName = cwd.replace(/\\/g, "/").split("/").pop();

let branch = "";
let commitHash = "";
let dirty = "";
let ahead = 0;
let behind = 0;

try {
  branch = execFileSync("git", ["rev-parse", "--abbrev-ref", "HEAD"], {
    cwd,
    stdio: ["ignore", "pipe", "ignore"],
    encoding: "utf8",
  }).trim();

  commitHash = execFileSync("git", ["rev-parse", "--short=7", "HEAD"], {
    cwd,
    stdio: ["ignore", "pipe", "ignore"],
    encoding: "utf8",
  }).trim();

  const status = execFileSync("git", ["status", "--porcelain"], {
    cwd,
    stdio: ["ignore", "pipe", "ignore"],
    encoding: "utf8",
  }).trim();
  if (status.length > 0) dirty = "*";

  const ab = execFileSync(
    "git",
    ["rev-list", "--left-right", "--count", "HEAD...@{upstream}"],
    { cwd, stdio: ["ignore", "pipe", "ignore"], encoding: "utf8" },
  ).trim();
  const parts = ab.split(/\s+/);
  ahead = parseInt(parts[0], 10) || 0;
  behind = parseInt(parts[1], 10) || 0;
} catch {
  // not a git repo or no upstream
}

const cyan = "\x1b[36m";
const reset = "\x1b[0m";

// Ring Meter: 使用率を円形シンボル + グラデーションカラーで表現
function ringMeter(pct) {
  const rings = ["○", "◔", "◑", "◕", "●"];
  const idx = pct >= 100 ? 4 : Math.floor(pct / 25);
  const ring = rings[Math.min(idx, 4)];

  // 緑→黄→赤 のグラデーション (ANSI true color)
  let r, g;
  if (pct <= 50) {
    r = Math.round((pct / 50) * 255);
    g = 255;
  } else {
    r = 255;
    g = Math.round((1 - (pct - 50) / 50) * 255);
  }
  const color = `\x1b[38;2;${r};${g};0m`;
  return `${color}${ring}${reset}`;
}

// --- 左側: ディレクトリ / Git 情報 ---
let left = `${dirName}`;
if (branch) {
  left += ` ${cyan}${branch}${reset} ${commitHash}${dirty}`;
}
const arrows = [];
if (ahead > 0) arrows.push(`\u2191${ahead}`);
if (behind > 0) arrows.push(`\u2193${behind}`);
if (arrows.length > 0) left += ` ${arrows.join("")}`;

// 小数点以下1桁に切り上げてフォーマット
function fmtPct(pct) {
  return (Math.ceil(pct * 10) / 10).toFixed(1);
}

// --- Ring Meter (コンテキスト / レートリミット) ---
const meters = [];

const ctx = data.context_window;
if (ctx && ctx.used_percentage != null) {
  const pct = ctx.used_percentage;
  meters.push(`${ringMeter(pct)} ${fmtPct(pct)}%(ctx)`);
}

const rl = data.rate_limits;
if (rl) {
  if (rl.five_hour?.used_percentage != null) {
    const pct = rl.five_hour.used_percentage;
    meters.push(`${ringMeter(pct)} ${fmtPct(pct)}%(5h)`);
  }
  if (rl.seven_day?.used_percentage != null) {
    const pct = rl.seven_day.used_percentage;
    meters.push(`${ringMeter(pct)} ${fmtPct(pct)}%(7d)`);
  }
}

let line = left;
if (meters.length > 0) line += `  ${meters.join(" ")}`;
process.stdout.write(line);
