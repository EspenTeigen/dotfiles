return {
  "mfussenegger/nvim-dap",
  config = function()
    local dap = require("dap")

    dap.adapters.coreclr = {
      type = "executable",
      command = vim.fn.expand("~/.vscode/extensions/ms-dotnettools.csharp-2.110.4-linux-x64/.debugger/vsdbg"),
      args = { "--interpreter=vscode" },
    }

    dap.adapters.coreclr_remote = {
      type = "executable",
      command = "ssh",
      args = { "test-laptop", "netcoredbg", "--interpreter=vscode" },
    }

    local function to_remote_path(local_path)
      return local_path:gsub(vim.fn.expand("~/remote/test%-laptop"), "/home/ispas")
    end

    local function pick_remote_dll(callback)
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      -- Find all csproj files
      local csproj_files = vim.fn.globpath(vim.fn.getcwd(), "**/*.csproj", false, true)

      if #csproj_files == 0 then
        vim.notify("No .csproj files found", vim.log.levels.WARN)
        callback(vim.fn.input("Path to dll: "))
        return
      end

      pickers.new({}, {
        prompt_title = "Select project to debug (remote)",
        finder = finders.new_table({
          results = csproj_files,
          entry_maker = function(entry)
            local name = vim.fn.fnamemodify(entry, ":t:r")
            return {
              value = entry,
              display = name,
              ordinal = name,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            local csproj = selection.value
            local project_name = vim.fn.fnamemodify(csproj, ":t:r")
            local project_dir = vim.fn.fnamemodify(csproj, ":h")
            local dll_path = to_remote_path(project_dir) .. "/bin/Debug/net8.0/" .. project_name .. ".dll"
            callback(dll_path)
          end)
          return true
        end,
      }):find()
    end

    vim.keymap.set("n", "<leader>dr", function()
      pick_remote_dll(function(dll_path)
        dap.run({
          name = "Remote: Launch",
          type = "coreclr_remote",
          request = "launch",
          program = dll_path,
          cwd = to_remote_path(vim.fn.getcwd()),
        })
      end)
    end, { desc = "Debug remote" })

    -- Logpoint: logs message on every hit, never stops
    vim.keymap.set("n", "<leader>dT", function()
      dap.set_breakpoint(nil, nil, vim.fn.input("Log message: "))
    end, { desc = "Tracepoint (log every hit)" })

    -- Conditional logpoint: logs message only when condition is true
    vim.keymap.set("n", "<leader>dM", function()
      local condition = vim.fn.input("Condition: ")
      local message = vim.fn.input("Log message: ")
      dap.set_breakpoint(condition, nil, message)
    end, { desc = "Conditional logpoint" })
  end,
}
