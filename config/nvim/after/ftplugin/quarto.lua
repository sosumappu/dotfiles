local utils = require("_.utils")

vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.wo.foldminlines = 1
vim.wo.conceallevel = 2

utils.plaintext()
