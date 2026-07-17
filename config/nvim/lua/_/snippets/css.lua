local ls = require 'luasnip'

local s = ls.snippet
local t = ls.text_node

return {
	s({
		trig = 'debug',
		dscr = 'Print box model from https://dev.to/gajus/my-favorite-css-hack-32g3',
	}, {
		t {
			'* { background-color: rgba(255,0,0,.2); }',
			'* * { background-color: rgba(0,255,0,.2); }',
			'* * * { background-color: rgba(0,0,255,.2); }',
			'* * * * { background-color: rgba(255,0,255,.2); }',
			'* * * * * { background-color: rgba(0,255,255,.2); }',
			'* * * * * * { background-color: rgba(255,255,0,.2); }',
			'* * * * * * * { background-color: rgba(255,0,0,.2); }',
			'* * * * * * * * { background-color: rgba(0,255,0,.2); }',
			'* * * * * * * * * { background-color: rgba(0,0,255,.2); }',
		},
	}),
}
