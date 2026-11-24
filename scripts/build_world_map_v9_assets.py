"""Build the v9 map, mask and QA artifacts from one surveyed road source.

V8's reviewed terrain is preserved. V9 adds a restrained, deterministic road
clarity treatment from the exact mask used by movement, then builds both mobile
and desktop sources from the same geometry. Changing the terrain or topology
invalidates the recorded hashes and requires a rebuild/review.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter
from scipy.ndimage import binary_erosion, label

from world_map_v9_road_source import (
    AUTHORING_SIZE,
    BLOCKED,
    FOOT_RADIUS,
    LOGICAL_SIZE,
    PORTALS,
    ROAD_CHECK_SECTIONS,
    ROAD_EDGE_ALPHA,
    ROAD_HIGHLIGHT_ALPHA,
    ROAD_SURFACES,
    ROAD_TINT,
    ROAD_TINT_ALPHA,
    ROUTES,
    SCHEMA_VERSION,
    WALKABLE,
)


ROOT = Path(__file__).resolve().parents[1]
MOBILE_SOURCE = ROOT / "game/art/backgrounds/region_masters_v2/bg_world_map_jianghu_v8_2304.png"
DESKTOP_SOURCE = ROOT / "assets/raw/scene_background/later_regions_codex_builtin_v2/bg_world_map_jianghu_v8_pc_4608.png"
MOBILE_OUT = ROOT / "game/art/backgrounds/region_masters_v2/bg_world_map_jianghu_v9_2304.png"
DESKTOP_OUT = ROOT / "assets/raw/scene_background/world_map_v9_shared_road_source/bg_world_map_jianghu_v9_pc_4608.png"
MASK_OUT = ROOT / "game/art/navigation_masks/world_map_jianghu_walk_v9.png"
OUT = ROOT / "assets/processed/scene/world_map_v9"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def canonical_payload() -> dict[str, object]:
    return {
        "schema_version": SCHEMA_VERSION,
        "authoring_size": AUTHORING_SIZE,
        "logical_size": LOGICAL_SIZE,
        "foot_radius": FOOT_RADIUS,
        "routes": ROUTES,
        "road_surfaces": ROAD_SURFACES,
        "portals": PORTALS,
        "road_check_sections": ROAD_CHECK_SECTIONS,
        "walkable_witnesses": WALKABLE,
        "blocked_witnesses": BLOCKED,
    }


def source_hash() -> str:
    raw = json.dumps(canonical_payload(), ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def point_at(point: tuple[int, int], size: tuple[int, int]) -> tuple[int, int]:
    return (
        round(point[0] * size[0] / AUTHORING_SIZE[0]),
        round(point[1] * size[1] / AUTHORING_SIZE[1]),
    )


def build_mask(size: tuple[int, int]) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    scale = size[0] / AUTHORING_SIZE[0]
    for _name, width, route in ROUTES:
        points = [point_at(point, size) for point in route]
        scaled_width = max(1, round(width * scale))
        draw.line(points, fill=255, width=scaled_width, joint="curve")
        radius = scaled_width / 2
        for x, y in points:
            draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=255)
    for polygon in ROAD_SURFACES.values():
        draw.polygon([point_at(point, size) for point in polygon], fill=255)
    return mask


def enhance_roads(source: Image.Image, mask: Image.Image) -> Image.Image:
    """Clarify only the authoritative road band while retaining source detail."""
    base = source.convert("RGB")
    blur_radius = max(2.0, source.width / 1152.0)
    soft = mask.filter(ImageFilter.GaussianBlur(radius=blur_radius))
    tint_alpha = soft.point(lambda value: round(value * ROAD_TINT_ALPHA / 255))
    result = Image.composite(Image.new("RGB", base.size, ROAD_TINT), base, tint_alpha)

    inner_filter = 7 if source.width <= LOGICAL_SIZE[0] else 13
    inner = mask.filter(ImageFilter.MinFilter(inner_filter))
    highlight_alpha = inner.point(lambda value: round(value * ROAD_HIGHLIGHT_ALPHA / 255))
    result = Image.composite(Image.new("RGB", base.size, (246, 224, 178)), result, highlight_alpha)

    outer_filter = 9 if source.width <= LOGICAL_SIZE[0] else 17
    outer = mask.filter(ImageFilter.MaxFilter(outer_filter))
    edge = ImageChops.subtract(outer, mask)
    edge_alpha = edge.point(lambda value: round(value * ROAD_EDGE_ALPHA / 255))
    return Image.composite(Image.new("RGB", base.size, (91, 75, 48)), result, edge_alpha)


def validate(mask: Image.Image) -> dict[str, object]:
    data = np.asarray(mask) > 0
    yy, xx = np.ogrid[-FOOT_RADIUS : FOOT_RADIUS + 1, -FOOT_RADIUS : FOOT_RADIUS + 1]
    safe = binary_erosion(data, structure=xx * xx + yy * yy <= FOOT_RADIUS * FOOT_RADIUS)
    labels, _count = label(safe)
    components: dict[str, int] = {}
    for name, point in PORTALS.items():
        x, y = point_at(point, LOGICAL_SIZE)
        component = int(labels[y, x])
        if component == 0:
            raise AssertionError(f"{name}: no {FOOT_RADIUS}px foot clearance")
        components[name] = component
    if len(set(components.values())) != 1:
        raise AssertionError(f"Disconnected portals: {components}")
    main_component = next(iter(components.values()))

    centerline_samples = 0
    for name, _width, route in ROUTES:
        for start, end in zip(route, route[1:]):
            a = np.asarray(point_at(start, LOGICAL_SIZE), dtype=float)
            b = np.asarray(point_at(end, LOGICAL_SIZE), dtype=float)
            count = max(2, round(float(np.linalg.norm(b - a)) / 2) + 1)
            for position in np.linspace(a, b, count):
                x, y = np.rint(position).astype(int)
                if labels[y, x] != main_component:
                    raise AssertionError(f"{name}: unsafe/disconnected centre at {x},{y}")
                centerline_samples += 1

    for name, point in WALKABLE.items():
        x, y = point_at(point, LOGICAL_SIZE)
        if labels[y, x] != main_component:
            raise AssertionError(f"Visible road blocked: {name} {point}")
    for name, point in BLOCKED.items():
        x, y = point_at(point, LOGICAL_SIZE)
        if data[y, x]:
            raise AssertionError(f"Blocked terrain opened: {name} {point}")

    section_samples = 0
    section_covered = 0
    for start, end in ROAD_CHECK_SECTIONS.values():
        a = np.asarray(point_at(start, LOGICAL_SIZE), dtype=float)
        b = np.asarray(point_at(end, LOGICAL_SIZE), dtype=float)
        count = max(2, round(float(np.linalg.norm(b - a))) + 1)
        for position in np.linspace(a, b, count):
            x, y = np.rint(position).astype(int)
            section_samples += 1
            section_covered += int(data[y, x])
    if section_covered != section_samples:
        raise AssertionError(f"Visible road surface gaps: {section_covered}/{section_samples}")

    return {
        "schema_version": SCHEMA_VERSION,
        "logical_size": LOGICAL_SIZE,
        "route_source_sha256": source_hash(),
        "route_count": len(ROUTES),
        "portal_count": len(PORTALS),
        "all_portals_connected": True,
        "foot_clearance_px": FOOT_RADIUS,
        "centerline_foot_clearance_samples": centerline_samples,
        "registered_surface_samples": section_samples,
        "registered_surface_covered": section_covered,
        "walkable_witnesses": len(WALKABLE),
        "blocked_witnesses": len(BLOCKED),
        "walkable_pixels": int(data.sum()),
    }


def write_overlay(background: Image.Image, mask: Image.Image) -> None:
    overlay = background.convert("RGBA")
    tint = Image.new("RGBA", background.size, (20, 235, 170, 0))
    tint.putalpha(mask.point(lambda value: 105 if value else 0))
    overlay = Image.alpha_composite(overlay, tint)
    draw = ImageDraw.Draw(overlay)
    for name, point in PORTALS.items():
        x, y = point_at(point, background.size)
        draw.ellipse((x - 6, y - 6, x + 6, y + 6), fill="yellow", outline="black", width=2)
        draw.text((x + 8, y - 8), name, fill="white", stroke_width=2, stroke_fill="black")
    overlay.save(OUT / "world_map_v9_navigation_overlay.png", optimize=True)


def main() -> None:
    mobile = Image.open(MOBILE_SOURCE).convert("RGB")
    desktop = Image.open(DESKTOP_SOURCE).convert("RGB")
    if mobile.size != LOGICAL_SIZE or desktop.size != (LOGICAL_SIZE[0] * 2, LOGICAL_SIZE[1] * 2):
        raise ValueError(f"Unexpected source sizes: mobile={mobile.size} desktop={desktop.size}")
    mobile_mask = build_mask(LOGICAL_SIZE)
    desktop_mask = build_mask(desktop.size)
    report = validate(mobile_mask)

    OUT.mkdir(parents=True, exist_ok=True)
    MOBILE_OUT.parent.mkdir(parents=True, exist_ok=True)
    DESKTOP_OUT.parent.mkdir(parents=True, exist_ok=True)
    MASK_OUT.parent.mkdir(parents=True, exist_ok=True)
    mobile_v9 = enhance_roads(mobile, mobile_mask)
    desktop_v9 = enhance_roads(desktop, desktop_mask)
    mobile_v9.save(MOBILE_OUT, optimize=True, compress_level=6)
    desktop_v9.save(DESKTOP_OUT, optimize=True, compress_level=5)
    mobile_mask.save(MASK_OUT, optimize=True)
    write_overlay(mobile_v9, mobile_mask)

    route_contract = canonical_payload()
    route_contract["route_source_sha256"] = source_hash()
    (OUT / "road_source_v9.json").write_text(
        json.dumps(route_contract, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    report.update(
        {
            "mobile_source_sha256": sha256(MOBILE_SOURCE),
            "desktop_source_sha256": sha256(DESKTOP_SOURCE),
            "mobile_background_sha256": sha256(MOBILE_OUT),
            "desktop_background_sha256": sha256(DESKTOP_OUT),
            "mask_sha256": sha256(MASK_OUT),
            "visual_and_navigation_share_route_source": True,
        }
    )
    (OUT / "navigation_validation.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
