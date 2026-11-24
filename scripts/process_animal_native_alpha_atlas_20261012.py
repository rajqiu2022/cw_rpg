"""Prepare native-alpha eagle candidates with ONE fit for all twenty poses.

No image API, Godot, runtime bindings or existing-asset replacement.
Species scale targets are animal authoring bounds, NOT the human 300px rule.
Visual species / left-facing / temporal-action approval remains manual.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import statistics
from pathlib import Path

from PIL import Image

from process_battle_sprite_atlas import (
    STATE_NAMES, CANVAS_SIZE, adaptive_cuts, content_box,
    keep_largest_component,
)

PROFILES = {
    "wild_dog": (400, 235),
    "tiger": (460, 265),
    "bear": (450, 290),
    "eagle": (440, 275),
}
MAX_CONTENT = (480, 350)
BOTTOM_MARGIN = 12
STYLE_REFERENCE = Path("game/art/sprites/battle/standard_v2/wild_wolf/wild_wolf_ready_01.png")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def split_animal_cells(atlas: Image.Image) -> tuple[list[Image.Image], list[dict]]:
    """Native alpha only: strong pre-clean edges and all post-clean edges must be empty."""
    row_cuts = adaptive_cuts(atlas, 5, "y", max(4, atlas.height // 25))
    cells, records = [], []
    alpha = atlas.getchannel("A")
    for cut in row_cuts[1:-1]:
        if max(alpha.crop((0, cut, atlas.width, cut + 1)).getdata()) >= 24:
            raise ValueError(f"occupied row gutter at y={cut}; visually correct atlas first")
    for row, state in enumerate(STATE_NAMES):
        top, bottom = row_cuts[row:row + 2]
        row_image = atlas.crop((0, top, atlas.width, bottom))
        col_cuts = adaptive_cuts(row_image, 4, "x", max(4, atlas.width // 20))
        for cut in col_cuts[1:-1]:
            if max(row_image.getchannel("A").crop((cut, 0, cut + 1, row_image.height)).getdata()) >= 24:
                raise ValueError(f"occupied column gutter in {state} at x={cut}")
        for col in range(4):
            left, right = col_cuts[col:col + 2]
            raw_cell = row_image.crop((left, 0, right, row_image.height))
            raw_box = content_box(raw_cell)
            strong_box = raw_cell.getchannel("A").point(lambda a: 255 if a >= 24 else 0).getbbox()
            if strong_box is None:
                raise ValueError(f"{state}/{col + 1} has no alpha>=24 subject")
            if strong_box[0] <= 0 or strong_box[1] <= 0 or strong_box[2] >= raw_cell.width or strong_box[3] >= raw_cell.height:
                raise ValueError(f"{state}/{col + 1} alpha>=24 touches a cell edge; no automatic repair")
            cell = keep_largest_component(raw_cell)
            box = content_box(cell)
            if box[0] <= 0 or box[1] <= 0 or box[2] >= cell.width or box[3] >= cell.height:
                raise ValueError(f"{state}/{col + 1} post-clean nonzero alpha touches a cell edge")
            cells.append(cell)
            records.append({
                "state": state, "index": col + 1,
                "source_cell_rect": [left, top, right, bottom],
                "source_cell_size": list(cell.size),
                "native_nonzero_bbox_before_component_cleanup": list(raw_box),
                "native_alpha24_bbox_before_component_cleanup": list(strong_box),
                "pre_clean_edge_guard": "ALL_ALPHA_GE_24_REJECT",
                "post_clean_edge_guard": "ALL_NONZERO_ALPHA_REJECT",
                "source_content_bbox": list(box),
                "source_content_size": [box[2] - box[0], box[3] - box[1]],
                "component_cleanup": "UNCHANGED_PROJECT_LARGEST_ALPHA24_COMPONENT",
            })
    if len(cells) != 20:
        raise ValueError("requires exactly twenty actual cells")
    return cells, records


def process(atlas_path: Path, output_dir: Path, species: str) -> dict:
    if species != "eagle":
        raise ValueError("native-alpha adapter is restricted to eagle candidates")
    if output_dir.exists():
        raise FileExistsError(f"refusing to overwrite existing directory: {output_dir}")
    if not atlas_path.is_file() or not STYLE_REFERENCE.is_file():
        raise FileNotFoundError("actual atlas and frozen style-reference PNG are required")
    with Image.open(atlas_path) as original:
        actual_size = original.size
        if min(actual_size) < 1024:
            raise ValueError(f"unexpected low resolution {actual_size}; do not silently upscale")
        if original.mode != "RGBA":
            raise ValueError("native input must actually be RGBA, not chroma-keyed RGB")
        corners = ((0, 0), (original.width - 1, 0), (0, original.height - 1),
                   (original.width - 1, original.height - 1))
        if any(original.getpixel(p)[3] != 0 for p in corners):
            raise ValueError("native transparent background requires alpha=0 corners")
        atlas = original.copy()
        native_rgba_sha = hashlib.sha256(atlas.tobytes()).hexdigest()
    cells, rows = split_animal_cells(atlas)
    widths = [r["source_content_size"][0] for r in rows]
    heights = [r["source_content_size"][1] for r in rows]
    ready_width = statistics.median(widths[:4])
    ready_height = statistics.median(heights[:4])
    wanted_width, wanted_height = PROFILES[species]
    # Compute all four constraints BEFORE rendering any cell. There is never
    # a per-frame fit, rescale, stretch or species substitution.
    scale = min(wanted_width / ready_width, wanted_height / ready_height,
                MAX_CONTENT[0] / max(widths), MAX_CONTENT[1] / max(heights))
    if not math.isfinite(scale) or scale <= 0:
        raise ValueError("invalid shared scale")
    prepared = []
    for cell, row in zip(cells, rows, strict=True):
        sprite = cell.crop(tuple(row["source_content_bbox"]))
        size = (max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale)))
        if size[0] > MAX_CONTENT[0] or size[1] > MAX_CONTENT[1]:
            raise ValueError("shared-fit rounding exceeds canvas; not repaired per frame")
        sprite = sprite.resize(size, Image.Resampling.LANCZOS)
        resized_box = content_box(sprite)
        sprite = sprite.crop(resized_box)  # remove only fully transparent resampling padding
        canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
        x = (CANVAS_SIZE[0] - sprite.width) // 2
        y = CANVAS_SIZE[1] - BOTTOM_MARGIN - sprite.height
        canvas.alpha_composite(sprite, (x, y))
        output_box = content_box(canvas)
        if CANVAS_SIZE[1] - output_box[3] != BOTTOM_MARGIN:
            raise ValueError("actual nonzero-alpha baseline is not exactly 12px")
        row.update({
            "global_scale": scale, "resized_size_before_zero_alpha_trim": list(size),
            "resized_zero_alpha_trim_bbox": list(resized_box),
            "output_content_bbox": list(output_box), "actual_bottom_margin": BOTTOM_MARGIN,
            "output_canvas": list(CANVAS_SIZE), "frame_fit_applied": False,
            "output_filename": f"{species}_{row['state']}_{row['index']:02d}.png",
        })
        prepared.append(canvas)
    output_dir.mkdir(parents=True, exist_ok=False)
    preview_dir = output_dir / "previews"
    preview_dir.mkdir()
    contact = Image.new("RGBA", (CANVAS_SIZE[0] * 4, CANVAS_SIZE[1] * 5), (0, 0, 0, 0))
    for index, (canvas, row) in enumerate(zip(prepared, rows, strict=True)):
        destination = output_dir / row["output_filename"]
        canvas.save(destination)
        row["output_sha256"] = sha256(destination)
        row["output_rgba_sha256"] = hashlib.sha256(canvas.tobytes()).hexdigest()
        contact.alpha_composite(canvas, ((index % 4) * CANVAS_SIZE[0], (index // 4) * CANVAS_SIZE[1]))
    contact.save(preview_dir / f"{species}_contact_4x5.png")
    for row, state in enumerate(STATE_NAMES):
        frames = prepared[row * 4:row * 4 + 4]
        durations = [140, 140, 140, 700] if state == "defeat" else [140] * 4
        frames[0].save(preview_dir / f"{species}_{state}_preview.webp",
                       save_all=True, append_images=frames[1:], duration=durations,
                       loop=0, lossless=True)
    source_meta = atlas_path.with_suffix(".meta.json")
    metadata = json.loads(source_meta.read_text(encoding="utf-8")) if source_meta.is_file() else None
    report = {
        "schema_version": 1, "scope": "ANIMAL_BATTLE_CANDIDATE_NOT_RUNTIME_ADOPTED",
        "species": species, "source_atlas": str(atlas_path),
        "source_sha256": sha256(atlas_path), "actual_source_size": list(actual_size),
        "input_kind": "ACTUAL_RGBA_NATIVE_ALPHA_ZERO_BACKGROUND_NOT_CHROMA",
        "source_rgba_sha256": native_rgba_sha, "chroma_removal_applied": False,
        "low_alpha_noise_policy": "UNCHANGED_LARGEST_ALPHA24_COMPONENT_ON_OWNED_CELLS",
        "source_generation_metadata_path": str(source_meta) if metadata is not None else None,
        "source_generation_metadata_sha256": sha256(source_meta) if metadata is not None else None,
        "source_generation_metadata": metadata,
        "style_reference_only": str(STYLE_REFERENCE),
        "style_reference_sha256": sha256(STYLE_REFERENCE),
        "processor": str(Path(__file__)), "processor_sha256": sha256(Path(__file__)),
        "global_scale": scale, "species_ready_target_bounds": [wanted_width, wanted_height],
        "ready_input_median_size": [ready_width, ready_height],
        "whole_twenty_input_maximum": [max(widths), max(heights)],
        "per_frame_fit": False, "frames": rows, "frame_count": 20,
        "adopted": False, "Godot_tested": False,
        "visual_left_facing_and_action_review_required": True,
        "source_body_proportion_drift_is_not_repaired_by_rescaling": True,
    }
    (output_dir / f"{species}_processing_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("atlas", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--species", choices=tuple(PROFILES), required=True)
    args = parser.parse_args()
    report = process(args.atlas, args.output_dir, args.species)
    print(json.dumps({"species": report["species"], "frames": report["frame_count"],
                      "global_scale": report["global_scale"],
                      "output_dir": str(args.output_dir), "adopted": False}))


if __name__ == "__main__":
    main()
