// Antigravity CLI (agy) Statusline - cross-platform (Node.js ESM)
// agy が stdin に渡す実際の JSON 構造に対応
// Display: model, context window, quota (Gemini / Claude & GPT), git status, directory, agent state

import { execFileSync } from 'node:child_process';
import { homedir } from 'node:os';

// stdin からデータを読み取り
const chunks = [];
for await (const chunk of process.stdin) chunks.push(chunk);
const inputStr = Buffer.concat(chunks).toString();

// JSON パースのエラーハンドリング
let input;
try {
  input = JSON.parse(inputStr);
} catch {
  process.stdout.write('⚠️ AGY StatusLine: JSON parse error');
  process.exit(0);
}

try {
// ── Colors ──
const GREEN = '\x1b[38;2;151;201;195m';
const YELLOW = '\x1b[38;2;229;192;123m';
const RED = '\x1b[38;2;224;108;117m';
const BLUE = '\x1b[38;2;97;175;239m';
const GRAY = '\x1b[38;2;74;88;92m';
const PURPLE = '\x1b[38;2;198;120;221m';
const CYAN = '\x1b[38;2;86;182;194m';
const WHITE = '\x1b[38;2;220;223;228m';
const RESET = '\x1b[0m';

function colorForPct(pct) {
  if (pct >= 80) return RED;
  if (pct >= 50) return YELLOW;
  return GREEN;
}

// 残量に対する色（20%以下は赤、50%以下は黄、それ以上は緑）
function colorForRemaining(remainingPct) {
  if (remainingPct <= 20) return RED;
  if (remainingPct <= 50) return YELLOW;
  return GREEN;
}

function progressBar(pct, total = 10, color = '') {
  let filled = Math.round((pct * total) / 100);
  if (filled > total) filled = total;
  if (filled < 0) filled = 0;
  if (!color) color = colorForPct(pct);

  let bar = '';
  for (let i = 0; i < total; i++) {
    const seg = i < filled ? '█' : '░';
    bar += `${color}${seg}${RESET}`;
  }
  return bar;
}

// 時間差分を日本語・短縮表示
function formatDuration(seconds) {
  if (!seconds || seconds <= 0) return '';
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  if (hours > 0 && minutes > 0) return `あと${hours}h${minutes}m`;
  if (hours > 0) return `あと${hours}h`;
  if (minutes > 0) return `あと${minutes}m`;
  return 'まもなく';
}

// パーセンテージ表示（100%は整数、それ以外は小数点第2位まで表示）
function formatPct(fraction) {
  const pct = (fraction ?? 1) * 100;
  if (pct >= 100) return '100%';
  return `${pct.toFixed(2)}%`;
}

// エージェント状態のアイコン
function agentStateIcon(state) {
  switch (state) {
    case 'working': return '⚡';
    case 'tool_use': return '🔧';
    case 'waiting': return '⏳';
    case 'idle': return '💤';
    default: return '🤖';
  }
}

// ── Model ──
const model = input.model?.display_name ?? input.model?.id ?? (typeof input.model === 'string' ? input.model : '');

// ── Context Window ──
const ctxWin = input.context_window;
const contextPct = ctxWin?.used_percentage ? Math.round(ctxWin.used_percentage) : 0;
const contextSize = ctxWin?.context_window_size ?? 0;
const contextInputTokens = ctxWin?.total_input_tokens ?? 0;
const contextOutputTokens = ctxWin?.total_output_tokens ?? 0;
const contextTotalUsed = contextInputTokens + contextOutputTokens;
const contextColor = colorForPct(contextPct);

// ── Workspace ──
const cwd = input.workspace?.current_dir ?? input.cwd ?? '';

// ── Agent State ──
const agentState = input.agent_state ?? '';
const stateIcon = agentStateIcon(agentState);

// ── Version / Product ──
const version = input.version ?? '';

// ── Git info ──
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

// ── Line 1: Session info ──
let line1 = '';

// エージェント状態アイコン + モデル名
line1 += `${PURPLE}${stateIcon}${RESET}${sep}${BLUE}${model}${RESET}`;

// バージョン
if (version) {
  line1 += ` ${GRAY}v${version}${RESET}`;
}

// コンテキストウィンドウ使用率
if (contextSize > 0) {
  const ctxBar = progressBar(contextPct, 14, contextColor);
  line1 += `${sep}📊 ${ctxBar} ${contextColor}${contextPct}%${RESET} ${GRAY}(${(contextTotalUsed / 1000).toFixed(1)}k/${(contextSize / 1000).toFixed(0)}k)${RESET}`;
}

// Git 情報
if (gitRepo && gitBranch) {
  line1 += `${sep}📦 ${gitRepo} 🔀 ${gitBranch}`;
} else if (gitRepo) {
  line1 += `${sep}📦 ${gitRepo}`;
} else if (gitBranch) {
  line1 += `${sep}🔀 ${gitBranch}`;
}

// ディレクトリ
if (dirDisplay) {
  line1 += `${sep}📁 ${dirDisplay}`;
}

// ── Line 2: Quota 情報 ──
// usage の構成に沿って GEMINI MODELS と CLAUDE AND GPT MODELS の両グループを表示
function formatQuotaItem(name, qData, barLength = 10) {
  if (!qData) return null;
  const fraction = qData.remaining_fraction ?? 1;
  const remainPct = fraction * 100;
  const color = colorForRemaining(remainPct);
  // usage の表示に合わせて「残量」をバーで塗りつぶす
  const bar = progressBar(remainPct, barLength, color);
  const pctStr = formatPct(fraction);

  let resetStr = '';
  if (fraction < 0.9999 && qData.reset_in_seconds) {
    const dur = formatDuration(qData.reset_in_seconds);
    if (dur) resetStr = ` ${GRAY}(${dur})${RESET}`;
  }

  return `${color}${name}${RESET} ${bar} ${color}${pctStr}残${RESET}${resetStr}`;
}

let line2 = '';
const quota = input.quota;
if (quota && typeof quota === 'object') {
  const quotaParts = [];

  // 1. GEMINI MODELS (Gemini Flash, Gemini Pro)
  const g5h = formatQuotaItem('💎 Gemini 5h', quota['gemini-5h'], 10);
  const gWk = formatQuotaItem('💎 Gemini 週', quota['gemini-weekly'], 10);
  if (g5h) quotaParts.push(g5h);
  if (gWk) quotaParts.push(gWk);

  // 2. CLAUDE AND GPT MODELS (Claude Opus, Claude Sonnet, GPT-OSS)
  const cg5h = formatQuotaItem('🔮 Claude/GPT 5h', quota['3p-5h'], 10);
  const cgWk = formatQuotaItem('🔮 Claude/GPT 週', quota['3p-weekly'], 10);
  if (cg5h) quotaParts.push(cg5h);
  if (cgWk) quotaParts.push(cgWk);

  if (quotaParts.length > 0) {
    line2 = quotaParts.join(sep);
  }
}

// ── Line 3: Subagents / 追加情報 ──
let line3 = '';
const infoParts = [];

// プランティア
if (input.plan_tier) {
  infoParts.push(`${CYAN}🏷️ ${input.plan_tier}${RESET}`);
}

// サブエージェント情報
const subagents = input.subagents;
if (Array.isArray(subagents) && subagents.length > 0) {
  const running = subagents.filter(s => s.status !== 'completed' && s.status !== 'killed').length;
  const completed = subagents.filter(s => s.status === 'completed').length;
  if (running > 0) {
    infoParts.push(`${YELLOW}🔄 サブエージェント: ${running}実行中 / ${completed}完了${RESET}`);
  } else if (completed > 0) {
    infoParts.push(`${GREEN}✅ サブエージェント: ${completed}完了${RESET}`);
  }
}

// アーティファクト数
if (input.artifact_count > 0) {
  infoParts.push(`${GRAY}📎 ${input.artifact_count}件${RESET}`);
}

if (infoParts.length > 0) {
  line3 = infoParts.join(sep);
}

// ── Output ──
let output = line1;
if (line2) output += '\n' + line2;
if (line3) output += '\n' + line3;
process.stdout.write(output);
} catch (err) {
  // エラー時でも exit 1 で落ちずに最低限のステータスを出力
  const modelName = input?.model?.display_name ?? input?.model?.id ?? 'Antigravity';
  process.stdout.write(`🤖 │ ${modelName}`);
  process.exit(0);
}
