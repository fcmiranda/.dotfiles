-- Smooth & Elegant (macOS-like)

hl.config({ animations = { enabled = true } })

hl.curve("smooth", { type = "bezier", points = { { 0.4, 0.0 }, { 0.2, 1.0 } } })
hl.curve("easeInOut", { type = "bezier", points = { { 0.42, 0.0 }, { 0.58, 1.0 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "smooth", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "smooth", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "smooth" })
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "smooth", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "smooth" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "easeInOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "smooth", style = "slidefade 20%" })
