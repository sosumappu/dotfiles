local ls = require("luasnip")
local parse = ls.parser.parse_snippet

local snippets = {
	parse(
		{ trig = "header", dscr = "Quarto YAML header" },
		[=[
---
title: "${1:$TM_FILENAME_BASE}"
author: "${2:Your Name}"
date: today
format: ${3:html}
---

$0
]=]
	),
	parse(
		{ trig = "rchunk", dscr = "R code chunk" },
		[=[
```{r}
$0
```
]=]
	),
	parse(
		{ trig = "pychunk", dscr = "Python code chunk" },
		[=[
```{python}
$0
```
]=]
	),
	parse(
		{ trig = "rchunko", dscr = "R code chunk with options" },
		[=[
```{r}
#| label: fig-${1:name}
#| fig-cap: "${2:caption}"
#| echo: ${3:false}
$0
```
]=]
	),
	parse(
		{ trig = "pychunko", dscr = "Python code chunk with options" },
		[=[
```{python}
#| label: fig-${1:name}
#| fig-cap: "${2:caption}"
#| echo: ${3:false}
$0
```
]=]
	),
	parse(
		{ trig = "callout", dscr = "Quarto callout block" },
		[=[
::: {.callout-${1|note,warning,important,tip,caution|}}
$0
:::
]=]
	),
	parse({ trig = "fig", dscr = "Figure with cross-ref label" }, [=[![${1:caption}](${2:path}){#fig-${3:id}}$0]=]),
	parse({ trig = "cite", dscr = "Citation" }, [=[[@${1:key}]$0]=]),
	parse(
		{ trig = "tabset", dscr = "Panel tabset" },
		[=[
::: {.panel-tabset}
## ${1:Tab 1}
$2

## ${3:Tab 2}
$0
:::
]=]
	),
	parse({ trig = "rinline", dscr = "Inline R code" }, [=[`r ${1:expr}`$0]=]),
}

vim.list_extend(snippets, require("_.snippets.markdown"))
vim.list_extend(snippets, require("_.snippets.markdown_math"))

return snippets
