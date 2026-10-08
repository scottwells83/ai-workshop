"""The large reviewer must stay optional on machines without its base model."""
import io
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

import workshop
from workshop_app import tool_specs


class OptionalReviewerTests(unittest.TestCase):
    def test_job_manifest_accepts_reviewer(self):
        with TemporaryDirectory() as tmp:
            project = Path(tmp)
            (project / "briefs").mkdir()
            (project / "briefs" / "review.txt").write_text("Task\nReview supplied text\n")
            (project / "jobs.json").write_text(json.dumps({"parallel": 1, "jobs": [
                {"id": "review", "model": "local-reviewer", "brief": "review.txt"}
            ]}))
            _, jobs = workshop.validate_jobs(project)
            self.assertEqual("local-reviewer", jobs[0]["model"])

    def test_doctor_succeeds_without_optional_reviewer(self):
        payload = {"models": [{"name": name + ":latest"} for name in workshop.MODELS]}
        response = io.BytesIO(json.dumps(payload).encode())
        output = io.StringIO()
        with patch("workshop.urlopen", return_value=response), patch("sys.stdout", output):
            status = workshop.doctor()
        self.assertEqual(0, status)
        self.assertIn("Optional model local-reviewer: not installed", output.getvalue())
        self.assertIn("All 7 workshop models are available", output.getvalue())

    def test_desktop_tool_offers_reviewer_only_when_available(self):
        def choices(available):
            tool = next(item for item in tool_specs(available)
                        if item["function"]["name"] == "local_job")
            return tool["function"]["parameters"]["properties"]["model"]["enum"]
        self.assertNotIn("local-reviewer", choices(False))
        self.assertIn("local-reviewer", choices(True))


if __name__ == "__main__":
    unittest.main()
