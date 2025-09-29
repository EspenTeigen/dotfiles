return {
  "GustavEikaas/easy-dotnet.nvim",
  -- Only load if dotnet is available
  cond = function()
    return vim.fn.executable("dotnet") == 1
  end,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "saghen/blink.cmp"
  },
  config = function()
    require("easy-dotnet").setup({
      secrets = true,
      csproj_mappings = true,
      auto_bootstrap_namespace = true,
      terminal = function(path, action, args)
        local command = string.format("dotnet %s %s %s", action, path, args or "")

        -- For run commands, always create a new terminal
        if action == "run" then
          -- Kill any existing dotnet terminal and its process
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf) then
              local buf_name = vim.api.nvim_buf_get_name(buf)
              if buf_name:match("term://.*dotnet") then
                -- Get the terminal job id and kill it
                local job_id = vim.api.nvim_buf_get_var(buf, "terminal_job_id")
                if job_id then
                  vim.fn.jobstop(job_id)
                end
                vim.api.nvim_buf_delete(buf, { force = true })
              end
            end
          end
          vim.cmd("15split")
          vim.cmd("term " .. command)
        else
          -- For other commands, reuse existing terminal
          local existing_buf = nil
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf) then
              local buf_name = vim.api.nvim_buf_get_name(buf)
              if buf_name:match("term://.*dotnet") then
                existing_buf = buf
                break
              end
            end
          end

          if existing_buf then
            local wins = vim.fn.win_findbuf(existing_buf)
            if #wins > 0 then
              vim.api.nvim_set_current_win(wins[1])
            else
              vim.cmd("15split")
              vim.api.nvim_win_set_buf(0, existing_buf)
            end
          else
            vim.cmd("15split")
            vim.cmd("term " .. command)
          end
        end
      end
    })
  end,
}