-- Suppress annoying LSP stderr messages
return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      -- Completely suppress stderr output for LSP clients
      local notify = vim.notify
      vim.notify = function(msg, ...)
        if type(msg) == "string" then
          -- Filter out all these annoying messages
          if msg:match("stderr") or
             msg:match("Could not execute") or
             msg:match("dotnet server") or
             msg:match("Client.*quit") or
             msg:match("Roslyn server") then
            return
          end
        end
        notify(msg, ...)
      end
    end,
  },
}
