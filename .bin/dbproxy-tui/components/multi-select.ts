import {
  BoxRenderable,
  TextRenderable,
  ScrollBoxRenderable,
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
  let filterMode = false;
  let filterText = "";

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
    adjustCursor();
  }

  function renderList(): string {
    const lines: string[] = [];
    const nameWidth = 30;
    const portWidth = 7;

    for (let i = 0; i < visibleItems.length; i++) {
      const item = visibleItems[i];
      if (item.type === "header") {
        lines.push(`  ${item.label}`);
        continue;
      }
      const isSelected =
        item.target && selected.has(item.target.entry.name);
      const isCursor = i === cursor;
      const checkbox = isSelected ? "[x]" : "[ ]";
      const pointer = isCursor ? ">" : " ";
      const name = item.label.padEnd(nameWidth);
      const port = String(item.port ?? "").padStart(portWidth);
      const api = item.apiInfo ? ` ${item.apiInfo}` : "";
      lines.push(`${pointer} ${checkbox} ${name} ${port}${api}`);
    }
    return lines.join("\n");
  }

  adjustCursor();

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

    const helpText = new TextRenderable(renderer, {
      content:
        "↑↓/jk:移動  Space:選択  a:全選択  /:フィルタ  Enter:確定  q:終了",
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

    const scrollBox = new ScrollBoxRenderable(renderer, {
      flexGrow: 1,
      scrollY: true,
      border: true,
      borderStyle: "rounded",
      borderColor: "#444444",
    });
    scrollBox.add(listText);

    container.add(title);
    container.add(helpText);
    container.add(filterDisplay);
    container.add(scrollBox);
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
