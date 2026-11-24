#!/usr/bin/env python3
"""Compose an offline Luoyang yamen east-side court-front candidate.

Only already-adopted, locally licensed/project-owned yamen modules are used.
The script writes a new preview package; it never runs Godot or edits formal
layouts, routes, portals, NPCs, interactions, collisions, or source PNGs.
"""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
UTIL_SCRIPT = ROOT / "scripts/build_luoyang_market_enrichment_candidate_20261013.py"
OUT = ROOT / "assets/previews/scene_module/luoyang_city_enrichment_20261013/yamen_side_courtyard_candidate_v3"
REJECTED_V1 = ROOT / "assets/previews/scene_module/luoyang_city_enrichment_20261013/yamen_side_courtyard_candidate_v1/luoyang_yamen_side_courtyard_placements_v1.json"
INTERMEDIATE_V2 = ROOT / "assets/previews/scene_module/luoyang_city_enrichment_20261013/yamen_side_courtyard_candidate_v2/luoyang_yamen_side_courtyard_placements_v2.json"
CONTRACT = ROOT / "game/art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s1_luoyang_yamen/art_contract.json"
LAYOUT = ROOT / "game/data/maps/luoyang_enclosure_v11_candidates/ch4_s1_luoyang_yamen_layout.tres"
FORMAL_SCENE = ROOT / "game/data/scenes/ch4_s1_luoyang_yamen.tres"
STATIC_REFERENCE = ROOT / "game/build/luoyang_enclosure_v13_export_preview/root_full_v14_ch4_s1_luoyang_yamen_01/full_region.png"
ENTITY_ROOT = ROOT / "game/art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s1_luoyang_yamen/entities"

H_WALL = ENTITY_ROOT / "native_wall_horizontal.png"
V_WALL = ENTITY_ROOT / "native_wall_vertical.png"
GATE = ENTITY_ROOT / "south_court_gate.png"
TREE = ENTITY_ROOT / "native_tree.png"
LAMP = ENTITY_ROOT / "lamp_0.png"
HALL = ENTITY_ROOT / "magistrate_hall.png"
NOTICE_BOARD = ENTITY_ROOT / "notice_pavilion.png"
WILD_FLOWER = ROOT / "game/art/modules/veg/veg_flower_wild_a.png"
NPC = ROOT / "game/art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png"


