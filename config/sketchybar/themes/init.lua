-- Load theme from themes directory
local light_theme = LIGHT_THEME or "aquarium_light"
local dark_theme = DARK_THEME or "plain"
local theme_path = ""

-- Query the apple AppleInterfaceStyle to know which colorscheme to use
local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
local appleInterfaceStyle = handle:read("*l")
handle:close()

if appleInterfaceStyle and not appleInterfaceStyle:find("Dark") then
  theme_path = "themes/" .. light_theme
else
  theme_path = "themes/" .. dark_theme
end

local success, colors = pcall(require, theme_path)

-- Fallback to catppuccin_mocha if theme not found
if not success then
  print("Theme '" .. theme_name .. "' not found, falling back to catppuccin_mocha")
  colors = require("themes/catppuccin_mocha")
end

-- Add with_alpha utility function
colors.transparent = 0x00000000
colors.with_alpha = function(color, alpha)
  if alpha > 1.0 or alpha < 0.0 then
    return color
  end
  return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
end

return colors
