# Ghostty theme browser next steps

## Confirmed cause

The installed Ghostty tip build is `1.3.2-main-+32e76d8ed`, from July 26, 2026. Its theme browser creates an input loop but never starts it. Both `themes` and a direct `ghostty +list-themes` call fail. Terminal replies can reach the shell as stray input and produce `zsh: 1 not found`.

[Ghostty PR #13466](https://github.com/ghostty-org/ghostty/pull/13466), merged July 28, 2026, starts the input loop and fixes the lifetime of the browser's environment map. The installed commit was checked against that fix and does not contain it.

The earlier diagnosis that Python's child-process launch caused the freeze was incorrect. Replacing Python with Ghostty is still a reasonable launch method, but it does not fix this Ghostty bug.

## Next steps

1. Update Ghostty to a tip build that includes PR #13466.
2. Finish or save work in terminal sessions before quitting Ghostty.
3. Quit Ghostty completely and reopen it.
4. Run `ghostty +version` to confirm the old build was replaced.
5. Run `ghostty +list-themes` in a fresh split. Verify that the preview renders, navigation changes the selected theme, and Escape returns to the shell without stray input.
6. Run `themes` and repeat the same checks. If the alias is unavailable, run `source ~/code/dotfiles/ghostty-themes.zsh` first.
7. Run `themes random dark`, then press `Ctrl+A`, then `R` to reload the config. Verify the theme changes while the light theme setting stays intact.

If the direct browser still fails, record the new version and behavior before changing the helper again. Startup escape sequences alone do not prove that the browser works.

## Available meanwhile

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

After a theme change, press `Ctrl+A`, then `R` to reload Ghostty.

Favorites are stored in `ghostty-favorites.json`. The helper updates the theme setting in `ghostty-config`, which is linked from `~/.config/ghostty/config`.

## Verification already completed

Favorite selection, cycling, favorite edits, config preservation, and symlink preservation passed checks with temporary copies. The process-handoff test passes, but does not verify Ghostty's interactive UI. Full browser verification remains pending the Ghostty update.

Run the process-handoff test with:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s bin -p 'test_*.py'
```
