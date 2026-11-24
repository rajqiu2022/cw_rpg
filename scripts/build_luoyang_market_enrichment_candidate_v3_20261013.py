#!/usr/bin/env python3
"""Build the denser v3 Luoyang south-market offline placement candidate.

This deliberately imports the frozen v2 builder for shared parsing/audit/render
helpers, but writes to a new v3 directory.  It does not run Godot or modify any
formal resource, route, portal, NPC, interaction, or candidate-v2 output.
"""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
V2_BUILDER = ROOT / "scripts/build_luoyang_market_enrichment_candidate_20261013.py"
V2_ROOT = ROOT / "assets/previews/scene_module/luoyang_city_enrichment_20261013/market_candidate_v2"
V2_PLACEMENTS = V2_ROOT / "luoyang_market_enrichment_placements_v2.json"
OUT = ROOT / "assets/previews/scene_module/luoyang_city_enrichment_20261013/market_candidate_v3"
FORMAL_SCENE = ROOT / "game/data/scenes/ch4_s3_luoyang_market.tres"


def load_v2_builder():
    spec = importlib.util.spec_from_file_location("luoyang_market_candidate_v2_builder", V2_BUILDER)
    if spec is None or spec.loader is None:
        raise RuntimeError("unable to load frozen v2 builder")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


V2 = load_v2_builder()


PLACEMENT_SPECS = [
    ("v3_west_ward_house", "cottage", (220.0, 1450.0), 0.34, "west ward ordinary home; continuous with west frontage"),
    ("v3_west_ward_frontage", "street_row", (650.0, 1440.0), 0.40, "west ward continuous rear frontage"),
    ("v3_east_ward_house", "cottage", (2140.0, 1270.0), 0.34, "east ward west-end ordinary home"),
    ("v3_east_ward_frontage", "street_row", (2550.0, 1260.0), 0.40, "east ward continuous rear frontage"),
    ("v3_east_ward_small_house", "cottage", (2928.0, 1270.0), 0.26, "east ward east-end small ordinary home"),
    ("v3_west_alley_stall", "stall", (900.0, 1190.0), 0.14, "west alley mouth dry-goods stall"),
    ("v3_east_alley_stall", "stall", (2300.0, 1150.0), 0.14, "east alley mouth household-goods stall"),
    ("v3_west_court_tree_a", "tree", (500.0, 1480.0), 1.0, "west enclosed court shade"),
    ("v3_west_court_tree_b", "tree", (760.0, 1480.0), 1.0, "west enclosed court shade"),
    ("v3_east_court_tree_a", "tree", (2350.0, 1290.0), 1.0, "east enclosed court shade"),
    ("v3_east_court_tree_b", "tree", (2700.0, 1290.0), 1.0, "east enclosed court shade"),
]


NPC_PREVIEW_SPECS = [
    {
        "id": "spar_luoyang_shen_guard",
        "source": ROOT / "game/art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png",
        "foot_px": [370.0, 1130.0], "scale": 0.96, "frame": 0,
    },
    {
        "id": "spar_luoyang_examiner",
        "source": ROOT / "game/art/characters/street_expansion_v1/npc_wulin_examiner_idle_down_4f.png",
        "foot_px": [1170.0, 820.0], "scale": 0.82, "frame": 0,
    },
    {
        "id": "spar_luoyang_blademaster",
        "source": ROOT / "game/art/characters/npc_linxi_martial_hall_master_idle_down_25d_4f_v2_runtime.png",
        "foot_px": [1380.0, 1540.0], "scale": 0.82, "frame": 0,
    },
    {
        "id": "spar_luoyang_patrol",
        "source": ROOT / "game/art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png",
        "foot_px": [1710.0, 1500.0], "scale": 0.96, "frame": 0,
    },
    {
        "id": "luoyang_paper_scholar",
        "source": ROOT / "game/art/characters/npc_zhuwei_inn_waiter_idle_down_25d_4f_v2_runtime.png",
        "foot_px": [520.0, 1340.0], "scale": 0.82, "frame": 0,
    },
    {
        "id": "luoyang_armorer",
        "source": ROOT / "game/art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png",
        "foot_px": [2440.0, 950.0], "scale": 0.82, "frame": 0,
    },
]


def pin(path: Path) -> dict[str, Any]:
    return V2.pin(path)


def build_additions() -> list[dict[str, Any]]:
    original = V2.PLACEMENT_SPECS
    try:
        V2.PLACEMENT_SPECS = PLACEMENT_SPECS
        return V2.build_additions()
    finally:
        V2.PLACEMENT_SPECS = original


