-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Clipboard configuration for Wayland
vim.opt.clipboard = "unnamedplus"

-- Debug root detection (remove after testing)
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    print("LazyVim root: " .. LazyVim.root.get())
    print("cwd: " .. vim.fn.getcwd())
  end,
})
