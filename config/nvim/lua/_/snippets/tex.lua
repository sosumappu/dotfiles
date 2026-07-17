local ls = require 'luasnip'

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local parse = ls.parser.parse_snippet
local line_begin = require('luasnip.extras.expand_conditions').line_begin

local in_mathzone = require('_.snippets.mathzone').in_mathzone

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
		opts.snippetType = 'autosnippet'
		opts.auto = nil
	end
	if opts.inword then
		opts.wordTrig = false
		opts.inword = nil
	end
	if opts.regex then
		opts.trigEngine = 'ecma'
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
		return snip.captures[index] or ''
	end
end

local function mk_spacing(args)
	local next_text = args[1] and args[1][1] or ''
	local first = next_text:sub(1, 1)
	if first ~= '' and not vim.tbl_contains({ ',', '.', '?', '-', ' ' }, first) then
		return ' '
	end
	return ''
end

local function paren_fraction(_, snip)
	local stripped = snip.captures[1] or ''
	local depth = 0

	for index = #stripped, 1, -1 do
		local char = stripped:sub(index, index)
		if char == ')' then
			depth = depth + 1
		elseif char == '(' then
			depth = depth - 1
		end
		if depth == 0 then
			local prefix = stripped:sub(1, index - 1)
			local numerator = stripped:sub(index + 1, -2)
			return prefix .. [[\frac{]] .. numerator .. '}'
		end
	end

	return [[\frac{]]
end

return {
	parse(ctx { trig = 'template', dscr = 'Basic template', line = true }, [=[
\documentclass[a4paper]{article}

\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{textcomp}
\usepackage[dutch]{babel}
\usepackage{amsmath, amssymb}


% figure support
\usepackage{import}
\usepackage{xifthen}
\pdfminorversion=7
\usepackage{pdfpages}
\usepackage{transparent}
\newcommand{\incfig}[1]{%
    \def\svgwidth{\columnwidth}
    \import{./figures/}{#1.pdf_tex}
}

\pdfsuppresswarningpagegroup=1

\begin{document}
    $0
\end{document}
]=]),
	parse(ctx { trig = 'beg', dscr = 'begin{} / end{}', line = true, auto = true }, [=[
\\begin{$1}
    $0
\\end{$1}
]=]),
	parse(ctx { trig = '...', dscr = 'ldots', priority = 100, inword = true, auto = true }, [=[\ldots]=]),
	parse(ctx { trig = 'table', dscr = 'Table environment', line = true }, [=[
\begin{table}[${1:htpb}]
    \centering
    \caption{${2:caption}}
    \label{tab:${3:label}}
    \begin{tabular}{${5:c}}
    $0${5/((?<=.)c|l|r)|./(?1: & )/g}
    \end{tabular}
\end{table}
]=]),
	parse(ctx { trig = 'fig', dscr = 'Figure environment', line = true }, [=[
\begin{figure}[${1:htpb}]
    \centering
    ${2:\includegraphics[width=0.8\textwidth]{$3}}
    \caption{${4:$3}}
    \label{fig:${5:${3/\W+/-/g}}}
\end{figure}
]=]),
	parse(ctx { trig = 'enum', dscr = 'Enumerate', line = true, auto = true }, [=[
\begin{enumerate}
    \item $0
\end{enumerate}
]=]),
	parse(ctx { trig = 'item', dscr = 'Itemize', line = true, auto = true }, [=[
\begin{itemize}
    \item $0
\end{itemize}
]=]),
	parse(ctx { trig = 'desc', dscr = 'Description', line = true }, [=[
\begin{description}
    \item[$1] $0
\end{description}
]=]),
	parse(ctx { trig = 'pac', dscr = 'Package', line = true }, [=[\usepackage[${1:options}]{${2:package}}$0]=]),
	parse(ctx { trig = '=>', dscr = 'implies', inword = true, auto = true }, [=[\implies]=]),
	parse(ctx { trig = '=<', dscr = 'implied by', inword = true, auto = true }, [=[\impliedby]=]),
	parse(ctx { trig = 'iff', dscr = 'iff', math = true, inword = true, auto = true }, [=[\iff]=]),
	s(ctx { trig = 'mk', dscr = 'Math', auto = true }, {
		t '$',
		i(1),
		t '$',
		f(mk_spacing, { 2 }),
		i(2),
	}),
	parse(ctx { trig = 'dm', dscr = 'Math', auto = true }, [=[
\[
${1:${TM_SELECTED_TEXT}}
.\] $0
]=]),
	parse(ctx { trig = 'ali', dscr = 'Align', line = true, auto = true }, [=[
\begin{align*}
    ${1:${TM_SELECTED_TEXT}}
.\end{align*}
]=]),
	parse(ctx { trig = '//', dscr = 'Fraction', math = true, inword = true, auto = true }, [=[\\frac{$1}{$2}$0]=]),
	parse(ctx { trig = '/', dscr = 'Fraction', inword = true }, [=[\\frac{${TM_SELECTED_TEXT}}{$1}$0]=]),
	s(ctx { trig = [[((\d+)|(\d*)(\\)?([A-Za-z]+)((\^|_)(\{\d+\}|\d))*)/]], dscr = 'symbol frac', math = true, regex = true, auto = true }, {
		t [[\frac{]],
		f(capture(1), {}),
		t '}{',
		i(1),
		t '}',
		i(0),
	}),
	s(ctx { trig = [[^(.*\))/]], dscr = '() frac', priority = 1000, math = true, regex = true, auto = true }, {
		f(paren_fraction, {}),
		t '{',
		i(1),
		t '}',
		i(0),
	}),
	s(ctx { trig = [[([A-Za-z])(\d)]], dscr = 'auto subscript', math = true, regex = true, auto = true }, {
		f(capture(1), {}),
		t '_',
		f(capture(2), {}),
	}),
	s(ctx { trig = [[([A-Za-z])_(\d\d)]], dscr = 'auto subscript2', math = true, regex = true, auto = true }, {
		f(capture(1), {}),
		t '_{',
		f(capture(2), {}),
		t '}',
	}),
	parse(ctx { trig = 'sympy', dscr = 'sympyblock ' }, [=[sympy $1 sympy$0]=]),
	-- TODO: verify port of sympy(.*)sympy
	-- The UltiSnips version evaluates arbitrary SymPy Python in-process.
	parse(ctx { trig = 'math', dscr = 'mathematicablock', priority = 1000 }, [=[math $1 math$0]=]),
	-- TODO: verify port of math(.*)math
	-- The UltiSnips version shells out to wolframscript.
	parse(ctx { trig = '==', dscr = 'equals', inword = true, auto = true }, [=[&= $1 \\]=]),
	parse(ctx { trig = '!=', dscr = 'equals', inword = true, auto = true }, [=[\neq ]=]),
	parse(ctx { trig = 'ceil', dscr = 'ceil', math = true, inword = true, auto = true }, [=[\left\lceil $1 \right\rceil $0]=]),
	parse(ctx { trig = 'floor', dscr = 'floor', math = true, inword = true, auto = true }, [=[\left\lfloor $1 \right\rfloor$0]=]),
	parse(ctx { trig = 'pmat', dscr = 'pmat', inword = true, auto = true }, [=[\begin{pmatrix} $1 \end{pmatrix} $0]=]),
	parse(ctx { trig = 'bmat', dscr = 'bmat', inword = true, auto = true }, [=[\begin{bmatrix} $1 \end{bmatrix} $0]=]),
	parse(ctx { trig = '()', dscr = 'left( right)', math = true, inword = true, auto = true }, [=[\left( ${1:${TM_SELECTED_TEXT}} \right) $0]=]),
	parse(ctx { trig = 'lr', dscr = 'left( right)', inword = true }, [=[\left( ${1:${TM_SELECTED_TEXT}} \right) $0]=]),
	parse(ctx { trig = 'lr(', dscr = 'left( right)', inword = true }, [=[\left( ${1:${TM_SELECTED_TEXT}} \right) $0]=]),
	parse(ctx { trig = 'lr|', dscr = 'left| right|', inword = true }, [=[\left| ${1:${TM_SELECTED_TEXT}} \right| $0]=]),
	parse(ctx { trig = 'lr{', dscr = [[left\{ right\}]], inword = true }, [=[\left\\{ ${1:${TM_SELECTED_TEXT}} \right\\} $0]=]),
	parse(ctx { trig = 'lrb', dscr = [[left\{ right\}]], inword = true }, [=[\left\\{ ${1:${TM_SELECTED_TEXT}} \right\\} $0]=]),
	parse(ctx { trig = 'lr[', dscr = 'left[ right]', inword = true }, [=[\left[ ${1:${TM_SELECTED_TEXT}} \right] $0]=]),
	parse(ctx { trig = 'lra', dscr = 'leftangle rightangle', inword = true, auto = true }, [=[\left<${1:${TM_SELECTED_TEXT}} \right>$0]=]),
	parse(ctx { trig = 'conj', dscr = 'conjugate', math = true, inword = true, auto = true }, [=[\overline{$1}$0]=]),
	parse(ctx { trig = 'sum', dscr = 'sum' }, [=[\sum_{n=${1:1}}^{${2:\infty}} ${3:a_n z^n}]=]),
	parse(ctx { trig = 'taylor', dscr = 'taylor' }, [=[\sum_{${1:k}=${2:0}}^{${3:\infty}} ${4:c_$1} (x-a)^$1 $0]=]),
	parse(ctx { trig = 'lim', dscr = 'limit' }, [=[\lim_{${1:n} \to ${2:\infty}} ]=]),
	parse(ctx { trig = 'limsup', dscr = 'limsup' }, [=[\limsup_{${1:n} \to ${2:\infty}} ]=]),
	parse(ctx { trig = 'prod', dscr = 'product' }, [=[\prod_{${1:n=${2:1}}}^{${3:\infty}} ${4:${TM_SELECTED_TEXT}} $0]=]),
	parse(ctx { trig = 'part', dscr = 'd/dx' }, [=[\frac{\partial ${1:V}}{\partial ${2:x}} $0]=]),
	parse(ctx { trig = 'sq', dscr = [[\sqrt{}]], math = true, inword = true, auto = true }, [=[\sqrt{${1:${TM_SELECTED_TEXT}}} $0]=]),
	parse(ctx { trig = 'sr', dscr = '^2', math = true, inword = true, auto = true }, [=[^2]=]),
	parse(ctx { trig = 'cb', dscr = '^3', math = true, inword = true, auto = true }, [=[^3]=]),
	parse(ctx { trig = 'td', dscr = 'to the ... power', math = true, inword = true, auto = true }, [=[^{$1}$0]=]),
	parse(ctx { trig = 'rd', dscr = 'to the ... power', math = true, inword = true, auto = true }, [=[^{($1)}$0]=]),
	parse(ctx { trig = '__', dscr = 'subscript', inword = true, auto = true }, [=[_{$1}$0]=]),
	parse(ctx { trig = 'ooo', dscr = [[\infty]], inword = true, auto = true }, [=[\infty]=]),
	parse(ctx { trig = 'rij', dscr = 'mrij', inword = true }, [=[(${1:x}_${2:n})_{${3:$2}\\in${4:\\N}}$0]=]),
	parse(ctx { trig = '<=', dscr = 'leq', inword = true, auto = true }, [=[\le ]=]),
	parse(ctx { trig = '>=', dscr = 'geq', inword = true, auto = true }, [=[\ge ]=]),
	parse(ctx { trig = 'EE', dscr = 'geq', math = true, inword = true, auto = true }, [=[\exists ]=]),
	parse(ctx { trig = 'AA', dscr = 'forall', math = true, inword = true, auto = true }, [=[\forall ]=]),
	parse(ctx { trig = 'xnn', dscr = 'xn', math = true, inword = true, auto = true }, [=[x_{n}]=]),
	parse(ctx { trig = 'ynn', dscr = 'yn', math = true, inword = true, auto = true }, [=[y_{n}]=]),
	parse(ctx { trig = 'xii', dscr = 'xi', math = true, inword = true, auto = true }, [=[x_{i}]=]),
	parse(ctx { trig = 'yii', dscr = 'yi', math = true, inword = true, auto = true }, [=[y_{i}]=]),
	parse(ctx { trig = 'xjj', dscr = 'xj', math = true, inword = true, auto = true }, [=[x_{j}]=]),
	parse(ctx { trig = 'yjj', dscr = 'yj', math = true, inword = true, auto = true }, [=[y_{j}]=]),
	parse(ctx { trig = 'xp1', dscr = 'x', math = true, inword = true, auto = true }, [=[x_{n+1}]=]),
	parse(ctx { trig = 'xmm', dscr = 'x', math = true, inword = true, auto = true }, [=[x_{m}]=]),
	parse(ctx { trig = 'R0+', dscr = 'R0+', inword = true, auto = true }, [=[\\R_0^+]=]),
	parse(ctx { trig = 'plot', dscr = 'Plot' }, [=[
\begin{figure}[$1]
    \centering
    \begin{tikzpicture}
        \begin{axis}[
            xmin= ${2:-10}, xmax= ${3:10},
            ymin= ${4:-10}, ymax = ${5:10},
            axis lines = middle,
        ]
            \addplot[domain=$2:$3, samples=${6:100}]{$7};
        \end{axis}
    \end{tikzpicture}
    \caption{$8}
    \label{${9:$8}}
\end{figure}
]=]),
	parse(ctx { trig = 'nn', dscr = 'Tikz node' }, [=[
\node[$5] (${1/[^0-9a-zA-Z]//g}${2}) ${3:at (${4:0,0}) }{\$${1}\$};
$0
]=]),
	parse(ctx { trig = 'mcal', dscr = 'mathcal', math = true, inword = true, auto = true }, [=[\mathcal{$1}$0]=]),
	parse(ctx { trig = 'lll', dscr = 'l', inword = true, auto = true }, [=[\ell]=]),
	parse(ctx { trig = 'nabl', dscr = 'nabla', math = true, inword = true, auto = true }, [=[\nabla ]=]),
	parse(ctx { trig = 'xx', dscr = 'cross', math = true, inword = true, auto = true }, [=[\times ]=]),
	parse(ctx { trig = '**', dscr = 'cdot', priority = 100, inword = true, auto = true }, [=[\cdot ]=]),
	parse(ctx { trig = 'norm', dscr = 'norm', math = true, inword = true, auto = true }, [=[\|$1\|$0]=]),
	s(ctx { trig = [[(?<!\\)(sin|cos|arccot|cot|csc|ln|log|exp|star|perp)]], dscr = 'ln', priority = 100, math = true, regex = true, auto = true }, {
		t [[\]],
		f(capture(1), {}),
	}),
	parse(ctx { trig = 'dint', dscr = 'integral', priority = 300, math = true, auto = true }, [=[\int_{${1:-\infty}}^{${2:\infty}} ${3:${TM_SELECTED_TEXT}} $0]=]),
	s(ctx { trig = [[(?<!\\)(arcsin|arccos|arctan|arccot|arccsc|arcsec|pi|zeta|int)]], dscr = 'ln', priority = 200, math = true, regex = true, auto = true }, {
		t [[\]],
		f(capture(1), {}),
	}),
	parse(ctx { trig = '->', dscr = 'to', priority = 100, math = true, inword = true, auto = true }, [=[\to ]=]),
	parse(ctx { trig = '<->', dscr = 'leftrightarrow', priority = 200, math = true, inword = true, auto = true }, [=[\leftrightarrow]=]),
	parse(ctx { trig = '!>', dscr = 'mapsto', math = true, inword = true, auto = true }, [=[\mapsto ]=]),
	parse(ctx { trig = 'invs', dscr = 'inverse', math = true, inword = true, auto = true }, [=[^{-1}]=]),
	parse(ctx { trig = 'compl', dscr = 'complement', math = true, inword = true, auto = true }, [=[^{c}]=]),
	parse(ctx { trig = [[\\\]], dscr = 'setminus', math = true, inword = true, auto = true }, [=[\setminus]=]),
	parse(ctx { trig = '>>', dscr = '>>', inword = true, auto = true }, [=[\gg]=]),
	parse(ctx { trig = '<<', dscr = '<<', inword = true, auto = true }, [=[\ll]=]),
	parse(ctx { trig = '~~', dscr = '~', inword = true, auto = true }, [=[\sim ]=]),
	parse(ctx { trig = 'set', dscr = 'set', math = true, auto = true }, [=[\\{$1\\} $0]=]),
	parse(ctx { trig = '||', dscr = 'mid', inword = true, auto = true }, [=[ \mid ]=]),
	parse(ctx { trig = 'cc', dscr = 'subset', math = true, inword = true, auto = true }, [=[\subset ]=]),
	parse(ctx { trig = 'notin', dscr = 'not in ', inword = true, auto = true }, [=[\not\in ]=]),
	parse(ctx { trig = 'inn', dscr = 'in ', math = true, inword = true, auto = true }, [=[\in ]=]),
	parse(ctx { trig = 'NN', dscr = 'n', inword = true, auto = true }, [=[\N]=]),
	parse(ctx { trig = 'Nn', dscr = 'cap', inword = true, auto = true }, [=[\cap ]=]),
	parse(ctx { trig = 'UU', dscr = 'cup', inword = true, auto = true }, [=[\cup ]=]),
	parse(ctx { trig = 'uuu', dscr = 'bigcup', inword = true, auto = true }, [=[\bigcup_{${1:i \in ${2: I}}} $0]=]),
	parse(ctx { trig = 'nnn', dscr = 'bigcap', inword = true, auto = true }, [=[\bigcap_{${1:i \in ${2: I}}} $0]=]),
	parse(ctx { trig = 'OO', dscr = 'emptyset', inword = true, auto = true }, [=[\O]=]),
	parse(ctx { trig = 'RR', dscr = 'real', inword = true, auto = true }, [=[\R]=]),
	parse(ctx { trig = 'QQ', dscr = 'Q', inword = true, auto = true }, [=[\Q]=]),
	parse(ctx { trig = 'ZZ', dscr = 'Z', inword = true, auto = true }, [=[\Z]=]),
	parse(ctx { trig = '<!', dscr = 'normal', inword = true, auto = true }, [=[\triangleleft ]=]),
	parse(ctx { trig = '<>', dscr = 'hokje', inword = true, auto = true }, [=[\diamond ]=]),
	parse(ctx { trig = [[(?<!i)sts]], dscr = 'text subscript', math = true, regex = true, inword = true, auto = true }, [=[_\text{$1} $0]=]),
	parse(ctx { trig = 'tt', dscr = 'text', math = true, inword = true, auto = true }, [=[\text{$1}$0]=]),
	parse(ctx { trig = 'case', dscr = 'cases', math = true, auto = true }, [=[
\begin{cases}
    $1
\end{cases}
]=]),
	parse(ctx { trig = 'SI', dscr = 'SI', inword = true, auto = true }, [=[\SI{$1}{$2}]=]),
	parse(ctx { trig = 'bigfun', dscr = 'Big function', inword = true, auto = true }, [=[
\begin{align*}
    $1: $2 &\longrightarrow $3 \\
    $4 &\longmapsto $1($4) = $0
.\end{align*}
]=]),
	parse(ctx { trig = 'cvec', dscr = 'column vector', inword = true, auto = true }, [=[\begin{pmatrix} ${1:x}_${2:1}\\ \vdots\\ $1_${2:n} \end{pmatrix}]=]),
	parse(ctx { trig = 'bar', dscr = 'bar', priority = 10, math = true, regex = true, inword = true, auto = true }, [=[\overline{$1}$0]=]),
	s(ctx { trig = [[([a-zA-Z])bar]], dscr = 'bar', priority = 100, math = true, regex = true, inword = true, auto = true }, {
		t [[\overline{]],
		f(capture(1), {}),
		t '}',
	}),
	parse(ctx { trig = 'hat', dscr = 'hat', priority = 10, math = true, regex = true, inword = true, auto = true }, [=[\hat{$1}$0]=]),
	s(ctx { trig = [[([a-zA-Z])hat]], dscr = 'hat', priority = 100, math = true, regex = true, inword = true, auto = true }, {
		t [[\hat{]],
		f(capture(1), {}),
		t '}',
	}),
	parse(ctx { trig = 'letw', dscr = 'let omega', inword = true, auto = true }, [=[Let \$\Omega \subset \C\$ be open.]=]),
	parse(ctx { trig = 'HH', dscr = 'H', inword = true, auto = true }, [=[\mathbb{H}]=]),
	parse(ctx { trig = 'DD', dscr = 'D', inword = true, auto = true }, [=[\mathbb{D}]=]),
}
