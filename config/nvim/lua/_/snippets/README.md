# Snippets setup

This directory contains the custom LuaSnip snippets used by the Neovim configuration. Markdown owns the math-snippet surface: LaTeX-style math macros are available only from Markdown buffers and only while the cursor is inside a Markdown math zone, except for the snippets that create a math zone.

## Goals

- Keep Markdown math snippets useful for notes without loading a full LaTeX document-authoring snippet set.
- Make `mk` and `dm` create Markdown-native `$...$` and `$$...$$` zones from normal prose.
- Gate math-macro snippets consistently for autosnippet expansion and completion-menu display.
- Detect math zones without requiring a `latex` tree-sitter parser or a `markup.math` capture.
- Avoid letting `$` in inline code, fenced code blocks, shell snippets, environment variables, or prices leak into later math-zone detection.

## Files

| File | Purpose |
| --- | --- |
| `init.lua` | Registers snippet modules by filetype. Markdown is registered; `tex` is intentionally not registered. |
| `markdown.lua` | Owns normal Markdown snippets and appends the dedicated Markdown math snippet list. |
| `markdown_math.lua` | Owns all Markdown math-zone creators and math-macro snippets. It does not require `tex.lua`. |
| `mathzone.lua` | Math-context detector used by snippet conditions. Its Markdown path is regex-based and skips inline code spans and fenced code blocks. |
| `mathzone_manual_test.lua` | Unit-style manual smoke test for tricky math-zone cases. |
| `tex.lua` | Legacy LaTeX snippet source kept unused. It is not registered for any filetype. |
| `README.md` | This document. |

Related files outside this directory:

| File | Purpose |
| --- | --- |
| `config/nvim/plugin/autopairs.lua` | Excludes Markdown from the `<`/`>` autopair rule so typing `<->` can expand to `\leftrightarrow`. |
| `config/nvim/plugin/markdown.lua` | Configures Markdown plugins. LaTeX preview rendering is not enabled here. |
| `config/nvim/plugin/treesitter.lua` | Does not install `latex` for snippets; math-zone detection does not depend on tree-sitter injections. |

## Markdown math snippets

`mk` and `dm` are intentionally ungated because they create math zones. Every other snippet in this section is gated by `mathzone.lua`, so it expands and appears in completion only inside `$...$`, `$$...$$`, `\(...\)`, or `\[...\]` in a Markdown buffer.

### Math-zone creators

| Trigger | Expansion | Before/after typing example |
| --- | --- | --- |
| `mk` | `$<1>$<space?><2>` | Outside math, type `mk`, then `x+1`, jump: `The value is $x+1$ <2>`. The spacing function inserts a space after the closing `$` unless the next text starts with punctuation, `-`, or a space. |
| `dm` | `$$` newline `<1>` newline `$$` newline `<0>` | On an empty Markdown line, type `dm`: `$$` / `<1>` / `$$` with the final cursor on the following line. |

### Fractions and scripts

| Trigger | Expansion | Before/after typing example |
| --- | --- | --- |
| `//` | `\frac{<1>}{<2>}<0>` | Inside `$...$`, type `//`: `$\frac{a}{b}$`. Outside math, `//` stays literal. |
| `/` | `\frac{<selection>}{<1>}<0>` | Inside math, select `a+b` and expand `/`: `$\frac{a+b}{n}$`. Outside math, the snippet is unavailable. |
| `__` | `_{<1>}<0>` | Inside math, type `x__i`: `$x_{i}$`. Outside math, `__` stays literal. |
| `sr` | `^2` | Inside math, type `xsr`: `$x^2$`. |
| `cb` | `^3` | Inside math, type `xcb`: `$x^3$`. |
| `td` | `^{<1>}<0>` | Inside math, type `xtd`: `$x^{n}$`. |
| `rd` | `^{(<1>)}<0>` | Inside math, type `xrd`: `$x^{(n+1)}$`. |
| `sq` | `\sqrt{<selection-or-1>} <0>` | Inside math, type `sq` then `x`: `$\sqrt{x} $`. |
| `[A-Za-z][0-9]` | `<letter>_<digit>` | Inside math, type `x1`: `$x_1$`. Outside math, `x1` stays literal. |
| `[A-Za-z]_[0-9][0-9]` | `<letter>_{<two-digits>}` | Inside math, type `x_12`: `$x_{12}$`. |

