return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Disable omnisharp - using Roslyn via easy-dotnet instead
        omnisharp = false,
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                diagnosticSeverityOverrides = {
                  reportAbstractUsage = "error",
                },
              },
            },
          },
        },
      },
      inlay_hints = {
        enabled = false,
      },
    },
  },
}
