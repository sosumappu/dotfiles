-- Markdown plugins
local pack = require("_.pack")

pack.add({
	{
		src = "https://github.com/zk-org/zk-nvim",
		config = function()
			require("zk").setup({
				picker = "fzf_lua",
				lsp = {
					auto_attach = {
						enabled = false,
					},
				},
			})

			require("_.notes").setup()
		end,
	},
	{
		src = "https://github.com/MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown", "md", "codecompanion", "quarto" },
		config = function()
			require("render-markdown").setup({
				file_types = { "markdown", "md", "codecompanion", "quarto" },
				render_modes = { "n", "no", "c", "t", "i", "ic" },
				code = {
					sign = false,
					border = "thin",
					position = "right",
					width = "block",
					above = "▁",
					below = "▔",
					language_left = "█",
					language_right = "█",
					language_border = "▁",
					left_pad = 1,
					right_pad = 1,
				},
				heading = {
					sign = false,
					width = "block",
					left_pad = 1,
					right_pad = 0,
					position = "inline",
					icons = { "󰉫  ", "󰉬  ", "󰉭  ", "󰉮  ", "󰉯  ", "󰉰  " },
				},
				bullet = {
					-- Nesting depth reads through shape and fill: solid then
					-- hollow, circle then square.
					icons = { "●", "○", "▪", "▫" },
				},
				pipe_table = {
					-- Soft corners and a thin alignment marker so borders match
					-- the weight of the thematic-break rule.
					preset = "round",
					alignment_indicator = "─",
				},
			})
			vim.schedule(function()
				vim.api.nvim_exec_autocmds("FileType", { buffer = 0 })
			end)
		end,
	},
	{
		src = "https://github.com/YousefHadder/markdown-plus.nvim",
		ft = { "markdown", "quarto" },
		config = function()
			require("markdown-plus").setup({
				filetypes = { "markdown", "quarto" },
				-- Avoid overlapping with markdown_oxide, render-markdown, and snippets.
				features = {
					list_management = true,
					text_formatting = true,
					thematic_break = false,
					links = false,
					images = false,
					headers_toc = false,
					quotes = false,
					callouts = false,
					code_block = false,
					html_block_awareness = true,
					table = true,
					footnotes = false,
				},
			})
		end,
	},
})
