"""Twenty authorized offline CPU BGM additions; sealed kernels remain unchanged.

Each fixed seed runs once through the proven per-track subprocess pipeline.
Only NEW expansion directories are written. No runtime/game adoption or models
downloaded; numeric loop candidates require later human listening.
"""
from pathlib import Path
import json
import time
import produce_wuxia_regional_story_bank_20261010 as bank

ROOT = bank.ROOT
RAW = ROOT / "assets/raw/audio/wuxia_expansion_20261022"
PROCESSED = ROOT / "assets/processed/audio/wuxia_expansion_20261022"
PLAN = Path(__file__).with_name("wuxia_expansion_plan_20261022.json")


def main():
    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    if len(plan["tracks"]) != 20 or len({t["seed"] for t in plan["tracks"]}) != 20:
        raise SystemExit("Expected twenty unique fixed seeds")
    if any(p.exists() and any(p.iterdir()) for p in (RAW, PROCESSED)):
        raise SystemExit("Preserving an existing expansion attempt")
    runner = bank.producer.record(Path(__file__))
    plan_record = bank.producer.record(PLAN)
    original_write = bank.producer.write_json
    started = time.time()

    def write_with_entry(path, data):
        data["continuation_runner"] = runner
        data["frozen_bank_kernel"] = bank.producer.record(Path(bank.__file__))
        data["execution_mode"] = "One proven official CPU subprocess per track; sequential; no automatic retries"
        original_write(path, data)

    bank.producer.write_json = write_with_entry
    bank.RAW, bank.PROCESSED, bank.PLAN = RAW, PROCESSED, PLAN
    bank.main()
    if bank.producer.record(Path(__file__)) != runner or bank.producer.record(PLAN) != plan_record:
        raise RuntimeError("Entry source or fixed plan changed during generation")
    metas = [json.loads(p.read_text(encoding="utf-8")) for p in sorted(RAW.glob("*.meta.json"))]
    write_with_entry(PROCESSED / "batch_execution_20261022.json", {
        "status": "TWENTY_RAW_FULL_PREVIEW_AND_LOOP_CANDIDATES_COMPLETE",
        "plan": plan_record, "total_wall_seconds": time.time() - started,
        "track_count": len(metas),
        "inference_wall_seconds": {m["id"]: m["wall_seconds"] for m in metas},
        "actual_exit_codes": {m["id"]: m["inference_exit_code"] for m in metas},
        "game_integration": "NONE", "listening": "PENDING",
        "new_model_downloads": False, "gpu_used": False,
    })


if __name__ == "__main__":
    main()
