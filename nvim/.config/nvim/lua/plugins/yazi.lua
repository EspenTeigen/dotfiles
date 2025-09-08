return {
  "mikavilpas/yazi.nvim", -- Or the yazi.nvim fork you prefer
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
  keys = {
    -- 👇 in this section, choose your own keymappings!
    {
      "<leader>a",
      mode = { "n", "v" },
      "<cmd>Yazi<cr>",
      desc = "Open yazi at the current file",
    },
    {
      -- Open in the current working directory
      "<leader>aw",
      "<cmd>Yazi cwd<cr>",
      desc = "Open the file manager in nvim's working directory",
    },
    {
      "<c-up>",
      "<cmd>Yazi toggle<cr>",
      desc = "Resume the last yazi session",
    },
  },
}
