return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      preset = "enter", -- Use arrow keys for both LSP and cmdline
      ["<C-y>"] = { "select_and_accept" },
    },
    completion = {
      menu = {
        max_height = 10, -- Limit menu height to reduce screen real estate
        scrollbar = true,
        direction_priority = { "s", "n" }, -- Prefer showing below cursor, then above
        auto_show = function(ctx)
          -- Only show menu after typing 2+ characters to reduce noise
          return ctx.trigger.kind == vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter or #ctx.line:sub(1, ctx.cursor[2]):match("[%w_]+$") >= 2
        end,
        winhighlight = "Normal:BlinkCmpMenu,CursorLine:BlinkCmpMenuSel", -- Custom highlight groups for transparency
        winblend = 15, -- Add transparency (0=opaque, 100=fully transparent)
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 500, -- Delay showing docs to avoid immediate popup
        window = {
          max_width = 80,
          max_height = 20,
          border = "rounded",
          winblend = 15, -- Make documentation window translucent too
        },
      },
      ghost_text = {
        enabled = true, -- Shows inline preview without blocking view
      },
    },
    cmdline = {
      enabled = true,
      keymap = { preset = "enter" }, -- Change from "cmdline" to "enter"
      completion = {
        list = { selection = { preselect = false } },
        menu = {
          auto_show = function(ctx)
            return vim.fn.getcmdtype() == ":"
          end,
        },
        ghost_text = { enabled = true },
      },
    },
  },
}