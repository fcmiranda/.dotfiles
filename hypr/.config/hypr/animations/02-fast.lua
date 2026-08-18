-- Fast & Snappy Style

hl.config({ animations = { enabled = true } })

hl.curve("ease", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1.0 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.13, 0.99 }, { 0.29, 1.05 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "overshot", style = "gnomed" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "ease", style = "slide bottom" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2, bezier = "overshot", style = "slide" })
hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "ease", style = "gnomed" })
hl.animation({ leaf = "fade", enabled = true, speed = 1, bezier = "ease" })
hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "liner", style = "loop" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "overshot", style = "slide" })
