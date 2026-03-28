import {
  BoxRenderable,
  TextRenderable,
  type CliRenderer,
  type KeyEvent,
} from "@opentui/core";
import type { DbTarget, AccessMode } from "../db-config.js";
import { CATEGORY_LABELS, CATEGORY_ORDER, getPort } from "../db-config.js";

export interface MultiSelectResult {
  selected: DbTarget[];
  cancelled: boolean;
}

interface GroupedTargets {
  category: string;
  label: string;
  targets: DbTarget[];
}

function groupByCategory(targets: DbTarget[]): GroupedTargets[] {
  const map = new Map<string, DbTarget[]>();
  for (const t of targets) {
    const cat = t.entry.category;
    if (!map.has(cat)) map.set(cat, []);
    map.get(cat)!.push(t);
  }
  return CATEGORY_ORDER.filter((cat) => map.has(cat)).map((cat) => ({
    category: cat,
    label: CATEGORY_LABELS[cat] ?? cat,
    targets: map.get(cat)!,
  }));
}

interface FlatItem {
  type: "header" | "item";
  label: string;
  target?: DbTarget;
  port?: number;
  apiInfo?: string;
}

function buildFlatList(
  groups: GroupedTargets[],
  mode: AccessMode
): FlatItem[] {
  const items: FlatItem[] = [];
  for (const group of groups) {
    items.push({ type: "header", label: `── ${group.label} ──` });
    for (const t of group.targets) {
      const port = getPort(t, mode);
      const apiInfo = t.entry.apiList
        ? `(${t.entry.apiList.join(", ")})`
        : "";
      items.push({
        type: "item",
        label: t.entry.name,
        target: t,
        port,
        apiInfo,
      });
    }
  }
  return items;
}

function filterItems(allItems: FlatItem[], filter: string): FlatItem[] {
  if (!filter) return allItems;
  const lower = filter.toLowerCase();
  const result: FlatItem[] = [];
  let pendingHeader: FlatItem | null = null;

  for (const item of allItems) {
    if (item.type === "header") {
      pendingHeader = item;
      continue;
    }
    const matches =
      item.label.toLowerCase().includes(lower) ||
      (item.apiInfo ?? "").toLowerCase().includes(lower);
    if (matches) {
      if (pendingHeader) {
        result.push(pendingHeader);
        pendingHeader = null;
      }
      result.push(item);
    }
  }
  return result;
}

