return {
  "epwalsh/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
  --   -- refer to `:h file-pattern` for more examples
  --   "BufReadPre path/to/my-vault/*.md",
  --   "BufNewFile path/to/my-vault/*.md",
  -- },
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",

    -- see below for full list of optional dependencies 👇
  },
  opts = {
    workspaces = {
      {
        name = "work",
        path = "~/obsidian_vault/",
      },
    },

    -- see below for full list of options 👇
  },
  keys = {
    { "<leader>o", group = "obsidian" },
    { "<leader>oo", "<cmd>ObsidianOpen<cr>", desc = "Open note" },
    { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "New note" },
    { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Search notes" },
    { "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", desc = "Quick switch" },
    { "<leader>ot", "<cmd>ObsidianToday<cr>", desc = "Today's note" },
    { "<leader>op", "<cmd>ObsidianTemplate<cr>", desc = "Insert template" },
    { "<leader>ow", "<cmd>ObsidianWorkspace<cr>", desc = "Switch workspace" },
    { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Show backlinks" },
    { "<leader>ol", "<cmd>ObsidianLinks<cr>", desc = "Show links" },
    { "<leader>of", "<cmd>ObsidianFollowLink<cr>", desc = "Follow link" },
  },
}
