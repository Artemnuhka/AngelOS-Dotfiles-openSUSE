#!/usr/bin/env python3
"""Offline integration tests: provider protocol, drafts, validation and install."""
import copy
import importlib.util
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest
import urllib.error
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
WORKER = ROOT / ".config/quickshell/angelos/scripts/plugin-studio.py"
spec = importlib.util.spec_from_file_location("studio", WORKER)
studio = importlib.util.module_from_spec(spec)
spec.loader.exec_module(studio)

PLAN = {
    "summary": "A small counter that follows the angelOS theme.",
    "questions": [],
    "spec": {
        "id": "studio-test-counter", "name": "Counter", "description": "A test widget",
        "kind": "desktop", "widthUnits": 150, "heightUnits": 80,
        "behavior": "Click to increment. Saved in plugin settings.",
        "dataSources": ["Local plugin settings"], "settings": ["Label"],
        "dependencies": [], "limitations": [],
    },
}
DESKTOP = """import QtQuick
import qs.config
import qs.widgets
Item {
    id: root
    property var plugin
    property string screenName
    property var widget
    implicitWidth: Theme.u * 150
    implicitHeight: Theme.u * 80
    PxButton {
        anchors.centerIn: parent
        text: I18n.t("Кликов: ", "Clicks: ") + (root.plugin ? root.plugin.get("count", 0) : 0)
        onClicked: if (root.plugin) root.plugin.set("count", root.plugin.get("count", 0) + 1)
    }
}
"""
SETTINGS = """import QtQuick
import qs.config
import qs.widgets
Column {
    id: root
    property var plugin
    spacing: Theme.u * 4
    PxText { text: I18n.t("Счётчик", "Counter") }
    PxButton {
        text: I18n.t("Сбросить", "Reset")
        onClicked: if (root.plugin) root.plugin.set("count", 0)
    }
}
"""
BUNDLE = {
    "summary": "Counter ready for review.", "notes": [],
    "files": [
        {"path": "manifest.json", "content": json.dumps({
            "id": PLAN["spec"]["id"], "name": "Counter", "version": "1.0.0",
            "description": "A themed counter", "icon": "heart",
            "enabledByDefault": False, "desktopWidget": "DesktopWidget.qml",
            "settings": "Settings.qml", "desktopTitle": "counter.exe",
        })},
        {"path": "DesktopWidget.qml", "content": DESKTOP},
        {"path": "Settings.qml", "content": SETTINGS},
        {"path": "README.md", "content": "# Counter\nClick to increment.\nКликни для увеличения."},
    ],
}


class StudioTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="angelos-studio-test-")
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.calls = []
        self.timeouts = []
        self.reply = PLAN
        self.worker = studio.Studio(self.home, api=self.fake_api)
        self.worker.config.mkdir(parents=True)
        self.settings = self.worker.config / "settings.json"
        self.settings.write_text('{"developer":{"enabled":true}}')
        self.request("save_key", key="test-only-placeholder-credential")

    def fake_api(self, wire, provider, timeout):
        self.calls.append((wire, provider))
        self.timeouts.append(timeout)
        return copy.deepcopy(self.reply), {"input_tokens": 100, "output_tokens": 200}

    def request(self, action, **extra):
        return self.worker.dispatch({
            "action": action, "provider": "openai", "model": "gpt-5.4",
            "language": "en", "maxOutputTokens": 16000, **extra,
        })

    def generate(self, bundle=None):
        self.request("plan", prompt="A desktop counter, please")
        self.reply = bundle or BUNDLE
        return self.request("generate")["session"]["draft"]

    def test_complete_flow_and_no_execution_before_install(self):
        draft = self.generate()
        self.assertTrue(self.timeouts)
        self.assertTrue(all(timeout > 0 for timeout in self.timeouts))
        self.assertEqual(draft["errors"], [])
        self.assertFalse((self.worker.plugins / PLAN["spec"]["id"]).exists())
        result = self.request("install", digest=draft["digest"])
        installed = Path(result["installed"]["directory"])
        self.assertEqual((installed / "DesktopWidget.qml").read_text(), DESKTOP)
        self.assertFalse(json.loads((installed / "manifest.json").read_text())["enabledByDefault"])
        self.assertEqual(result["session"]["installed"], PLAN["spec"]["id"])
        with self.assertRaises(studio.StudioError):
            self.request("install", digest=draft["digest"])
        # Starting another idea cannot remove an installed plugin.
        self.request("reset")
        self.assertTrue(installed.exists())

    def test_plan_questions_block_generation(self):
        self.reply = copy.deepcopy(PLAN)
        self.reply["questions"] = [{"question": "Where?", "options": ["Desktop", "Bar"]}]
        self.request("plan", prompt="A counter")
        with self.assertRaises(studio.StudioError):
            self.request("generate")
        self.assertEqual(len(self.calls), 1)

    def test_followup_and_original_request_reach_generation(self):
        self.request("plan", prompt="Counter named Rainbow")
        self.request("plan", prompt="Reset on right click")
        self.reply = BUNDLE
        self.request("generate")
        body = json.loads(self.calls[-1][0].data)
        self.assertIn("Rainbow", json.dumps(body["input"]))
        self.assertIn("Reset on right click", json.dumps(body["input"]))
        self.assertNotIn("test-only-placeholder-credential", self.calls[-1][0].data.decode())

    def test_keys_private_and_status_redacted(self):
        self.assertEqual(stat.S_IMODE(self.worker.keys.stat().st_mode), 0o600)
        self.assertEqual(stat.S_IMODE(self.worker.keys.parent.stat().st_mode), 0o700)
        status = self.request("status")
        self.assertEqual(status["keys"], {"openai": True, "anthropic": False})
        self.assertNotIn("test-only-placeholder-credential", json.dumps(status))
        self.request("delete_key")
        with self.assertRaises(studio.StudioError):
            self.request("plan", prompt="counter")

    def test_developer_gate_and_existing_plugin_preserved(self):
        draft = self.generate()
        self.settings.write_text('{"developer":{"enabled":false}}')
        for action in ("plan", "generate", "install", "save_key", "reset"):
            with self.subTest(action=action), self.assertRaises(studio.StudioError):
                self.request(action, prompt="anything", digest=draft["digest"])
        self.assertTrue(self.request("status")["session"]["draft"])

    def test_collision_never_overwrites_plugin(self):
        draft = self.generate()
        destination = self.worker.plugins / PLAN["spec"]["id"]
        destination.mkdir(parents=True)
        (destination / "keep.txt").write_text("existing")
        with self.assertRaises(studio.StudioError):
            self.request("install", digest=draft["digest"])
        self.assertEqual((destination / "keep.txt").read_text(), "existing")

    def test_external_edit_requires_new_review(self):
        draft = self.generate()
        target = Path(draft["directory"]) / "README.md"
        target.write_text("# Edited\nReview this change.")
        with self.assertRaises(studio.StudioError):
            self.request("install", digest=draft["digest"])
        reviewed = self.request("review")["session"]["draft"]
        self.assertNotEqual(reviewed["digest"], draft["digest"])
        self.request("install", digest=reviewed["digest"])

    def test_invalid_qml_can_be_repaired(self):
        broken = copy.deepcopy(BUNDLE)
        broken["files"][1]["content"] += "\nItem { broken syntax"
        draft = self.generate(broken)
        self.assertTrue(draft["errors"])
        with self.assertRaises(studio.StudioError):
            self.request("install", digest=draft["digest"])
        self.reply = BUNDLE
        fixed = self.request("generate")["session"]["draft"]
        self.assertEqual(fixed["errors"], [])
        self.assertIn("broken syntax", self.calls[-1][0].data.decode())

    def test_path_traversal_duplicates_and_limits(self):
        for path in ("../escape.qml", "/tmp/escape.qml", "a/../../escape.qml",
                     "a//b.qml", ".hidden.qml", "a\\b.qml", "a/b.exe"):
            with self.subTest(path=path):
                bundle = copy.deepcopy(BUNDLE)
                bundle["files"][1]["path"] = path
                with self.assertRaises(studio.StudioError):
                    studio.bundle_files(bundle)
        duplicate = copy.deepcopy(BUNDLE)
        duplicate["files"].append(duplicate["files"][0])
        with self.assertRaises(studio.StudioError):
            studio.bundle_files(duplicate)
        oversized = copy.deepcopy(BUNDLE)
        oversized["files"][1]["content"] = "x" * (studio.MAX_BYTES + 1)
        with self.assertRaises(studio.StudioError):
            studio.bundle_files(oversized)

    def test_symlink_in_draft_refused(self):
        draft = self.generate()
        target = Path(draft["directory"]) / "README.md"
        target.unlink()
        target.symlink_to(self.settings)
        with self.assertRaises(studio.StudioError):
            self.request("install", digest=draft["digest"])

    def test_secret_in_prompt_or_bundle_refused(self):
        with self.assertRaises(studio.StudioError):
            self.request("plan", prompt="Use test-only-placeholder-credential")
        self.request("plan", prompt="counter")
        self.reply = copy.deepcopy(BUNDLE)
        self.reply["files"][-1]["content"] = "test-only-placeholder-credential"
        with self.assertRaises(studio.StudioError):
            self.request("generate")
        self.assertIsNone(self.worker.session()["draft"])

    def test_arbitrary_script_is_parsed_not_executed(self):
        bundle = copy.deepcopy(BUNDLE)
        marker = self.home / "must-not-exist"
        bundle["files"].append({"path": "helper.py", "content":
                               f"from pathlib import Path\nPath({str(marker)!r}).write_text('bad')\n"})
        draft = self.generate(bundle)
        self.assertEqual(draft["errors"], [])
        self.request("install", digest=draft["digest"])
        self.assertFalse(marker.exists())

    def test_worker_stdin_protocol(self):
        result = subprocess.run(["python3", str(WORKER)], input=json.dumps({
            "action": "status", "language": "en",
        }) + "\n", text=True, capture_output=True,
            env={**os.environ, "HOME": str(self.home)}, timeout=5)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stderr, "")
        self.assertEqual(json.loads(result.stdout)["event"], "result")
        self.assertNotIn("test-only-placeholder-credential", result.stdout)

    def test_runtime_sandbox_setup_failure_is_not_plugin_failure(self):
        directory = self.worker.state / "runtime-fixture"
        directory.mkdir(parents=True)
        (directory / "DesktopWidget.qml").write_text("import QtQuick\nItem {}\n")
        failed = subprocess.CompletedProcess(
            args=["bwrap"], returncode=1, stdout="",
            stderr="bwrap: loopback: Failed to create NETLINK_ROUTE socket",
        )
        with patch.object(studio, "quickshell_binary", return_value=("/bin/true", {}, [])), \
             patch.object(studio.subprocess, "run", return_value=failed):
            errors, note = self.worker.runtime_check(
                directory, {"id": "runtime-test", "desktopWidget": "DesktopWidget.qml"})
        self.assertEqual(errors, [])
        self.assertIn("skipped", note)


