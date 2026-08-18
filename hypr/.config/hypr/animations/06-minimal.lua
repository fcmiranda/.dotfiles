-- Minimal & Instant Style

hl.config({ animations = { enabled = true } })

hl.curve("linear", { type = "bezier", points = { { 0.0, 0.0 }, { 1.0, 1.0 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 1, bezier = "linear", style = "popin" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, bezier = "linear", style = "popin" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1, bezier = "linear" })
hl.animation({ leaf = "layers", enabled = true, speed = 1, bezier = "linear" })
hl.animation({ leaf = "fade", enabled = true, speed = 1, bezier = "linear" })
hl.animation({ leaf = "border", enabled = false })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1, bezier = "linear", style = "fade" })