### Relations, arrows, and quantifiers

| Trigger | Expansion | Before/after typing example |
| --- | --- | --- |
| `->` | `\to ` | Inside math, type `A->B`: `$A\to B$`. |
| `<->` | `\leftrightarrow` | Inside math, type `A<->B`: `$A\leftrightarrowB$`; Markdown autopairs is disabled for `<` so no extra `>` is inserted. |
| `!>` | `\mapsto ` | Inside math, type `x!>x^2`: `$x\mapsto x^2$`. |
| `<=` | `\le ` | Inside math, type `x<=y`: `$x\le y$`. |
| `>=` | `\ge ` | Inside math, type `x>=y`: `$x\ge y$`. |
| `==` | `&= <1> \\` | Inside display math, type `==`: `&= rhs \\`. Outside math, `==` stays literal. |
| `!=` | `\neq ` | Inside math, type `x!=y`: `$x\neq y$`. |
| `EE` | `\exists ` | Inside math, type `EEx`: `$\exists x$`. |
| `AA` | `\forall ` | Inside math, type `AAx`: `$\forall x$`. |

### Operators and common symbols

| Trigger | Expansion | Before/after typing example |
| --- | --- | --- |
| `xx` | `\times ` | Inside math, type `a xxb`: `$a \times b$`. |
| `**` | `\cdot ` | Inside math, type `a**b`: `$a\cdot b$`. |
| `RR` | `\R` | Inside math, type `x inn RR`: `$x \in \R$`. |
| `NN` | `\N` | Inside math, type `n inn NN`: `$n \in \N$`. |
| `QQ` | `\Q` | Inside math, type `q inn QQ`: `$q \in \Q$`. |
| `ZZ` | `\Z` | Inside math, type `z inn ZZ`: `$z \in \Z$`. |
| `OO` | `\O` | Inside math, type `OO`: `$\O$`. |
| `UU` | `\cup ` | Inside math, type `A UUB`: `$A \cup B$`. |
| `Nn` | `\cap ` | Inside math, type `A NnB`: `$A \cap B$`. |
| `cc` | `\subset ` | Inside math, type `A ccB`: `$A \subset B$`. |
| `inn` | `\in ` | Inside math, type `x inn A`: `$x \in A$`. |
| `notin` | `\not\in ` | Inside math, type `x notin A`: `$x \not\in A$`. |
| `lll` | `\ell` | Inside math, type `lll`: `$\ell$`. |
| `nabl` | `\nabla ` | Inside math, type `nabl f`: `$\nabla f$`. |
| `ooo` | `\infty` | Inside math, type `ooo`: `$\infty$`. |

### Delimiters, accents, and text

| Trigger | Expansion | Before/after typing example |
| --- | --- | --- |
| `case` | `\begin{cases}` newline `<1>` newline `\end{cases}` | Inside display math, type `case`: `\begin{cases} ... \end{cases}`. |
| `bar` | `\overline{<1>}<0>` | Inside math, type `bar` then `x`: `$\overline{x}$`. |
| `[A-Za-z]bar` | `\overline{<letter>}` | Inside math, type `xbar`: `$\overline{x}$`. |
| `hat` | `\hat{<1>}<0>` | Inside math, type `hat` then `x`: `$\hat{x}$`. |
| `[A-Za-z]hat` | `\hat{<letter>}` | Inside math, type `xhat`: `$\hat{x}$`. |
| `norm` | `\|<1>\|<0>` | Inside math, type `norm` then `x`: `$\|x\|$`. |
| `conj` | `\overline{<1>}<0>` | Inside math, type `conj` then `z`: `$\overline{z}$`. |
| `invs` | `^{-1}` | Inside math, type `Ainvs`: `$A^{-1}$`. |
| `compl` | `^{c}` | Inside math, type `Acompl`: `$A^{c}$`. |
| `ceil` | `\left\lceil <1> \right\rceil <0>` | Inside math, type `ceil` then `x`: `$\left\lceil x \right\rceil $`. |
| `floor` | `\left\lfloor <1> \right\rfloor<0>` | Inside math, type `floor` then `x`: `$\left\lfloor x \right\rfloor$`. |
| `mcal` | `\mathcal{<1>}<0>` | Inside math, type `mcal` then `F`: `$\mathcal{F}$`. |
| `tt` | `\text{<1>}<0>` | Inside math, type `tt` then `where`: `$\text{where}$`. |

