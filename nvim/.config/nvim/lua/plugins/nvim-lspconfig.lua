return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = {
          cmd = {
            vim.fn.expand("~/.local/share/nvim/mason/packages/omnisharp/OmniSharp"),
            "-z",
            "--hostPID",
            tostring(vim.fn.getpid()),
            "DotNet:enablePackageRestore=false",
            "--encoding",
            "utf-8",
            "--languageserver",
            "Sdk:IncludePrereleases=true",
            "FormattingOptions:EnableEditorConfigSupport=true",
            "FormattingOptions:EnableXmlDocComment=true",
          },
          enable_roslyn_analyzers = true,
          organize_imports_on_format = true,
          enable_import_completion = true,
          -- Override the gd keybinding to use standard LSP instead of omnisharp-extended
          keys = {
            { "gd", vim.lsp.buf.definition, desc = "Goto Definition", mode = "n" },
          },
        },
      },
    },
  },
}
