local ls = require("luasnip")

local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local fmt = require("luasnip.extras.fmt").fmt
local parse = ls.parser.parse_snippet

local math_snippets = require("_.snippets.math")
local ctx = math_snippets.ctx

local snippets = {
	parse(
		ctx({
			trig = "oto",
			dscr = "One to one section",
			text = true,
		}),
		[=[## [[${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}]]
$0

### My topics

### Their topics

### Actions
]=]
	),
	s(
		ctx({ trig = "img", dscr = "Markdown image", text = true }),
		fmt("![{alt}]({url}){next}", {
			url = f(function(_, snip)
				return snip.env.TM_SELECTED_TEXT[1] or sn(nil, i(1, "https://example.com"))
			end, {}),
			alt = i(1, "ALt"),
			next = i(0),
		})
	),
	s(
		ctx({ trig = "link", dscr = "Markdown link", text = true }),
		fmt("[{text}]({url}){next}", {
			url = f(function(_, snip)
				return snip.env.TM_SELECTED_TEXT[1] or sn(nil, i(1, "https://example.com"))
			end, {}),
			text = i(1, "Text"),
			next = i(0),
		})
	),
	s(ctx({ trig = "table", dscr = "Table template", text = true }), {
		t("| "),
		i(1, "First Header"),
		t({
			"  | Second Header |",
			"| ------------- | ------------- |",
			"| Content Cell  | Content Cell  |",
			"| Content Cell  | Content Cell  |",
		}),
	}),
	parse(
		ctx({ trig = "footer", dscr = "Project footer", text = true }),
		[=[
**${1:projectname}** © ${$CURRENT_YEAR}+, Adel Arab Released under the [MIT] License.<br>
Authored and maintained Adel Arab with help from contributors ([list][contributors]).

> GitHub [@sosumappu](https://github.com/sosumappu) &nbsp;&middot;&nbsp;

[MIT]: http://mit-license.org/
[contributors]: http://github.com/sosumappu/$1/contributors
    ]=]
	),
	parse(
		ctx({ trig = "mit", dscr = "MIT Licence", text = true }),
		[=[
The MIT License (MIT)

Copyright (c) ${$CURRENT_YEAR} ${0}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
    ]=]
	),
}

vim.list_extend(snippets, require("_.snippets.math").get({ dm_style = "dollar" }))

return snippets
