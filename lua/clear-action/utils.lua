local M = {}

local function apply_action(action, client, ctx)
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
  elseif action.command then
    local command = type(action.command) == "table" and action.command or action
    client._exec_cmd(command, ctx)
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
  local dyn_cap = client.dynamic_capabilities
  local reg = dyn_cap and dyn_cap:get("textDocument/codeAction", { bufnr = context.bufnr })
  local supports_resolve = vim.tbl_get(reg or {}, "registerOptions", "resolveProvider")
    or client.supports_method("codeAction/resolve")

  if not action.edit and client and supports_resolve then
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

return M
