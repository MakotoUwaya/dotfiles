---
name: mise-tools-upgrade
description: >-
  mise outdated を起点に dotfiles 管理ツールを安全に更新する。
  Neovim メジャーバージョンアップ時のプラグイン互換性確認、
  `mise upgrade --bump` の major 跨ぎ事故を回避する LTS ピン保護、
  Windows / WSL2 Ubuntu 両対応の検証手順を含む。
  「mise 更新」「ツール更新」「mise upgrade」「neovim アップデート」で使用。
---

# mise tools upgrade

## Overview

dotfiles で `mise` 管理しているツール群を、影響範囲を見極めながら段階的に更新する。
ナイーブに `mise upgrade --bump` を実行すると LTS から非 LTS へ major 跨ぎ更新する事故が起きるため、
事前に影響を分類してユーザーと方針合意してから進める。

特に Neovim はメジャーアップで内部 API / autocmd / 標準機能が変わり、Lua プラグインが破壊されやすい。
本スキルはその確認手順をテンプレ化する。

## When to Use

- 定期メンテナンスで「mise 更新」「ツール更新」と指示された時
- `mise outdated` の結果を見て個別アップデートを進める時
- Neovim / Node / Python / .NET 等のメジャーアップが含まれる時
- 別 PC (Windows / WSL2 Ubuntu) で同じ更新を再現したい時

## Instructions

### Step 0: 対象把握

```bash
mise outdated
```

出力を以下 3 段階に分類:
- **patch / minor**: そのまま進めて問題なし
- **major**: 影響調査必須
- **major.minor が独自意味を持つ言語** (python `3.12`, node `24`, dotnet `10` 等):
  config の pin が partial 指定 (`"3.12"`, `"24"`) なら勝手に major を跨がないが、
  完全指定 (`"24.11.1"`) は `--bump` が major を跨いで書き換える事故源

config の現状を必ず確認:

```bash
cat .config/mise/config.toml
```

### Step 1: メジャーアップの影響調査

major が含まれる場合、以下の順で影響を確認する:

#### Neovim メジャーアップ (例: 0.11 → 0.12)

1. **公式 news.txt** の Breaking Changes を確認:
   - URL: `https://github.com/neovim/neovim/blob/v{X.Y.Z}/runtime/doc/news.txt`
   - 注目セクション: Breaking Changes / Deprecated / API
2. **lazy-lock.json** から現在のプラグイン一覧を抽出し、メジャー影響を受けやすいものを特定:
   - LSP 系: `mason.nvim`, `mason-lspconfig.nvim`, `nvim-lspconfig`
   - 補完: `nvim-cmp` (またはその後継)
   - 構文: `nvim-treesitter` (※2026/04 archive 済み)
   - その他活発なもの: `snacks.nvim`, `noice.nvim`, `gitsigns.nvim`
3. **既知の罠** (本スキル作成時点 / 適宜更新):
   - `nvim-treesitter` (master/main とも) は **archive 済み**。当面 master で動作するが、新パーサ追加なし。0.12+ は組み込み treesitter / `tree-sitter-manager.nvim` への移行が長期方針
   - `mason-lspconfig.nvim v2` で `handlers` / `setup_handlers` が **削除**。`vim.lsp.config()` + `automatic_enable` への移行が必須
   - `mason-org` への repo 移管: `williamboman/mason*.nvim` → `mason-org/mason*.nvim`
   - `copilot-cmp` の `client.is_stopped` (関数呼び出し) は deprecated → `client:is_stopped` (メソッド) に。Nvim 0.13 で削除予定。warning だけなら当面放置可
   - `vim.diff` → `vim.text.diff` リネーム
   - `vim.lsp.semantic_tokens.start/stop` → `enable` に統一

#### Node / Python / .NET メジャーアップ

- **node**: LTS は偶数 major (24, 26, …)。奇数は current (短命)。LTS 維持なら toml は `node = "24"` のように major 指定で固定
- **python**: tool 互換性 (basedpyright / ruff 等) が遅れることがある。`"3.12"` 等の major.minor pin を維持
- **.NET**: dotnet SDK は major pin (`"10"`) で OK

### Step 2: 方針合意

`AskUserQuestion` で進行プランを提示する:

