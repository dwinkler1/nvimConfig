-- Global Functions
Config.new_scratch_buffer = function() vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, true)) end

-- Toggle quickfix window
Config.toggle_quickfix = function()
  local cur_tabnr = vim.fn.tabpagenr()
  for _, wininfo in ipairs(vim.fn.getwininfo()) do
    if wininfo.quickfix == 1 and wininfo.tabnr == cur_tabnr then return vim.cmd('cclose') end
  end
  vim.cmd('copen')
end

Config.log = {}
Config.log_buf_id = Config.log_buf_id or nil
Config.start_hrtime = Config.start_hrtime or vim.loop.hrtime()

Config.log_print = function()
  if Config.log_buf_id == nil or not vim.api.nvim_buf_is_valid(Config.log_buf_id) then
    Config.log_buf_id = vim.api.nvim_create_buf(true, true)
  end
  vim.api.nvim_win_set_buf(0, Config.log_buf_id)
  vim.api.nvim_buf_set_lines(Config.log_buf_id, 0, -1, false, vim.split(vim.inspect(Config.log), '\n'))
end

Config.log_clear = function()
  Config.log = {}
  Config.start_hrtime = vim.loop.hrtime()
  vim.cmd('echo "Cleared log"')
end

-- Execute current line with `lua`
Config.execute_lua_line = function()
  local line = 'lua ' .. vim.api.nvim_get_current_line()
  vim.api.nvim_command(line)
  print(line)
  vim.api.nvim_input('<Down>')
end

-- Try opening current file's dir with fallback to cwd
Config.try_opendir = function()
  local buff = vim.api.nvim_buf_get_name(0)
  local ok, err = pcall(MiniFiles.open, buff)
  if ok then return end
  vim.notify(err)
  MiniFiles.open()
end

-- For mini.start
--- Edit a file in the specified window, with smart buffer reuse
--- @param path string: File path to edit
--- @param win_id number|nil: Window ID (defaults to current window)
--- @return number|nil: Buffer ID on success, nil on failure
Config.edit = function(path, win_id)
  -- Validate inputs
  if type(path) ~= 'string' or path == '' then
    return nil
  end

  win_id = win_id or 0
  if not vim.api.nvim_win_is_valid(win_id == 0 and vim.api.nvim_get_current_win() or win_id) then
    return nil
  end

  local current_buf = vim.api.nvim_win_get_buf(win_id)

  -- Check if current buffer can be reused (empty, unmodified, single window)
  local is_empty_buffer = vim.fn.bufname(current_buf) == ''
  local is_regular_buffer = vim.bo[current_buf].buftype ~= 'quickfix'
  local is_unmodified = not vim.bo[current_buf].modified
  local is_single_window = #vim.fn.win_findbuf(current_buf) == 1
  local has_only_empty_line = vim.deep_equal(vim.fn.getbufline(current_buf, 1, '$'), { '' })

  local can_reuse_buffer = is_empty_buffer and is_regular_buffer and is_unmodified
      and is_single_window and has_only_empty_line

  -- Create or get buffer for the file
  local normalized_path = vim.fn.fnamemodify(path, ':.')
  local target_buf = vim.fn.bufadd(normalized_path)

  -- Set buffer in window (use pcall to handle swap file messages gracefully)
  local success = pcall(vim.api.nvim_win_set_buf, win_id, target_buf)
  if not success then
    return nil
  end

  -- Ensure buffer is listed
  vim.bo[target_buf].buflisted = true

  -- Clean up old buffer if it was reused
  if can_reuse_buffer then
    pcall(vim.api.nvim_buf_delete, current_buf, { unload = false })
  end

  return target_buf
end

-- Load library
local packdir = nixCats.vimPackDir or MiniDeps.config.path.package

-- See https://github.com/echasnovski/mini.deps/blob/2953b2089591a49a70e0a88194dbb47fb0e4635c/lua/mini/deps.lua#L518C5-L518C39
Config.source_path = function(path)
  pcall(function() vim.cmd('source ' .. vim.fn.fnameescape(path)) end)
end

Config.add = (function(pkg)
  vim.cmd.packadd(pkg)
  local should_load_after_dir = vim.v.vim_did_enter == 1 and vim.o.loadplugins
  if not should_load_after_dir then return end
  local after_paths = vim.fn.glob(
    packdir .. '/pack/myNeovimPackages/opt/' .. pkg .. '/after/plugin/**/*.{vim,lua}',
    false,
    true
  )
  vim.iter(after_paths):map(function(p)
    Config.source_path(p)
  end)
end)

Config.now_if_args = vim.fn.argc(-1) > 0 and MiniDeps.now or MiniDeps.later