def render_npc_scale_preview(candidate: Image.Image) -> tuple[Image.Image, list[dict[str, Any]]]:
    preview = candidate.copy().convert("RGBA")
    records: list[dict[str, Any]] = []
    layers: list[tuple[float, dict[str, Any], Image.Image, tuple[int, int]]] = []
    for spec in NPC_PREVIEW_SPECS:
        strip = Image.open(spec["source"]).convert("RGBA")
        if strip.width % 4 != 0:
            raise RuntimeError(f"expected 4-frame horizontal strip: {spec['source']}")
        frame_width = strip.width // 4
        left = frame_width * spec["frame"]
        frame = strip.crop((left, 0, left + frame_width, strip.height))
        scaled = V2.resize_rgba(frame, (frame.width * spec["scale"], frame.height * spec["scale"]))
        foot_x, foot_y = spec["foot_px"]
        origin = (round(foot_x - scaled.width / 2.0), round(foot_y - scaled.height))
        layers.append((foot_y, spec, scaled, origin))
        records.append({
            "id": spec["id"],
            "source": pin(spec["source"]),
            "source_strip_size_px": [strip.width, strip.height],
            "preview_frame_index": spec["frame"],
            "preview_frame_size_px": [frame_width, strip.height],
            "formal_foot_px": spec["foot_px"],
            "formal_scale": spec["scale"],
            "render_origin_px": [origin[0], origin[1]],
            "credit_limit": "Offline first-frame scale reference only; not a runtime NPC, animation, Y-sort, or gameplay execution record.",
        })
    for _, _, sprite, origin in sorted(layers, key=lambda item: item[0]):
        preview.alpha_composite(sprite, origin)
    draw = ImageDraw.Draw(preview, "RGBA")
    draw.rounded_rectangle((32, 24, 1160, 128), radius=16, fill=(7, 14, 20, 226), outline=(226, 186, 83, 255), width=4)
    draw.text((58, 42), "南市 v3 · 连续街坊 + 现有 NPC 比例预览", font=V2.font(34, True), fill=(248, 247, 238, 255))
    draw.text((60, 84), "仅叠加 6 个现有 sprite 首帧；未新增或运行 NPC", font=V2.font(22), fill=(224, 211, 170, 255))
    return preview, records


def render_implementation_map(candidate: Image.Image, additions: list[dict[str, Any]]) -> Image.Image:
    image = candidate.copy().convert("RGBA")
    draw = ImageDraw.Draw(image, "RGBA")
    routes = json.loads(V2.BASE_CONTRACT.read_text(encoding="utf-8"))["routes"]
    for route in routes:
        draw.line([tuple(point) for point in route["points_px"]], fill=(35, 224, 196, 180), width=18)
    for item in additions:
        rect = item["collision_foot_range_px"]
        draw.rectangle(rect, fill=(255, 111, 73, 70), outline=(255, 160, 104, 250), width=4)
        approach = item["front_approach_foot_px"]
        if approach:
            draw.ellipse((approach[0] - 8, approach[1] - 8, approach[0] + 8, approach[1] + 8), fill=(255, 224, 76, 250))
    for item in V2.PROTECTED_PORTALS:
        x, y = item["foot_px"]
        draw.rectangle((x - 24, y - 12, x + 24, y + 12), outline=(65, 255, 130, 255), width=5)
    for item in V2.PROTECTED_NPCS:
        x, y = item["foot_px"]
        draw.ellipse((x - 10, y - 10, x + 10, y + 10), fill=(196, 117, 255, 245), outline=(255, 255, 255, 255), width=2)
    draw.rounded_rectangle((32, 24, 1260, 128), radius=16, fill=(8, 15, 22, 230), outline=(62, 213, 230, 255), width=4)
    draw.text((58, 42), "南市 v3 · 连续街坊实施/脚域离线图", font=V2.font(34, True), fill=(245, 250, 252, 255))
    draw.text((60, 84), "青=原路线  橙=新增阻挡脚域  黄=门前足点  绿=门户  紫=原 NPC", font=V2.font(22), fill=(196, 224, 231, 255))
    return image


