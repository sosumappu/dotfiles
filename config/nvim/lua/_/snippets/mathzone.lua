--[[
Optimized Mathematical Context Detection Module for LuaSnip's autosnippets.

Features:
- Configurable caching mechanism
- Configurable incremental parsing
- Robust math environment detection
- Multiple fallback strategies
]]

-- Module table
local M = {}

local function current_buffer()
	return vim.api.nvim_get_current_buf()
end

------------------------------------------------------------------------------
-- UNIFIED CACHE MECHANISM (Configurable)
------------------------------------------------------------------------------
local function create_unified_cache(options)
	-- Default configuration with options handling
	local config = {
		max_size = (options and options.max_size) or 100, -- Maximum cache size
		on_evict = (options and options.on_evict) or function() end,
		on_miss = (options and options.on_miss) or function() end,
		eviction_strategy = (options and options.eviction_strategy) or "lru",
	}

	-- Cache storage structure
	local cache = {
		items = {}, -- Cached items
		access_count = {}, -- Access frequency tracking
		last_access = {}, -- Last accessed timestamp tracking
		config = config, -- Cache configuration
	}

	-- Update access tracking
	local function update_access_tracking(full_key)
		cache.access_count[full_key] = (cache.access_count[full_key] or 0) + 1
		cache.last_access[full_key] = os.time() -- Update last access time
	end

	-- Eviction strategies
	local eviction_strategies = {
		lru = function()
			local oldest_key, oldest_time = nil, math.huge
			for key, access_time in pairs(cache.last_access) do
				if access_time < oldest_time then
					oldest_key, oldest_time = key, access_time
				end
			end
			return oldest_key
		end,
		lfu = function()
			local least_used_key, least_count = nil, math.huge
			for key, count in pairs(cache.access_count) do
				if count < least_count then
					least_used_key, least_count = key, count
				end
			end
			return least_used_key
		end,
		arc = function()
			local lru_key = eviction_strategies.lru()
			local lfu_key = eviction_strategies.lfu()
			return lru_key or lfu_key -- Combine LRU and LFU strategies
		end,
	}

	-- Namespace-aware cache getter method
	function cache:get(namespace, key)
		local full_key = string.format("%s:%s", namespace, tostring(key))
		local value = self.items[full_key]

		if value then
			update_access_tracking(full_key) -- Update access tracking
			return value
		else
			config.on_miss(namespace, key) -- Trigger cache miss callback
			return nil
		end
	end

	-- Namespace-aware cache setter method
	function cache:set(namespace, key, value)
		local full_key = string.format("%s:%s", namespace, tostring(key))

		-- Eviction logic
		if #vim.tbl_keys(self.items) >= config.max_size then
			local evict_strategy = eviction_strategies[config.eviction_strategy] or eviction_strategies.lru
			local key_to_evict = evict_strategy()

			if key_to_evict then
				config.on_evict(key_to_evict, self.items[key_to_evict]) -- Trigger eviction callback
				-- Remove evicted item
				self.items[key_to_evict] = nil
				self.access_count[key_to_evict] = nil
				self.last_access[key_to_evict] = nil
			end
		end

		-- Add or update cache item
		self.items[full_key] = value
		update_access_tracking(full_key)

		return true
	end

	-- Utility methods
	function cache:clear()
		self.items = {}
		self.access_count = {}
		self.last_access = {}
	end

	function cache:size()
		return #vim.tbl_keys(self.items) -- Return the number of cached items
	end

	function cache:stats()
		return {
			total_items = #vim.tbl_keys(self.items),
			max_size = config.max_size,
			eviction_strategy = config.eviction_strategy,
		}
	end

	return cache
end

