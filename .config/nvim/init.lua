require('config.lazy')

vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.wrap = false
vim.opt.laststatus = 3

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
