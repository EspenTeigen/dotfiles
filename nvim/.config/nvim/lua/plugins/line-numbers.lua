return {
  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      -- Custom line number colors for Tokyo Night
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          -- Only apply if using Tokyo Night theme
          if vim.g.colors_name and string.match(vim.g.colors_name, "tokyonight") then
            -- Current line number (center marker)
            vim.api.nvim_set_hl(0, "LineNr", { fg = "#7aa2f7", bold = true })

            -- Lines above current line (use a cooler tone)
            vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#7dcfff" })

            -- Lines below current line (use a warmer tone)
            vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#bb9af7" })
          end
        end,
      })
    end,
  },
}