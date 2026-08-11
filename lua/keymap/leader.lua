local Config = require('config')
local helpers = require('keymap.helpers')
local nmap_leader = helpers.nmap_leader
local xmap_leader = helpers.xmap_leader
local nmap_lsp = helpers.nmap_lsp

-- stylua: ignore start

-- Switch buffers
nmap_leader('<Tab>', '<Cmd>bnext<CR>', 'Next buffer')
nmap_leader('<S-Tab>', '<Cmd>bprev<CR>', 'Prev buffer')

-- a is for 'AI'
nmap_leader("aa", function()
  require("opencode").ask("@this: ")
end, "Ask OpenCode about this")
nmap_leader("ab", function()
  require("opencode").prompt("Analyse @buffer")
end, "Analyse buffer")
nmap_leader("aB", function()
  require("opencode").prompt("Analyse @buffers")
end, "Analyse open buffers")
nmap_leader("ad", function()
  require("opencode").prompt("Explain @diagnostics and fix the underlying issue")
end, "Explain/fix diagnostics")
nmap_leader("an", function()
  require("opencode").command("session.new")
end, "New OpenCode session")
nmap_leader("ap", function()
  require("opencode").ask("@")
end, "Ask OpenCode with context")
nmap_leader("as", function()
  require("opencode").select()
end, "Select OpenCode action")
xmap_leader("aa", function()
  require("opencode").ask("@this: ")
end, "Ask OpenCode about selection")
xmap_leader("af", function()
  require("opencode").prompt("Fix the selected code and preserve its surrounding API:\n@this")
end, "Fix selection")
xmap_leader("ap", function()
  require("opencode").ask("@")
end, "Ask OpenCode with context")
xmap_leader("as", function()
  require("opencode").select()
end, "Select OpenCode action")

-- b is for 'buffer'
nmap_leader('bb', '<Cmd>b#<CR>', 'Alternate')
nmap_leader('bd', '<Cmd>lua MiniBufremove.delete()<CR>', 'Delete')
nmap_leader('bD', '<Cmd>lua MiniBufremove.delete(0, true)<CR>', 'Delete!')
nmap_leader('bs', '<Cmd>lua Config.new_scratch_buffer()<CR>', 'Scratch')
nmap_leader('bw', '<Cmd>lua MiniBufremove.wipeout()<CR>', 'Wipeout')
nmap_leader('bW', '<Cmd>lua MiniBufremove.wipeout(0, true)<CR>', 'Wipeout!')
nmap_leader('bq', '<Cmd>qall<CR>', 'Quit all')

-- e is for 'explore' and 'edit'
nmap_leader('ed', '<Cmd>lua MiniFiles.open()<CR>', 'Directory')
nmap_leader('ef', '<Cmd>lua Config.try_opendir()<CR>', 'File directory')
nmap_leader('es', '<Cmd>lua MiniSessions.select()<CR>', 'Sessions')
nmap_leader('eq', '<Cmd>lua Config.toggle_quickfix()<CR>', 'Quickfix')
nmap_leader('ez', '<Cmd>lua MiniFiles.open(os.getenv("ZK_NOTEBOOK_DIR"))<CR>', 'Notes directory')

