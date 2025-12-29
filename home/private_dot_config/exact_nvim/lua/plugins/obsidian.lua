local prefix = "<leader>m"
local utils = require("config.utils")

return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    keys = {
      { prefix .. "o",       "<cmd>Obsidian open<CR>",              desc = "Open on App" },
      { prefix .. "g",       "<cmd>Obsidian search<CR>",            desc = "Grep" },
      { prefix .. "n",       "<cmd>Obsidian new<CR>",               desc = "New Note" },
      { prefix .. "N",       "<cmd>Obsidian new_from_template<CR>", desc = "New Note (Template)" },
      { prefix .. "<space>", "<cmd>Obsidian quick_switch<CR>",      desc = "Find Files" },
      { prefix .. "b",       "<cmd>Obsidian backlinks<CR>",         desc = "Backlinks" },
      { prefix .. "t",       "<cmd>Obsidian tags<CR>",              desc = "Tags" },
      { prefix .. "T",       "<cmd>Obsidian template<CR>",          desc = "Template" },
      { prefix .. "L",       "<cmd>Obsidian link<CR>",              mode = "v",                  desc = "Link" },
      { prefix .. "l",       "<cmd>Obsidian links<CR>",             desc = "Links" },
      { prefix .. "l",       "<cmd>Obsidian link_new<CR>",          mode = "v",                  desc = "New Link" },
      { prefix .. "e",       "<cmd>Obsidian extract_note<CR>",      mode = "v",                  desc = "Extract Note" },
      { prefix .. "w",       "<cmd>Obsidian workspace<CR>",         desc = "Workspace" },
      { prefix .. "r",       "<cmd>Obsidian rename<CR>",            desc = "Rename" },
      { prefix .. "i",       "<cmd>Obsidian paste_img<CR>",         desc = "Paste Image" },
      { prefix .. "d",       "<cmd>Obsidian dailies<CR>",           desc = "Daily Notes" },
    },
    ---@module 'obsidian'
    ---@type function|obsidian.config
    opts = function()
      vim.wo.conceallevel = 1
      return {
        legacy_commands = false,
        workspaces = { {
          name = "Notes",
          path = vim.fn.expand("$OBSIDIAN_VAULT")
        } },
        notes_subdir = "fleeting",

        new_notes = "notes_subdir",

        completion = {
          nvim_cmp = false,
          blink = true,
        },

        templates = {
          subdir = "templates",
          date_format = "%Y-%m-%d",
          time_format = "%H:%M:%S",
        },

        picker = {
          name = "snacks.pick",
          note_mappings = {
            new = "<C-x>",
            insert_link = "<C-l>",
          },
          tag_mappings = {
            tag_note = "<C-x>",
            insert_tag = "<C-l>",
          },
        },

        create_new = false,

        note_frontmatter_func = function(note)
          local out = { id = note.id, aliases = note.aliases, tags = note.tags, hubs = {}, urls = {} }

          if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
            for k, v in pairs(note.metadata) do
              out[k] = v
            end
          end
          return out
        end,

        note_id_func = function(title)
          local suffix = ""
          if title ~= nil then
            suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
          else
            for _ = 1, 4 do
              suffix = suffix .. string.char(math.random(65, 90)):lower()
            end
          end
          return tostring(os.date("%Y-%m-%d")) .. "_" .. suffix
        end,

        ui = { enable = false },

        statusline = {
          enabled = true,
          format = "{{backlinks}} backlinks | {{words}} words",
        },
      }
    end
  },
  {
    "folke/snacks.nvim",
    keys = {
      {
        prefix .. "k",
        function()
          Snacks.picker.grep({
            search = "^\\s*- \\[ \\]",
            regex = true,
            dirs = { vim.fn.getcwd() },
            finder = "grep",
            format = "file",
            show_empty = true,
            supports_live = false,
            live = false,
          })
        end,
        desc = "Tasks (Unfinished)",
      },
      {
        prefix .. "K",
        function()
          Snacks.picker.grep({
            search = "^\\s*- \\[x\\]:",
            regex = true,
            dirs = { vim.fn.getcwd() },
            finder = "grep",
            format = "file",
            show_empty = true,
            supports_live = false,
            live = false,
          })
        end,
        desc = "Tasks (Finished)",
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { prefix, group = "obsidian", icon = "", mode = { "n", "v" } },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, 1, "g:obsidian")
    end,
  },
}
