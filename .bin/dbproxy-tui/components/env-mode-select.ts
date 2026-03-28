import {
  BoxRenderable,
  TextRenderable,
  type CliRenderer,
  type KeyEvent,
} from "@opentui/core";
import type { Environment, AccessMode } from "../db-config.js";

export interface EnvModeResult {
  env: Environment;
  mode: AccessMode;
  cancelled: boolean;
}

interface SelectItem<T> {
  label: string;
  description: string;
  value: T;
}

function showSingleSelect<T>(
  renderer: CliRenderer,
  title: string,
  items: SelectItem<T>[]
): Promise<{ value: T; cancelled: boolean }> {
  return new Promise((resolve) => {
    let cursor = 0;

    function renderList(): string {
      return items
        .map((item, i) => {
          const pointer = i === cursor ? ">" : " ";
          return `${pointer} ${item.label}  ${item.description}`;
        })
        .join("\n");
    }

    const container = new BoxRenderable(renderer, {
      flexDirection: "column",
      width: "100%",
      padding: 1,
      gap: 1,
    });

    const titleText = new TextRenderable(renderer, {
      content: title,
      fg: "#00FF00",
    });
    const listText = new TextRenderable(renderer, {
      content: renderList(),
      fg: "#FFFFFF",
    });
    const helpText = new TextRenderable(renderer, {
      content: "↑↓/jk:移動  Enter:選択  q:終了",
      fg: "#888888",
    });

    container.add(titleText);
    container.add(listText);
    container.add(helpText);
    renderer.root.add(container);

    function cleanup() {
      renderer.root.remove(container.id);
      renderer.keyInput.off("keypress", onKeypress);
    }

    function onKeypress(key: KeyEvent) {
      switch (key.name) {
        case "up":
        case "k":
          cursor = Math.max(0, cursor - 1);
          listText.content = renderList();
          break;
        case "down":
        case "j":
          cursor = Math.min(items.length - 1, cursor + 1);
          listText.content = renderList();
          break;
        case "return":
          cleanup();
          resolve({ value: items[cursor].value, cancelled: false });
          break;
        case "q":
        case "escape":
          cleanup();
          resolve({ value: items[0].value, cancelled: true });
          break;
      }
    }

    renderer.keyInput.on("keypress", onKeypress);
  });
}

export async function showEnvModeSelect(
  renderer: CliRenderer
): Promise<EnvModeResult> {
  const envResult = await showSingleSelect<Environment>(
    renderer,
    "環境を選択",
    [
      {
        label: "Staging",
        description: "ステージング環境 (stg-dbproxy)",
        value: "staging",
      },
      {
        label: "Production",
        description: "本番環境 (dbproxy) ⚠️",
        value: "production",
      },
    ]
  );

  if (envResult.cancelled) {
    return { env: "staging", mode: "ro", cancelled: true };
  }

  const modeResult = await showSingleSelect<AccessMode>(
    renderer,
    `アクセスモードを選択 [${envResult.value}]`,
    [
      {
        label: "Read-Only",
        description: "読み取り専用 (-ro サフィックス)",
        value: "ro",
      },
      {
        label: "Read-Write",
        description: "読み書き (書き込み DB へ接続)",
        value: "rw",
      },
    ]
  );

  if (modeResult.cancelled) {
    return { env: "staging", mode: "ro", cancelled: true };
  }

  return {
    env: envResult.value,
    mode: modeResult.value,
    cancelled: false,
  };
}