-- f is for 'fuzzy find'
nmap_leader('f/', '<Cmd>Pick history scope="/"<CR>', '"/" history')
nmap_leader('f:', '<Cmd>Pick history scope=":"<CR>', '":" history')
nmap_leader('f,', '<Cmd>Pick visit_labels<CR>', 'Visit labels')
nmap_leader('faa', '<Cmd>Pick git_hunks scope="staged"<CR>', 'Added hunks (all)')
nmap_leader('faA', '<Cmd>Pick git_hunks path="%" scope="staged"<CR>', 'Added hunks (current)')
nmap_leader('fb', '<Cmd>Pick buffers<CR>', 'Buffers')
nmap_leader(',', '<Cmd>Pick buffers<CR>', 'Buffers')
nmap_leader('fac', '<Cmd>Pick git_commits<CR>', 'Commits (all)')
nmap_leader('faC', '<Cmd>Pick git_commits path="%"<CR>', 'Commits (current)')
nmap_leader('fd', '<Cmd>Pick diagnostic scope="all"<CR>', 'Diagnostic workspace')
nmap_leader('fD', '<Cmd>Pick diagnostic scope="current"<CR>', 'Diagnostic buffer')
nmap_leader('ff', '<Cmd>Pick files<CR>', 'Files')
nmap_leader('fg', '<Cmd>Pick grep_live<CR>', 'Grep live')
nmap_leader('fG', '<Cmd>Pick grep pattern="<cword>"<CR>', 'Grep current word')
nmap_leader('fh', '<Cmd>Pick help<CR>', 'Help tags')
nmap_leader('fH', '<Cmd>Pick hl_groups<CR>', 'Highlight groups')
nmap_leader('fj', '<Cmd>Pick buf_lines scope="all"<CR>', 'Lines (all)')
nmap_leader('fJ', '<Cmd>Pick buf_lines scope="current"<CR>', 'Lines (current)')
nmap_leader('fam', '<Cmd>Pick git_hunks<CR>', 'Modified hunks (all)')
nmap_leader('faM', '<Cmd>Pick git_hunks path="%"<CR>', 'Modified hunks (current)')
nmap_leader('fm', '<Cmd>Pick marks<CR>', 'Marks')
nmap_leader('fn', '<cmd>ZkNotes<CR>', "Notes")
nmap_leader('fk', '<Cmd>Pick keymaps<CR>', 'Keymaps')
nmap_leader('fR', '<Cmd>Pick resume<CR>', 'Resume')
nmap_leader('fp', '<Cmd>Pick files<CR>', 'Files')
nmap_leader('fq', '<Cmd>Pick list scope="quickfix"<CR>', 'Quickfix')
nmap_leader('fr', '<Cmd>Pick lsp scope="references"<CR>', 'References (LSP)')
nmap_leader('flr', '<Cmd>Pick lsp scope="references"<CR>', 'References (LSP)')
nmap_leader('fS', '<Cmd>Pick lsp scope="workspace_symbol"<CR>', 'Symbols workspace (LSP)')
nmap_leader('flS', '<Cmd>Pick lsp scope="workspace_symbol"<CR>', 'Symbols workspace (LSP)')
nmap_leader('fs', '<Cmd>Pick lsp scope="document_symbol"<CR>', 'Symbols buffer (LSP)')
nmap_leader('fls', '<Cmd>Pick lsp scope="document_symbol"<CR>', 'Symbols buffer (LSP)')
nmap_leader('fld', '<Cmd>Pick lsp scope="definition"<CR>', 'Definition (LSP)')
nmap_leader('flD', '<Cmd>Pick lsp scope="declaration"<CR>', 'Declaration (LSP)')
nmap_leader('flt', '<Cmd>Pick lsp scope="type_definition"<CR>', 'Type Definition (LSP)')
nmap_leader('fv', '<Cmd>Pick visit_paths cwd=""<CR>', 'Visit paths (all)')
nmap_leader('fV', '<Cmd>Pick visit_paths<CR>', 'Visit paths (cwd)')

-- g is for git
local git_log_cmd = [[Git log --pretty=format:\%h\ \%as\ │\ \%s --topo-order]]

nmap_leader('gc', '<Cmd>Git commit<CR>', 'Commit')
nmap_leader('gC', '<Cmd>Git commit --amend<CR>', 'Commit amend')
nmap_leader('gd', '<Cmd>Git diff<CR>', 'Diff')
nmap_leader('gD', '<Cmd>Git diff -- %<CR>', 'Diff buffer')
nmap_leader("gg", "<cmd>Neogit<cr>", "Open Neogit UI")
nmap_leader('gl', '<Cmd>' .. git_log_cmd .. '<CR>', 'Log')
nmap_leader('gL', '<Cmd>' .. git_log_cmd .. ' --follow -- %<CR>', 'Log buffer')
nmap_leader('go', '<Cmd>lua MiniDiff.toggle_overlay()<CR>', 'Toggle overlay')
nmap_leader('gp', '<Cmd>Git pull<CR>', 'Pull')
nmap_leader('gP', '<Cmd>Git push<CR>', 'Push')
nmap_leader('gs', '<Cmd>lua MiniGit.show_at_cursor()<CR>', 'Show at cursor')

xmap_leader('gs', '<Cmd>lua MiniGit.show_at_cursor()<CR>', 'Show at selection')

-- j/k navigate quickfix
nmap_leader("j", '<cmd>cnext<CR>zz', "Quickfix next")
nmap_leader("k", '<cmd>cprev<CR>zz', "Quickfix prev")

-- l is for 'LSP' (Language Server Protocol)
vim.keymap.set({ 'n' }, 'grd', '<Cmd>lua vim.lsp.buf.definition()<CR>', { desc = 'Definition' })
vim.keymap.set({ 'n' }, 'grk', '<Cmd>lua vim.lsp.buf.hover()<CR>', { desc = 'Documentation' })
vim.keymap.set({ 'n' }, 'gre', '<Cmd>lua vim.diagnostic.open_float()<CR>', { desc = 'Diagnostics' })

