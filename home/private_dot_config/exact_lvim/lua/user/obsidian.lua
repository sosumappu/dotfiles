local M = {}

M.config = function()
  local status_ok, obs = pcall(require, "obsidian")
  if not status_ok then
    return
  end

  ---@diagnostic disable-next-line: missing-fields
  obs.setup({
    workspaces = {
      {
        name = "Notes",
        path = lvim.builtin.obsidian.vault_path,
      },
    },
    notes_subdir = "fleeting",
    completion = {
      nvim_cmp = true,
      min_chars = 2,
    },
    new_notes = "notes_subdir",

    -- frontmatter management
    -- disable_frontmatter = true,
    note_frontmatter_func = function(note)
        -- This is equivalent to the default frontmatter function.
        local out = { id = note.id, aliases = note.aliases, tags = note.tags, hubs = {}, urls = {} }

        -- `note.metadata` contains any manually added fields in the frontmatter.
        -- So here we just make sure those fields are kept in the frontmatter.
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
            for k, v in pairs(note.metadata) do
                out[k] = v
            end
        end
        return out
    end,

    -- note id as YYYY-MM-DD_title
    note_id_func = function(title)
      local suffix = ""
      if title ~= nil then
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        -- If title is nil, just add 4 random lowercase letters to the suffix.
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90)):lower()
        end
      end
      return tostring(os.date("%Y-%m-%d")) .. "_" .. suffix
    end,

    templates = {
      subdir = "templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M:%S",
    },

    mappings = {
      -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
      ["gf"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
      -- create and toggle checkboxes
      ["<cr>"] = {
        action = function()
          local line = vim.api.nvim_get_current_line()
          if line:match("%s*- %[") then
            require("obsidian").util.toggle_checkbox()
          elseif line:match("%s*-") then
            vim.cmd([[s/-/- [ ]/]])
            vim.cmd.nohlsearch()
          end
        end,
        opts = { buffer = true },
      },
    },
  })

  vim.wo.conceallevel = 1
end

return M
