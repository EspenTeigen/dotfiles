return {
  "GustavEikaas/easy-dotnet.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  ft = { "cs", "fsharp", "vb", "csproj", "fsproj", "sln" },
  config = function()
    require("easy-dotnet").setup({
      -- Roslyn LSP (replaces OmniSharp)
      lsp = {
        enabled = true,
        roslynator_enabled = true,
        analyzer_assemblies = {},
        config = {},
      },
      -- DAP integration with netcoredbg
      debugger = {
        bin_path = nil, -- auto-detect from Mason
        auto_register_dap = true,
        mappings = {
          open_variable_viewer = { lhs = "T", desc = "open variable viewer" },
        },
      },
      -- Test runner
      test_runner = {
        viewmode = "float",
        enable_buffer_test_execution = true,
        noBuild = true,
        mappings = {
          run_test_from_buffer = { lhs = "<leader>r", desc = "run test from buffer" },
          debug_test = { lhs = "<leader>d", desc = "debug test" },
          run_all = { lhs = "<leader>R", desc = "run all tests" },
        },
      },
      -- Project file completion
      csproj_mappings = true,
      fsproj_mappings = true,
      -- Telescope for picking
      picker = "telescope",
    })
  end,
}
