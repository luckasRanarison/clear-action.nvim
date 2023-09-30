local M = {}

local utils = require("clear-action.utils")
local popup = require("clear-action.popup")
local config = require("clear-action.config")

local function on_code_action_results(results, context, options)
  local function action_filter(action)
    if options.context and options.context.only then
      if not action.kind then return false end
      for _, kind in ipairs(options.context.only) do
        if vim.startswith(action.kind, kind) then return true end
      end
      return false
    end
    return not options.filter and true or options.filter(action)
  end

  local function on_select(action_tuple)
    if not action_tuple then return end

    local client = vim.lsp.get_client_by_id(action_tuple[1])
    local action = action_tuple[2]
    local ctx = { bufnr = context.bufnr }

    utils.handle_action(action, client, ctx)
  end

  local action_tuples = {}

  for client_id, result in pairs(results) do
    for _, action in pairs(result.result or {}) do
      if action_filter(action) then table.insert(action_tuples, { client_id, action }) end
    end
  end

  if #action_tuples == 0 then
    vim.notify("No code actions available", vim.log.levels.INFO)
    return
  end

  if options.first or (options.apply and #action_tuples == 1) then
    on_select(action_tuples[1])
  else
    if config.options.popup.enable then
      popup.select(action_tuples, on_select)
    else
      vim.ui.select(action_tuples, {
        prompt = "Code actions:",
        kind = "codeaction",
        format_item = function(action_tuple)
          local action = action_tuple[2]
          return vim.trim(action.title)
        end,
      }, on_select)
    end
  end
end

---Custom implementation of `vim.lsp.buf.code_action()`
---@see vim.lsp.buf.code_action
local function code_action(options)
  options = options or {}

  local params = {}
  local bufnr = vim.api.nvim_get_current_buf()
  local context = options.context or {}

  if not context.triggerKind then
    context.triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked
  end
  if not context.diagnostics then
    context.diagnostics = vim.lsp.diagnostic.get_line_diagnostics(bufnr)
  end

  if options.range then
    local start = options.range.start
    local end_ = options.range["end"]
    params = vim.lsp.util.make_given_range_params(start, end_)
  else
    params = vim.lsp.util.make_range_params()
  end

  params.context = context

  utils.code_action_request_all(bufnr, params, function(results)
    local ctx = { bufnr = bufnr }
    on_code_action_results(results, ctx, options)
  end)
end

local function apply_kind(kind)
  code_action({
    apply = true,
    context = {
      only = { kind },
    },
  })
end

---@param prefix string
M.apply = function(prefix)
  code_action({
    apply = true,
    filter = function(action)
      local title = vim.fn.trim(action.title)
      return vim.startswith(title, prefix)
    end,
  })
end

---@param filters table<string, string> | nil
M.quickfix = function(filters)
  code_action({
    apply = true,
    context = {
      only = { "quickfix" },
    },
    filter = function(action)
      local found = false
      local diagnostics = vim.lsp.diagnostic.get_line_diagnostics()
      for diag_code, fix_message in pairs(filters or {}) do
        for _, diagnostic in pairs(diagnostics) do
          if diagnostic.code == diag_code then
            found = true
            local title = vim.fn.trim(action.title)
            if vim.startswith(title, fix_message) then return true end
          end
        end
      end
      return not found
    end,
  })
end

---@param filters table<string, string> | nil
M.quickfix_next = function(filters)
  vim.diagnostic.goto_next()
  M.quickfix(filters)
end

---@param filters table<string, string> | nil
M.quickfix_prev = function(filters)
  vim.diagnostic.get_prev()
  M.quickfix(filters)
end

M.apply_first = function() code_action({ first = true }) end
M.refactor = function() apply_kind("refactor") end
M.refactor_inline = function() apply_kind("refactor.inline") end
M.refactor_extract = function() apply_kind("refactor.extract") end
M.refactor_rewrite = function() apply_kind("refactor.rewrite") end
M.source = function() apply_kind("source") end
M.code_action = code_action

return M
