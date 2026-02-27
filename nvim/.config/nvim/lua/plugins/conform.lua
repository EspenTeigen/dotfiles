return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      xml = { "xmllint" },
      axaml = { "xmllint" },
      text = { "fold" },
      markdown = { "prettier" },
    },
    formatters = {
      xmllint = {
        command = "xmllint",
        args = { "--format", "-" },
        stdin = true,
      },
      fold = {
        command = "fold",
        args = { "-s", "-w", "80" },
        stdin = true,
      },
      prettier = {
        command = "prettier",
        args = { "--prose-wrap", "always", "--print-width", "80", "--stdin-filepath", "$FILENAME" },
        stdin = true,
      },
    },
  },
}
