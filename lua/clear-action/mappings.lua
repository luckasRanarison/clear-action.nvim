local M = {}

local config = require("clear-action.config")
local actions = require("clear-action.actions")

local function parse_value(value)
  local key, desc

  if type(value) == "string" then
    key = value
  elseif type(value) == "table" then
    key = value[1]
    desc = value[2]
  end

  return key, desc
end

M.on_attach = function(bufnr, client)
  local mappings = config.options.mappings
  local client_keymaps = mappings.actions[client.name]
  local quickfix_filters = config.options.quickfix_filters[client.name]
  local function set(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, {
      silent = true,
      buffer = bufnr,
      desc = desc,
    })
  end

  for name, value in pairs(mappings) do
    local key, desc = parse_value(value)
    if name ~= "actions" and key and actions[name] then
      local arg
      if vim.startswith(name, "quickfix") then
        arg = quickfix_filters
      elseif name == "apply_first" then
        arg = client
      end
      set("n", key, function() actions[name](arg) end, desc)
    end
  end

  if client_keymaps then
    for action_prefix, value in pairs(client_keymaps) do
      local key, desc = parse_value(value)
      set("n", key, function() actions.apply(action_prefix) end, desc)
    end
  end
end

return M
