--stylua: ignore start
local later = MiniDeps.later
local now = MiniDeps.now
local nix = require('config.nix')


if not Config.isNixCats then
  now(function()
    MiniDeps.add({ name = "mini.nvim" })
  end)
end

-- Leader key =================================================================
vim.g.mapleader      = ' '
vim.g.maplocalleader = ','
-- General ====================================================================
vim.o.backup         = true                             -- Don't store backup
vim.opt.backupdir    = vim.fn.stdpath('data') .. '/backups'
vim.o.mouse          = 'a'                              -- Enable mouse
vim.o.mousescroll    = 'ver:25,hor:6'                   -- Customize mouse scroll
vim.o.scrolloff      = 8                                -- Lines above and below cursor
vim.o.switchbuf      = 'usetab'                         -- Use already opened buffers when switching
vim.o.writebackup    = true                             -- Don't store backup (better performance)
vim.o.undofile       = true                             -- Enable persistent undo
vim.o.wildmenu       = true                             -- Enable wildmenu
vim.o.wildmode       = 'full'                           -- Show all matches in command line completion

vim.o.shada          = "'100,<50,s10,:1000,/100,@100,h" -- Limit what is stored in ShaDa file

vim.cmd('filetype plugin indent on')                    -- Enable all filetype plugins

-- UI =========================================================================
vim.o.breakindent    = true -- Indent wrapped lines to match line start
vim.o.colorcolumn    = '+1' -- Draw colored column one step to the right of desired maximum width
vim.o.cursorline     = false -- Enable highlighting of the current line
vim.o.foldenable     = false -- Enable folding
vim.o.linebreak      = true -- Wrap long lines at 'breakat' (if 'wrap' is set)
vim.o.list           = true -- Show helpful character indicators
vim.o.number         = true -- Show line numbers
vim.o.pumheight      = 10 -- Make popup menu smaller
vim.o.relativenumber = true -- Show relative line numbers
vim.o.ruler          = false -- Don't show cursor position
vim.o.shortmess      = 'FOSWaco' -- Disable certain messages from |ins-completion-menu|
vim.o.showmode       = false -- Don't show mode in command line
vim.o.signcolumn     = 'yes' -- Always show signcolumn or it would frequently shift
vim.o.splitbelow     = true -- Horizontal splits will be below
vim.o.splitright     = true -- Vertical splits will be to the right
vim.o.wrap           = true -- Display long lines as just one line
vim.o.background     = nix.get_setting('dark', "background") --'light' -- Set background

vim.o.listchars      = table.concat({ 'extends:…', 'nbsp:␣', 'precedes:…', 'tab:> ', 'trail:·' }, ',') -- Special text symbols
vim.o.cursorlineopt  = 'screenline,number' -- Show cursor line only screen line when wrapped
vim.o.breakindentopt = 'list:-1' -- Add padding for lists when 'wrap' is on

if vim.fn.has('nvim-0.9') == 1 then
  vim.o.shortmess = 'CFOSWaco' -- Don't show "Scanning..." messages
  vim.o.splitkeep = 'screen'   -- Reduce scroll during window split
end

if vim.fn.has('nvim-0.10') == 0 then
  vim.o.termguicolors = true -- Enable gui colors (Neovim>=0.10 does this automatically)
end

if vim.fn.has('nvim-0.11') == 1 then
  --  vim.o.completeopt = 'menuone,fuzzy' -- Use fuzzy matching for built-in completion noselect,
  vim.o.winborder = 'rounded' -- Use double-line as default border
end
if vim.fn.has('nvim-0.12') == 1 then
  vim.o.pummaxwidth = 100                                 -- Limit maximum width of popup menu
  vim.o.completefuzzycollect = 'keyword,files,whole_line' -- Use fuzzy matching when collecting candidates
end

vim.o.complete = '.,w,b,kspell' -- Use spell check and don't use tags for completion
-- Colors =====================================================================
-- Enable syntax highlighing if it wasn't already (as it is time consuming)
-- Don't use defer it because it affects start screen appearance
if vim.fn.exists('syntax_on') ~= 1 then vim.cmd('syntax enable') end

