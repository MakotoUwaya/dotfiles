// GitHub Copilot CLI Statusline - cross-platform (Node.js ESM)
// Display: session info, model, git status, directory

import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { homedir, tmpdir } from 'node:os';
import { join } from 'node:path';

const chunks = [];
for await (const chunk of process.stdin) chunks.push(chunk);
const input = JSON.parse(Buffer.concat(chunks).toString());

// ── Colors ──
const GREEN = '\x1b[38;2;151;201;195m';
const YELLOW = '\x1b[38;2;229;192;123m';
const RED = '\x1b[38;2;224;108;117m';
const BLUE = '\x1b[38;2;97;175;239m';
const GRAY = '\x1b[38;2;74;88;92m';
const MARKER = '\x1b[38;2;198;120;221m';
const RESET = '\x1b[0m';

function colorForPct(pct) {
  if (pct >= 80) return RED;
  if (pct >= 50) return YELLOW;
  return GREEN;
}

function colorForPace(ratio100) {
  if (ratio100 >= 130) return RED;
  if (ratio100 >= 110) return YELLOW;
  if (ratio100 >= 90) return GREEN;
  return BLUE;
}

function progressBar(pct, divs = 0, total = 14, color = '', markerPct = -1) {
  let filled = Math.round((pct * total) / 100);
  if (filled > total) filled = total;
  if (!color) color = colorForPct(pct);

  let markerIdx = -1;
  if (markerPct >= 0) {
    markerIdx = Math.round((markerPct * total) / 100);
    if (markerIdx >= total) markerIdx = total - 1;
  }

  const gapAfter = new Set();
  if (divs > 1) {
    for (let k = 1; k < divs; k++) {
      gapAfter.add(Math.floor((total * k) / divs) - 1);
    }
  }

  let bar = '';
  for (let i = 0; i < total; i++) {
    const seg = i < filled ? '█' : '░';
    const segColor = i === markerIdx ? MARKER : color;
    bar += `${segColor}${seg}${RESET}`;
    if (divs > 1 && gapAfter.has(i)) bar += ' ';
  }
  return bar;
}

// ── Line 1: Session info ──
let model = input.model?.display_name ?? input.model?.name ?? '';
if (model) {
  model = model.replace(' (1M context)', '(1M)').replaceAll(' ', '');
}
const effort = input.effort?.level ?? input.reasoning_effort ?? '';
const usedPct = input.context_window?.used_percentage;
const linesAdded = input.cost?.total_lines_added ?? 0;
const linesRemoved = input.cost?.total_lines_removed ?? 0;
const cwd = input.workspace?.current_dir ?? '';

const ctxInt = usedPct != null ? Math.round(usedPct) : 0;
const ctxColor = colorForPct(ctxInt);

let gitBranch = '';
let gitRepo = '';
if (cwd) {
  try {
    execFileSync('git', ['-C', cwd, 'rev-parse', '--git-dir'], { stdio: 'pipe' });
    try {
      gitBranch = execFileSync('git', ['-C', cwd, 'symbolic-ref', '--short', 'HEAD'], { encoding: 'utf8', stdio: 'pipe' }).trim();
    } catch {
      try {
        gitBranch = execFileSync('git', ['-C', cwd, 'rev-parse', '--short', 'HEAD'], { encoding: 'utf8', stdio: 'pipe' }).trim();
      } catch {}
    }
    try {
      const toplevel = execFileSync('git', ['-C', cwd, 'rev-parse', '--show-toplevel'], { encoding: 'utf8', stdio: 'pipe' }).trim();
      if (toplevel) gitRepo = toplevel.split(/[/\\]/).pop();
    } catch {}
    if (gitBranch) {
      try {
        const porcelain = execFileSync('git', ['-C', cwd, 'status', '--porcelain'], { encoding: 'utf8', stdio: 'pipe' }).trim();
        if (porcelain) gitBranch += '*';
      } catch {}
    }
  } catch {}
}

const home = homedir();
const dirDisplay = cwd ? cwd.replace(home, '~') : '';
const sep = `${GRAY} │ ${RESET}`;

let modelDisplay = model;
if (effort) modelDisplay += ` ${GRAY}${effort}${RESET}`;

