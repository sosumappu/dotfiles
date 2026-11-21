return {
	root_dir = function(_bufnr, on_dir)
		local root = vim.fs.root(0, {
			".latexmkrc",
			"latexmkrc",
			".texlabroot",
			"Tectonic.toml",
			".git",
			vim.api.nvim_buf_get_name(0),
		})
		if root then
			on_dir(root)
		end
	end,
	settings = {
		texlab = {
			auxDirectory = "build",
			diagnosticsDelay = 300,
			chktex = {
				onOpenAndSave = true,
				onEdit = false, -- Keep CPU usage low on Raspberry Pi
			},
			formatterLineLength = 80,
			latexFormatter = "tex-fmt",
			bibtexFormatter = "texlab",
		},
	},
}
