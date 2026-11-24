# Linxi Tutorial Panorama Map V1

## Goal

Replace the stretched single-screen tutorial map with a native-resolution,
scrollable two-panel world. The runtime world is `3072x1024`: two adjacent
`1536x1024` generated panels at scale `1.0`, never independently scaled on X
or Y.

## Panel Contract

| Panel | Runtime range | Purpose | Seam treatment |
| --- | --- | --- | --- |
| `left` | x=0..1536 | master courtyard and route beginning | its right 12% is bamboo, stone wall, and shaded path |
| `right` | x=1536..3072 | smithy lane and village exit | its left 12% repeats bamboo, stone wall, and shaded path |

The overlap is intentionally hidden with separate foreground bamboo and stone
props. Do not blend unrelated generated pixels or scale either image to make a
seam disappear.

## Base Layer Rules

- Panorama panels contain terrain, broad paths, distant foliage, and static
  building masses only.
- Both panels must have an unobstructed 180-260 px wide walking lane that
  reaches the shared seam and the exit.
- No people, readable writing, UI, baked portal arrows, or interactive chest.
- Roofs are visual only. Gameplay collision covers wall feet, platforms, and
  fences, never the complete roof silhouette.

## Modular Object Layer

Each placed object uses `scene_objects` in `WalkableMapLayout` and has a
separate visual texture, z-index, optional foot collision, and interaction
anchor. The first pass needs these objects:

| Asset ID | Placement | Gameplay role |
| --- | --- | --- |
| `linxi_smithy_forge_prop` | right panel forge bay | visual, forge glow anchor |
| `linxi_chest_closed` / `linxi_chest_open` | right panel lane shoulder | one-time loot interaction |
| `linxi_stone_tablet` | right panel lane shoulder | interact-only dialog |
| `linxi_bamboo_seam_left/right` | around x=1536 | hides panel boundary, foot collision |
| `linxi_fence_short` | road edges | foot collision only |
| `linxi_barrel_stack` | workshop frontage | visual / optional collision |

## Runtime Handoff

1. Generate and approve both source panels under `assets/raw/scene_background/linxi/panorama/v1/`.
2. Copy to `game/art/backgrounds/` and compose a native `3072x1024` panorama
   without resampling.
3. Set tutorial `design_size = Vector2i(3072, 1024)` and update every
   normalized walkable region, portal, NPC, probe, blocker, and object anchor.
4. Populate `visual_objects` with only reviewed modular PNGs.
5. Run `validate_walkable_map_v2.gd`, `validate_first_two_walkability.gd`, and
   a visual scroll capture from both map ends before adoption.
