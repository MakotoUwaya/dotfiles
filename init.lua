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