let line1 = `${modelDisplay}${sep}${ctxColor}📊 ${ctxInt}%${RESET}`;
if (linesAdded > 0 || linesRemoved > 0) {
  line1 += ` ✏️ +${linesAdded}/-${linesRemoved}`;
}
if (gitRepo && gitBranch) {
  line1 += `${sep}📦 ${gitRepo} 🔀 ${gitBranch}`;
} else if (gitRepo) {
  line1 += `${sep}📦 ${gitRepo}`;
} else if (gitBranch) {
  line1 += `${sep}🔀 ${gitBranch}`;
}
if (dirDisplay) line1 += `${sep}📁 ${dirDisplay}`;

// ── Usage API (GitHub rate limit) ──
const CACHE_FILE = join(tmpdir(), 'copilot-usage-cache.json');
const CACHE_TTL = 360;

async function fetchRateLimit() {
  try {
    const ghPath = process.platform === 'win32' ? 'gh.exe' : 'gh';
    const result = execFileSync(ghPath, ['api', 'rate_limit'], {
      encoding: 'utf8',
      stdio: 'pipe',
      timeout: 5000,
    });
    const data = JSON.parse(result);
    try {
      writeFileSync(CACHE_FILE, JSON.stringify({ ...data, cached_at: Math.floor(Date.now() / 1000) }));
    } catch {}
    return data;
  } catch {
    return null;
  }
}

async function getUsage() {
  try {
    const cached = JSON.parse(readFileSync(CACHE_FILE, 'utf8'));
    const age = Math.floor(Date.now() / 1000) - (cached.cached_at ?? 0);
    if (age < CACHE_TTL) {
      const { cached_at, ...rest } = cached;
      return rest;
    }
  } catch {}
  return fetchRateLimit();
}

// ── Date helpers (Asia/Tokyo) ──
const TZ = 'Asia/Tokyo';

function jpTime(date) {
  return date.toLocaleTimeString('ja-JP', { timeZone: TZ, hour: '2-digit', minute: '2-digit', hour12: false });
}

function jpRemaining(targetMs) {
  const diff = targetMs - Date.now();
  if (diff <= 0) return 'まもなく';
  const h = Math.floor(diff / 3_600_000);
  const m = Math.floor((diff % 3_600_000) / 60_000);
  if (h > 0 && m > 0) return `あと${h}時間${m}分`;
  if (h > 0) return `あと${h}時間`;
  return `あと${m}分`;
}

function elapsedPct(resetSec, windowLenSec) {
  if (!resetSec) return null;
  const resetMs = resetSec * 1000;
  const windowMs = windowLenSec * 1000;
  let elapsed = Date.now() - (resetMs - windowMs);
  if (elapsed < 0) elapsed = 0;
  if (elapsed > windowMs) elapsed = windowMs;
  return Math.round((elapsed * 100) / windowMs);
}

function paceRatio100(usage, elapsed) {
  if (elapsed <= 0) return null;
  return Math.floor((usage * 100) / elapsed);
}

function formatReset(resetSec, label) {
  const d = new Date(resetSec * 1000);
  if (isNaN(d.getTime())) return '';
  return `${label} リセット: ${jpTime(d)} (${jpRemaining(d.getTime())})`;
}

// ── Lines 2 & 3: Rate Limit Usage ──
let line2 = '';
let line3 = '';

const usage = await getUsage();

if (usage && usage.rate) {
  const { limit, used, remaining, reset } = usage.rate;
  if (limit && reset) {
    const usedPct = Math.round((used / limit) * 100);
    const remainingPct = Math.round((remaining / limit) * 100);
    
    // Assume 1 hour window (GitHub resets hourly)
    const elapsed = elapsedPct(reset, 3600);
    let rateColor = colorForPct(usedPct);
    let rateMarker = -1;
    if (elapsed != null) {
      const ratio = paceRatio100(usedPct, elapsed);
      if (ratio != null) rateColor = colorForPace(ratio);
      rateMarker = elapsed;
    }
    const rateBar = progressBar(usedPct, 0, 30, rateColor, rateMarker);
    const resetStr = formatReset(reset, '📊 API');
    line2 = `${rateColor}🔄 Rate${RESET} ${rateBar} ${rateColor}${used}/${limit}${RESET} (${remainingPct}% 残)  ${GRAY}${resetStr}${RESET}`;
  }
}

// Additional resource: Copilot-specific quota (if available in future)
// For now, we display GitHub API rate limit as a proxy

// ── Output ──
let output = line1;
if (line2) output += '\n' + line2;
if (line3) output += '\n' + line3;
process.stdout.write(output);