def load_utils():
    spec = importlib.util.spec_from_file_location("luoyang_offline_util", UTIL_SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError("unable to load offline utility builder")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


UTIL = load_utils()
DESIGN_SIZE = (3072, 2048)


ASSETS: dict[str, dict[str, Any]] = {
    "courtyard_gate": {
        "source": GATE, "source_size_px": [1942, 809], "render_size_px": [971, 404.5],
        "foot_uv": [0.5, 0.871446229913473], "collision_size_px": [0, 0],
        "source_solid_polygons_px": [
            [[1131.5, 1633.5], [1469.5, 1633.5], [1469.5, 1701.25], [1131.5, 1694.75]],
            [[1601.0, 1633.5], [1954.5, 1633.5], [1954.5, 1694.75], [1601.0, 1701.25]],
        ],
        "source_reference_foot_px": [1536, 1700],
        "license_boundary": "Project-original generated independent architecture; existing source and padding history retained.",
    },
    "tree": {
        "source": TREE, "source_size_px": [178, 250], "render_size_px": [178, 250],
        "foot_uv": [0.426966292134831, 0.974724609375], "collision_size_px": [24, 18],
        "license_boundary": "Poly Haven Tree Small 02 CC0, already imported and adopted through the current yamen entity.",
    },
    "lamp": {
        "source": LAMP, "source_size_px": [1024, 1536], "render_size_px": [138.24, 207.36],
        "foot_uv": [0.5, 0.9166669], "collision_size_px": [27.81, 17.55],
        "license_boundary": "Existing project city prop; reused byte-identically from the current yamen entity.",
    },
}


PLACEMENT_SPECS = [
    ("side_court_tree_west", "tree", [2300.0, 810.0], "side-court shade tree"),
    ("side_court_tree_east", "tree", [2870.0, 810.0], "side-court shade tree"),
    ("side_court_lamp_west", "lamp", [2420.0, 870.0], "side-court path lamp"),
    ("side_court_lamp_east", "lamp", [2760.0, 870.0], "side-court path lamp"),
    ("side_court_south_gate", "courtyard_gate", [2586.0, 950.0], "side-court south gate and enclosure front"),
]


RETAINED_REOVERLAY: list[tuple[str, str, list[float]]] = []
ALLOWED_NEW_SEAMS: set[frozenset[str]] = set()


PROTECTED_NPCS = [
    {"id": "spar_yamen_patrol", "foot_px": [1170, 1000]},
    {"id": "spar_yamen_captain", "foot_px": [1790, 870]},
    {"id": "ch8_luoyang_final_clerk", "foot_px": [1980, 1180]},
]
PROTECTED_PORTALS = [
    {"id": "to_city_gate", "foot_px": [1536, 1860]},
    {"id": "to_south_market", "foot_px": [300, 1220]},
    {"id": "to_canal_quay", "foot_px": [2790, 1350]},
]
PROTECTED_INTERACTIONS = [
    {"id": "yamen_case_board", "foot_px": [550, 1240]},
    {"id": "hanjia_water_rule", "foot_px": [1960, 1450]},
    {"id": "hanjia_rubbing", "foot_px": [1960, 1450]},
]


def pin(path: Path) -> dict[str, Any]:
    return UTIL.pin(path)


def rect_polygon(rect: list[float]) -> list[list[float]]:
    return [[rect[0], rect[1]], [rect[2], rect[1]], [rect[2], rect[3]], [rect[0], rect[3]]]


def polygon_bbox(poly: list[list[float]]) -> list[float]:
    xs = [p[0] for p in poly]
    ys = [p[1] for p in poly]
    return [min(xs), min(ys), max(xs), max(ys)]


def build_additions() -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for object_id, asset_id, foot, role in PLACEMENT_SPECS:
        asset = ASSETS[asset_id]
        width, height = asset["render_size_px"]
        foot_uv = asset["foot_uv"]
        origin = [foot[0] - foot_uv[0] * width, foot[1] - foot_uv[1] * height]
        polygons: list[list[list[float]]] = []
        if asset_id == "courtyard_gate":
            ref = asset["source_reference_foot_px"]
            dx, dy = foot[0] - ref[0], foot[1] - ref[1]
            polygons = [[[p[0] + dx, p[1] + dy] for p in poly] for poly in asset["source_solid_polygons_px"]]
        else:
            cw, ch = asset["collision_size_px"]
            collision = [foot[0] - cw / 2, foot[1] - ch, foot[0] + cw / 2, foot[1]]
            polygons = [rect_polygon(collision)]
        record = {
            "id": object_id, "operation": "add", "asset_id": asset_id, "role": role,
            "source": pin(asset["source"]), "world_foot_px": foot,
            "depth_sort_foot_y": foot[1], "render_origin_px": origin,
            "render_size_px": [width, height], "solid_polygons_px": polygons,
            "collision_foot_ranges_px": [polygon_bbox(poly) for poly in polygons],
            "blocking": True, "interaction_identity": None, "portal_identity": None,
            "license_boundary": asset["license_boundary"],
        }
        if origin[0] < 0 or origin[1] < 0 or origin[0] + width > DESIGN_SIZE[0] or origin[1] + height > DESIGN_SIZE[1]:
            raise RuntimeError(f"render outside canvas: {object_id}")
        records.append(record)
    return records


def existing_blockers(contract: dict[str, Any]) -> list[tuple[str, list[float]]]:
    result: list[tuple[str, list[float]]] = []
    for item in contract["objects"]:
        for poly in item.get("solid_polygons_px", []):
            result.append((item["id"], polygon_bbox(poly)))
        size = item.get("collision_size_px", [0, 0])
        if not item.get("solid_polygons_px") and size[0] > 0 and size[1] > 0:
            center = item["physical_center_px"]
            result.append((item["id"], [
                center[0] - size[0] / 2, center[1] - size[1] / 2,
                center[0] + size[0] / 2, center[1] + size[1] / 2,
            ]))
    return result


def audit(additions: list[dict[str, Any]], contract: dict[str, Any]) -> dict[str, Any]:
    new_rects = [(item["id"], rect) for item in additions for rect in item["collision_foot_ranges_px"]]
    old_rects = existing_blockers(contract)
    failures: list[str] = []
    for index, (item_id, rect) in enumerate(new_rects):
        for other_id, other_rect in new_rects[index + 1:]:
            if UTIL.rects_intersect(rect, other_rect) and frozenset((item_id, other_id)) not in ALLOWED_NEW_SEAMS:
                failures.append(f"new/new overlap: {item_id} / {other_id}")
        for other_id, other_rect in old_rects:
            if UTIL.rects_intersect(rect, other_rect):
                failures.append(f"new/existing overlap: {item_id} / {other_id}")

    sample_count = 0
    for route in contract["routes"]:
        for start, end in zip(route["points_px"], route["points_px"][1:]):
            for x, y in UTIL.sample_segment(start, end):
                sample_count += 1
                shoe = [x - 17, y - 12, x + 17, y + 12]
                if any(UTIL.rects_intersect(shoe, rect) for _, rect in new_rects):
                    failures.append(f"formal route shoe overlap: {route['id']} at {x:.3f},{y:.3f}")
                    break

    connector = [[2586.0, 1080.0], [2586.0, 700.0]]
    connector_samples = UTIL.sample_segment(connector[0], connector[1])
    for x, y in connector_samples:
        shoe = [x - 17, y - 12, x + 17, y + 12]
        if any(UTIL.rects_intersect(shoe, rect) for _, rect in new_rects):
            failures.append(f"candidate court connector overlap at {x:.3f},{y:.3f}")
            break

    protected = (
        [("portal:" + x["id"], x["foot_px"], [48, 24]) for x in PROTECTED_PORTALS]
        + [("npc:" + x["id"], x["foot_px"], [34, 24]) for x in PROTECTED_NPCS]
        + [("interaction:" + x["id"], x["foot_px"], [34, 24]) for x in PROTECTED_INTERACTIONS]
    )
    for protected_id, foot, size in protected:
        rect = [foot[0] - size[0] / 2, foot[1] - size[1] / 2, foot[0] + size[0] / 2, foot[1] + size[1] / 2]
        for item_id, new_rect in new_rects:
            if UTIL.rects_intersect(rect, new_rect):
                failures.append(f"protected foot overlap: {protected_id} / {item_id}")
    if failures:
        raise RuntimeError("; ".join(failures[:20]))
    return {
        "formal_route_count": len(contract["routes"]), "formal_route_sample_count": sample_count,
        "candidate_connector_px": connector, "candidate_connector_sample_count": len(connector_samples),
        "existing_blocker_rect_count": len(old_rects), "new_blocker_rect_count": len(new_rects),
        "protected_portal_count": len(PROTECTED_PORTALS), "protected_npc_count": len(PROTECTED_NPCS),
        "protected_interaction_count": len(PROTECTED_INTERACTIONS), "failures": [],
        "allowed_wall_seams": [sorted(pair) for pair in ALLOWED_NEW_SEAMS],
        "method": "All formal segments and the proposed side-court connector sampled at <=4px using a 34x24 foot box.",
        "credit_limit": "Offline bounding geometry only; not Godot Physics, navigation, actual import, Y-sort/alpha, or Field credit.",
    }


def retained_boundary_layers() -> list[dict[str, Any]]:
    layers = []
    for object_id, asset_id, foot in RETAINED_REOVERLAY:
        asset = ASSETS[asset_id]
        width, height = asset["render_size_px"]
        uv = asset["foot_uv"]
        layers.append({
            "id": object_id, "source": asset["source"], "depth_sort_foot_y": foot[1],
            "render_origin_px": [foot[0] - uv[0] * width, foot[1] - uv[1] * height],
            "render_size_px": [width, height], "retained_reoverlay": True,
        })
    return layers


def render_candidate(additions: list[dict[str, Any]], include_npc: bool) -> Image.Image:
    image = Image.open(STATIC_REFERENCE).convert("RGBA")
    layers: list[dict[str, Any]] = []
    for item in additions:
        layers.append({**item, "source_path": ROOT / item["source"]["path"]})
    layers += retained_boundary_layers()
    if include_npc:
        strip = Image.open(NPC).convert("RGBA")
        frame = strip.crop((0, 0, strip.width // 4, strip.height))
        scaled = UTIL.resize_rgba(frame, (frame.width * 0.96, frame.height * 0.96))
        layers.append({
            "id": "existing_guard_scale_reference", "source_image": scaled,
            "depth_sort_foot_y": 1010.0, "render_origin_px": [2586 - scaled.width / 2, 1010 - scaled.height],
            "render_size_px": [scaled.width, scaled.height], "retained_reoverlay": False,
        })
    for layer in sorted(layers, key=lambda x: (x["depth_sort_foot_y"], x["id"])):
        sprite = layer.get("source_image")
        if sprite is None:
            sprite = UTIL.resize_rgba(Image.open(layer.get("source_path", layer["source"])), layer["render_size_px"])
        image.alpha_composite(sprite, (round(layer["render_origin_px"][0]), round(layer["render_origin_px"][1])))
    draw = ImageDraw.Draw(image, "RGBA")
    draw.rounded_rectangle((30, 24, 1210, 126), radius=16, fill=(7, 14, 20, 228), outline=(216, 183, 91, 255), width=4)
    title = "府衙东侧绿荫门院 · 现成人物尺度预览" if include_npc else "府衙东侧绿荫门院 · 离线模块 candidate"
    draw.text((56, 42), title, font=UTIL.font(34, True), fill=(248, 247, 238, 255))
    draw.text((58, 84), "不是富宅花园；未新增 NPC / 交互 / 门户，未运行引擎", font=UTIL.font(22), fill=(224, 211, 170, 255))
    return image


def render_detail(full: Image.Image) -> Image.Image:
    crop = full.crop((1980, 400, 3072, 1120)).convert("RGB")
    canvas = Image.new("RGB", (1536, 1080), (38, 43, 48))
    enlarged = crop.resize((1536, 1013), Image.Resampling.LANCZOS)
    canvas.paste(enlarged, (0, 67))
    draw = ImageDraw.Draw(canvas)
    draw.text((28, 16), "东侧门院局部 · 现成构件与人物比例", font=UTIL.font(30, True), fill=(240, 245, 248))
    return canvas


def render_map(candidate: Image.Image, additions: list[dict[str, Any]], contract: dict[str, Any]) -> Image.Image:
    image = candidate.copy()
    draw = ImageDraw.Draw(image, "RGBA")
    for route in contract["routes"]:
        draw.line([tuple(point) for point in route["points_px"]], fill=(35, 224, 196, 175), width=18)
    draw.line([(2586, 1080), (2586, 700)], fill=(255, 215, 70, 220), width=12)
    for item in additions:
        for rect in item["collision_foot_ranges_px"]:
            draw.rectangle(rect, fill=(255, 105, 72, 74), outline=(255, 151, 94, 250), width=4)
    for item in PROTECTED_PORTALS:
        x, y = item["foot_px"]
        draw.rectangle((x - 24, y - 12, x + 24, y + 12), outline=(65, 255, 130, 255), width=5)
    for item in PROTECTED_NPCS:
        x, y = item["foot_px"]
        draw.ellipse((x - 10, y - 10, x + 10, y + 10), fill=(196, 117, 255, 245), outline=(255, 255, 255, 255), width=2)
    return image


def write_inventory(path: Path) -> None:
    rows = [
        ("宅/正厅", "有限", HALL, "现有府衙正厅，可作为背景；不是富宅、厢房或可重复住宅，不在本候选新增。"),
        ("墙", "仅保留现有", H_WALL, "项目原生横/竖墙有脚域语义，但单独裁出 PNG 是简化灰白捕获面，不适合新增美术；本候选只保留场内既有侧墙背景。"),
        ("门", "可直接用", GATE, "项目原有院门/围墙组件；按现有 1:1 人物尺度复用。"),
        ("树", "可直接用", TREE, "当前城市树实体；上游 Poly Haven Tree Small 02，CC0。"),
        ("花坛", "缺失", WILD_FLOWER, "仅有 44x93 乡野单株草花，不是城市花坛，本候选不使用。"),
        ("池", "缺失", None, "未找到带许可、透明边界和城市脚域语义的池水/池岸模块。"),
        ("亭", "缺失", NOTICE_BOARD, "文件名含 pavilion，但实物是告示牌，且合同明确成人头部净空不足；不能冒称园亭。"),
        ("院落细节", "可直接用", LAMP, "当前府衙灯杆；可作路径照明，不新增交互。"),
    ]
    lines = [
        "# 洛阳府衙侧院 / 富宅花园现成资源盘点", "",
        "> 结论：足够做府衙东侧绿荫门院立面小样；不足以做完整侧院或富宅花园。没有新生成、下载、付费或 API 资源。", "",
        "| 类型 | 结论 | 实际资源 | 内容与边界 |", "|---|---|---|---|",
    ]
    for kind, status, source, note in rows:
        source_text = "—" if source is None else f"`{source.relative_to(ROOT).as_posix()}`"
        lines.append(f"| {kind} | {status} | {source_text} | {note} |")
    lines += [
        "", "## 本小样实际使用", "",
        "- 一座院门、两棵城市树、两盏府衙灯。",
        "- 现有主厅与既有东侧墙只作为当前静态布局背景/边界；不重新叠绘灰白墙片，也不复制成富宅。",
        "- 一名现有守卫 sprite 首帧只用于人物比例预览，实际新增 NPC 数为 0。",
        "- 不使用乡村小屋、世界地图缩略城、野花单株或告示牌来冒充富宅园林。",
        "", "## 后续缺口", "",
        "- 独立富宅主屋、厢房与回廊。",
        "- 城市花坛/盆景、池岸与水面、真正可通行园亭。",
        "- 上述资产完成后，才适合继续做‘豪宅花园’候选。",
    ]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def render_comparison(before: Image.Image, after: Image.Image) -> Image.Image:
    thumb = (960, 640)
    canvas = Image.new("RGB", (1944, 706), (42, 47, 52))
    canvas.paste(before.convert("RGB").resize(thumb, Image.Resampling.LANCZOS), (0, 66))
    canvas.paste(after.convert("RGB").resize(thumb, Image.Resampling.LANCZOS), (984, 66))
    draw = ImageDraw.Draw(canvas)
    draw.text((28, 16), "BEFORE · 现有静态布局参考（非游戏截图）", font=UTIL.font(27, True), fill=(240, 245, 248))
    draw.text((1012, 16), "AFTER · 东侧绿荫门院离线 candidate", font=UTIL.font(27, True), fill=(240, 245, 248))
    return canvas


def main() -> None:
    if OUT.exists():
        raise RuntimeError(f"refuse to overwrite existing output: {OUT}")
    required = [UTIL_SCRIPT, CONTRACT, LAYOUT, FORMAL_SCENE, STATIC_REFERENCE, H_WALL, V_WALL, GATE, TREE, LAMP, HALL, NOTICE_BOARD, WILD_FLOWER, NPC, REJECTED_V1, INTERMEDIATE_V2]
    for path in required:
        if not path.is_file():
            raise FileNotFoundError(path)
    contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
    expected = contract["asset_sha256"]
    for path in [H_WALL, V_WALL, GATE, TREE, LAMP, HALL, NOTICE_BOARD]:
        key = "res://" + path.relative_to(ROOT / "game").as_posix()
        if expected.get(key) != UTIL.sha256(path):
            raise RuntimeError(f"contract pin mismatch: {path}")
    before_guard = {path.relative_to(ROOT).as_posix(): UTIL.sha256(path) for path in required}

    additions = build_additions()
    audit_result = audit(additions, contract)
    candidate = render_candidate(additions, False)
    scale_preview = render_candidate(additions, True)
    detail = render_detail(scale_preview)
    implementation_map = render_map(candidate, additions, contract)
    comparison = render_comparison(Image.open(STATIC_REFERENCE), scale_preview)

    OUT.mkdir(parents=True)
    candidate_path = OUT / "luoyang_yamen_side_courtyard_candidate_v3.png"
    scale_path = OUT / "luoyang_yamen_side_courtyard_scale_preview_v3.png"
    detail_path = OUT / "luoyang_yamen_side_courtyard_detail_v3.png"
    map_path = OUT / "luoyang_yamen_side_courtyard_implementation_map_v3.png"
    comparison_path = OUT / "luoyang_yamen_side_courtyard_before_after_v3.png"
    inventory_path = OUT / "luoyang_yamen_garden_asset_inventory_v3.md"
    candidate.save(candidate_path, optimize=True)
    scale_preview.save(scale_path, optimize=True)
    detail.save(detail_path, optimize=True)
    implementation_map.save(map_path, optimize=True)
    comparison.save(comparison_path, optimize=True)
    write_inventory(inventory_path)

    after_guard = {path.relative_to(ROOT).as_posix(): UTIL.sha256(path) for path in required}
    if before_guard != after_guard:
        raise RuntimeError("protected source changed during offline composition")

    manifest = {
        "schema_version": 3,
        "status": "OFFLINE_YAMEN_SIDE_COURT_FRONT_CANDIDATE_NOT_COMPLETE_COURTYARD_RICH_GARDEN_FIELD_OR_PRODUCTION_APPROVAL",
        "scene_id": "ch4_s1_luoyang_yamen", "design_size_px": list(DESIGN_SIZE),
        "engine_executed": False, "api_used": False, "formal_tres_modified": False,
        "source_guard_before_after_equal": True, "source_pins": [pin(path) for path in required],
        "rejected_v1_preserved": {**pin(REJECTED_V1), "reason": "Standalone horizontal/vertical captured wall PNGs read as flat grey-white panels and were rejected from v2 visual use."},
        "intermediate_v2_preserved": {**pin(INTERMEDIATE_V2), "note": "Court-front composition retained; v3 only moves the scale-reference guard in front of the gate so the full body is readable."},
        "asset_catalog": {asset_id: {**asset, "source": pin(asset["source"])} for asset_id, asset in ASSETS.items()},
        "changes_relative_to_formal": {"add": additions, "move": [], "delete": []},
        "retained_visual_reoverlay_only": [x[0] for x in RETAINED_REOVERLAY],
        "protected_routes": contract["routes"], "protected_portals": PROTECTED_PORTALS,
        "protected_npcs": PROTECTED_NPCS, "protected_interactions": PROTECTED_INTERACTIONS,
        "collision_audit": audit_result,
        "npc_scale_preview": {
            "source": pin(NPC), "frame": 0, "foot_px": [2586, 1010], "scale": 0.96,
            "implemented_npc_count": 0,
            "credit_limit": "Existing guard first frame for scale only; no NPC identity, behavior, interaction, or runtime placement added.",
        },
        "inventory_conclusion": {
            "enough_for": "yamen east-side shaded court-front scale sample",
            "not_enough_for": "complete side courtyard or wealthy residence garden",
            "missing": ["distinct wealthy residence/side office", "city flowerbed/bonsai", "pond and bank", "walkable garden pavilion"],
            "rejected_mislabels": ["notice board as garden pavilion", "single rural wildflower as flowerbed", "village cottage as mansion", "world-map miniature compound as city building"],
        },
        "outputs": [pin(candidate_path), pin(scale_path), pin(detail_path), pin(map_path), pin(comparison_path), pin(inventory_path)],
        "known_limits": [
            "Static Pillow composite is not Godot rendering, actual import, Physics, navigation, Y-sort/alpha, or Field credit.",
            "The proposed internal connector is a review line only and does not add a formal route or portal.",
            "Current formal route, NPC, portal, interaction and visual records were not modified.",
            "This package deliberately stops at a yamen court-front sample because compatible standalone walls and garden-specific modules are absent.",
        ],
    }
    placements_path = OUT / "luoyang_yamen_side_courtyard_placements_v3.json"
    placements_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({
        "placements": pin(placements_path), "candidate": pin(candidate_path),
        "scale_preview": pin(scale_path), "detail": pin(detail_path),
        "implementation_map": pin(map_path), "comparison": pin(comparison_path),
        "inventory": pin(inventory_path), "collision_audit": audit_result,
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
