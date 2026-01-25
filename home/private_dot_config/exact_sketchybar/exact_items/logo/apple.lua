-- Padding item required because of bracket
SBAR.add("item", { width = 5 })

preset_conf = PRESET_OPTIONS[PRESET]

local apple = SBAR.add("item", {
  icon = {
    font = { size = 22.0 },
    string = ICONS.apple,
    color = COLORS.text,
    padding_right = 15,
    padding_left = 15,
  },
  label = { drawing = false },
  padding_left = 1,
  padding_right = 15,
  background = { color = COLORS.mantle },
  click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0",
})
