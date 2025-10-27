return {
  "saghen/blink.cmp",
  version = 'v0.*',
  opts = function(_, opts)
    -- Completely replace cmdline.keymap to avoid LazyVim's invalid boolean values
    opts.cmdline = opts.cmdline or {}
    opts.cmdline.enabled = true
    opts.cmdline.keymap = { preset = "enter" } -- Replace entirely, don't merge
    opts.cmdline.completion = {
      list = { selection = { preselect = false } },
      menu = {
        auto_show = function(ctx)
          return vim.fn.getcmdtype() == ":"
        end,
      },
      ghost_text = { enabled = true },
    }

    -- Apply your custom completion settings
    opts.keymap = vim.tbl_deep_extend("force", opts.keymap or {}, {
      preset = "enter",
      ["<C-y>"] = { "select_and_accept" },
    })

    -- Ensure LSP source is enabled (it's enabled by default in blink.cmp)
    -- We don't need to override it, just make sure we're not disabling it

    opts.completion = vim.tbl_deep_extend("force", opts.completion or {}, {
      menu = {
        max_height = 10,
        scrollbar = true,
        direction_priority = { "s", "n" },
        auto_show = true,
        winhighlight = "Normal:BlinkCmpMenu,CursorLine:BlinkCmpMenuSel",
        winblend = 15,
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 500,
        window = {
          max_width = 80,
          max_height = 20,
          border = "rounded",
          winblend = 15,
        },
      },
      ghost_text = {
        enabled = true,
      },
    })

    return opts
  end,
}