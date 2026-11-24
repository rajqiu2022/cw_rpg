"""Deterministic y soldier candidate normalization; never edits raw sources.

Static: one global uniform resize of the complete raw canvas, then transparent padding.
Atlas: exact 2x NEAREST of the whole 1774x887 raw to resolve half-pixel 4x2 cells,
then one shared uniform scale for all eight 887x887 cells and baseline translation.
No alpha threshold is used to erase pixels; A>=16 is measurement-only centering data.
"""
import hashlib
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "assets/raw/luoyang_soldier_diversity_20261019y"
PROCESSED = ROOT / "assets/processed/sprite/luoyang_soldier_diversity_20261019y"
PREVIEWS = ROOT / "assets/previews/sprite/luoyang_soldier_diversity_20261019y"
TARGET = 160
TARGET_FOOT_END = 152
TARGET_FRAME0_A0_HEIGHT = 140

STATIC = [
    "npc_luoyang_young_gate_sentry_idle_down_1f_v2_weapon_envelope_edit",
    "npc_luoyang_old_veteran_idle_down_1f_v2_weapon_envelope_edit",
    "npc_luoyang_squad_leader_idle_down_1f_v1",
    "npc_luoyang_commander_idle_down_1f_v1",
]
ATLASES = [
    "npc_luoyang_mature_patrol_walk_right_8f_atlas_v1",
    "npc_luoyang_archer_walk_right_8f_atlas_v1",
]

