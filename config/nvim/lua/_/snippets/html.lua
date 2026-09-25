local ls = require 'luasnip'

local s = ls.snippet
local i = ls.insert_node
local c = ls.choice_node
local fmt = require('luasnip.extras.fmt').fmt

return {
	s(
		'script',
		fmt('<script {scriptEnd}{body}</script>{next}', {
			scriptEnd = c(1, {
				fmt('src="{src}">', {
					src = i(1, 'path/to/file.js'),
				}),
				fmt('>\n\t{code}\n\n', { code = i(1, '// code') }),
			}),
			body = i(2),
			next = i(0),
		})
	),
	s(
		{ trig = 'fav', dscr = 'Add an inline SVG Emoji Favicon' },
		fmt(
			'<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>{text}</text></svg>"/>',
			{ text = i(1) }
		)
	),
}
