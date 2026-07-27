local Config = require('config')
local helpers = require('keymap.helpers')
local nmap_leader = helpers.nmap_leader

-- Exit terminal insert mode with <Esc>
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- t is for 'terminal'
nmap_leader("tc", '<Cmd>lua Config.terminal.open_clickhouse_client()<CR>', 'Open Clickhouse client')
nmap_leader("tl", '<Cmd>lua Config.terminal.open_clickhouse_local()<CR>', 'Open Clickhouse local')
nmap_leader("tp", '<Cmd>lua Config.terminal.open_python()<CR>', 'Open Python')
nmap_leader("tj", '<Cmd>lua Config.terminal.open_julia()<CR>', 'Open Julia')
nmap_leader("td", '<Cmd>lua Config.terminal.open_duckdb();Config.terminal.toggle_bracket()<CR>', 'Open DuckDB')
nmap_leader("tx", '<Cmd>lua Config.terminal.open_in_terminal()<CR>', 'Terminal Command')
nmap_leader("tt", '<Cmd>lua Config.terminal.open_shell()<CR>', 'Terminal')
nmap_leader("tb", '<Cmd>lua Config.terminal.toggle_bracket()<CR>', 'Toggle bracketed paste')
nmap_leader("up", '<Cmd>lua Config.terminal.toggle_bracket()<CR>', 'Toggle bracketed paste')
