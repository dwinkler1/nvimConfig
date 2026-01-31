

local quarto = require('quarto')
quarto.setup()
vim.keymap.set('n', '<leader>qp', quarto.quartoPreview, { silent = true, noremap = true })

vim.keymap.set("n", "<Enter>", "<Plug>RDSendLine", { buffer = true })
vim.keymap.set("v", "<Enter>", "<Plug>RSendSelection", { buffer = true })

-- Assignment operator (--)
vim.keymap.set("i", "--", "<Cmd>lua MiniTrailspace.trim()<CR><Plug>RInsertAssign", { buffer = true, noremap = true })

-- Pipe operator (;;)
vim.keymap.set("i", ";;", "<Cmd>lua MiniTrailspace.trim()<CR><Plug>RInsertPipe<CR>", { buffer = true, noremap = true })

local runner = require("quarto.runner")
vim.keymap.set("n", "<localleader>a", runner.run_cell,  { desc = "run cell", silent = true })
vim.keymap.set("n", "<localleader>A", runner.run_all,   { desc = "run all cells", silent = true })
vim.keymap.set("n", "<localleader>RA", function()
  runner.run_all(true)
end, { desc = "run all cells of all languages", silent = true })


