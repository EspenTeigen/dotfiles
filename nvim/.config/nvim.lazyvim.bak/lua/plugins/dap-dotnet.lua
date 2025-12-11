return {
  "mfussenegger/nvim-dap",
  opts = function()
    local dap = require("dap")

    -- Find netcoredbg from Mason
    local netcoredbg_path = vim.fn.stdpath("data") .. "/mason/packages/netcoredbg/netcoredbg"

    dap.adapters.coreclr = {
      type = "executable",
      command = netcoredbg_path,
      args = { "--interpreter=vscode" },
    }

    dap.configurations.cs = {
      {
        type = "coreclr",
        name = "Launch - netcoredbg",
        request = "launch",
        program = function()
          -- Try to find dll automatically
          local cwd = vim.fn.getcwd()
          local dll = vim.fn.glob(cwd .. "/bin/Debug/**/**.dll", false, true)
          if #dll > 0 then
            -- Filter out ref assemblies and pick main one
            for _, d in ipairs(dll) do
              if not d:match("/ref/") and not d:match("%.resources%.dll$") then
                return vim.fn.input("Path to dll: ", d, "file")
              end
            end
          end
          return vim.fn.input("Path to dll: ", cwd .. "/bin/Debug/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
      },
      {
        type = "coreclr",
        name = "Attach - netcoredbg",
        request = "attach",
        processId = require("dap.utils").pick_process,
      },
    }
  end,
  keys = {
    { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Conditional Breakpoint" },
    { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
  },
}
