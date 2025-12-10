local status_ok, lspconfig = pcall(require, "lspconfig")

if not status_ok then
  return
end

local home = vim.env.HOME
local root_makers = { ".git", "Package.swift" }
local root_dir = lspconfig.util.root_pattern(unpack(root_makers))(vim.fn.expand "%:p")

if not root_dir then
  return
end



lspconfig.sourcekit.setup({
			-- capabilities = capabilities,
			capabilities = {
				workspace = {
					didChangeWatchedFiles = {
						dynamicRegistration = true,
					},
				},
			},
		})
