return {
	settings = {
		["rust-analyzer"] = {
			imports = {
				granularity = {
					group = "module",
				},
				prefix = "self",
			},
			cargo = {
				allFeatures = true,
				buildScripts = {
					enable = true,
				},
			},
			procMacro = {
				enable = true,
			},

			checkOnSave = true,
			check = {
				command = "clippy",
				allFeatures = true,
			},

			assist = {
				importEnforceGranularity = true,
				importPrefix = "crate",
			},

			inlayHints = {
				lifetimeElisionHints = {
					enable = true,
					useParameterNames = true,
				},
			},
		},
	},
}
