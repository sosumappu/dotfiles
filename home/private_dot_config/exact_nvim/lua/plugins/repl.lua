local send_region = require('_.utils.repl').slime_send_region
local send_cell = require("_.utils.repl").slime_send_cell
local insert_a_code_chunk = require("_.utils.repl").insert_a_code_chunk

vim.g['quarto_is_r_mode'] = nil
vim.g['reticulate_running'] = false

local insert_code_chunk = function(lang)
  insert_a_code_chunk(lang, true)
end

local insert_r_chunk = function()
  insert_code_chunk 'r'
end

local insert_py_chunk = function()
  insert_code_chunk 'python'
end

local insert_lua_chunk = function()
  insert_code_chunk 'lua'
end

local insert_lua_chunk = function()
  insert_code_chunk 'java'
end

local insert_julia_chunk = function()
  insert_code_chunk 'julia'
end

local insert_bash_chunk = function()
  insert_code_chunk 'bash'
end

local insert_ojs_chunk = function()
  insert_code_chunk 'ojs'
end

return {
  { -- requires plugins in lua/plugins/treesitter.lua and lua/plugins/lsp.lua
    -- for complete functionality (language features)
    'https://github.com/quarto-dev/quarto-nvim',
    dev = false,
    opts = {
      lspFeatures = {
        enabled = true,
        chunks = 'curly',
      },
      codeRunner = {
        enabled = true,
        default_method = 'slime',
      },
    },
    dependencies = {
      -- for language features in code cells
      -- configured in lua/plugins/lsp.lua
      'jmbuhr/otter.nvim',
    },
  },

  { -- directly open ipynb files as quarto docuements
    -- and convert back behind the scenes
    -- requires quattro exec
    'GCBallesteros/jupytext.nvim',
    opts = {
      custom_language_formatting = {
        python = {
          extension = 'qmd',
          style = 'quarto',
          force_ft = 'quarto',
        },
        r = {
          extension = 'qmd',
          style = 'quarto',
          force_ft = 'quarto',
        },
      },
    },
  },
  { -- send code from python/r/qmd documets to a terminal or REPL
    -- like ipython, R, bash
    'https://github.com/jpalardy/vim-slime',
    dev = false,
    init = function()
      vim.b['quarto_is_python_chunk'] = false
      Quarto_is_in_python_chunk = function()
        require('otter.tools.functions').is_otter_language_context 'python'
      end
      vim.cmd [[
      let g:slime_dispatch_ipython_pause = 100
      function SlimeOverride_EscapeText_quarto(text)
      call v:lua.Quarto_is_in_python_chunk()
      if exists('g:slime_python_ipython') && len(split(a:text,"\n")) > 1 && b:quarto_is_python_chunk && !(exists('b:quarto_is_r_mode') && b:quarto_is_r_mode)
      return ["%cpaste -q\n", g:slime_dispatch_ipython_pause, a:text, "--", "\n"]
      else
      if exists('b:quarto_is_r_mode') && b:quarto_is_r_mode && b:quarto_is_python_chunk
      return [a:text, "\n"]
      else
      return [a:text]
      end
      end
      endfunction
      ]]

      vim.g.slime_target = 'neovim'
      vim.g.slime_no_mappings = true
      vim.g.slime_python_ipython = 1
    end,
    config = function()
      vim.g.slime_input_pid = false
      vim.g.slime_suggest_default = true
      vim.g.slime_menu_config = false
      vim.g.slime_neovim_ignore_unlisted = true

      local function mark_terminal()
        local job_id = vim.b.terminal_job_id
        vim.print('job_id: ' .. job_id)
      end

      local function set_terminal()
        vim.fn.call('slime#config', {})
      end
      vim.keymap.set('n', '<localleader>jm', mark_terminal, { desc = '[m]ark terminal' })
      vim.keymap.set('n', '<localleader>js', set_terminal, { desc = '[s]et terminal' })
      vim.keymap.set('n', '<localleader>jc', send_cell, { desc = "send [c]ell" })
      vim.keymap.set('v', '<localleader>jr', send_region, { desc = "send [r]egion" })
      vim.keymap.set('n', '<localleader>jip', insert_py_chunk, { desc = "insert [p]ython code chunk" })
      vim.keymap.set('n', '<localleader>jir', insert_r_chunk, { desc = "insert [r] code chunk" })
      vim.keymap.set('n', '<localleader>jiu', insert_julia_chunk, { desc = "insert j[u]lia code chunk" })
      vim.keymap.set('n', '<localleader>jib', insert_bash_chunk, { desc = "insert [b]ash code chunk" })
      vim.keymap.set('n', '<localleader>jij', insert_bash_chunk, { desc = "insert [j]ava code chunk" })
    end,
  },
  { -- paste an image from the clipboard or drag-and-drop
    'https://github.com/HakonHarnes/img-clip.nvim',
    event = 'BufEnter',
    ft = { 'markdown', 'quarto', 'latex' },
    opts = {
      default = {
        dir_path = 'img',
      },
      filetypes = {
        markdown = {
          url_encode_path = true,
          template = '![$CURSOR]($FILE_PATH)',
          drag_and_drop = {
            download_images = false,
          },
        },
        quarto = {
          url_encode_path = true,
          template = '![$CURSOR]($FILE_PATH)',
          drag_and_drop = {
            download_images = false,
          },
        },
      },
    },
    config = function(_, opts)
      require('img-clip').setup(opts)
      vim.keymap.set('n', '<localleader>jii', ':PasteImage<cr>', { desc = 'insert [i]mage from clipboard' })
    end,
  },

  -- { -- preview equations
  --   'https://github.com/jbyuki/nabla.nvim',
  --   keys = {
  --     { '<localleader>je', ':lua require"nabla".toggle_virt()<cr>', desc = 'toggle math [e]quations' },
  --   },
  -- },
}
