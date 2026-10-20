# Papercuts

Small frictions whose plausible fixes would change version-controlled files in this repository. Logged via `papercuts`.

2026-09-07T01:51:52.983Z - gpt-6 - Jamison Dance

The gchg and gbugs aliases in .zshrc used HEAD -20 after a Git ref capitalization edit. Restored the lowercase head command so both reports work.
2026-09-09T18:37:13.141Z - gpt-6-astra - Jamison Dance

The Claude account directory list had drifted from README.md, which omitted three work paths. Keep Claude and Codex routing in ai_account.zsh and document the shared list.
2026-09-11T15:01:19.357Z - gpt-6 - Jamison Dance

The interactive browser check for bin/ghostty-themes verified startup output but not input or rendering, so it missed a broken Ghostty build. Future browser verification must include navigation and exit; Ghostty PR #13466 fixes the missing input loop in installed build 32e76d8ed.
