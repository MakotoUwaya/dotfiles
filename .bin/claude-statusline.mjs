// Claude Code Statusline - cross-platform (Node.js ESM)
// 3-line display: session info, 5h usage, 7d usage

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
let model = input.model?.display_name ?? '';
if (model) {
  model = model.replace(' (1M context)', '(1M)').replaceAll(' ', '');
}
const effort = input.effort?.level ?? '';
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

let line1 = `${modelDisplay}${sep}${ctxColor}📊 ${ctxInt}%${RESET} ✏️ +${linesAdded}/-${linesRemoved}`;
if (gitRepo && gitBranch) {
  line1 += `${sep}📦 ${gitRepo} 🔀 ${gitBranch}`;
} else if (gitRepo) {
  line1 += `${sep}📦 ${gitRepo}`;
} else if (gitBranch) {
  line1 += `${sep}🔀 ${gitBranch}`;
}
if (dirDisplay) line1 += `${sep}📁 ${dirDisplay}`;

// ── Usage API (OAuth, cached) ──
const CACHE_FILE = join(tmpdir(), 'claude-usage-cache.json');
const CACHE_TTL = 360;

async function fetchUsage() {
  let tokenStr = '';
  try {
    tokenStr = execFileSync('security', ['find-generic-password', '-s', 'Claude Code-credentials', '-w'], { encoding: 'utf8', stdio: 'pipe' }).trim();
  } catch {}
  if (!tokenStr) {
    try {
      tokenStr = readFileSync(join(home, '.claude', '.credentials.json'), 'utf8');
    } catch { return null; }
  }
  if (!tokenStr) return null;

  let accessToken = '';
  try {
    const parsed = JSON.parse(tokenStr);
    accessToken = parsed.claudeAiOauth?.accessToken ?? parsed.accessToken ?? parsed.access_token ?? '';
  } catch { return null; }
  if (!accessToken) return null;

  try {
    const res = await fetch('https://api.anthropic.com/api/oauth/usage', {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'anthropic-beta': 'oauth-2025-04-20',
      },
      signal: AbortSignal.timeout(5000),
    });
    if (!res.ok) return null;
    const data = await res.json();
    try {
      writeFileSync(CACHE_FILE, JSON.stringify({ ...data, cached_at: Math.floor(Date.now() / 1000) }));
    } catch {}
    return data;
  } catch { return null; }
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
  return fetchUsage();
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

function elapsedPct(resetsAt, windowLenSec) {
  const resetMs = new Date(resetsAt).getTime();
  if (isNaN(resetMs)) return null;
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

function format5hReset(resetsAt) {
  const d = new Date(resetsAt);
  if (isNaN(d.getTime())) return '';
  return `${jpTime(d)} (${jpRemaining(d.getTime())})`;
}

function format7dReset(resetsAt) {
  const d = new Date(resetsAt);
  if (isNaN(d.getTime())) return '';
  const diff = d.getTime() - Date.now();

  const parts = new Intl.DateTimeFormat('ja-JP', {
    timeZone: TZ, month: 'numeric', day: 'numeric', weekday: 'short',
  }).formatToParts(d);
  const month = parts.find(p => p.type === 'month')?.value;
  const day = parts.find(p => p.type === 'day')?.value;
  const weekday = parts.find(p => p.type === 'weekday')?.value;
  const md = `${month}/${day}(${weekday})`;
  const time = jpTime(d);

  if (diff <= 0) return `${md} ${time} (まもなく)`;

  const days = Math.floor(diff / 86_400_000);
  const hours = Math.floor((diff % 86_400_000) / 3_600_000);
  let rem;
  if (days > 0 && hours > 0) rem = `あと${days}日${hours}時間`;
  else if (days > 0) rem = `あと${days}日`;
  else rem = jpRemaining(d.getTime());

  return `${md} ${time} (${rem})`;
}

// ── Lines 2 & 3: Usage ──
let line2 = '';
let line3 = '';

const usage = await getUsage();

if (usage) {
  const fiveUtil = usage.five_hour?.utilization;
  const fiveReset = usage.five_hour?.resets_at;
  const sevenUtil = usage.seven_day?.utilization;
  const sevenReset = usage.seven_day?.resets_at;

  if (fiveUtil != null) {
    const fiveInt = Math.round(fiveUtil);
    const fiveElapsed = fiveReset ? elapsedPct(fiveReset, 18000) : null;
    let fiveColor = colorForPct(fiveInt);
    let fiveMarker = -1;
    if (fiveElapsed != null) {
      const ratio = paceRatio100(fiveInt, fiveElapsed);
      if (ratio != null) fiveColor = colorForPace(ratio);
      fiveMarker = fiveElapsed;
    }
    const fiveBar = progressBar(fiveInt, 0, 30, fiveColor, fiveMarker);
    const fiveResetStr = fiveReset ? format5hReset(fiveReset) : '';
    line2 = `${fiveColor}⏱ 5h${RESET} ${fiveBar} ${fiveColor}${fiveInt}%${RESET}`;
    if (fiveResetStr) line2 += `  ${GRAY}${fiveResetStr}${RESET}`;
  }

  if (sevenUtil != null) {
    const sevenInt = Math.round(sevenUtil);
    const sevenElapsed = sevenReset ? elapsedPct(sevenReset, 604800) : null;
    let sevenColor = colorForPct(sevenInt);
    let sevenMarker = -1;
    if (sevenElapsed != null) {
      const ratio = paceRatio100(sevenInt, sevenElapsed);
      if (ratio != null) sevenColor = colorForPace(ratio);
      sevenMarker = sevenElapsed;
    }
    const sevenBar = progressBar(sevenInt, 0, 30, sevenColor, sevenMarker);
    const sevenResetStr = sevenReset ? format7dReset(sevenReset) : '';
    line3 = `${sevenColor}📅7d${RESET} ${sevenBar} ${sevenColor}${sevenInt}%${RESET}`;
    if (sevenResetStr) line3 += `  ${GRAY}${sevenResetStr}${RESET}`;
  }
}

// ── Output ──
let output = line1;
if (line2) output += '\n' + line2;
if (line3) output += '\n' + line3;
process.stdout.write(output);
