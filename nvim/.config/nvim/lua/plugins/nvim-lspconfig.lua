return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
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
    },
  },
}
