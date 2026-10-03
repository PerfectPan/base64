"""Exercise the publishing preflight with a local fake moon; no registry calls."""

import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("check_publish.py")
RECEIPT = (
    "Server status: 202 Accepted, detail: Dry run completed successfully. "
    "No changes were made. The dry-run was made for package "
    "PerfectPan/base64 version 0.2.0."
)
CLI_ERROR = "Error: `moon publish` failed"
SUCCESS = f"{RECEIPT}\n{CLI_ERROR}\n"


class PublishPreflightTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "module"
        (self.root / "scripts").mkdir(parents=True)
        self.script = self.root / "scripts" / SCRIPT.name
        shutil.copyfile(SCRIPT, self.script)
        self.script.chmod(0o755)
        (self.root / "moon.mod").write_text(
            'name = "PerfectPan/base64"\nversion = "0.2.0"\n', encoding="utf-8"
        )
        self.bin = Path(self.temp.name) / "bin"
        self.bin.mkdir()
        self.calls = Path(self.temp.name) / "calls.json"
        moon = self.bin / "moon"
        moon.write_text(
            f"#!{sys.executable}\n"
            "import json, os, pathlib, signal, sys\n"
            "pathlib.Path(os.environ['TEST_MOON_CALLS']).write_text(\n"
            "    json.dumps({'args': sys.argv[1:], 'cwd': os.getcwd()}))\n"
            "sys.stdout.write(os.environ.get('TEST_MOON_OUTPUT', ''))\n"
            "sys.stdout.flush()\n"
            "sys.stderr.write(os.environ.get('TEST_MOON_ERROR_OUTPUT', ''))\n"
            "sys.stderr.flush()\n"
            "if os.environ.get('TEST_MOON_SIGNAL'):\n"
            "    os.kill(os.getpid(), int(os.environ['TEST_MOON_SIGNAL']))\n"
            "sys.exit(int(os.environ.get('TEST_MOON_EXIT', '255')))\n",
            encoding="utf-8",
        )
        moon.chmod(0o755)

    def run_script(self, output=SUCCESS, exit_code=255, args=(), sig=None, direct=False,
                   error_output=""):
        env = dict(os.environ, PATH=f"{self.bin}{os.pathsep}{os.environ.get('PATH', '')}",
                   TEST_MOON_CALLS=str(self.calls), TEST_MOON_OUTPUT=output,
                   TEST_MOON_EXIT=str(exit_code), TEST_MOON_ERROR_OUTPUT=error_output)
        env.pop("TEST_MOON_SIGNAL", None)
        if sig is not None:
            env["TEST_MOON_SIGNAL"] = str(sig)
        command = [str(self.script)] if direct else [sys.executable, str(self.script)]
        return subprocess.run(command + list(args), cwd=self.bin, env=env,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              text=True, check=False)

    def test_exact_receipt_normalizes_only_known_cli_failure(self):
        result = self.run_script(direct=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.startswith(SUCCESS))
        self.assertIn("exact 202 dry-run success receipt", result.stdout)
        self.assertIn("no release was published", result.stdout)
        self.assertEqual(json.loads(self.calls.read_text()), {
            "args": ["publish", "--dry-run"], "cwd": str(self.root.resolve()),
        })

    def test_receipt_and_conflicts_on_stderr_are_checked(self):
        result = self.run_script(output="Packaging complete\n", error_output=SUCCESS)
        self.assertEqual(result.returncode, 0)
        self.assertTrue(result.stdout.startswith("Packaging complete\n" + SUCCESS))
        output = "Error: archive failed\n"
        result = self.run_script(output=output, error_output=SUCCESS)
        self.assertEqual(result.returncode, 255)
        self.assertEqual(result.stdout, output + SUCCESS)

    def test_native_success_preserves_output(self):
        for output in ("Published dry-run successfully\n", SUCCESS, ""):
            with self.subTest(output=output):
                result = self.run_script(output, exit_code=0)
                self.assertEqual(result.returncode, 0)
                self.assertEqual(result.stdout, output)
                self.assertEqual(result.stderr, "")

    def test_http_errors_preserve_failure(self):
        for status in ("401 Unauthorized", "403 Forbidden", "500 Internal Server Error"):
            with self.subTest(status=status):
                output = f"Server status: {status}, detail: rejected\n{CLI_ERROR}\n"
                result = self.run_script(output)
                self.assertEqual(result.returncode, 255)
                self.assertEqual(result.stdout, output)

    def test_missing_similar_or_wrong_identity_receipt_fails(self):
        for output in (
            CLI_ERROR + "\n", RECEIPT + "\n", "", SUCCESS.replace("successfully", "successful"),
            SUCCESS.replace("PerfectPan/base64", "Other/base64"),
            SUCCESS.replace("version 0.2.0.", "version 0.2.1."),
            SUCCESS.replace("202 Accepted", "200 OK"), SUCCESS + "extra output\n",
        ):
            with self.subTest(output=output):
                result = self.run_script(output)
                self.assertEqual(result.returncode, 255)
                self.assertEqual(result.stdout, output)

    def test_additional_errors_or_server_status_fail(self):
        for extra in (
            "Error: invalid credentials\n", "error: archive failed\n", "Failure: rejected\n",
            "upload FAILED\n", "Server status: 500 Internal Server Error\n", RECEIPT + "\n",
        ):
            with self.subTest(extra=extra):
                output = extra + SUCCESS
                result = self.run_script(output)
                self.assertEqual(result.returncode, 255)
                self.assertEqual(result.stdout, output)

    def test_other_nonzero_codes_and_signals_remain_failures(self):
        for code in (1, 2, 64, 254):
            with self.subTest(code=code):
                result = self.run_script(exit_code=code)
                self.assertEqual(result.returncode, code)
                self.assertEqual(result.stdout, SUCCESS)
        result = self.run_script(sig=signal.SIGTERM)
        self.assertEqual(result.returncode, 128 + signal.SIGTERM)
        self.assertEqual(result.stdout, SUCCESS)

    def test_unknown_arguments_never_invoke_moon(self):
        for args in (("--publish",), ("publish",), ("--dry-run",), ("--", "publish")):
            with self.subTest(args=args):
                result = self.run_script(args=args)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(self.calls.exists())

    def test_unsupported_manifest_never_invokes_moon(self):
        for manifest in (
            'name = "PerfectPan/base64"\n',
            'name = "PerfectPan/base64"\nname = "Other/base64"\nversion = "0.2.0"\n',
            'name = "PerfectPan/base64"\nversion = 2\n',
            'name = "PerfectPan/base64"\nversion = "0.2.0" # comment\n',
            'name = "PerfectPan/base64"\n version = "0.2.0"\n',
            'name = "PerfectPan/base64"\nversion = "bad\\q"\n',
        ):
            with self.subTest(manifest=manifest):
                (self.root / "moon.mod").write_text(manifest, encoding="utf-8")
                result = self.run_script()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("cannot read canonical module identity", result.stderr)
                self.assertFalse(self.calls.exists())


if __name__ == "__main__":
    unittest.main()
