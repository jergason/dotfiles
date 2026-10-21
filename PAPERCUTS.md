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

