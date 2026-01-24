-- Padding item required because of bracket
SBAR.add("item", { width = 5 })

local apple = SBAR.add("item", {
  icon = {
    font = { size = 22.0 },
    string = ICONS.apple,
    color = COLORS.text,
    padding_right = 8,
    padding_left = 8,
  },
  label = { drawing = false },
  padding_left = PADDINGS,
  padding_right = PADDINGS,
  padding_top = PADDINGS,
  padding_bottom = PADDINGS,
  background = { color = COLORS.red },
  click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0",
})
