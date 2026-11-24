"""Write measured provenance metadata for the eight completed y raw source files.

This is metadata-only: it does not rewrite, crop, threshold, or otherwise edit PNGs.
"""
import hashlib
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "prompts/luoyang_soldier_diversity_20261019y"
RAW = ROOT / "assets/raw/luoyang_soldier_diversity_20261019y"
GENERATED = Path("C:/Users/rajqiu/.codex/generated_images/019ff02b-0e55-70f3-82bb-5e5410641bf8")

RECORDS = [
    {
        "stem": "npc_luoyang_young_gate_sentry_idle_down_1f_v1",
        "external": "exec-6c8e7573-a2e5-4a90-85e3-40dd1b8defb3.png",
        "status": "GENERATED_SOURCE_IDENTITY_ACCEPTED_RUNTIME_NORMALIZATION_BLOCKED_BY_SPEAR_EXTENT",
        "art_review": "young blue-grey gate sentry identity accepted; original tall spear prevents body140 plus whole-weapon 160px fit",
        "runtime_decision": "source-only; superseded for normalization by the measured-cause v2 weapon-envelope edit",
    },
    {
        "stem": "npc_luoyang_mature_patrol_walk_right_8f_atlas_v1",
        "external": "exec-62e32bea-4083-453c-9764-ed81ac7f4e1f.png",
        "status": "GENERATED_SOURCE_RAW_GRID_FAIL_MECHANICAL_SUCCESSOR_READY_WALK_REVIEW_PENDING",
        "art_review": "mature saber patrol identity accepted; apparent four-pose near-repeat requires human gait review",
        "runtime_decision": "raw 1774x887 integer-grid contract remains failed; lossless 2x-nearest grid successor exists but is not runtime-authorized",
    },
    {
        "stem": "npc_luoyang_old_veteran_idle_down_1f_v1",
        "external": "exec-c284c4af-11de-4976-85a8-19a9671a1293.png",
        "status": "GENERATED_SOURCE_IDENTITY_ACCEPTED_RAW_BORDER_FAIL",
        "art_review": "old grey-bearded patched veteran identity accepted; original spear reaches strong-alpha source top",
        "runtime_decision": "source-only; superseded for normalization by the measured-cause v2 weapon-envelope edit",
    },
    {
        "stem": "npc_luoyang_archer_walk_right_8f_atlas_v1",
        "external": "exec-d50c2064-1c3b-4c69-a66b-ca48725b7e5d.png",
        "status": "GENERATED_SOURCE_RAW_GRID_FAIL_MECHANICAL_SUCCESSOR_READY_WALK_REVIEW_PENDING",
        "art_review": "moss-green bow-and-quiver archer identity accepted; walk reads better than patrol but still requires human phase review",
        "runtime_decision": "raw 1774x887 integer-grid contract remains failed; lossless 2x-nearest grid successor exists but is not runtime-authorized",
    },
    {
        "stem": "npc_luoyang_squad_leader_idle_down_1f_v1",
        "external": "exec-e01b9d1b-734d-464b-96fc-eac42a999860.png",
        "status": "GENERATED_SOURCE_IDENTITY_ACCEPTED_MECHANICAL_CANDIDATE_READY",
        "art_review": "steel-blue compact squad-leader identity accepted",
        "runtime_decision": "mechanical 160px candidate exists; no import, Field, or formal binding credit",
    },
    {
        "stem": "npc_luoyang_commander_idle_down_1f_v1",
        "external": "exec-f1e62fdb-c7b8-470e-8e2e-8b094f52cbeb.png",
        "status": "GENERATED_SOURCE_IDENTITY_ACCEPTED_MECHANICAL_CANDIDATE_READY",
        "art_review": "dark-red armoured broad commander identity accepted",
        "runtime_decision": "mechanical 160px candidate exists; no import, Field, or formal binding credit",
    },
    {
        "stem": "npc_luoyang_young_gate_sentry_idle_down_1f_v2_weapon_envelope_edit",
        "external": "exec-ba048df2-eb18-4d22-9571-2aa904544970.png",
        "status": "GENERATED_TARGETED_EDIT_IDENTITY_PRESERVED_WEAPON_ENVELOPE_FIXED",
        "art_review": "same young sentry identity and clothes retained; short spear is contained between cap and boot envelope",
        "runtime_decision": "actual raw border and weapon envelope pass for mechanical normalization; no import, Field, or formal binding credit",
        "reference": "npc_luoyang_young_gate_sentry_idle_down_1f_v1",
    },
    {
        "stem": "npc_luoyang_old_veteran_idle_down_1f_v2_weapon_envelope_edit",
        "external": "exec-cb3bf085-b1f5-49fe-86cc-ca37a59f2797.png",
        "status": "GENERATED_TARGETED_EDIT_IDENTITY_PRESERVED_WEAPON_ENVELOPE_FIXED",
        "art_review": "same old veteran identity, beard, patches and stance retained; tall spear replaced by waist-sheathed plain dao",
        "runtime_decision": "actual raw border and weapon envelope pass for mechanical normalization; no import, Field, or formal binding credit",
        "reference": "npc_luoyang_old_veteran_idle_down_1f_v1",
    },
]


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def bbox(alpha: Image.Image, threshold: int):
    if threshold <= 0:
        value = alpha.getbbox()
    else:
        value = alpha.point(lambda pixel: 255 if pixel >= threshold else 0).getbbox()
    return None if value is None else list(value)


