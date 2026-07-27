local Config = require('config')

local later = MiniDeps.later
local nix = require('config.nix')

later(function()
  -- Only pull in the DAP packages when R (the only cat that has a real
  -- adapter for now) is enabled; otherwise the lazy load + autoload chain
  -- still works but those three would sit unused on the runtime path.
  if not nix.get_cat("r", false) then
    return
  end

  Config.add("nvim-dap")
  Config.add("nvim-dap-ui")
  Config.add("nvim-dap-virtual-text")
end)

later(function()
  if not nix.get_cat("r", false) then
    return
  end

  local dap_ok, dap = pcall(require, "dap")
  if not dap_ok then
    vim.notify("nvim-dap not available", vim.log.levels.WARN)
    return
  end

  local dapui_ok, dapui = pcall(require, "dapui")
  if dapui_ok then
    dapui.setup()
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end
  end

  local vt_ok, _ = pcall(require, "nvim-dap-virtual-text")
  if vt_ok then
    -- Default setup is enough; virtual text is enabled automatically.
  end

  -- R adapter via vscDebugger (https://github.com/cwida/vscDebugger)
  if nix.get_cat("r", false) then
    dap.adapters.r = {
      type = "executable",
      command = "R",
      args = {
        "--quiet",
        "--no-save",
        "-e",
        "vscDebugger::main()",
      },
    }

    dap.configurations.r = {
      {
        type = "r",
        name = "Debug current R script",
        request = "launch",
        program = "${file}",
        debugMode = "function",
      },
      {
        type = "r",
        name = "Attach to R process",
        request = "attach",
        hostName = "localhost",
        port = 18721,
      },
    }
  end
end)
