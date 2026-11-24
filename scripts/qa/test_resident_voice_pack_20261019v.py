"""Offline contract checks; no TTS service calls or game state writes."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("resident_voice_pack", ROOT / "scripts/audio/generate_resident_voice_pack.py")
voice_pack = importlib.util.module_from_spec(spec)
spec.loader.exec_module(voice_pack)


class ResidentVoiceContract(unittest.TestCase):
    def setUp(self):
        self.doc = json.loads((ROOT / "assets/specs/luoyang_resident_voice_trial_20261019v.json").read_text(encoding="utf-8"))

    def load(self, doc):
        with tempfile.TemporaryDirectory(prefix="resident_voice_contract_") as folder:
            target = Path(folder) / "input.json"
            target.write_text(json.dumps(doc, ensure_ascii=False), encoding="utf-8")
            return voice_pack.load_manifest(target)

    def test_eight_real_nodes_bound(self):
        lines, digest = self.load(self.doc)
        self.assertEqual(len(lines), 8)
        self.assertEqual(len(digest), 64)
        self.assertEqual(len({row["voice"] for row in lines}), 4)
        self.assertTrue(all(len(row["dialog_source_sha256"]) == 64 for row in lines))

    def test_duplicate_refused(self):
        self.doc["lines"][1]["id"] = self.doc["lines"][0]["id"]
        with self.assertRaises(ValueError):
            self.load(self.doc)

    def test_text_drift_refused(self):
        self.doc["lines"][0]["text"] += "候选漂移"
        with self.assertRaises(ValueError):
            self.load(self.doc)

    def test_node_and_speaker_drift_refused(self):
        for key, value in (("node_id", "absent"), ("speaker", "不符身份"), ("emotion", "happy")):
            doc = copy.deepcopy(self.doc)
            doc["lines"][0][key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                self.load(doc)

    def test_unknown_voice_no_fallback(self):
        self.doc["lines"][0]["voice"] = "unknown"
        with self.assertRaises(ValueError):
            self.load(self.doc)

    def test_path_escape_refused(self):
        self.doc["lines"][0]["dialog_path"] = "../outside.tres"
        with self.assertRaises(ValueError):
            self.load(self.doc)

    def test_extreme_parameters_refused(self):
        self.doc["lines"][0]["character_params"]["pitch"] = "-80Hz"
        with self.assertRaises(ValueError):
            self.load(self.doc)

    def test_cache_key_binds_voice_and_source(self):
        line = self.load(self.doc)[0][0]
        altered = copy.deepcopy(line)
        altered["dialog_source_sha256"] = "0" * 64
        self.assertNotEqual(voice_pack.row_digest(line, "a" * 64), voice_pack.row_digest(altered, "a" * 64))
        altered = copy.deepcopy(line)
        altered["voice"] = "zh-CN-YunxiNeural"
        self.assertNotEqual(voice_pack.row_digest(line, "a" * 64), voice_pack.row_digest(altered, "a" * 64))


if __name__ == "__main__":
    unittest.main(verbosity=2)
