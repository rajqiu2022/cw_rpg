"""Read-only four-static structural successor. No image/engine/formal-art credit."""
import argparse
import hashlib
import itertools
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
MANIFEST = "assets/processed/sprite/luoyang_soldier_diversity_20261019y/mechanical_candidates_v2.json"
MANIFEST_SHA = "c47a802ea377cea7eb6182397878f23ae38fdd8792521f4ffafb74a2fefb5f4c"
IDS = (
    "npc_luoyang_young_gate_sentry_idle_down_1f_v2_weapon_envelope_edit",
    "npc_luoyang_old_veteran_idle_down_1f_v2_weapon_envelope_edit",
    "npc_luoyang_squad_leader_idle_down_1f_v1",
    "npc_luoyang_commander_idle_down_1f_v1",
)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def path(rel):
    candidate = (ROOT / rel).resolve()
    candidate.relative_to(ROOT)
    return candidate


def fact(rel):
    target = path(rel)
    stat = target.stat()
    return {"sha256": digest(target.read_bytes()), "bytes": stat.st_size,
            "mtime_ns_string": str(stat.st_mtime_ns)}


def bbox(image, threshold=0):
    alpha = image.getchannel("A")
    if threshold:
        alpha = alpha.point(lambda value: 255 if value >= threshold else 0)
    result = alpha.getbbox()
    return list(result) if result else None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", required=True)
    args = parser.parse_args()
    report_path = path(args.report)
    report_path.relative_to(ROOT / "game/build/luoyang_soldier_assets_20261019y")
    if report_path.exists():
        raise SystemExit("refusing to overwrite existing evidence")
    checks = []
    sources = {}
    records = []
    images = {}

    def check(value, label, detail=None):
        checks.append({"ok": bool(value), "label": label, "detail": detail})

    def track(rel, expected=None):
        sources[rel] = fact(rel)
        if expected is not None:
            check(sources[rel]["sha256"] == expected, "Exact source SHA " + rel)

    track(str(Path(__file__).resolve().relative_to(ROOT)).replace("\\", "/"))
    track(MANIFEST, MANIFEST_SHA)
    manifest = json.loads(path(MANIFEST).read_text(encoding="utf-8-sig"))
    selected = [row for row in manifest["records"] if row.get("kind") == "static_1f"]
    check(tuple(row["asset_id"] for row in selected) == IDS, "Exact four-static scope/order; no rejected atlas/contact idle")
    for row in selected:
        identity = row["asset_id"]
        track(row["source_path"], row["source_sha256"])
        track(row["output_path"], row["output_sha256"])
        with Image.open(path(row["source_path"])) as opened:
            check(opened.mode == "RGBA", "Raw true RGBA " + identity)
            source = opened.convert("RGBA")
        with Image.open(path(row["output_path"])) as opened:
            check(opened.mode == "RGBA", "Derived true RGBA " + identity)
            derived = opened.convert("RGBA")
        check(list(source.size) == row["source_size"] and source.size[0] == source.size[1], "Actual whole-square source dimensions " + identity)
        check(derived.size == (160, 160) and row["output_size"] == [160, 160], "Exact one square static cell " + identity)
        size = row["frame"]["resize_size"]
        offset = row["frame"]["paste"]
        check(type(size) is int and size > 0 and len(offset) == 2 and all(type(n) is int for n in offset), "Exact integer uniform scale/translation declaration " + identity)
        resized = source.resize((size, size), Image.Resampling.LANCZOS)
        raw_box = bbox(resized)
        shifted = [raw_box[0] + offset[0], raw_box[1] + offset[1], raw_box[2] + offset[0], raw_box[3] + offset[1]]
        check(0 <= shifted[0] < shifted[2] <= 160 and 0 <= shifted[1] < shifted[3] <= 160, "All resized A>0 pixels fit: no alpha clipping " + identity, shifted)
        expected = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
        expected.alpha_composite(resized, tuple(offset))
        check(expected.tobytes() == derived.tobytes(), "Independent whole-canvas uniform Lanczos+translation reproduces every RGBA byte " + identity)
        actual_box = bbox(derived)
        check(actual_box == shifted == row["frame"]["a_gt_0"] and bbox(derived, 16) == row["frame"]["a_ge_16"], "Exact actual alpha extents agree " + identity)
        check(actual_box[1] == 12 and actual_box[3] == 152 and actual_box[3] - actual_box[1] == 140, "Alpha envelope 140px / foot152, not body-height or engine proof " + identity)
        alpha = derived.getchannel("A")
        check(all(alpha.crop(box).getbbox() is None for box in [(0, 0, 160, 1), (0, 159, 160, 160), (0, 0, 1, 160), (159, 0, 160, 160)]), "Four runtime borders wholly transparent " + identity)
        images[identity] = derived
        records.append({"identity": identity, "source": row["source_path"], "derived": row["output_path"], "alpha_box": actual_box, "strong_alpha_box": bbox(derived, 16), "predicted_calibrated_scale_from_alpha_only": 140 / (actual_box[3] - actual_box[1]), "engine_calibration_verified": False})
    for left, right in itertools.combinations(IDS, 2):
        check(images[left].tobytes() != images[right].tobytes(), "Not exact duplicate RGBA " + left + " vs " + right)
        check(images[left].getchannel("A").tobytes() != images[right].getchannel("A").tobytes(), "Not identical silhouette alpha " + left + " vs " + right)
    after = {rel: fact(rel) for rel in sources}
    check(sources == after, "Every finite input source first/final unchanged")
    failed = sum(not item["ok"] for item in checks)
    report = {"scope": "FOUR_STATIC_STRUCTURAL_ASSET_ONLY_NOT_FIELD_OR_FORMAL_ART", "complete": failed == 0, "checks": len(checks), "failures": failed, "records": records, "assertions": checks, "source_before": sources, "source_after": after, "engine_calls": 0, "image_writes": 0, "actual_walk_phase_verified": False, "contact_idle_accepted": False, "portrait_identity_verified": False, "actual_body_height_verified": False, "full_art_pass": False, "original_raw01_fail_retained": True}
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"checks": len(checks), "failures": failed, "report_path": str(report_path), "sha256": digest(report_path.read_bytes())}))
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
