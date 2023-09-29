local M = {}

local config = require("clear-action.config")

local is_sending = false
local extmark_id = nil
local extmark_buf = nil

local function clear_extmark()
  if extmark_buf and vim.api.nvim_buf_is_valid(extmark_buf) and extmark_id then
    vim.api.nvim_buf_del_extmark(extmark_buf, config.ns, extmark_id)
  end
end

local function on_result(results, context)
  local virt_text = {}
  local opts = config.options.signs

  if opts.combine and #results > 0 then
    table.insert(virt_text, {
      opts.icons.combined .. (opts.show_count and #results or ""),
      opts.highlights.combined,
    })
  else
    local actions = { quickfix = 0, refactor = 0, source = 0 }

    for _, action in pairs(results) do
      for key, value in pairs(actions) do
        if vim.startswith(action.kind, key) then actions[key] = value + 1 end
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

  if #results > 0 and opts.show_label then
    table.insert(virt_text, { opts.separator })
    table.insert(virt_text, { opts.label_fmt(results), opts.highlights.label })
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local col = opts.position == "overlay" and (cursor[2] + 1) or 0
  local context_line = context.params.range.start.line
  local is_insert = vim.fn.mode() == "i"
  local update = opts.update_on_insert == is_insert

  clear_extmark()

  if context_line == cursor[1] - 1 and update then
    extmark_buf = context.bufnr
    extmark_id = vim.api.nvim_buf_set_extmark(0, config.ns, context_line, col, {
      hl_mode = "combine",
      virt_text = virt_text,
      virt_text_pos = opts.position,
      priority = 200,
    })
  end
end

local function code_action_request()
  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_range_params()

  params.context = {
    triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Automatic,
    diagnostics = vim.lsp.diagnostic.get_line_diagnostics(),
  }

  is_sending = true

  vim.lsp.buf_request(bufnr, "textDocument/codeAction", params, function(error, results, context)
    is_sending = false

    if error then
      local message = type(error) == "string" and error or error.message
      vim.notify("code action: " .. message, vim.log.levels.WARN)
    end
    if results then on_result(results, context) end
  end)
end

local function update()
  clear_extmark()
  if config.options.signs.enable and not is_sending then
    vim.defer_fn(code_action_request, config.options.signs.timeout)
  end
end

M.on_attach = function(bufnr)
  local events = { "CursorMoved", "TextChanged" }

  if config.options.signs.update_on_insert then
    vim.list_extend(events, { "CursorMovedI, TextChangedI" })
  else
    vim.api.nvim_create_autocmd("InsertEnter", {
      buffer = bufnr,
      group = config.augroup,
      callback = clear_extmark,
    })
  end

  vim.api.nvim_create_autocmd(events, {
    buffer = bufnr,
    group = config.augroup,
    callback = update,
  })
end

M.toggle_signs = function()
  config.options.signs.enable = not config.options.signs.enable
  update()
end

M.toggle_label = function()
  config.options.signs.show_first_label = not config.options.signs.show_first_label
  update()
end

return M
