local ls = require("luasnip")
local parse = ls.parser.parse_snippet
local math_snippets = require("_.snippets.math")
local ctx = math_snippets.ctx

local snippets = {
	parse(
		ctx({ trig = "template", dscr = "Analysis Mémoire / Article template", line = true }),
		[=[
\documentclass[11pt,a4paper]{article}

\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage[french,english]{babel}
\usepackage{amsmath,amssymb,amsthm,mathtools}
\usepackage{microtype}
\usepackage{hyperref}
\usepackage{cleveref}

\newtheorem{theorem}{Théorème}[section]
\newtheorem{lemma}[theorem]{Lemme}
\newtheorem{proposition}[theorem]{Proposition}
\newtheorem{corollary}[theorem]{Corollaire}
\theoremstyle{definition}
\newtheorem{definition}[theorem]{Définition}
\theoremstyle{remark}
\newtheorem{remark}[theorem]{Remarque}

\begin{document}
	$0
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
}

vim.list_extend(snippets, math_snippets.get({ dm_style = "bracket" }))

return snippets
