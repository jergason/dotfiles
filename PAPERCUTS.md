# Papercuts

Small frictions whose plausible fixes would change version-controlled files in this repository. Logged via `papercuts`.

2026-09-07T01:51:52.983Z - gpt-6 - Jamison Dance

The gchg and gbugs aliases in .zshrc used HEAD -20 after a Git ref capitalization edit. Restored the lowercase head command so both reports work.
2026-09-09T18:37:13.141Z - gpt-6-astra - Jamison Dance

The Claude account directory list had drifted from README.md, which omitted three work paths. Keep Claude and Codex routing in ai_account.zsh and document the shared list.
2026-09-11T15:01:19.357Z - gpt-6 - Jamison Dance

The interactive browser check for bin/ghostty-themes verified startup output but not input or rendering, so it missed a broken Ghostty build. Future browser verification must include navigation and exit; Ghostty PR #13466 fixes the missing input loop in installed build 32e76d8ed.
2026-10-20T18:13:31.422Z - gpt-6 - jamison

The AI installer did not repair copied account symlinks or load wrappers in a minimal shell, and the Codex wrapper did not select saved CLI profiles. Fixed account-link installation with backups and automatic shell loading, plus CLI profile selection limited to supported commands.
2026-10-20T18:22:13.445Z - gpt-6 - Jamison Dance

install.sh offers to reinstall Homebrew even when brew is already available, and the package prompt is nested under that reinstall step. Detect the existing command and offer package installation independently.
2026-10-20T18:26:43.263Z - gpt-6 - Jamison Dance

install.sh reruns tool installers and git clones without checking existing installs or checkouts, and recreates correct config links. Check installed tools and fonts, reuse checkouts, and preserve matching links so setup can run again safely.
2026-10-20T18:30:21.489Z - gpt-6 - Jamison Dance

install.sh configures AI account links without installing Claude Code, Codex, or Pi, and Oh My Zsh runs after the repo .zshrc is linked. Add checked CLI install steps and run Oh My Zsh first with configuration preservation and automatic shell launch disabled.
2026-10-21T18:11:37.919Z - gpt-6 - Jamison Dance

install.sh still prompts for dotfiles, OpenCode plugins, Homebrew packages, and AI configuration when they are complete. Check the required links and installed packages before each prompt, and retain prompts for incomplete setup.

2026-10-21T18:17:48.526Z - gpt-6 - Jamison Dance

The font completion check in install.sh accepts any Nerd Font, but ghostty-config requires MesloLGM Nerd Font. Check the configured family so another installed Nerd Font cannot hide missing Meslo fonts.

2026-10-22T16:26:06.039Z - gpt-6 - Jamison Dance

hammerspoon/init.lua did not load hs.ipc, so the installed hs command could not inspect or reload the configuration. The config now loads hs.ipc so window automation can be captured and checked through the local CLI.

2026-10-22T16:40:00.489Z - gpt-6 - Jamison Dance

hammerspoon/display-layouts.lua must verify actual desktop assignments because macOS 26.6 can return success from hs.spaces.moveWindowToSpace without moving a window. Restore now checks assignments after one second and reports incomplete desktop restoration instead of claiming success.

2026-10-22T17:48:36.924Z - gpt-6 - Jamison Dance

Chrome DevTools MCP launched testing windows on the active workspace, where Amethyst tiled them with personal apps. A shared executablePath config now routes new browser processes through bin/agent-chrome, which selects an empty desktop before Chrome starts.

2026-10-23T18:11:40.909Z - gpt-6.1-sol - Jamison Dance

The Homebrew manifest covers only formulae, while Hammerspoon is installed by a separate hard-coded step. Add a macOS cask manifest so required applications are visible and checked by the package install step.

2026-10-23T20:07:24.525Z - gpt-6.1-sol - Jamison Dance

bin/test_install.py hard-coded the missing-cask expectation to Hammerspoon, so adding required casks broke the installer test. Derive the expected cask list from homebrew-casks.txt so manifest changes remain covered.

2026-10-23T23:45:43.966Z - gpt-6.1-sol - Jamison Dance

bin/agent-chrome switches to the testing desktop before every headed launch, which interrupts keyboard focus even when Hammerspoon later returns to the previous workspace. Launch testing Chrome without changing the active workspace, and cover focus preservation in the browser checks.

2026-10-23T23:59:35.346Z - gpt-6 - Jamison Dance

CLAUDE.md lists gpf as a plain force push and br as a configured Git alias, but .zshrc uses --force-with-lease and .gitconfig has no br alias. Keep the command reference aligned with those files, and document that .zshrc already loads alias_reminder.zsh.

2026-10-24T00:02:16.202Z - gpt-6.1-sol - Jamison Dance

hammerspoon/agent-browser.lua used the shared window filter to detect new testing windows, which missed a second Chrome process with the same application name. Per-process application watchers now track and place windows from independent agent browsers.

