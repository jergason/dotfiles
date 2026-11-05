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

Hammerspoon restores the matching profile five seconds after the last display event. It also restores after wake. To restore manually, select **Layouts > Restore saved layout**.

Profiles contain window sizes, positions, desktop assignments, and the active desktop on each display. Hammerspoon stores them locally under `displayLayouts.v1`, including window titles.

The restore matches open windows by process and window ID, then by app and title. If an app has one saved window and one unmatched open window, it can match by app alone. Restore skips ambiguous matches and does not reopen closed apps. Native full-screen windows and windows assigned to all desktops are excluded.

### Desktop settings and limits

Enable **Displays have separate Spaces** in macOS Mission Control settings. Disable **Automatically rearrange Spaces based on most recent use** to keep desktop order stable.

Monitor IDs can change with adapters, ports, or laptop lid position. Save a profile for each setup. Amethyst continues to tile apps it manages.

On macOS 26.6 with Hammerspoon 1.1.1, the desktop-move API can report success without moving a window. See [Hammerspoon issue 3698](https://github.com/Hammerspoon/hammerspoon/issues/3698). Restore checks assignments after one second and reports incomplete moves. Window sizes and positions still restore. It creates missing desktops, but you may need to move windows in Mission Control.

When a disconnect leaves one monitor with no saved profile, the config selects Amethyst's fullscreen layout with `Option+Shift+D`. It reapplies the layout with `Option+Shift+Z`. These require Amethyst's default bindings and affect the active Space.

To check automatic restore, disconnect and reconnect the monitors, then wait five seconds.

## Run checks

From the repo root, run this check without moving windows:

```sh
lua bin/test_display_layouts.lua
```

It checks how the config responds to monitor and wake events.
