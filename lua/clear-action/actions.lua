local M = {}

local code_action = vim.lsp.buf.code_action

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

M.refactor = function() apply_kind("refactor") end

M.refactor_inline = function() apply_kind("refactor.inline") end

M.refactor_extract = function() apply_kind("refactor.extract") end

M.refactor_rewrite = function() apply_kind("refactor.rewrite") end

M.source = function() apply_kind("source") end

return M
