"""Build v11 art/navigation by reusing the proven v10 synchronized pipeline."""

from pathlib import Path

import build_world_map_v10_assets as builder
import world_map_v11_road_source as source


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    for name in (
        "AUTHORING_SIZE", "BLOCKED", "CLOSED_REGIONS", "FOOT_RADIUS", "LOGICAL_SIZE", "OPEN_REGIONS",
        "PORTALS", "ROAD_EDGE_ALPHA", "ROAD_TINT", "ROAD_TINT_ALPHA", "ROUTES",
        "SCHEMA_VERSION", "WALKABLE",
    ):
        setattr(builder, name, getattr(source, name))
    builder.SOURCE = ROOT / "assets/raw/scene_background/world_map_v11_realistic/bg_world_map_jianghu_v11_source.png"
    builder.MOBILE_OUT = ROOT / "game/art/backgrounds/region_masters_v2/bg_world_map_jianghu_v11_2304.png"
    builder.DESKTOP_OUT = ROOT / "assets/raw/scene_background/world_map_v11_realistic/bg_world_map_jianghu_v11_pc_4608.png"
    builder.MASK_OUT = ROOT / "game/art/navigation_masks/world_map_jianghu_walk_v11.png"
    builder.OUT = ROOT / "assets/processed/scene/world_map_v11"
    builder.main()


if __name__ == "__main__":
    main()
