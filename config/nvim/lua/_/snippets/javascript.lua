local ls = require 'luasnip'

local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local fmt = require('luasnip.extras.fmt').fmt

return {
	s(
		{ trig = 'import', dscr = 'import statement' },
		fmt("import {} from '{}{}';", {
			i(1, 'name'),
			i(2),
			d(3, function(nodes)
				local text = nodes[1][1]
				local _, _, typish, target = text:find '^%s*(%a*)%s*{?%s*(%a+).*}?%s*$'
				if typish == 'type' and target then
					return sn(1, { i(1, target) })
				elseif typish and target then
					return sn(1, { i(1, typish .. target) })
				else
					return sn(1, { i(1, 'specifier') })
				end
			end, { 1 }),
		})
	),
	s(
		{ trig = 'require', dscr = 'require statement' },
		fmt("const {} = require('{}{}');", {
			i(1, 'name'),
			i(2),
			d(3, function(nodes)
				local text = nodes[1][1]
				return sn(1, { i(1, text) })
			end, { 1 }),
		})
	),
	s({ trig = '**', dscr = 'docblock' }, {
		t { '/**', '' },
		f(function(_args, snip)
			local lines = vim.tbl_map(function(line)
				return ' * ' .. vim.trim(line)
			end, snip.env.SELECT_RAW)
			if #lines == 0 then
				return ' * '
			else
				return lines
			end
		end, {}),
		i(1),
		t { '', ' */' },
	}),
}
