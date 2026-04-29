local ram = SBAR.add("graph", "widgets.ram", 42, {
  position = "left",
  graph = { color = COLORS.subtext1 },
  background = {
    height = 22,
    color = { alpha = 0 },
    border_color = { alpha = 0 },
    drawing = true,
  },
  icon = { string = ICONS.ram, color = COLORS.subtext1 },
  label = {
    string = "RAM ??%",
    font = { size = 9.0 },
    align = "right",
    padding_right = 0,
    width = 0,
    y_offset = 4,
  },
  update_freq = 3,
  updates = "when_shown",
  padding_right = PADDINGS,
})

ram:subscribe({ "system_stats" }, function(env)
  GRAPH_UTILS.update_graph(env.RAM_USAGE, ram, "RAM")
end)
