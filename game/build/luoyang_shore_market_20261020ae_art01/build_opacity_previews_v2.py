from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path

from PIL import Image


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
V1_SCRIPT = HERE / "build_runtime_candidates_and_previews.py"
SPEC = importlib.util.spec_from_file_location("ae_v1_builder", V1_SCRIPT)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("cannot load v1 builder")
V1 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(V1)

OUT = HERE / "runtime_candidates_v2_opacity"


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def set_opacity(image: Image.Image, opacity: float) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A").point(lambda value: round(value * opacity))
    rgba.putalpha(alpha)
    return rgba


def main() -> None:
    V1.verify_inputs()
    OUT.mkdir(parents=True, exist_ok=True)

    rope_scale = 0.208
    rope_source_anchor = (152.5264485145448, 328.9355325742852)
    rope_world_anchor = (2189.04, 1693.9499545288086)
    rope_img, rope_origin = V1.transformed_full_canvas(Image.open(V1.ROPE), rope_source_anchor, rope_world_anchor, rope_scale)
    rope_img = set_opacity(rope_img, 0.85)

    ruts_scale = 500.0 / 1702.0
    ruts_source_anchor = (893.0, 471.5)
    ruts_world_anchor = (870.0, 1555.0)
    ruts_img, ruts_origin = V1.transformed_full_canvas(Image.open(V1.RUTS), ruts_source_anchor, ruts_world_anchor, ruts_scale)
    ruts_img = set_opacity(ruts_img, 0.32)

    # Market v2 is fitted from the complete 2024x777 source canvas, not its
    # A>=16 bbox. This preserves FIRST_CLUSTER.encloses geometry expectations.
    market_scale = min(960.0 / 2024.0, 368.0 / 777.0)
    market_source_anchor = (2024.0 / 2.0, 777.0 / 2.0)
    market_world_anchor = (1530.0, 1196.0)
    market_img, market_origin = V1.transformed_full_canvas(Image.open(V1.MARKET), market_source_anchor, market_world_anchor, market_scale)
    market_img = set_opacity(market_img, 0.38)

    docks_floor = Image.open(V1.DOCKS_FLOOR).convert("RGBA")
    docks_after = docks_floor.copy()
    V1.alpha_over(docks_after, ruts_img, ruts_origin)
    docks_crop = (500, 1350, 1250, 1750)
    ruts_preview = V1.panel_pair(docks_floor.crop(docks_crop), docks_after.crop(docks_crop), "CURRENT CANONICAL FLOOR", "OFFLINE RUTS OPACITY 0.32")
    ruts_preview_path = OUT / "docks_ruts_opacity032_before_after.png"
    V1.save_new_or_exact(ruts_preview, ruts_preview_path)

    market_floor = Image.open(V1.MARKET_FLOOR).convert("RGBA")
    market_after = market_floor.copy()
    V1.alpha_over(market_after, market_img, market_origin)
    market_crop = (850, 850, 2210, 1520)
    market_before_panel = market_floor.crop(market_crop).resize((952, 469), Image.Resampling.LANCZOS)
    market_after_panel = market_after.crop(market_crop).resize((952, 469), Image.Resampling.LANCZOS)
    market_preview = V1.panel_pair(market_before_panel, market_after_panel, "CURRENT CANONICAL FLOOR", "OFFLINE MARKET OPACITY 0.38 FULL-CANVAS FIT")
    market_preview_path = OUT / "market_ground_opacity038_full_canvas_before_after.png"
    V1.save_new_or_exact(market_preview, market_preview_path)

    base_actual = Image.open(V1.DOCKS_ACTUAL).convert("RGBA")
    zoom = 1.05
    camera_top_left = (1225.7142857142858, 1019.4285714285716)
    rope_screen = rope_img.convert("RGBa").resize((round(rope_img.width * zoom), round(rope_img.height * zoom)), Image.Resampling.BICUBIC).convert("RGBA")
    rope_screen_xy = (round((rope_origin[0] - camera_top_left[0]) * zoom), round((rope_origin[1] - camera_top_left[1]) * zoom))
    rope_actual = base_actual.copy()
    V1.alpha_over(rope_actual, rope_screen, rope_screen_xy)
    ferry_render_size_world = (307.2, 460.8)
    ferry_foot_uv = (0.6728515625, 0.9205729365348816)
    ferry_foot_world = (2653.0, 1824.0)
    ferry_top_left_world = (ferry_foot_world[0] - ferry_foot_uv[0] * ferry_render_size_world[0], ferry_foot_world[1] - ferry_foot_uv[1] * ferry_render_size_world[1])
    ferry_screen_size = (round(ferry_render_size_world[0] * zoom), round(ferry_render_size_world[1] * zoom))
    ferry_alpha = Image.open(V1.FERRY).convert("RGBA").getchannel("A").resize(ferry_screen_size, Image.Resampling.BICUBIC)
    ferry_xy = (round((ferry_top_left_world[0] - camera_top_left[0]) * zoom), round((ferry_top_left_world[1] - camera_top_left[1]) * zoom))
    restore_mask = Image.new("L", base_actual.size, 0)
    restore_mask.paste(ferry_alpha, ferry_xy)
    rope_actual = Image.composite(base_actual, rope_actual, restore_mask)
    rope_crop = (850, 470, 1570, 900)
    rope_preview = V1.panel_pair(base_actual.crop(rope_crop), rope_actual.crop(rope_crop), "ACTUAL FIELD REFERENCE", "OFFLINE ROPE OPACITY 0.85")
    rope_preview_path = OUT / "docks_rope_opacity085_before_after.png"
    V1.save_new_or_exact(rope_preview, rope_preview_path)

    textures = HERE / "runtime_candidates_v1/textures"
    overlay_admission = [
        {
            "id": "docks_hawser_knot_right_v2",
            "texture_path": str((textures / V1.ROPE.name).relative_to(ROOT)).replace("\\", "/"),
            "texture_sha256": sha(textures / V1.ROPE.name),
            "center_world_px": [2361.050498708975, 1709.0433637533572],
            "uniform_scale": rope_scale,
            "opacity": 0.85,
            "z_index": -1
        },
        {
            "id": "docks_cart_ruts_horizontal_v1",
            "texture_path": str((textures / V1.RUTS.name).relative_to(ROOT)).replace("\\", "/"),
            "texture_sha256": sha(textures / V1.RUTS.name),
            "center_world_px": [868.2373678025851, 1546.7743830787308],
            "uniform_scale": ruts_scale,
            "opacity": 0.32,
            "z_index": -998
        },
        {
            "id": "market_cross_street_stall_wear_patch_v1",
            "texture_path": str((textures / V1.MARKET.name).relative_to(ROOT)).replace("\\", "/"),
            "texture_sha256": sha(textures / V1.MARKET.name),
            "center_world_px": [1530.0, 1196.0],
            "uniform_scale": market_scale,
            "opacity": 0.38,
            "z_index": -998
        }
    ]
    report = {
        "schema": "luoyang_shore_market_overlay_admission_v2",
        "status": "OFFLINE_OPACITY_PREVIEW_ONLY_ROOT_ART_REVIEW_PENDING",
        "texture_bytes_unchanged": True,
        "overlay_admission_exact_seven_keys_each": overlay_admission,
        "placement_basis": {
            "rope": "prompts/luoyang_shore_market_20261020ae/rope_successor_authored_sag_measurement.json",
            "ruts": "A>=16 authored track width 1702px mapped to 500 world px; full canvas preserved",
            "market": "complete 2024x777 canvas fitted by min(960/full_width,368/full_height), centered at [1530,1196]"
        },
        "previews": [
            {"path": str(rope_preview_path.relative_to(ROOT)).replace("\\", "/"), "sha256": sha(rope_preview_path)},
            {"path": str(ruts_preview_path.relative_to(ROOT)).replace("\\", "/"), "sha256": sha(ruts_preview_path)},
            {"path": str(market_preview_path.relative_to(ROOT)).replace("\\", "/"), "sha256": sha(market_preview_path)}
        ],
        "credit_boundary": "Offline opacity and placement review only; no candidate PNG bytes changed, no import/runtime binding/Field/collision/NAV/formal credit."
    }
    report_path = OUT / "overlay_admission_v2.json"
    text = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if report_path.exists() and report_path.read_text(encoding="utf-8") != text:
        raise RuntimeError(f"refusing to replace different report: {report_path}")
    report_path.write_text(text, encoding="utf-8", newline="\n")
    print(json.dumps({"report": str(report_path), "sha256": sha(report_path), "previews": len(report["previews"])}, ensure_ascii=False))


if __name__ == "__main__":
    main()
