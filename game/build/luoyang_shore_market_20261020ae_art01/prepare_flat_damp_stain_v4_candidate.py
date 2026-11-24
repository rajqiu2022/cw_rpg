from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[3]
RAW = ROOT / "assets/raw/luoyang_shore_market_20261020ae/decal_docks_flat_damp_stain_vertical_v4.png"
RAW_SHA = "770E09432079CFA1EB4BE95DAEFE3BC87309AB8856F2EE531BF6DA9E41F55576"
FLOOR = ROOT / "game/art/maps/luoyang_enclosure_v11/ch4_s2_canal_docks/ground_v14/root_ground_v14_02/floor.png"
FLOOR_SHA = "494C52DAC3EDC4D82C8A1CB02691B80C8175E5B25EF351866E3733FF5471ABA1"
OUT = ROOT / "game/build/luoyang_shore_market_20261020ae_art01/wet_flat_v4_runtime_candidate_v1"
CANDIDATE = OUT / RAW.name


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def save_new_or_exact(image: Image.Image, path: Path) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    image.save(temporary, format="PNG", optimize=False)
    encoded = temporary.read_bytes()
    temporary.unlink()
    if path.exists() and path.read_bytes() != encoded:
        raise RuntimeError(f"refusing to replace different output: {path}")
    if not path.exists():
        path.write_bytes(encoded)


def alpha_bbox(alpha: Image.Image, threshold: int) -> tuple[int, int, int, int] | None:
    return alpha.point(lambda value: 255 if value >= threshold else 0).getbbox()


def modulated(source: Image.Image, rgb: tuple[float, float, float], opacity: float, size: tuple[int, int]) -> Image.Image:
    resized = source.convert("RGBa").resize(size, Image.Resampling.BICUBIC).convert("RGBA")
    red, green, blue, alpha = resized.split()
    red = red.point(lambda value: round(value * rgb[0]))
    green = green.point(lambda value: round(value * rgb[1]))
    blue = blue.point(lambda value: round(value * rgb[2]))
    alpha = alpha.point(lambda value: round(value * opacity))
    return Image.merge("RGBA", (red, green, blue, alpha))


