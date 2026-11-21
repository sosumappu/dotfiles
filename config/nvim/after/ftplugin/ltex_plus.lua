local function read_spellfile()
	local spell_path = vim.fn.stdpath("config") .. "/spell/spell.add"
	if vim.fn.filereadable(spell_path) == 0 then
		return {}
	end
	return vim.fn.readfile(spell_path)
end

local words = read_spellfile()

return {
	cmd = { "ltex-ls-plus" },
	filetypes = {
		"bib",
		"gitcommit",
		"mail",
		"markdown",
		"quarto",
		"rmd",
		"tex",
		"plaintex",
	},
	settings = {
		ltex = {
			language = "en-US",
			additionalRules = {
				enablePickyRules = true,
				motherTongue = "fr",
			},
			diagnosticSeverity = "information",
			checkFrequency = "save", -- Crucial on so JVM doesn't spike CPU on every keystroke
			dictionary = {
				["en-US"] = words,
				["fr"] = words,
			},
			disabledRules = {
				-- Let typos_lsp handle simple identifier/typo checks if desired
				["en-US"] = { "MORFOLOGIK_RULE_EN_US" },
			},
			latex = {
				environments = {
					verbatim = "ignore",
					lstlisting = "ignore",
					minted = "ignore",
					align = "ignore",
					["align*"] = "ignore",
					equation = "ignore",
					["equation*"] = "ignore",
					gather = "ignore",
					["gather*"] = "ignore",
				},
			},
			markdown = {
				nodes = {
					CodeBlock = "ignore",
					FencedCodeBlock = "ignore",
					AutoLink = "ignore",
				},
			},
		},
	},
}
