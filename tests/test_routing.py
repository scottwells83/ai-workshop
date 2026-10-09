"""Routing records must be useful for improvement without retaining prompts."""

import contextlib
import io
import json
from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch

import workshop
import workshop_app


class RoutingTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.log = Path(self.tmp.name) / "usage-log.jsonl"
        self.patcher = patch.object(workshop, "USAGE_LOG", self.log)
        self.patcher.start()
        self.addCleanup(self.patcher.stop)

    def records(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_routing_summary_keeps_gaps_separate_from_token_usage(self):
        workshop.record_routing("entered_workshop", "none", "codex", project="sample",
                                recorded_by="launcher")
        workshop.record_routing("unavailable", "no_local_access", "chatgpt",
                                "filesystem", recorded_by="backfill")
        workshop.record_routing("unavailable", "no_local_access", "gemini",
                                "filesystem", recorded_by="backfill")
        with contextlib.redirect_stdout(io.StringIO()) as out:
            workshop.usage_summary()
        summary = json.loads(out.getvalue())
        self.assertEqual(2, summary["routing"]["unavailable_by_reason"]["no_local_access"])
        self.assertEqual(2, summary["routing"]["unavailable_by_capability"]["filesystem"])
        self.assertEqual({}, summary["surfaces"])
        self.assertNotIn("prompt", self.log.read_text())

    def test_task_percentages_use_only_logged_responses(self):
        workshop.record_task_outcome("workshop", "responded", "workshop",
                                     recorded_by="manager")
        workshop.record_task_outcome("hybrid", "responded", "workshop",
                                     recorded_by="manager")
        workshop.record_task_outcome("external", "responded", "codex",
                                     recorded_by="backfill")
        workshop.record_task_outcome("workshop", "failed", "workshop",
                                     recorded_by="manager")
        with contextlib.redirect_stdout(io.StringIO()) as out:
            workshop.usage_summary()
        report = json.loads(out.getvalue())["task_execution"]
        self.assertEqual(3, report["logged_responses"])
        self.assertEqual(1, report["failed_requests"])
        self.assertEqual(33.3, report["percent_of_logged_responses"]["workshop"])
        self.assertEqual(33.3, report["percent_of_logged_responses"]["external"])
        self.assertIn("unlogged work is excluded", report["coverage"])

    def test_invalid_or_sensitive_labels_are_rejected(self):
        with self.assertRaises(ValueError):
            workshop.record_routing("unavailable", "none", "chatgpt")
        with self.assertRaises(ValueError):
            workshop.record_routing("unavailable", "no_local_access", "chatgpt",
                                    "My private book title")
        self.assertFalse(self.log.exists())

    def test_disabled_handoff_is_logged_without_opening_the_app(self):
        with patch.object(workshop_app.App, "preferences", return_value={"auto_handoff": False}):
            with contextlib.redirect_stdout(io.StringIO()):
                workshop_app.launch("A task", handoff=True, origin="chatgpt")
        self.assertEqual("auto_handoff_disabled", self.records()[0]["reason"])
        self.assertEqual("chatgpt", self.records()[0]["surface"])

    def test_successful_app_handoff_records_origin_without_prompt(self):
        completed = threading.Event()
        app = workshop_app.App()
        project = Path(self.tmp.name) / "sample"
        project.mkdir()
        with patch.object(app, "respond", side_effect=lambda *_: completed.set()):
            app.start_handoff(project, "Private request text", "gemini")
            self.assertTrue(completed.wait(2))
        self.assertEqual("entered_workshop", self.records()[0]["outcome"])
        self.assertEqual("gemini", self.records()[0]["surface"])
        self.assertNotIn("Private request text", self.log.read_text())


if __name__ == "__main__":
    unittest.main()