nmap_lsp("K", '<Cmd>lua vim.lsp.buf.hover()<CR>', "Documentation")
local formatting_cmd = '<Cmd>lua require("conform").format({ lsp_format = "fallback" })<CR>'
nmap_leader('la', '<Cmd>lua vim.lsp.buf.code_action()<CR>', 'Actions')
nmap_leader('le', '<Cmd>lua vim.diagnostic.open_float()<CR>', 'Diagnostics popup')
nmap_leader('lf', formatting_cmd, 'Format')
nmap_leader('lk', '<Cmd>lua vim.lsp.buf.hover()<CR>', 'Documentation')
nmap_leader('li', '<Cmd>lua vim.lsp.buf.implementation()<CR>', 'Information')
-- use ]d and [d
--nmap_leader('lj', '<Cmd>lua vim.diagnostic.goto_next()<CR>', 'Next diagnostic')
--nmap_leader('lk', '<Cmd>lua vim.diagnostic.goto_prev()<CR>', 'Prev diagnostic')
nmap_leader('lR', '<Cmd>lua vim.lsp.buf.references()<CR>', 'References')
nmap_leader('lr', '<Cmd>lua vim.lsp.buf.rename()<CR>', 'Rename')
nmap_leader('ls', '<Cmd>lua vim.lsp.buf.definition()<CR>', 'Source definition')

xmap_leader('lf', formatting_cmd, 'Format selection')

-- L is for 'Lua'
nmap_leader('Lc', '<Cmd>lua Config.log_clear()<CR>', 'Clear log')
nmap_leader('LL', '<Cmd>luafile %<CR><Cmd>echo "Sourced lua"<CR>', 'Source buffer')
nmap_leader('Ls', '<Cmd>lua Config.log_print()<CR>', 'Show log')
nmap_leader('Lx', '<Cmd>lua Config.execute_lua_line()<CR>', 'Execute `lua` line')

-- m is for 'mark' (checkbox toggling)
nmap_leader('mc', '<Cmd>ToggleCheckbox<CR>', 'Toggle checkbox')

-- o is for 'other'
local trailspace_toggle_command = '<Cmd>lua vim.b.minitrailspace_disable = not vim.b.minitrailspace_disable<CR>'
nmap_leader('oh', '<Cmd>normal gxiagxila<CR>', 'Move arg left')
nmap_leader('ol', '<Cmd>normal gxiagxina<CR>', 'Move arg right')
nmap_leader('or', '<Cmd>lua MiniMisc.resize_window()<CR>', 'Resize to default width')
nmap_leader('ot', '<Cmd>lua MiniTrailspace.trim()<CR>', 'Trim trailspace')
nmap_leader('oT', trailspace_toggle_command, 'Trailspace hl toggle')
nmap_leader('oz', '<Cmd>lua MiniMisc.zoom()<CR>', 'Zoom toggle')
nmap_leader('ow',
  "<Cmd>lua MiniSessions.write(vim.fn.input('Session name: ', string.match(vim.fn.getcwd(), \"[^/]+$\") .. '-session.vim'))<CR>",
  'Write session')

-- r is for 'R'
nmap_leader('rc', '<Cmd>RSend devtools::check()<CR>', 'Check')
nmap_leader('rC', '<Cmd>RSend devtools::test_coverage()<CR>', 'Coverage')
nmap_leader('rd', '<Cmd>RSend devtools::document()<CR>', 'Document')
nmap_leader('ri', '<Cmd>RSend devtools::install(keep_source=TRUE)<CR>', 'Install')
nmap_leader('rk', '<Cmd>RSend quarto::quarto_preview("%")<CR>', 'Knit file')
nmap_leader('rl', '<Cmd>RSend devtools::load_all()<CR>', 'Load all')
nmap_leader('rL', '<Cmd>RSend devtools::load_all(recompile=TRUE)<CR>', 'Load all recompile')
nmap_leader('rm', '<Cmd>RSend Rcpp::compileAttributes()<CR>', 'Run examples')
nmap_leader('rT', '<Cmd>RSend testthat::test_file("%")<CR>', 'Test file')
nmap_leader('rt', '<Cmd>RSend devtools::test()<CR>', 'Test')

-- Visual `<leader>r` bindings (dispatched by the filetype-aware REPL
-- runner in `lua/keymap/repl.lua`). Previously the visual clue group was
-- empty, so this restores parity between the visual and normal `r`-group.
xmap_leader('rr', function() require('keymap.repl').send_selection() end, 'Send selection to REPL')
-- - Copy to clipboard and make reprex (which itself is loaded to clipboard)
xmap_leader('rx', '"+y :RSend reprex::reprex()<CR>', 'Reprex selection')

-- s is for 'send' (Send text to the active REPL/runner)
nmap_leader('s', function() require('keymap.repl').send_line() end, 'Send to REPL')
xmap_leader('s', function() require('keymap.repl').send_selection() end, 'Send selection to REPL')

-- d is for 'debug' (nvim-dap)
nmap_leader('db', '<Cmd>lua require("dap").toggle_breakpoint()<CR>', 'Toggle breakpoint')
nmap_leader('dB', '<Cmd>lua require("dap").set_breakpoint(vim.fn.input("Condition: "))<CR>', 'Conditional breakpoint')
nmap_leader('dc', '<Cmd>lua require("dap").continue()<CR>', 'Continue')
nmap_leader('do', '<Cmd>lua require("dap").step_over()<CR>', 'Step over')
nmap_leader('di', '<Cmd>lua require("dap").step_into()<CR>', 'Step into')
nmap_leader('dO', '<Cmd>lua require("dap").step_out()<CR>', 'Step out')
nmap_leader('dr', '<Cmd>lua require("dap").repl.open()<CR>', 'Open DAP REPL')
nmap_leader('du', '<Cmd>lua require("dapui").toggle()<CR>', 'Toggle DAP UI')
nmap_leader('dK', '<Cmd>lua require("dapui").eval()<CR>', 'Evaluate expression')

-- u is for UI
nmap_leader('ut', '<Cmd>TSContext toggle<CR>', 'Toggle TScontext')
nmap_leader('ua', '<Cmd>Copilot toggle<CR>', 'Toggle AI completion')

-- v is for 'visits'
nmap_leader('vv', '<Cmd>lua MiniVisits.add_label("core")<CR>', 'Add "core" label')
nmap_leader('vV', '<Cmd>lua MiniVisits.remove_label("core")<CR>', 'Remove "core" label')
nmap_leader('vl', '<Cmd>lua MiniVisits.add_label()<CR>', 'Add label')
nmap_leader('vL', '<Cmd>lua MiniVisits.remove_label()<CR>', 'Remove label')

local map_pick_core = function(keys, cwd, desc)
  local rhs = function()
    local sort_latest = MiniVisits.gen_sort.default({ recency_weight = 1 })
    MiniExtra.pickers.visit_paths({
      cwd = cwd,
      filter = 'core',
      sort = sort_latest
    }, { source = { name = desc } })
  end
  nmap_leader(keys, rhs, desc)
end
map_pick_core('vc', '', 'Core visits (all)')
map_pick_core('vC', nil, 'Core visits (cwd)')

-- w is for 'windows'
nmap_leader("wh", "<C-w>h", "Go to Left Window", { remap = true })
nmap_leader("wj", "<C-w>j", "Go to Lower Window", { remap = true })
nmap_leader("wk", "<C-w>k", "Go to Upper Window", { remap = true })
nmap_leader("wl", "<C-w>l", "Go to Right Window", { remap = true })
nmap_leader("w>", "<Cmd>vertical resize +5<CR>", "Increase Window Width")
nmap_leader("w<lt>", "<Cmd>vertical resize -5<CR>", "Decrease Window Width")

local function set_window_width_percent(percent)
  return function()
    local target_width = math.max(1, math.floor(vim.o.columns * percent / 100 + 0.5))
    vim.api.nvim_win_set_width(0, target_width)
  end
end

for i = 1, 9 do
  local percent = i * 10
  nmap_leader(
    "w" .. i,
    set_window_width_percent(percent),
    string.format("Set Window Width to %d%%", percent)
  )
end

nmap_leader("_", "<C-W>s", "Split Window Below", { remap = true })
nmap_leader("|", "<C-W>v", "Split Window Right", { remap = true })
nmap_leader("wd", "<C-W>c", "Delete Window", { remap = true })
nmap_leader("wo", "<C-W>o", "Delete Other Windows", { remap = true })

-- z is for 'ZettelKasten'
nmap_leader("zo", '<Cmd>ZkNotes<CR>', "Notes")
nmap_leader("zt", '<Cmd>ZkTags<cr>', "Tags")

nmap_leader(
  "zrd",
  '<Cmd>ZkNew { group = "dreviews" }<CR>',
  "Daily Review"
)
nmap_leader(
  "zrw",
  '<Cmd>ZkNew { group = "wreviews" }<CR>',
  "Weekly Review"
)
nmap_leader(
  "zn",
  '<Cmd>ZkNew { group = "inbox", title = vim.fn.input("Title: ") }<CR>',
  "New"
)
nmap_leader(
  "zp",
  "<Cmd>ZkNew { group = 'permanent', title = vim.fn.input('Title: ') }<CR>",
  "Permanent"
)

nmap_leader(
  "zl",
  "<Cmd>ZkNew { group = 'literature', title = vim.fn.input('Title: '), extra.author = vim.fn.input('Author: '), extra.year = vim.fn.input('Year: ') }<CR>",
  "Literature"
)

nmap_leader(
  "zd",
  "<Cmd>ZkNew { group = 'dashboard', title = vim.fn.input('Title: ') }<CR>",
  "Dashboard"
)
nmap_leader(
  "zP",
  "<Cmd>ZkNew { group = 'project', title = vim.fn.input('Title: ')}<CR>",
  "Project"
)
-- stylua: ignore end
