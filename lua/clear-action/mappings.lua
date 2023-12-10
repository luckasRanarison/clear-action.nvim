local M = {}

local config = require("clear-action.config")
local actions = require("clear-action.actions")

local function parse_value(value)
  if type(value) == "table" and not vim.tbl_islist(value) then return value end

  local opts = {
    options = {},
  }

  if type(value) == "string" then
    opts.key = value
  elseif type(value) == "table" then
    opts.key = value[1]
    opts.options.desc = value[2]
  end

  return opts
end

M.on_attach = function(bufnr, client)
  local mappings = config.options.mappings
  local client_keymaps = mappings.actions[client.name]
  local quickfix_filters = config.options.quickfix_filters[client.name]

  local function set(opts, action)
    vim.keymap.set(
      opts.mode or { "n", "v" },
      opts.key,
      action,
      vim.tbl_extend("force", {
        silent = true,
        buffer = bufnr,
      }, opts.options or {})
    )
  end

  for name, value in pairs(mappings) do
    local opts = parse_value(value)
    if name ~= "actions" and opts.key and actions[name] then
      local arg = vim.startswith(name, "quickfix") and quickfix_filters
      set(opts, function() actions[name](arg) end)
    end
  end

  if client_keymaps then
    for action_prefix, value in pairs(client_keymaps) do
      local opts = parse_value(value)
      set(opts, function() actions.apply(action_prefix) end)
    end
  end
end

return M
