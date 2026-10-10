import unittest
from unittest.mock import Mock, patch

import workshop_app
from workshop_app import App, draft_warnings, normalize_brief


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


class HandoffReuseTests(unittest.TestCase):
    def test_existing_window_shows_new_project(self):
        app = App()
        app.address = "http://127.0.0.1:1234/#token=example"
        app.window = Mock()

        self.assertTrue(app.focus_project("new-project"))
        app.window.load_url.assert_called_once_with(app.address + "&project=new-project")
        app.window.restore.assert_called_once_with()
        app.window.show.assert_called_once_with()

    def test_existing_instance_does_not_create_desktop_window(self):
        instance = Mock()
        instance.exists.return_value = True
        instance.read_text.return_value = '{"port": 1234, "token": "example"}'
        response = Mock()
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)

        with patch.object(workshop_app, "INSTANCE", instance), \
             patch.object(workshop_app, "urlopen", return_value=response), \
             patch.object(workshop_app, "request_json", return_value={"id": "new-project", "focused": True}), \
             patch.object(workshop_app, "desktop_window") as create_window, \
             patch.object(workshop_app.webbrowser, "open") as open_browser:
            workshop_app.launch("New objective", handoff=True, desktop=True, origin="codex")

        create_window.assert_not_called()
        open_browser.assert_not_called()

    def test_older_instance_uses_its_server_without_new_desktop_window(self):
        instance = Mock()
        instance.exists.return_value = True
        instance.read_text.return_value = '{"port": 1234, "token": "example"}'
        response = Mock()
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)

        with patch.object(workshop_app, "INSTANCE", instance), \
             patch.object(workshop_app, "urlopen", return_value=response), \
             patch.object(workshop_app, "request_json", return_value={"id": "new-project"}), \
             patch.object(workshop_app, "desktop_window") as create_window, \
             patch.object(workshop_app.webbrowser, "open") as open_browser, \
             patch.object(workshop_app, "serve") as serve:
            workshop_app.launch("New objective", handoff=True, desktop=True, origin="codex")

        create_window.assert_not_called()
        serve.assert_not_called()
        open_browser.assert_called_once_with("http://127.0.0.1:1234/#token=example&project=new-project")

    def test_no_instance_starts_server(self):
        with patch.object(workshop_app, "INSTANCE") as instance, \
             patch.object(workshop_app, "serve") as serve:
            instance.exists.return_value = False
            workshop_app.launch("New objective", handoff=True, desktop=True, origin="codex")

        serve.assert_called_once()
        self.assertEqual("New objective", serve.call_args.kwargs["initial"])
        self.assertTrue(serve.call_args.kwargs["desktop"])

    def test_handoff_error_does_not_start_another_instance(self):
        instance = Mock()
        instance.exists.return_value = True
        instance.read_text.return_value = '{"port": 1234, "token": "example"}'
        response = Mock()
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)

        with patch.object(workshop_app, "INSTANCE", instance), \
             patch.object(workshop_app, "urlopen", return_value=response), \
             patch.object(workshop_app, "request_json", side_effect=RuntimeError("handoff failed")), \
             patch.object(workshop_app, "serve") as serve:
            with self.assertRaisesRegex(RuntimeError, "handoff failed"):
                workshop_app.launch("New objective", handoff=True, desktop=True, origin="codex")

        serve.assert_not_called()


if __name__ == "__main__":
    unittest.main()