- **段階的 (推奨)**: ① Neovim 以外を更新 → ② LSP 設定など必要な config 修正 → ③ Neovim 更新 → ④ 起動確認
- **一気に全部**: 全更新 + 修正をまとめて実施 (まとめてレビュー)
- **Neovim はまだ**: 当面 Neovim 以外だけ更新

Neovim プラグインが archive されている場合は移行方針も別途確認:
- 様子見 (現状維持で動作確認)
- 組み込み機能へ移行
- 後継プラグインへ移行

### Step 3: 更新の実行

#### 個別更新 (推奨: 制御しやすい)

```bash
# 個別ツールを最新化
mise upgrade <tool>...

# 例: Neovim 以外を一括 (Neovim だけは後回し)
mise upgrade $(mise outdated | awk 'NR>1 && $1!="aqua:neovim/neovim"{print $1}')
```

#### 一括更新 (注意)

```bash
# 全ツール最新化 + config の pin も書き換え
mise upgrade --bump
```

**`--bump` の落とし穴**:
- 完全指定 pin (`"24.11.1"`) を最新 specific 版 (`"25.9.0"`) に書き換える
- LTS pin の意図を破壊するので、実行後に `git diff .config/mise/config.toml` で確認し、
  major を跨いだ部分は意図的なら残す / 維持したいなら下記に巻き戻す:
  - node: `"24"` (LTS major のみ)
  - python: `"3.12"` (使用 major.minor)
  - dotnet: `"10"` (LTS major)

#### `mise upgrade` でアセット名違いエラーが出る場合

`pnpm`, `gh` 等で「no asset found: pnpm-win-x64」のようなエラーは aqua レジストリ側のラグ。
当面 config の pin を据え置きにし、エラーは無視する。後日 `mise upgrade <tool>` で再試行。

### Step 4: config 修正 (Neovim メジャーアップ時)

Step 1 の調査結果に応じて Lua プラグイン設定を修正する。
代表的な修正パターン:

#### mason-lspconfig v2 への移行

`v1` の `handlers = {...}` パターンを廃止し、`vim.lsp.config()` + `automatic_enable` に置換:

```lua
-- 旧 (v1)
require('mason-lspconfig').setup({
  ensure_installed = vim.tbl_keys(opts.servers),
  handlers = {
    function(server_name)
      local server_opts = opts.servers[server_name] or {}
      server_opts.capabilities = capabilities
      lspconfig[server_name].setup(server_opts)
    end,
  },
})

-- 新 (v2)
local capabilities = require('cmp_nvim_lsp').default_capabilities()
vim.lsp.config('*', { capabilities = capabilities })

vim.lsp.config('eslint', { settings = { workingDirectories = { mode = 'auto' } } })
-- ... per-server 上書き

require('mason-lspconfig').setup({
  ensure_installed = { 'lua_ls', 'ts_ls', ... },
  automatic_enable = true,
})
```

repo 移管も同時に:
- `'williamboman/mason.nvim'` → `'mason-org/mason.nvim'`
- `'williamboman/mason-lspconfig.nvim'` → `'mason-org/mason-lspconfig.nvim'`

### Step 5: 動作確認

#### ヘッドレス起動チェック (CI 的)

新 Neovim は mise インストール直後だとシェルの PATH キャッシュに乗っていない。
`mise where` でフルパスを取得して直接実行する。

**Windows (Git Bash):**
```bash
NVIM=$(mise where aqua:neovim/neovim)/nvim-win64/bin/nvim.exe
"$NVIM" --version | head -2
```

**WSL2 / Ubuntu:**
```bash
NVIM=$(mise where aqua:neovim/neovim)/nvim-linux64/bin/nvim
"$NVIM" --version | head -2
```

プラグイン全 load + messages dump (両 OS 共通):

```bash
cat > "$TEMP/dump.lua" <<'EOF'
vim.cmd('Lazy! load all')
vim.defer_fn(function()
  local msgs = vim.api.nvim_exec2('messages', {output=true}).output
  vim.fn.writefile(vim.split(msgs, '\n', {plain=true}), os.getenv('TEMP')..'/nvim_msgs.txt')
  vim.cmd('qa!')
end, 8000)
EOF
"$NVIM" --headless -S "$TEMP/dump.lua"
cat "$TEMP/nvim_msgs.txt"
```

WSL2 では `$TEMP` の代わりに `/tmp` を使う。

警告がある場合の絞り込み:

