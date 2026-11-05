# Hammerspoon

Hammerspoon restores window layouts when monitors change.

## Install and check Hammerspoon

1. Run `./install.sh` from the repo root. Accept the Homebrew cask step and the Hammerspoon setup step.
2. Grant Hammerspoon access in **System Settings > Privacy & Security > Accessibility**.
3. If Hammerspoon was already running, select **Reload Config** from its menu.

The installer links `~/.hammerspoon/init.lua` to this checkout and opens Hammerspoon. Keep the checkout in place. The config loads its Lua modules from here and enables launch at login.

Open **Console** from the Hammerspoon menu and run:

```lua
hs.accessibilityState() -- must return true
hs.autoLaunch() -- must return true after the config loads
amethystMonitor ~= nil and displayLayouts ~= nil -- must return true
```

The **Layouts** menu must appear in the menu bar. If a check fails, reload the config and check the Console for an error. Reload after config edits too.

## Save and restore window layouts

Arrange your windows and desktops. Select **Layouts > Save current layout…** and enter a name such as `Work` or `Home`. Each connected monitor set has one profile. Save again with those monitors connected to update it.

Hammerspoon restores the matching profile five seconds after the last display event. It also restores after wake. If the screen is locked at that point, restore waits until you unlock it. To restore manually, select **Layouts > Restore saved layout**.

Profiles contain window sizes, positions, desktop assignments, and the active desktop on each display. Hammerspoon stores them locally under `displayLayouts.v1`, including window titles.

The restore matches open windows by process and window ID, then by app and title. If an app has one saved window and one unmatched open window, it can match by app alone. Restore skips ambiguous matches and does not reopen closed apps. Native full-screen windows and windows assigned to all desktops are excluded.

### Desktop settings and limits

Enable **Displays have separate Spaces** in macOS Mission Control settings. Disable **Automatically rearrange Spaces based on most recent use** to keep desktop order stable.

Monitor IDs can change with adapters, ports, or laptop lid position. Save a profile for each setup. Amethyst continues to tile apps it manages.

Hammerspoon 1.1.1's own desktop changes don't work on macOS 27. On macOS 26.6 and later, `hs.spaces.moveWindowToSpace` reports success without moving the window ([Hammerspoon issue 3698](https://github.com/Hammerspoon/hammerspoon/issues/3698)). On macOS 27, `hs.spaces.gotoSpace` and `hs.spaces.addSpaceToScreen` fail too, because Mission Control's accessibility tree moved from the Dock to `com.apple.WindowManager`. `desktops.lua` makes these changes instead:

- `move-window-space` moves windows between desktops. `desktops.lua` builds it from `move-window-space.m` into `hammerspoon/.build/` the first time it moves a window, and again after the source changes. The build needs the Xcode Command Line Tools. Without them, restore still positions windows and reports the build failure.
- `desktops.lua` creates desktops and switches the shown desktop by pressing buttons in Mission Control, so Mission Control flashes open. Creating desktops opens it once. Each display that shows the wrong desktop opens it once more.

If a desktop can't be created, restore still positions every window and reports each window it couldn't put on its desktop. One second after a restore, it checks each window's desktop and each display's shown desktop. It reports anything that didn't stick in the Console.

To change desktops from config code, call `desktops.lua`, not `hs.spaces.moveWindowToSpace`, `gotoSpace`, or `addSpaceToScreen`. `bin/test_display_restore.lua` fails if `display-layouts.lua` calls them.

When a disconnect leaves one monitor with no saved profile, the config selects Amethyst's fullscreen layout with `Option+Shift+D`. It reapplies the layout with `Option+Shift+Z`. These require Amethyst's default bindings and affect the active Space.

To check automatic restore, disconnect and reconnect the monitors, then wait five seconds.

## Run checks

From the repo root, run these checks without moving windows:

```sh
lua bin/test_display_layouts.lua
lua bin/test_display_restore.lua
```

The first checks how the config responds to monitor and wake events. The second checks restore against a fake Mac: window frames, desktop mapping, and failure reports.

To check restore on the real desktops, unlock the screen and run:

```sh
bin/check_layout_restore.sh
```

The live check saves the current layout over the profile for the connected monitors. It moves one window to another desktop and switches that display to the same desktop. Then it runs restore and checks that both came back. On exit it puts the window, the display, and your saved profiles back, then reloads the Hammerspoon config.

Before the live check moves anything, it checks for the following:

- Hammerspoon's `hs` command is at `/opt/homebrew/bin/hs`. To install it, run `hs.ipc.cliInstall("/opt/homebrew")` in the Hammerspoon Console.
- The screen is unlocked, and **Displays have separate Spaces** is on.
- A display has two or more desktops and a standard window on the desktop it shows.

On success, the live check prints a `PASS` line and exits 0. Otherwise it prints a `FAIL` line. Exit code 1 means restore didn't put things back, 2 means a precondition failed, and 3 means the check couldn't move the window before restoring.
