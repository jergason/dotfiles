#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
hs_cli=/opt/homebrew/bin/hs

# hs -c prints the chunk's print() output before its result, so the result follows a 0x1e marker.
hs_lua() {
  local output
  output=$("$hs_cli" -t "$1" -c "local r = table.pack((function() $2
end)())
for i = 1, r.n do r[i] = tostring(r[i]) end
return '\30' .. table.concat(r, '\t', 1, r.n)" </dev/null) || { printf '%s\n' "$output"; return 1; }
  printf '%s' "${output%$'\x1e'*}" >&2
  printf '%s\n' "${output##*$'\x1e'}"
}

fail() {
  local code=$1
  shift
  printf 'FAIL: %s\n' "$*" >&2
  exit "$code"
}

[[ -x $hs_cli ]] || fail 2 "$hs_cli is missing. Run hs.ipc.cliInstall(\"/opt/homebrew\") in the Hammerspoon Console."
hs_lua 2 'return true' >/dev/null || fail 2 "Hammerspoon did not answer. Open it and check that hs.ipc is loaded."

problem=$(hs_lua 5 "$(cat <<'LUA'
if type(displayLayouts) ~= "table" then return "displayLayouts is not loaded. Reload the Hammerspoon config." end
if hs.caffeinate.sessionProperties().CGSSessionScreenIsLocked then return "The screen is locked. Unlock it and rerun." end
if not hs.spaces.screensHaveSeparateSpaces() then return "Turn on Displays have separate Spaces in Mission Control settings." end
LUA
)") || fail 2 "Precondition query failed: $problem"
[[ -z $problem ]] || fail 2 "$problem"

picked=$(hs_lua 10 "local repo = [==[$repo]==]
$(cat <<'LUA'
local desktops = dofile(repo .. "/hammerspoon/desktops.lua")
local function onlyDesktop(window)
  local spaces = hs.spaces.windowSpaces(window) or {}
  return #spaces == 1 and spaces[1]
end
local screens = hs.screen.allScreens()
table.sort(screens, function(a, b) return a:getUUID() < b:getUUID() end)
for _, screen in ipairs(screens) do
  local uuid = screen:getUUID()
  local spaces = desktops.list(uuid)
  local home = hs.spaces.activeSpaceOnScreen(uuid)
  local away = hs.fnutils.find(spaces, function(id) return id ~= home end)
  local window = hs.fnutils.find(displayLayouts.windows:getWindows(), function(w)
    return w:isStandard() and not w:isFullScreen() and onlyDesktop(w) == home
      and w:screen() and w:screen():getUUID() == uuid
  end)
  if away and window and hs.fnutils.contains(spaces, home) then
    checkLayout = { desktops = desktops, window = window, screen = uuid, home = home, away = away }
    function checkLayout.mismatch(key)
      local want = checkLayout[key]
      local on = hs.spaces.windowSpaces(checkLayout.window) or {}
      local showing = hs.spaces.activeSpaceOnScreen(checkLayout.screen)
      local problems = {}
      if not hs.fnutils.contains(on, want) then
        problems[#problems + 1] = string.format("the window is on desktop %s, not %d", table.concat(on, ","), want)
      end
      if showing ~= want then
        problems[#problems + 1] = string.format("the display shows desktop %s, not %d", tostring(showing), want)
      end
      return table.concat(problems, "; ")
    end
    return "ok", string.format("%s window %d on %s", window:application():name(), window:id(), screen:name()),
      home, away
  end
end
return "No display has two or more desktops and a standard window on the desktop it shows."
LUA
)") || fail 2 "Could not pick a window: $picked"
IFS=$'\t' read -r verdict target home away <<<"$picked"
[[ $verdict == ok ]] || fail 2 "$picked"
echo "Checking with $target. It moves from desktop $home to desktop $away and back."

hs_lua 5 'checkLayoutBackup = { profiles = hs.settings.get("displayLayouts.v1") }' >/dev/null \
  || fail 2 "Could not back up the saved profiles."

put_back_and_reload() {
  local status=$?
  local profiles leftover
  profiles=$(hs_lua 5 "$(cat <<'LUA'
local profiles = checkLayoutBackup.profiles
if profiles == nil then hs.settings.clear("displayLayouts.v1") else hs.settings.set("displayLayouts.v1", profiles) end
return "ok"
LUA
)") || true
  leftover=$(hs_lua 30 "$(cat <<'LUA'
local c = checkLayout
local failures = c.desktops.assign({ { window = c.window, space = c.home } })
for _, failure in ipairs(c.desktops.activate({ [c.screen] = c.home })) do failures[#failures + 1] = failure end
return table.concat(failures, "; ")
LUA
)") || leftover="the put-back call failed"
  [[ -z $leftover ]] || printf 'WARNING: could not put the window and display back: %s\n' "$leftover" >&2
  if [[ $profiles == ok ]]; then
    hs_lua 2 'hs.reload()' >/dev/null 2>&1 || true
  else
    printf 'WARNING: saved profiles were not put back. checkLayoutBackup.profiles in the Hammerspoon Console holds them.\n' >&2
  fi
  exit "$status"
}
trap put_back_and_reload EXIT

saved=$(hs_lua 10 'return displayLayouts.save("Live check")') || fail 2 "displayLayouts.save raised an error: $saved"
[[ $saved == true ]] || fail 2 "displayLayouts.save did not save a layout."

moved=$(hs_lua 30 "$(cat <<'LUA'
local c = checkLayout
local failures = c.desktops.assign({ { window = c.window, space = c.away } })
for _, failure in ipairs(c.desktops.activate({ [c.screen] = c.away })) do failures[#failures + 1] = failure end
return table.concat(failures, "; ")
LUA
)") || fail 3 "perturbation failed: desktops.lua raised an error: $moved"
sleep 1
perturbed=$(hs_lua 5 'return checkLayout.mismatch("away")') || fail 3 "perturbation failed: could not read desktops."
[[ -z $perturbed ]] || fail 3 "perturbation failed: $perturbed${moved:+ ($moved)}"

restored=$(hs_lua 30 "$(cat <<'LUA'
displayLayouts.lastResult = nil
local result, err = displayLayouts.restore(true)
return result and "" or tostring(err)
LUA
)") || fail 1 "displayLayouts.restore raised an error: $restored"
[[ -z $restored ]] || fail 1 "displayLayouts.restore returned an error: $restored"
sleep 3

reported=$(hs_lua 5 "$(cat <<'LUA'
local result = displayLayouts.lastResult
return result and table.concat(result.failures or {}, "\n") or ""
LUA
)") || reported=""
[[ -z $reported ]] || printf 'displayLayouts.lastResult failures:\n%s\n' "$reported" >&2

unrestored=$(hs_lua 5 'return checkLayout.mismatch("home")') || fail 1 "Could not read desktops after restore."
[[ -z $unrestored ]] || fail 1 "restore did not put things back: $unrestored"
echo "PASS: restore put $target back on desktop $home and switched the display back to it"