def border(alpha: Image.Image):
    width, height = alpha.size
    pixels = alpha.load()
    edges = {
        "top": [pixels[x, 0] for x in range(width)],
        "bottom": [pixels[x, height - 1] for x in range(width)],
        "left": [pixels[0, y] for y in range(height)],
        "right": [pixels[width - 1, y] for y in range(height)],
    }
    return {
        name: {"nonzero_count": sum(value > 0 for value in values), "max_alpha": max(values)}
        for name, values in edges.items()
    }


for record in RECORDS:
    stem = record["stem"]
    raw_path = RAW / f"{stem}.png"
    external_path = GENERATED / record["external"]
    prompt_path = BASE / f"{stem}.txt"
    spec_path = BASE / f"{stem}.spec.json"
    image = Image.open(raw_path).convert("RGBA")
    alpha = image.getchannel("A")
    external_sha = sha(external_path)
    raw_sha = sha(raw_path)
    if external_sha != raw_sha or external_path.stat().st_size != raw_path.stat().st_size:
        raise ValueError(f"external/workspace raw mismatch for {stem}")
    metadata = {
        "version": 1,
        "task_id": f"luoyang_soldier_diversity_20261019y_{stem.removeprefix('npc_luoyang_')}",
        "asset_id": stem,
        "status": record["status"],
        "generation": {
            "owner": "producer_ROOT",
            "execution_backend": "builtin_image_gen",
            "execution_mode": "edit" if "weapon_envelope_edit" in stem else "generate",
            "model": None,
            "provider": None,
            "cost": None,
            "attempt_number": 1,
            "attempt_budget": 1,
            "retries_allowed": False,
            "tool_response_fields": ["image_url", "output_hint"],
            "transparent_background_requested": True,
        },
        "provenance": {
            "external_generated_path": external_path.as_posix(),
            "workspace_raw_path": raw_path.relative_to(ROOT).as_posix(),
            "external_sha256": external_sha,
            "workspace_sha256": raw_sha,
            "bytes": raw_path.stat().st_size,
            "exact_copy_verified": True,
            "prompt_path": prompt_path.relative_to(ROOT).as_posix(),
            "prompt_sha256": sha(prompt_path),
            "spec_path": spec_path.relative_to(ROOT).as_posix(),
            "spec_sha256": sha(spec_path),
        },
        "actual_image": {
            "format": "PNG",
            "mode": image.mode,
            "size_px": list(image.size),
            "alpha_extrema": list(alpha.getextrema()),
            "alpha_bounds_pil_exclusive": {
                "a_gt_0": bbox(alpha, 0),
                "a_ge_1": bbox(alpha, 1),
                "a_ge_8": bbox(alpha, 8),
                "a_ge_16": bbox(alpha, 16),
            },
            "alpha_border": border(alpha),
        },
        "art_review": record["art_review"],
        "runtime_decision": record["runtime_decision"],
        "license_boundary": "project-generated original candidate; not claimed CC0 and not claimed commercially cleared beyond the project's builtin generation context",
    }
    if "reference" in record:
        reference_path = RAW / f"{record['reference']}.png"
        metadata["generation"]["reference_image_path"] = reference_path.relative_to(ROOT).as_posix()
        metadata["generation"]["reference_image_sha256"] = sha(reference_path)
    meta_path = RAW / f"{stem}.meta.json"
    meta_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{meta_path.relative_to(ROOT).as_posix()} {sha(meta_path)}")
