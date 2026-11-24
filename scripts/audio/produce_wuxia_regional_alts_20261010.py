"""Explicit single-seed comparisons after the sealed twenty-track batch."""
from pathlib import Path
import argparse
import json
import sys
import produce_wuxia_stable_personal_continuation as producer
import produce_wuxia_regional_story_bank_20261010 as bank

ROOT = producer.ROOT
SPECIFICATIONS = {
    "bianzhou": ("city_bianzhou", 20261010022, "wuxia_regional_bianzhou_alt_20261010", "wuxia_regional_bianzhou_alt_plan_20261010.json"),
    "village_night": ("village_night", 20261010082, "wuxia_regional_village_night_alt_20261010", "wuxia_regional_village_night_alt_plan_20261010.json"),
    "forest": ("outskirts_forest_xiangzhou", 20261010102, "wuxia_regional_forest_alt_20261010", "wuxia_regional_forest_alt_plan_20261010.json"),
    "story_tension": ("story_tension", 20261010122, "wuxia_regional_story_tension_alt_20261010", "wuxia_regional_story_tension_alt_plan_20261010.json"),
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--theme", choices=tuple(SPECIFICATIONS), required=True)
    args = ap.parse_args()
    track_id, seed, directory, plan_name = SPECIFICATIONS[args.theme]
    RAW = ROOT / "assets/raw/audio" / directory
    PROCESSED = ROOT / "assets/processed/audio" / directory
    PLAN = Path(__file__).with_name(plan_name)
    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    if len(plan["tracks"]) != 1 or plan["tracks"][0]["id"] != track_id or plan["tracks"][0]["seed"] != seed:
        raise ValueError("Fixed ONE comparison plan mismatch")
    original_bank_path = ROOT / "assets/processed/audio/wuxia_regional_story_bank_20261010/manifest.json"
    original_bank = json.loads(original_bank_path.read_text(encoding="utf-8"))
    if len(original_bank["tracks"]) != 20 or len(original_bank.get("loops", [])) != 20:
        raise ValueError("Complete original twenty-track generation and loop phase first")
    preserved_bank = producer.record(original_bank_path)
    producer.PLAN, producer.RAW, producer.PROCESSED = PLAN, RAW, PROCESSED
    runner = producer.record(Path(__file__))
    original_write_json = producer.write_json

    def annotated_write(path, data):
        data["continuation_runner"] = runner
        data["preserved_original_bank_manifest"] = preserved_bank
        original_write_json(path, data)

    producer.write_json = annotated_write
    sys.argv = [sys.argv[0], "--track", "all"]
    producer.main()
    bank.RAW, bank.PROCESSED = RAW, PROCESSED
    track = plan["tracks"][0]
    try:
        loop = bank.make_loop(track)
    except ValueError as error:
        loop = {"status": "LOOP_PROCESSING_FAILED", "track": track,
                "source": producer.record(RAW / (track_id + "_raw.wav")),
                "error": str(error), "automatic_retry": False}
    loop["continuation_runner"] = runner
    loop["selection_io_kernel"] = producer.record(Path(bank.loop_kernel.__file__))
    loop["loop_processing_kernel"] = producer.record(Path(bank.__file__))
    producer.write_json(PROCESSED / (track_id + ".loop.processing.json"), loop)
    manifest_path = PROCESSED / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["loops"] = [loop]
    manifest["no_further_automatic_retry"] = True
    producer.write_json(manifest_path, manifest)
    if producer.record(original_bank_path) != preserved_bank:
        raise ValueError("Original bank manifest changed")


if __name__ == "__main__":
    main()
