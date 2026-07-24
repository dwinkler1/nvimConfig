

local quarto_ok, quarto = pcall(require, 'quarto')
if quarto_ok then
  vim.keymap.set('n', '<leader>qp', quarto.quartoPreview, { silent = true, noremap = true, buffer = true })
end

if vim.bo.filetype == "r" then
  vim.keymap.set("n", "<Enter>", "<Plug>RDSendLine", { buffer = true })
  vim.keymap.set("v", "<Enter>", "<Plug>RSendSelection", { buffer = true })

  -- Assignment operator (--)
  vim.keymap.set("i", "--", "<Cmd>lua MiniTrailspace.trim()<CR><Plug>RInsertAssign", { buffer = true, noremap = true })

  -- Pipe operator (;;)
  vim.keymap.set("i", ";;", "<Cmd>lua MiniTrailspace.trim()<CR><Plug>RInsertPipe<CR>", { buffer = true, noremap = true })
end

local runner_ok, runner = pcall(require, "quarto.runner")
if runner_ok then
  vim.keymap.set("n", "<localleader>a", runner.run_cell,  { desc = "run cell", silent = true, buffer = true })
  vim.keymap.set("n", "<localleader>A", runner.run_all,   { desc = "run all cells", silent = true, buffer = true })
  vim.keymap.set("n", "<localleader>RA", function()
    runner.run_all(true)
  end, { desc = "run all cells of all languages", silent = true, buffer = true })
end


