local fnutils = {
  filter = function(t, f) local o = {} for _, v in ipairs(t) do if f(v) then o[#o + 1] = v end end return o end,
  imap = function(t, f) local o = {} for i, v in ipairs(t) do o[i] = f(v) end return o end,
  find = function(t, f) for _, v in ipairs(t) do if f(v) then return v end end end,
  contains = function(t, x) for _, v in ipairs(t) do if v == x then return true end end return false end,
}

local function sameFrame(a, b)
  return a ~= nil and a.x == b.x and a.y == b.y and a.w == b.w and a.h == b.h
end

local function fakeWindow(id, bundle)
  local window = { frames = {} }
  function window.id() return id end
  function window.title() return bundle .. id end
  function window.isStandard() return true end
  function window.isFullScreen() return false end
  function window.application()
    return { pid = function() return 1 end, bundleID = function() return bundle end }
  end
  function window.setFrame(_, frame) window.frames[#window.frames + 1] = frame end
  return window
end

local profile = { name = "Home", screens = {
    { uuid = "A", frame = { x = 0, y = 0, w = 100, h = 100 } },
    { uuid = "B", frame = { x = 100, y = 0, w = 100, h = 100 } } },
  spaces = { A = { 1, 679, 3 }, B = { 10 } }, activeSpaces = { A = 679, B = 10 },
  windows = {
    { id = 1, pid = 1, bundle = "editor", title = "editor1", screen = "A", spaces = { 679 },
      frame = { x = 10, y = 10, w = 50, h = 50 } },
    { id = 2, pid = 1, bundle = "chat", title = "chat2", screen = "A", spaces = { 3 },
      frame = { x = 20, y = 20, w = 50, h = 50 } },
    { id = 3, pid = 1, bundle = "mail", title = "mail3", screen = "B", spaces = { 10 },
      frame = { x = 120, y = 0, w = 50, h = 50 } } } }
local screenFrames = { A = { x = 0, y = 0, w = 100, h = 100 }, B = { x = 200, y = 0, w = 100, h = 100 } }
local windows = { fakeWindow(1, "editor"), fakeWindow(2, "chat"), fakeWindow(3, "mail") }
local spacesAfterRestore = { [1] = { 1 }, [3] = { 10 } }
local shownAfterRestore = { A = 1, B = 10 }

local calls, brokenCalls, verify = {}, {}, nil
local desktops = {
  list = function(uuid) return ({ A = { 1, 2 }, B = { 10 } })[uuid] end,
  ensureCount = function(wanted) calls.wanted = wanted return { "Cannot create desktops" } end,
  assign = function(assignments) calls.assignments = assignments return {} end,
  activate = function(active) calls.active = active return {} end,
}
local function broken(name)
  return function() brokenCalls[#brokenCalls + 1] = name return true end
end

local hs = {
  fnutils = fnutils,
  settings = { get = function() return { ["A:B"] = profile } end, set = function() end },
  window = { filter = { new = function()
    return { setDefaultFilter = function(self) return self end, getWindows = function() return windows end }
  end } },
  screen = {
    allScreens = function()
      return fnutils.imap({ "A", "B" }, function(uuid)
        return { getUUID = function() return uuid end, name = function() return uuid end,
          fullFrame = function() return { table = screenFrames[uuid] } end }
      end)
    end,
    find = function(uuid) return { fullFrame = function() return screenFrames[uuid] end } end,
  },
  spaces = {
    screensHaveSeparateSpaces = function() return true end,
    windowSpaces = function(window) return spacesAfterRestore[window:id()] or {} end,
    activeSpaceOnScreen = function(uuid) return shownAfterRestore[uuid] end,
    moveWindowToSpace = broken("moveWindowToSpace"),
    gotoSpace = broken("gotoSpace"),
    addSpaceToScreen = broken("addSpaceToScreen"),
  },
  timer = { doAfter = function(_, fn) verify = fn return { stop = function() end } end },
  alert = { show = function() end },
  menubar = { new = function()
    local menu = {}
    function menu.setTitle() return menu end
    function menu.setMenu() return menu end
    return menu
  end },
}

local env = setmetatable({ hs = hs, print = function() end, dofile = function(path)
  assert(path:match("/desktops%.lua$"), "display-layouts.lua must load desktops.lua from its own folder")
  return desktops
end }, { __index = _G })
local layouts = assert(loadfile("hammerspoon/display-layouts.lua", "t", env))()
local result = layouts.restore(true)

assert(#brokenCalls == 0,
  "Restore must not call hs.spaces desktop writes, which do nothing or fail on macOS 27: "
  .. table.concat(brokenCalls, ", "))
assert(calls.wanted and calls.wanted.A == 3 and calls.wanted.B == 1,
  "Restore must ask for as many desktops on each display as the profile saved")
assert(result and result.restored == 3
  and sameFrame(windows[1].frames[1], { x = 10, y = 10, w = 50, h = 50 })
  and sameFrame(windows[2].frames[1], { x = 20, y = 20, w = 50, h = 50 })
  and sameFrame(windows[3].frames[1], { x = 220, y = 0, w = 50, h = 50 }),
  "A failed desktop creation must not stop windows from returning to their saved frames on their saved displays")
assert(#calls.assignments == 2
  and calls.assignments[1].window == windows[1] and calls.assignments[1].space == 2
  and calls.assignments[2].window == windows[3] and calls.assignments[2].space == 10,
  "Drifted desktop IDs must map by position, and a window whose desktop has no match must not be moved")
assert(calls.active.A == 2 and calls.active.B == 10,
  "Each display must switch to its saved active desktop through the mapped ID")
assert(#result.failures == 2,
  "Restore must report both the failed creation and the window it could not put on a desktop")

verify()
local reported = table.concat(result.failures, "\n")
assert(result.verified and #result.failures == 4
  and reported:find("Window 1:", 1, true) and reported:find("Display A:", 1, true),
  "The check after restore must report the window and the display that missed their desktops, and nothing else")
print("Display restore checks passed")
