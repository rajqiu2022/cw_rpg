"""One authorized journey comparison; reuses the sealed batch kernel unchanged."""
import json
from pathlib import Path
import produce_wuxia_stable_personal_continuation as producer

ROOT = producer.ROOT
PLAN = Path(__file__).with_name("wuxia_stable_personal_journey_alt_plan_20261009.json")
RAW = ROOT / "assets/raw/audio/wuxia_stable_personal_journey_alt_20261009"
PROCESSED = ROOT / "assets/processed/audio/wuxia_stable_personal_journey_alt_20261009"


def main():
    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    assert len(plan["tracks"]) == 1
    assert plan["tracks"][0]["id"] == "jianghu_continuous_96s"
    assert plan["tracks"][0]["seed"] == 20261009122
    producer.PLAN, producer.RAW, producer.PROCESSED = PLAN, RAW, PROCESSED
    original_write_json = producer.write_json
    runner_record = producer.record(Path(__file__))

    def annotate_write_json(path, data):
        data["continuation_runner"] = runner_record
        original_write_json(path, data)

    # In-memory only: record the actual runner even in RUNNING/FAILED metadata.
    producer.write_json = annotate_write_json
    producer.main()


if __name__ == "__main__":
    main()
