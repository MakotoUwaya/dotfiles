// Antigravity CLI (agy) Statusline - cross-platform (Node.js ESM)
// Display: agent info, model, quota, git status, directory

import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
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
const PURPLE = '\x1b[38;2;198;120;221m';
const RESET = '\x1b[0m';

function colorForPct(pct) {
  if (pct >= 80) return RED;
  if (pct >= 50) return YELLOW;
  return GREEN;
}

function progressBar(pct, total = 14, color = '') {
  let filled = Math.round((pct * total) / 100);
  if (filled > total) filled = total;
  if (!color) color = colorForPct(pct);

  let bar = '';
  for (let i = 0; i < total; i++) {
    const seg = i < filled ? '█' : '░';
    bar += `${color}${seg}${RESET}`;
  }
  return bar;
}

// ── Line 1: Session info ──
const agentName = input.agent?.name ?? input.agent_name ?? '';
const model = input.model?.name ?? input.model ?? '';
const projectId = input.project?.id ?? input.project_id ?? '';
const conversationId = input.conversation?.id ?? input.conversation_id ?? '';

// Context window
const contextUsed = input.context?.used ?? input.context_used ?? 0;
const contextLimit = input.context?.limit ?? input.context_limit ?? 0;
const contextPct = contextLimit > 0 ? Math.round((contextUsed / contextLimit) * 100) : 0;
const contextColor = colorForPct(contextPct);

// Workspace
const cwd = input.workspace?.current_dir ?? input.cwd ?? '';

// Git info
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

let line1 = '';
if (agentName) {
  line1 += `${PURPLE}🤖 ${agentName}${RESET}${sep}`;
}
line1 += `${BLUE}${model}${RESET}`;

if (contextLimit > 0) {
  line1 += `${sep}${contextColor}📊 ${contextPct}%${RESET} (${contextUsed}/${contextLimit})`;
}

if (gitRepo && gitBranch) {
  line1 += `${sep}📦 ${gitRepo} 🔀 ${gitBranch}`;
} else if (gitRepo) {
  line1 += `${sep}📦 ${gitRepo}`;
} else if (gitBranch) {
  line1 += `${sep}🔀 ${gitBranch}`;
}

if (dirDisplay) {
  line1 += `${sep}📁 ${dirDisplay}`;
}

// ── Line 2: Quota (if available) ──
let line2 = '';
const quota = input.quota ?? input.usage?.quota;
if (quota) {
  const used = quota.used ?? 0;
  const limit = quota.limit ?? 0;
  const remaining = quota.remaining ?? (limit - used);
  
  if (limit > 0) {
    const quotaPct = Math.round((used / limit) * 100);
    const remainingPct = Math.round((remaining / limit) * 100);
    const quotaColor = colorForPct(quotaPct);
    const quotaBar = progressBar(quotaPct, 30, quotaColor);
    
    const resetAt = quota.reset_at ?? quota.resets_at;
    let resetStr = '';
    if (resetAt) {
      try {
        const d = new Date(resetAt);
        if (!isNaN(d.getTime())) {
          const diff = d.getTime() - Date.now();
          const hours = Math.floor(diff / 3_600_000);
          const minutes = Math.floor((diff % 3_600_000) / 60_000);
          if (hours > 0 && minutes > 0) {
            resetStr = `  ${GRAY}リセット: あと${hours}時間${minutes}分${RESET}`;
          } else if (hours > 0) {
            resetStr = `  ${GRAY}リセット: あと${hours}時間${RESET}`;
          } else if (minutes > 0) {
            resetStr = `  ${GRAY}リセット: あと${minutes}分${RESET}`;
          } else {
            resetStr = `  ${GRAY}リセット: まもなく${RESET}`;
          }
        }
      } catch {}
    }
    
    line2 = `${quotaColor}📈 Quota${RESET} ${quotaBar} ${quotaColor}${used}/${limit}${RESET} (${remainingPct}% 残)${resetStr}`;
  }
}

// ── Line 3: Token usage (if available) ──
let line3 = '';
const tokens = input.tokens ?? input.usage?.tokens;
if (tokens) {
  const inputTokens = tokens.input ?? tokens.prompt ?? 0;
  const outputTokens = tokens.output ?? tokens.completion ?? 0;
  const totalTokens = tokens.total ?? (inputTokens + outputTokens);
  
  if (totalTokens > 0) {
    line3 = `${GRAY}🔢 Tokens: ↓${inputTokens.toLocaleString()} ↑${outputTokens.toLocaleString()} 合計${totalTokens.toLocaleString()}${RESET}`;
  }
}

// ── Output ──
let output = line1;
if (line2) output += '\n' + line2;
if (line3) output += '\n' + line3;
process.stdout.write(output);
