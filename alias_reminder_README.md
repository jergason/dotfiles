# Alias Reminder for ZSH

A simple ZSH script that reminds you to use your aliases when you type the full command.

## How It Works

This script:

1. Builds a mapping of your full commands to their aliases
2. Uses ZSH's preexec hook to check each command before execution
3. Shows a reminder when you could have used an alias

## Installation

1. Save the `alias_reminder.zsh` file somewhere on your system (e.g., `~/.zsh/alias_reminder.zsh`)

2. Add the following line to your `.zshrc` file:

   ```zsh
   source ~/.zsh/alias_reminder.zsh
   ```

3. Restart your terminal or run `source ~/.zshrc`

## Usage

The script works automatically. When you type a full command that has an alias, you'll see a reminder like:

```
TIP: use gca instead of git commit --amend --no-edit
```

If you add new aliases to your `.zshrc`, you can refresh the alias map by running:

```
refresh_aliases
```

## Customization

- Modify the color and format of the reminder by editing the `printf` statement in `alias_reminder`
- If you define aliases after shell startup, run `refresh_aliases` to rebuild the map
