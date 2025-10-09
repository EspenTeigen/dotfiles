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

-- Which-key group for obsidian and dotnet
local wk = require("which-key")
wk.add({
  { "<leader>o", group = "obsidian" },
  { "<leader>c", group = "code" },
})

-- Easy-dotnet keymaps
vim.keymap.set("n", "<leader>ce", "<cmd>Dotnet<cr>", { desc = "Easy Dotnet" })

-- Kill running dotnet processes
vim.keymap.set("n", "<leader>ck", function()
  -- Kill all dotnet terminals and their processes
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name:match("term://.*dotnet") then
        local job_id = vim.api.nvim_buf_get_var(buf, "terminal_job_id")
        if job_id then
          vim.fn.jobstop(job_id)
        end
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end
  -- Kill any remaining dotnet run processes
  vim.fn.system("pkill -f 'dotnet.*run'")
  vim.notify("Killed all running dotnet processes", vim.log.levels.INFO)
end, { desc = "Kill dotnet processes" })
