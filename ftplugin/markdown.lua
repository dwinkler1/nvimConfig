-- Add the key mappings only for Markdown files in a zk notebook.
if require("zk.util").notebook_root(vim.fn.expand('%:p')) ~= nil then
  local map = vim.keymap.set
  -- Open the link under the caret.
  map("n", "<CR>", "<Cmd>lua vim.lsp.buf.definition()<CR>", { noremap = true, silent = false, buffer = true })

  -- Create a new note after asking for its title.
  -- This overrides the global `<leader>zn` mapping to create the note in the same directory as the current buffer.
  map("n", "<leader>zhn", "<Cmd>ZkNew { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>",
    { noremap = true, silent = false, buffer = true, desc = "Note (here)" })
  -- Create a new note in the same directory as the current buffer, using the current selection for title.
  map("v", "<leader>zhnt", ":'<,'>ZkNewFromTitleSelection { dir = vim.fn.expand('%:p:h') }<CR>",
    { noremap = true, silent = false, buffer = true, desc = "Note from selection (title)" })
  -- Create a new note in the same directory as the current buffer, using the current selection for note content and asking for its title.
  map("v", "<leader>zhnc",
    ":'<,'>ZkNewFromContentSelection { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>",
    { noremap = true, silent = false, buffer = true, desc = "Note from selection (content)" })

  -- Open notes linking to the current buffer.
  map("n", "<leader>zb", "<Cmd>ZkBacklinks<CR>", { noremap = true, silent = false, buffer = true, desc = "Backlinks" })
  -- Alternative for backlinks using pure LSP and showing the source context.
  --map('n', '<leader>zb', '<Cmd>lua vim.lsp.buf.references()<CR>', opts)
  -- Open notes linked by the current buffer.
  map("n", "<leader>zL", "<Cmd>ZkLinks<CR>", { noremap = true, silent = false, buffer = true, desc = "Links" })
  map("n", "<leader>zi", "<Cmd>ZkInsertLink<CR>", { noremap = true, silent = false, buffer = true, desc = "Insert link" })

  -- Preview a linked note.
  -- Open the code actions for a visual selection.
  map("v", "<leader>za", ":'<,'>lua vim.lsp.buf.range_code_action()<CR>",
    { noremap = true, silent = false, buffer = true, desc = "Code actions" })

end