def main() -> None:
    if sha256(RAW) != RAW_SHA or sha256(FLOOR) != FLOOR_SHA:
        raise RuntimeError("pinned input changed")
    OUT.mkdir(parents=True, exist_ok=True)
    raw_bytes = RAW.read_bytes()
    if CANDIDATE.exists() and CANDIDATE.read_bytes() != raw_bytes:
        raise RuntimeError("refusing to replace different candidate byte copy")
    if not CANDIDATE.exists():
        CANDIDATE.write_bytes(raw_bytes)
    if sha256(CANDIDATE) != RAW_SHA:
        raise RuntimeError("candidate byte copy mismatch")

    source = Image.open(RAW).convert("RGBA")
    alpha = source.getchannel("A")
    bbox_a1 = alpha.getbbox()
    bbox_a16 = alpha_bbox(alpha, 16)
    if bbox_a1 != (65, 32, 996, 1490) or bbox_a16 != (350, 52, 714, 1478):
        raise RuntimeError(f"unexpected alpha bounds: {bbox_a1} / {bbox_a16}")

    scale = 0.28
    target_right_a16 = 2205.0
    target_bottom_a16 = 1900.0
    right_a16_inclusive = bbox_a16[2] - 1
    bottom_a16_inclusive = bbox_a16[3] - 1
    top_left = [
        target_right_a16 - right_a16_inclusive * scale,
        target_bottom_a16 - bottom_a16_inclusive * scale,
    ]
    render_size = [source.width * scale, source.height * scale]
    render_size_int = [round(render_size[0]), round(render_size[1])]
    center = [top_left[0] + render_size[0] * 0.5, top_left[1] + render_size[1] * 0.5]
    strong_world_bbox = [
        top_left[0] + bbox_a16[0] * scale,
        top_left[1] + bbox_a16[1] * scale,
        top_left[0] + right_a16_inclusive * scale,
        top_left[1] + bottom_a16_inclusive * scale,
    ]
    floor = Image.open(FLOOR).convert("RGBA")
    variants = [
        ("WHITE x OPACITY 0.45", (1.0, 1.0, 1.0), 0.45),
        ("FIXED WET CLASS RGB(.38,.48,.52) x OPACITY 0.60", (0.38, 0.48, 0.52), 0.60),
    ]
    crop = (1960, 1420, 2240, 1960)
    panel_size = (448, 864)
    header = 36
    preview = Image.new("RGB", (panel_size[0] * 2, panel_size[1] + header), (22, 25, 27))
    draw = ImageDraw.Draw(preview)
    for index, (label, rgb, opacity) in enumerate(variants):
        composed = floor.copy()
        overlay = modulated(source, rgb, opacity, tuple(render_size_int))
        composed.alpha_composite(overlay, dest=(round(top_left[0]), round(top_left[1])))
        panel = composed.crop(crop).resize(panel_size, Image.Resampling.LANCZOS).convert("RGB")
        x = panel_size[0] * index
        preview.paste(panel, (x, header))
        draw.text((x + 10, 11), label, fill=(232, 234, 234))
    preview_path = OUT / "flat_damp_stain_v4_white045_vs_fixedwet060.png"
    save_new_or_exact(preview, preview_path)

    report = {
        "schema": "luoyang_shore_market_flat_damp_stain_v4_candidate_v1",
        "status": "OFFLINE_BYTE_EXACT_CANDIDATE_ROOT_ART_REVIEW_PENDING",
        "raw": {
            "path": RAW.relative_to(ROOT).as_posix(),
            "sha256": RAW_SHA,
            "bytes": RAW.stat().st_size,
            "size_px": list(source.size),
            "mode": "RGBA"
        },
        "candidate_byte_copy": {
            "path": CANDIDATE.relative_to(ROOT).as_posix(),
            "sha256": sha256(CANDIDATE),
            "bytes": CANDIDATE.stat().st_size,
            "exact_raw_bytes": CANDIDATE.read_bytes() == raw_bytes
        },
        "alpha_measurement": {
            "extrema": list(alpha.getextrema()),
            "a_gt_0_bbox_half_open": list(bbox_a1),
            "a_ge_16_bbox_half_open": list(bbox_a16),
            "a_gt_0_count": sum(1 for value in alpha.getdata() if value > 0),
            "a_ge_16_count": sum(1 for value in alpha.getdata() if value >= 16),
            "corner_rgba": [list(source.getpixel(point)) for point in ((0, 0), (1023, 0), (0, 1535), (1023, 1535))]
        },
        "placement": {
            "center_px": center,
            "render_size_px": render_size,
            "region_origin_px": [0, 0],
            "region_size_px": list(source.size),
            "uniform_scale": scale,
            "a_ge_16_world_bbox_inclusive_approx": strong_world_bbox,
            "target_right_a_ge_16_x": target_right_a16,
            "target_bottom_a_ge_16_y": target_bottom_a16,
            "effective_z_index": -998,
            "solid": False,
            "walk_support": False,
            "nav_change": False
        },
        "preview_variants": [
            {"asset_modulate_rgb": [1.0, 1.0, 1.0], "opacity": 0.45},
            {"asset_modulate_rgb": [0.38, 0.48, 0.52], "opacity": 0.60, "fixed_class_name_proposal": "wet_ground_ae"}
        ],
        "preview": {"path": preview_path.relative_to(ROOT).as_posix(), "sha256": sha256(preview_path)},
        "pixel_boundary": "Source and candidate PNG bytes are exact. RGB/opacity modulation exists only in the offline preview and is not baked into either PNG.",
        "credit_boundary": "Offline byte-copy, alpha measurement and placement preview only. No import, engine, Field, runtime binding, collision, NAV, walk support or formal art credit."
    }
    report_path = OUT / "flat_damp_stain_v4_candidate_report.json"
    text = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if report_path.exists() and report_path.read_text(encoding="utf-8") != text:
        raise RuntimeError("refusing to replace different report")
    report_path.write_text(text, encoding="utf-8", newline="\n")
    print(json.dumps({"report": str(report_path), "report_sha256": sha256(report_path), "preview_sha256": sha256(preview_path)}, ensure_ascii=False))


if __name__ == "__main__":
    main()

