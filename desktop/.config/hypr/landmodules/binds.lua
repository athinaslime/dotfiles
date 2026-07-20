local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("vicinae toggle"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("vicinae vicinae://launch/clipboard/history?toggle=true"))

hl.bind("CTRL + mouse:275", hl.dsp.exec_cmd("playerctl next"))
hl.bind("CTRL + mouse:276", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("CTRL + mouse:274", hl.dsp.exec_cmd("playerctl play-pause"))

local screenshotScript = os.getenv("HOME") .. "/.scripts/screenshot.sh"

local screenshotBinds = {
  { "R", "--region"  },
  { "M", "--monitor" },
  { "F", "--full"    },
  { "W", "--window"  },
  { "D", "--device"  },
  { "Z", "--devmon"  },
}

for _, bind in ipairs(screenshotBinds) do
  local key, flag = bind[1], bind[2]
  hl.bind(mainMod .. "+SHIFT+" .. key, hl.dsp.exec_cmd(screenshotScript .. " " .. flag))
end

local ccAudioControlScript = os.getenv("HOME") .. "/.scripts/cc-audio-control.sh"

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ccAudioControlScript .. " --up"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ccAudioControlScript .. " --down"))

for i = 1, 10 do
  local key = i % 10
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({workspace = i}))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({workspace = i}))
end

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
