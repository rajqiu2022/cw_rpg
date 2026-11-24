from __future__ import annotations

import hashlib
import json
import math
import shutil
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "game/build/luoyang_shore_market_20261020ae_art01/runtime_candidates_v1"
TEXTURES = OUT / "textures"

ROPE = ROOT / "assets/raw/luoyang_shore_market_20261020ae/decal_docks_hawser_knot_right_v2.png"
RUTS = ROOT / "assets/raw/luoyang_shore_market_20261020ae/decal_docks_cart_ruts_horizontal_v1.png"
MARKET = ROOT / "assets/raw/luoyang_shore_market_20261020ae/decal_market_cross_street_stall_wear_patch_v1.png"
DOCKS_FLOOR = ROOT / "game/art/maps/luoyang_enclosure_v11/ch4_s2_canal_docks/ground_v14/root_ground_v14_02/floor.png"
MARKET_FLOOR = ROOT / "game/art/maps/luoyang_enclosure_v11/ch4_s3_luoyang_market/ground_v14/root_ground_v14_02/floor.png"
DOCKS_ACTUAL = ROOT / "game/build/luoyang_docks08_formal_field_20261019ab/113316/ordinary_docks08_default_after32px.png"
FERRY = ROOT / "game/art/maps/luoyang_harbour_life_20261016/covered_ferry_v1.png"

