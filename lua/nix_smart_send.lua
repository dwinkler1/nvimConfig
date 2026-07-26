local M = {}

-- Define comment node types as constants
local COMMENT_TYPES = {
  comment = true,
  block_comment = true,
  line_comment = true,
}

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

-- Safely get the Tree-sitter node under the cursor.
function M.get_current_node()
  local ok, node = pcall(vim.treesitter.get_node, { ignore_injections = false })
  return ok and node or nil
end

-- Detect the root node type of the current buffer's Tree-sitter tree.
function M.detect_global_node()
  local cur_node = M.get_current_node()
  local root

  if not cur_node then
    local ok, parser = pcall(vim.treesitter.get_parser)
    if not ok or not parser then
      return nil
    end
    local trees = parser:parse()
    if not trees or not trees[1] then
      return nil
    end
    root = trees[1]:root()
  else
    root = cur_node:root()
  end

  return root and root:type() or nil
end

-- Ascend the tree from the current node until we hit a node whose parent is a
-- "global" node (or the root).  This is the unit of code we want to send.
local function get_target_node(global_nodes)
  local root_type = M.detect_global_node()
  global_nodes = global_nodes or {}

  local node = M.get_current_node()
  if not node then
    return nil
  end

  while node do
    local parent = node:parent()
    if not parent then
      break
    end

    local p_type = parent:type()
    if is_in_list(global_nodes, p_type) or p_type == root_type then
      break
    end
    node = parent
  end

  return node
end

-- Move the cursor to the next named sibling that is not a comment.
-- Operates on the Tree-sitter AST instead of scanning lines, so it is fast and
-- language-agnostic.
function M.move_to_next_non_empty_line(current_node)
  local node = current_node
  if not node then
    node = get_target_node({})
  end
  if not node then
    return false
  end

  node = node:next_named_sibling()
  while node do
    if not COMMENT_TYPES[node:type()] then
      local start_row, start_col = node:range()
      pcall(vim.api.nvim_win_set_cursor, 0, { start_row + 1, start_col })
      return true, node
    end
    node = node:next_named_sibling()
  end

  return false
end

function M.vselect_node(node)
  if not node then
    return false
  end

  local start_row, _, end_row, _ = node:range()

  vim.api.nvim_win_set_cursor(0, { start_row + 1, 0 })
  vim.cmd("normal! V")
  vim.api.nvim_win_set_cursor(0, { end_row + 1, 0 })

  return true
end

function M.select_until_global(global_nodes)
  local target = get_target_node(global_nodes)
  if not target then
    return nil
  end

  if M.vselect_node(target) then
    return target
  end

  return nil
end

function M.slime_send_region()
  if vim.fn.exists('*slime#send_op') == 0 then
    vim.notify("slime plugin not available", vim.log.levels.ERROR)
    return
  end

  local slime_command = ":<C-u>call slime#send_op(visualmode(), 1)<CR>"
  local termcodes = vim.api.nvim_replace_termcodes(slime_command, true, true, true)

  vim.api.nvim_feedkeys(termcodes, "x", true)
end

function M.send_repl(global_nodes)
  local target_node = get_target_node(global_nodes)
  if not target_node then
    return
  end

  -- If sitting on a comment, step forward first so we don't send comments.
  if COMMENT_TYPES[target_node:type()] then
    local moved, next_node = M.move_to_next_non_empty_line(target_node)
    if not moved or not next_node then
      return
    end
    target_node = next_node
  end

  -- Select the target node and send it to the REPL.
  if not M.vselect_node(target_node) then
    return
  end
  M.slime_send_region()

  -- Place cursor at end of visual block
  local _, _, er, ec = target_node:range()
  vim.api.nvim_win_set_cursor(0, { er + 1, ec })

  -- Jump to the next relevant AST node instead of scanning lines
  M.move_to_next_non_empty_line(target_node)
end

return M
