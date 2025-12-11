return {
  "harrisoncramer/gitlab.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "sindrets/diffview.nvim",
    "stevearc/dressing.nvim",
  },
  build = function()
    require("gitlab.server").build(true)
  end,
  opts = {
    auth_provider = function()
      local handle = io.popen(
        'printf "protocol=https\\nhost=gitlab.ispas.no" | git credential fill 2>/dev/null | grep "^password=" | cut -d= -f2'
      )
      if handle then
        local token = handle:read("*a"):gsub("%s+$", "")
        handle:close()
        if token and token ~= "" then
          return token, "https://gitlab.ispas.no", nil
        end
      end
      return nil, nil, "Failed to retrieve GitLab token from git credentials"
    end,
  },
  keys = {
    { "<leader>gl", "", desc = "+GitLab", mode = "n" },
    { "<leader>glr", "<cmd>lua require('gitlab').review()<cr>", desc = "Review MR" },
    { "<leader>gls", "<cmd>lua require('gitlab').summary()<cr>", desc = "MR Summary" },
    { "<leader>glA", "<cmd>lua require('gitlab').approve()<cr>", desc = "Approve MR" },
    { "<leader>glR", "<cmd>lua require('gitlab').revoke()<cr>", desc = "Revoke approval" },
    { "<leader>glc", "<cmd>lua require('gitlab').create_comment()<cr>", desc = "Create comment" },
    { "<leader>gln", "<cmd>lua require('gitlab').create_note()<cr>", desc = "Create note" },
    { "<leader>gld", "<cmd>lua require('gitlab').toggle_discussions()<cr>", desc = "Toggle discussions" },
    { "<leader>glp", "<cmd>lua require('gitlab').pipeline()<cr>", desc = "Pipeline status" },
    { "<leader>glo", "<cmd>lua require('gitlab').open_in_browser()<cr>", desc = "Open in browser" },
    { "<leader>glm", "<cmd>lua require('gitlab').merge()<cr>", desc = "Merge MR" },
    { "<leader>glM", "<cmd>lua require('gitlab').create_mr()<cr>", desc = "Create MR" },
    { "<leader>glq", "<cmd>lua require('gitlab').close_review()<cr>", desc = "Close review" },
  },
}
