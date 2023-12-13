# clear-action.nvim

A simple Neovim plugin that enhances LSP code actions with fully customizable signs, personalized actions, and server-specific mappings, making code actions more predictable.

![Preview](https://github.com/luckasRanarison/clear-action.nvim/assets/101930730/73d57753-1e9f-4d48-903b-8646908a127f)

![Preview](https://github.com/luckasRanarison/clear-action.nvim/assets/101930730/bdf6be6c-e463-4b60-98f7-d5d2aea4450d)

## Installation

Using Lazy:

```lua
{
  "luckasRanarison/clear-action.nvim",
  opts = {}
}
```

Using packer:

```lua
use {
  "luckasRanarison/clear-action.nvim",
  config = function()
    require("clear-action").setup({})
  end
}
```

## Configuration

The default configuration:

```lua
{
  silent = true, -- dismiss code action requests errors
  signs = {
    enable = true,
    combine = false, -- combines all action kinds into a single sign
    priority = 200, -- extmark priority
    position = "eol", -- "right_align" | "overlay"
    separator = " ", -- signs separator
    show_count = true, -- show the number of each action kind
    show_label = false, -- show the string returned by `label_fmt`
    label_fmt = function(actions) return actions[1].title end, -- actions is an array of `CodeAction`
    update_on_insert = false, -- show and update signs in insert mode
    icons = {
      quickfix = "🔧",
      refactor = "💡",
      source = "🔗",
      combined = "💡", -- used when combine is set to true or as a fallback when there is no action kind
    },
    highlights = { -- highlight groups
      quickfix = "NonText",
      refactor = "NonText",
      source = "NonText",
      combined = "NonText",
      label = "NonText",
    },
  },
  popup = { -- replaces the default prompt when selecting code actions
    enable = true,
    center = false,
    border = "rounded",
    hide_cursor = false,
    hide_client = false, -- hide displaying name of LSP client
    highlights = {
      header = "CodeActionHeader",
      label = "CodeActionLabel",
      title = "CodeActionTitle",
    },
  },
  mappings = {
    -- The values can either be a string or a string tuple (with description)
    -- example: "<leader>aq" | { "<leader>aq", "Quickfix" }
    -- Or if you want more control: { key = "<leader>aq", mode = { "n" }, options = { desc = "Quickfix" } }
    -- `options` accetps the same keys as vim.keymap.set()
    code_action = nil, -- a modified version of `vim.lsp.buf.code_action`
    apply_first = nil, -- directly applies the first code action
    -- These are just basically `vim.lsp.buf.code_action` with the `apply` option with some filters
    -- If there's only one code action, it gets automatically applied.
    quickfix = nil, -- can be filtered with the `quickfix_filter` option bellow
    quickfix_next = nil, -- tries to fix the next diagnostic
    quickfix_prev = nil, -- tries to fix the previous diagnostic
    refactor = nil,
    refactor_inline = nil,
    refactor_extract = nil,
    refactor_rewrite = nil,
    source = nil,
    -- server-specific mappings, server_name = {...}
    -- This is a map of code actions prefixes and keys
    actions = {
      -- example:
      -- ["rust_analyzer"] = {
      --   ["Inline"] = "<leader>ai"
      --   ["Add braces"] = { "<leader>ab", "Add braces" }
      -- }
    },
  },
  -- This is used for filtering actions in the quickfix functions
  -- It's a map of diagnostic codes and the preferred action prefixes
  -- You can check the diagnostic codes by hovering on the diagnostic
  quickfix_filters = {
    -- example:
    -- ["rust_analyzer"] = {
    --   ["E0433"] = "Import",
    -- },
    -- ["lua_ls"] = {
    --   ["unused-local"] = "Disable diagnostics on this line",
    -- },
  },
}
```

## Commands

Available commands:

- `CodeActionToggleSigns`: Toggle the signs.
- `CodeActionToggleLabel`: Toggle the label.

## Contributing

Issues, pull requests, ideas and feature requests are all welcome!
