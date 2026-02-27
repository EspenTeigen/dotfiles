return {
  "gbprod/yanky.nvim",
  dependencies = { "kkharji/sqlite.lua" }, -- persistent yank history across sessions
  opts = {
    ring = {
      history_length = 50,
      storage = "sqlite",
    },
    highlight = {
      on_put = true,
      on_yank = true,
      timer = 200,
    },
  },
  keys = {
    { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank" },
    { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put after" },
    { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put before" },
    { "<C-p>", "<Plug>(YankyPreviousEntry)", desc = "Prev yank" },
    { "<C-n>", "<Plug>(YankyNextEntry)", desc = "Next yank" },
    { "<leader>sy", "<cmd>YankyRingHistory<cr>", desc = "Yank history" },
  },
}
