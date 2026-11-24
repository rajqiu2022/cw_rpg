"""Build v10 runtime art, navigation and QA from the sparse-map source."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter
from scipy.ndimage import binary_erosion, label

from world_map_v10_road_source import (
    AUTHORING_SIZE,
    BLOCKED,
    FOOT_RADIUS,
    LOGICAL_SIZE,
    OPEN_REGIONS,
    PORTALS,
    ROAD_EDGE_ALPHA,
    ROAD_TINT,
    ROAD_TINT_ALPHA,
    ROUTES,
    SCHEMA_VERSION,
    WALKABLE,
)

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/raw/scene_background/world_map_v10_open_plain/bg_world_map_jianghu_v10_source.png"
MOBILE_OUT = ROOT / "game/art/backgrounds/region_masters_v2/bg_world_map_jianghu_v10_2304.png"
DESKTOP_OUT = ROOT / "assets/raw/scene_background/world_map_v10_open_plain/bg_world_map_jianghu_v10_pc_4608.png"
MASK_OUT = ROOT / "game/art/navigation_masks/world_map_jianghu_walk_v10.png"
OUT = ROOT / "assets/processed/scene/world_map_v10"


def point_at(point: tuple[int, int], size: tuple[int, int]) -> tuple[int, int]:
    return (round(point[0] * size[0] / AUTHORING_SIZE[0]), round(point[1] * size[1] / AUTHORING_SIZE[1]))


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def route_payload() -> dict[str, object]:
    return {
        "schema_version": SCHEMA_VERSION,
        "authoring_size": AUTHORING_SIZE,
        "logical_size": LOGICAL_SIZE,
        "foot_radius": FOOT_RADIUS,
        "routes": ROUTES,
        "open_regions": OPEN_REGIONS,
        "closed_regions": globals().get("CLOSED_REGIONS", {}),
        "portals": PORTALS,
        "walkable": WALKABLE,
        "blocked": BLOCKED,
    }


def source_hash() -> str:
    raw = json.dumps(route_payload(), ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def draw_routes(size: tuple[int, int]) -> Image.Image:
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
    return mask


def build_mask(size: tuple[int, int]) -> tuple[Image.Image, Image.Image]:
    route_mask = draw_routes(size)
    mask = route_mask.copy()
    draw = ImageDraw.Draw(mask)
    for polygon in OPEN_REGIONS.values():
        draw.polygon([point_at(point, size) for point in polygon], fill=255)
    # Exclusion terrain is authoritative. Repainting every road after this
    # carve reopened city roofs and even sea routes whenever a centerline was
    # authored too far into a landmark. Gate approaches end outside the
    # exclusion footprint and are validated as normal route segments.
    for polygon in globals().get("CLOSED_REGIONS", {}).values():
        draw.polygon([point_at(point, size) for point in polygon], fill=0)
    return mask, route_mask


def enhance_roads(source: Image.Image, route_mask: Image.Image) -> Image.Image:
    base = source.convert("RGB")
    soft = route_mask.filter(ImageFilter.GaussianBlur(radius=max(2.0, source.width / 1200.0)))
    tint_alpha = soft.point(lambda value: round(value * ROAD_TINT_ALPHA / 255))
    result = Image.composite(Image.new("RGB", base.size, ROAD_TINT), base, tint_alpha)
    outer = route_mask.filter(ImageFilter.MaxFilter(9 if source.width <= LOGICAL_SIZE[0] else 17))
    edge = ImageChops.subtract(outer, route_mask)
    edge_alpha = edge.point(lambda value: round(value * ROAD_EDGE_ALPHA / 255))
    return Image.composite(Image.new("RGB", base.size, (89, 75, 49)), result, edge_alpha)


def validate(mask: Image.Image) -> dict[str, object]:
    data = np.asarray(mask) > 0
    yy, xx = np.ogrid[-FOOT_RADIUS : FOOT_RADIUS + 1, -FOOT_RADIUS : FOOT_RADIUS + 1]
    safe = binary_erosion(data, structure=xx * xx + yy * yy <= FOOT_RADIUS * FOOT_RADIUS)
    labels, _ = label(safe)
    components: dict[str, int] = {}
    for name, point in PORTALS.items():
        x, y = point_at(point, LOGICAL_SIZE)
        component = int(labels[y, x])
        if component == 0:
            raise AssertionError(f"{name}: portal lacks foot clearance")
        components[name] = component
    if len(set(components.values())) != 1:
        raise AssertionError(f"portals disconnected: {components}")
    main = next(iter(components.values()))

    center_samples = 0
    for name, _width, route in ROUTES:
        for start, end in zip(route, route[1:]):
            a = np.asarray(point_at(start, LOGICAL_SIZE), dtype=float)
            b = np.asarray(point_at(end, LOGICAL_SIZE), dtype=float)
            count = max(2, round(float(np.linalg.norm(b - a)) / 2) + 1)
            for point in np.linspace(a, b, count):
                x, y = np.rint(point).astype(int)
                if labels[y, x] != main:
                    raise AssertionError(f"{name}: unsafe centerline {x},{y}")
                center_samples += 1
    for name, point in WALKABLE.items():
        x, y = point_at(point, LOGICAL_SIZE)
        if labels[y, x] != main:
            raise AssertionError(f"open-region witness blocked: {name}")
    for name, point in BLOCKED.items():
        x, y = point_at(point, LOGICAL_SIZE)
        if data[y, x]:
            raise AssertionError(f"blocked terrain opened: {name}")

    open_area = int(data.sum())
    ratio = open_area / (LOGICAL_SIZE[0] * LOGICAL_SIZE[1])
    if ratio < 0.22:
        raise AssertionError(f"map remains too corridor-dense: open ratio={ratio:.3f}")
    return {
        "schema_version": SCHEMA_VERSION,
        "route_source_sha256": source_hash(),
        "route_count": len(ROUTES),
        "open_region_count": len(OPEN_REGIONS),
        "portal_count": len(PORTALS),
        "all_portals_connected": True,
        "centerline_foot_samples": center_samples,
        "walkable_pixels": open_area,
        "walkable_ratio": round(ratio, 4),
        "minimum_authored_road_width": min(width for _name, width, _route in ROUTES),
    }


def write_overlay(background: Image.Image, mask: Image.Image) -> None:
    overlay = background.convert("RGBA")
    tint = Image.new("RGBA", background.size, (20, 235, 170, 0))
    tint.putalpha(mask.point(lambda value: 88 if value else 0))
    overlay = Image.alpha_composite(overlay, tint)
    draw = ImageDraw.Draw(overlay)
    for name, point in PORTALS.items():
        x, y = point_at(point, background.size)
        draw.ellipse((x - 8, y - 8, x + 8, y + 8), fill="yellow", outline="black", width=2)
        draw.text((x + 10, y - 10), name, fill="white", stroke_width=2, stroke_fill="black")
    overlay.save(OUT / f"world_map_v{SCHEMA_VERSION}_navigation_overlay.png", optimize=True)


def main() -> None:
    source = Image.open(SOURCE).convert("RGB")
    if source.size != AUTHORING_SIZE:
        raise ValueError(f"unexpected ImageGen source size: {source.size}")
    mobile_source = source.resize(LOGICAL_SIZE, Image.Resampling.LANCZOS)
    desktop_source = source.resize((LOGICAL_SIZE[0] * 2, LOGICAL_SIZE[1] * 2), Image.Resampling.LANCZOS)
    mobile_mask, mobile_routes = build_mask(LOGICAL_SIZE)
    desktop_mask, desktop_routes = build_mask(desktop_source.size)
    report = validate(mobile_mask)

    OUT.mkdir(parents=True, exist_ok=True)
    MOBILE_OUT.parent.mkdir(parents=True, exist_ok=True)
    DESKTOP_OUT.parent.mkdir(parents=True, exist_ok=True)
    MASK_OUT.parent.mkdir(parents=True, exist_ok=True)
    mobile = enhance_roads(mobile_source, mobile_routes)
    desktop = enhance_roads(desktop_source, desktop_routes)
    mobile.save(MOBILE_OUT, optimize=True, compress_level=6)
    desktop.save(DESKTOP_OUT, optimize=True, compress_level=5)
    mobile_mask.save(MASK_OUT, optimize=True)
    write_overlay(mobile, mobile_mask)

    payload = route_payload()
    payload["route_source_sha256"] = source_hash()
    (OUT / f"road_source_v{SCHEMA_VERSION}.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    report.update({
        "imagegen_source_sha256": sha256(SOURCE),
        "runtime_background_sha256": sha256(MOBILE_OUT),
        "desktop_background_sha256": sha256(DESKTOP_OUT),
        "navigation_mask_sha256": sha256(MASK_OUT),
        "visual_and_navigation_share_route_source": True,
    })
    (OUT / "navigation_validation.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
