# Hammerspoon

Hammerspoon restores window layouts when monitors change and keeps agent testing browsers on a separate desktop.

## Install and check Hammerspoon

1. Run `./install.sh` from the repo root. Accept the Homebrew cask step and the Hammerspoon setup step.
2. Grant Hammerspoon access in **System Settings > Privacy & Security > Accessibility**.
3. If Hammerspoon was already running, select **Reload Config** from its menu.

The installer links `~/.hammerspoon/init.lua` to this checkout and opens Hammerspoon. Keep the checkout in place. The config loads its Lua modules from here and enables launch at login.

Open **Console** from the Hammerspoon menu and run:

```lua
hs.accessibilityState() -- must return true
hs.autoLaunch() -- must return true after the config loads
amethystMonitor ~= nil and displayLayouts ~= nil and agentBrowser ~= nil -- must return true
```

The **Layouts** menu must appear in the menu bar. If a check fails, reload the config and check the Console for an error. Reload after config edits too.

## Save and restore window layouts

Arrange your windows and desktops. Select **Layouts > Save current layout…** and enter a name such as `Work` or `Home`. Each connected monitor set has one profile. Save again with those monitors connected to update it.

Hammerspoon restores the matching profile five seconds after the last display event. It also restores after wake. To restore manually, select **Layouts > Restore saved layout**.

Profiles contain window sizes, positions, desktop assignments, and the active desktop on each display. Hammerspoon stores them locally under `displayLayouts.v1`, including window titles.

The restore matches open windows by process and window ID, then by app and title. If an app has one saved window and one unmatched open window, it can match by app alone. Restore skips ambiguous matches and does not reopen closed apps. Native full-screen windows, windows assigned to all desktops, and agent testing windows are excluded.

### Desktop settings and limits

Enable **Displays have separate Spaces** in macOS Mission Control settings. Disable **Automatically rearrange Spaces based on most recent use** to keep desktop order stable.

Monitor IDs can change with adapters, ports, or laptop lid position. Save a profile for each setup. Amethyst continues to tile apps it manages.

On macOS 26.6 with Hammerspoon 1.1.1, the desktop-move API can report success without moving a window. See [Hammerspoon issue 3698](https://github.com/Hammerspoon/hammerspoon/issues/3698). Restore checks assignments after one second and reports incomplete moves. Window sizes and positions still restore. It creates missing desktops, but you may need to move windows in Mission Control.

When a disconnect leaves one monitor with no saved profile, the config selects Amethyst's fullscreen layout with `Option+Shift+D`. It reapplies the layout with `Option+Shift+Z`. These require Amethyst's default bindings and affect the active Space.

To check automatic restore, disconnect and reconnect the monitors, then wait five seconds.

## Keep agent testing browsers on a separate desktop

From the repo root, run:

```sh
python3 bin/setup-agent-chrome
```

Setup requires Node.js and the Xcode Command Line Tools. It builds `hammerspoon/.build/move-window-space` and checks that the macOS API is available. It sets `executablePath` to `bin/agent-chrome` in `~/.config/cd4a/config.json`, or under `$XDG_CONFIG_HOME` when it is an absolute path. Other settings stay intact.

Reload the Hammerspoon config, then restart your Chrome DevTools MCP sessions. See the [Chrome DevTools MCP configuration guide](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/configuration.md) for launch options.

The launcher starts Chrome without a startup window, then creates a visible background page. Hammerspoon chooses a desktop on the primary display without switching desktops. It reuses an empty desktop or one containing only testing Chrome windows. If neither is available, it creates one.

Hammerspoon moves new testing windows there and checks their desktop assignments. Amethyst can tile them together. The native helper uses the [Hammerspoon desktop-move fix](https://github.com/Hammerspoon/hammerspoon/pull/3889) because the installed Hammerspoon API does not move windows on macOS 26.6.

The launcher forwards Chrome's debugging pipe and forces new pages to open in the background. It acknowledges `Page.bringToFront` and `Target.activateTarget` without activating Chrome. You can still select Chrome in Mission Control.

Hammerspoon identifies testing Chrome by its registered process ID or its profile under `~/.cache/chrome-devtools-mcp/`. It does not use window titles.

This setup applies to new Chrome DevTools MCP browser processes that use the launcher's debugging pipe. Existing sessions and browsers started by other tools are not moved. Headless launches bypass this logic. Explicit launch flags or plugin-specific config can override the shared config.

To disable the launcher, remove `executablePath` from the MCP config.

## Run checks

From the repo root, run these checks without moving windows:

```sh
lua bin/test_display_layouts.lua
lua bin/test_agent_browser.lua
node --test bin/test_agent_chrome.mjs
```

They check monitor events, desktop selection, process classification, and focus policy.

For a live check of background windows, desktop placement, and shutdown, run:

```sh
node bin/test_agent_chrome_live.mjs
```

This opens and closes blank Chrome windows with temporary profiles.
