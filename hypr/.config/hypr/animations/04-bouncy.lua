-- Bouncy & Playful Style

hl.config({ animations = { enabled = true } })

hl.curve("bounce", { type = "bezier", points = { { 0.68, -0.55 }, { 0.265, 1.55 } } })
hl.curve("easeOut", { type = "bezier", points = { { 0.0, 0.0 }, { 0.2, 1.0 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "bounce", style = "popin" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "easeOut", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "bounce" })
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "bounce", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "easeOut" })
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "easeOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "bounce", style = "slide" })
