local ls = require("luasnip")
local parse = ls.parser.parse_snippet

local math_snippets = require("_.snippets.math")
local ctx = math_snippets.ctx

return {
	parse(
		ctx({ trig = "header", dscr = "Quarto YAML header", text = true }),
		[=[
---
title: "${1:$TM_FILENAME_BASE}"
author: "${2:Adel Arab}"
date: today
format:
  html:
    toc: true
    html-math-method: mathjax
---

$0
]=]
	),
	parse(
		ctx({ trig = "rchunk", dscr = "R code chunk", text = true }),
		[=[
```{r}
$0
]=]
	),
	parse(
		ctx({ trig = "pychunk", dscr = "Python code chunk", text = true }),
		[=[
$0
]=]
	),
	parse(
		ctx({ trig = "rchunko", dscr = "R code chunk with options", text = true }),
		[=[
#| label: fig-${1:name}
#| fig-cap: "${2:caption}"
#| echo: ${3:false}
$0
]=]
	),
	parse(
		ctx({ trig = "pychunko", dscr = "Python code chunk with options", text = true }),
		[=[
#| label: fig-${1:name}
#| fig-cap: "${2:caption}"
#| echo: ${3:false}
$0
]=]
	),
	parse(
		ctx({ trig = "callout", dscr = "Quarto callout block", text = true }),
		[=[::: {.callout-${1|note,warning,important,tip,caution|}}$0
:::
]=]
	),
	parse(
		ctx({ trig = "thm", dscr = "Quarto Theorem block", text = true }),
		[=[
::: {#thm-${1:label}}${2:Theorem Name}$0
:::
]=]
	),
	parse(
		ctx({ trig = "def", dscr = "Quarto Definition block", text = true }),
		[=[
::: {#def-${1:label}}${2:Definition Name}$0:::]=]
	),
	parse(
		ctx({ trig = "prf", dscr = "Quarto Proof block", text = true }),
		[=[::: {.proof}$0
:::
]=]
	),
	parse(
		ctx({ trig = "fig", dscr = "Figure with cross-ref label", text = true }),
		[=[![${1:caption}](${2:path}){#fig-${3:id}}$0]=]
	),
	parse(ctx({ trig = "cite", dscr = "Citation", text = true }), [=[[@${1:key}]$0]=]),
	parse(
		ctx({ trig = "tabset", dscr = "Panel tabset", text = true }),
		[=[::: {.panel-tabset}${1:Tab 1}$2${3:Tab 2}$0:::]=]
	),
	parse(ctx({ trig = "rinline", dscr = "Inline R code", text = true }), [=[r ${1:expr}$0]=]),
}
