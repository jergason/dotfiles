#!/usr/bin/env python3
"""Check repeat installs without changing the user's home or installing tools."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class InstallTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.repo = root / "dotfiles"
        self.home = root / "home"
        self.commands = root / "bin"
        for directory in (self.repo, self.home, self.commands):
            directory.mkdir()
        for name in (
            "install.sh", ".zshrc", ".gitconfig", "ghostty-config",
            "homebrew-packages.txt", "homebrew-casks.txt", "hammerspoon/init.lua",
            "ai/install.sh", "ai/link.sh",
            "ai/install-codex-accounts.sh", "ai/AGENTS.md",
        ):
            target = self.repo / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(REPO / name, target)
        for name in ("opencode/plugins/example.js", "skills/.skill-lock.json"):
            target = self.repo / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("{}\n")
        self.packages = root / "installed-packages"
        self.packages.write_text((self.repo / "homebrew-packages.txt").read_text())
        self.casks = root / "installed-casks"
        self.casks.write_text((self.repo / "homebrew-casks.txt").read_text())
        self.brew_log = root / "brew-log"
        self.env = {
            **os.environ, "HOME": str(self.home),
            "PATH": f"{self.commands}:/usr/bin:/bin:/usr/sbin:/sbin",
            "NVM_DIR": str(self.home / ".nvm"),
            "ZSH": str(self.home / ".oh-my-zsh"),
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "XDG_DATA_HOME": str(self.home / ".local/share"),
            "XDG_STATE_HOME": str(self.home / ".local/state"),
            "BREW_LIST": str(self.packages), "BREW_CASK_LIST": str(self.casks),
            "BREW_LOG": str(self.brew_log),
        }
        for name in ("nvim", "claude", "codex", "pi", "rustc", "atuin"):
            self.command(name, "exit 0\n")
        self.command("brew", 'if [ "$1" = list ]; then\n  if [ "$2" = --cask ]; then cat "$BREW_CASK_LIST"; else cat "$BREW_LIST"; fi\nelse\n  printf "%s\\n" "$@" > "$BREW_LOG"\nfi\n')
        self.command("uname", "echo Linux\n")
        for name in (
            ".config/ghostty/shaders", ".config/ghostty/ghostty-shader-playground",
            "code/nvim-config", ".oh-my-zsh", ".nvm", "Library/Fonts",
        ):
            (self.home / name).mkdir(parents=True, exist_ok=True)
        for name in (".oh-my-zsh/oh-my-zsh.sh", ".nvm/nvm.sh", "Library/Fonts/TestNerdFont.ttf"):
            (self.home / name).write_text("# installed\n")
        for source, target in (
            (".zshrc", ".zshrc"), (".gitconfig", ".gitconfig"),
            ("hammerspoon/init.lua", ".hammerspoon/init.lua"),
            ("ghostty-config", ".config/ghostty/config"),
            ("opencode/plugins/example.js", ".config/opencode/plugins/example.js"),
        ):
            path = self.home / target
            path.parent.mkdir(parents=True, exist_ok=True)
            path.symlink_to(self.repo / source)
        self.run_script("ai/install.sh")

    def command(self, name, body):
        path = self.commands / name
        path.write_text("#!/bin/bash\n" + body)
        path.chmod(0o755)

    def run_script(self, name="install.sh", *args, answers="n\n" * 30, check=True):
        return subprocess.run(
            ["/bin/bash", str(self.repo / name), *args], env=self.env,
            input=answers, text=True, capture_output=True, check=check,
        )

    def test_completed_install_has_no_prompts(self):
        result = self.run_script()
        self.assertNotIn("Do you want", result.stdout)
        self.assertIn("Dotfiles are already installed.", result.stdout)
        self.assertFalse(self.brew_log.exists())

    def test_missing_links_are_repaired_then_skipped(self):
        for target, prompt in (
            (".gitconfig", "install dotfiles"),
            (".config/opencode/plugins/example.js", "install OpenCode plugins"),
            (".codex-work/config.toml", "install AI instructions"),
        ):
            with self.subTest(target=target):
                (self.home / target).unlink()
                declined = self.run_script()
                self.assertIn(f"Do you want to {prompt}", declined.stdout)
                self.assertFalse((self.home / target).exists())
                self.run_script(answers="y\n")
                self.assertTrue((self.home / target).is_symlink())
                self.assertNotIn("Do you want", self.run_script().stdout)

    def test_only_missing_packages_are_installed(self):
        packages = self.packages.read_text().splitlines()
        self.packages.write_text("\n".join(packages[1:]) + "\n")
        result = self.run_script(answers="y\n")
        self.assertEqual(result.stdout.count("Do you want"), 1)
        self.assertEqual(self.brew_log.read_text().splitlines(), ["install", packages[0]])

    def test_missing_hashicorp_tools_use_official_formulae(self):
        tools = ["hashicorp/tap/packer", "hashicorp/tap/terraform"]
        packages = self.packages.read_text().splitlines()
        self.packages.write_text("\n".join(p for p in packages if p not in tools) + "\n")
        self.run_script(answers="y\n")
        self.assertEqual(self.brew_log.read_text().splitlines(), ["install", *tools])

    def test_missing_casks_are_installed_on_macos(self):
        self.command("uname", "echo Darwin\n")
        self.casks.write_text("")
        self.run_script(answers="y\nn\n")
        self.assertEqual(self.brew_log.read_text().splitlines(),
                         ["install", "--cask", *(self.repo / "homebrew-casks.txt").read_text().splitlines()])

    def test_installed_casks_are_skipped(self):
        self.command("uname", "echo Darwin\n")
        result = self.run_script()
        self.assertIn("Homebrew casks are already installed.", result.stdout)
        self.assertFalse(self.brew_log.exists())

    def test_casks_are_skipped_on_linux(self):
        self.casks.write_text("")
        result = self.run_script()
        self.assertNotIn("install homebrew casks", result.stdout)
        self.assertFalse(self.brew_log.exists())

    def test_ai_check_does_not_repair_stale_links(self):
        target = self.home / ".codex-work/config.toml"
        target.unlink()
        target.symlink_to("/missing/copied-config.toml")
        result = self.run_script("ai/install.sh", "--check", check=False)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(os.readlink(target), "/missing/copied-config.toml")
        self.assertEqual(list(target.parent.glob("*.bak.*")), [])
        self.run_script("ai/install.sh")
        self.run_script("ai/install.sh", "--check")

    def test_ai_check_on_empty_home_creates_nothing(self):
        shutil.rmtree(self.home)
        self.home.mkdir()
        result = self.run_script("ai/install.sh", "--check", check=False)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(list(self.home.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
