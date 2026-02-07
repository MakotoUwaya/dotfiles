return {
  'nvim-telescope/telescope.nvim',
  tag = 'v0.2.1',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = function()
        if vim.fn.has('win32') == 1 then
          -- Windows: Visual Studio ジェネレーターを使用（Developer Command Prompt 不要）
          vim.fn.system('cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release -G "Visual Studio 18 2026" -A x64')
          vim.fn.system('cmake --build build --config Release --target install')
        else
          vim.fn.system('make')
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
