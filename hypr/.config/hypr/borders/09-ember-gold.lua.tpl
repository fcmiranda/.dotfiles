-- Ember Gold (Yellow + Orange + Red)
local active_border_color = { colors = { "rgba({{ yellow_strip }}ee)", "rgba({{ orange_strip }}ee)", "rgba({{ red_strip }}ee)" }, angle = 45 }
local inactive_border_color = "rgba(595959aa)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },
  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
})
