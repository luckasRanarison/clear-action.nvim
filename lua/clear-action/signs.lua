local M = {}

local config = require("clear-action.config")
local utils = require("clear-action.utils")

local clear_extmark = function() vim.api.nvim_buf_clear_namespace(0, config.ns, 0, -1) end

local function on_result(results_all, line, bufnr)
  local count = 0
  local flat = {}

  for client_id, results in pairs(results_all) do
    if results.result ~= nil then
      count = count + #results.result
      for _, action in pairs(results.result) do
        table.insert(flat, vim.tbl_extend("error", action, { client_id = client_id }))
      end
    end
  end

  local virt_text = {}
  local opts = config.options.signs

  if opts.combine and count > 0 then
    table.insert(virt_text, {
      opts.icons.combined .. (opts.show_count and count or ""),
      opts.highlights.combined,
    })
  else
    local actions = { quickfix = 0, refactor = 0, source = 0, combined = 0 }

    for _, action in pairs(flat) do
      if action.kind then
        for key, value in pairs(actions) do
          if vim.startswith(action.kind, key) then
            actions[key] = value + 1
          end
        end
      else
        actions.combined = actions.combined + 1
      end
    end
    for key, _ in pairs(actions) do
      if actions[key] > 0 then
        if #virt_text > 0 then table.insert(virt_text, { opts.separator }) end
        table.insert(virt_text, {
          opts.icons[key] .. (opts.show_count and actions[key] or ""),
          opts.highlights[key],
        })
      end
    end
  end

  if count > 0 and opts.show_label then
    table.insert(virt_text, { opts.separator })
    table.insert(virt_text, { opts.label_fmt(flat), opts.highlights.label })
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local col = opts.position == "overlay" and (cursor[2] + 1) or 0
  local is_insert = vim.fn.mode() == "i"
  local update = opts.update_on_insert == is_insert

  clear_extmark()

  if line == cursor[1] - 1 and update then
    vim.api.nvim_buf_set_extmark(bufnr, config.ns, line, col, {
      hl_mode = "combine",
      virt_text = virt_text,
      virt_text_pos = opts.position,
      priority = opts.priority,
    })
  end
end

local function code_action_request()
  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_range_params()

  params.context = {
    triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Automatic,
    diagnostics = utils.get_current_line_diagnostics(),
  }
  utils.code_action_request_all(bufnr, params, on_result)
end

local function update()
  clear_extmark()
  if config.options.signs.enable then code_action_request() end
end

M.on_attach = function(bufnr)
  local events = { "CursorMoved", "TextChanged" }

  if config.options.signs.update_on_insert then
    vim.list_extend(events, { "CursorMovedI", "TextChangedI" })
  else
    vim.api.nvim_create_autocmd("InsertEnter", {
      buffer = bufnr,
      group = config.augroup,
      callback = clear_extmark,
    })
  end

  if vim.b[bufnr].is_update_autocmd_set then
    return
  end
  vim.api.nvim_create_autocmd(events, {
    buffer = bufnr,
    group = config.augroup,
    callback = update,
  })
  vim.b[bufnr].is_update_autocmd_set = true
end

M.toggle_signs = function()
  config.options.signs.enable = not config.options.signs.enable
  update()
end

M.toggle_label = function()
  config.options.signs.show_label = not config.options.signs.show_label
  update()
end

return M
