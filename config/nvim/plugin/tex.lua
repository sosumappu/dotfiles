local pack = require("_.pack")

-- VimTeX globals must be defined before the plugin loads
vim.g.tex_flavor = "latex"
vim.g.vimtex_mappings_enabled = 1
vim.g.vimtex_imaps_enabled = 0 -- We use LuaSnip autosnippets instead of VimTeX insert maps
vim.g.vimtex_quickfix_mode = 2
vim.g.vimtex_quickfix_open_on_warning = 0
vim.g.vimtex_fold_enabled = 1
vim.g.vimtex_syntax_conceal = {
	accents = 1,
	ligatures = 1,
	cites = 1,
	fancy = 1,
	spacing = 0,
	greek = 1,
	math_bounds = 1,
	math_delimiters = 1,
	math_fracs = 1,
	math_super_sub = 1,
	math_symbols = 1,
	sections = 0,
	styles = 1,
}

vim.g.vimtex_compiler_latexmk = {
	aux_dir = "build",
	out_dir = "",
	callback = 1,
	continuous = 1,
	executable = "latexmk",
	options = {
		"-verbose",
		"-file-line-error",
		"-synctex=1",
		"-interaction=nonstopmode",
	},
}

-- On headless Raspberry Pi over Blink SSH, disable local GUI viewer auto-open
if vim.env.SSH_CONNECTION ~= nil and vim.env.DISPLAY == nil and vim.uv.os_uname().sysname ~= "Darwin" then
	vim.g.vimtex_view_enabled = 0
elseif vim.uv.os_uname().sysname == "Darwin" then
	vim.g.vimtex_view_method = "sioyek"
else
	vim.g.vimtex_view_method = "zathura"
end

pack.add({
	{
		src = "https://github.com/lervag/vimtex",
		-- VimTeX should not be lazy-loaded on `ft` so inverse-search and ftdetect work cleanly
	},
})
