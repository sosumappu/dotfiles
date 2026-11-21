local M = {}

local max_markdown_scan_lines = 500

local markdown_filetypes = {
	markdown = true,
	md = true,
	mdx = true,
	quarto = true,
	rmd = true,
}

local math_envs = {
	equation = true,
	["equation*"] = true,
	align = true,
	["align*"] = true,
	alignat = true,
	["alignat*"] = true,
	gather = true,
	["gather*"] = true,
	multline = true,
	["multline*"] = true,
	flalign = true,
	["flalign*"] = true,
	displaymath = true,
	math = true,
}

local function current_buffer()
	return vim.api.nvim_get_current_buf()
end

local function is_markdown_buffer(bufnr)
	local ft = vim.bo[bufnr].filetype
	return markdown_filetypes[ft] == true or ft:find("markdown", 1, true) ~= nil
end

local function escaped_at(line, index)
	local count = 0
	for pos = index - 1, 1, -1 do
		if line:sub(pos, pos) ~= "\\" then
			break
		end
		count = count + 1
	end
	return count % 2 == 1
end

local function fence_start(line)
	local indent, marker = line:match("^(%s*)(`+)")
	if marker ~= nil and #marker >= 3 and #indent <= 3 then
		return { char = "`", length = #marker }
	end

	indent, marker = line:match("^(%s*)(~+)")
	if marker ~= nil and #marker >= 3 and #indent <= 3 then
		return { char = "~", length = #marker }
	end

	return nil
end

local function fence_close(line, fence)
	local pattern = fence.char == "`" and "^(%s*)(`+)(.*)$" or "^(%s*)(~+)(.*)$"
	local indent, marker, rest = line:match(pattern)
	return marker ~= nil and #marker >= fence.length and #indent <= 3 and rest:match("^%s*$") ~= nil
end

local function math_region_start(lines, row, current_prefix)
	local in_fence = false
	local fence = nil
	local region_start = 1

	for lnum = 1, row + 1 do
		local line = lines[lnum] or ""
		if lnum == row + 1 then
			line = current_prefix
		end

		if in_fence then
			if fence_close(line, fence) then
				in_fence = false
				fence = nil
				region_start = lnum + 1
			end
		else
			local next_fence = fence_start(line)
			if next_fence ~= nil then
				in_fence = true
				fence = next_fence
				region_start = lnum + 1
			end
		end
	end

	local lower_bound = math.max(1, row + 2 - max_markdown_scan_lines)
	return math.max(region_start, lower_bound), in_fence
end

local function mask_inline_code(line)
	local parts = {}
	local index = 1

	while index <= #line do
		local start_pos, end_pos = line:find("`+", index)
		if start_pos == nil then
			parts[#parts + 1] = line:sub(index)
			break
		end

		parts[#parts + 1] = line:sub(index, start_pos - 1)

		local delimiter = line:sub(start_pos, end_pos)
		local close_start, close_end = line:find(delimiter, end_pos + 1, true)
		if close_start == nil then
			parts[#parts + 1] = (" "):rep(#line - start_pos + 1)
			break
		end

		parts[#parts + 1] = (" "):rep(close_end - start_pos + 1)
		index = close_end + 1
	end

	return table.concat(parts)
end

local function starts_with(line, marker, index)
	return line:sub(index, index + #marker - 1) == marker
end

local function update_block_math_state(state, line)
	line = mask_inline_code(line)

	for env in line:gmatch("\\begin{([^}]+)}") do
		if math_envs[env] then
			state.env = state.env + 1
		end
	end
	for env in line:gmatch("\\end{([^}]+)}") do
		if math_envs[env] then
			state.env = math.max(state.env - 1, 0)
		end
	end

	local index = 1
	while index <= #line do
		if starts_with(line, "$$", index) and not escaped_at(line, index) then
			state.dollar = not state.dollar
			index = index + 2
		elseif starts_with(line, "\\[", index) and not escaped_at(line, index) then
			state.bracket = state.bracket + 1
			index = index + 2
		elseif starts_with(line, "\\]", index) and not escaped_at(line, index) then
			state.bracket = math.max(state.bracket - 1, 0)
			index = index + 2
		elseif starts_with(line, "\\(", index) and not escaped_at(line, index) then
			state.paren = state.paren + 1
			index = index + 2
		elseif starts_with(line, "\\)", index) and not escaped_at(line, index) then
			state.paren = math.max(state.paren - 1, 0)
			index = index + 2
		else
			index = index + 1
		end
	end
end

local function block_math_open(lines, region_start, row, current_prefix)
	local state = {
		dollar = false,
		bracket = 0,
		paren = 0,
		env = 0,
	}

	for lnum = region_start, row + 1 do
		local line = lines[lnum] or ""
		if lnum == row + 1 then
			line = current_prefix
		end
		update_block_math_state(state, line)
	end

	return state.dollar or state.bracket > 0 or state.paren > 0 or state.env > 0
end

local function single_dollar_at(line, index)
	return line:sub(index, index) == "$"
		and line:sub(index - 1, index - 1) ~= "$"
		and line:sub(index + 1, index + 1) ~= "$"
		and not escaped_at(line, index)
end

local function dollar_can_open(line, index)
	local next_char = line:sub(index + 1, index + 1)
	return next_char ~= "" and next_char:match("%s") == nil
end

local function dollar_can_close(line, index)
	local previous_char = line:sub(index - 1, index - 1)
	return previous_char ~= "" and previous_char:match("%s") == nil
end

local function inline_dollar_open(line, cursor_col)
	line = mask_inline_code(line)

	local open_index = nil
	local index = 1
	while index <= #line do
		if single_dollar_at(line, index) then
			local can_open = dollar_can_open(line, index)
			local can_close = dollar_can_close(line, index)

			if open_index ~= nil and can_close then
				if cursor_col >= open_index and cursor_col < index then
					return true
				end
				open_index = nil
				if can_open then
					open_index = index
				end
			elseif can_open then
				open_index = index
			end
		end

		index = index + 1
	end

	return false
end

local function in_text_command(line_prefix)
	-- Check if the cursor is inside an unclosed \text{...} or \operatorname{...}
	local last_text = line_prefix:match(".*\\text{([^}]*)$") or line_prefix:match(".*\\operatorname{([^}]*)$")
	return last_text ~= nil
end

function M.in_markdown_mathzone(line_to_cursor)
	local bufnr = current_buffer()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1] - 1
	local col = cursor[2]
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row + 1, false)
	if #lines == 0 then
		return false
	end

	local current_line = lines[#lines]
	local current_prefix = line_to_cursor or current_line:sub(1, col)
	if in_text_command(current_prefix) then
		return false
	end

	local cursor_col = #current_prefix
	local region_start, in_fence = math_region_start(lines, row, current_prefix)
	if in_fence then
		return false
	end

	return block_math_open(lines, region_start, row, current_prefix) or inline_dollar_open(current_line, cursor_col)
end

function M.in_tex_mathzone(line_to_cursor)
	-- Prefer VimTeX's native syntax stack detector when loaded
	if vim.fn.exists("*vimtex#syntax#in_mathzone") == 1 then
		return vim.fn["vimtex#syntax#in_mathzone"]() == 1
	end

	-- Fallback to the bounded delimiter/environment scanner
	return M.in_markdown_mathzone(line_to_cursor)
end

function M.math_mode(line_to_cursor)
	local bufnr = current_buffer()
	if is_markdown_buffer(bufnr) then
		return M.in_markdown_mathzone(line_to_cursor)
	end
	return M.in_tex_mathzone(line_to_cursor)
end

M.in_mathzone = M.math_mode

function M.in_text(line_to_cursor)
	return not M.math_mode(line_to_cursor)
end

vim.api.nvim_create_user_command("CheckCursorMathZone", function()
	print(M.math_mode() and "Cursor is in math mode" or "Cursor is NOT in math mode")
end, {})

return M
