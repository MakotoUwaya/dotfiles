return {
  'nvim-telescope/telescope.nvim',
  tag = 'v0.2.1',
  cmd = 'Telescope',
  keys = {
    { '<leader>ff', function() require('telescope.builtin').find_files() end, desc = 'Find Files' },
    { '<leader>fg', function() require('telescope.builtin').live_grep() end, desc = 'Live Grep' },
    { '<leader>fb', function() require('telescope.builtin').buffers() end, desc = 'Buffers' },
    { '<leader>fh', function() require('telescope.builtin').help_tags() end, desc = 'Help Tags' },
  },
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
  end,
}