------------------------------------------------------------------------------
-- CONFIGURATION AND SETUP
------------------------------------------------------------------------------
M.config = {
	-- Performance and parsing settings
	cache_size = 300,
	use_cache = true, -- Enable/disable the caching mechanism
	incremental_parsing = {
		enabled = false, -- Enable/disable incremental parsing
		max_lines_for_full_parse = 1000, -- Max lines for full parse
		partial_update_threshold = 50, -- Threshold for partial updates
	},

	-- Logging and debugging
	debug = false, -- Enable debug logging

	-- Detection method priorities
	detection_strategies = {
		"cache", -- Fastest
		"treesitter", -- Intermediate speed
		"regex", -- Slower fallback
		"environment", -- Slowest
	},

	-- Math environment definitions
	math_environments = {
		latex = {
			equation = true,
			align = true,
			displaymath = true,
			gather = true,
			multline = true,
		},
		context = {
			formula = true,
			subformulas = true,
			placeformula = true,
		},
	},
}

-- Initialize the unified cache only if caching is enabled
if M.config.use_cache then
	M.cache = create_unified_cache({
		max_size = M.config.cache_size,
		on_evict = function(key, value)
			if M.config.debug then
				vim.notify(
					string.format("Evicting cache key: %s (value: %s)", key, tostring(value)),
					vim.log.levels.DEBUG
				)
			end
		end,
		on_miss = function(namespace, key)
			if M.config.debug then
				vim.notify(string.format("Cache miss in namespace %s for key %s", namespace, key), vim.log.levels.DEBUG)
			end
		end,
		eviction_strategy = M.config.eviction_strategy or "lru", -- Default eviction strategy
	})
else
	M.cache = nil -- Disable caching
end

------------------------------------------------------------------------------
-- CONFIGURATION SETUP
------------------------------------------------------------------------------
function M.setup(user_config)
	-- Deep merge user configurations
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})

	-- Validate incremental parsing settings
	if type(M.config.incremental_parsing.enabled) ~= "boolean" then
		M.config.incremental_parsing.enabled = false

		if M.config.debug then
			vim.notify("Invalid incremental parsing setting. Defaulting to false.", vim.log.levels.WARN)
		end
	end

	-- Reinitialize cache if caching is enabled
	if M.config.use_cache then
		M.cache = create_unified_cache({
			max_size = M.config.cache_size,
			on_evict = function(key, value)
				if M.config.debug then
					vim.notify(
						string.format("Evicting cache key: %s (value: %s)", key, tostring(value)),
						vim.log.levels.DEBUG
					)
				end
			end,
			on_miss = function(namespace, key)
				if M.config.debug then
					vim.notify(
						string.format("Cache miss in namespace %s for key %s", namespace, key),
						vim.log.levels.DEBUG
					)
				end
			end,
			eviction_strategy = M.config.eviction_strategy or "lru",
		})
	else
		M.cache = nil -- Disable caching
	end

	-- Optional debug logging
	if M.config.debug then
		vim.notify("Math Detection Config: " .. vim.inspect(M.config), vim.log.levels.DEBUG)
	end
end

------------------------------------------------------------------------------
-- INCREMENTAL PARSING HELPER
------------------------------------------------------------------------------
local function get_incremental_parser(buffer, language)
	local parser = vim.treesitter.get_parser(buffer, language)
	local config = M.config.incremental_parsing

	if not config.enabled then
		local line_count = vim.api.nvim_buf_line_count(buffer)

		-- Determine max_lines_for_full_parse if it's a function
		local max_lines = type(config.max_lines_for_full_parse) == "function" and config.max_lines_for_full_parse()
			or config.max_lines_for_full_parse

		if line_count > max_lines then
			parser:parse(true) -- Force a full parse if exceeds limit
		end
	end

	return parser
end

------------------------------------------------------------------------------
-- HELPER FUNCTIONS
------------------------------------------------------------------------------
local function get_cursor_pos()
	local cursor = vim.api.nvim_win_get_cursor(0) -- Get cursor position
	return cursor[1], cursor[2] + 1 -- Return 1-indexed row and column
end

------------------------------------------------------------------------------
-- MARKDOWN MATH DETECTION
------------------------------------------------------------------------------
local max_markdown_scan_lines = 500

local markdown_filetypes = {
	markdown = true,
	md = true,
	mdx = true,
	quarto = true,
}

