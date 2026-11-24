local ls = require("luasnip")
local parse = ls.parser.parse_snippet
local math_snippets = require("_.snippets.math")
local ctx = math_snippets.ctx

local snippets = {
	parse(
		ctx({ trig = "template", dscr = "French math/quant article template", line = true, text = true }),
		[=[
\documentclass[11pt,a4paper]{article}

% ---------- Encoding, fonts, language ----------
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage[english,french]{babel}
\usepackage{csquotes}

% ---------- Math ----------
\usepackage{amsmath, amssymb, amsthm, mathtools}
\usepackage{bm, dsfont}
\usepackage{siunitx}

% ---------- Typography & layout ----------
\usepackage{microtype}
\usepackage[margin=2.5cm]{geometry}
\usepackage{enumitem}
\usepackage{booktabs}

% ---------- Graphics ----------
\usepackage{graphicx}
\usepackage{tikz}
\usepackage{pgfplots}
\pgfplotsset{compat=1.18}
\usetikzlibrary{cd}

% ---------- Bibliography ----------
\usepackage[backend=biber, style=authoryear-comp]{biblatex}
\addbibresource{${1:refs.bib}}

% ---------- Cross-references (hyperref late, cleveref after) ----------
\usepackage{hyperref}
\usepackage{cleveref}

% ---------- Theorem environments ----------
\theoremstyle{plain}
\newtheorem{theorem}{Théorème}[section]
\newtheorem{lemma}[theorem]{Lemme}
\newtheorem{proposition}[theorem]{Proposition}
\newtheorem{corollary}[theorem]{Corollaire}
\theoremstyle{definition}
\newtheorem{definition}[theorem]{Définition}
\theoremstyle{remark}
\newtheorem*{remark}{Remarque}

\title{${2:Title}}
\author{${3:Adel Arab}}
\date{\today}

\begin{document}
\maketitle
\tableofcontents

$0

\printbibliography
\end{document}
]=]
	),
	parse(
		ctx({ trig = "beg", dscr = "begin{} / end{}", line = true, auto = true }),
		[=[
\begin{$1}
	$0
\end{$1}
]=]
	),
	parse(
		ctx({ trig = "thm", dscr = "Theorem environment", line = true }),
		[=[
\begin{theorem}[${1:Name}]\label{thm:${2:label}}
	$0
\end{theorem}
]=]
	),
	parse(
		ctx({ trig = "lem", dscr = "Lemma environment", line = true }),
		[=[
\begin{lemma}[${1:Name}]\label{lem:${2:label}}
	$0
\end{lemma}
]=]
	),
	parse(
		ctx({ trig = "prop", dscr = "Proposition environment", line = true }),
		[=[
\begin{proposition}[${1:Name}]\label{prop:${2:label}}
	$0
\end{proposition}
]=]
	),
	parse(
		ctx({ trig = "def", dscr = "Definition environment", line = true }),
		[=[
\begin{definition}[${1:Name}]\label{def:${2:label}}
	$0
\end{definition}
]=]
	),
	parse(
		ctx({ trig = "prf", dscr = "Proof environment", line = true }),
		[=[
\begin{proof}
	$0
\end{proof}
]=]
	),
	parse(
		ctx({ trig = "enum", dscr = "Enumerate", line = true, auto = true }),
		[=[
\begin{enumerate}
	\item $0
\end{enumerate}
]=]
	),
	parse(
		ctx({ trig = "item", dscr = "Itemize", line = true, auto = true }),
		[=[
\begin{itemize}
	\item $0
\end{itemize}
]=]
	),
	parse(
		ctx({ trig = "desc", dscr = "Description", line = true }),
		[=[
\begin{description}
	\item[$1] $0
\end{description}
]=]
	),
	parse(ctx({ trig = "pac", dscr = "Package", line = true }), [=[\usepackage[${1:options}]{${2:package}}$0]=]),
	parse(
		ctx({ trig = "fig", dscr = "Figure environment", line = true }),
		[=[
\begin{figure}[${1:htpb}]
	\centering
	${2:\includegraphics[width=0.8\textwidth]{$3}}
	\caption{${4:$3}}
	\label{fig:${5:${3/\W+/-/g}}}
\end{figure}
]=]
	),
	parse(
		ctx({ trig = "table", dscr = "Table environment", line = true }),
		[=[
\begin{table}[${1:htpb}]
	\centering
	\caption{${2:caption}}
	\label{tab:${3:label}}
	\begin{tabular}{${5:c}}
	$0${5/((?<=.)c|l|r)|./(?1: & )/g}
	\end{tabular}
\end{table}
]=]
	),

	-- Document structure. Line-begin + text so they never fire inside math
	-- or inline prose. Each pairs the heading with a cleveref-ready label.
	parse(ctx({ trig = "cha", dscr = "Chapter", line = true, text = true }), [=[\chapter{$1}\label{chap:${2:label}}$0]=]),
	parse(ctx({ trig = "sec", dscr = "Section", line = true, text = true }), [=[\section{$1}\label{sec:${2:label}}$0]=]),
	parse(
		ctx({ trig = "sub", dscr = "Subsection", line = true, text = true }),
		[=[\subsection{$1}\label{subsec:${2:label}}$0]=]
	),
	parse(
		ctx({ trig = "ssub", dscr = "Subsubsection", line = true, text = true }),
		[=[\subsubsection{$1}\label{subsubsec:${2:label}}$0]=]
	),
	parse(ctx({ trig = "par", dscr = "Paragraph heading", line = true, text = true }), [=[\paragraph{$1}$0]=]),

	-- Biblatex citations. All text-mode; no line-begin so they drop in mid-sentence.
	parse(ctx({ trig = "cite", dscr = "Plain cite", text = true }), [=[\cite{$1}$0]=]),
	parse(
		ctx({ trig = "tcite", dscr = "Textual cite (Smith (2024))", text = true }),
		[=[\textcite{$1}$0]=]
	),
	parse(
		ctx({ trig = "pcite", dscr = "Parenthetical cite ((Smith 2024))", text = true }),
		[=[\parencite{$1}$0]=]
	),
	parse(ctx({ trig = "acite", dscr = "Autocite (style-dependent)", text = true }), [=[\autocite{$1}$0]=]),
	parse(ctx({ trig = "fcite", dscr = "Footnote cite", text = true }), [=[\footcite{$1}$0]=]),
	parse(ctx({ trig = "cauth", dscr = "citeauthor", text = true }), [=[\citeauthor{$1}$0]=]),

	-- Cross-references via cleveref. `cref` figures out the referent type
	-- (Theorem X, Section Y) from the label prefix so prefer it over
	-- bare \ref.
	parse(ctx({ trig = "cref", dscr = "cref (lowercase)", text = true }), [=[\cref{$1}$0]=]),
	parse(ctx({ trig = "Cref", dscr = "Cref (capitalised, sentence start)", text = true }), [=[\Cref{$1}$0]=]),
	parse(ctx({ trig = "cref2", dscr = "cref with two labels", text = true }), [=[\cref{$1,$2}$0]=]),
	parse(ctx({ trig = "nref", dscr = "nameref (prints name, not number)", text = true }), [=[\nameref{$1}$0]=]),
	parse(ctx({ trig = "pref", dscr = "pageref", text = true }), [=[\pageref{$1}$0]=]),
}

vim.list_extend(snippets, math_snippets.get({ dm_style = "bracket" }))

return snippets
