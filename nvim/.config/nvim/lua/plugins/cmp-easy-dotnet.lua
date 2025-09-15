return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      {
        "GustavEikaas/cmp-easy-dotnet",
        dependencies = { "GustavEikaas/easy-dotnet.nvim" },
        ft = { "cs", "fsharp", "vb" },
      },
    },
    opts = function(_, opts)
      table.insert(opts.sources, { name = "easy-dotnet" })
    end,
  },
}
