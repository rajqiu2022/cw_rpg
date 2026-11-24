from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "rope_successor_anchor_measurement.json"
BUILDER = ROOT / "game/scripts/dev/luoyang_docks_native_structures_v12_preview.gd"
WHARF = ROOT / "game/art/maps/luoyang_enclosure_v11/ch4_s2_canal_docks/native_v12/root_native_docks_v12_01/dry_loading_wharf.json"
COMPONENTS = ROOT / "game/art/maps/luoyang_harbour_life_20261016/components-author-v1.json"
LAYOUT = ROOT / "game/build/luoyang_harbour_life_publication_20261016/93032_1727/ch4_s2_canal_docks/layout.tres"
FERRY = ROOT / "game/art/maps/luoyang_harbour_life_20261016/covered_ferry_v1.png"

EXPECTED_SHA = {
    BUILDER: "845B0683567C6156967D25293096F791A6F8744E206CE61E59834E6F5EBE44E4",
    WHARF: "E6E21C336B06376FD1FED432A93700FE3176507B6AE6B222F33BE1FA44AD7F0E",
    COMPONENTS: "920A06CA4E2390C831215C643C9BDE5263F85D64CA1B3472CFA9A52021D8B2BB",
    LAYOUT: "49DB163A97BAC5D0A89087D85300749521C3204B02BAA485457ACCD6D1EF4804",
    FERRY: "D67140A7AFA0FDFFFFF97DE9E34A0680B0069FC9DBD05BBCF85FB7E4EF989357",
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


for path, expected in EXPECTED_SHA.items():
    actual = sha256(path)
    if actual != expected:
        raise SystemExit(f"source SHA mismatch: {path}: {actual}")

builder = BUILDER.read_text(encoding="utf-8")
required_builder_literals = [
    "for z in [-2.5,2.5]:",
    '_box(Vector3(.61,.31,z),Vector3(.17,.62,.17),"dark_timber")',
    '_box(Vector3(.61,.61,z),Vector3(.27,.08,.23),"dark_timber")',
    '_box(Vector3(.61,.47,z),Vector3(.37,.075,.075),"dark_timber")',
]
if any(text not in builder for text in required_builder_literals):
    raise SystemExit("pinned wharf post source literals changed")

wharf = json.loads(WHARF.read_text(encoding="utf-8"))
components = json.loads(COMPONENTS.read_text(encoding="utf-8"))
ferry_component = next(row for row in components["components"] if row["id"] == "covered_ferry_v1")
layout_text = LAYOUT.read_text(encoding="utf-8")
match = re.search(
    r'"id": "harbour_covered_ferry".*?"physical_center_px": \[([0-9.]+), ([0-9.]+)\].*?'
    r'"render_size_px": Vector2\(([0-9.]+), ([0-9.]+)\).*?'
    r'"source_sha256": "([0-9a-f]+)".*?"source_size_px": \[([0-9.]+), ([0-9.]+)\]',
    layout_text,
    re.S,
)
if not match:
    raise SystemExit("actual ferry layout record not found")

physical_center = [float(match.group(1)), float(match.group(2))]
render_size = [float(match.group(3)), float(match.group(4))]
source_sha = match.group(5).upper()
source_size = [float(match.group(6)), float(match.group(7))]
if source_sha != EXPECTED_SHA[FERRY] or source_size != [1024.0, 1536.0]:
    raise SystemExit("actual ferry source identity changed")
scale_x = render_size[0] / source_size[0]
scale_y = render_size[1] / source_size[1]
if abs(scale_x - 0.3) > 1e-6 or abs(scale_y - 0.3) > 1e-6:
    raise SystemExit("actual ferry scale changed")

foot = [float(wharf["world_foot_px"][0]), float(wharf["world_foot_px"][1])]
px_x = float(wharf["raw_camera"]["logical_pixels_per_world_m_x"])
px_z = float(wharf["raw_camera"]["logical_pixels_per_world_m_ground_z"])
vertical_px_per_m = float(wharf["raw_camera"]["basis_columns"][1][1]) * px_x
post_x_m = 0.61
tie_y_m = 0.47


def post_anchor(z_m: float) -> list[float]:
    return [foot[0] + post_x_m * px_x, foot[1] + z_m * px_z - tie_y_m * vertical_px_per_m]


north_post = post_anchor(-2.5)
south_post = post_anchor(2.5)
ground_anchor = [float(v) for v in ferry_component["source_ground_anchor_px"]]
origin = [physical_center[0] - ground_anchor[0] * scale_x,
          physical_center[1] - ground_anchor[1] * scale_y]

image = Image.open(FERRY).convert("RGBA")


def ferry_left_hull_at_world_y(world_y: float, alpha_floor: int = 16) -> dict[str, object]:
    source_y_float = (world_y - origin[1]) / scale_y
    source_y = int(round(source_y_float))
    candidates = [x for x in range(image.width) if image.getpixel((x, source_y))[3] >= alpha_floor]
    if not candidates:
        raise SystemExit(f"no ferry hull support at source row {source_y}")
    source_x = min(candidates)
    alpha = image.getpixel((source_x, source_y))[3]
    return {
        "source_px": [source_x, source_y],
        "source_y_float_before_round": source_y_float,
        "alpha": alpha,
        "alpha_floor": alpha_floor,
        "world_px": [origin[0] + source_x * scale_x, origin[1] + source_y * scale_y],
    }


north_hull = ferry_left_hull_at_world_y(north_post[1])
south_hull = ferry_left_hull_at_world_y(south_post[1])
selected_length = south_hull["world_px"][0] - south_post[0]

report = {
    "schema": "luoyang_shore_market_rope_successor_anchor_measurement_v1",
    "passed": True,
    "method": "Read-only projection from pinned native wharf post source plus actual published ferry transform; ferry right endpoint is the leftmost A>=16 pixel at the selected rope row.",
    "source_pins": {str(path.relative_to(ROOT)).replace("\\", "/"): expected for path, expected in EXPECTED_SHA.items()},
    "wharf_projection": {
        "world_foot_px": foot,
        "post_source_local_m": {"x": post_x_m, "tie_y": tie_y_m, "z_values": [-2.5, 2.5]},
        "logical_px_per_m": {"x": px_x, "ground_z": px_z, "vertical_y": vertical_px_per_m},
        "native_post_wrap_anchors_world_px": {"north": north_post, "south": south_post},
    },
    "actual_ferry_transform": {
        "physical_center_px": physical_center,
        "source_ground_anchor_px": ground_anchor,
        "uniform_scale": scale_x,
        "world_origin_px": origin,
        "render_size_px": render_size,
    },
    "candidate_pairs": {
        "north_post_to_ferry": {"left_world_px": north_post, "right_hull": north_hull},
        "south_post_to_ferry": {"left_world_px": south_post, "right_hull": south_hull},
    },
    "selected_pair": {
        "reason": "South post is nearest the current covered-ferry working line and produces an almost horizontal loaded hawser.",
        "left_existing_wharf_south_post_wrap_center_world_px": south_post,
        "right_inside_existing_ferry_left_hull_a16_world_px": south_hull["world_px"],
        "right_source_px": south_hull["source_px"],
        "right_source_alpha": south_hull["alpha"],
        "horizontal_span_px": selected_length,
        "vertical_delta_px": south_hull["world_px"][1] - south_post[1],
    },
    "credit_boundary": "Coordinate/source proof only. No rope image, import, placement, collision, NAV, Field or formal credit.",
}
OUT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
print(json.dumps({"passed": True, "selected_pair": report["selected_pair"]}, ensure_ascii=False))
