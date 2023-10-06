local M = {}

local function apply_action(action, client, ctx)
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
  elseif action.command then
    local command = type(action.command) == "table" and action.command or action
    local fn = client.commands[command.command] or vim.lsp.commands[command.command]

    if fn then
      ctx.client_id = client.id
      fn(command, ctx)
    else
      local params = {
        command = command.command,
        arguments = command.arguments,
        workDoneToken = command.workDoneToken,
      }
      client.request("workspace/executeCommand", params, nil, ctx.bufnr)
    end
  end
end

M.code_action_request = function(bufnr, params, on_result)
  vim.lsp.buf_request(bufnr, "textDocument/codeAction", params, function(error, results, context)
    if error then
      local message = type(error) == "string" and error or error.message
      vim.notify("code action: " .. message, vim.log.levels.WARN)
    end
    if results then on_result(results, context) end
  end)
end

M.code_action_request_all = function(bufnr, params, on_result)
  vim.lsp.buf_request_all(bufnr, "textDocument/codeAction", params, function(results)
    if results then on_result(results) end
  end)
end

M.handle_action = function(action, client, context)
  local supports_resolve = client
    and vim.tbl_get(client.server_capabilities, "codeActionProvider", "resolveProvider")

  if not action.edit and supports_resolve then
    client.request("codeAction/resolve", action, function(err, resolved_action)
      if err then
        vim.notify(err.code .. ": " .. err.message, vim.log.levels.ERROR)
        return
      end
      apply_action(resolved_action, client, context)
    end, context.bufnr)
  else
    apply_action(action, client, context)
  end
end

M.range_from_selection = function(bufnr, mode)
  local start = vim.fn.getpos("v")
  local end_ = vim.fn.getpos(".")
  local start_row = start[2]
  local start_col = start[3]
  local end_row = end_[2]
  local end_col = end_[3]

  -- A user can start visual selection at the end and move backwards
  -- Normalize the range to start < end
  if start_row == end_row and end_col < start_col then
    end_col, start_col = start_col, end_col
  elseif end_row < start_row then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end
  if mode == "V" then
    start_col = 1
    local lines = vim.api.nvim_buf_get_lines(bufnr, end_row - 1, end_row, true)
    end_col = #lines[1]
  end
  return {
    ["start"] = { start_row, start_col - 1 },
    ["end"] = { end_row, end_col - 1 },
  }
end

return M
