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
      local cmp = require("cmp")
      table.insert(opts.sources, { name = "easy-dotnet" })

      opts.mapping = vim.tbl_extend("force", opts.mapping or {}, {
        ["<Up>"] = cmp.mapping.select_prev_item(),
        ["<Down>"] = cmp.mapping.select_next_item(),
      })
    end,
  },
}
