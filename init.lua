_G.Config = {}
local nix = require('config.nix').init { non_nix_value = true }
Config.isNixCats = nix.is_nix
Config.nixConfig = nix

require('lze').register_handlers(require('nixCatsUtils.lzUtils').for_cat)

local mini_deps = require('mini.deps')

if not Config.isNixCats then
  local path_package = vim.fn.stdpath('data') .. '/site/'
  local mini_path = path_package .. 'pack/deps/start/mini.nvim'
  if not vim.uv.fs_stat(mini_path) then
    vim.cmd('echo "Installing `mini.nvim`" | redraw')
    local clone_cmd = {
      'git', 'clone', '--filter=blob:none',
      'https://github.com/echasnovski/mini.nvim', mini_path
    }
    vim.fn.system(clone_cmd)
    vim.cmd('packadd mini.nvim | helptags ALL')
    vim.cmd('echo "Installed `mini.nvim`" | redraw')
  end

  -- Set up 'mini.deps' (customize to your liking)
  mini_deps.setup({ path = { package = path_package } })
else
  mini_deps.setup()
end
