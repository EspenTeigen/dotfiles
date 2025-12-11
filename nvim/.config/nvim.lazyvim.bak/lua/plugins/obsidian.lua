return {
  "epwalsh/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
  --   -- refer to `:h file-pattern` for more examples
  --   "BufReadPre path/to/my-vault/*.md",
  --   "BufNewFile path/to/my-vault/*.md",
  -- },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "hrsh7th/nvim-cmp",
    "nvim-telescope/telescope.nvim",
    "nvim-treesitter/nvim-treesitter",
    "epwalsh/pomo.nvim",
  },
  opts = {
    workspaces = {
      {
        name = "notes",
        path = "~/vaults/notes/",
      },
    },

    daily_notes = {
      folder = "Daily Notes",
      date_format = "%Y-%m/%Y-%m-%d",
      alias_format = "%B %-d, %Y",
      default_tags = { "daily-note" },
      -- Don't auto-apply template, we'll do it manually with proper substitution
      template = nil,
    },

    templates = {
      folder = "Templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      substitutions = {
        date = function()
          return os.date("%Y-%m-%d")
        end,
        time = function()
          return os.date("%H:%M")
        end,
        yesterday = function()
          return os.date("%Y-%m-%d", os.time() - 86400)
        end,
      },
    },

    -- Picker configuration (use Telescope)
    picker = {
      name = "telescope.nvim",
    },

    -- Completion settings (disabled since using blink.cmp)
    completion = {
      nvim_cmp = false,
      min_chars = 2,
    },

    -- Follow links behavior
    follow_url_func = function(url)
      vim.fn.jobstart({ "xdg-open", url })
    end,
  },
  config = function(_, opts)
    require("obsidian").setup(opts)

    -- Register obsidian completion sources with cmp (via blink.compat)
    local cmp = require("cmp")
    cmp.register_source("obsidian", require("cmp_obsidian").new())
    cmp.register_source("obsidian_new", require("cmp_obsidian_new").new())
    cmp.register_source("obsidian_tags", require("cmp_obsidian_tags").new())

    -- Custom command to create daily note with template applied
    vim.api.nvim_create_user_command("ObsidianDailyNote", function(opts)
      local offset = tonumber(opts.args) or 0
      local client = require("obsidian").get_client()

      -- Create/open daily note
      local note = client:today(offset)
      client:open_note(note)

      -- Check if template needs to be applied
      vim.defer_fn(function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        -- Check if template already applied by looking for the work log heading
        local has_template = false
        for _, line in ipairs(lines) do
          if line:match("Daily Work Log") then
            has_template = true
            break
          end
        end

        -- If template not applied, clear buffer and apply it
        if not has_template then
          -- Clear the auto-generated content
          vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
          -- Apply template
          vim.cmd("ObsidianTemplate Daily Work Note.md")
        end
      end, 150)
    end, { nargs = "?" })

    -- Custom command to create yesterday's note with template applied
    vim.api.nvim_create_user_command("ObsidianYesterday", function()
      local client = require("obsidian").get_client()

      -- Store original substitutions
      local original_substitutions = vim.deepcopy(client.opts.templates.substitutions)

      -- Calculate yesterday's date
      local yesterday_time = os.time() - 86400
      local yesterday_date = os.date("%Y-%m-%d", yesterday_time)

      -- Override template substitutions for yesterday
      client.opts.templates.substitutions = vim.tbl_extend("force", client.opts.templates.substitutions, {
        date = function()
          return yesterday_date
        end,
        time = function()
          return os.date("%H:%M", yesterday_time)
        end,
      })

      -- Use client:daily to create yesterday's note properly
      local note = client:daily(-1)

      -- Open the note
      client:open_note(note)

      -- Apply template after opening
      vim.defer_fn(function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local has_content = false
        for _, line in ipairs(lines) do
          if line:match("Daily Work Log") then
            has_content = true
            break
          end
        end

        if not has_content then
          vim.cmd("ObsidianTemplate Daily Work Note.md")
        end

        -- Restore original substitutions
        vim.defer_fn(function()
          client.opts.templates.substitutions = original_substitutions
        end, 200)
      end, 150)
    end, {})

    -- Custom command to select project for current daily note
    vim.api.nvim_create_user_command("ObsidianSelectProject", function()
      local projects = {
        "RSCDrone",
        "NMEA",
        "Asus NUC",
        "Infrastructure",
        "Other",
      }

      vim.ui.select(projects, {
        prompt = "Select project:",
      }, function(choice)
        if choice then
          -- Find the projects field in frontmatter
          local line = vim.fn.search("^projects:", "n")

          if line > 0 then
            -- Projects field exists, add to it
            vim.fn.append(line, "  - " .. choice)
          else
            -- Projects field doesn't exist, add it after tags
            local tags_line = vim.fn.search("^tags:", "n")
            if tags_line > 0 then
              -- Find the end of the tags list
              local current_line = tags_line + 1
              while current_line <= vim.fn.line("$") do
                local line_content = vim.fn.getline(current_line)
                if not string.match(line_content, "^  %-") then
                  break
                end
                current_line = current_line + 1
              end
              -- Insert projects field
              vim.fn.append(current_line - 1, { "projects:", "  - " .. choice })
            else
              -- No tags field, add before closing ---
              local close_line = vim.fn.search("^---", "n", vim.fn.line("$"))
              if close_line > 1 then
                vim.fn.append(close_line - 1, { "projects:", "  - " .. choice })
              end
            end
          end
        end
      end)
    end, {})
  end,
  keys = {
    { "<leader>o", group = "obsidian" },
    { "<leader>oo", "<cmd>ObsidianOpen<cr>", desc = "Open in Obsidian app" },
    { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "New note" },
    { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Search notes" },
    { "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", desc = "Quick switch" },
    { "<leader>of", "<cmd>ObsidianFollowLink<cr>", desc = "Follow link" },
    { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Backlinks" },
    { "<leader>og", "<cmd>ObsidianTags<cr>", desc = "Search tags" },
    { "<leader>ot", "<cmd>ObsidianDailyNote<cr>", desc = "Today's note" },
    { "<leader>oy", "<cmd>ObsidianYesterday<cr>", desc = "Yesterday's note" },
    { "<leader>om", "<cmd>ObsidianTomorrow<cr>", desc = "Tomorrow's note" },
    { "<leader>od", "<cmd>ObsidianDailies<cr>", desc = "Daily notes list" },
    { "<leader>op", "<cmd>ObsidianTemplate<cr>", desc = "Insert template" },
    { "<leader>ol", "<cmd>ObsidianLink<cr>", desc = "Link selection", mode = "v" },
    { "<leader>oL", "<cmd>ObsidianLinkNew<cr>", desc = "Link to new note", mode = "v" },
    { "<leader>oll", "<cmd>ObsidianLinks<cr>", desc = "List links" },
    { "<leader>ox", "<cmd>ObsidianExtractNote<cr>", desc = "Extract note", mode = "v" },
    { "<leader>ow", "<cmd>ObsidianWorkspace<cr>", desc = "Switch workspace" },
    { "<leader>oi", "<cmd>ObsidianPasteImg<cr>", desc = "Paste image" },
    { "<leader>or", "<cmd>ObsidianRename<cr>", desc = "Rename note" },
    { "<leader>oc", "<cmd>ObsidianToggleCheckbox<cr>", desc = "Toggle checkbox" },
    { "<leader>oN", "<cmd>ObsidianNewFromTemplate<cr>", desc = "New from template" },
    { "<leader>oT", "<cmd>ObsidianTOC<cr>", desc = "Table of contents" },
    { "<leader>oj", "<cmd>ObsidianSelectProject<cr>", desc = "Select project" },
  },
}
