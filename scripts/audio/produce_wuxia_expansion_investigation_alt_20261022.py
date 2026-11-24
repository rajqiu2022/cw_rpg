"""One explicitly authorized investigation contrast; no automatic retries.

Run after the fixed original twenty-track process has naturally completed.
Only this NEW alternative directory is written; the original bank is immutable.
"""
from pathlib import Path
import json
import sys
import produce_wuxia_stable_personal_continuation as producer
import produce_wuxia_regional_story_bank_20261010 as bank

ROOT = producer.ROOT
RAW = ROOT / "assets/raw/audio/wuxia_expansion_investigation_alt_20261022"
PROCESSED = ROOT / "assets/processed/audio/wuxia_expansion_investigation_alt_20261022"
PLAN = Path(__file__).with_name("wuxia_expansion_investigation_alt_plan_20261022.json")
ORIGINAL = ROOT / "assets/processed/audio/wuxia_expansion_20261022/manifest.json"


def main():
    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    if len(plan["tracks"]) != 1 or plan["tracks"][0]["seed"] != 2026102251 or plan["tracks"][0]["seconds"] != 96:
        raise SystemExit("Only the one authorized fixed alternative")
    original = producer.record(ORIGINAL)
    old = json.loads(ORIGINAL.read_text(encoding="utf-8"))
    if len(old["tracks"]) != 20 or len(old["loops"]) != 20:
        raise SystemExit("Original twenty full and loop phases must finish first")
    if any(p.exists() and any(p.iterdir()) for p in (RAW, PROCESSED)):
        raise SystemExit("Existing alternative preserved")
    runner = producer.record(Path(__file__))
    original_write = producer.write_json

    def write_with_entry(path, data):
        data["continuation_runner"] = runner
        data["preserved_original_twenty_manifest"] = original
        original_write(path, data)

    producer.PLAN, producer.RAW, producer.PROCESSED = PLAN, RAW, PROCESSED
    producer.write_json = write_with_entry
    sys.argv = [sys.argv[0], "--track", "all"]
    producer.main()
    bank.RAW, bank.PROCESSED = RAW, PROCESSED
    result = bank.make_loop(plan["tracks"][0])
    result["continuation_runner"] = runner
    result["selection_io_kernel"] = producer.record(Path(bank.loop_kernel.__file__))
    write_with_entry(PROCESSED / "story_investigation_threads.loop.processing.json", result)
    manifest_path = PROCESSED / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest.update({"loops": [result], "model_attempt_count": 1,
                     "selection_status": "INDEPENDENT_QA_AND_LISTENING_PENDING", "game_integration": "NONE"})
    write_with_entry(manifest_path, manifest)
    if producer.record(ORIGINAL) != original:
        raise RuntimeError("Original twenty manifest changed")
    print("ONE_INVESTIGATION_ALT_COMPLETE", result["loop"]["loop_seconds"], flush=True)


if __name__ == "__main__":
    main()