export async function showMultiSelect(
  renderer: CliRenderer,
  targets: DbTarget[],
  mode: AccessMode
): Promise<MultiSelectResult> {
  const groups = groupByCategory(targets);
  const allItems = buildFlatList(groups, mode);
  let visibleItems = allItems;
  const selected = new Set<string>();
  let cursor = 0;
  let scrollOffset = 0;
  let filterMode = false;
  let filterText = "";

  // ヘッダ(1) + ヘルプ(1) + フィルタ(1) + ボーダー(2) + カウント(1) + ステータスライン等余白(2) = 8行分
  const CHROME_LINES = 8;

  function getViewportHeight(): number {
    return Math.max(5, renderer.terminalHeight - CHROME_LINES);
  }

  function adjustCursor() {
    while (
      cursor < visibleItems.length &&
      visibleItems[cursor].type === "header"
    ) {
      cursor++;
    }
    if (cursor >= visibleItems.length) {
      for (let i = visibleItems.length - 1; i >= 0; i--) {
        if (visibleItems[i].type === "item") {
          cursor = i;
          return;
        }
      }
    }
  }

  function adjustScroll() {
    const vh = getViewportHeight();
    // カーソルがビューポートより下にある場合、スクロールダウン
    if (cursor >= scrollOffset + vh) {
      scrollOffset = cursor - vh + 1;
    }
    // カーソルがビューポートより上にある場合、スクロールアップ
    if (cursor < scrollOffset) {
      scrollOffset = cursor;
    }
    // ヘッダ行がカーソルの直前にある場合、ヘッダも表示する
    if (cursor > 0 && visibleItems[cursor - 1]?.type === "header" && cursor - 1 < scrollOffset) {
      scrollOffset = cursor - 1;
    }
    // scrollOffset の上限
    const maxOffset = Math.max(0, visibleItems.length - vh);
    scrollOffset = Math.min(scrollOffset, maxOffset);
    scrollOffset = Math.max(0, scrollOffset);
  }

  function getSelectableItems(): FlatItem[] {
    return visibleItems.filter((i) => i.type === "item");
  }

  function moveCursor(direction: number) {
    let next = cursor + direction;
    while (
      next >= 0 &&
      next < visibleItems.length &&
      visibleItems[next].type === "header"
    ) {
      next += direction;
    }
    if (next >= 0 && next < visibleItems.length) {
      cursor = next;
    }
    adjustScroll();
  }

  function toggleCurrent() {
    const item = visibleItems[cursor];
    if (item?.type !== "item" || !item.target) return;
    const key = item.target.entry.name;
    if (selected.has(key)) {
      selected.delete(key);
    } else {
      selected.add(key);
    }
  }

  function toggleAll() {
    const selectable = getSelectableItems();
    const allSelected = selectable.every(
      (i) => i.target && selected.has(i.target.entry.name)
    );
    if (allSelected) {
      for (const i of selectable) {
        if (i.target) selected.delete(i.target.entry.name);
      }
    } else {
      for (const i of selectable) {
        if (i.target) selected.add(i.target.entry.name);
      }
    }
  }

  function applyFilter() {
    visibleItems = filterItems(allItems, filterText);
    cursor = 0;
    scrollOffset = 0;
    adjustCursor();
    adjustScroll();
  }

  // 全角文字を考慮した表示幅を計算
  function displayWidth(str: string): number {
    let w = 0;
    for (const ch of str) {
      const cp = ch.codePointAt(0) ?? 0;
      // CJK統合漢字、ひらがな、カタカナ、全角記号、CJK記号等
      if (
        (cp >= 0x1100 && cp <= 0x115f) || // Hangul Jamo
        (cp >= 0x2e80 && cp <= 0x303e) || // CJK Radicals, Kangxi, CJK Symbols
        (cp >= 0x3040 && cp <= 0x33bf) || // Hiragana, Katakana, CJK Compat
        (cp >= 0x3400 && cp <= 0x4dbf) || // CJK Unified Ext A
        (cp >= 0x4e00 && cp <= 0xa4cf) || // CJK Unified, Yi
        (cp >= 0xac00 && cp <= 0xd7af) || // Hangul Syllables
        (cp >= 0xf900 && cp <= 0xfaff) || // CJK Compat Ideographs
        (cp >= 0xfe30 && cp <= 0xfe6f) || // CJK Compat Forms
        (cp >= 0xff01 && cp <= 0xff60) || // Fullwidth Forms
        (cp >= 0xffe0 && cp <= 0xffe6) || // Fullwidth Signs
        (cp >= 0x20000 && cp <= 0x2ffff)  // CJK Ext B-F
      ) {
        w += 2;
      } else {
        w += 1;
      }
    }
    return w;
  }

  // 表示幅ベースで切り詰め
  function truncate(str: string, maxCols: number): string {
    let w = 0;
    let i = 0;
    for (const ch of str) {
      const cp = ch.codePointAt(0) ?? 0;
      const cw =
        (cp >= 0x1100 && cp <= 0x115f) ||
        (cp >= 0x2e80 && cp <= 0x303e) ||
        (cp >= 0x3040 && cp <= 0x33bf) ||
        (cp >= 0x3400 && cp <= 0x4dbf) ||
        (cp >= 0x4e00 && cp <= 0xa4cf) ||
        (cp >= 0xac00 && cp <= 0xd7af) ||
        (cp >= 0xf900 && cp <= 0xfaff) ||
        (cp >= 0xfe30 && cp <= 0xfe6f) ||
        (cp >= 0xff01 && cp <= 0xff60) ||
        (cp >= 0xffe0 && cp <= 0xffe6) ||
        (cp >= 0x20000 && cp <= 0x2ffff)
          ? 2
          : 1;
      if (w + cw > maxCols - 1) {
        return str.slice(0, i) + "…";
      }
      w += cw;
      i += ch.length;
    }
    return str;
  }

  // 表示幅ベースでパディング
  function padEndCols(str: string, cols: number): string {
    const w = displayWidth(str);
    const pad = Math.max(0, cols - w);
    return str + " ".repeat(pad);
  }

  function buildScrollbar(viewportLines: number): string[] {
    const total = visibleItems.length;
    if (total <= viewportLines) {
      return Array(viewportLines).fill(" ");
    }
    const thumbSize = Math.max(1, Math.round((viewportLines / total) * viewportLines));
    const maxOffset = total - viewportLines;
    const thumbPos = Math.round((scrollOffset / maxOffset) * (viewportLines - thumbSize));
    return Array.from({ length: viewportLines }, (_, i) =>
      i >= thumbPos && i < thumbPos + thumbSize ? "█" : "│"
    );
  }

  function renderList(): string {
    const vh = getViewportHeight();
    const tw = renderer.terminalWidth;
    const hasScrollbar = visibleItems.length > vh;
    // スクロールバー分 (2文字: スペース + バー) を確保
    const contentWidth = hasScrollbar ? tw - 2 : tw;
    const lines: string[] = [];
    const end = Math.min(scrollOffset + vh, visibleItems.length);

    // 幅に応じて DB 名のカラム幅を調整
    const nameWidth = Math.max(15, Math.min(30, contentWidth - 25));
    const portWidth = 7;
    // API リスト表示に使える残り幅
    const fixedCols = 2 + 3 + 1 + nameWidth + 1 + portWidth; // "> [x] name port"
    const apiMaxLen = Math.max(0, contentWidth - fixedCols - 1);

    const rawLines: string[] = [];
    for (let i = scrollOffset; i < end; i++) {
      const item = visibleItems[i];
      if (item.type === "header") {
        rawLines.push(truncate(`  ${item.label}`, contentWidth));
        continue;
      }
      const isSelected =
        item.target && selected.has(item.target.entry.name);
      const isCursor = i === cursor;
      const checkbox = isSelected ? "[x]" : "[ ]";
      const pointer = isCursor ? ">" : " ";
      const name = item.label.padEnd(nameWidth).slice(0, nameWidth);
      const port = String(item.port ?? "").padStart(portWidth);
      const base = `${pointer} ${checkbox} ${name} ${port}`;
      const api =
        item.apiInfo && apiMaxLen > 3
          ? ` ${truncate(item.apiInfo, apiMaxLen)}`
          : "";
      rawLines.push(truncate(`${base}${api}`, contentWidth));
    }

    if (hasScrollbar) {
      const scrollbar = buildScrollbar(vh);
      for (let i = 0; i < vh; i++) {
        const bar = scrollbar[i] ?? "│";
        const raw = rawLines[i] ?? "";
        lines.push(`${padEndCols(raw, contentWidth)} ${bar}`);
      }
    } else {
      lines.push(...rawLines);
    }

    return lines.join("\n");
  }

  adjustCursor();
  adjustScroll();

  return new Promise<MultiSelectResult>((resolve) => {
    const container = new BoxRenderable(renderer, {
      flexDirection: "column",
      width: "100%",
      height: "100%",
    });

    const title = new TextRenderable(renderer, {
      content: "DB 接続先を選択してください",
      fg: "#00FF00",
    });

    const helpFull =
      "↑↓/jk:移動  Space:選択  a:全選択  /:フィルタ  Enter:確定  q:終了";
    const helpShort = "↑↓:移動 Space:選択 a:全 /:検索 Enter:確定 q:終了";
    const helpText = new TextRenderable(renderer, {
      content: renderer.terminalWidth < 65 ? helpShort : helpFull,
      fg: "#888888",
    });

    const filterDisplay = new TextRenderable(renderer, {
      content: "",
      fg: "#FFFF00",
    });

    const listText = new TextRenderable(renderer, {
      content: renderList(),
      fg: "#FFFFFF",
    });

    const countText = new TextRenderable(renderer, {
      content: `選択: ${selected.size} 件`,
      fg: "#00CCFF",
    });

    container.add(title);
    container.add(helpText);
    container.add(filterDisplay);
    container.add(listText);
    container.add(countText);
    renderer.root.add(container);

    function update() {
      listText.content = renderList();
      countText.content = `選択: ${selected.size} 件`;
      filterDisplay.content = filterMode
        ? `フィルタ: ${filterText}█`
        : filterText
          ? `フィルタ: ${filterText} (Esc でクリア)`
          : "";
    }

    function cleanup() {
      renderer.root.remove(container.id);
      renderer.keyInput.off("keypress", onKeypress);
    }

    function onKeypress(key: KeyEvent) {
      if (filterMode) {
        if (key.name === "return") {
          filterMode = false;
          update();
          return;
        }
        if (key.name === "escape") {
          filterMode = false;
          filterText = "";
          applyFilter();
          update();
          return;
        }
        if (key.name === "backspace") {
          filterText = filterText.slice(0, -1);
          applyFilter();
          update();
          return;
        }
        if (
          key.sequence.length === 1 &&
          key.sequence >= " " &&
          !key.ctrl &&
          !key.meta
        ) {
          filterText += key.sequence;
          applyFilter();
          update();
        }
        return;
      }

      switch (key.name) {
        case "up":
        case "k":
          moveCursor(-1);
          update();
          break;
        case "down":
        case "j":
          moveCursor(1);
          update();
          break;
        case "space":
          toggleCurrent();
          moveCursor(1);
          update();
          break;
        case "a":
          toggleAll();
          update();
          break;
        case "/":
          filterMode = true;
          update();
          break;
        case "escape":
          if (filterText) {
            filterText = "";
            applyFilter();
            update();
          } else {
            cleanup();
            resolve({ selected: [], cancelled: true });
          }
          break;
        case "q":
          cleanup();
          resolve({ selected: [], cancelled: true });
          break;
        case "return": {
          const result = targets.filter((t) =>
            selected.has(t.entry.name)
          );
          cleanup();
          resolve({ selected: result, cancelled: false });
          break;
        }
      }
    }

    renderer.keyInput.on("keypress", onKeypress);
    update();
  });
}
