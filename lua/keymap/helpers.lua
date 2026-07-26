local M = {}

---Create a normal-mode `<Leader>` mapping.
function M.nmap_leader(suffix, rhs, desc, opts)
  opts = opts or {}
  opts.desc = desc
  vim.keymap.set('n', '<Leader>' .. suffix, rhs, opts)
end

---Create a visual-mode `<Leader>` mapping.
function M.xmap_leader(suffix, rhs, desc, opts)
  opts = opts or {}
  opts.desc = desc
  vim.keymap.set('x', '<Leader>' .. suffix, rhs, opts)
end

---Create a normal-mode LSP keymap with an "(LSP)" suffix in the description.
function M.nmap_lsp(keys, func, desc)
  if desc then
    desc = desc .. "(LSP)"
  end
  vim.keymap.set("n", keys, func, { desc = desc })
end

return M
