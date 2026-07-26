local Config = require('config')

local later = MiniDeps.later
local nix = require('config.nix')

-- Only load image-nvim when a cat that benefits from in-buffer plots is on.
later(function()
  if not nix.get_cat({ "r", "markdown" }, false) then
    return
  end

  Config.add("image-nvim")
end)

later(function()
  if not nix.get_cat({ "r", "markdown" }, false) then
    return
  end

  local ok, image = pcall(require, "image")
  if not ok then
    vim.notify("image.nvim not available", vim.log.levels.DEBUG)
    return
  end

  image.setup({
    backend = "auto",
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = false,
        download_remote_images = true,
        only_render_image_at_cursor = false,
        filetypes = { "markdown", "quarto" },
      },
    },
    max_width = nil,
    max_height = nil,
    max_width_window_percentage = nil,
    max_height_window_percentage = 50,
    window_overlap_clear_enabled = false,
    window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs" },
    editor_only_render_when_focused = false,
    hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp" },
  })
end)
