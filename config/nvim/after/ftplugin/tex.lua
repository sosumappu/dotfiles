local utils = require("_.utils")

utils.plaintext()

vim.wo.conceallevel = 2
vim.wo.spell = true

local preview_process = nil

local function stop_preview()
	if preview_process then
		preview_process:kill("sigterm")
		preview_process:wait(500)
		preview_process = nil
	end
end

vim.keymap.set("n", "<localleader>lp", function()
	if preview_process then
		utils.notify("Preview server is already running.")
		return
	end

	local dir = vim.fn.expand("%:p:h")
	local port = vim.env.LATEX_PREVIEW_PORT or "8080"

	preview_process = vim.system({ "python3", "-m", "http.server", port, "--directory", dir })
	utils.notify("Serving PDF directory at http://localhost:" .. port)

	-- Kill the process when the buffer is closed or wiped
	vim.api.nvim_create_autocmd({ "BufUnload", "BufDelete" }, {
		buffer = vim.api.nvim_get_current_buf(),
		callback = stop_preview,
	})
end, {
	buf = 0,
	silent = true,
	desc = "[L]aTeX HTTP [P]review server (for iPad/SSH)",
})
