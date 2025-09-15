-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("x", "p", '"_dP', { desc = "Safe paste in visual mode" })
vim.keymap.set("n", "<leader>;", function()
  local line = vim.api.nvim_get_current_line()
  if not line:match(";$") then
    vim.api.nvim_set_current_line(line .. ";")
  end
end, { noremap = true, silent = true, desc = "Add semicolon at end of line" })

-- Which-key group for obsidian
local wk = require("which-key")
wk.add({
  { "<leader>o", group = "obsidian" },
})
