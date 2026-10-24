-- Test display events without access to macOS or the user's saved profiles.
local function session()
  local state = { setup = "work", count = 3, restores = 0, keys = {}, profile = true }
  local function watcher(callback)
    return { start = function(self) return self end, callback = callback }
  end
  local layouts = {
    signature = function() return state.setup end,
    hasProfile = function() return state.profile end,
    restore = function() state.restores = state.restores + 1 end,
  }
  local env = setmetatable({
    require = function() end,
    dofile = function(path)
      if path == "/repo/hammerspoon/agent-browser.lua" then return {} end
      assert(path == "/repo/hammerspoon/display-layouts.lua")
      return layouts
    end,
    print = function() end,
    hs = {
      configdir = "/home/.hammerspoon",
      fs = { symlinkAttributes = function() return "/repo/hammerspoon/init.lua" end },
      screen = {
        allScreens = function()
          local screens = {}
          for i = 1, state.count do screens[i] = i end
          return screens
        end,
        watcher = { new = watcher },
      },
      timer = { delayed = { new = function(_, callback)
        local timer = { callback = callback,
          start = function(self) self.running = true end,
          stop = function(self) self.running = false end }
        return timer
      end } },
      caffeinate = { watcher = { new = watcher, systemDidWake = 1, screensDidWake = 2 } },
      application = { get = function() return true end },
      eventtap = { keyStroke = function(_, key) table.insert(state.keys, key) end },
      autoLaunch = function() end,
    },
  }, { __index = _G })
  assert(loadfile("hammerspoon/init.lua", "t", env))()
  function state.change(setup, count, profile)
    state.setup, state.count, state.profile = setup, count, profile
    env.amethystMonitor.screens.callback()
  end
  function state.settle() env.amethystMonitor.settle.callback() end
  function state.wake() env.amethystMonitor.wake.callback(1) end
  function state.reflow() env.amethystMonitor.reflow.callback() end
  return state
end

local quick = session()
quick.change("laptop", 1, false)
quick.change("work", 3, true)
quick.settle()
assert(quick.restores == 1, "A quick unplug/replug must restore the work profile")
quick.settle()
assert(quick.restores == 1, "An unchanged setup must not trigger repeated restores")

local home = session()
home.change("home", 3, false)
home.settle()
assert(home.restores == 0, "Unknown monitors must not use the work profile")

local laptop = session()
laptop.change("laptop", 1, false)
laptop.settle()
laptop.reflow()
assert(table.concat(laptop.keys) == "dz", "An unsaved laptop setup must use Amethyst fullscreen")

local savedLaptop = session()
savedLaptop.change("laptop", 1, true)
savedLaptop.settle()
assert(savedLaptop.restores == 1 and #savedLaptop.keys == 0, "A saved laptop profile takes priority")

local wake = session()
wake.wake()
wake.settle()
assert(wake.restores == 1, "Wake must restore even if monitor IDs stay the same")
print("Display layout event checks passed")
