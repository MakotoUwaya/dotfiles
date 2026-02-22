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
      debounce = 1500, -- 1.5秒待機してから実行するように設定
      sources = {
        cspell.diagnostics.with({
          method = null_ls.methods.DIAGNOSTICS_ON_SAVE, -- 保存時のみ実行（頻度を下げて負荷を軽減）
          diagnostics_postprocess = function(diagnostic)
            diagnostic.severity = vim.diagnostic.severity.HINT
          end,
        }),
        cspell.code_actions,
      },
    })
  end,
}
