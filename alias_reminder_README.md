# Alias reminder for Zsh

`alias_reminder.zsh` prints a reminder when a command starts with the expansion of an alias:

```text
TIP: use gca instead of git commit --amend --no-edit
```

It checks commands through Zsh's `preexec` hook. It does not change the command that runs. When aliases overlap, it picks the longest matching command. When several aliases have the same expansion, it picks one of the shortest aliases.

## Load the reminder

This repo's `.zshrc` already loads the script. Open a new shell after installation.

To use it with another Zsh config, add this line after your alias definitions:

```zsh
source ~/code/dotfiles/alias_reminder.zsh
```

Restart the shell or run `source ~/.zshrc`.

## Refresh aliases

After you add or change aliases in the current shell, rebuild the map:

```zsh
refresh_aliases
```

To change the reminder's color or format, edit the `printf` statement in `alias_reminder.zsh`.
