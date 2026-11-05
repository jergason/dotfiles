-- Profiles stay in Hammerspoon's local settings, including private window titles.
local M = {}
local moduleDir = debug.getinfo(1, "S").source:sub(2):match("^(.*)/")
local desktops = dofile(moduleDir .. "/desktops.lua")
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
    snapshot.spaces[screen.uuid] = desktops.list(screen.uuid)
  end
  for _, window in ipairs(M.windows:getWindows()) do
    local spaces = hs.spaces.windowSpaces(window) or {}
    if window:isStandard() and not window:isFullScreen() and #spaces == 1
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
    return w:isStandard() and not w:isFullScreen()
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

-- macOS can give a desktop a new ID or hand it to another display after a reconnect,
-- so a saved ID that is gone falls back to the desktop in the same position.
local function mapDesktops(saved, current)
  local targets, used = {}, {}
  for _, id in ipairs(saved) do
    if hs.fnutils.contains(current, id) then targets[id], used[id] = id, true end
  end
  for i, id in ipairs(saved) do
    if not targets[id] then
      local target = (current[i] and not used[current[i]]) and current[i]
        or hs.fnutils.find(current, function(candidate) return not used[candidate] end)
      if target then targets[id], used[target] = target, true end
    end
  end
  return targets
end

local function translate(frame, oldScreen, newScreen)
  return { x = newScreen.x + frame.x - oldScreen.x, y = newScreen.y + frame.y - oldScreen.y,
    w = frame.w, h = frame.h }
end

local function append(list, more)
  table.move(more, 1, #more, #list + 1, list)
  return list
end

local function restore()
  local profile = profiles[M.signature()]
  if not profile then return nil, "No saved layout for these monitors" end
  if not hs.spaces.screensHaveSeparateSpaces() then
    return nil, "Enable Displays have separate Spaces before restoring"
  end

  local wanted = {}
  for uuid, saved in pairs(profile.spaces) do wanted[uuid] = #saved end
  local failures = desktops.ensureCount(wanted)

  local targets = {}
  for uuid, saved in pairs(profile.spaces) do
    for savedID, id in pairs(mapDesktops(saved, desktops.list(uuid))) do targets[savedID] = id end
  end

  local matches = matchWindows(profile.windows)
  local placed = {}
  for i, item in ipairs(profile.windows) do
    if matches[i] then placed[#placed + 1] = { item = item, window = matches[i] } end
  end
  for _, p in ipairs(placed) do
    local old = hs.fnutils.find(profile.screens, function(s) return s.uuid == p.item.screen end)
    p.window:setFrame(translate(p.item.frame, old.frame, hs.screen.find(p.item.screen):fullFrame()), 0)
  end

  local assignments = {}
  for _, p in ipairs(placed) do
    local space = targets[p.item.spaces[1]]
    if space then
      assignments[#assignments + 1] = { window = p.window, space = space }
    else
      failures[#failures + 1] = p.item.bundle .. ": saved desktop has no match on this display"
    end
  end
  append(failures, desktops.assign(assignments))

  local active = {}
  for uuid, savedID in pairs(profile.activeSpaces) do active[uuid] = targets[savedID] end
  append(failures, desktops.activate(active))

  local postconditions = hs.fnutils.imap(assignments, function(a)
    return { problem = "Window " .. a.window:id() .. ": desktop assignment did not change",
      holds = function() return hs.fnutils.contains(hs.spaces.windowSpaces(a.window) or {}, a.space) end }
  end)
  for uuid, space in pairs(active) do
    postconditions[#postconditions + 1] = { problem = "Display " .. uuid .. ": active desktop did not change",
      holds = function() return hs.spaces.activeSpaceOnScreen(uuid) == space end }
  end
  return { restored = #placed, saved = #profile.windows, failures = failures, name = profile.name }, postconditions
end

function M.restore(quiet)
  local ok, result, postconditions = pcall(restore)
  if not ok then postconditions, result = result, nil end
  if not result then
    if not quiet then notify(tostring(postconditions)) end
    print("Display layouts: " .. tostring(postconditions))
    return nil, postconditions
  end
  local setup = M.signature()
  if M.verifyTimer then M.verifyTimer:stop() end
  M.verifyTimer = hs.timer.doAfter(1, function()
    if M.signature() ~= setup then return end
    local unmet = hs.fnutils.filter(postconditions, function(check) return not check.holds() end)
    append(result.failures, hs.fnutils.imap(unmet, function(check) return check.problem end))
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
