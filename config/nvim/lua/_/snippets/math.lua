local ls = require("luasnip")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local parse = ls.parser.parse_snippet
local line_begin = require("luasnip.extras.expand_conditions").line_begin

local mathzone = require("_.snippets.mathzone")

local M = {}

function M.in_mathzone(...)
	local ok, result = pcall(mathzone.math_mode, ...)
	return ok and result == true
end

function M.in_text(...)
	return not M.in_mathzone(...)
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

function M.ctx(opts)
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
		conditions[#conditions + 1] = M.in_mathzone
		opts.math = nil
	end
	if opts.text then
		conditions[#conditions + 1] = M.in_text
		opts.text = nil
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

function M.capture(index)
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

local function paren_fraction(_, snip)
	local stripped = snip.captures[1] or ""
	local depth = 0

	for index = #stripped, 1, -1 do
		local char = stripped:sub(index, index)
		if char == ")" then
			depth = depth + 1
		elseif char == "(" then
			depth = depth - 1
		end
		if depth == 0 then
			local prefix = stripped:sub(1, index - 1)
			local numerator = stripped:sub(index + 1, -2)
			return prefix .. [[\frac{]] .. numerator .. "}"
		end
	end

	return [[\frac{]]
end

---@param opts? { dm_style?: 'dollar' | 'bracket' }
function M.get(opts)
	opts = opts or {}
	local ctx = M.ctx
	local capture = M.capture

	local dm_body = opts.dm_style == "bracket" and [=[
\[
	${1:${TM_SELECTED_TEXT}}
\]
$0]=] or [=[
$$
${1:${TM_SELECTED_TEXT}}
$$
$0]=]

	return {
		-- Math zone entry
		s(ctx({ trig = "mk", dscr = "Inline math", text = true, auto = true }), {
			t("$"),
			i(1),
			t("$"),
			f(mk_spacing, { 2 }),
			i(2),
		}),
		parse(ctx({ trig = "dm", dscr = "Display math", line = true, text = true, auto = true }), dm_body),
		parse(
			ctx({ trig = "ali", dscr = "Align environment", line = true, auto = true }),
			[=[
\begin{align*}
	${1:${TM_SELECTED_TEXT}}
\end{align*}
$0]=]
		),

		-- Fractions & Powers
		parse(ctx({ trig = "//", dscr = "Fraction", math = true, inword = true, auto = true }), [=[\frac{$1}{$2}$0]=]),
		parse(
			ctx({ trig = "/", dscr = "Fraction from selection", math = true, inword = true }),
			[=[\frac{${TM_SELECTED_TEXT}}{$1}$0]=]
		),
		s(
			ctx({
				trig = [[((\d+)|(\d*)(\\)?([A-Za-z]+)((\^|_)(\{\d+\}|\d))*)/]],
				dscr = "Symbol fraction",
				math = true,
				regex = true,
				auto = true,
			}),
			{
				t([[\frac{]]),
				f(capture(1), {}),
				t("}{"),
				i(1),
				t("}"),
				i(0),
			}
		),
		s(
			ctx({
				trig = [[^(.*\))/]],
				dscr = "Parenthesized fraction",
				priority = 1000,
				math = true,
				regex = true,
				auto = true,
			}),
			{
				f(paren_fraction, {}),
				t("{"),
				i(1),
				t("}"),
				i(0),
			}
		),
		parse(ctx({ trig = "__", dscr = "Subscript", math = true, inword = true, auto = true }), [=[_{$1}$0]=]),
		parse(ctx({ trig = "sr", dscr = "Squared", math = true, inword = true, auto = true }), [=[^2]=]),
		parse(ctx({ trig = "cb", dscr = "Cubed", math = true, inword = true, auto = true }), [=[^3]=]),
		parse(ctx({ trig = "td", dscr = "Power", math = true, inword = true, auto = true }), [=[^{$1}$0]=]),
		parse(
			ctx({ trig = "rd", dscr = "Parenthesized power", math = true, inword = true, auto = true }),
			[=[^{($1)}$0]=]
		),
		parse(ctx({ trig = "invs", dscr = "Inverse", math = true, inword = true, auto = true }), [=[^{-1}]=]),
		parse(ctx({ trig = "compl", dscr = "Complement", math = true, inword = true, auto = true }), [=[^{c}]=]),
		parse(ctx({ trig = "TP", dscr = "Transpose", math = true, inword = true, auto = true }), [=[^{\top}]=]),
		parse(
			ctx({ trig = "sq", dscr = "Square root", math = true, inword = true, auto = true }),
			[=[\sqrt{${1:${TM_SELECTED_TEXT}}}$0]=]
		),

		-- Auto-subscripts & Sequences (Analysis)
		s(ctx({ trig = [[([A-Za-z])(\d)]], dscr = "Auto subscript", math = true, regex = true, auto = true }), {
			f(capture(1), {}),
			t("_"),
			f(capture(2), {}),
		}),
		s(
			ctx({ trig = [[([A-Za-z])_(\d\d)]], dscr = "Auto braced subscript", math = true, regex = true, auto = true }),
			{
				f(capture(1), {}),
				t("_{"),
				f(capture(2), {}),
				t("}"),
			}
		),
		parse(ctx({ trig = "xnn", dscr = "x_n", math = true, inword = true, auto = true }), [=[x_{n}]=]),
		parse(ctx({ trig = "ynn", dscr = "y_n", math = true, inword = true, auto = true }), [=[y_{n}]=]),
		parse(ctx({ trig = "xii", dscr = "x_i", math = true, inword = true, auto = true }), [=[x_{i}]=]),
		parse(ctx({ trig = "yii", dscr = "y_i", math = true, inword = true, auto = true }), [=[y_{i}]=]),
		parse(ctx({ trig = "xjj", dscr = "x_j", math = true, inword = true, auto = true }), [=[x_{j}]=]),
		parse(ctx({ trig = "yjj", dscr = "y_j", math = true, inword = true, auto = true }), [=[y_{j}]=]),
		parse(ctx({ trig = "xp1", dscr = "x_{n+1}", math = true, inword = true, auto = true }), [=[x_{n+1}]=]),
		parse(ctx({ trig = "xmm", dscr = "x_m", math = true, inword = true, auto = true }), [=[x_{m}]=]),
		parse(
			ctx({ trig = "rij", dscr = "Sequence (x_n)", math = true, inword = true }),
			[=[(${1:x}_${2:n})_{${3:$2}\in${4:\mathbb{N}}}$0]=]
		),

		-- Logic, Arrows & Relations
		parse(ctx({ trig = "->", dscr = "To", priority = 100, math = true, inword = true, auto = true }), [=[\to ]=]),
		parse(
			ctx({ trig = "<->", dscr = "Leftrightarrow", priority = 200, math = true, inword = true, auto = true }),
			[=[\leftrightarrow ]=]
		),
		parse(ctx({ trig = "!>", dscr = "Mapsto", math = true, inword = true, auto = true }), [=[\mapsto ]=]),
		parse(ctx({ trig = "=>", dscr = "Implies", math = true, inword = true, auto = true }), [=[\implies ]=]),
		parse(ctx({ trig = "=<", dscr = "Implied by", math = true, inword = true, auto = true }), [=[\impliedby ]=]),
		parse(ctx({ trig = "iff", dscr = "Iff", math = true, inword = true, auto = true }), [=[\iff ]=]),
		parse(ctx({ trig = "<=", dscr = "Less or equal", math = true, inword = true, auto = true }), [=[\le ]=]),
		parse(ctx({ trig = ">=", dscr = "Greater or equal", math = true, inword = true, auto = true }), [=[\ge ]=]),
		parse(ctx({ trig = "==", dscr = "Aligned equals", math = true, inword = true, auto = true }), [=[&= $1 \\\\]=]),
		parse(ctx({ trig = "!=", dscr = "Not equal", math = true, inword = true, auto = true }), [=[\neq ]=]),
		parse(
			ctx({ trig = "~~", dscr = "Sim / Distributed as", math = true, inword = true, auto = true }),
			[=[\sim ]=]
		),
		parse(ctx({ trig = "apx", dscr = "Approx", math = true, inword = true, auto = true }), [=[\approx ]=]),
		parse(ctx({ trig = ">>", dscr = "Much greater", math = true, inword = true, auto = true }), [=[\gg ]=]),
		parse(ctx({ trig = "<<", dscr = "Much less", math = true, inword = true, auto = true }), [=[\ll ]=]),
		parse(ctx({ trig = "EE", dscr = "Exists", math = true, inword = true, auto = true }), [=[\exists ]=]),
		parse(ctx({ trig = "AA", dscr = "For all", math = true, inword = true, auto = true }), [=[\forall ]=]),
		parse(
			ctx({ trig = "...", dscr = "ldots", priority = 100, math = true, inword = true, auto = true }),
			[=[\ldots]=]
		),
		parse(ctx({ trig = "xx", dscr = "Times", math = true, inword = true, auto = true }), [=[\times ]=]),
		parse(
			ctx({ trig = "**", dscr = "Cdot", priority = 100, math = true, inword = true, auto = true }),
			[=[\cdot ]=]
		),
		parse(ctx({ trig = "||", dscr = "Mid", math = true, inword = true, auto = true }), [=[ \mid ]=]),

		-- Sets & Number Systems (Standard \mathbb for portability across Quarto/KaTeX/MathJax & TeX)
		parse(ctx({ trig = "RR", dscr = "Real numbers", math = true, inword = true, auto = true }), [=[\mathbb{R}]=]),
		parse(
			ctx({ trig = "NN", dscr = "Natural numbers", math = true, inword = true, auto = true }),
			[=[\mathbb{N}]=]
		),
		parse(
			ctx({ trig = "QQ", dscr = "Rational numbers", math = true, inword = true, auto = true }),
			[=[\mathbb{Q}]=]
		),
		parse(ctx({ trig = "ZZ", dscr = "Integers", math = true, inword = true, auto = true }), [=[\mathbb{Z}]=]),
		parse(
			ctx({ trig = "CC", dscr = "Complex numbers", math = true, inword = true, auto = true }),
			[=[\mathbb{C}]=]
		),
		parse(ctx({ trig = "HH", dscr = "H", math = true, inword = true, auto = true }), [=[\mathbb{H}]=]),
		parse(ctx({ trig = "DD", dscr = "D", math = true, inword = true, auto = true }), [=[\mathbb{D}]=]),
		parse(ctx({ trig = "OO", dscr = "Empty set", math = true, inword = true, auto = true }), [=[\emptyset]=]),
		parse(ctx({ trig = "UU", dscr = "Union", math = true, inword = true, auto = true }), [=[\cup ]=]),
		parse(ctx({ trig = "Nn", dscr = "Intersection", math = true, inword = true, auto = true }), [=[\cap ]=]),
		parse(
			ctx({ trig = "uuu", dscr = "Big union", math = true, inword = true, auto = true }),
			[=[\bigcup_{${1:i \in ${2:I}}} $0]=]
		),
		parse(
			ctx({ trig = "nnn", dscr = "Big intersection", math = true, inword = true, auto = true }),
			[=[\bigcap_{${1:i \in ${2:I}}} $0]=]
		),
		parse(ctx({ trig = "cc", dscr = "Subset", math = true, inword = true, auto = true }), [=[\subset ]=]),
		parse(ctx({ trig = "cq", dscr = "Subseteq", math = true, inword = true, auto = true }), [=[\subseteq ]=]),
		parse(ctx({ trig = "inn", dscr = "In", math = true, inword = true, auto = true }), [=[\in ]=]),
		parse(ctx({ trig = "notin", dscr = "Not in", math = true, inword = true, auto = true }), [=[\notin ]=]),
		parse(ctx({ trig = [[\\\]], dscr = "Setminus", math = true, inword = true, auto = true }), [=[\setminus ]=]),
		parse(ctx({ trig = "set", dscr = "Set braces", math = true, auto = true }), [=[\{$1\} $0]=]),

		-- Statistics & Probability
		parse(
			ctx({ trig = "PP", dscr = "Probability", math = true, inword = true, auto = true }),
			[=[\mathbb{P}\left($1\right)$0]=]
		),
		parse(
			ctx({ trig = "EX", dscr = "Expectation", math = true, inword = true, auto = true }),
			[=[\mathbb{E}\left[$1\right]$0]=]
		),
		parse(
			ctx({ trig = "Var", dscr = "Variance", math = true, inword = true, auto = true }),
			[=[\operatorname{Var}\left($1\right)$0]=]
		),
		parse(
			ctx({ trig = "Cov", dscr = "Covariance", math = true, inword = true, auto = true }),
			[=[\operatorname{Cov}\left($1, $2\right)$0]=]
		),
		parse(
			ctx({ trig = "iid", dscr = "i.i.d. sim", math = true, inword = true, auto = true }),
			[=[\overset{\text{i.i.d.}}{\sim} ]=]
		),
		parse(
			ctx({ trig = "indep", dscr = "Independent", math = true, inword = true, auto = true }),
			[=[\perp\!\!\!\perp ]=]
		),
		parse(
			ctx({ trig = "Nrm", dscr = "Normal distribution", math = true, inword = true, auto = true }),
			[=[\mathcal{N}\left(${1:\mu}, ${2:\sigma^2}\right)$0]=]
		),
		parse(
			ctx({ trig = "1ind", dscr = "Indicator function", math = true, inword = true, auto = true }),
			[=[\mathbb{1}_{\{$1\}}$0]=]
		),

		-- Analysis, Calculus & Large Operators
		parse(ctx({ trig = "lll", dscr = "Ell", math = true, inword = true, auto = true }), [=[\ell]=]),
		parse(ctx({ trig = "nabl", dscr = "Nabla", math = true, inword = true, auto = true }), [=[\nabla ]=]),
		parse(ctx({ trig = "ooo", dscr = "Infinity", math = true, inword = true, auto = true }), [=[\infty]=]),
		parse(ctx({ trig = "eps", dscr = "varepsilon", math = true, inword = true, auto = true }), [=[\varepsilon]=]),
		parse(
			ctx({ trig = "dint", dscr = "Definite integral", priority = 300, math = true, auto = true }),
			[=[\int_{${1:-\infty}}^{${2:\infty}} ${3:${TM_SELECTED_TEXT}} \, \mathrm{d}${4:x}$0]=]
		),
		parse(ctx({ trig = "sum", dscr = "Sum", math = true, auto = true }), [=[\sum_{${1:n=1}}^{${2:\infty}} $0]=]),
		parse(
			ctx({ trig = "taylor", dscr = "Taylor series", math = true, auto = true }),
			[=[\sum_{${1:k}=${2:0}}^{${3:\infty}} ${4:c_$1} (x-a)^$1 $0]=]
		),
		parse(
			ctx({ trig = "prod", dscr = "Product", math = true, auto = true }),
			[=[\prod_{${1:n=1}}^{${2:\infty}} ${3:${TM_SELECTED_TEXT}} $0]=]
		),
		parse(ctx({ trig = "lim", dscr = "Limit", math = true, auto = true }), [=[\lim_{${1:n} \to ${2:\infty}} ]=]),
		parse(
			ctx({ trig = "limsup", dscr = "Limit superior", math = true, auto = true }),
			[=[\limsup_{${1:n} \to ${2:\infty}} ]=]
		),
		parse(
			ctx({ trig = "liminf", dscr = "Limit inferior", math = true, auto = true }),
			[=[\liminf_{${1:n} \to ${2:\infty}} ]=]
		),
		parse(
			ctx({ trig = "part", dscr = "Partial derivative", math = true, auto = true }),
			[=[\frac{\partial ${1:f}}{\partial ${2:x}} $0]=]
		),
		parse(
			ctx({ trig = "ddx", dscr = "Derivative", math = true, auto = true }),
			[=[\frac{\mathrm{d}${1:f}}{\mathrm{d}${2:x}} $0]=]
		),

		-- Delimiters, Norms, Matrices & Accents
		parse(
			ctx({ trig = "()", dscr = "left( right)", math = true, inword = true, auto = true }),
			[=[\left( ${1:${TM_SELECTED_TEXT}} \right)$0]=]
		),
		parse(
			ctx({ trig = "lr(", dscr = "left( right)", math = true, inword = true, auto = true }),
			[=[\left( ${1:${TM_SELECTED_TEXT}} \right)$0]=]
		),
		parse(
			ctx({ trig = "lr|", dscr = "left| right|", math = true, inword = true, auto = true }),
			[=[\left| ${1:${TM_SELECTED_TEXT}} \right|$0]=]
		),
		parse(
			ctx({ trig = "lr{", dscr = [[left\{ right\}]], math = true, inword = true, auto = true }),
			[=[\left\{ ${1:${TM_SELECTED_TEXT}} \right\}$0]=]
		),
		parse(
			ctx({ trig = "lrb", dscr = [[left\{ right\}]], math = true, inword = true, auto = true }),
			[=[\left\{ ${1:${TM_SELECTED_TEXT}} \right\}$0]=]
		),
		parse(
			ctx({ trig = "lr[", dscr = "left[ right]", math = true, inword = true, auto = true }),
			[=[\left[ ${1:${TM_SELECTED_TEXT}} \right]$0]=]
		),
		parse(
			ctx({ trig = "lra", dscr = "Inner product <,>", math = true, inword = true, auto = true }),
			[=[\left\langle ${1:${TM_SELECTED_TEXT}} \right\rangle$0]=]
		),
		parse(
			ctx({ trig = "norm", dscr = "Norm", math = true, inword = true, auto = true }),
			[=[\left\| $1 \right\|$0]=]
		),
		parse(
			ctx({ trig = "abs", dscr = "Absolute value", math = true, inword = true, auto = true }),
			[=[\left| $1 \right|$0]=]
		),
		parse(
			ctx({ trig = "ceil", dscr = "Ceiling", math = true, inword = true, auto = true }),
			[=[\left\lceil $1 \right\rceil$0]=]
		),
		parse(
			ctx({ trig = "floor", dscr = "Floor", math = true, inword = true, auto = true }),
			[=[\left\lfloor $1 \right\rfloor$0]=]
		),
		parse(
			ctx({ trig = "pmat", dscr = "pmatrix", math = true, inword = true, auto = true }),
			[=[\begin{pmatrix} $1 \end{pmatrix}$0]=]
		),
		parse(
			ctx({ trig = "bmat", dscr = "bmatrix", math = true, inword = true, auto = true }),
			[=[\begin{bmatrix} $1 \end{bmatrix}$0]=]
		),
		parse(
			ctx({ trig = "cvec", dscr = "Column vector", math = true, inword = true, auto = true }),
			[=[\begin{pmatrix} ${1:x}_${2:1}\\ \vdots\\ $1_${3:n} \end{pmatrix}$0]=]
		),
		parse(
			ctx({ trig = "case", dscr = "Cases", math = true, auto = true }),
			[=[
\begin{cases}
	$1
\end{cases}$0]=]
		),
		parse(ctx({ trig = "mcal", dscr = "Mathcal", math = true, inword = true, auto = true }), [=[\mathcal{$1}$0]=]),
		parse(ctx({ trig = "mbb", dscr = "Mathbb", math = true, inword = true, auto = true }), [=[\mathbb{$1}$0]=]),
		parse(ctx({ trig = "mbf", dscr = "Mathbf", math = true, inword = true, auto = true }), [=[\mathbf{$1}$0]=]),
		parse(ctx({ trig = "tt", dscr = "Text", math = true, inword = true, auto = true }), [=[\text{$1}$0]=]),
		parse(
			ctx({ trig = [[(?<!i)sts]], dscr = "Text subscript", math = true, regex = true, inword = true, auto = true }),
			[=[_\text{$1}$0]=]
		),
		parse(
			ctx({ trig = "conj", dscr = "Conjugate", math = true, inword = true, auto = true }),
			[=[\overline{$1}$0]=]
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
		parse(
			ctx({ trig = "til", dscr = "Tilde", priority = 10, math = true, regex = true, inword = true, auto = true }),
			[=[\tilde{$1}$0]=]
		),
		s(
			ctx({
				trig = [[([a-zA-Z])til]],
				dscr = "Letter tilde",
				priority = 100,
				math = true,
				regex = true,
				inword = true,
				auto = true,
			}),
			{
				t([[\tilde{]]),
				f(capture(1), {}),
				t("}"),
			}
		),

		-- Auto-backslashed functions & symbols
		s(
			ctx({
				trig = [[(?<!\\)(arcsin|arccos|arctan|arccot|arccsc|arcsec|sin|cos|tan|cot|csc|sec|ln|log|exp|det|dim|ker|im|sup|inf|max|min|arg|deg|gcd|star|perp|pi|zeta|int)]],
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
end

return M