class ProviderTest(unittest.TestCase):
    def test_both_wire_formats(self):
        messages = [{"role": "user", "content": "counter"}]
        for provider in ("openai", "anthropic"):
            wire = studio.provider_request(provider, "model-id", "fake-key", "rules", messages, studio.PLAN, 4000)
            body = json.loads(wire.data)
            self.assertTrue(wire.full_url.startswith("https://api."))
            self.assertNotIn("fake-key", wire.data.decode())
            if provider == "openai":
                self.assertEqual(wire.full_url, "https://api.openai.com/v1/responses")
                self.assertFalse(body["store"])
                self.assertTrue(body["text"]["format"]["strict"])
                self.assertEqual(body["input"], messages)
            else:
                self.assertEqual(wire.full_url, "https://api.anthropic.com/v1/messages")
                self.assertEqual(body["output_config"]["format"]["schema"], studio.PLAN)
                self.assertEqual(body["messages"], messages)

    def test_response_parsing_and_truncation(self):
        text = json.dumps(PLAN)
        openai = {"status": "completed", "output": [
            {"type": "reasoning", "summary": []},
            {"type": "message", "content": [{"type": "output_text", "text": text}]},
        ]}
        anthropic = {"stop_reason": "end_turn", "content": [
            {"type": "thinking", "thinking": "not returned to UI"},
            {"type": "text", "text": text},
        ]}
        self.assertEqual(studio.parse_response("openai", openai)[0], PLAN)
        self.assertEqual(studio.parse_response("anthropic", anthropic)[0], PLAN)
        openai["status"] = "incomplete"
        anthropic["stop_reason"] = "max_tokens"
        for provider, data in (("openai", openai), ("anthropic", anthropic)):
            with self.subTest(provider=provider), self.assertRaises(studio.StudioError):
                studio.parse_response(provider, data)

    def test_http_errors_do_not_leak_body(self):
        for code in (400, 401, 403, 404, 429, 500):
            with self.subTest(code=code), patch.object(studio.urllib.request, "build_opener") as opener:
                opener.return_value.open.side_effect = urllib.error.HTTPError(
                    "https://api.openai.com/v1/responses", code, "secret-body", {}, None)
                with self.assertRaises(studio.StudioError) as raised:
                    studio.call_provider(None, "openai")
                self.assertIn(str(code), str(raised.exception))
                self.assertNotIn("secret-body", str(raised.exception))

    def test_redirects_never_forward_credentials(self):
        self.assertIsNone(studio.NoRedirect().redirect_request(
            None, None, 307, "", {}, "https://other.example/"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
