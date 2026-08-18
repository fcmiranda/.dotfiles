-- Windows 11 Fluent Style

hl.config({ animations = { enabled = true } })

hl.curve("fluent", { type = "bezier", points = { { 0.0, 0.0 }, { 0.0, 1.0 } } })
hl.curve("fluentOut", { type = "bezier", points = { { 1.0, 0.0 }, { 1.0, 1.0 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "fluent", style = "popin 95%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "fluentOut", style = "popin 95%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "fluent" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "fluent", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "fluent" })
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "fluent" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "fluent", style = "slidefade 10%" })
