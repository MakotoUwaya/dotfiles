return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre', 'InsertLeave' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>f',
      function()
        require('conform').format({ async = true, lsp_fallback = true })
      end,
      mode = '',
      desc = 'Format buffer',
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { 'stylua' },
      typescript = { 'prettierd', 'prettier', stop_after_first = true },
      typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      javascript = { 'prettierd', 'prettier', stop_after_first = true },
      javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      html = { 'prettier' },
      css = { 'prettier' },
      json = { 'prettier' },
      xml = { 'xmlformatter' },
      xaml = { 'xmlformatter' },
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true,
    },
  },
  config = function(_, opts)
    local conform = require('conform')
    conform.setup(opts)

    vim.api.nvim_create_autocmd('InsertLeave', {
      pattern = '*',
      callback = function(args)
        conform.format({
          bufnr = args.buf,
          lsp_fallback = true,
          async = true,
        })
      end,
    })
  end,
}
