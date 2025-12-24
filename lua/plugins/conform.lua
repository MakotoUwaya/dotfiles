return {
  "stevearc/conform.nvim",
  -- InsertLeave でも実行するため、イベントに InsertLeave を追加
  event = { "BufWritePre", "InsertLeave" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>f",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "",
      desc = "Format buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      javascript = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      html = { "prettier" },
      css = { "prettier" },
      json = { "prettier" },
      xml = { "xmlformatter" },
      xaml = { "xmlformatter" },
    },
    -- 保存時のオートフォーマット設定（既存）
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true,
    },
  },
  -- config 関数を使って InsertLeave の挙動を追加
  config = function(_, opts)
    local conform = require("conform")
    conform.setup(opts)

    -- INSERT モードを抜けた時にフォーマットを実行する autocmd
    vim.api.nvim_create_autocmd("InsertLeave", {
      pattern = "*",
      callback = function()
        conform.format({
          lsp_fallback = true,
          async = true, -- 入力直後のため、非同期で実行して操作を妨げないようにする
        })
      end,
    })
  end,
}

