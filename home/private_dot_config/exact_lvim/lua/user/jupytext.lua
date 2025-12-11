local M = {}

M.config = function()
  require("jupytext").setup({
    style = "markdown",
    output_extension = "md",
    force_ft = "markdown",
    custom_language_formatting = {
      python = {
        extension = "md",
        style = "markdown",
        force_ft = "markdown",
      },
    },
  })
end

return M
