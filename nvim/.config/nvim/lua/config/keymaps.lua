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
  { "<leader>m", group = "markdown" },
})

-- DAP keymaps (supplements LazyVim defaults)
vim.keymap.set("n", "<leader>di", function()
  require("dap").step_into()
end, { desc = "Step Into" })

vim.keymap.set("n", "<leader>do", function()
  require("dap").step_over()
end, { desc = "Step Over" })

vim.keymap.set("n", "<leader>du", function()
  require("dap").step_out()
end, { desc = "Step Out" })

vim.keymap.set("n", "<leader>de", function()
  require("dap").set_exception_breakpoints({ "all" })
end, { desc = "Exception Breakpoints" })

vim.keymap.set("n", "<leader>dq", function()
  require("dap").terminate()
  require("dapui").close()
end, { desc = "Quit/Terminate Debug" })

vim.keymap.set("n", "<leader>dL", function()
  require("dap").list_breakpoints()
  vim.cmd("copen")
end, { desc = "List Breakpoints" })

vim.keymap.set("n", "<leader>dC", function()
  require("dap").repl.clear()
end, { desc = "Clear REPL" })

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

-- Markdown PDF export
vim.keymap.set("n", "<leader>mr", function()
  local file = vim.fn.expand("%:p")
  local output = vim.fn.expand("%:p:r") .. ".pdf"
  local cmd = string.format("pandoc --from=markdown --to=pdf '%s' --output '%s' --pdf-engine=weasyprint 2>&1", file, output)
  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("PDF export failed: " .. result, vim.log.levels.ERROR)
  else
    vim.notify("PDF exported to: " .. output, vim.log.levels.INFO)
  end
end, { desc = "Render PDF" })
