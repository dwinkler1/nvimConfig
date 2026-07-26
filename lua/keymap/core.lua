local Config = require('config')

-- Basic mappings =============================================================
-- NOTE: Most basic mappings come from 'mini.basics'
-- Shorter version of the most frequent way of going outside of terminal window
vim.keymap.set('t', '<C-h>', [[<C-\><C-N><C-w>h]])
-- Select all
-- vim.keymap.set({ "n", "v", "x" }, "<C-a>", "gg3vG$", { noremap = true, silent = true, desc = "Select all" })
-- Escape deletes highlights
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
-- Paste before/after linewise
local cmd = vim.fn.has('nvim-0.12') == 1 and 'iput' or 'put'
vim.keymap.set({ 'n', 'x' }, '[p', '<Cmd>exe "' .. cmd .. '! " . v:register<CR>', { desc = 'Paste Above' })
vim.keymap.set({ 'n', 'x' }, ']p', '<Cmd>exe "' .. cmd .. ' "  . v:register<CR>', { desc = 'Paste Below' })

vim.keymap.set({ "n", "v", "x" }, "<leader>p", '"+p', { noremap = true, silent = true, desc = "Paste from clipboard" })
vim.keymap.set({ "n", "v", "x" }, "<leader>y", '"+y', { noremap = true, silent = true, desc = "Copy toclipboard" })

-- Create global tables with information about clue group in certain modes
-- Structure of tables is taken to be compatible with 'mini.clue'.
Config.leader_group_clues = {
  { mode = 'n', keys = '<Leader>a',  desc = '+AI' },
  { mode = 'n', keys = '<Leader>b',  desc = '+Buffer' },
  { mode = 'n', keys = '<Leader>e',  desc = '+Explore' },
  { mode = 'n', keys = '<Leader>f',  desc = '+Find' },
  { mode = 'n', keys = '<Leader>fl', desc = '+LSP' },
  { mode = 'n', keys = '<Leader>fa', desc = '+Git' },
  { mode = 'n', keys = '<Leader>g',  desc = '+Git' },
  { mode = 'n', keys = '<Leader>l',  desc = '+LSP' },
  { mode = 'n', keys = '<Leader>L',  desc = '+Lua/Log' },
  { mode = 'n', keys = '<Leader>o',  desc = '+Other' },
  { mode = 'n', keys = '<Leader>r',  desc = '+R' },
  { mode = 'n', keys = '<Leader>s',  desc = '+Send' },
  { mode = 'n', keys = '<Leader>d',  desc = '+Debug' },
  { mode = 'n', keys = '<Leader>t',  desc = '+Terminal' },
  { mode = 'n', keys = '<Leader>u',  desc = '+UI' },
  { mode = 'n', keys = '<Leader>v',  desc = '+Visits' },
  { mode = 'n', keys = '<Leader>w',  desc = '+Windows' },
  { mode = 'x', keys = '<Leader>l',  desc = '+LSP' },
  { mode = 'x', keys = '<Leader>r',  desc = '+R' },
  { mode = 'n', keys = '<Leader>z',  desc = '+ZK' },
  { mode = 'n', keys = '<Leader>zr', desc = '+Reviews' },
  { mode = 'x', keys = '<leader>a',  desc = '+AI' },
}
