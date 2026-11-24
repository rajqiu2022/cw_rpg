from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "assets/raw/luoyang_shore_market_20261020ae/decal_docks_wet_stone_shore_vertical_v2_halo_extraction_edit.png"
SOURCE_SHA = "92BE528E0BA9EEA7CD7B21FA8AE20EDACF48012AA97FEF747FE23BE1A42A6BB4"
FLOOR = ROOT / "game/art/maps/luoyang_enclosure_v11/ch4_s2_canal_docks/ground_v14/root_ground_v14_02/floor.png"
FLOOR_SHA = "494C52DAC3EDC4D82C8A1CB02691B80C8175E5B25EF351866E3733FF5471ABA1"
OUT = ROOT / "game/build/luoyang_shore_market_20261020ae_art01/wet_shore_local_cleanup_v1"
DERIVED = OUT / "decal_docks_wet_stone_shore_vertical_v3_local_bg_cleanup.png"


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def save_new_or_exact(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    image.save(tmp, format="PNG", optimize=False)
    data = tmp.read_bytes()
    tmp.unlink()
    if path.exists() and path.read_bytes() != data:
        raise RuntimeError(f"refusing to replace different output: {path}")
    if not path.exists():
        path.write_bytes(data)


def bbox_at(alpha: Image.Image, threshold: int) -> list[int] | None:
    mask = alpha.point(lambda value: 255 if value >= threshold else 0)
    box = mask.getbbox()
    if box is None:
        return None
    return [box[0], box[1], box[2] - 1, box[3] - 1]


def checker(size: tuple[int, int], cell: int = 24) -> Image.Image:
    out = Image.new("RGBA", size, (52, 55, 57, 255))
    draw = ImageDraw.Draw(out)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if ((x // cell) + (y // cell)) % 2:
                draw.rectangle((x, y, min(x + cell - 1, size[0] - 1), min(y + cell - 1, size[1] - 1)), fill=(78, 81, 83, 255))
    return out


def pair(before: Image.Image, after: Image.Image, left: str, right: str) -> Image.Image:
    if before.size != after.size:
        raise RuntimeError("pair size mismatch")
    bar = 32
    out = Image.new("RGB", (before.width * 2, before.height + bar), (24, 27, 29))
    out.paste(before.convert("RGB"), (0, bar))
    out.paste(after.convert("RGB"), (before.width, bar))
    draw = ImageDraw.Draw(out)
    draw.text((10, 9), left, fill=(230, 232, 232))
    draw.text((before.width + 10, 9), right, fill=(230, 232, 232))
    return out


def main() -> None:
    if sha(SOURCE) != SOURCE_SHA or sha(FLOOR) != FLOOR_SHA:
        raise RuntimeError("pinned source changed")
    OUT.mkdir(parents=True, exist_ok=True)
    source = Image.open(SOURCE).convert("RGBA")
    source_data = source.tobytes()
    source_alpha = source.getchannel("A")
    source_alpha_bytes = source_alpha.tobytes()

    # Exact authorized operation: clear only alpha==1 background haze. RGB is
    # retained byte-for-byte, and every pixel whose alpha was >=2 is untouched.
    cleaned_alpha = source_alpha.point(lambda value: 0 if value == 1 else value)
    cleaned = source.copy()
    cleaned.putalpha(cleaned_alpha)
    save_new_or_exact(cleaned, DERIVED)

    cleaned_data = cleaned.tobytes()
    changed_pixels = 0
    rgb_changed_pixels = 0
    alpha_changed_pixels = 0
    subject_rgba_changed_pixels = 0
    weak_removed = 0
    for index in range(source.width * source.height):
        offset = index * 4
        src = source_data[offset:offset + 4]
        dst = cleaned_data[offset:offset + 4]
        if src != dst:
            changed_pixels += 1
        if src[:3] != dst[:3]:
            rgb_changed_pixels += 1
        if src[3] != dst[3]:
            alpha_changed_pixels += 1
        if src[3] >= 2 and src != dst:
            subject_rgba_changed_pixels += 1
        if src[3] == 1 and dst[3] == 0:
            weak_removed += 1

    # Checkerboard before/after, downscaled only for the review image.
    display_size = (512, 768)
    source_display = source.convert("RGBa").resize(display_size, Image.Resampling.LANCZOS).convert("RGBA")
    cleaned_display = cleaned.convert("RGBa").resize(display_size, Image.Resampling.LANCZOS).convert("RGBA")
    check = checker(display_size)
    before_check = check.copy(); before_check.alpha_composite(source_display)
    after_check = check.copy(); after_check.alpha_composite(cleaned_display)
    checker_preview = pair(before_check, after_check, "RAW V2 ON CHECKER", "LOCAL BG CLEANUP V3")
    checker_path = OUT / "wet_shore_cleanup_checker_before_after.png"
    save_new_or_exact(checker_preview, checker_path)

    # Placement proposal: keep the strong-alpha right edge on the land side of
    # the actual x=2215 shore. It remains below wharf/boats/actors and adds no
    # solid or walk support. No transform is baked into the derived PNG.
    uniform_scale = 0.98
    opacity = 0.55
    strong_right_source_x = 637.0
    strong_top_source_y = 16.0
    target_strong_right_world_x = 2210.0
    target_strong_top_world_y = 300.0
    top_left_world = [
        target_strong_right_world_x - strong_right_source_x * uniform_scale,
        target_strong_top_world_y - strong_top_source_y * uniform_scale,
    ]
    center_world = [
        top_left_world[0] + source.width * uniform_scale * 0.5,
        top_left_world[1] + source.height * uniform_scale * 0.5,
    ]
    render_size = [source.width * uniform_scale, source.height * uniform_scale]
    display = cleaned.convert("RGBa").resize((round(render_size[0]), round(render_size[1])), Image.Resampling.BICUBIC).convert("RGBA")
    display.putalpha(display.getchannel("A").point(lambda value: round(value * opacity)))
    floor = Image.open(FLOOR).convert("RGBA")
    floor_after = floor.copy()
    floor_after.alpha_composite(display, dest=(round(top_left_world[0]), round(top_left_world[1])))
    crop = (1830, 240, 2290, 1860)
    before_floor = floor.crop(crop).resize((414, 1458), Image.Resampling.LANCZOS)
    after_floor = floor_after.crop(crop).resize((414, 1458), Image.Resampling.LANCZOS)
    floor_preview = pair(before_floor, after_floor, "CURRENT CANONICAL FLOOR", "OFFLINE CLEAN WET SHORE OPACITY 0.55")
    floor_path = OUT / "wet_shore_current_floor_before_after.png"
    save_new_or_exact(floor_preview, floor_path)

    source_nonzero = sum(value > 0 for value in source_alpha_bytes)
    source_ge2 = sum(value >= 2 for value in source_alpha_bytes)
    cleaned_alpha_bytes = cleaned_alpha.tobytes()
    report = {
        "schema": "luoyang_shore_market_wet_shore_local_cleanup_v1",
        "status": "LOCAL_DERIVATIVE_READY_FOR_ROOT_ART_REVIEW_NOT_IMPORT_OR_FIELD_CREDIT",
        "authorization_scope": "Local Python background removal only; preserve stone-shore subject. No repaint, generation, crop, rotation or deformation.",
        "source": {"path": str(SOURCE.relative_to(ROOT)).replace("\\", "/"), "sha256": SOURCE_SHA, "bytes": SOURCE.stat().st_size, "size_px": list(source.size)},
        "derived": {"path": str(DERIVED.relative_to(ROOT)).replace("\\", "/"), "sha256": sha(DERIVED), "bytes": DERIVED.stat().st_size, "size_px": list(cleaned.size)},
        "operation": {"alpha_rule": "A==1 -> 0; every other alpha and all RGB bytes unchanged", "crop": False, "rotation": False, "shape_change": False, "paint_or_fill": False},
        "pixel_accounting": {
            "total_pixels": source.width * source.height,
            "source_a_gt_0_count": source_nonzero,
            "source_a_ge_2_count": source_ge2,
            "removed_a_eq_1_count": weak_removed,
            "changed_pixel_count": changed_pixels,
            "alpha_changed_pixel_count": alpha_changed_pixels,
            "rgb_changed_pixel_count": rgb_changed_pixels,
            "subject_a_ge_2_rgba_changed_pixel_count": subject_rgba_changed_pixels,
            "source_alpha_sum": sum(source_alpha_bytes),
            "derived_alpha_sum": sum(cleaned_alpha_bytes),
            "alpha_sum_delta": sum(cleaned_alpha_bytes) - sum(source_alpha_bytes),
        },
        "mask_bounds_inclusive": {
            "source_a_gt_0": bbox_at(source_alpha, 1),
            "source_a_ge_2": bbox_at(source_alpha, 2),
            "derived_a_gt_0": bbox_at(cleaned_alpha, 1),
            "derived_a_ge_2": bbox_at(cleaned_alpha, 2),
        },
        "placement_proposal": {
            "center_px": center_world,
            "render_size_px": render_size,
            "region_origin_px": [0, 0],
            "region_size_px": list(source.size),
            "uniform_scale": uniform_scale,
            "opacity": opacity,
            "effective_z_index": -998,
            "strong_alpha_world_bbox_approx_px": [
                top_left_world[0] + 385.0 * uniform_scale,
                top_left_world[1] + 16.0 * uniform_scale,
                top_left_world[0] + 638.0 * uniform_scale,
                top_left_world[1] + 1519.0 * uniform_scale,
            ],
            "solid": False,
            "walk_support": False,
            "nav_change": False,
            "ordering": "above water/floor visual base; below existing wharf, boats, props and actors",
        },
        "previews": [
            {"path": str(checker_path.relative_to(ROOT)).replace("\\", "/"), "sha256": sha(checker_path)},
            {"path": str(floor_path.relative_to(ROOT)).replace("\\", "/"), "sha256": sha(floor_path)},
        ],
        "credit_boundary": "Local derivative and deterministic offline previews only. Root art review is still required before isolated import; no runtime binding, Field, collision, NAV, walk-support or formal credit."
    }
    report_path = OUT / "wet_shore_cleanup_report.json"
    text = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if report_path.exists() and report_path.read_text(encoding="utf-8") != text:
        raise RuntimeError(f"refusing to replace different report: {report_path}")
    report_path.write_text(text, encoding="utf-8", newline="\n")
    print(json.dumps({"report": str(report_path), "sha256": sha(report_path), "derived_sha256": sha(DERIVED)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
