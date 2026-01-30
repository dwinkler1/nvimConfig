vim.g.omni_sql_default_compl_type = "syntax"

local ts_lib = Config.treesitter_helpers
local global_nodes_sql = { 'program', 'cte' }
ts_lib.setup_keybindings(global_nodes_sql)

-- SQL specific keybindings
vim.keymap.set({ 'n' }, '<localleader>;', function()
    vim.api.nvim_call_function('slime#send', { ";\n" })
  end,
  { noremap = true, silent = true, desc = "SQL statment return", buffer = true })
