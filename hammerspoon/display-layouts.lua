-- Profiles stay in Hammerspoon's local settings, including private window titles.
local M = {}
local settingsKey = "displayLayouts.v1"
local profiles = hs.settings.get(settingsKey) or {}
M.windows = hs.window.filter.new():setDefaultFilter({})

local function signature(screens)
  local ids = hs.fnutils.imap(screens, function(s) return s.uuid end)
  table.sort(ids)
  return table.concat(ids, ":")
end

local function screens()
  return hs.fnutils.imap(hs.screen.allScreens(), function(s)
    return { uuid = s:getUUID(), name = s:name(), frame = s:fullFrame().table }
  end)
end

function M.signature()
  return signature(screens())
end

function M.hasProfile()
  return profiles[M.signature()] ~= nil
end

local function desktops(uuid)
  return hs.fnutils.filter(hs.spaces.spacesForScreen(uuid) or {}, function(id)
    return hs.spaces.spaceType(id) == "user"
  end)
end

local function notify(message)
  print("Display layouts: " .. message)
  hs.alert.show(message)
end

function M.save(name)
  if not hs.spaces.screensHaveSeparateSpaces() then
    notify("Enable Displays have separate Spaces before saving a layout")
    return false
  end
  local snapshot = { name = name or "Saved layout", screens = screens(), spaces = {},
    activeSpaces = hs.spaces.activeSpaces(), windows = {} }
  for _, screen in ipairs(snapshot.screens) do
    snapshot.spaces[screen.uuid] = desktops(screen.uuid)
  end
  for _, window in ipairs(M.windows:getWindows()) do
    local spaces = hs.spaces.windowSpaces(window) or {}
    if window:isStandard() and not window:isFullScreen() and #spaces == 1
      and not agentBrowser.isTestingWindow(window)
      and hs.spaces.spaceType(spaces[1]) == "user" then
      table.insert(snapshot.windows, { id = window:id(), pid = window:application():pid(),
        bundle = window:application():bundleID(), title = window:title(),
        screen = window:screen():getUUID(), frame = window:frame().table, spaces = spaces })
    end
  end
  if #snapshot.windows == 0 then
    notify("No windows available to save; check Accessibility access")
    return false
  end
  profiles[signature(snapshot.screens)] = snapshot
  hs.settings.set(settingsKey, profiles)
  notify("Saved " .. snapshot.name .. ": " .. #snapshot.windows .. " windows")
  return true
end

-- Reserve exact matches first. A changed title can fall back to the app only
-- when that app had one saved window and has one unmatched current window.
local function matchWindows(saved)
  local available = hs.fnutils.filter(M.windows:getWindows(), function(w)
    return w:isStandard() and not w:isFullScreen() and not agentBrowser.isTestingWindow(w)
  end)
  local result, used = {}, {}
  local predicates = {
    function(s, w) return s.id == w:id() and s.pid == w:application():pid() end,
    function(s, w) return s.title == w:title() end,
    function(s)
      return #hs.fnutils.filter(saved, function(other) return other.bundle == s.bundle end) == 1
    end,
  }
  for _, predicate in ipairs(predicates) do
    for i, item in ipairs(saved) do
      if not result[i] then
        local candidates = hs.fnutils.filter(available, function(w)
          return not used[w:id()] and item.bundle == w:application():bundleID() and predicate(item, w)
        end)
        if #candidates == 1 then
          result[i], used[candidates[1]:id()] = candidates[1], true
        end
      end
    end
  end
  return result
end

local function restore()
  local profile = profiles[M.signature()]
  if not profile then return nil, "No saved layout for these monitors" end
  if not hs.spaces.screensHaveSeparateSpaces() then
    return nil, "Enable Displays have separate Spaces before restoring"
  end

  local targets, failures = {}, {}
  for _, screen in ipairs(profile.screens) do
    local current = desktops(screen.uuid)
    local saved = profile.spaces[screen.uuid]
    -- Create only missing desktops. Repeated restores cannot add duplicates.
    while #current < #saved do
      local ok, err = hs.spaces.addSpaceToScreen(screen.uuid)
      if not ok then return nil, "Cannot create desktop: " .. tostring(err) end
      local updated = desktops(screen.uuid)
      if #updated <= #current then return nil, "Desktop creation did not finish; try Restore again" end
      current = updated
    end
    local used = {}
    for _, id in ipairs(saved) do
      if hs.fnutils.contains(current, id) then targets[id], used[id] = id, true end
    end
    for i, id in ipairs(saved) do
      if not targets[id] then
        local target = not used[current[i]] and current[i]
          or hs.fnutils.find(current, function(candidate) return not used[candidate] end)
        targets[id], used[target] = target, true
      end
    end
  end

  local matches = matchWindows(profile.windows)
  local verification = {}
  local restored = 0
  for i, item in ipairs(profile.windows) do
    local window = matches[i]
    if window then
      local target = targets[item.spaces[1]]
      local oldScreen = hs.fnutils.find(profile.screens, function(s) return s.uuid == item.screen end)
      local newFrame = hs.screen.find(item.screen):fullFrame()
      -- Position first, then request the saved desktop on the target monitor.
      window:setFrame({ x = newFrame.x + item.frame.x - oldScreen.frame.x,
        y = newFrame.y + item.frame.y - oldScreen.frame.y,
        w = item.frame.w, h = item.frame.h }, 0)
      local current = hs.spaces.windowSpaces(window) or {}
      local ok, err = true, nil
      if not hs.fnutils.contains(current, target) then
        ok, err = hs.spaces.moveWindowToSpace(window, target)
      end
      if ok then
        restored = restored + 1
        table.insert(verification, { window = window, target = target, screen = item.screen })
      else
        table.insert(failures, item.bundle .. ": " .. tostring(err))
      end
    end
  end
  for _, screen in ipairs(profile.screens) do
    local target = targets[profile.activeSpaces[screen.uuid]]
    if target and hs.spaces.activeSpaceOnScreen(screen.uuid) ~= target then
      local ok, err = hs.spaces.gotoSpace(target)
      if not ok then table.insert(failures, "Active desktop: " .. tostring(err)) end
    end
  end
  if #failures > 0 then print(table.concat(failures, "\n")) end
  return { restored = restored, saved = #profile.windows, failures = failures, name = profile.name }, verification
end

function M.restore(quiet)
  local ok, result, detail = pcall(restore)
  if not ok then detail, result = result, nil end
  if not result then
    if not quiet then notify(tostring(detail)) end
    print("Display layouts: " .. tostring(detail))
    return nil, detail
  end
  local setup = M.signature()
  if M.verifyTimer then M.verifyTimer:stop() end
  M.verifyTimer = hs.timer.doAfter(1, function()
    if M.signature() ~= setup then return end
    -- Recent macOS versions can report success without moving a window.
    -- Read the actual assignment after WindowServer processes the request.
    for _, job in ipairs(detail) do
      local spaces = hs.spaces.windowSpaces(job.window) or {}
      if not hs.fnutils.contains(spaces, job.target) then
        table.insert(result.failures, "Window " .. job.window:id() .. ": desktop assignment did not change")
      end
    end
    result.verified = true
    M.lastResult = result
    notify("Positioned " .. result.name .. ": " .. result.restored .. "/" .. result.saved .. " windows"
      .. (#result.failures > 0 and "; desktop restore incomplete (see Console)" or ""))
    for _, failure in ipairs(result.failures) do print("Display layouts: " .. failure) end
  end)
  return result
end

M.menu = hs.menubar.new():setTitle("Layouts"):setMenu(function()
  local current = profiles[M.signature()]
  return {
    { title = current and ("Current profile: " .. current.name) or "No saved profile for these monitors", disabled = true },
    { title = "Restore saved layout", disabled = not current, fn = function() M.restore() end },
    { title = "Save current layout…", fn = function()
      local button, name = hs.dialog.textPrompt("Save display layout",
        "Save windows and desktops for the connected monitors.", current and current.name or "Home", "Save", "Cancel")
      if button == "Save" and name ~= "" then M.save(name) end
    end },
  }
end)

return M
