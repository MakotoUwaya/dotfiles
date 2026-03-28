import {
  createCliRenderer,
  BoxRenderable,
  TextRenderable,
  type KeyEvent,
} from "@opentui/core";
import { getTargets, getReadmePath } from "./db-config.js";
import { showEnvModeSelect } from "./components/env-mode-select.js";
import { showMultiSelect } from "./components/multi-select.js";
import { showConfirmView } from "./components/confirm-view.js";
import {
  startPortForwards,
  killAll,
  getStatusSummary,
  type PortForwardProcess,
} from "./port-forward.js";
import { existsSync } from "node:fs";

async function main() {
  const readmePath = getReadmePath();
  if (!existsSync(readmePath)) {
    console.error(`README.md が見つかりません: ${readmePath}`);
    console.error("DBPROXY_README_PATH 環境変数でパスを指定できます");
    process.exit(1);
  }

  const renderer = await createCliRenderer({
    exitOnCtrlC: false,
    useAlternateScreen: true,
  });
  renderer.auto();

  let portForwardProcesses: PortForwardProcess[] = [];

  function cleanupAndExit() {
    killAll(portForwardProcesses);
    renderer.destroy();
    process.exit(0);
  }

  process.on("SIGINT", cleanupAndExit);
  process.on("SIGTERM", cleanupAndExit);

  try {
    // Step 1: Environment & Mode selection
    const envMode = await showEnvModeSelect(renderer);
    if (envMode.cancelled) {
      renderer.destroy();
      return;
    }

    // Step 2: Multi-select DB targets
    const targets = getTargets(envMode.env);
    const selectResult = await showMultiSelect(
      renderer,
      targets,
      envMode.mode
    );
    if (selectResult.cancelled || selectResult.selected.length === 0) {
      renderer.destroy();
      return;
    }

    // Step 3: Confirmation
    const confirmed = await showConfirmView(
      renderer,
      selectResult.selected,
      envMode.env,
      envMode.mode
    );
    if (!confirmed) {
      renderer.destroy();
      return;
    }

    // Step 4: Start port forwarding
    portForwardProcesses = startPortForwards(
      selectResult.selected,
      envMode.env,
      envMode.mode
    );

    // Step 5: Show status view
    const container = new BoxRenderable(renderer, {
      flexDirection: "column",
      width: "100%",
      height: "100%",
      padding: 1,
    });

    const title = new TextRenderable(renderer, {
      content: "DB ポートフォワード接続中",
      fg: "#00FF00",
    });

    const statusText = new TextRenderable(renderer, {
      content: getStatusSummary(portForwardProcesses),
      fg: "#FFFFFF",
    });

    const help = new TextRenderable(renderer, {
      content: "\nq / Ctrl+C: 全接続を切断して終了",
      fg: "#888888",
    });

    container.add(title);
    container.add(statusText);
    container.add(help);
    renderer.root.add(container);

    const updateInterval = setInterval(() => {
      statusText.content = getStatusSummary(portForwardProcesses);
    }, 1000);

    await new Promise<void>((resolve) => {
      function onKeypress(key: KeyEvent) {
        if (key.name === "q" || (key.name === "c" && key.ctrl)) {
          clearInterval(updateInterval);
          renderer.keyInput.off("keypress", onKeypress);
          resolve();
        }
      }
      renderer.keyInput.on("keypress", onKeypress);
    });

    cleanupAndExit();
  } catch (err) {
    killAll(portForwardProcesses);
    renderer.destroy();
    console.error("エラーが発生しました:", err);
    process.exit(1);
  }
}

main();
