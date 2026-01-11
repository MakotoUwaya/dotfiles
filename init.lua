require("config.lazy")

vim.opt.number = true
vim.opt.wrap = false

local keymap = vim.keymap

-- window
keymap.set('n', '<leader>sh', ':split<Return><C-w>w', { desc = 'Splits horizontal', noremap = true })
keymap.set('n', '<leader>sv', ':vsplit<Return><C-w>w', { desc = 'Splits vertical', noremap = true })
keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Navigate left' })
keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Navigate down' })
keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Navigate up' })
keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Navigate right' })
keymap.set("n", "<C-Up>", ":resize -3<CR>")
keymap.set("n", "<C-Down>", ":resize +3<CR>")
keymap.set("n", "<C-Left>", ":vertical resize -3<CR>")
keymap.set("n", "<C-Right>", ":vertical resize +3<CR>")

keymap.set('n', '<leader>w', ':w<cr>', { desc = 'Save file', remap = true })
keymap.set('n', '<leader>q', ':q<cr>', { desc = 'Quit Neovim', remap = true })
keymap.set('n', '<C-a>', 'gg<S-v>G', { desc = 'Select all', noremap = true })
keymap.set('n', '<C-b>', ':Neotree<cr>', { desc = 'Open Neotree', noremap = true })

keymap.set('i', 'jk', '<ESC>', { desc = 'jk to ESC', noremap = true })

-- barbar
keymap.set("n", "<Tab>", ":BufferNext<CR>", { desc = "Move to next tab", noremap = true })
keymap.set("n", "<S-Tab>", ":BufferPrevious<CR>", { desc = "Move to previous tab", noremap = true })
keymap.set("n", "<leader>x", ":BufferClose<CR>", { desc = "Buffer close", noremap = true })
keymap.set("n", "<A-p>", ":BufferPin<CR>", { desc = "Pin buffer", noremap = true })