def render_comparison(before: Image.Image, after: Image.Image) -> Image.Image:
    thumb = (960, 640)
    canvas = Image.new("RGB", (1944, 706), (42, 47, 52))
    canvas.paste(before.convert("RGB").resize(thumb, Image.Resampling.LANCZOS), (0, 66))
    canvas.paste(after.convert("RGB").resize(thumb, Image.Resampling.LANCZOS), (984, 66))
    draw = ImageDraw.Draw(canvas)
    draw.text((28, 16), "BEFORE · 现有静态布局参考（非游戏截图）", font=V2.font(27, True), fill=(240, 245, 248))
    draw.text((1012, 16), "AFTER · v3 离线连续街坊 candidate", font=V2.font(27, True), fill=(240, 245, 248))
    return canvas


def write_integration_table(path: Path, additions: list[dict[str, Any]], audit: dict[str, Any]) -> None:
    lines = [
        "# 洛阳南市丰实 v3 · SYSTEM 接入表",
        "",
        "> 离线候选；未运行 Godot，不是 Field、视觉验收或正式采用。v2 全部保留。",
        "",
        "| 操作 | ID | 类型 | 足点 | 缩放 | 阻挡脚域 x1,y1,x2,y2 | 门前足点 |",
        "|---|---|---|---:|---:|---|---|",
    ]
    for item in additions:
        foot = ",".join(f"{value:g}" for value in item["world_foot_px"])
        rect = ",".join(f"{value:g}" for value in item["collision_foot_range_px"])
        approach = "—" if item["front_approach_foot_px"] is None else ",".join(f"{value:g}" for value in item["front_approach_foot_px"])
        lines.append(f"| 新增 | `{item['id']}` | `{item['asset_id']}` | {foot} | {item['scale']:g} | {rect} | {approach} |")
    lines += [
        "",
        "正式相对变更：新增以上 11 项；移动 0；删除 0。v2→v3 的重组只是候选替换关系，不是正式对象移动。",
        "",
        f"离线几何：7 条原路线、{audit['route_sample_count']} 个 ≤4px 样本、4 门户、8 NPC 足点、4 交互足点，记录为 0 冲突。",
        "",
        "SYSTEM 后续仍须验证：Godot Physics、实际导入纹理、Y-sort/alpha、人物前后遮挡、门前可达与重复素材观感。",
        "",
        "未补齐资产：独立豪宅/大院、河岸/桥梁、完整城防门楼；本候选只解决南市普通街坊的密度与人物比例展示。",
        "",
    ]
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    if OUT.exists():
        raise RuntimeError(f"refuse to overwrite existing output: {OUT}")
    required = [
        V2_BUILDER, V2_PLACEMENTS, FORMAL_SCENE, V2.LAYOUT, V2.SCENE,
        V2.BASE_CONTRACT, V2.EXPORT_PLAN, V2.FLOOR, V2.BEFORE,
        V2.MODULE_SEMANTICS, V2.STREET_ROW, V2.STALL, V2.TREE,
        V2.COTTAGE, V2.COTTAGE_RAW, V2.COTTAGE_META,
        *sorted({spec["source"] for spec in NPC_PREVIEW_SPECS}),
    ]
    for path in required:
        if not path.is_file():
            raise FileNotFoundError(path)
    if V2.sha256(V2_PLACEMENTS) != "553ef3c6115282f9427c36a3134b12f083cd1a399623087d572709267d281c33":
        raise RuntimeError("candidate v2 changed; v3 refuses to continue")
    for path, expected in V2.EXPECTED_PINS.items():
        if V2.sha256(path) != expected:
            raise RuntimeError(f"shared source pin changed: {path}")
    before_guard = {path.relative_to(ROOT).as_posix(): V2.sha256(path) for path in required}

    additions = build_additions()
    audit = V2.audit(additions)
    existing_reconstruction, candidate = V2.render_candidate(additions)
    scale_preview, npc_records = render_npc_scale_preview(candidate)
    implementation_map = render_implementation_map(candidate, additions)
    comparison = render_comparison(Image.open(V2.BEFORE).convert("RGBA"), scale_preview)

    OUT.mkdir(parents=True)
    existing_path = OUT / "luoyang_market_existing_static_layout_reference_v3.png"
    candidate_path = OUT / "luoyang_market_enrichment_candidate_v3.png"
    scale_path = OUT / "luoyang_market_enrichment_npc_scale_preview_v3.png"
    map_path = OUT / "luoyang_market_enrichment_implementation_map_v3.png"
    comparison_path = OUT / "luoyang_market_enrichment_static_reference_before_after_v3.png"
    table_path = OUT / "luoyang_market_enrichment_integration_table_v3.md"
    existing_reconstruction.save(existing_path, optimize=True)
    candidate.save(candidate_path, optimize=True)
    scale_preview.save(scale_path, optimize=True)
    implementation_map.save(map_path, optimize=True)
    comparison.save(comparison_path, optimize=True)
    write_integration_table(table_path, additions, audit)

    after_guard = {path.relative_to(ROOT).as_posix(): V2.sha256(path) for path in required}
    if before_guard != after_guard:
        raise RuntimeError("a protected source changed during offline composition")

    manifest = {
        "schema_version": 3,
        "status": "OFFLINE_DENSE_WARD_PLACEMENT_CANDIDATE_NOT_FIELD_OR_PRODUCTION_APPROVAL",
        "scene_id": "ch4_s3_luoyang_market",
        "design_size_px": list(V2.DESIGN_SIZE),
        "engine_executed": False,
        "api_used": False,
        "formal_tres_modified": False,
        "v2_preserved": {**pin(V2_PLACEMENTS), "expected_sha256": "553ef3c6115282f9427c36a3134b12f083cd1a399623087d572709267d281c33"},
        "source_guard_before_after_equal": True,
        "source_pins": [pin(path) for path in required],
        "candidate_structure": {
            "west_ward": ["v3_west_ward_house", "v3_west_ward_frontage", "v3_west_court_tree_a", "v3_west_court_tree_b"],
            "east_ward": ["v3_east_ward_house", "v3_east_ward_frontage", "v3_east_ward_small_house", "v3_east_court_tree_a", "v3_east_court_tree_b"],
            "alley_mouths": ["v3_west_alley_stall", "v3_east_alley_stall"],
            "reading": "Two continuous residential/frontage clusters backed by existing low walls, with retained main cross street and loop lanes.",
        },
        "changes_relative_to_formal": {"add": additions, "move": [], "delete": []},
        "candidate_v2_to_v3_note": "v3 supersedes v2 only as an offline visual proposal; no v2 or formal record was moved or deleted.",
        "protected_routes": json.loads(V2.BASE_CONTRACT.read_text(encoding="utf-8"))["routes"],
        "protected_portals": V2.PROTECTED_PORTALS,
        "protected_npcs": V2.PROTECTED_NPCS,
        "protected_interactions": V2.PROTECTED_INTERACTIONS,
        "collision_audit": audit,
        "npc_scale_preview": {
            "records": npc_records,
            "ambient_npc_proposal_count": 18,
            "ambient_npc_implemented_count": 0,
            "credit_limit": "Six existing first-frame sprites are composited only to show scale; no NPC definition, schedule, behavior, interaction, animation, or runtime placement was added.",
        },
        "counts_are_candidate_records_not_acceptance": {
            "ordinary_homes": 3, "street_rows": 2, "alley_stalls": 2, "courtyard_trees": 4, "total": len(additions),
        },
        "render_recipe": {
            "method": "Pillow alpha composition of formal floor/current visual modules plus unchanged reusable PNG modules; authored depth-foot order; separate current-NPC first-frame scale layer.",
            "before_label": "现有静态布局参考（非游戏截图）",
            "resample": "LANCZOS for offline preview only; SYSTEM must use exact native transforms and recorded feet/scales.",
        },
        "outputs": [pin(existing_path), pin(candidate_path), pin(scale_path), pin(map_path), pin(comparison_path), pin(table_path)],
        "system_integration_notes": [
            "Treat all 11 records as additions relative to formal; move/delete remain empty.",
            "Do not add interior, portal, interaction, quest, or ambient-NPC identities from this visual candidate.",
            "Retain all current route/portal/NPC/interaction identities and run actual Field Physics plus Y-sort/alpha and approach tests after integration.",
            "The 18+ ambient-NPC target is a later proposal only; this package implements zero NPC records.",
        ],
        "known_limits": [
            "Offline geometry audit is not Godot Physics, imported-texture, visual, navigation, gameplay, or Field credit.",
            "Cottage foot/collision remains a candidate author contract and needs actual integration verification.",
            "Repeated cottage/frontage sources still need in-engine repetition, lighting, occlusion, and scale review.",
            "No distinct mansion/compound, riverbank/bridge, or complete fortified-gate module is available in this package.",
            "Gate, yamen, and docks enrichment remain separate pending work.",
        ],
    }
    placements_path = OUT / "luoyang_market_enrichment_placements_v3.json"
    placements_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({
        "placements": pin(placements_path),
        "candidate": pin(candidate_path),
        "npc_scale_preview": pin(scale_path),
        "implementation_map": pin(map_path),
        "comparison": pin(comparison_path),
        "integration_table": pin(table_path),
        "collision_audit": audit,
        "v2_after": pin(V2_PLACEMENTS),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
