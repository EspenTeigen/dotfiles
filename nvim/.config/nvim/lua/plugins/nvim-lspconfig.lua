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
        omnisharp = {
          settings = {
            RoslynExtensionsOptions = {
              EnableImportCompletion = true,
              EnableDecompilationSupport = true,
              InlayHintsOptions = {
                EnableForParameters = false,
                EnableForLiteralParameters = false,
                EnableForIndexerParameters = false,
                EnableForObjectCreationParameters = false,
                EnableForOtherParameters = false,
                SuppressForParametersThatDifferOnlyBySuffix = false,
                SuppressForParametersThatMatchMethodIntent = false,
                SuppressForParametersThatMatchArgumentName = false,
                EnableForTypes = false,
                EnableForImplicitVariableTypes = false,
                EnableForLambdaParameterTypes = false,
                EnableForImplicitObjectCreation = false,
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
