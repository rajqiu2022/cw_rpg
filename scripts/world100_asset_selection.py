"""Resolve current visual candidates without rewriting original generation receipts."""
import json
from pathlib import Path


def select_assets(root: Path, assets: list[dict]) -> tuple[list[dict], list[dict]]:
    current = [r for r in assets if r.get("sha256")]
    history = []
    base = root / "assets/raw/world_expansion_100_20261022"
    corrections, review = base / "corrections.json", base / "xueying_correction_review.json"
    if corrections.is_file() and review.is_file() and json.loads(review.read_text("utf-8")).get("current_candidate"):
        for corrected in json.loads(corrections.read_text("utf-8"))["assets"]:
            index = next(i for i, r in enumerate(current) if r["id"] == corrected["parent_id"])
            history.append({**current[index], "selection_status": "rejected_weapon_mismatch", "superseded_by": corrected["id"]})
            current[index] = {**corrected, "selection_status": "current_candidate_not_runtime"}
    return current, history