-- Editing ====================================================================
vim.o.autoindent       = true                  -- Use auto indent
vim.o.expandtab        = true                  -- Convert tabs to spaces
vim.o.formatoptions    = 'qnl1j'               -- Improve comment editing
vim.o.ignorecase       = true                  -- Ignore case when searching (use `\C` to force not doing that)
vim.o.incsearch        = true                  -- Show search results while typing
vim.o.infercase        = true                  -- Infer letter cases for a richer built-in keyword completion
vim.o.shiftwidth       = 2                     -- Use this number of spaces for indentation
vim.o.smartcase        = true                  -- Don't ignore case when searching if pattern has upper case
vim.o.smartindent      = true                  -- Make indenting smart
vim.o.tabstop          = 2                     -- Insert 2 spaces for a tab
vim.o.virtualedit      = 'block'               -- Allow going past the end of line in visual block mode

vim.o.iskeyword        = '@,48-57,_,192-255,-' -- Treat dash separated words as a word text object

-- Define pattern for a start of 'numbered' list. This is responsible for
-- correct formatting of lists when using `gw`. This basically reads as 'at
-- least one special character (digit, -, +, *) possibly followed some
-- punctuation (. or `)`) followed by at least one space is a start of list
-- item'
vim.o.formatlistpat    = [[^\s*[0-9\-\+\*]\+[\.\)]*\s\+]]

-- Spelling ===================================================================
vim.o.spelllang        = 'en_us,de' -- Define spelling dictionaries
vim.o.spelloptions     = 'camel'    -- Treat parts of camelCase words as seprate words

-- vim.o.dictionary = vim.fn.stdpath('config') .. '/misc/dict/english.txt' -- Use specific dictionaries

-- Folds ======================================================================
vim.o.foldmethod       = 'indent' -- Set 'indent' folding method
vim.o.foldlevel        = 1        -- Display all folds except top ones
vim.o.foldnestmax      = 10       -- Create folds only for some number of nested levels
vim.g.markdown_folding = 1        -- Use folding by heading in markdown files

if vim.fn.has('nvim-0.10') == 1 then
  vim.o.foldtext = '' -- Use underlying text with its highlighting
end



-- Diagnostics ================================================================
local diagnostic_opts = {
  -- Define how diagnostic entries should be shown
  signs            = { priority = 9999, severity = { min = 'HINT', max = 'ERROR' } },
  virtual_lines    = false,
  virtual_text     = { current_line = false, severity = { min = 'WARN', max = 'ERROR' } },
  jump             = { float = false },
  underline        = false,
  -- Don't update diagnostics when typing
  update_in_insert = false,
}
later(function() vim.diagnostic.config(diagnostic_opts) end)


-- Custom autocommands ========================================================
local augroup = vim.api.nvim_create_augroup('CustomSettings', {})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown' },
  group = augroup,
  callback = function()
    vim.diagnostic.config({
      signs = {
        severity = { min = 'WARN', max = 'ERROR' }
      },
      virtual_text = {
        current_line = false,
        severity = { min = 'HINT', max = 'ERROR' }
      }
    })
  end
})

vim.api.nvim_create_autocmd("FileType", {
  desc = "remove formatoptions",
  callback = function()
    vim.opt.formatoptions:remove({ "r", "o" }) -- Don't continue comments on enter or o
    vim.b.minitrailspace_disable = true        -- Don't highlight trailing space by default
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  callback = function()
    -- Don't auto-wrap comments and don't insert comment leader after hitting 'o'
    -- If don't do this on `FileType`, this keeps reappearing due to being set in
    -- filetype plugins.
    vim.cmd('setlocal formatoptions-=r formatoptions-=o')
  end,
  desc = [[Ensure proper 'formatoptions']],
})
-- Neovide  ==============================================
if vim.g.neovide then
  vim.g.neovide_cursor_vfx_mode = "pixiedust"
  vim.g.neovide_cursor_smooth_blink = true
  vim.g.neovide_cursor_animation_length = 0.02
  vim.g.neovide_cursor_short_animation_length = 0
  vim.g.neovide_font_hinting = 'none'
  vim.g.neovide_font_edging = 'subpixelantialias'
  vim.o.guifont = 'Iosevka Nerd Font,Symbols Nerd Font:h14:#e-subpixelantialias:#h-none'
  vim.g.neovide_floating_corner_radius = 0.35
  vim.keymap.set("n", "<leader>nf", "<cmd>NeovideFullscreen<CR>", { desc = "Toggle Neovide Fullscreen" })
end

--stylua: ignore end
