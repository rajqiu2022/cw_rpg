"""Canonical source shared by v9 road visuals, navigation and tests.

The route geometry was surveyed against the adopted v8 terrain. V9 keeps that
reviewed geography, but the geometry now also paints a restrained road-clarity
layer into the background. Runtime art and collision therefore cannot drift.
"""

from world_map_v8_road_survey import (  # noqa: F401
    BLOCKED,
    PORTALS,
    ROAD_CHECK_SECTIONS,
    ROAD_SURFACES,
    ROUTES,
    WALKABLE,
)

# The reported bamboo fork is a real painted road, but its original 16px
# survey width left less than one player-foot diameter near several bends.
# Keep the same authored centreline and widen only this visible corridor.
ROUTES = [
    (name, 34 if name == "lingyue_bamboo" else width, points)
    for name, width, points in ROUTES
]
ROAD_CHECK_SECTIONS = dict(ROAD_CHECK_SECTIONS)
ROAD_CHECK_SECTIONS["reported_bamboo_fork_wide"] = [(1680, 214), (1694, 227)]
WALKABLE = dict(WALKABLE)
WALKABLE["reported_bamboo_fork"] = (1687, 220)


SCHEMA_VERSION = 9
AUTHORING_SIZE = (1920, 1280)
LOGICAL_SIZE = (2304, 1536)
FOOT_RADIUS = 5

# Subtle treatment rather than a painted game-board stripe. The existing road
# texture remains visible below this colour/contrast lift.
ROAD_TINT = (205, 166, 105)
ROAD_TINT_ALPHA = 28
ROAD_HIGHLIGHT_ALPHA = 18
ROAD_EDGE_ALPHA = 20
