local pack = require("_.pack")

local repl_filetypes = { "rmd", "quarto" }

pack.add({
	{
		src = "https://github.com/jpalardy/vim-slime",
		ft = repl_filetypes,
		config = function()
			vim.g.slime_target = "tmux"
			vim.g.slime_no_mappings = 1
			vim.g.slime_bracketed_paste = 1
			vim.g.slime_dont_ask_default = 1
			vim.g.slime_default_config = {
				socket_name = "default",
				target_pane = "{last}",
			}
		end,
	},
	{
		src = "https://github.com/jmbuhr/otter.nvim",
		ft = { "quarto", "rmd" },
		config = function()
			require("otter").setup({
				lsp = {
					hover = { border = "rounded" },
					diagnostic_update_events = { "BufWritePost" },
				},
				buffers = {
					write_to_disk = false,
					set_filetype = true,
				},
			})
		end,
	},
	{
		src = "https://github.com/quarto-dev/quarto-nvim",
		ft = { "quarto" },
		config = function()
			require("quarto").setup({
				lspFeatures = {
					enabled = true,
					languages = {},
					chunks = "curly",
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
					default_method = "slime",
					ft_runners = { r = "slime" },
				},
			})
		end,
	},
})

-- Start R in a tmux split. With slime_target = "tmux" and target_pane =
-- "{last}", tmux resolves "last active pane" dynamically on every send, so
-- as long as focus returns to the nvim pane after R starts, no further
-- configuration step is needed.
local function start_repl()
	vim.fn.jobstart({ "tmux", "split-window", "-h", "R" }, { detach = true })
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = repl_filetypes,
	group = vim.api.nvim_create_augroup("repl_keymaps", { clear = true }),
	callback = function(args)
		local otter = require("otter")
		local blink = require("blink.cmp")

		otter.activate({ "python", "r", "julia", "bash" }, {
			lsp = { capabilities = blink.get_lsp_capabilities() },
		})

		local buf = args.buf
		local is_quarto = vim.bo[buf].filetype == "quarto"

		-- ---------------
		-- MAPPINGS
		-- ---------------
		for _, item in ipairs({
			{
				{ "n" },
				"<localleader>rl",
				"<Plug>SlimeLineSend",
				{ desc = "Send [l]ine" },
			},
			{
				{ "x" },
				"<localleader>rl",
				"<Plug>SlimeRegionSend",
				{ desc = "Send se[l]ection" },
			},
			{
				{ "n" },
				"<localleader>rc",
				function()
					if is_quarto then
						require("quarto.runner").run_cell()
					else
						vim.cmd([[normal! <Plug>SlimeParagraphSend]])
					end
				end,
				{ desc = "Send [c]ell/chunk" },
			},
			{
				{ "n" },
				"<localleader>ra",
				function()
					if is_quarto then
						require("quarto.runner").run_above()
					else
						local cur = vim.api.nvim_win_get_cursor(0)[1]
						vim.cmd(string.format("normal! ggV%dG", cur))
						vim.fn["slime#send_op"]("v")
					end
				end,
				{ desc = "Send cell and [a]bove" },
			},
			{
				{ "n" },
				"<localleader>rf",
				function()
					vim.cmd("normal! ggVG")
					vim.fn["slime#send_op"]("v")
				end,
				{ desc = "Send whole [f]ile" },
			},
			{
				{ "n" },
				"<localleader>ro",
				start_repl,
				{ desc = "[O]pen (tmux split + R)" },
			},
			{
				{ "n" },
				"<localleader>rC",
				"<Cmd>SlimeConfig<CR>",
				{ desc = "[C]onfigure target pane" },
			},
		}) do
			local extra_opts = table.remove(item, 4)
			local merged_opts = vim.tbl_extend("force", { silent = true, buf = buf }, extra_opts)

			table.insert(item, 4, merged_opts)

			local modes, lhs, rhs, opt = item[1], item[2], item[3], item[4]

			vim.keymap.set(modes, lhs, rhs, opt)
		end

		if is_quarto then
			vim.keymap.set("n", "<localleader>rp", "<Cmd>QuartoPreview<CR>", {
				silent = true,
				buf = buf,
				desc = "[P]review",
			})
		end
	end,
})
