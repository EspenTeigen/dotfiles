return {
  "GustavEikaas/easy-dotnet.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "saghen/blink.cmp"
  },
  config = function()
    require("easy-dotnet").setup({
      secrets = true,
      csproj_mappings = true,
      auto_bootstrap_namespace = true,
    })
  end,
}