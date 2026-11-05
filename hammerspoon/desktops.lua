-- On macOS 27, hs.spaces.moveWindowToSpace reports success without moving, and
-- gotoSpace/addSpaceToScreen look for Mission Control in the Dock. hs.spaces reads still work.
local M = {}
local moduleDir = debug.getinfo(1, "S").source:sub(2):match("^(.*)/")
local helperSource = moduleDir .. "/move-window-space.m"
local helperBinary = moduleDir .. "/.build/move-window-space"
local settleSeconds = 0.3

local function quote(text)
  return "'" .. (text:gsub("'", "'\\''")) .. "'"
end

local function sortedKeys(map)
  local keys = {}
  for key in pairs(map) do keys[#keys + 1] = key end
  table.sort(keys)
  return keys
end

local function blockUntil(predicate, seconds)
  local deadline = hs.timer.secondsSinceEpoch() + seconds
  while not predicate() do
    if hs.timer.secondsSinceEpoch() > deadline then return false end
    hs.timer.usleep(50000)
  end
  return true
end

--- User desktops on a screen, in Mission Control order.
function M.list(uuid)
  return hs.fnutils.filter(hs.spaces.spacesForScreen(uuid) or {}, function(id)
    return hs.spaces.spaceType(id) == "user"
  end)
end

local function ensureHelperBuilt()
  local built = hs.fs.attributes(helperBinary, "modification")
  local source = hs.fs.attributes(helperSource, "modification")
  if built and source and built >= source then return helperBinary end
  hs.fs.mkdir(moduleDir .. "/.build")
  local output, ok = hs.execute(string.format(
    "xcrun clang -fobjc-arc -Wall -Wextra -Werror -framework Cocoa %s -o %s 2>&1",
    quote(helperSource), quote(helperBinary)))
  if not ok then return nil, "Cannot build move-window-space: " .. output end
  return helperBinary
end

--- Put each window on its desktop.
--- assignments: { { window = hs.window, space = spaceID }, ... }
function M.assign(assignments)
  local pending = hs.fnutils.filter(assignments, function(a)
    return not hs.fnutils.contains(hs.spaces.windowSpaces(a.window) or {}, a.space)
  end)
  if #pending == 0 then return {} end
  local binary, err = ensureHelperBuilt()
  if not binary then return { err } end
  local args = hs.fnutils.imap(pending, function(a)
    return string.format("%d %d", a.window:id(), a.space)
  end)
  local output, ok = hs.execute(quote(binary) .. " " .. table.concat(args, " ") .. " 2>&1")
  return ok and {} or { "move-window-space: " .. output }
end

local function child(element, identifier)
  return element and hs.fnutils.find(element:attributeValue("AXChildren") or {}, function(c)
    return c.AXIdentifier == identifier
  end)
end

-- macOS 27 moved the Mission Control tree from the Dock to WindowManager.
local function displayGroups()
  local app = hs.application.applicationsForBundleID("com.apple.WindowManager")[1]
  local root = app and hs.axuielement.applicationElement(app)
  local groups = {}
  for _, group in ipairs(root and root:attributeValue("AXChildren") or {}) do
    if group.AXIdentifier == "mc.display" then groups[group.AXDisplayID] = group end
  end
  return groups
end

local function isOpen() return next(displayGroups()) ~= nil end
local function isClosed() return not isOpen() end

local function open()
  local toggled = isClosed()
  if toggled then hs.spaces.toggleMissionControl() end
  if not blockUntil(isOpen, 2) then
    if toggled then hs.spaces.toggleMissionControl() end
    return nil, "Mission Control did not show its desktops"
  end
  hs.timer.usleep(math.floor(settleSeconds * 1e6))
  return displayGroups()
end

local function close()
  if isOpen() then hs.spaces.toggleMissionControl() end
  blockUntil(isClosed, 1)
end

local function spacesGroup(groups, uuid)
  local screen = hs.screen.find(uuid)
  return child(screen and groups[screen:id()], "mc.spaces")
end

local function addUntil(groups, uuid, count)
  local button = child(spacesGroup(groups, uuid), "mc.spaces.add")
  if not button then return "No Add Desktop button for display " .. uuid end
  while #M.list(uuid) < count do
    local before = #M.list(uuid)
    button:performAction("AXPress")
    if not blockUntil(function() return #M.list(uuid) > before end, 1) then
      return "Desktop creation did not finish on display " .. uuid
    end
  end
end

--- Make each screen have at least the wanted number of user desktops.
--- Opens Mission Control once, and only when some screen is short.
--- wanted: { [screenUUID] = count }
function M.ensureCount(wanted)
  local short = hs.fnutils.filter(sortedKeys(wanted), function(uuid)
    return #M.list(uuid) < wanted[uuid]
  end)
  if #short == 0 then return {} end
  local groups, err = open()
  if not groups then return { "Cannot create desktops: " .. err } end
  local failures = {}
  for _, uuid in ipairs(short) do
    local ok, failure = pcall(addUntil, groups, uuid, wanted[uuid])
    if not ok or failure then failures[#failures + 1] = tostring(failure) end
  end
  close()
  return failures
end

-- Pressing a desktop button switches to it and closes Mission Control, so each
-- switch is its own opening.
local function switch(uuid, space)
  local index = hs.fnutils.indexOf(hs.spaces.spacesForScreen(uuid) or {}, space)
  if not index then return "Desktop " .. space .. " is not on display " .. uuid end
  local groups, err = open()
  if not groups then return "Cannot switch desktop: " .. err end
  local list = child(spacesGroup(groups, uuid), "mc.spaces.list")
  local button = list and (list:attributeValue("AXChildren") or {})[index]
  local pressed = button and button:performAction("AXPress")
  if not pressed then
    close()
    return "Cannot press desktop " .. index .. " on display " .. uuid
  end
  blockUntil(isClosed, 1)
end

--- Show the given desktop on each screen. Screens already showing it cost nothing.
--- active: { [screenUUID] = spaceID }
function M.activate(active)
  local failures = {}
  for _, uuid in ipairs(sortedKeys(active)) do
    if hs.spaces.activeSpaceOnScreen(uuid) ~= active[uuid] then
      local ok, failure = pcall(switch, uuid, active[uuid])
      if not ok then close() end
      if not ok or failure then failures[#failures + 1] = tostring(failure) end
    end
  end
  return failures
end

return M
