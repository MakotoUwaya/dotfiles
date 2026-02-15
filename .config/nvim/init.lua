-- Neovim の Python provider を無効化（LSP とは別の仕組みで、今回不要）
vim.g.loaded_python3_provider = 0

-- mise 管理のツールを PATH に追加（Mason 等が参照できるようにする）
-- Windows では shim が壊れるため、mise bin-paths で実際のバイナリパスを使う
local sep = vim.fn.has('win32') == 1 and ';' or ':'
if vim.fn.has('win32') == 1 then
  local mise_path = vim.fn.exepath('mise')
  if mise_path ~= '' then
    local bin_paths = vim.fn.system('"' .. mise_path .. '" bin-paths')
    if vim.v.shell_error == 0 then
      -- bin-paths を逆順に prepend して元の順序を維持する
      local paths = {}
      for path in bin_paths:gmatch('[^\r\n]+') do
        table.insert(paths, path)
      end
      for i = #paths, 1, -1 do
        vim.env.PATH = paths[i] .. sep .. vim.env.PATH
      end
    end
  end
else
  local mise_shims = vim.fn.expand('$HOME/.local/share/mise/shims')
  if vim.fn.isdirectory(mise_shims) == 1 then
    vim.env.PATH = mise_shims .. sep .. vim.env.PATH
  end
end

require('config.lazy')

vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.wrap = false
vim.opt.laststatus = 3
vim.opt.clipboard = "unnamedplus"

local keymap = vim.keymap

-- window
keymap.set('n', '<leader>sh', '<cmd>split<CR><C-w>w', { desc = 'Splits horizontal', noremap = true })
keymap.set('n', '<leader>sv', '<cmd>vsplit<CR><C-w>w', { desc = 'Splits vertical', noremap = true })
keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Navigate left' })
keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Navigate down' })
keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Navigate up' })
keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Navigate right' })
keymap.set('n', '<C-Up>', '<cmd>resize -3<CR>')
keymap.set('n', '<C-Down>', '<cmd>resize +3<CR>')
keymap.set('n', '<C-Left>', '<cmd>vertical resize -3<CR>')
keymap.set('n', '<C-Right>', '<cmd>vertical resize +3<CR>')

keymap.set('n', '<leader>w', '<cmd>w<CR>', { desc = 'Save file' })
keymap.set('n', '<leader>q', '<cmd>q<CR>', { desc = 'Quit Neovim' })
keymap.set('n', '<C-a>', 'gg<S-v>G', { desc = 'Select all', noremap = true })
keymap.set('n', '<C-b>', '<cmd>Neotree reveal<CR>', { desc = 'Open Neotree', noremap = true })

keymap.set('i', 'jk', '<ESC>', { desc = 'jk to ESC', noremap = true })

-- barbar
keymap.set('n', '<Tab>', '<cmd>BufferNext<CR>', { desc = 'Move to next tab', noremap = true })
keymap.set('n', '<S-Tab>', '<cmd>BufferPrevious<CR>', { desc = 'Move to previous tab', noremap = true })
keymap.set('n', '<leader>x', '<cmd>BufferClose<CR>', { desc = 'Buffer close', noremap = true })
keymap.set('n', '<A-p>', '<cmd>BufferPin<CR>', { desc = 'Pin buffer', noremap = true })
