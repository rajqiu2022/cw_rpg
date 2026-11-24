"""Build v12 art/navigation from the realistic open-world clean plate."""

from pathlib import Path

import build_world_map_v10_assets as builder
import world_map_v12_road_source as source


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    for name in (
        "AUTHORING_SIZE", "BLOCKED", "CLOSED_REGIONS", "FOOT_RADIUS", "LOGICAL_SIZE", "OPEN_REGIONS",
        "PORTALS", "ROAD_EDGE_ALPHA", "ROAD_TINT", "ROAD_TINT_ALPHA", "ROUTES",
        "SCHEMA_VERSION", "WALKABLE",
    ):
        setattr(builder, name, getattr(source, name))
    builder.SOURCE = ROOT / "assets/raw/scene_background/scene_realism_v5/bg_world_map_jianghu_v12_draft_source.png"
    builder.MOBILE_OUT = ROOT / "game/art/backgrounds/region_masters_v2/bg_world_map_jianghu_v12_2304.png"
    builder.DESKTOP_OUT = ROOT / "assets/raw/scene_background/scene_realism_v5/bg_world_map_jianghu_v12_pc_4608.png"
    builder.MASK_OUT = ROOT / "game/art/navigation_masks/world_map_jianghu_walk_v12.png"
    builder.OUT = ROOT / "assets/processed/scene/world_map_v12"
    builder.main()


if __name__ == "__main__":
    main()
