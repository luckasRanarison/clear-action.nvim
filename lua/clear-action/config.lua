local M = {}

---@class clear-action.options
local defaults = {
  silent = true,
  signs = {
    enable = true,
    combine = false,
    priority = 200,
    position = "eol", -- "right_align" | "overlay""
    separator = " ",
    show_count = true,
    show_label = false,
    label_fmt = function(actions) return actions[1].title end,
    update_on_insert = false,
    icons = {
      quickfix = "🔧",
      refactor = "💡",
      source = "🔗",
      combined = "💡",
    },
    highlights = {
      quickfix = "NonText",
      refactor = "NonText",
      source = "NonText",
      combined = "NonText",
      label = "NonText",
    },
  },
  popup = {
    enable = true,
    center = false,
    border = "rounded",
    hide_cursor = false,
    highlights = {
      header = "CodeActionHeader",
      label = "CodeActionLabel",
      title = "CodeActionTitle",
      lsp = "Comment",
    },
  },
  mappings = {
    code_action = nil,
    apply_first = nil,
    quickfix = nil,
    quickfix_next = nil,
    quickfix_prev = nil,
    refactor = nil,
    refactor_inline = nil,
    refactor_extract = nil,
    refactor_rewrite = nil,
    source = nil,
    actions = {},
  },
  quickfix_filters = {},
  action_labels = {},
}

---@type clear-action.options
M.options = {}

M.ns = vim.api.nvim_create_namespace("clear-action")
M.ns_popup = vim.api.nvim_create_namespace("clear-action-popup")

M.augroup = vim.api.nvim_create_augroup("clear-action", {})

---@param options clear-action.options
M.setup = function(options) M.options = vim.tbl_deep_extend("force", defaults, options or {}) end

return M
