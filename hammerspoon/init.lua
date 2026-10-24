require("hs.ipc")

-- The installer links init.lua, so load the module beside its actual file.
local configFile = hs.fs.symlinkAttributes(hs.configdir .. "/init.lua", "target")
  or hs.configdir .. "/init.lua"
if configFile:sub(1, 1) ~= "/" then configFile = hs.configdir .. "/" .. configFile end
agentBrowser = dofile(configFile:match("^(.*)/") .. "/agent-browser.lua")
displayLayouts = dofile(configFile:match("^(.*)/") .. "/display-layouts.lua")

local previousCount = #hs.screen.allScreens()
local previousSetup = displayLayouts.signature()
local setupChanged = false
local modifiers = { "alt", "shift" }

-- Keep watchers and timers alive until Hammerspoon reloads this config.
amethystMonitor = {}

amethystMonitor.reflow = hs.timer.delayed.new(0.5, function()
  if #hs.screen.allScreens() == 1 and hs.application.get("Amethyst") then
    hs.eventtap.keyStroke(modifiers, "z", 0)
    print("Amethyst: reapplied fullscreen layout")
  end
end)

amethystMonitor.settle = hs.timer.delayed.new(5, function()
  local count = #hs.screen.allScreens()
  local becameSingle = previousCount > 1 and count == 1
  local setup = displayLayouts.signature()
  local changed = setupChanged or previousSetup ~= setup
  setupChanged = false
  previousCount = count
  previousSetup = setup

  if changed and displayLayouts.hasProfile() then
    displayLayouts.restore(true)
  elseif becameSingle and hs.application.get("Amethyst") then
    hs.eventtap.keyStroke(modifiers, "d", 0)
    amethystMonitor.reflow:start()
  end
end)

local function screenChanged()
  -- A quick unplug/replug can return to the same setup before settling.
  setupChanged = setupChanged or displayLayouts.signature() ~= previousSetup
  amethystMonitor.reflow:stop()
  amethystMonitor.settle:start()
end

amethystMonitor.screens = hs.screen.watcher.new(screenChanged):start()
amethystMonitor.wake = hs.caffeinate.watcher.new(function(event)
  if event == hs.caffeinate.watcher.systemDidWake
    or event == hs.caffeinate.watcher.screensDidWake then
    setupChanged = true
    screenChanged()
  end
end):start()

hs.autoLaunch(true)
print("Amethyst monitor watcher loaded; displays: " .. previousCount)
