# Hammerspoon

Install Hammerspoon and its CLI at `/opt/homebrew/bin/hs`. Link this checkout's `hammerspoon/init.lua` to `~/.hammerspoon/init.lua`. Open Hammerspoon and grant Accessibility access in macOS System Settings. Enable **Displays have separate Spaces** in Mission Control settings.

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
lua bin/test_agent_browser.lua
node --test bin/test_agent_chrome.mjs
```

They check desktop selection, process classification, and focus policy.

For a live check of background windows, desktop placement, and shutdown, run:

```sh
node bin/test_agent_chrome_live.mjs
```

This opens and closes blank Chrome windows with temporary profiles.
