import {
  BoxRenderable,
  TextRenderable,
  type CliRenderer,
  type KeyEvent,
} from "@opentui/core";
import type { DbTarget, Environment, AccessMode } from "../db-config.js";
import { getPort, getServiceName, getNamespace } from "../db-config.js";

export async function showConfirmView(
  renderer: CliRenderer,
  targets: DbTarget[],
  env: Environment,
  mode: AccessMode
): Promise<boolean> {
  const ns = getNamespace(env, mode);
  const envLabel = env === "production" ? "本番" : "ステージング";
  const modeLabel = mode === "ro" ? "読み取り専用" : "読み書き";

  const lines: string[] = [
    `環境:         ${envLabel} (${ns})`,
    `アクセスモード: ${modeLabel}`,
    "",
    `接続先 (${targets.length} 件):`,
    "",
  ];

  const nameWidth = 30;
  const portWidth = 7;
  lines.push(
    `  ${"DB 名".padEnd(nameWidth)} ${"ポート".padStart(portWidth)}  サービス名`
  );
  lines.push(
    `  ${"─".repeat(nameWidth)} ${"─".repeat(portWidth)}  ${"─".repeat(30)}`
  );

  for (const t of targets) {
    const port = getPort(t, mode);
    const svc = getServiceName(t, mode);
    lines.push(
      `  ${t.entry.name.padEnd(nameWidth)} ${String(port).padStart(portWidth)}  ${svc}`
    );
  }

  return new Promise<boolean>((resolve) => {
    const container = new BoxRenderable(renderer, {
      flexDirection: "column",
      width: "100%",
      height: "100%",
      padding: 1,
    });

    const title = new TextRenderable(renderer, {
      content: "接続確認",
      fg: "#00FF00",
    });
    const detail = new TextRenderable(renderer, {
      content: lines.join("\n"),
      fg: "#FFFFFF",
    });
    const help = new TextRenderable(renderer, {
      content: "\nEnter: 接続開始  q: キャンセル",
      fg: "#888888",
    });

    container.add(title);
    container.add(detail);
    container.add(help);
    renderer.root.add(container);

    function cleanup() {
      renderer.root.remove(container.id);
      renderer.keyInput.off("keypress", onKeypress);
    }

    function onKeypress(key: KeyEvent) {
      if (key.name === "return") {
        cleanup();
        resolve(true);
      } else if (key.name === "q" || key.name === "escape") {
        cleanup();
        resolve(false);
      }
    }

    renderer.keyInput.on("keypress", onKeypress);
  });
}
