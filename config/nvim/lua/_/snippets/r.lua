local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node

return {
	s({ trig = ">>", dscr = "Pipe operator", inword = false }, {
		t(" %>% "),
	}),

	s({ trig = "--", dscr = "Assignment operator", inword = false }, {
		t(" <- "),
	}),

	s({ trig = "mut", dscr = "dplyr::mutate" }, {
		t("mutate("),
	}),
}
