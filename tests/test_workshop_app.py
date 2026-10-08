import unittest

from workshop_app import draft_warnings, normalize_brief


class BriefNormalizationTests(unittest.TestCase):
    def test_accepts_mapping_string_from_model(self):
        supplied = "{'Task': 'Write story', 'Context': 'Young reader', 'Constraints': 'Gentle', 'Deliverable': 'Story', 'Definition of done': 'Check request'}"
        brief = normalize_brief(supplied, "Write a story")
        for heading in ("Task", "Context", "Constraints", "Deliverable", "Definition of done"):
            self.assertIn(heading + "\n", brief)
        self.assertIn("Young reader", brief)

    def test_accepts_colon_headings(self):
        brief = normalize_brief("Task: Write story\nContext: Young reader\nConstraints: Gentle\nDeliverable: Story\nDefinition of done: Check request", "Write a story")
        self.assertIn("Task\nWrite story", brief)
        self.assertIn("Definition of done\nCheck request", brief)

    def test_falls_back_to_request_for_nonempty_brief(self):
        brief = normalize_brief("A gentle story, no commands", "Write a story")
        self.assertIn("Task\nWrite a story", brief)
        self.assertIn("Context\nA gentle story, no commands", brief)


class DraftWarningTests(unittest.TestCase):
    def test_flags_direct_bedtime_pressure_for_pda_request(self):
        request = "Story for a child with pathological demand avoidance (PDA)"
        self.assertTrue(draft_warnings(request, '"Time for bed! Close your eyes," said Mom.'))
        self.assertTrue(draft_warnings(request, '"Let\'s make sure to get ready every night."'))

    def test_ignores_autonomy_language(self):
        request = "Story for a child with PDA"
        self.assertEqual([], draft_warnings(request, "She didn't have to do anything. She could rest if she wanted to."))

    def test_does_not_apply_pda_rule_to_unrelated_task(self):
        self.assertEqual([], draft_warnings("Compile a Python file", "You should run a check."))


if __name__ == "__main__":
    unittest.main()
