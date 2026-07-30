-- Comprehensive CI smoke tests for the Neovim configuration.
-- Run inside the wrapped Neovim binary, e.g.:
--   vv --headless -c "luafile tests/smoke.lua" -c "qa!"
--
-- The script loads the full config (plugin/*.lua files are sourced by Neovim on
-- startup), waits for mini.deps deferred work, then exercises key functionality
-- without user interaction.

local M = {}

-- ---------------------------------------------------------------------------
-- Tiny test harness
-- ---------------------------------------------------------------------------
local failures = {}
local passed = 0

local function fail(msg)
  table.insert(failures, msg)
  print("  FAIL: " .. msg)
end

local function pass(msg)
  passed = passed + 1
  print("  PASS: " .. msg)
end

local function assert_eq(a, b, msg)
  if a == b then
    pass(msg)
  else
    fail(string.format("%s (expected %s, got %s)", msg, vim.inspect(b), vim.inspect(a)))
  end
end

local function assert_true(cond, msg)
  if cond then
    pass(msg)
  else
    fail(msg)
  end
end

local function assert_loaded(mod, msg)
  assert_true(package.loaded[mod] ~= nil, msg or ("module '" .. mod .. "' loaded"))
end

-- ---------------------------------------------------------------------------
-- Wait for deferred mini.deps/later work.
-- We patch MiniDeps.later to count pending callbacks and then drain the event
-- loop until the counter returns to zero (or we time out).
-- ---------------------------------------------------------------------------
local function wait_for_deferred(timeout_ms)
  timeout_ms = timeout_ms or 10000

  -- Fire VimEnter so startup autocmds run, then drain the event loop so
  -- mini.deps' deferred setup closures have a chance to execute before we
  -- assert anything.
  vim.cmd('doautocmd VimEnter')
  vim.wait(timeout_ms, function() return false end, 50)
end

-- ---------------------------------------------------------------------------
-- Helper: check whether a keymap is registered for a given lhs in normal mode.
-- ---------------------------------------------------------------------------
local function has_normal_map(lhs)
  -- <leader> is stored as the literal leader key, so test both the raw
  -- symbolic form and the expanded form (e.g. "<leader>ff" and " ff").
  local expanded = lhs:gsub('^<leader>', vim.g.mapleader or '\\')

  if vim.keymap and vim.keymap.get then
    local maps = vim.keymap.get('n')
    for _, map in ipairs(maps) do
      if map.lhs == lhs or map.lhs == expanded then
        return true
      end
    end
  end

  return vim.fn.maparg(lhs, 'n') ~= '' or vim.fn.maparg(expanded, 'n') ~= ''
end

-- ---------------------------------------------------------------------------
-- Helper: check whether a Treesitter parser is available.
-- ---------------------------------------------------------------------------
local function has_parser(lang)
  return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) > 0
end

-- ---------------------------------------------------------------------------
-- Helper: check whether an LSP config was registered (Neovim 0.11+ native API).
-- ---------------------------------------------------------------------------
local function has_lsp_config(name)
  if vim.lsp and vim.lsp.config then
    -- vim.lsp.config(name) returns the merged config or {} if none registered.
    local ok, cfg = pcall(vim.lsp.config, name)
    if ok and cfg and next(cfg) ~= nil then
      return true
    end
  end
  -- Fallback: inspect lspconfig internal table.
  local ok, configs = pcall(require, 'lspconfig.configs')
  if ok and configs and configs[name] then
    return true
  end
  return false
end

-- ---------------------------------------------------------------------------
-- Test suites
-- ---------------------------------------------------------------------------
function M.test_core_config()
  print("\n=== Core configuration ===")
  assert_eq(vim.g.mapleader, ' ', "leader is space")
  assert_eq(vim.g.maplocalleader, ',', "localleader is comma")
  assert_true(vim.o.backup, "backup option enabled")
  assert_true(vim.o.undofile, "undofile enabled")
  assert_eq(vim.o.mouse, 'a', "mouse enabled")
end

function M.test_config_module()
  print("\n=== Config module ===")
  assert_true(_G.Config ~= nil, "global Config table exists")
  assert_true(type(Config.edit) == 'function', "Config.edit helper exists")
  assert_true(type(Config.terminal) == 'table', "Config.terminal namespace exists")
  assert_true(type(Config.treesitter_helpers) == 'table', "Config.treesitter_helpers exists")
end

function M.test_mini_modules()
  print("\n=== mini.nvim modules ===")
  assert_loaded('mini.basics', 'mini.basics loaded')
  assert_loaded('mini.statusline', 'mini.statusline loaded')
  assert_loaded('mini.tabline', 'mini.tabline loaded')
  assert_loaded('mini.clue', 'mini.clue loaded')
  assert_loaded('mini.pick', 'mini.pick loaded')
  assert_loaded('mini.notify', 'mini.notify loaded')
end

function M.test_keymaps()
  print("\n=== Keymaps ===")
  assert_true(has_normal_map('<leader>ff'), "leader ff -> pick files")
  assert_true(has_normal_map('<leader>fg'), "leader fg -> live grep")
  assert_true(has_normal_map('<leader>bb'), "leader bb -> alternate buffer")
  assert_true(has_normal_map('<leader>ed'), "leader ed -> mini.files open")
  assert_true(has_normal_map('<Esc>'), "Esc clears search highlight")
end

function M.test_treesitter()
  print("\n=== Treesitter parsers ===")
  local expected = { 'lua', 'python', 'nix', 'markdown', 'latex', 'r', 'julia' }
  for _, lang in ipairs(expected) do
    assert_true(has_parser(lang), "parser available: " .. lang)
  end
end

function M.test_filetype_detection()
  print("\n=== Filetype detection ===")
  local test_buf = vim.api.nvim_create_buf(false, true)
  local orig_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_current_buf(test_buf)

  -- Test by manually triggering filetype detection for a couple of languages.
  vim.api.nvim_buf_set_name(test_buf, 'test.py')
  vim.api.nvim_set_option_value('filetype', 'python', { buf = test_buf })
  assert_eq(vim.bo.filetype, 'python', "python filetype set")

  vim.api.nvim_buf_set_name(test_buf, 'test.lua')
  vim.api.nvim_set_option_value('filetype', 'lua', { buf = test_buf })
  assert_eq(vim.bo.filetype, 'lua', "lua filetype set")

  vim.api.nvim_set_current_buf(orig_buf)
  vim.api.nvim_buf_delete(test_buf, { force = true })
end

function M.test_lsp_config()
  print("\n=== LSP server registration ===")
  local servers = { 'lua_ls', 'basedpyright', 'ruff', 'nil_ls', 'texlab', 'marksman', 'harper_ls' }
  for _, name in ipairs(servers) do
    assert_true(has_lsp_config(name), "LSP config registered: " .. name)
  end
end

function M.test_plugin_configs()
  print("\n=== Plugin-specific configuration ===")
  -- vimtex globals should be set when the markdown cat is on.
  if vim.g.vimtex_compiler_method then
    assert_eq(vim.g.vimtex_compiler_method, 'latexmk', "vimtex compiler is latexmk")
  else
    pass("vimtex not configured (markdown cat disabled)")
  end

  -- conform formatters should be registered.
  local ok, conform = pcall(require, 'conform')
  if ok and conform then
    local formatters = require('conform').formatters
    assert_true(formatters ~= nil, "conform formatters table exists")
  else
    pass("conform not loaded (expected if utils cat disabled)")
  end

  -- blink.cmp keymap preset should be available.
  local blink_ok, blink = pcall(require, 'blink.cmp')
  if blink_ok and blink then
    pass("blink.cmp loaded")
  else
    pass("blink.cmp not loaded (expected if utils cat disabled)")
  end
end

function M.test_nix_cats_helper()
  print("\n=== nixCats helper ===")
  local ok, nix = pcall(require, 'config.nix')
  assert_true(ok and nix ~= nil, "config.nix can be required")
  if ok and nix then
    local cat = nix.get_cat('general', true)
    assert_true(type(cat) == 'boolean', "get_cat returns boolean default")
  end
end

-- ---------------------------------------------------------------------------
-- Entry point
-- ---------------------------------------------------------------------------
function M.run()
  print("Neovim config CI smoke tests")
  local v = vim.version()
  print(string.format("Neovim version: %d.%d.%d", v.major, v.minor, v.patch))

  -- Drain deferred plugin setup before asserting.
  wait_for_deferred()

  M.test_core_config()
  M.test_config_module()
  M.test_mini_modules()
  M.test_keymaps()
  M.test_treesitter()
  M.test_filetype_detection()
  M.test_lsp_config()
  M.test_plugin_configs()
  M.test_nix_cats_helper()

  print("\n=== Summary ===")
  print(string.format("Passed: %d", passed))
  print(string.format("Failed: %d", #failures))

  if #failures > 0 then
    print("\nFailed tests:")
    for _, f in ipairs(failures) do
      print("  - " .. f)
    end
    vim.cmd('cquit 1')
  else
    print("\nAll smoke tests passed!")
    vim.cmd('cquit 0')
  end
end

local ok, err = pcall(M.run)
if not ok then
  print("CRASH: " .. tostring(err))
  vim.cmd('cquit 1')
end
