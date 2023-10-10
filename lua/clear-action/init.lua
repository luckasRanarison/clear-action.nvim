local M = {}

local config = require("clear-action.config")
local signs = require("clear-action.signs")
local mappings = require("clear-action.mappings")
local actions = require("clear-action.actions")
local popup = require("clear-action.popup")

M.setup = function(options)
  config.setup(options)

  vim.api.nvim_create_autocmd("LspAttach", {
    group = config.augroup,
    callback = function(args)
      local bufnr = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local cmd = vim.api.nvim_buf_create_user_command

      if client and client.supports_method("textDocument/codeAction") then return end

      signs.on_attach(bufnr)
      mappings.on_attach(bufnr, client)

      if config.options.popup.hide_cursor then popup.hide_cursor_autocmd() end

      cmd(bufnr, "CodeActionToggleSigns", signs.toggle_signs, {})
      cmd(bufnr, "CodeActionToggleLabel", signs.toggle_label, {})
    end,
  })
end

M.code_action = actions.code_action

return M