EXPECTED = {
    ROPE: "7F1623EFC447DC5A10A4D0806FC78390D448D9E45BF442FAB0D8DE6FFD626242",
    RUTS: "3F4013006FB3FD285CD0CA9306A1028D27E0F6F378EF55C1A25E85F5116E2043",
    MARKET: "F8F5603FBCD6C3E40626277465EB505BE17393CFB588AED17DB623465523205F",
    DOCKS_FLOOR: "494C52DAC3EDC4D82C8A1CB02691B80C8175E5B25EF351866E3733FF5471ABA1",
    MARKET_FLOOR: "78D4C0CEDB57AF87FAE276F382D87CA98C40513B564FF8D69F164ED627718DAA",
    DOCKS_ACTUAL: "F85A85E460256E7F48E4A59059EBA4123C4745F6ABBA4E8E6BCBACC782822B67",
    FERRY: "D67140A7AFA0FDFFFFF97DE9E34A0680B0069FC9DBD05BBCF85FB7E4EF989357",
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def verify_inputs() -> None:
    for path, expected in EXPECTED.items():
        actual = sha(path)
        if actual != expected:
            raise RuntimeError(f"source changed: {path}: {actual} != {expected}")


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


def copy_exact(source: Path, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        if target.read_bytes() != source.read_bytes():
            raise RuntimeError(f"refusing to replace different candidate texture: {target}")
        return
    shutil.copyfile(source, target)
    if sha(source) != sha(target):
        raise RuntimeError(f"copy mismatch: {source} -> {target}")


def transformed_full_canvas(
    image: Image.Image,
    source_anchor: tuple[float, float],
    world_anchor: tuple[float, float],
    scale: float,
    rotation_degrees: float = 0.0,
) -> tuple[Image.Image, tuple[int, int]]:
    """Transform the complete source canvas without crop or alpha thresholding."""
    rgba = image.convert("RGBA")
    theta = math.radians(rotation_degrees)
    cos_t = math.cos(theta)
    sin_t = math.sin(theta)

    def forward(px: float, py: float) -> tuple[float, float]:
        dx = px - source_anchor[0]
        dy = py - source_anchor[1]
        return (
            world_anchor[0] + scale * (cos_t * dx - sin_t * dy),
            world_anchor[1] + scale * (sin_t * dx + cos_t * dy),
        )

    corners = [forward(0.0, 0.0), forward(float(rgba.width), 0.0), forward(0.0, float(rgba.height)), forward(float(rgba.width), float(rgba.height))]
    origin_x = math.floor(min(p[0] for p in corners)) - 1
    origin_y = math.floor(min(p[1] for p in corners)) - 1
    max_x = math.ceil(max(p[0] for p in corners)) + 1
    max_y = math.ceil(max(p[1] for p in corners)) + 1
    out_size = (max_x - origin_x, max_y - origin_y)

    inv = 1.0 / scale
    a = cos_t * inv
    b = sin_t * inv
    d = -sin_t * inv
    e = cos_t * inv
    c = source_anchor[0] + a * (origin_x - world_anchor[0]) + b * (origin_y - world_anchor[1])
    f = source_anchor[1] + d * (origin_x - world_anchor[0]) + e * (origin_y - world_anchor[1])
    premul = rgba.convert("RGBa")
    transformed = premul.transform(
        out_size,
        Image.Transform.AFFINE,
        (a, b, c, d, e, f),
        resample=Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    ).convert("RGBA")
    return transformed, (origin_x, origin_y)


def alpha_over(base: Image.Image, overlay: Image.Image, xy: tuple[int, int]) -> None:
    base.alpha_composite(overlay, dest=xy)


def panel_pair(before: Image.Image, after: Image.Image, left_label: str, right_label: str) -> Image.Image:
    if before.size != after.size:
        raise RuntimeError("panel sizes differ")
    bar = 32
    out = Image.new("RGB", (before.width * 2, before.height + bar), (24, 27, 29))
    out.paste(before.convert("RGB"), (0, bar))
    out.paste(after.convert("RGB"), (before.width, bar))
    draw = ImageDraw.Draw(out)
    draw.text((10, 9), left_label, fill=(226, 229, 229))
    draw.text((before.width + 10, 9), right_label, fill=(226, 229, 229))
    return out


def main() -> None:
    verify_inputs()
    OUT.mkdir(parents=True, exist_ok=True)
    TEXTURES.mkdir(parents=True, exist_ok=True)

    # Candidate runtime textures are byte-for-byte copies. Scale and placement
    # remain separate data, so no raw RGBA pixel is removed or repainted.
    candidate_sources = [ROPE, RUTS, MARKET]
    for source in candidate_sources:
        copy_exact(source, TEXTURES / source.name)

    rope_source_anchor = (152.5264485145448, 328.9355325742852)
    rope_world_anchor = (2189.04, 1693.9499545288086)
    rope_scale = 0.208
    rope_img, rope_origin = transformed_full_canvas(Image.open(ROPE), rope_source_anchor, rope_world_anchor, rope_scale)

    ruts_source_anchor = ((42.0 + 1744.0) / 2.0, (290.0 + 653.0) / 2.0)
    ruts_world_anchor = (870.0, 1555.0)
    ruts_scale = 500.0 / 1702.0
    ruts_img, ruts_origin = transformed_full_canvas(Image.open(RUTS), ruts_source_anchor, ruts_world_anchor, ruts_scale)

    market_source_anchor = ((12.0 + 2011.0) / 2.0, (8.0 + 771.0) / 2.0)
    market_world_anchor = (1530.0, 1196.0)
    market_scale = 960.0 / 1999.0
    market_img, market_origin = transformed_full_canvas(Image.open(MARKET), market_source_anchor, market_world_anchor, market_scale)

    # Docks cart-rut preview: exact current canonical floor, before/after crop.
    docks_floor = Image.open(DOCKS_FLOOR).convert("RGBA")
    docks_after = docks_floor.copy()
    alpha_over(docks_after, ruts_img, ruts_origin)
    docks_crop = (500, 1350, 1250, 1750)
    ruts_before_panel = docks_floor.crop(docks_crop)
    ruts_after_panel = docks_after.crop(docks_crop)
    ruts_preview = panel_pair(ruts_before_panel, ruts_after_panel, "CURRENT CANONICAL FLOOR", "OFFLINE RUTS CANDIDATE")
    ruts_preview_path = OUT / "docks_ruts_current_floor_before_after.png"
    save_new_or_exact(ruts_preview, ruts_preview_path)

    # Market preview: exact current canonical floor, before/after crop. It is
    # deliberately ground-only and does not claim prop/actor depth ordering.
    market_floor = Image.open(MARKET_FLOOR).convert("RGBA")
    market_after = market_floor.copy()
    alpha_over(market_after, market_img, market_origin)
    market_crop = (850, 850, 2210, 1520)
    market_before_panel = market_floor.crop(market_crop).resize((952, 469), Image.Resampling.LANCZOS)
    market_after_panel = market_after.crop(market_crop).resize((952, 469), Image.Resampling.LANCZOS)
    market_preview = panel_pair(market_before_panel, market_after_panel, "CURRENT CANONICAL FLOOR", "OFFLINE MARKET GROUND CANDIDATE")
    market_preview_path = OUT / "market_ground_current_floor_before_after.png"
    save_new_or_exact(market_preview, market_preview_path)

    # Rope preview uses the actual ordinary Field screenshot. Default camera
    # mapping is reconstructed from the pinned 1920x1080 viewport, zoom 1.05,
    # player foot and map-edge clamp. The rope is placed above the existing
    # wharf (-2) and then hidden again by the current ferry source alpha.
    base_actual = Image.open(DOCKS_ACTUAL).convert("RGBA")
    zoom = 1.05
    camera_top_left = (1225.7142857142858, 1019.4285714285716)
    rope_screen = rope_img.convert("RGBa").resize(
        (round(rope_img.width * zoom), round(rope_img.height * zoom)),
        Image.Resampling.BICUBIC,
    ).convert("RGBA")
    rope_screen_xy = (
        round((rope_origin[0] - camera_top_left[0]) * zoom),
        round((rope_origin[1] - camera_top_left[1]) * zoom),
    )
    rope_actual = base_actual.copy()
    alpha_over(rope_actual, rope_screen, rope_screen_xy)

    ferry_render_size_world = (307.2, 460.8)
    ferry_foot_uv = (0.6728515625, 0.9205729365348816)
    ferry_foot_world = (2653.0, 1824.0)
    ferry_top_left_world = (
        ferry_foot_world[0] - ferry_foot_uv[0] * ferry_render_size_world[0],
        ferry_foot_world[1] - ferry_foot_uv[1] * ferry_render_size_world[1],
    )
    ferry_screen_size = (round(ferry_render_size_world[0] * zoom), round(ferry_render_size_world[1] * zoom))
    ferry_alpha = Image.open(FERRY).convert("RGBA").getchannel("A").resize(ferry_screen_size, Image.Resampling.BICUBIC)
    ferry_xy = (
        round((ferry_top_left_world[0] - camera_top_left[0]) * zoom),
        round((ferry_top_left_world[1] - camera_top_left[1]) * zoom),
    )
    restore_mask = Image.new("L", base_actual.size, 0)
    restore_mask.paste(ferry_alpha, ferry_xy)
    rope_actual = Image.composite(base_actual, rope_actual, restore_mask)
    rope_crop = (850, 470, 1570, 900)
    rope_preview = panel_pair(base_actual.crop(rope_crop), rope_actual.crop(rope_crop), "ACTUAL FIELD REFERENCE", "OFFLINE ROPE LAYER CANDIDATE")
    rope_preview_path = OUT / "docks_rope_actual_field_before_after.png"
    save_new_or_exact(rope_preview, rope_preview_path)

    outputs = [
        *(TEXTURES / p.name for p in candidate_sources),
        ruts_preview_path,
        market_preview_path,
        rope_preview_path,
    ]
    report = {
        "schema": "luoyang_shore_market_runtime_candidates_v1",
        "status": "OFFLINE_CANDIDATES_AND_PREVIEWS_ONLY_NO_IMPORT_FIELD_OR_FORMAL_CREDIT",
        "source_pixels": "All three runtime candidate texture files are byte-for-byte copies of the complete raw RGBA files. Scaling/placement is data-only. Preview resampling does not replace the runtime textures.",
        "placements": [
            {
                "id": "docks_hawser_knot_right_v2",
                "texture": str((TEXTURES / ROPE.name).relative_to(ROOT)).replace("\\", "/"),
                "texture_sha256": sha(TEXTURES / ROPE.name),
                "uniform_scale": rope_scale,
                "rotation_degrees": 0.0,
                "source_anchor_px": list(rope_source_anchor),
                "world_anchor_px": list(rope_world_anchor),
                "derived_right_endpoint_world_px": [2564.5784987089746, 1720.7945637537574],
                "right_endpoint_existing_ferry_source_sample_px": [394, 1070],
                "right_endpoint_existing_ferry_source_alpha": 252,
                "z_index": -1,
                "ordering": "above dry_loading_wharf z=-2; below current ferry/actors",
                "solid": False,
                "nav_change": False,
            },
            {
                "id": "docks_cart_ruts_horizontal_v1",
                "texture": str((TEXTURES / RUTS.name).relative_to(ROOT)).replace("\\", "/"),
                "texture_sha256": sha(TEXTURES / RUTS.name),
                "uniform_scale": ruts_scale,
                "rotation_degrees": 0.0,
                "source_anchor_px": list(ruts_source_anchor),
                "world_anchor_px": list(ruts_world_anchor),
                "a_ge_16_world_bbox_target_px": [620.0, 1501.680376028202, 1120.0, 1608.319623971798],
                "z_index": -998,
                "solid": False,
                "nav_change": False,
            },
            {
                "id": "market_cross_street_stall_wear_patch_v1",
                "texture": str((TEXTURES / MARKET.name).relative_to(ROOT)).replace("\\", "/"),
                "texture_sha256": sha(TEXTURES / MARKET.name),
                "uniform_scale": market_scale,
                "rotation_degrees": 0.0,
                "source_anchor_px": list(market_source_anchor),
                "world_anchor_px": list(market_world_anchor),
                "a_ge_16_world_bbox_target_px": [1050.0, 1012.816408204102, 2010.0, 1379.183591795898],
                "z_index": -998,
                "solid": False,
                "nav_change": False,
            },
        ],
        "preview_sources": {
            "docks_floor": {"path": str(DOCKS_FLOOR.relative_to(ROOT)).replace("\\", "/"), "sha256": sha(DOCKS_FLOOR)},
            "market_floor": {"path": str(MARKET_FLOOR.relative_to(ROOT)).replace("\\", "/"), "sha256": sha(MARKET_FLOOR)},
            "docks_actual": {"path": str(DOCKS_ACTUAL.relative_to(ROOT)).replace("\\", "/"), "sha256": sha(DOCKS_ACTUAL)},
            "ferry_occlusion_source": {"path": str(FERRY.relative_to(ROOT)).replace("\\", "/"), "sha256": sha(FERRY)},
        },
        "outputs": [
            {"path": str(path.relative_to(ROOT)).replace("\\", "/"), "sha256": sha(path), "bytes": path.stat().st_size}
            for path in outputs
        ],
        "credit_boundary": "Offline art comparison only. No import, runtime binding, Field visibility, layering proof, collision, NAV, interaction, gameplay or formal credit.",
    }
    report_path = OUT / "runtime_candidate_report.json"
    report_text = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if report_path.exists() and report_path.read_text(encoding="utf-8") != report_text:
        raise RuntimeError(f"refusing to replace different report: {report_path}")
    report_path.write_text(report_text, encoding="utf-8", newline="\n")
    print(json.dumps({"report": str(report_path), "sha256": sha(report_path), "outputs": len(outputs)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
