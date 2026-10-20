# Resolve the checkout when sourced, so themes works from any directory.
alias themes="python3 '${${(%):-%N}:A:h}/bin/ghostty-themes'"
