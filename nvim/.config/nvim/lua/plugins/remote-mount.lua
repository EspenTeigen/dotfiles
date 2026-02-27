return {
  "remote-mount",
  virtual = true,
  lazy = true,
  keys = {
    { "<leader>rm", desc = "Mount remote" },
    { "<leader>ru", desc = "Unmount remote" },
  },
  cmd = { "RemoteMount", "RemoteUnmount" },
  config = function()
    local mounts = {
      ["test-laptop"] = {
        remote = "test-laptop:/home/ispas",
        local_path = vim.fn.expand("~/remote/test-laptop"),
      },
    }

    local active_mounts = {}

    local function mount(name)
      local config = mounts[name]
      if not config then
        vim.notify("Unknown remote: " .. name, vim.log.levels.ERROR)
        return
      end

      vim.fn.mkdir(config.local_path, "p")

      local check = vim.fn.system("mountpoint -q " .. config.local_path .. " && echo 'mounted'")
      if check:match("mounted") then
        vim.notify("Already mounted", vim.log.levels.INFO)
        vim.cmd("cd " .. config.local_path)
        vim.cmd("edit .")
        return
      end

      vim.notify("Mounting " .. name .. "...", vim.log.levels.INFO)
      vim.fn.jobstart({
        "sshfs", config.remote, config.local_path,
        "-o", "reconnect,ServerAliveInterval=15"
      }, {
        on_exit = function(_, code)
          if code == 0 then
            active_mounts[name] = true
            vim.schedule(function()
              vim.notify("Mounted!", vim.log.levels.INFO)
              vim.cmd("cd " .. config.local_path)
              vim.cmd("edit .")
            end)
          else
            vim.schedule(function()
              vim.notify("Mount failed", vim.log.levels.ERROR)
            end)
          end
        end,
      })
    end

    local function unmount(name)
      local config = mounts[name]
      if not config then
        vim.notify("Unknown remote: " .. name, vim.log.levels.ERROR)
        return
      end
      vim.fn.system("fusermount -u " .. config.local_path)
      active_mounts[name] = nil
      vim.notify("Unmounted " .. name, vim.log.levels.INFO)
    end

    vim.api.nvim_create_user_command("RemoteMount", function(opts)
      mount(opts.args)
    end, {
      nargs = 1,
      complete = function()
        return vim.tbl_keys(mounts)
      end,
    })

    vim.api.nvim_create_user_command("RemoteUnmount", function(opts)
      unmount(opts.args)
    end, {
      nargs = 1,
      complete = function()
        return vim.tbl_keys(mounts)
      end,
    })

    vim.keymap.set("n", "<leader>rm", function()
      vim.ui.select(vim.tbl_keys(mounts), { prompt = "Select remote:" }, function(choice)
        if choice then
          mount(choice)
        end
      end)
    end, { desc = "Mount remote" })

    vim.keymap.set("n", "<leader>ru", function()
      vim.ui.select(vim.tbl_keys(mounts), { prompt = "Unmount remote:" }, function(choice)
        if choice then
          unmount(choice)
        end
      end)
    end, { desc = "Unmount remote" })

    vim.api.nvim_create_autocmd("VimLeave", {
      callback = function()
        for name, _ in pairs(active_mounts) do
          local config = mounts[name]
          if config then
            os.execute("fusermount -u " .. config.local_path)
          end
        end
      end,
    })
  end,
}
