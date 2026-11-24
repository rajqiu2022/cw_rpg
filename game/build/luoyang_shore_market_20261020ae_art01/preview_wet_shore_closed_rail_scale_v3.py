from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "game/build/luoyang_shore_market_20261020ae_art01/wet_shore_local_cleanup_v1/decal_docks_wet_stone_shore_vertical_v3_local_bg_cleanup.png"
SOURCE_SHA = "24955194835C5DA22446F90FAC17E64AE0585DAB9528E35355024885C75F55D3"
FLOOR = ROOT / "game/art/maps/luoyang_enclosure_v11/ch4_s2_canal_docks/ground_v14/root_ground_v14_02/floor.png"
FLOOR_SHA = "494C52DAC3EDC4D82C8A1CB02691B80C8175E5B25EF351866E3733FF5471ABA1"
OUT = ROOT / "game/build/luoyang_shore_market_20261020ae_art01/wet_shore_local_cleanup_v1"


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def save_new_or_exact(image: Image.Image, path: Path) -> None:
    tmp = path.with_suffix(path.suffix + ".tmp")
    image.save(tmp, format="PNG", optimize=False)
    data = tmp.read_bytes(); tmp.unlink()
    if path.exists() and path.read_bytes() != data:
        raise RuntimeError(f"refusing to replace different output: {path}")
    if not path.exists():
        path.write_bytes(data)


def main() -> None:
    if sha(SOURCE) != SOURCE_SHA or sha(FLOOR) != FLOOR_SHA:
        raise RuntimeError("pinned source changed")
    source = Image.open(SOURCE).convert("RGBA")
    scale = 0.28
    opacity = 0.48
    derived_bbox_inclusive = [385, 16, 637, 1518]
    target_rightmost_a_gt_0_x = 2205.0
    target_bottommost_a_gt_0_y = 1900.0
    top_left = [
        target_rightmost_a_gt_0_x - derived_bbox_inclusive[2] * scale,
        target_bottommost_a_gt_0_y - derived_bbox_inclusive[3] * scale,
    ]
    render_size = [source.width * scale, source.height * scale]
    center = [top_left[0] + render_size[0] * 0.5, top_left[1] + render_size[1] * 0.5]
    visible_bbox = [
        top_left[0] + derived_bbox_inclusive[0] * scale,
        top_left[1] + derived_bbox_inclusive[1] * scale,
        top_left[0] + derived_bbox_inclusive[2] * scale,
        top_left[1] + derived_bbox_inclusive[3] * scale,
    ]
    if visible_bbox[2] > 2205.000001 or visible_bbox[2] >= 2230.0:
        raise RuntimeError("wet shore crosses closed land boundary")
    overlay = source.convert("RGBa").resize((round(render_size[0]), round(render_size[1])), Image.Resampling.BICUBIC).convert("RGBA")
    overlay.putalpha(overlay.getchannel("A").point(lambda value: round(value * opacity)))
    floor = Image.open(FLOOR).convert("RGBA")
    after = floor.copy(); after.alpha_composite(overlay, dest=(round(top_left[0]), round(top_left[1])))
    crop = (2070, 1400, 2240, 1970)
    before_panel = floor.crop(crop).resize((408, 1368), Image.Resampling.LANCZOS)
    after_panel = after.crop(crop).resize((408, 1368), Image.Resampling.LANCZOS)
    bar = 32
    preview = Image.new("RGB", (816, 1400), (24, 27, 29))
    preview.paste(before_panel.convert("RGB"), (0, bar)); preview.paste(after_panel.convert("RGB"), (408, bar))
    draw = ImageDraw.Draw(preview)
    draw.text((10, 9), "CURRENT CANONICAL FLOOR", fill=(230, 232, 232))
    draw.text((418, 9), "OFFLINE CLOSED-RAIL WET BAND SCALE 0.28", fill=(230, 232, 232))
    preview_path = OUT / "wet_shore_closed_rail_scale028_before_after.png"
    save_new_or_exact(preview, preview_path)
    report = {
        "schema": "luoyang_shore_market_wet_shore_closed_rail_placement_v3",
        "status": "OFFLINE_CLOSED_LAND_CANDIDATE_ROOT_ART_REVIEW_PENDING",
        "texture": str(SOURCE.relative_to(ROOT)).replace("\\", "/"),
        "texture_sha256": SOURCE_SHA,
        "center_px": center,
        "render_size_px": render_size,
        "region_origin_px": [0, 0],
        "region_size_px": list(source.size),
        "uniform_scale": scale,
        "opacity": opacity,
        "effective_z_index": -998,
        "derived_a_gt_0_source_bbox_inclusive": derived_bbox_inclusive,
        "derived_a_gt_0_world_bbox_inclusive_approx": visible_bbox,
        "closed_domain_reference": {
            "rail_center_x": 2215,
            "blocked_x_inclusive": [2206, 2223],
            "original_land_surface_max_x": 2229,
            "water_min_x": 2230,
            "candidate_rightmost_a_gt_0_x": visible_bbox[2]
        },
        "single_instance_only": True,
        "no_repeat_crop_rotation_or_stretch": True,
        "solid": False,
        "walk_support": False,
        "nav_change": False,
        "ordering": "ground visual only, below existing wharf, boats, props and actors",
        "preview": {"path": str(preview_path.relative_to(ROOT)).replace("\\", "/"), "sha256": sha(preview_path)},
        "credit_boundary": "Offline source placement only. No import, actual Field, runtime binding, collision, NAV, walk-support or formal credit."
    }
    report_path = OUT / "wet_shore_closed_rail_placement_v3.json"
    text = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if report_path.exists() and report_path.read_text(encoding="utf-8") != text:
        raise RuntimeError(f"refusing to replace different report: {report_path}")
    report_path.write_text(text, encoding="utf-8", newline="\n")
    print(json.dumps({"report": str(report_path), "sha256": sha(report_path), "preview_sha256": sha(preview_path)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
