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


def pair(before: Image.Image, after: Image.Image) -> Image.Image:
    bar = 32
    out = Image.new("RGB", (before.width * 2, before.height + bar), (24, 27, 29))
    out.paste(before.convert("RGB"), (0, bar)); out.paste(after.convert("RGB"), (before.width, bar))
    draw = ImageDraw.Draw(out)
    draw.text((10, 9), "CURRENT CANONICAL FLOOR", fill=(230, 232, 232))
    draw.text((before.width + 10, 9), "OFFLINE LOCAL LANDING WET BAND SCALE 0.42", fill=(230, 232, 232))
    return out


def main() -> None:
    if sha(SOURCE) != SOURCE_SHA or sha(FLOOR) != FLOOR_SHA:
        raise RuntimeError("pinned source changed")
    source = Image.open(SOURCE).convert("RGBA")
    scale = 0.42
    opacity = 0.48
    strong_right_source_x = 637.0
    strong_top_source_y = 16.0
    target_strong_right_x = 2210.0
    target_strong_top_y = 1050.0
    top_left = [target_strong_right_x - strong_right_source_x * scale, target_strong_top_y - strong_top_source_y * scale]
    render_size = [source.width * scale, source.height * scale]
    center = [top_left[0] + render_size[0] * 0.5, top_left[1] + render_size[1] * 0.5]
    overlay = source.convert("RGBa").resize((round(render_size[0]), round(render_size[1])), Image.Resampling.BICUBIC).convert("RGBA")
    overlay.putalpha(overlay.getchannel("A").point(lambda value: round(value * opacity)))
    floor = Image.open(FLOOR).convert("RGBA")
    after = floor.copy(); after.alpha_composite(overlay, dest=(round(top_left[0]), round(top_left[1])))
    crop = (1980, 900, 2270, 1800)
    before_panel = floor.crop(crop).resize((406, 1260), Image.Resampling.LANCZOS)
    after_panel = after.crop(crop).resize((406, 1260), Image.Resampling.LANCZOS)
    preview = pair(before_panel, after_panel)
    preview_path = OUT / "wet_shore_local_landing_scale042_before_after.png"
    save_new_or_exact(preview, preview_path)
    report = {
        "schema": "luoyang_shore_market_wet_shore_placement_successor_v2",
        "status": "OFFLINE_LOCAL_LANDING_CANDIDATE_ROOT_ART_REVIEW_PENDING",
        "texture": str(SOURCE.relative_to(ROOT)).replace("\\", "/"),
        "texture_sha256": SOURCE_SHA,
        "center_px": center,
        "render_size_px": render_size,
        "region_origin_px": [0, 0],
        "region_size_px": list(source.size),
        "uniform_scale": scale,
        "opacity": opacity,
        "effective_z_index": -998,
        "strong_alpha_world_bbox_approx_px": [
            top_left[0] + 385.0 * scale,
            top_left[1] + 16.0 * scale,
            top_left[0] + 638.0 * scale,
            top_left[1] + 1519.0 * scale,
        ],
        "single_instance_only": True,
        "no_repeat_or_stretch": True,
        "solid": False,
        "walk_support": False,
        "nav_change": False,
        "ordering": "below existing wharf, boats, props and actors",
        "preview": {"path": str(preview_path.relative_to(ROOT)).replace("\\", "/"), "sha256": sha(preview_path)},
        "credit_boundary": "Local landing-only placement proposal. No import, actual Field, runtime binding, collision, NAV or formal credit."
    }
    report_path = OUT / "wet_shore_placement_successor_v2.json"
    text = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if report_path.exists() and report_path.read_text(encoding="utf-8") != text:
        raise RuntimeError(f"refusing to replace different report: {report_path}")
    report_path.write_text(text, encoding="utf-8", newline="\n")
    print(json.dumps({"report": str(report_path), "sha256": sha(report_path), "preview_sha256": sha(preview_path)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
