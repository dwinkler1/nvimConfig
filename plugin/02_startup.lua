local M = {}

-- Helper function to normalize input to a list
local function normalize_filetypes_input(input)
  if type(input) == "string" then
    return { input }
  elseif type(input) == "table" then
    return input
  else
    vim.notify("get_recent_files_by_ft_or_ext: Invalid input type for filetypes", vim.log.levels.ERROR)
    return nil
  end
end

-- Helper function to check if a file matches any target filetype
local function matches_target_filetype(file_path, file_ext, detected_ft, target_ft_map)
  for target_ft in pairs(target_ft_map) do
    if file_ext:lower() == target_ft:lower() or
        (detected_ft and detected_ft == target_ft) then
      return target_ft
    end
  end
  return nil
end

-- Helper function to safely detect filetype
local function detect_filetype(file_path)
  local success, ft_match_fn = pcall(function() return vim.filetype.match end)
  if not (success and type(ft_match_fn) == "function") then
    return nil
  end

  local ok, result = pcall(ft_match_fn, { filename = file_path })
  return ok and type(result) == "string" and result ~= "" and result or nil
end

-- Helper function to capitalize first letter
local function capitalize_first(str)
  return str:sub(1, 1):upper() .. str:sub(2)
end

function M.get_recent_files_by_ft_or_ext(target_filetypes_input)
  local target_filetypes_list = normalize_filetypes_input(target_filetypes_input)
  if not target_filetypes_list or #target_filetypes_list == 0 then
    return {}
  end

  -- Create lookup map for O(1) filetype checking
  local target_ft_map = {}
  for _, ft in ipairs(target_filetypes_list) do
    target_ft_map[ft] = true
  end

  local oldfiles = vim.v.oldfiles
  if not oldfiles or #oldfiles == 0 then
    return {}
  end

  local cwd = vim.fn.getcwd()
  local fnamemodify = vim.fn.fnamemodify
  local filereadable = vim.fn.filereadable
  local getftime = vim.fn.getftime

  -- Track most recent file for each target filetype
  local most_recent_files = {}
  for _, ft in ipairs(target_filetypes_list) do
    most_recent_files[ft] = { file = nil, time = 0 }
  end

  local processed_paths = {}

  for _, file_path in ipairs(oldfiles) do
    local full_path = fnamemodify(file_path, ':p')

    -- Skip if already processed or invalid
    if processed_paths[full_path] or
        filereadable(full_path) ~= 1 or
        not full_path:find(cwd, 1, true) then
      goto continue
    end

    processed_paths[full_path] = true

    local file_ext = fnamemodify(full_path, ':e')
    local detected_ft = detect_filetype(full_path)
    local matched_ft = matches_target_filetype(full_path, file_ext, detected_ft, target_ft_map)

    if matched_ft then
      local mod_time = getftime(full_path)
      if mod_time > most_recent_files[matched_ft].time then
        most_recent_files[matched_ft] = { file = full_path, time = mod_time }
      end
    end

    ::continue::
  end

  -- Build result items
  local result_items = {}
  for ft, data in pairs(most_recent_files) do
    if data.file then
      local filename = fnamemodify(data.file, ':t')
      local relative_path = fnamemodify(data.file, ':~:.')

      table.insert(result_items, {
        action = function() Config.edit(data.file) end,
        name = string.format('%s (%s)', filename, relative_path),
        section = 'Recent ' .. capitalize_first(ft),
      })
    end
  end

  return result_items
end

M.footer_text = (function()
  return [[
$$$$$$$\                      $$\           $$\ $$\               $$\  $$\ $$$$$$$\             $$\              $$\    $$\ $$\               
$$  __$$\                     \__|          $$ |$  |             $$  |$$  |$$  __$$\            $$ |             $$ |   $$ |\__|              
$$ |  $$ | $$$$$$\  $$$$$$$\  $$\  $$$$$$\  $$ |\_/$$$$$$$\     $$  /$$  / $$ |  $$ | $$$$$$\ $$$$$$\    $$$$$$\ $$ |   $$ |$$\ $$$$$$\$$$$\  
$$ |  $$ | \____$$\ $$  __$$\ $$ |$$  __$$\ $$ |  $$  _____|   $$  /$$  /  $$ |  $$ | \____$$\\_$$  _|   \____$$\\$$\  $$  |$$ |$$  _$$  _$$\ 
$$ |  $$ | $$$$$$$ |$$ |  $$ |$$ |$$$$$$$$ |$$ |  \$$$$$$\    $$  /$$  /   $$ |  $$ | $$$$$$$ | $$ |     $$$$$$$ |\$$\$$  / $$ |$$ / $$ / $$ |
$$ |  $$ |$$  __$$ |$$ |  $$ |$$ |$$   ____|$$ |   \____$$\  $$  /$$  /    $$ |  $$ |$$  __$$ | $$ |$$\ $$  __$$ | \$$$  /  $$ |$$ | $$ | $$ |
$$$$$$$  |\$$$$$$$ |$$ |  $$ |$$ |\$$$$$$$\ $$ |  $$$$$$$  |$$  /$$  /     $$$$$$$  |\$$$$$$$ | \$$$$  |\$$$$$$$ |  \$  /   $$ |$$ | $$ | $$ |
\_______/  \_______|\__|  \__|\__| \_______|\__|  \_______/ \__/ \__/      \_______/  \_______|  \____/  \_______|   \_/    \__|\__| \__| \__|
]]
end
)

Config.startup = M
