local M = {}

-- Default parsers list moved from startup config
M.default_parsers = { 
  "bash", "bibtex", "c", "caddy", "cmake", "comment", "commonlisp", "cpp", "css", "csv",
  "cuda", "desktop", "diff", "dockerfile", "doxygen", "editorconfig", "fortran", "git_config", "git_rebase",
  "gitattributes", "gitcommit", "gitignore", "gnuplot", "go", "gpg", "html", "javascript", "jq", "json", "json5",
  "julia", "just", "latex", "ledger", "lua", "luadoc", "luap", "luau", "make", "markdown", "markdown_inline",
  "matlab", "meson", "muttrc", "nix", "nu", "passwd", "powershell", "prql", "python", "r", "query", "readline", "regex",
  "requirements", "rnoweb", "rust", "sql", "ssh_config", "swift", "tmux", "toml", "tsv", "tsx", "typescript", "typst",
  "vala", "vim", "vimdoc", "yaml", "zig", 
}

-- Cache treesitter utils to avoid repeated requires
local smart_send = require('nix_smart_send')

-- Helper function to check if value exists in list (optimized with early return)
local function is_in_list(list, value)
  if not list or not value then
    return false
  end

  for _, v in ipairs(list) do
    if v == value then
      return true
    end
  end
  return false
end


function M.add_global_node(nodes)
  if not nodes then
    return nil
  end

  local node_type = M.get_type()
  if not node_type then
    return nodes
  end

  -- Create a copy to avoid modifying the original
  local global_nodes = vim.deepcopy(nodes)

  -- Check if node type already exists to avoid duplicates
  if not is_in_list(global_nodes, node_type) then
    table.insert(global_nodes, node_type)
  end

  return global_nodes
end

function M.remove_global_node(nodes)
  if not nodes then
    return nil
  end

  local node_type = M.get_type()
  if not node_type then
    return nodes
  end

  local global_nodes = vim.deepcopy(nodes)

  -- Remove all occurrences (iterate backwards to avoid index issues)
  for i = #global_nodes, 1, -1 do
    if global_nodes[i] == node_type then
      table.remove(global_nodes, i)
    end
  end

  return global_nodes
end

function M.set_global_nodes()
  local input = vim.fn.input("Enter root nodes: ")
  if input == "" then
    return {}
  end

  local nodes_in = {}
  -- Trim whitespace from each node name
  for node in string.gmatch(input, '([^,]+)') do
    local trimmed = vim.trim(node)
    if trimmed ~= "" then
      table.insert(nodes_in, trimmed)
    end
  end

  return nodes_in
end

function M.get_type()
  local cur_node = smart_send.get_current_node()
  if not cur_node then
    print("Not a node")
    return nil
  end

  local node_type = cur_node:type()
  print("Node type: " .. node_type)
  return node_type
end


function M.setup_keybindings(global_nodes)
  local current_global_nodes = global_nodes

  vim.keymap.set({ 'n' }, '<localleader>r', function()
      current_global_nodes = M.set_global_nodes()
    end,
    { noremap = true, silent = true, desc = "set global_nodes", buffer = true })

  vim.keymap.set({ 'n', 'v' }, '<localleader>v', function()
      smart_send.move_to_next_non_empty_line(); smart_send.select_until_global(current_global_nodes)
    end,
    { noremap = true, silent = true, desc = "Visual select next node after WS", buffer = true })

  vim.keymap.set('n', '<localleader>a', function() smart_send.send_repl(current_global_nodes) end,
    { noremap = true, silent = true, desc = "Send node to REPL", buffer = true })

  vim.keymap.set({ 'n', 'i' }, '<S-CR>', function() smart_send.send_repl(current_global_nodes) end,
    { noremap = true, silent = true, desc = "Send node to REPL", buffer = true })

  vim.keymap.set('n', '<CR>', function() smart_send.send_repl(current_global_nodes) end,
    { noremap = true, silent = true, desc = "Send node to REPL", buffer = true })

  vim.keymap.set('n', '<localleader>n',
    function() current_global_nodes = M.add_global_node(current_global_nodes) end,
    { noremap = true, silent = true, desc = "Add node under cursor to globals", buffer = true })

  vim.keymap.set('n', '<localleader>x',
    function() current_global_nodes = M.remove_global_node(current_global_nodes) end,
    { noremap = true, silent = true, desc = "Remove node under cursor from globals", buffer = true })

  vim.keymap.set('n', '<localleader>o', function()
    pout = table.concat(global_nodes, ', ') .. ""
    print(pout)
  end, { noremap = true, silent = true, desc = "Print globals", buffer = true })

  vim.keymap.set('n', '<localleader>p', function() M.get_type() end,
    { noremap = true, silent = true, desc = "Print node type", buffer = true })
end

Config.treesitter_helpers = M

return M
