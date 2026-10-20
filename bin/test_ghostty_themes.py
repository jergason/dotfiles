"""Run with python3 -m unittest discover -s bin -p 'test_*.py'."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class BrowserLaunchTest(unittest.TestCase):
    def test_browser_replaces_helper_and_preserves_arguments_and_exit_status(self):
        helper = Path(__file__).resolve().with_name("ghostty-themes")
        with tempfile.TemporaryDirectory() as directory:
            ghostty = Path(directory) / "ghostty"
            ghostty.write_text(
                "#!/bin/sh\n"
                "printf '%s\\n' \"$$\" \"$@\"\n"
                "exit 7\n"
            )
            ghostty.chmod(0o755)
            for args, color in (([], "all"), (["browse", "dark"], "dark"),
                                (["browse", "light"], "light")):
                with self.subTest(args=args):
                    with subprocess.Popen(
                        [sys.executable, str(helper), *args],
                        env={**os.environ, "PATH": directory},
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                    ) as process:
                        output, error = process.communicate(timeout=5)
                        self.assertEqual(error, "")
                        self.assertEqual(process.returncode, 7)
                        self.assertEqual(output.splitlines(), [
                            str(process.pid), "+list-themes", f"--color={color}",
                        ])
