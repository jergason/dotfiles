# Ghostty theme browser investigation

This note records a past diagnosis. The installed version and browser behavior have not been rechecked here.

## Recorded cause

The affected tip build was `1.3.2-main-+32e76d8ed`, from July 26, 2026. Its theme browser created an input loop but did not start it. Both `themes` and `ghostty +list-themes` failed. Terminal replies could reach the shell as stray input and produce `zsh: 1 not found`.

[Ghostty PR #13466](https://github.com/ghostty-org/ghostty/pull/13466), merged July 28, 2026, starts the input loop and fixes the lifetime of the browser's environment map. The affected commit did not contain the fix.

The initial diagnosis blamed Python's child-process launch. Replacing that launch with a direct Ghostty process did not fix the browser bug.

## Update and check the browser

1. Update Ghostty to a build that includes PR #13466.
2. Save or finish work in terminal sessions before quitting Ghostty.
3. Quit Ghostty completely, then reopen it.
4. Run `ghostty +version` to confirm the affected build was replaced.
5. Run `ghostty +list-themes` in a fresh split. Check that the preview renders and navigation changes the selected theme. Press Escape and check that no stray input reaches the shell.
6. Run `themes` and repeat those checks. If the alias is unavailable, first run `source ~/code/dotfiles/ghostty-themes.zsh`.
7. Run `themes random dark`. Press `Ctrl+A`, then `R` to reload. Check that the dark theme changes and the light setting stays intact.

If the direct browser still fails, record the new version and behavior before changing the helper. Startup escape sequences do not prove that navigation or exit works.

## Use themes without the browser

These commands bypass the interactive browser:

```sh
themes list
themes random
themes random dark
themes next
themes previous light
themes add dark "Rose Pine Moon"
ghostty +list-themes --plain
```

After a theme change, press `Ctrl+A`, then `R` to reload Ghostty. Favorites live in `ghostty-favorites.json`. The helper edits `ghostty-config`, linked to `~/.config/ghostty/config`.

## Recorded checks

Tests with temporary files passed for favorite selection, cycling, favorite edits, config preservation, and symlink preservation. The process-handoff test also passed. These tests did not check the interactive UI. Browser verification was pending a Ghostty update.

Run the Ghostty helper tests with:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s bin -p 'test_ghostty_themes.py'
```
