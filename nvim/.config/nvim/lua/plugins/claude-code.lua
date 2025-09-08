return {
  "greggh/claude-code.nvim",
  config = function()
    require("claude-code").setup({
      -- Terminal configuration
      terminal = {
        size = 20,
        direction = "horizontal", -- "horizontal", "vertical", "tab", "float"
        float_opts = {
          border = "curved",
          width = 0.9,
          height = 0.8,
        },
      },

      -- Claude Code command
      claude_command = "claude-code",

      -- Auto-reload files when modified by Claude Code
      auto_reload = true,

      -- Show notifications
      notifications = true,
    })
  end,
}