### Large operators and calculus

| Trigger | Expansion | Before/after typing example |
| --- | --- | --- |
| `dint` | `\int_{<1:-\infty>}^{<2:\infty>} <3> <0>` | Inside math, type `dint`: `$\int_{0}^{1} f(x) dx$`. |
| `sum` | `\sum_{n=<1:1>}^{<2:\infty>} <3:a_n z^n>` | Inside math, type `sum`: `$\sum_{n=1}^{\infty} a_n z^n$`. |
| `prod` | `\prod_{<1:n=<2:1>>}^{<3:\infty>} <4> <0>` | Inside math, type `prod`: `$\prod_{n=1}^{\infty} a_n$`. |
| `lim` | `\lim_{<1:n> \to <2:\infty>} ` | Inside math, type `lim`: `$\lim_{n \to \infty} $`. |
| `limsup` | `\limsup_{<1:n> \to <2:\infty>} ` | Inside math, type `limsup`: `$\limsup_{n \to \infty} $`. |
| `part` | `\frac{\partial <1:V>}{\partial <2:x>} <0>` | Inside math, type `part`: `$\frac{\partial V}{\partial x}$`. |

### Function-name backslashing

| Trigger | Expansion | Before/after typing example |
| --- | --- | --- |
| `sin`, `cos`, `cot`, `csc`, `ln`, `log`, `exp` | Prefixes the function name with `\` | Inside math, type `sin x`: `$\sin x$`; outside math, `sin` stays literal. |
| `arcsin`, `arccos`, `arctan`, `arccot`, `arccsc`, `arcsec` | Prefixes the inverse function name with `\` | Inside math, type `arcsin x`: `$\arcsin x$`. |
| `star`, `perp`, `pi`, `zeta`, `int` | Prefixes the symbol name with `\` | Inside math, type `pi`: `$\pi$`; type `int`: `$\int$`. |

## Math-zone detection

`mathzone.lua` exposes `math_mode(line_to_cursor)` as the snippet-facing API. For Markdown buffers it uses bounded regex-style scanning instead of tree-sitter captures: fenced code block boundaries reset block-math delimiter state, fenced code contents are ignored, inline code spans are masked before delimiter scanning, `$$` / `\[...\]` / `\(...\)` are counted from at most the last 500 lines of the current non-fenced region, and single-dollar inline math is recognized only as a matched pair on the current line. The Markdown path does not require a `latex` tree-sitter parser.

Run the manual smoke test after changing the detector:

```sh
nvim --headless --clean -u NONE +'set rtp^=./config/nvim' +'luafile config/nvim/lua/_/snippets/mathzone_manual_test.lua' +qa
```

The test covers dollars in inline code, dollars in fenced code blocks, two separate `$$` blocks, unmatched `$HOME` before real math, prices before real math, and `\[...\]` / `\(...\)` delimiters.

## Troubleshooting

### Math snippets expand in prose

Check that the buffer filetype is Markdown and that the trigger is not `mk` or `dm`. Math macros should have both `condition` and `show_condition` through `markdown_math.lua`; autosnippets use `condition`, and both paths call `mathzone.math_mode()` through a safe wrapper.

### Math snippets do not expand inside `$...$`

Make sure the cursor is between a matched pair of dollar delimiters on the same line, or inside a currently open `$$`, `\[`, or `\(` block. Inline code spans and fenced code blocks intentionally suppress detection.

### Typing `<->` inserts an extra `>`

Markdown must stay in the `<`/`>` autopairs exclusion list in `config/nvim/plugin/autopairs.lua`.

### LaTeX preview rendering is missing

This setup does not enable render-markdown.nvim LaTeX preview rendering. Snippets do not need the `latex` tree-sitter parser or Markdown-to-LaTeX injections; enable those separately only if preview rendering is intentionally wanted.
