local M = {}

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

-- Define comment node types as constants
local COMMENT_TYPES = {
  comment = true,
  block_comment = true,
  line_comment = true,
}

function M.get_current_node()
  local ts_utils = require('nvim-treesitter.ts_utils')
  local cur_win = vim.api.nvim_get_current_win()
  return ts_utils.get_node_at_cursor(cur_win, true)
end

function M.detect_global_node()
  local cur_node = M.get_current_node()
  local root

  if not cur_node then
    -- print("No node detected")
    local parser = vim.treesitter.get_parser()
    if not parser then
      return nil
    end
    root = parser:parse()[1]:root()
  else
    root = cur_node:root()
  end

  if not root then
    return nil
  end

  return root:type()
end

function M.move_to_next_non_empty_line()
  local ts_utils = require('nvim-treesitter.ts_utils')
  -- Search for the next non-empty line
  local line_num = vim.fn.search("[^;\\s]", "W")

  if line_num <= 0 then
    -- print("No non-empty line found below the current position")
    return false
  end

  -- Get the line content and find first non-whitespace character
  local line_content = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
  local first_non_ws = line_content:find("%S") or 1
  vim.api.nvim_win_set_cursor(0, { line_num, first_non_ws - 1 })

  local node = M.get_current_node()
  if not node or not node:type() then
    -- print("No node found")
    return false
  end

  local global_node_type = M.detect_global_node()

  -- Skip comments and global nodes
  while node and (COMMENT_TYPES[node:type()] or node:type() == global_node_type) do
    line_num = line_num + 1
    local max_lines = vim.api.nvim_buf_line_count(0)

    if line_num > max_lines then
      -- print("Reached end of buffer")
      return false
    end

    -- Get the line content and find first non-whitespace character
    line_content = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
    first_non_ws = line_content:find("%S") or 1
    vim.api.nvim_win_set_cursor(0, { line_num, first_non_ws - 1 })
    node = ts_utils.get_node_at_cursor()
  end

  return true
end

function M.vselect_node(node)
  local ts_utils = require('nvim-treesitter.ts_utils')
  if not node then
    return false
  end

  local cur_buf = vim.api.nvim_get_current_buf()
  ts_utils.update_selection(cur_buf, node, "V")
  return true
end

function M.select_until_global(global_nodes)
  local ts_utils = require('nvim-treesitter.ts_utils')
  local root_node = M.detect_global_node()
  if not root_node and global_nodes then
    root_node = global_nodes[1]
  end

  -- Use empty table if no global nodes provided
  global_nodes = global_nodes or {}

  local node = ts_utils.get_node_at_cursor()
  if not node then
    -- print("No syntax node found at cursor position")
    return nil
  end

  local node_type = node:type()

  if node_type == root_node then
    -- print("Cursor is on the root " .. root_node .. " node or in an empty area.")
    return nil
  end

  -- Check if current node is a global
  if is_in_list(global_nodes, node_type) then
    if M.vselect_node(node) then
      return node
    end
  end

  -- Traverse up the tree until we find a global node or reach the root
  local parent = node:parent()
  local parent_type = parent:type() or ""
  if parent and is_in_list(global_nodes, parent_type) then
    if M.vselect_node(node) then
      return node
    end
  end
  while parent and not is_in_list(global_nodes, parent:type()) do
    node = parent
    parent = node:parent()
  end

  if M.vselect_node(node) then
    return node
  end

  return nil
end

function M.slime_send_region()
  -- Check if slime plugin is available
  if not vim.fn.exists('*slime#send_op') then
    vim.notify("slime plugin not available", vim.log.levels.ERROR)
    return
  end

  local slime_command = ":<C-u>call slime#send_op(visualmode(), 1)<CR>"
  local termcodes = vim.api.nvim_replace_termcodes(slime_command, true, true, true)

  vim.api.nvim_feedkeys(termcodes, "x", true)
end

function M.send_repl(global_nodes)
  local ts_utils = require('nvim-treesitter.ts_utils')
  local cur_node = M.get_current_node()

  if not cur_node then
    M.move_to_next_non_empty_line()
  else
    local cur_type = cur_node:type()
    if COMMENT_TYPES[cur_type] or is_in_list(global_nodes, cur_type) then
      M.move_to_next_non_empty_line()
    end
  end

  local sel_node = M.select_until_global(global_nodes)
  if not sel_node then
    -- print("No node selected for REPL")
    return
  end

  -- Send the selected text to the terminal using vim-slime
  M.slime_send_region()

  -- Move cursor and continue
  ts_utils.goto_node(sel_node, true)
  M.move_to_next_non_empty_line()
end

return M
