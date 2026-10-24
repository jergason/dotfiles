-- Exercise desktop selection and classification without changing macOS state.
local function session(options)
  local state = { spaces = options.spaces or { 1, 2 }, active = 1, created = 0,
    jobs = {}, timers = {}, alerts = {}, createdWatchers = {}, destroyedWatchers = {} }
  local screen = {
    getUUID = function() return "screen" end,
    frame = function() return { x = 0, y = 33 } end,
  }
  local function watcher(callback)
    return { callback = callback, start = function(self) return self end,
      stop = function(self) self.stopped = true end }
  end
  local function app(pid, bundle)
    return { pid = function() return pid end, bundleID = function() return bundle end,
      newWatcher = function(_, callback)
        local w = watcher(callback)
        state.createdWatchers[pid] = w
        return w
      end,
      allWindows = function()
        local windows = {}
        for _, w in ipairs(state.windows) do
          if w:application():pid() == pid then windows[#windows + 1] = w end
        end
        return windows
      end,
    }
  end
  local function window(pid, bundle, space, id)
    id = id or pid
    return { application = function() return app(pid, bundle) end,
      id = function() return id end, isStandard = function() return true end, space = space,
      moveToScreen = function(self, target) self.targetScreen = target end,
      newWatcher = function(_, callback)
        local w = watcher(callback)
        state.destroyedWatchers[id] = w
        return w
      end,
    }
  end
  state.window = window
  state.personal = window(1, "com.google.Chrome", 1)
  state.testing = window(2, "com.google.Chrome", 2)
  state.windows = options.windows and options.windows(state) or { state.personal }
  local function find(items, predicate)
    for _, item in ipairs(items) do if predicate(item) then return item end end
  end
  local filter = {
    setDefaultFilter = function(self) return self end,
    getWindows = function() return state.windows end,
  }
  local env = setmetatable({ hs = {
    accessibilityState = function() return true end,
    execute = function(command)
      return command:find("-p 2 ", 1, true)
        and "Chrome --user-data-dir=" .. os.getenv("HOME") .. "/.cache/chrome-devtools-mcp/chrome-profile"
        or "Chrome --user-data-dir=personal"
    end,
    fnutils = {
      find = find,
      contains = function(items, value) return find(items, function(item) return item == value end) ~= nil end,
    },
    screen = { primaryScreen = function() return screen end, find = function() return screen end },
    window = { filter = { new = function() return filter end } },
    uielement = { watcher = { windowCreated = "created", elementDestroyed = "destroyed" } },
    application = { applicationForPID = function(pid) return app(pid, "com.google.Chrome") end, watcher = {
      terminated = "terminated",
      new = function(callback)
        state.onApp = callback
        return { start = function(self) return self end }
      end,
    } },
    task = { new = function(_, callback, args)
      local job = { callback = callback, args = args, running = false }
      function job:start() self.running = true; return self end
      function job:isRunning() return self.running end
      function job:terminate() self.running = false end
      state.jobs[#state.jobs + 1] = job
      return job
    end },
    timer = { doAfter = function(_, callback)
      state.timers[#state.timers + 1] = callback
      return { stop = function() end }
    end },
    alert = { show = function(message) state.alerts[#state.alerts + 1] = message end },
    inspect = function() return "spaces" end,
    spaces = {
      screensHaveSeparateSpaces = function() return true end,
      spacesForScreen = function() return state.spaces end,
      spaceType = function() return "user" end,
      windowSpaces = function(w) return { w.space } end,
      activeSpaceOnScreen = function() return state.active end,
      gotoSpace = function(id)
        state.requested = id
        state.active = id
        return true
      end,
      addSpaceToScreen = function()
        state.created = state.created + 1
        local copy = {}
        for i, id in ipairs(state.spaces) do copy[i] = id end
        copy[#copy + 1] = 3
        state.spaces = copy
        return true
      end,
    },
  } }, { __index = _G })
  env.print = function() end
  state.module = assert(loadfile("hammerspoon/agent-browser.lua", "t", env))()
  state.onWindow = function(w)
    local registered = state.createdWatchers[w:application():pid()]
    if registered then registered.callback(w) end
  end
  return state
end

local empty = session({})
assert(empty.module.prepare(100))
assert(empty.module.launches[100].space == 2 and empty.created == 0, "Reuse an empty desktop")
assert(not empty.module.isTestingWindow(empty.personal), "Personal Chrome must not match")
assert(empty.module.isTestingWindow(empty.testing), "The MCP profile must match")

local occupied = session({ spaces = { 1 } })
occupied.module.prepare(100)
assert(occupied.created == 1 and occupied.module.launches[100].space == 3, "Create a desktop when all are occupied")
occupied.module.prepare(101)
assert(occupied.created == 1, "Repeated launches must reuse the testing desktop")

local agentOnly = session({ windows = function(s) return { s.personal, s.testing } end })
agentOnly.module.prepare(100)
assert(agentOnly.module.launches[100].space == 2 and agentOnly.created == 0, "Reuse a desktop containing only testing windows")
agentOnly.personal.space = 2
agentOnly.module.prepare(101)
assert(agentOnly.module.launches[101].space == 1, "Stop using a testing desktop if a personal window moves into it")

local background = session({})
background.module.prepare(100)
background.module.watch(100)
assert(background.requested == nil, "Preparing a browser must not switch desktops")
local first = background.window(100, "com.google.Chrome", 1)
background.onWindow(first)
assert(background.jobs[1].args[1] == "100" and background.jobs[1].args[2] == "2", "Move a testing window to its selected desktop")
assert(background.module.isTestingWindow(first), "Register the actual Chrome process")
first.space = 2
background.jobs[1].callback(0, "", "")
background.timers[1]()
assert(background.module.launches[100].windows[100].phase == "ready")
assert(background.requested == nil and background.active == 1, "Placing Chrome must leave the active desktop unchanged")
background.onWindow(background.personal)
assert(#background.jobs == 1, "Never move personal Chrome windows")

local second = background.window(100, "com.google.Chrome", 1, 101)
background.onWindow(second)
background.jobs[2].callback(0, "", "")
background.timers[2]()
assert(#background.alerts == 1, "Report a move that claimed success but left the window on the wrong desktop")
assert(background.requested == nil, "A failed move must not switch desktops")
local third = background.window(100, "com.google.Chrome", 1, 102)
background.onWindow(third)
background.destroyedWatchers[102].callback()
background.jobs[3].callback(0, "", "")
assert(#background.timers == 2 and not background.jobs[3].running, "Cancel placement when a window closes before the move finishes")
background.onApp(nil, "terminated", first:application())
assert(background.module.launches[100] == nil, "Forget terminated browser processes")

local concurrent = session({})
concurrent.module.prepare(100)
concurrent.module.prepare(200)
concurrent.module.watch(100)
concurrent.module.watch(200)
concurrent.onWindow(concurrent.window(100, "com.google.Chrome", 1))
concurrent.onWindow(concurrent.window(200, "com.google.Chrome", 1))
assert(#concurrent.jobs == 2, "Track independent Chrome processes with the same application name")
print("Agent browser desktop checks passed")
