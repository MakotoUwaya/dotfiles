return {
  'nvim-telescope/telescope.nvim',
  tag = 'v0.2.1',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = function(plugin)
        if vim.fn.has('win32') == 1 then
          -- Windows: zig cc で直接 DLL をビルド（mise 経由で zig がインストール済み）
          -- リスト引数でシェルを回避（shellcmdflag の不整合対策）
          local dir = plugin.dir
          vim.fn.mkdir(dir .. '/build', 'p')
          vim.fn.system({
            'zig', 'cc', '-shared', '-O2',
            '-o', dir .. '/build/libfzf.dll',
            dir .. '/src/fzf.c',
            '-I' .. dir .. '/src',
          })
        else
          vim.fn.system({ 'make', '-C', plugin.dir })
        end
      end,
    },
  },
  config = function()
    require('telescope').load_extension('fzf')
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find Files' })
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live Grep' })
    vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Buffers' })
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help Tags' })
  end
}
