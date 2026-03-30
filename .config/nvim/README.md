# Neovim Config

## Plugins

lazy.nvim で管理しているプラグイン一覧。設定ファイルは `lua/plugins/` 配下。

### 検索・ナビゲーション

| プラグイン | 説明 | キーマップ |
|---|---|---|
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | ファジーファインダー（ファイル検索・全文検索・バッファ切替） | `<leader>ff/fg/fb/fh` |
| [telescope-fzf-native.nvim](https://github.com/nvim-telescope/telescope-fzf-native.nvim) | Telescope の fzf ソーター（高速ファジーマッチ） | - |
| [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) | ファイルツリー（サイドバー） | `<C-b>` |

### LSP・補完・フォーマット

| プラグイン | 説明 | キーマップ |
|---|---|---|
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP クライアント設定 | `gd`, `K`, `<leader>rn/ca`, `[d/]d` |
| [mason.nvim](https://github.com/williamboman/mason.nvim) | LSP サーバー・ツールのインストール管理 | `:Mason` |
| [roslyn.nvim](https://github.com/seblyng/roslyn.nvim) | C# 専用 LSP (Roslyn) | (lspconfig と共通) |
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | 補完エンジン | `<Tab>`, `<CR>`, `<C-Space>` |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | スニペットエンジン | (cmp に統合) |
| [conform.nvim](https://github.com/stevearc/conform.nvim) | コードフォーマッター（保存時自動実行） | `<leader>cf` |
| [lazydev.nvim](https://github.com/folke/lazydev.nvim) | Lua 開発時の Neovim API 補完 | - |

### Git

| プラグイン | 説明 | キーマップ |
|---|---|---|
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git 差分表示・blame・hunk 操作 | `]c/[c`, `<leader>hp/hb/hd` |
| [snacks.nvim](https://github.com/folke/snacks.nvim) | Lazygit 統合 | `<leader>gg` |

### AI

| プラグイン | 説明 | キーマップ |
|---|---|---|
| [copilot.lua](https://github.com/zbirenbaum/copilot.lua) | GitHub Copilot | - |
| [copilot-cmp](https://github.com/zbirenbaum/copilot-cmp) | Copilot → cmp 補完ソース連携 | (cmp に統合) |

### UI

| プラグイン | 説明 | キーマップ |
|---|---|---|
| [barbar.nvim](https://github.com/romgrk/barbar.nvim) | タブ型バッファバー | `<Tab>`, `<S-Tab>`, `<leader>x` |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | ステータスライン | - |
| [noice.nvim](https://github.com/folke/noice.nvim) | コマンドライン・通知 UI の刷新 | - |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | キーマップヘルプ表示 | `<leader>?` |
| [transparent.nvim](https://github.com/xiyaowong/transparent.nvim) | 背景透過 | - |

### シンタックス・言語サポート

| プラグイン | 説明 | キーマップ |
|---|---|---|
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | シンタックスハイライト・構文解析 | - |
| [none-ls.nvim](https://github.com/nvimtools/none-ls.nvim) + [cspell](https://github.com/davidmh/cspell.nvim) | スペルチェック（保存時） | - |
| [Comment.nvim](https://github.com/numToStr/Comment.nvim) | コメントトグル | `gcc`, `gc{motion}` |
| [csvview.nvim](https://github.com/hat0uma/csvview.nvim) | CSV 表示・ナビゲーション | `<Tab>`/`<S-Tab>` (CSV内) |
| [markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) | Markdown ブラウザプレビュー | `<leader>mp` |