local function is_markdown_buffer(bufnr)
	local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
	return markdown_filetypes[filetype] == true or filetype:find("markdown", 1, true) ~= nil
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
	}

	for lnum = region_start, row + 1 do
		local line = lines[lnum] or ""
		if lnum == row + 1 then
			line = current_prefix
		end
		update_block_math_state(state, line)
	end

	return state.dollar or state.bracket > 0 or state.paren > 0
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

function M.in_markdown_mathzone(line_to_cursor)
	local bufnr = current_buffer()
	if not is_markdown_buffer(bufnr) then
		return false
	end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1] - 1
	local col = cursor[2]
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row + 1, false)
	if #lines == 0 then
		return false
	end

	local current_line = lines[#lines]
	local current_prefix = line_to_cursor or current_line:sub(1, col)
	local cursor_col = #current_prefix
	local region_start, in_fence = math_region_start(lines, row, current_prefix)
	if in_fence then
		return false
	end

	return block_math_open(lines, region_start, row, current_prefix) or inline_dollar_open(current_line, cursor_col)
end

-------------------------------------------------------------------------------
-- MATH ZONE DETECTION
-------------------------------------------------------------------------------
local function create_math_query()
	local cached_query = nil

	return function()
		if not cached_query then
			cached_query = vim.treesitter.query.parse(
				"latex",
				[[
        (
          (inline_formula) @inline
          (displayed_equation) @display
          (math_delimiter) @delim
          (math_environment) @latex
          (generic_command) @context
        )
        ]]
			)
		end
		return cached_query
	end
end

local get_math_query = create_math_query()

function M.is_mathzone()
	local current_row, current_col = get_cursor_pos()
	local cache_key = string.format("%d:%d", current_row, current_col)

	-- Check cache first if caching is enabled
	local cached_result = M.config.use_cache and M.cache:get("mathzone", cache_key)
	if cached_result ~= nil then
		return cached_result
	end

	-- Use incremental parser; ensure you run `:TSInstall latex`
	local parser = get_incremental_parser(0, "latex")
	if not parser then
		return M.is_mathzone_fallback()
	end

	local root = parser:parse()[1]:root()
	local row, col = get_cursor_pos()
	local cursor_row, cursor_col = row - 1, col - 1

	local query = get_math_query()

	local function check_math_environment(node, capture)
		local env_name = vim.treesitter.get_node_text(node, 0):gsub("[\\{}]", ""):lower()
		local s_row, s_col, e_row, e_col = node:range()

		-- Check if the environment is defined
		if M.config.math_environments[env_name] then
			if
				cursor_row >= s_row
				and cursor_row <= e_row
				and (cursor_row > s_row or cursor_col >= s_col)
				and (cursor_row < e_row or cursor_col < e_col)
			then
				return true
			end
		end

		return false
	end

	for id, node in query:iter_captures(root, 0) do
		local capture = query.captures[id]
		local s_row, s_col, e_row, e_col = node:range()

		local is_in_zone = (capture == "inline" or capture == "display" or capture == "delim")
			and cursor_row >= s_row
			and cursor_row <= e_row
			and (cursor_row > s_row or cursor_col >= s_col)
			and (cursor_row < e_row or cursor_col < e_col)

		local is_math_env = (capture == "latex" or capture == "context") and check_math_environment(node, capture)

		if is_in_zone or is_math_env then
			if M.config.use_cache then
				M.cache:set("mathzone", cache_key, true)
			end
			return true
		end
	end

	if M.config.use_cache then
		M.cache:set("mathzone", cache_key, false)
	end
	return false
end

------------------------------------------------------------------------------
-- REGEX-BASED DETECTION
------------------------------------------------------------------------------
local function safe_regex_matcher(line)
	local matches = {}
	local patterns = {
		{ pattern = "()%$(.-)%$()", type = "inline" },
		{ pattern = "()%$%$(.-)%$%$()", type = "display" },
		{ pattern = "()\\(%(.-)\\%)()", type = "latex_inline" },
		{ pattern = "()\\(%[.-)\\%]()()", type = "latex_display" },
		{ pattern = "()\\math{(.-)}()", type = "sile_inline" },
	}

	for _, pat in ipairs(patterns) do
		for start, content, stop in line:gmatch(pat.pattern) do
			table.insert(matches, {
				type = pat.type,
				start = start,
				stop = stop,
				content = content,
			})
		end
	end

	return matches
end

function M.is_mathzone_fallback()
	local current_row, current_col = get_cursor_pos()
	local cache_key = string.format("fallback:%d:%d", current_row, current_col)

	-- Check cache first if caching is enabled
	if M.config.use_cache then
		local cached_result = M.cache:get("fallback", cache_key)
		if cached_result ~= nil then
			return cached_result
		end
	end

	local line = vim.api.nvim_buf_get_lines(current_buffer(), current_row - 1, current_row, false)[1] or ""
	local matches = safe_regex_matcher(line)

	-- Check for math zones in the current line
	for _, zone in ipairs(matches) do
		if current_col >= zone.start and current_col <= zone.stop then
			-- Cache the result if caching is enabled
			if M.config.use_cache then
				M.cache:set("fallback", cache_key, true)
			end
			return true
		end
	end

	-- Cache the result as false if no match was found
	if M.config.use_cache then
		M.cache:set("fallback", cache_key, false)
	end

	return false
end

------------------------------------------------------------------------------
-- ENVIRONMENT DETECTION
------------------------------------------------------------------------------
local function in_environment(env_name)
	local current_row = get_cursor_pos()

	-- Check cache first if caching is enabled
	local cache_key = string.format("%d:%s", current_row, env_name)
	local cached_result = M.config.use_cache and M.cache:get("environment", cache_key)
	if cached_result ~= nil then
		return cached_result
	end

	local start_patterns = {
		"\\begin{" .. env_name .. "}",
		"\\start" .. env_name,
	}

	local end_patterns = {
		"\\end{" .. env_name .. "}",
		"\\stop" .. env_name,
	}

	local last_start_marker = nil
	for line_num = current_row, 1, -1 do
		local text = vim.api.nvim_buf_get_lines(current_buffer(), line_num - 1, line_num, false)[1] or ""

		for _, pat in ipairs(start_patterns) do
			if text:find(pat, 1, true) then
				last_start_marker = line_num
				break -- Break after finding a start marker
			end
		end

		if last_start_marker then
			break
		end
	end

	if not last_start_marker then
		if M.config.use_cache then
			M.cache:set("environment", cache_key, false)
		end
		return false
	end

	for line_num = last_start_marker, vim.api.nvim_buf_line_count(0) do
		local text = vim.api.nvim_buf_get_lines(current_buffer(), line_num - 1, line_num, false)[1] or ""

		for _, pat in ipairs(end_patterns) do
			if text:find(pat, 1, true) then
				local result = line_num > current_row and last_start_marker < current_row
				if M.config.use_cache then
					M.cache:set("environment", cache_key, result)
				end
				return result
			end
		end
	end

	local result = last_start_marker < current_row
	if M.config.use_cache then
		M.cache:set("environment", cache_key, result)
	end
	return result
end

------------------------------------------------------------------------------
-- SPECIFIC ENVIRONMENT CHECKS
------------------------------------------------------------------------------
M.in_text = function()
	return in_environment("text") and not M.math_mode()
end

M.in_tikz = function()
	return in_environment("tikzpicture")
end

M.in_bullets = function()
	return in_environment("itemize") or in_environment("enumerate")
end

M.in_MPcode = function()
	return in_environment("MPcode")
end

local function is_math_range()
	local math_ranges = {
		"formula",
		"placeformula",
		"subformulas",
		"equation",
		"align",
		"displaymath",
		"gather",
		"multline",
	}

	for _, env in ipairs(math_ranges) do
		if in_environment(env) then
			return true
		end
	end

	return false
end

function M.is_in_sile_display_math()
	local current_row, current_col = get_cursor_pos()
	local cache_key = string.format("%d:%d", current_row, current_col)

	-- Check cache first
	if M.config.use_cache then
		local cached_result = M.cache:get("sile_display_math", cache_key)
		if cached_result ~= nil then
			return cached_result
		end
	end

	-- Look for the begin marker above the current row
	local begin_row = nil
	for row = current_row, 1, -1 do
		local line = vim.api.nvim_buf_get_lines(current_buffer(), row - 1, row, false)[1] or ""
		if line:match("\\begin%[mode=display%]{math}") then
			begin_row = row
			break
		end
	end

	-- Return false if no begin marker is found
	if not begin_row then
		if M.config.use_cache then
			M.cache:set("sile_display_math", cache_key, false)
		end
		return false
	end

	-- Look for end marker below the last found begin marker
	local end_row = nil
	for row = begin_row, vim.api.nvim_buf_line_count(current_buffer()) do
		local line = vim.api.nvim_buf_get_lines(current_buffer(), row - 1, row, false)[1] or ""
		if line:match("\\end{math}") then
			end_row = row
			break
		end
	end

	-- Check if the cursor is within the display math environment
	local result = begin_row <= current_row and (not end_row or current_row <= end_row)

	if M.config.use_cache then
		M.cache:set("sile_display_math", cache_key, result)
	end
	return result
end

------------------------------------------------------------------------------
-- TEXT COMMAND DETECTION
------------------------------------------------------------------------------
local function is_cursor_in_text_command()
	local current_row, current_col = get_cursor_pos()
	local cache_key = string.format("%d:%d", current_row, current_col)

	-- Check cache for result if caching is enabled
	local cached_result = M.config.use_cache and M.cache:get("text_command", cache_key)
	if cached_result ~= nil then
		return cached_result
	end

	local line = vim.api.nvim_buf_get_lines(current_buffer(), current_row - 1, current_row, false)[1] or ""
	local text_start = line:find("\\text{")
	local text_end = line:find("}")

	local result = text_start and text_end and text_start < current_col and current_col < text_end
	if M.config.use_cache then
		M.cache:set("text_command", cache_key, result) -- Store result in cache
	end
	return result
end

------------------------------------------------------------------------------
-- MATH MODE DETECTION
------------------------------------------------------------------------------
function M.math_mode(line_to_cursor)
	if is_markdown_buffer(current_buffer()) then
		return M.in_markdown_mathzone(line_to_cursor)
	end

	return (M.config.use_cache and M.cache:get("mathzone", string.format("%d:%d", get_cursor_pos())) == true)
		or (M.is_mathzone() or M.is_mathzone_fallback() or is_math_range() or M.is_in_sile_display_math())
			and not is_cursor_in_text_command()
end

function M.in_mathzone(line_to_cursor)
	return M.math_mode(line_to_cursor)
end

------------------------------------------------------------------------------
-- NEOVIM INTEGRATION
------------------------------------------------------------------------------
vim.api.nvim_create_user_command("CheckCursorMathZone", function()
	if M.math_mode() then
		print("Cursor is in a math mode")
	else
		print("Cursor is NOT in a math mode")
	end
end, {})

-- Initialize with default settings
M.setup({
	cache_size = 500,
	use_cache = true, -- Enable or disable caching
	eviction_strategy = "arc",
	incremental_parsing = {
		enabled = true,
		max_lines_for_full_parse = function()
			local line_count = vim.api.nvim_buf_line_count(current_buffer())
			return math.max(line_count, 1000) -- Minimum 1000 lines for full parse
		end,
		-- partial_update_threshold = 50, -- Lines for partial updates
	},
	debug = false, -- Enable debug logging
})

vim.api.nvim_create_user_command("DebugSileMath", function()
	local current_row, current_col = get_cursor_pos()
	local line = vim.api.nvim_buf_get_lines(current_buffer(), current_row - 1, current_row, false)[1] or ""

	print("SILE Math Debug")
	print("Current line:", line)
	print("Cursor position:", current_row, current_col)
	print("In math mode:", M.math_mode())
	print("In math environment:", in_environment("math"))
	print("In SILE display math:", M.is_in_sile_display_math())

	-- Test pattern matching
	local test_string = "\\begin[mode=display]{math}"
	print("Test string:", test_string)
	print("Matches pattern \\begin%[mode=display%]{math}:", test_string:match("\\begin%[mode=display%]{math}") ~= nil)
end, {})

return M
