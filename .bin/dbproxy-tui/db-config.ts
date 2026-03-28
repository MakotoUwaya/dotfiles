import { readFileSync } from "node:fs";

export interface DbEntry {
  name: string;
  apiList?: string[];
  category: string;
}

export interface DbTarget {
  entry: DbEntry;
  roPort: number;
  rwPort: number;
  roServiceName: string;
  rwServiceName: string;
}

export type Environment = "staging" | "production";
export type AccessMode = "ro" | "rw";

function categorize(name: string): string {
  if (name.startsWith("bukken-") || name.startsWith("stg-bukken-"))
    return "bukken";
  if (name.startsWith("kanri-") || name.startsWith("stg-kanri-"))
    return "kanri";
  if (name.includes("aurora3")) return "aurora3";
  if (name.startsWith("dev-")) return "dev";
  if (name.startsWith("esa-")) return "esa";
  if (name.startsWith("stg-")) return "stg";
  return "core";
}

// README.md のテーブル行をパースする
// 形式: | 13306(ro) 13307(rw) | alert-auth-report-db (alert, auth, report) |
const TABLE_ROW_RE =
  /^\|\s*(\d+)\(ro\)\s+(\d+)\(rw\)\s*\|\s*(.+?)\s*\|$/;

function parseTableRow(
  line: string
): { roPort: number; rwPort: number; name: string; apiList?: string[] } | null {
  const m = line.match(TABLE_ROW_RE);
  if (!m) return null;

  const roPort = parseInt(m[1], 10);
  const rwPort = parseInt(m[2], 10);
  const raw = m[3].trim();

  if (raw === "PADDING") return null;

  // "db-name (api1, api2, ...)" or just "db-name"
  const apiMatch = raw.match(/^(.+?)\s+\(([^)]+)\)$/);
  if (apiMatch) {
    const name = apiMatch[1].trim();
    const apiList = apiMatch[2].split(",").map((s) => s.trim());
    return { roPort, rwPort, name, apiList };
  }

  return { roPort, rwPort, name: raw };
}

interface ParsedEnv {
  label: string;
  targets: DbTarget[];
}

function parseReadme(content: string): { production: ParsedEnv; staging: ParsedEnv } {
  const lines = content.split("\n");
  const envs: ParsedEnv[] = [];
  let currentTargets: DbTarget[] | null = null;
  let currentLabel = "";

  for (const line of lines) {
    // テーブルヘッダ行を検出: "| 本番の公開ポート |" or "| ステージングの公開ポート |"
    if (line.includes("の公開ポート")) {
      if (currentTargets && currentTargets.length > 0) {
        envs.push({ label: currentLabel, targets: currentTargets });
      }
      currentTargets = [];
      currentLabel = line.includes("本番") ? "production" : "staging";
      continue;
    }

    // セパレータ行をスキップ
    if (line.match(/^\|[:\-\s|]+\|$/)) continue;

    if (currentTargets !== null) {
      const parsed = parseTableRow(line);
      if (parsed) {
        currentTargets.push({
          entry: {
            name: parsed.name,
            apiList: parsed.apiList,
            category: categorize(parsed.name),
          },
          roPort: parsed.roPort,
          rwPort: parsed.rwPort,
          roServiceName: `${parsed.name}-ro`,
          rwServiceName: parsed.name,
        });
      } else if (!line.startsWith("|")) {
        // テーブル外の行に到達 → テーブル終了
        envs.push({ label: currentLabel, targets: currentTargets });
        currentTargets = null;
      }
    }
  }

  // 最後のテーブルを追加
  if (currentTargets && currentTargets.length > 0) {
    envs.push({ label: currentLabel, targets: currentTargets });
  }

  const production = envs.find((e) => e.label === "production") ?? {
    label: "production",
    targets: [],
  };
  const staging = envs.find((e) => e.label === "staging") ?? {
    label: "staging",
    targets: [],
  };

  return { production, staging };
}

// README.md のデフォルトパス (dbproxy リポジトリ)
const DEFAULT_README_PATH =
  process.env.DBPROXY_README_PATH ??
  `${process.env.HOME}/ghq/gitlab.com/eseikatsu/ebone-api/one-provisioning/dbproxy/README.md`;

let cachedData: { production: ParsedEnv; staging: ParsedEnv } | null = null;

function loadData(): { production: ParsedEnv; staging: ParsedEnv } {
  if (cachedData) return cachedData;
  const content = readFileSync(DEFAULT_README_PATH, "utf-8");
  cachedData = parseReadme(content);
  return cachedData;
}

export function getTargets(env: Environment): DbTarget[] {
  const data = loadData();
  return env === "production" ? data.production.targets : data.staging.targets;
}

export function getNamespace(env: Environment, mode: AccessMode): string {
  const base = env === "production" ? "dbproxy" : "stg-dbproxy";
  return mode === "ro" ? `${base}-readonly` : base;
}

export function getServiceName(target: DbTarget, mode: AccessMode): string {
  return mode === "ro" ? target.roServiceName : target.rwServiceName;
}

export function getPort(target: DbTarget, mode: AccessMode): number {
  return mode === "ro" ? target.roPort : target.rwPort;
}

export const CATEGORY_LABELS: Record<string, string> = {
  core: "Core DB",
  bukken: "Bukken (物件)",
  kanri: "Kanri (管理)",
  aurora3: "Aurora3 (統合)",
  stg: "Staging",
  dev: "Dev",
  esa: "ESA",
};

export const CATEGORY_ORDER = [
  "core",
  "aurora3",
  "bukken",
  "kanri",
  "stg",
  "dev",
  "esa",
];

export function getReadmePath(): string {
  return DEFAULT_README_PATH;
}