WALK_ART_VERDICTS = {
    "npc_luoyang_mature_patrol_walk_right_8f_atlas_v1": "REJECTED_AS_TRUE_8_PHASE_AND_IDLE: repeated forward-foot poses read as a near-four-pose loop",
    "npc_luoyang_archer_walk_right_8f_atlas_v1": "REJECTED_AS_TRUE_8_PHASE_AND_IDLE: too many frames retain the same forward-foot pose",
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def alpha_bbox(image: Image.Image, threshold: int = 0):
    alpha = image.getchannel("A")
    if threshold == 0:
        return alpha.getbbox()
    return alpha.point(lambda value: 255 if value >= threshold else 0).getbbox()


def choose_resize_size(image: Image.Image, target_height: int) -> int:
    source_bbox = alpha_bbox(image, 0)
    if source_bbox is None:
        raise ValueError("empty image")
    estimate = round(image.height * target_height / (source_bbox[3] - source_bbox[1]))
    candidates = []
    # Low-alpha source residue can vanish under LANCZOS at the first estimate.
    # Search a bounded wider interval, but still choose one uniform full-canvas scale.
    for size in range(max(1, estimate - 16), estimate + 17):
        resized = image.resize((size, size), Image.Resampling.LANCZOS)
        bbox = alpha_bbox(resized, 0)
        height = 0 if bbox is None else bbox[3] - bbox[1]
        candidates.append((abs(height - target_height), abs(size - estimate), size, height))
    candidates.sort()
    return candidates[0][2]


def place_frame(image: Image.Image, resize_size: int):
    resized = image.resize((resize_size, resize_size), Image.Resampling.LANCZOS)
    a0 = alpha_bbox(resized, 0)
    strong = alpha_bbox(resized, 16)
    if a0 is None or strong is None:
        raise ValueError("missing alpha content")
    center_x = (strong[0] + strong[2]) / 2.0
    paste_x = round(TARGET / 2.0 - center_x)
    paste_y = TARGET_FOOT_END - a0[3]
    transformed = [paste_x + a0[0], paste_y + a0[1], paste_x + a0[2], paste_y + a0[3]]
    if transformed[0] < 0 or transformed[1] < 0 or transformed[2] > TARGET or transformed[3] > TARGET:
        raise ValueError(f"nonzero alpha would clip: {transformed}")
    canvas = Image.new("RGBA", (TARGET, TARGET), (0, 0, 0, 0))
    canvas.alpha_composite(resized, (paste_x, paste_y))
    return canvas, {"resize_size": resize_size, "a_gt_0": list(alpha_bbox(canvas, 0)), "a_ge_16": list(alpha_bbox(canvas, 16)), "paste": [paste_x, paste_y]}


def process_static(asset_id: str):
    source_path = RAW / f"{asset_id}.png"
    source = Image.open(source_path).convert("RGBA")
    resize_size = choose_resize_size(source, TARGET_FRAME0_A0_HEIGHT)
    frame, metrics = place_frame(source, resize_size)
    output_path = PROCESSED / f"{asset_id}_runtime.png"
    frame.save(output_path, format="PNG")
    return {
        "asset_id": asset_id,
        "kind": "static_1f",
        "source_path": str(source_path.relative_to(ROOT)).replace("\\", "/"),
        "source_sha256": sha(source_path),
        "source_size": list(source.size),
        "operation": "uniform full-canvas LANCZOS then transparent translation/padding; no crop, paint or alpha threshold",
        "frame": metrics,
        "output_path": str(output_path.relative_to(ROOT)).replace("\\", "/"),
        "output_sha256": sha(output_path),
        "output_size": list(frame.size),
    }


def process_atlas(asset_id: str):
    source_path = RAW / f"{asset_id}.png"
    source = Image.open(source_path).convert("RGBA")
    if source.size != (1774, 887):
        raise ValueError(f"unexpected atlas size {source.size}")
    doubled = source.resize((3548, 1774), Image.Resampling.NEAREST)
    # Prove the grid-resolution step is pure 2x2 pixel replication.
    probe = doubled.resize(source.size, Image.Resampling.NEAREST)
    if probe.tobytes() != source.tobytes():
        raise ValueError("2x NEAREST round-trip changed RGBA")
    cells = []
    for index in range(8):
        x = (index % 4) * 887
        y = (index // 4) * 887
        cells.append(doubled.crop((x, y, x + 887, y + 887)))
    shared_resize_size = choose_resize_size(cells[0], TARGET_FRAME0_A0_HEIGHT)
    frames = []
    metrics = []
    for index, cell in enumerate(cells):
        frame, row = place_frame(cell, shared_resize_size)
        row["frame"] = index
        frames.append(frame)
        metrics.append(row)
    strip = Image.new("RGBA", (TARGET * 8, TARGET), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        strip.alpha_composite(frame, (index * TARGET, 0))
    runtime_stem = asset_id.replace("_atlas", "")
    output_path = PROCESSED / f"{runtime_stem}_runtime.png"
    idle_path = PROCESSED / f"{runtime_stem}_frame0_contact_idle_candidate.png"
    preview_path = PREVIEWS / f"{runtime_stem}_120ms_preview.gif"
    strip.save(output_path, format="PNG")
    frames[0].save(idle_path, format="PNG")
    frames[0].save(preview_path, save_all=True, append_images=frames[1:], duration=120, loop=0, disposal=2, transparency=0)
    return {
        "asset_id": asset_id,
        "kind": "walk_right_8f",
        "source_path": str(source_path.relative_to(ROOT)).replace("\\", "/"),
        "source_sha256": sha(source_path),
        "source_size": list(source.size),
        "grid_resolution": "whole raw 2x NEAREST to 3548x1774, exact 4x2 cells of 887x887; round-trip RGBA exact",
        "operation": "one shared uniform LANCZOS size for all frames; per-frame translation only; no fit-per-frame scale, crop, paint or alpha threshold",
        "shared_resize_size": shared_resize_size,
        "frames": metrics,
        "output_path": str(output_path.relative_to(ROOT)).replace("\\", "/"),
        "output_sha256": sha(output_path),
        "output_size": list(strip.size),
        "idle_candidate_path": str(idle_path.relative_to(ROOT)).replace("\\", "/"),
        "idle_candidate_sha256": sha(idle_path),
        "preview_path": str(preview_path.relative_to(ROOT)).replace("\\", "/"),
        "preview_sha256": sha(preview_path),
        "preview_duration_ms": 120,
        "walk_phase_and_idle_approval": WALK_ART_VERDICTS[asset_id],
    }


def main():
    PROCESSED.mkdir(parents=True, exist_ok=True)
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    records = [process_static(asset_id) for asset_id in STATIC]
    records.extend(process_atlas(asset_id) for asset_id in ATLASES)
    static_preview = Image.new("RGBA", (TARGET * len(STATIC), TARGET), (0, 0, 0, 0))
    for index, record in enumerate(records[: len(STATIC)]):
        candidate = Image.open(ROOT / record["output_path"]).convert("RGBA")
        static_preview.alpha_composite(candidate, (index * TARGET, 0))
    static_preview_path = PREVIEWS / "four_static_candidates_actual_pixels.png"
    static_preview.save(static_preview_path, format="PNG")
    report = {
        "kind": "LUOYANG_SOLDIER_MECHANICAL_CANDIDATES_NOT_RUNTIME_OR_FORMAL",
        "target": {"cell_px": [160, 160], "frame0_a_gt_0_height": 140, "foot_bbox_end_y": 152},
        "raw_modified": False,
        "alpha_threshold_used_for_deletion": False,
        "engine_calls": 0,
        "batch_art_decision": {
            "four_static_candidates": "ACCEPTED_AS_ASSET_CANDIDATES_ONLY: young sentry, old veteran, squad leader and commander are role-readable at a common 160px cell scale",
            "same_identity_review": "Root visually compared both targeted edits to their exact v1 references and accepted identity/clothing continuity; this is an art review, not pixel identity proof",
            "walk_candidates": "REJECTED_FOR_RUNTIME: neither generated atlas is accepted as a true eight-phase loop or as a contact-idle source",
            "runtime_import_field_formal_credit": False,
        },
        "four_static_actual_pixel_preview": {
            "path": str(static_preview_path.relative_to(ROOT)).replace("\\", "/"),
            "sha256": sha(static_preview_path),
            "size": list(static_preview.size),
            "composition": "four unchanged 160x160 derived candidates placed side by side without further scaling",
        },
        "records": records,
    }
    report_path = PROCESSED / "mechanical_candidates_v2.json"
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"report": str(report_path.relative_to(ROOT)).replace("\\", "/"), "sha256": sha(report_path), "records": len(records)}, indent=2))


if __name__ == "__main__":
    main()
