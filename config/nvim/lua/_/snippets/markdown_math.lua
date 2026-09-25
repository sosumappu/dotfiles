local ls = require("luasnip")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local parse = ls.parser.parse_snippet
local line_begin = require("luasnip.extras.expand_conditions").line_begin

local mathzone = require("_.snippets.mathzone")

local function in_mathzone(...)
	if type(mathzone.math_mode) ~= "function" then
		return false
	end

	local ok, result = pcall(mathzone.math_mode, ...)
	return ok and result == true
end

local function all_conditions(conditions)
	return function(...)
		for _, condition in ipairs(conditions) do
			if not condition(...) then
				return false
			end
		end
		return true
	end
end

local function all_show_conditions(conditions)
	return function(...)
		for _, condition in ipairs(conditions) do
			local ok, result = pcall(condition, ...)
			if not ok then
				result = true
			end
			if not result then
				return false
			end
		end
		return true
	end
end

local function ctx(opts)
	opts = vim.deepcopy(opts)
	local conditions = {}

	if opts.condition ~= nil then
		conditions[#conditions + 1] = opts.condition
	end
	if opts.line then
		conditions[#conditions + 1] = line_begin
		opts.line = nil
	end
	if opts.math then
		conditions[#conditions + 1] = in_mathzone
		opts.math = nil
	end
	if opts.auto then
		opts.snippetType = "autosnippet"
		opts.auto = nil
	end
	if opts.inword then
		opts.wordTrig = false
		opts.inword = nil
	end
	if opts.regex then
		opts.trigEngine = "ecma"
		opts.regex = nil
	end

	if #conditions > 0 then
		opts.condition = all_conditions(conditions)
		opts.show_condition = all_show_conditions(conditions)
	end

	return opts
end

local function capture(index)
	return function(_, snip)
		return snip.captures[index] or ""
	end
end

local function mk_spacing(args)
	local next_text = args[1] and args[1][1] or ""
	local first = next_text:sub(1, 1)
	if first ~= "" and not vim.tbl_contains({ ",", ".", "?", "-", " " }, first) then
		return " "
	end
	return ""
end

return {
	s(ctx({ trig = "mk", dscr = "Inline math", auto = true }), {
		t("$"),
		i(1),
		t("$"),
		f(mk_spacing, { 2 }),
		i(2),
	}),
	parse(
		ctx({ trig = "dm", dscr = "Display math", line = true, auto = true }),
		[=[$$
${1:${TM_SELECTED_TEXT}}
$$
$0]=]
	),
	parse(ctx({ trig = "//", dscr = "Fraction", math = true, inword = true, auto = true }), [=[\frac{$1}{$2}$0]=]),
	parse(
		ctx({ trig = "/", dscr = "Fraction from selection", math = true, inword = true }),
		[=[\frac{${TM_SELECTED_TEXT}}{$1}$0]=]
	),
	parse(ctx({ trig = "__", dscr = "Subscript", math = true, inword = true, auto = true }), [=[_{$1}$0]=]),
	parse(ctx({ trig = "sr", dscr = "Squared", math = true, inword = true, auto = true }), [=[^2]=]),
	parse(ctx({ trig = "cb", dscr = "Cubed", math = true, inword = true, auto = true }), [=[^3]=]),
	parse(ctx({ trig = "td", dscr = "Power", math = true, inword = true, auto = true }), [=[^{$1}$0]=]),
	parse(ctx({ trig = "rd", dscr = "Parenthesized power", math = true, inword = true, auto = true }), [=[^{($1)}$0]=]),
	parse(
		ctx({ trig = "sq", dscr = [[\sqrt{}]], math = true, inword = true, auto = true }),
		[=[\sqrt{${1:${TM_SELECTED_TEXT}}} $0]=]
	),
	parse(ctx({ trig = "->", dscr = "To", priority = 100, math = true, inword = true, auto = true }), [=[\to ]=]),
	parse(
		ctx({ trig = "<->", dscr = "Leftrightarrow", priority = 200, math = true, inword = true, auto = true }),
		[=[\leftrightarrow]=]
	),
	parse(ctx({ trig = "!>", dscr = "Mapsto", math = true, inword = true, auto = true }), [=[\mapsto ]=]),
	parse(ctx({ trig = "<=", dscr = "Less than or equal", math = true, inword = true, auto = true }), [=[\le ]=]),
	parse(ctx({ trig = ">=", dscr = "Greater than or equal", math = true, inword = true, auto = true }), [=[\ge ]=]),
	parse(ctx({ trig = "==", dscr = "Aligned equals", math = true, inword = true, auto = true }), [=[&= $1 \\]=]),
	parse(ctx({ trig = "!=", dscr = "Not equal", math = true, inword = true, auto = true }), [=[\neq ]=]),
	parse(ctx({ trig = "EE", dscr = "Exists", math = true, inword = true, auto = true }), [=[\exists ]=]),
	parse(ctx({ trig = "AA", dscr = "For all", math = true, inword = true, auto = true }), [=[\forall ]=]),
	parse(ctx({ trig = "xx", dscr = "Times", math = true, inword = true, auto = true }), [=[\times ]=]),
	parse(ctx({ trig = "**", dscr = "Cdot", priority = 100, math = true, inword = true, auto = true }), [=[\cdot ]=]),
	parse(ctx({ trig = "RR", dscr = "Real numbers", math = true, inword = true, auto = true }), [=[\R]=]),
	parse(ctx({ trig = "NN", dscr = "Natural numbers", math = true, inword = true, auto = true }), [=[\N]=]),
	parse(ctx({ trig = "QQ", dscr = "Rational numbers", math = true, inword = true, auto = true }), [=[\Q]=]),
	parse(ctx({ trig = "ZZ", dscr = "Integers", math = true, inword = true, auto = true }), [=[\Z]=]),
	parse(ctx({ trig = "OO", dscr = "Empty set", math = true, inword = true, auto = true }), [=[\O]=]),
	parse(ctx({ trig = "UU", dscr = "Union", math = true, inword = true, auto = true }), [=[\cup ]=]),
	parse(ctx({ trig = "Nn", dscr = "Intersection", math = true, inword = true, auto = true }), [=[\cap ]=]),
	parse(ctx({ trig = "cc", dscr = "Subset", math = true, inword = true, auto = true }), [=[\subset ]=]),
	parse(ctx({ trig = "inn", dscr = "In", math = true, inword = true, auto = true }), [=[\in ]=]),
	parse(ctx({ trig = "notin", dscr = "Not in", math = true, inword = true, auto = true }), [=[\not\in ]=]),
	parse(
		ctx({ trig = "case", dscr = "Cases", math = true, auto = true }),
		[=[\begin{cases}
    $1
\end{cases}]=]
	),
	parse(
		ctx({ trig = "bar", dscr = "Overline", priority = 10, math = true, regex = true, inword = true, auto = true }),
		[=[\overline{$1}$0]=]
	),
	s(
		ctx({
			trig = [[([a-zA-Z])bar]],
			dscr = "Letter overline",
			priority = 100,
			math = true,
			regex = true,
			inword = true,
			auto = true,
		}),
		{
			t([[\overline{]]),
			f(capture(1), {}),
			t("}"),
		}
	),
	parse(
		ctx({ trig = "hat", dscr = "Hat", priority = 10, math = true, regex = true, inword = true, auto = true }),
		[=[\hat{$1}$0]=]
	),
	s(
		ctx({
			trig = [[([a-zA-Z])hat]],
			dscr = "Letter hat",
			priority = 100,
			math = true,
			regex = true,
			inword = true,
			auto = true,
		}),
		{
			t([[\hat{]]),
			f(capture(1), {}),
			t("}"),
		}
	),
	parse(ctx({ trig = "norm", dscr = "Norm", math = true, inword = true, auto = true }), [=[\|$1\|$0]=]),
	parse(ctx({ trig = "conj", dscr = "Conjugate", math = true, inword = true, auto = true }), [=[\overline{$1}$0]=]),
	parse(ctx({ trig = "invs", dscr = "Inverse", math = true, inword = true, auto = true }), [=[^{-1}]=]),
	parse(ctx({ trig = "compl", dscr = "Complement", math = true, inword = true, auto = true }), [=[^{c}]=]),
	parse(
		ctx({ trig = "ceil", dscr = "Ceiling", math = true, inword = true, auto = true }),
		[=[\left\lceil $1 \right\rceil $0]=]
	),
	parse(
		ctx({ trig = "floor", dscr = "Floor", math = true, inword = true, auto = true }),
		[=[\left\lfloor $1 \right\rfloor$0]=]
	),
	parse(ctx({ trig = "mcal", dscr = "Mathcal", math = true, inword = true, auto = true }), [=[\mathcal{$1}$0]=]),
	parse(ctx({ trig = "lll", dscr = "Ell", math = true, inword = true, auto = true }), [=[\ell]=]),
	parse(ctx({ trig = "nabl", dscr = "Nabla", math = true, inword = true, auto = true }), [=[\nabla ]=]),
	parse(ctx({ trig = "ooo", dscr = "Infinity", math = true, inword = true, auto = true }), [=[\infty]=]),
	parse(
		ctx({ trig = "dint", dscr = "Definite integral", priority = 300, math = true, auto = true }),
		[=[\int_{${1:-\infty}}^{${2:\infty}} ${3:${TM_SELECTED_TEXT}} $0]=]
	),
	parse(
		ctx({ trig = "sum", dscr = "Sum", math = true, auto = true }),
		[=[\sum_{n=${1:1}}^{${2:\infty}} ${3:a_n z^n}]=]
	),
	parse(
		ctx({ trig = "prod", dscr = "Product", math = true, auto = true }),
		[=[\prod_{${1:n=${2:1}}}^{${3:\infty}} ${4:${TM_SELECTED_TEXT}} $0]=]
	),
	parse(ctx({ trig = "lim", dscr = "Limit", math = true, auto = true }), [=[\lim_{${1:n} \to ${2:\infty}} ]=]),
	parse(
		ctx({ trig = "limsup", dscr = "Limit superior", math = true, auto = true }),
		[=[\limsup_{${1:n} \to ${2:\infty}} ]=]
	),
	parse(
		ctx({ trig = "part", dscr = "Partial derivative", math = true, auto = true }),
		[=[\frac{\partial ${1:V}}{\partial ${2:x}} $0]=]
	),
	parse(ctx({ trig = "tt", dscr = "Text", math = true, inword = true, auto = true }), [=[\text{$1}$0]=]),
	s(ctx({ trig = [[([A-Za-z])(\d)]], dscr = "Auto subscript", math = true, regex = true, auto = true }), {
		f(capture(1), {}),
		t("_"),
		f(capture(2), {}),
	}),
	s(ctx({ trig = [[([A-Za-z])_(\d\d)]], dscr = "Auto braced subscript", math = true, regex = true, auto = true }), {
		f(capture(1), {}),
		t("_{"),
		f(capture(2), {}),
		t("}"),
	}),
	s(
		ctx({
			trig = [[(?<!\\)(arcsin|arccos|arctan|arccot|arccsc|arcsec|sin|cos|cot|csc|ln|log|exp|star|perp|pi|zeta|int)]],
			dscr = "Backslash math function",
			priority = 200,
			math = true,
			regex = true,
			auto = true,
		}),
		{
			t([[\]]),
			f(capture(1), {}),
		}
	),
}
