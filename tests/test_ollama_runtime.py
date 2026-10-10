"""Checks that the bundled helper remains private and avoids duplicate work."""
import tempfile
from pathlib import Path
import unittest
from unittest.mock import patch

import ollama_runtime


class OllamaRuntimeTests(unittest.TestCase):
    def test_existing_private_server_is_reused(self):
        with patch.object(ollama_runtime, "healthy", return_value=True), \
             patch.object(ollama_runtime.subprocess, "Popen") as launch:
            self.assertIsNone(ollama_runtime.start())
            launch.assert_not_called()

    def test_entrypoint_must_stay_inside_bundle(self):
        with tempfile.TemporaryDirectory() as temp, patch.object(ollama_runtime, "BUNDLE", Path(temp)):
            (Path(temp) / "entrypoint.txt").write_text("../other/ollama\n", encoding="utf-8")
            with self.assertRaisesRegex(RuntimeError, "Invalid bundled"):
                ollama_runtime.executable()

    def test_first_run_only_downloads_missing_models(self):
        existing = {"llama3.2:3b", "local-worker"}
        created = existing | {"llama3.1:8b"}
        commands = []
        with patch.object(ollama_runtime, "model_names", side_effect=[existing, created]), \
             patch.object(ollama_runtime, "model_readable", return_value=True), \
             patch.object(ollama_runtime, "cli", side_effect=lambda *args: commands.append(args)):
            ollama_runtime.ensure_models(lambda _: None)
        self.assertEqual([("pull", "llama3.1:8b")], [item for item in commands if item[0] == "pull"])
        self.assertNotIn(("create", "local-worker", "-f", str(ollama_runtime.ROOT / "Modelfile")), commands)
        self.assertEqual(6, sum(item[0] == "create" for item in commands))


if __name__ == "__main__":
    unittest.main()