```vim
:checkhealth vim.deprecated
```

#### 対話確認 (LSP attach は対話推奨)

ヘッドレスでは mason の PATH 反映タイミングで LSP client が attach しないことがある。
**LSP の最終確認は対話モードでユーザーが行う**:

1. `nvim` を普通に起動
2. `:Lazy sync` でプラグイン最新化
3. `:checkhealth` で warning/error 把握
4. 普段使うファイルを開いて:
   - `:lua =vim.lsp.get_clients()` で LSP attach 確認
   - 補完 (nvim-cmp) が効くか
   - syntax highlight (treesitter) が効くか

`AskUserQuestion` で対話確認を依頼するか、Claude 側で続けて headless で粘るかをユーザーに選択させる。

### Step 6: コミット

gitmoji スタイルで分割コミット (CLAUDE.md / AGENTS.md の規約):

- `📦️ Update mise tools to latest`: ツール更新だけ
- `🔧 Pin <tool> to <version>`: pin 戻し系
- `♻️ Migrate <plugin> to <new API>`: API 移行に伴う Lua 修正
- `📝 Update lazy-lock.json`: ロックファイル更新

**重要**: `git add` と `git commit` は別コマンド (`.config/claude-code/rules/git.md` の規約)。
git 操作は **直列**、サブエージェントには委任しない。

### Step 7: 他 PC 反映時の参考メモ

最初の PC で本スキルを完走したあと、他 PC でやる時の差分:

- mise config (`.config/mise/config.toml`) は dotfiles 同期で反映済み → `mise install` だけで完了
- Lua 設定も dotfiles 同期で反映済み
- 各 PC で `:Lazy sync` と動作確認だけ実施すればよい

ただし、各 PC ごとに mason インストール済みサーバーが微妙に違う可能性があるため、
`:Mason` で確認してから運用に戻ること。

## Examples

### 典型的なフロー (本スキル初回適用時の実例)

```
ユーザー: mise outdated でピックアップされているライブラリをバージョンアップしていきたい。
         Neovim プラグインが 0.12.x に追従しているか確認したい。

Claude:
  1. mise outdated 実行 → 26 件、うち Neovim が 0.11.6 → 0.12.2 で major up
  2. news.txt 調査 → vim.diff rename, mason-lspconfig v2 handlers 削除等
  3. lazy-lock.json から mason / treesitter 確認 → mason-lspconfig v2 を既にインストール済 (現状の handlers 設定が無効化されている疑い)
  4. AskUserQuestion: 段階的 (推奨) を選択。treesitter は様子見
  5. mise upgrade --bump → 完了。ただし node が 24.11.1 → 25.9.0 に major 跨ぎ。pnpm はアセット名違いで失敗
  6. node を "24" に戻し、pnpm はそのまま据え置き
  7. lspconfig.lua を v2 API に書き換え (handlers → vim.lsp.config + automatic_enable)
  8. ヘッドレス起動: 警告は client.is_stopped の 1 件のみ (copilot-cmp 内部、許容)
  9. 対話確認をユーザーに依頼 → :Lazy sync で 35/35 plugins up to date、Mason v2.2.1 で 17 サーバー installed 確認
  10. 2 コミットに分割 (🔧 node pin / ♻️ lspconfig v2 移行)
  11. /difit でレビュー → push は保留
```

## Guidelines

- **`mise upgrade --bump` の前に必ずユーザー確認**。LTS pin 方針 (node, python, dotnet) を質問してから実行する
- **major 跨ぎを git diff で目視確認**。意図しない上げを発見したら即戻す
- **Neovim 更新と Lua 設定修正は同一コミットにしない**。原因切り分けが効くよう分割する
- **LSP attach の最終確認は対話モード**。ヘッドレスは PATH 反映タイミングで嘘の結果が出ることがある
- **新 Neovim を `nvim` コマンドで叩こうとして PATH キャッシュに引っかかったら**、`mise where` のフルパスで直接実行する
- **archive されたプラグインを発見したら**、まず動作するかを試し、エラーが出るまで対応を強制しない (今回の treesitter 様子見方針)
- **scripting-guide スキル** (`.config/claude-code/skills/scripting-guide`) の規約に従い、繰り返し使うスクリプトは静的ファイル化する。今のところ本スキルは固有スクリプトを持たない (将来的に news.txt 取得の自動化等が候補)
