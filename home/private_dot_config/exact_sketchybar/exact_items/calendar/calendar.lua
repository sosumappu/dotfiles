-- Padding item required because of bracket
SBAR.add("item", { position = "right", width = PADDINGS + 6 })

local cal_date = SBAR.add("item", {
  position = "right",
  icon = {
    padding_left = 15,
    string = ICONS.calendar,
    color = COLORS.text,
  },
  background = { color = COLORS.mantle },
  label = {
    padding_right = 15,
    color = COLORS.text,
    font = {
      size = 13.0,
    },
  },
})

-- Double border for calendar using a single item bracket
local cal_bracket = SBAR.add("bracket", { cal_date.name }, {
  update_freq = 1,
})

-- Padding item required because of bracket
-- SBAR.add("item", { position = "right", width = PADDINGS })

cal_bracket:subscribe({ "forced", "routine", "system_woke" }, function(env)
  cal_date:set({ label = { string = os.date("%a %b %d %H:%M") } })
end)

local function click_event()
  SBAR.exec("open -a Calendar")
end

cal_date:subscribe("mouse.clicked", click_event)
