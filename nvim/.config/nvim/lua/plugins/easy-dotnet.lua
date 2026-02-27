return {
  "GustavEikaas/easy-dotnet.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "mfussenegger/nvim-dap",
  },
  ft = { "cs", "fsharp", "vb", "csproj", "fsproj", "sln" },
  config = function()
    require("easy-dotnet").setup({
      dotnet_cmd = "/usr/bin/dotnet",
      picker = "telescope",
      terminal = function(path, action, args, ctx)
        args = args or ""
        local command = ctx and ctx.cmd or string.format("dotnet %s --project %s %s", action, path, args)

        -- Find and close existing dotnet terminal
        local term_bufs = vim.tbl_filter(function(buf)
          return vim.bo[buf].buftype == "terminal" and vim.api.nvim_buf_get_name(buf):match("dotnet")
        end, vim.api.nvim_list_bufs())

        for _, buf in ipairs(term_bufs) do
          local wins = vim.fn.win_findbuf(buf)
          for _, win in ipairs(wins) do
            vim.api.nvim_win_close(win, true)
          end
          vim.api.nvim_buf_delete(buf, { force = true })
        end

        vim.cmd("botright split | resize 15")
        vim.cmd("term " .. command)
      end,
      debugger = {
        auto_register_dap = true,
        mappings = {
          open_variable_viewer = { lhs = "T", desc = "open variable viewer" },
        },
      },
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
    })

    -- Kill dotnet terminal buffers when their window is closed
    vim.api.nvim_create_autocmd("WinClosed", {
      group = vim.api.nvim_create_augroup("EasyDotnetTerminalCleanup", { clear = true }),
      callback = function(ev)
        local buf = vim.fn.winbufnr(ev.match)
        if buf ~= -1 and vim.api.nvim_buf_is_valid(buf) then
          local bufname = vim.api.nvim_buf_get_name(buf)
          if vim.bo[buf].buftype == "terminal" and bufname:match("dotnet") then
            vim.schedule(function()
              if vim.api.nvim_buf_is_valid(buf) and #vim.fn.win_findbuf(buf) == 0 then
                vim.api.nvim_buf_delete(buf, { force = true })
              end
            end)
          end
        end
      end,
    })
  end,
}
