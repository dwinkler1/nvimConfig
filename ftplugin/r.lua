vim.b.slime_cell_delimiter = vim.b.slime_cell_delimiter or "## ----"

local assign_action = function()
  if vim.bo.filetype ~= "r" then
    return
  end

  local ok, r_edit = pcall(require, "r.edit")
  if not ok then
    return
  end

  if MiniTrailspace and MiniTrailspace.trim then
    MiniTrailspace.trim()
  end
  r_edit.assign()
end

vim.api.nvim_buf_create_user_command(0, "RAssign", assign_action, { desc = "Trim trailing space and insert <-" })
-- Settings
vim.bo.comments = [[:#',:####,:###,:##,:#]]

-- Keymaps
-- Note: These use <Plug> mappings provided by R.nvim
vim.keymap.set("n", "<Enter>", "<Plug>RDSendLine", { buffer = true })
vim.keymap.set("v", "<Enter>", "<Plug>RSendSelection", { buffer = true })

-- Assignment operator (--)
vim.keymap.set("i", "--", "<Cmd>lua MiniTrailspace.trim()<CR><Plug>RInsertAssign", { buffer = true, noremap = true })

-- Pipe operator (;;)
vim.keymap.set("i", ";;", "<Cmd>lua MiniTrailspace.trim()<CR><Plug>RInsertPipe<CR>", { buffer = true, noremap = true })

-- MiniClue / WhichKey hints
local r_clues = {
  { mode = "n", keys = "<localleader>a", desc = "+batch" },
  { mode = "n", keys = "<localleader>b", desc = "+between/debug" },
  { mode = "n", keys = "<localleader>c", desc = "+substitute" },
  { mode = "n", keys = "<localleader>f", desc = "+functions" },
  { mode = "n", keys = "<localleader>i", desc = "+install" },
  { mode = "n", keys = "<localleader>k", desc = "+knit" },
  { mode = "n", keys = "<localleader>p", desc = "+paragraph" },
  { mode = "n", keys = "<localleader>r", desc = "+regular" },
  { mode = "n", keys = "<localleader>s", desc = "+selection" },
  { mode = "n", keys = "<localleader>t", desc = "+dput" },
  { mode = "n", keys = "<localleader>u", desc = "+undebug" },
}

vim.b.miniclue_config = {
  clues = {
    r_clues,
  },
  triggers = {
    { mode = "n", keys = "<localleader>", desc = "+R" },
  },
}
