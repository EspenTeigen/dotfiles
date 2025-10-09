-- Conditional OmniSharp setup - only load if dotnet is available
return {
  {
    "Hoffs/omnisharp-extended-lsp.nvim",
    lazy = true,
    cond = function()
      return vim.fn.executable("dotnet") == 1
    end,
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      {
        "Issafalcon/neotest-dotnet",
        cond = function()
          return vim.fn.executable("dotnet") == 1
        end,
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Only configure omnisharp if dotnet is available
      if vim.fn.executable("dotnet") == 1 then
        opts.servers = opts.servers or {}
        opts.servers.omnisharp = {
          handlers = {
            ["textDocument/definition"] = function(...)
              return require("omnisharp_extended").handler(...)
            end,
          },
          enable_roslyn_analyzers = true,
          organize_imports_on_format = true,
          enable_import_completion = true,
        }
      end
    end,
    keys = {
      {
        "gd",
        function()
          require("omnisharp_extended").telescope_lsp_definitions()
        end,
        desc = "Goto Definition",
        ft = "cs",
      },
    },
  },
}