hl.window_rule({
  name = "fix-xwayland-drags",
  match = {
    class = "^$",
    title = "^$",
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false,
  },

  no_focus = true,
})

hl.window_rule({
  name = "intellij-xwayland-fix",
  match = {
    class = "^(jetbrains-.*)"
  },

  no_initial_focus = true
})

hl.window_rule({
  name = "xwayland-blur-fix",
  match = {
    xwayland = true
  },

  no_blur = true
})

for i = 1, 5 do
  hl.workspace_rule({
    workspace = i,
    monitor = "DP-1",
    default = true
  })
end

for i = 6, 10 do
  hl.workspace_rule({
    workspace = i,
    monitor = "HDMI-A-2",
    default = true
  })
end
