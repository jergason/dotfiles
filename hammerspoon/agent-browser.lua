local M = { launches = {}, backgroundLaunch = true }
local moduleDir = debug.getinfo(1, "S").source:sub(2):match("^(.*)/")
local mover = moduleDir .. "/.build/move-window-space"
M.windows = hs.window.filter.new():setDefaultFilter({})

function M.isTestingWindow(window)
  local app = window:application()
  if app:bundleID() ~= "com.google.Chrome" then return false end
  if M.launches[app:pid()] then return true end
  local command = hs.execute("/bin/ps -p " .. app:pid() .. " -o command=", false)
  return command:find("--user-data-dir=" .. os.getenv("HOME") .. "/.cache/chrome-devtools-mcp/", 1, true) ~= nil
end

local function hasPersonalWindows(space)
  return hs.fnutils.find(M.windows:getWindows(), function(window)
    return window:isStandard()
      and hs.fnutils.contains(hs.spaces.windowSpaces(window) or {}, space)
      and not M.isTestingWindow(window)
  end) ~= nil
end

local function cancelPlacement(placement)
  if placement.watcher then placement.watcher:stop() end
  if placement.timer then placement.timer:stop() end
  if placement.task and placement.task:isRunning() then placement.task:terminate() end
end

function M.prepare(pid)
  assert(type(pid) == "number" and pid > 0 and pid % 1 == 0, "Invalid browser PID")
  assert(hs.accessibilityState(), "Hammerspoon needs Accessibility access")
  assert(hs.spaces.screensHaveSeparateSpaces(), "Enable Displays have separate Spaces")
  local screen = hs.screen.primaryScreen()
  local spaces = hs.spaces.spacesForScreen(screen) or {}
  local function usable(id)
    return hs.spaces.spaceType(id) == "user" and not hasPersonalWindows(id)
  end
  local target = M.space and hs.fnutils.contains(spaces, M.space) and usable(M.space) and M.space
    or hs.fnutils.find(spaces, usable)
  if not target then
    local before = spaces
    assert(hs.spaces.addSpaceToScreen(screen))
    spaces = hs.spaces.spacesForScreen(screen) or {}
    target = hs.fnutils.find(spaces, function(id)
      return not hs.fnutils.contains(before, id) and usable(id)
    end)
    assert(target, "Cannot find the new desktop")
  end
  M.space = target
  M.launches[pid] = { pid = pid, space = target, screen = screen:getUUID(), windows = {} }
  M.lastLaunch = M.launches[pid]
  return true
end

local function placeWindow(launch, window)
  if not window:isStandard() then return end
  local id = window:id()
  if launch.windows[id] then return end
  window:moveToScreen(assert(hs.screen.find(launch.screen), "Testing display disconnected"), true, true, 0)
  local placement = { phase = "moving" }
  launch.windows[id] = placement
  placement.watcher = window:newWatcher(function()
    launch.windows[id] = nil
    cancelPlacement(placement)
  end):start({ hs.uielement.watcher.elementDestroyed })
  placement.task = hs.task.new(mover, function(code, _, errors)
    if M.launches[launch.pid] ~= launch or launch.windows[id] ~= placement then return end
    placement.phase = "checking"
    placement.timer = hs.timer.doAfter(0.1, function()
      if M.launches[launch.pid] ~= launch or launch.windows[id] ~= placement then return end
      local actual = hs.spaces.windowSpaces(window) or {}
      placement.phase = code == 0 and hs.fnutils.contains(actual, launch.space) and "ready" or "failed"
      if placement.phase == "failed" then
        hs.alert.show("Cannot place testing Chrome; check Hammerspoon Console")
        print("Agent browser: expected desktop " .. launch.space .. ", got " .. hs.inspect(actual) .. "; " .. errors)
      end
    end)
  end, { tostring(id), tostring(launch.space) })
  assert(placement.task and placement.task:start(), "Cannot start move-window-space; run bin/setup-agent-chrome")
end

function M.watch(pid)
  local launch = assert(M.launches[pid], "Browser launch was not prepared")
  if launch.watcher then return true end
  local app = assert(hs.application.applicationForPID(pid), "Chrome did not register its application")
  launch.watcher = app:newWatcher(function(window) placeWindow(launch, window) end)
    :start({ hs.uielement.watcher.windowCreated })
  for _, window in ipairs(app:allWindows()) do placeWindow(launch, window) end
  return true
end

M.apps = hs.application.watcher.new(function(_, event, app)
  if event == hs.application.watcher.terminated and app then
    local pid = app:pid()
    if not pid then return end
    local launch = M.launches[pid]
    M.launches[pid] = nil
    if launch and launch.watcher then launch.watcher:stop() end
    for _, placement in pairs(launch and launch.windows or {}) do
      cancelPlacement(placement)
    end
  end
end):start()

return M
