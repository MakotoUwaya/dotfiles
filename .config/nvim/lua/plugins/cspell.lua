return {
  'nvimtools/none-ls.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'davidmh/cspell.nvim',
  },
  config = function()
    local null_ls = require('null-ls')
    local cspell = require('cspell')
    null_ls.setup({
      sources = {
        cspell.diagnostics.with({
          diagnostics_postprocess = function(diagnostic)
            diagnostic.severity = vim.diagnostic.severity.HINT
          end,
        }),
        cspell.code_actions,
      },
    })
  end,
}
