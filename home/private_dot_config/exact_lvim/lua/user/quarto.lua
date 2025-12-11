local M = {}

local function keys(str)
  return function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(str, true, false, true), "m", true)
  end
end

M.config = function()
  local quarto = require("quarto")
  quarto.setup({
    lspFeatures = {
      enabled = true,
      languages = { "python", "r", "rust", "lua", "javascript", "typescript" },
      chunks = "all",
      diagnostics = {
        enabled = true,
        triggers = { "BufWritePost" },
      },
      completion = {
        enabled = true,
      },
    },
    codeRunner = {
      enabled = true,
      default_method = "molten",
    },
  })

  -- Setup Hydra for notebook navigation only in markdown files
  local hydra_status, hydra = pcall(require, "hydra")
  if hydra_status then
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown", "quarto" },
      callback = function()
        hydra({
          name = "Jupyter Hydra",
          hint = [[
 _j_/_k_: move down/up  _r_: run cell
 _l_: run line  _R_: run above
 _a_: run all   _<esc>_/_q_: exit ]],
          config = {
            color = "pink",
            invoke_on_body = true,
            hint = { border = "rounded" },
            buffer = 0, -- Only for current buffer
          },
          mode = { "n" },
          body = "<leader>:",
          heads = {
            { "j", keys("]b") },
            { "k", keys("[b") },
            { "r", ":QuartoSend<CR>" },
            { "l", ":QuartoSendLine<CR>" },
            { "R", ":QuartoSendAbove<CR>" },
            { "a", ":QuartoSendAll<CR>" },
            { "<esc>", nil, { exit = true } },
            { "q", nil, { exit = true } },
          },
        })
      end,
    })
  end

  -- Setup keybindings using which-key
  local wk_status, wk = pcall(require, "which-key")
  if not wk_status then
    vim.notify("which-key not found", vim.log.levels.WARN)
    return
  end

  -- Only set these keybindings for markdown and quarto files
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "quarto" },
    callback = function()
      wk.register({
        j = {
          c = { ":QuartoSend<CR>", "󰴓 Run current cell" },
          a = { ":QuartoSendAbove<CR>", "󰝖 Run cell and above" },
          A = { ":QuartoSendAll<CR>", "󰓎 Run all cells" },
          l = { ":QuartoSendLine<CR>", "󰘦 Run line" },
        },
      }, { prefix = "<leader>", mode = "n", noremap = true, silent = true, nowait = true, buffer = 0 })

      -- Visual mode for running selection
      wk.register({
        j = {
          r = { ":<C-u>QuartoSendRange<CR>", "▶ Run selection" },
        },
      }, { prefix = "<leader>", mode = "v", noremap = true, silent = true, nowait = true, buffer = 0 })
    end,
  })
end

return M
