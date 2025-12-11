return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Ensure servers table exists
      opts.servers = opts.servers or {}

      -- Add Avalonia LSP configuration
      opts.servers.avalonia_lsp = {
        cmd = { vim.fn.expand("~/avalonia-lsp-bin/AvaloniaLanguageServer") },
        filetypes = { "xml" },
        root_dir = function(fname)
          local util = require("lspconfig.util")
          -- Ensure fname is a string
          if type(fname) ~= "string" then
            fname = vim.api.nvim_buf_get_name(0)
          end
          return util.root_pattern("*.sln", "*.csproj")(fname)
            or util.find_git_ancestor(fname)
            or vim.fn.getcwd()
        end,
        settings = {},
      }

      return opts
    end,
  },
  {
    -- Setup filetype detection for AXAML files
    "neovim/nvim-lspconfig",
    init = function()
      vim.filetype.add({
        extension = {
          axaml = "xml",
        },
      })
    end,
  },
}
