#!/usr/bin/env python3
"""Collect the reuse-index inventory and generate separate, cached gallery thumbnails."""
from __future__ import annotations

import hashlib
import json
import re
import wave
from collections import Counter
from datetime import datetime
from pathlib import Path
from urllib.parse import quote
from zoneinfo import ZoneInfo

from PIL import Image, ImageOps
import build_resource_reuse_index as inventory

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
THUMBS = ROOT / "docs/assets/resources"
CACHE = THUMBS / "thumbnail-index.json"
CATEGORIES = {
    "map": "地图组件", "background": "场景背景", "npc": "NPC 精灵", "portrait": "NPC 立绘",
    "battle": "战斗动作", "player": "主角与武器", "music": "音乐", "sfx": "音效与环境音",
    "voice": "对白配音", "candidate": "新增候选", "design": "地图设计图",
    "vfx": "战斗特效", "archive": "已归档",
}
FOLDERS = {
    "building": "建筑与门窗", "ground": "道路与地表", "prop": "家具与物件", "veg": "树木与植被",
    "luoyang_assembled_20261016b": "洛阳拼装建筑", "luoyang_assembled_interiors_20261016g": "洛阳室内",
    "luoyang_district_life_20261016f": "洛阳生活陈设", "luoyang_estate_components_20261021am": "宅园建筑与花床",
    "luoyang_market_two_shops_20261021ao": "南市药铺与书斋", "luoyang_shore_market_20261020ae": "湿岸与街面细节",
    "luoyang_docks_office_20261016h": "码头与岗位", "world_map_v13": "世界组件原型",
    "street_expansion_v1": "街坊角色", "street_expansion_v2": "街坊角色二版",
    "luoyang_docks_roles_20261019ad": "码头搬运工", "luoyang_soldier_diversity_20261019y": "军士差异候选",
    "generic": "通用肖像", "companions": "同行角色", "conversation_direction_v1": "对话朝向",
    "weapon_variants": "玩家武器变体", "walk_frames": "玩家行走帧", "standard_v2": "标准战斗动作",
    "wuxia_20261011": "认可音乐库", "free": "战斗与UI音效", "cc0": "CC0来源音效",
    "ambience": "环境底噪", "navigation_masks": "导航蒙版", "ambient": "动态氛围物件",
    "interactive": "互动与调查物件", "battle_arenas_v2": "战斗场景", "candidates": "角色候选",
}
OTHER_CITY_BASE = "assets/raw/other_city_modules_20261022"
WORLD100_BASE = "assets/raw/world_expansion_100_20261022"
PLACEWALK_BASE = "assets/raw/world_placeables_walk_20261022"
DESIGN_BASE = "assets/raw/sect_western_map_designs_20261022d"
DESERT_DESIGN_BASE = "assets/raw/desert_town_design_20261029c"
MIAO_DESIGN_BASE = "assets/raw/miao_town_design_20261029e"
MIAO_CITY_BASES = ("assets/raw/miao_town_20261029f", "assets/processed/miao_town_20261029f", "game/art/modules/miao_town_20261029f")
MIAO_RECOMPOSE_BASES = ("assets/raw/miao_recompose_20261029g", "assets/processed/miao_recompose_20261029g", "game/art/modules/miao_recompose_20261029g")
MIAO_VARIETY_BASES = ("assets/raw/miao_building_variety_20261029h", "assets/processed/miao_building_variety_20261029h", "game/art/modules/miao_building_variety_20261029h")
MIAO_CITY_GROUPS = {"building":"苗风山城 / 木构建筑与桥阶", "landform":"苗风山城 / 台地与梯田", "vegetation":"苗风山城 / 山林与溪岸", "ground":"苗风山城 / 土石街面与溪水", "scene_prop":"苗风山城 / 手艺与场景物件", "npc_walk":"苗风山城 / 地图待机与侧向行走", "portrait":"苗风山城 / 同人肖像"}
DESERT_CITY_BASES = ("assets/raw/desert_town_20261029d", "assets/processed/desert_town_20261029d", "game/art/modules/desert_town_20261029d")
DESERT_CITY_GROUPS = {"building":"沙漠城镇 / 土坯建筑与院墙", "ground":"沙漠城镇 / 黄沙地表", "vegetation":"沙漠城镇 / 井边植被", "landform":"沙漠城镇 / 城外沙丘"}
REDROCK_BASE = "assets/raw/redrock_gate_resources_20261023a"
REDROCK_REDESIGN_BASE = "assets/raw/redrock_gate_redesign_20261023d"
REDROCK_TRIAL_BASE = "assets/raw/redrock_joint_trial_20261023e"
REDROCK_DESERT_LIFE_BASE = "assets/raw/redrock_desert_life_20261025a"
REDROCK_TOWN_BASE = "assets/raw/redrock_town_20261028a"
REDROCK_STANDARD_BASE = "assets/raw/redrock_luoyang_standard_20261028b"
REDROCK_COMPLETE_BASE = "assets/raw/redrock_desert_complete_20261028d"
REDROCK_CITY_LIFE_BASE = "assets/raw/redrock_city_life_20261029a"
REDROCK_BASES = (REDROCK_BASE, "assets/raw/redrock_ground_resources_20261023b", REDROCK_REDESIGN_BASE, REDROCK_TRIAL_BASE, REDROCK_DESERT_LIFE_BASE, REDROCK_TOWN_BASE, REDROCK_STANDARD_BASE, REDROCK_COMPLETE_BASE, REDROCK_CITY_LIFE_BASE)
REDROCK_DERIVED_BASE = "assets/processed/redrock_gate_20261023b"
REDROCK_JOINT_DERIVED_BASE = "assets/processed/redrock_joint_trial_20261023e"
REDROCK_EDITOR_BASE = "game/art/modules/redrock_gate_20261023c"
REDROCK_JOINT_EDITOR_BASE = "game/art/modules/redrock_joint_editor_20261023f"
REDROCK_TOWN_EDITOR_BASE = "game/art/modules/redrock_town_20261028a"
REDROCK_STANDARD_EDITOR_BASE = "game/art/modules/redrock_luoyang_standard_20261028b"
REDROCK_COMPLETE_EDITOR_BASE = "game/art/modules/redrock_desert_complete_20261028d"
REDROCK_CITY_LIFE_EDITOR_BASE = "game/art/modules/redrock_city_life_20261029a"
REDROCK_GROUPS = {"building": "赤岩关镇 / 建筑与墙体", "scene_prop": "赤岩关镇 / 场景与大世界物件",
                  "npc_sprite": "赤岩关镇 / 地图待机", "npc_walk": "赤岩关镇 / 地图行走原生帧",
                  "portrait": "赤岩关镇 / 同人立绘", "ground": "赤岩关镇 / 道路与地表", "design": "赤岩关镇 / 峡口连接重设计", "landform": "赤岩关镇 / 墙翼与岩肩", "vegetation": "赤岩关镇 / 沙漠植被", "animal": "赤岩关镇 / 商旅驮兽", "enemy": "赤岩关镇 / 野外动物序列"}
DESIGN_GROUPS = {"miao": "苗族风情山城总规 / 沿溪吊脚街寨", "desert": "沙漠城镇总规 / 黄沙土坯商城", "wudang": "门派总规 / 武当派", "mingwu": "门派总规 / 茗雾山庄",
                 "huashan": "门派总规 / 华山派", "gufeng": "门派总规 / 古峰派", "lingyue": "门派总规 / 凌月派",
                 "oasis": "西域城镇总规 / 绿洲商镇", "redrock": "西域城镇总规 / 赤岩关镇"}
PLACEWALK_KINDS = {"scene_props": "场景生活摆件", "field_objects": "野外互动与采集物", "small_buildings": "小建筑", "npc_walk": "地图行走精灵", "npc_walk_frames": "地图行走独立帧"}
WORLD100_KINDS = {"maps": "地图建筑", "quest_props": "任务道具", "npc_sprites": "NPC静态精灵", "portraits": "NPC同人立绘", "animals": "动物怪物", "human_enemies": "人形敌人", "story_bosses": "剧情Boss"}
WORLD100_TIERS = {"normal": "普通怪", "elite": "野外高品质精英怪", "story_boss": "剧情Boss"}
ANIMAL_LABELS = {"tiger": "老虎", "lion": "狮子", "wild_dog": "野狗", "fox": "狐狸", "bear": "狗熊"}
CITY_LABELS = {"bianzhou": "汴州", "jinling": "金陵", "xiangzhou": "襄州", "qinghe": "清河", "yanmen": "雁门", "shared": "跨城通用"}
ASSET_LABELS = {"maps": "地图建筑", "npc_sprites": "NPC静态精灵", "portraits": "同人立绘", "enemies": "敌人待机", "monsters": "怪物待机", "quest_props": "任务与采集道具"}
BIANZHOU_ART04_RAW = "assets/raw/bianzhou_enclosure_20261028d"
BIANZHOU_ART04_PROCESSED = "assets/processed/bianzhou_enclosure_20261028d"
BIANZHOU_ART04_GAME = "game/art/maps/bianzhou_enclosure_20261028d"
# Exact batch only: seven preserved RAWs, four authorized derivatives, five runtime copies.
BIANZHOU_ART04_SOURCES = (
    ("horizontal_wall_v1", "横向灰砖城墙", "689e723565eb5acdfba5f508b28c13db974092d3af9ab1f2a4d9bf848921b30c"),
    ("west_longitudinal_wall_v1", "西纵城墙首稿", "9d224d96c07b16aacc487b6956e017cfc71b10fa77cf6da70fdbb33dea423847"),
    ("east_longitudinal_wall_v1", "东纵城墙首稿", "fd5d7b978fa2b190d6c588a39ced0712fd8e2d5536531f5bee3386bb00ca9ec4"),
    ("post_stable_cartshed_v1", "开放马车棚", "b8ab74cec828e4e8317bb1e20c654cbb9bcf6b193ae097957669375a5a8ce143"),
    ("west_longitudinal_wall_v2_edit", "西纵城墙平行后继", "357fdae89ba7292cdfb181b10080d4f0728f4e50b6f1596d525d7f543428bece"),
    ("east_longitudinal_wall_v2_edit", "东纵城墙平行后继", "96ab146e931990ca6c584304d1c27d7f78627568bc8d32432429ef9e22fbae17"),
    ("compacted_earth_tile_v1", "细夯土地面", "52fe324716bfb158c9bd55e3561ef8cb0a03ea772877a96dc4d82f4485994d1f"),
)
BIANZHOU_ART04_DERIVATIVES = {
    "horizontal_wall_v1": "f7f459e4b266411f161f3f00fab023792b6cdcd441300fb6d198020fc686bd1e",
    "west_longitudinal_wall_v2_edit": "ade94858b255bcb98b6e228907bb860cc8881f4c3bd982e58039f2fc7568473d",
    "east_longitudinal_wall_v2_edit": "dc7e9cd6fd83a6d3968d74f8c6ebe8a39c09f6ea1c7bb19b2257a1e4b7235d22",
    "post_stable_cartshed_v1": "b4e8cb1b835d9c4729282a86c310db92161d1dcbf42f73799d7505175c3d8180",
}


def bianzhou_art04_assets() -> dict[str, dict]:
    """Read and pin exactly sixteen existing files; never scan an entire RAW/maps tree."""
    rows = {}
    for asset_id, name, raw_sha in BIANZHOU_ART04_SOURCES:
        raw = f"{BIANZHOU_ART04_RAW}/{asset_id}.png"
        rejected = asset_id in ("west_longitudinal_wall_v1", "east_longitudinal_wall_v1")
        ground = asset_id == "compacted_earth_tile_v1"
        group_name = "汴州 / 道路与地表" if ground else "汴州 / 城墙与马车棚"
        raw_note = "原PNG字节保留；原完整A1留白失败不因后继导入洗成通过。" if not ground else "RGB无缝细夯土原稿，原样工程副本；不清背景、不补白。"
        rows[raw] = dict(name=name + " · 原图", sha256=raw_sha, status="rejected" if rejected else "candidate",
                         statusLabel="弃用首稿 · 纵深渐窄不可重复" if rejected else "原图来源 · 工程组件引用",
                         group=group_name + " / 原图来源", sourcePath=None, children=[],
                         note=raw_note + (" 透视截面渐窄，禁止整张纵向平铺；仅保留追溯，不导入。" if rejected else ""))
        if rejected:
            continue
        filename = asset_id + (".png" if ground else "_padded.png")
        game = f"{BIANZHOU_ART04_GAME}/{filename}"
        source = raw
        final_sha = raw_sha if ground else BIANZHOU_ART04_DERIVATIVES[asset_id]
        if not ground:
            processed = f"{BIANZHOU_ART04_PROCESSED}/{filename}"
            rows[processed] = dict(name=name + " · 留白派生", sha256=final_sha, status="candidate",
                                   statusLabel="许可清边留白派生 · 工程引用", group=group_name + " / 留白派生",
                                   sourcePath=raw, children=[game],
                                   note="用户本批许可仅保护框外alpha1清理+透明补白；全原RGB/主体RGBA保，W/E原maxalpha254不归一。处理60703F3C；原RAW保。")
            rows[raw]["children"].append(processed)
            source = processed
        else:
            rows[raw]["children"].append(game)
        rows[game] = dict(name=name + " · 工程图", sha256=final_sha, status="referenced",
                          statusLabel="汴州现役室外组件 · 工程引用", group=group_name + " / 工程引用",
                          sourcePath=source, children=[],
                          note="与来源PNG精确相同；61624隔离导入86检查0失败/whole RGBA exact，五图15叶已晋升。05原生地面后继与八区室外用途结构已显示，城廓/完整棚体/成人比例有限准；不是整城ART或所有室内完成。")
    if len(rows) != 16:
        raise RuntimeError("Bianzhou ART04 exact sixteen-path contract differs")
    for key, row in rows.items():
        if hashlib.sha256((ROOT / key).read_bytes()).hexdigest() != row["sha256"]:
            raise RuntimeError("Bianzhou ART04 source differs: " + key)
    return rows


def href(path: Path) -> str:
    return "../" + quote(path.relative_to(ROOT).as_posix(), safe="/")


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def category(path: Path) -> str:
    key = relative(path)
    if key.startswith("assets/retained/"): return "archive"
    if key.startswith("game/art/battle_vfx/"): return "vfx"
    if key.startswith("assets/raw/sect_remaining_designs_20261029l/"): return "design"
    if key.startswith(REDROCK_REDESIGN_BASE + "/"): return "design"
    if key.startswith((DESIGN_BASE + "/", DESERT_DESIGN_BASE + "/", MIAO_DESIGN_BASE + "/")): return "design"
    if not key.startswith("game/"): return "candidate"
    if path.suffix.lower() in inventory.AUDIO:
        if "/voices/" in key: return "voice"
        return "music" if "/bgm/" in key or path.name.startswith("bgm_") else "sfx"
    if "/sprites/battle/" in key: return "battle"
    if "portrait" in path.stem or "/portraits/" in key: return "portrait"
    if "/weapon_variants/" in key or "/walk_frames/" in key or path.name.startswith(("protagonist", "sprite_lengguyun", "battle_lengguyun")): return "player"
    if path.name.startswith("battle_"): return "battle"
    if "/characters/" in key or path.name.startswith("npc_"): return "npc"
    if "/backgrounds/" in key or ("/maps/world_" in key and path.stem == "overview"): return "background"
    return "map"


def group(path: Path, kind: str) -> str:
    if kind == "archive": return "保留库 / " + path.parent.name
    if kind == "vfx": return FOLDERS.get(path.parent.name, path.parent.name)
    for base in REDROCK_BASES:
        if relative(path).startswith(base + "/"):
            return REDROCK_GROUPS[path.relative_to(ROOT / base).parts[0]]
    if kind == "design": return DESIGN_GROUPS[path.stem.split("_masterplan_", 1)[0]]
    if relative(path).startswith(PLACEWALK_BASE + "/"):
        asset_kind = path.relative_to(ROOT / PLACEWALK_BASE).parts[0]
        return ("地图行走精灵 / 下行4帧" if asset_kind.startswith("npc_walk") else "场景可放置 / " + PLACEWALK_KINDS[asset_kind])
    if relative(path).startswith(WORLD100_BASE + "/"):
        asset_kind, region = path.relative_to(ROOT / WORLD100_BASE).parts[:2]
        name = "百图扩充 / " + WORLD100_KINDS[asset_kind] + " / " + WORLD100_TIERS.get(region, CITY_LABELS.get(region, {"zhuwei": "竹尾村", "linxi": "林西村"}.get(region, region)))
        if asset_kind == "animals":
            match = re.search(r'_animal_(.+?)_(?:normal|elite)_', path.stem)
            name += " / " + ANIMAL_LABELS[match.group(1)]
        return name
    if relative(path).startswith(OTHER_CITY_BASE + "/"):
        city, asset_kind = path.relative_to(ROOT / OTHER_CITY_BASE).parts[:2]
        return "其他城镇 / " + CITY_LABELS[city] + " / " + ASSET_LABELS[asset_kind]
    if kind == "voice":
        parts = path.relative_to(GAME / "art/audio/voices").parts
        return parts[0] + " / " + (parts[1] if len(parts) > 2 else "其他对白")
    if kind == "candidate":
        if "voice_sfx" in relative(path):
            return "新增对白试听" if "voices" in relative(path) or "edge" in relative(path) else "新增音效试听"
        if path.suffix.lower() in inventory.AUDIO: return "新增音乐试听"
        return "AP 整城候选"
    for part in reversed(path.parent.parts):
        if part in FOLDERS: return FOLDERS[part]
        if part.startswith("luoyang_"): return "洛阳 / " + part.removeprefix("luoyang_")
    if kind == "battle": return path.parent.name
    return {"music": "历史与场景曲", "sfx": "其他音效", "portrait": "专属立绘", "npc": "通用与剧情角色", "background": "章节与地点背景", "player": "主角角色", "map": "地图组件"}[kind]


def state(path: Path, approved: set[str]) -> tuple[str, str]:
    key = relative(path)
    if key.startswith("assets/retained/"): return "candidate", "已归档保留"
    if key.startswith((DESIGN_BASE + "/", DESERT_DESIGN_BASE + "/", MIAO_DESIGN_BASE + "/")): return "candidate", "设计提案 · 待审阅"
    if not key.startswith("game/") or "/candidates/" in key or "20261019y" in key:
        return "candidate", "候选 · 未正式接入"
    if key in approved: return "adopted", "已认可曲库"
    if any(x in key for x in ["/luoyang_estate_components_20261021am/", "/luoyang_market_two_shops_20261021ao/", "/luoyang_shore_market_20261020ae/", "/luoyang_docks_roles_20261019ad/", "/luoyang_docks_office_20261016h/"]):
        return "adopted", "已正式接入"
    if inventory.refs.get(inventory.res(path)): return "referenced", "配置中有引用"
    return "unconfirmed", "使用状态待核对"


def thumbnail(path: Path, kind: str, cache: dict, updated: dict) -> tuple[str, list[int]]:
    key = relative(path)
    stat = path.stat()
    signature = [stat.st_size, str(stat.st_mtime_ns)]
    token = hashlib.sha256(key.encode()).hexdigest()[:24]
    output = THUMBS / kind / (token + ".webp")
    previous = cache.get(key, {})
    if previous.get("signature") == signature and output.is_file():
        updated[key] = previous
        return "assets/resources/" + kind + "/" + output.name, previous["size"]
    with Image.open(path) as original:
        image = ImageOps.exif_transpose(original).convert("RGBA")
        size = list(image.size)
        image.thumbnail((360, 220), Image.Resampling.LANCZOS)
        output.parent.mkdir(parents=True, exist_ok=True)
        image.save(output, "WEBP", quality=84, method=4)
    if signature != [path.stat().st_size, str(path.stat().st_mtime_ns)]:
        raise RuntimeError("Source changed while generating thumbnail: " + key)
    updated[key] = {"signature": signature, "size": size, "thumbnail": relative(output)}
    return "assets/resources/" + kind + "/" + output.name, size


def build() -> dict:
    inventory.refs.clear(); inventory.scene_refs.clear(); inventory.snapshots.clear()
    texts, scenes = inventory.scan_sources()
    music = texts[GAME / "scripts/audio/music_catalog.gd"]
    track_block = re.search(r'const TRACK_IDS\s*:=\s*\[(.*?)\]', music, re.S)
    approved = {"game/art/audio/bgm/wuxia_20261011/" + name + ".wav" for name in re.findall(r'&"([^"]+)"', track_block.group(1))}
    approved.add("game/art/audio/bgm/bgm_village_day_v4.wav")
    paths: set[Path] = set()
    for base in ["game/art/modules", "game/art/characters", "game/art/backgrounds", "game/art/sprites/battle", "game/art/audio", "game/art/props", "game/art/navigation_masks"]:
        paths.update(inventory.files(base, inventory.MEDIA | inventory.AUDIO))
    for base in ("game/art/battle_vfx", "assets/retained"):
        if (ROOT / base).is_dir():
            paths.update(inventory.files(base, inventory.MEDIA))
    paths.update(inventory.local(key) for key in inventory.refs if key.startswith("res://art/maps/luoyang") and Path(key).suffix.lower() in inventory.MEDIA and inventory.local(key).is_file())
    for source in scenes.values():
        preview = inventory.assignment(source, "background_path")
        if preview.startswith("res://") and inventory.local(preview).is_file():
            paths.add(inventory.local(preview))
    for base in ["assets/processed/audio/wuxia_expansion_20261022", "assets/processed/audio/wuxia_voice_sfx_expansion_20261022", "assets/processed/luoyang_city_full_rollout_20261022ap", OTHER_CITY_BASE, WORLD100_BASE, PLACEWALK_BASE]:
        if (ROOT / base).is_dir(): paths.update(inventory.files(base, inventory.MEDIA | inventory.AUDIO))
    bianzhou_assets = bianzhou_art04_assets()
    paths.update(ROOT / key for key in bianzhou_assets)
    design_manifests = [ROOT / base / "manifest.json" for base in (DESIGN_BASE, DESERT_DESIGN_BASE, MIAO_DESIGN_BASE, "assets/raw/sect_redesign_20261029j", "assets/raw/sect_remaining_designs_20261029l")]
    design_assets = {}
    sect_assets = {}
    settlement_assets = {}
    settlement_pack_path = ROOT / "game/art/modules/four_settlements_20261030e/resource-pack.json"
    settlement_pack = json.loads(settlement_pack_path.read_text("utf-8")) if settlement_pack_path.is_file() else {}
    for row in settlement_pack.get("assets", []):
        for phase, field in [("原生来源", "source"), ("留白派生", "processed"), ("工程运行图", "output")]:
            asset_path = ROOT / row[field]
            if not asset_path.is_file(): raise RuntimeError("Missing settlement resource: " + row[field])
            if field == "output" and hashlib.sha256(asset_path.read_bytes()).hexdigest() != row["sha256"]:
                raise RuntimeError("Settlement runtime differs: " + row[field])
            paths.add(asset_path)
            settlement_assets[row[field]] = {**row, "phase": phase}
    for row in settlement_pack.get("designs", []):
        paths.add(ROOT / row["output"])
        settlement_assets[row["output"]] = {**row, "phase": "设计参考", "scenes": []}
    current_sect_pack = ROOT / "game/art/modules/sect_completion_20261030a/resource-pack.json"
    current_sect = json.loads(current_sect_pack.read_text("utf-8")) if current_sect_pack.is_file() else {}
    desert_rework_assets = {}
    desert_rework_pack = ROOT / "game/art/modules/desert_city_rework_20261029o/resource-pack.json"
    if desert_rework_pack.is_file():
        for row in json.loads(desert_rework_pack.read_text("utf-8"))["assets"]:
            for phase, field in [("原生来源", "source"), ("留白派生", "processed"), ("工程运行图", "output")]:
                item = ROOT / row[field]
                if not item.is_file(): raise RuntimeError("Missing native city resource: " + row[field])
                if field == "output" and hashlib.sha256(item.read_bytes()).hexdigest() != row["sha256"]:
                    raise RuntimeError("Native city runtime differs: " + row[field])
                paths.add(item)
                desert_rework_assets[row[field]] = {**row, "phase": phase}
    for sect_pack_path in [ROOT / "game/art/modules/sect_maps_20261029k/resource-pack.json", ROOT / "game/art/modules/huashan_map_20261029m/resource-pack.json", ROOT / "game/art/modules/sect_completion_20261030a/resource-pack.json"]:
        if not sect_pack_path.is_file(): continue
        for row in json.loads(sect_pack_path.read_text("utf-8"))["assets"]:
            for phase, field in [("原生来源", "source"), ("留白派生", "processed"), ("工程运行图", "output")]:
                asset_path = ROOT / row[field]
                if not asset_path.is_file(): raise RuntimeError("Missing sect resource: " + row[field])
                if field == "output" and hashlib.sha256(asset_path.read_bytes()).hexdigest() != row["sha256"]:
                    raise RuntimeError("Sect runtime resource differs: " + row[field])
                paths.add(asset_path)
                sect_assets[row[field]] = {**row, "phase": phase}
    redrock_assets = {}
    desert_city_assets = {}
    miao_city_assets = {}
    recompose_keys=set()
    variety_f_keys=set();variety_g_keys=set()
    terrain_pack_path=ROOT/"game/art/modules/miao_terrain_20261029i/resource-pack.json"
    terrain_pack=json.loads(terrain_pack_path.read_text('utf-8')) if terrain_pack_path.is_file() else {}
    for base in (*MIAO_CITY_BASES,*MIAO_RECOMPOSE_BASES,*MIAO_VARIETY_BASES):
        pack_path=ROOT/base/"resource-pack.json"
        if pack_path.is_file():
            pack=json.loads(pack_path.read_text("utf-8"))
            recompose_keys.update(pack.get('reused_previous_asset_keys',[]))
            variety_f_keys.update(pack.get('reused_29f_asset_keys',[]));variety_g_keys.update(pack.get('reused_29g_asset_keys',[]))
            for row in pack["assets"]:
                miao_path=ROOT/row["output"]
                if hashlib.sha256(miao_path.read_bytes()).hexdigest()!=row["sha256"]:
                    raise RuntimeError("Miao city resource differs: "+row["output"])
                paths.add(miao_path)
                miao_city_assets[row["output"]]={**row,'_recompose':base in MIAO_RECOMPOSE_BASES,'_variety':base in MIAO_VARIETY_BASES}
    for base in DESERT_CITY_BASES:
        pack_path=ROOT/base/"resource-pack.json"
        if pack_path.is_file():
            for row in json.loads(pack_path.read_text("utf-8"))["assets"]:
                desert_path=ROOT/row["output"]
                if hashlib.sha256(desert_path.read_bytes()).hexdigest()!=row["sha256"]:
                    raise RuntimeError("Desert city resource differs: "+row["output"])
                paths.add(desert_path)
                desert_city_assets[row["output"]]=row
    editor_rows = []
    for editor_base in (REDROCK_EDITOR_BASE,REDROCK_JOINT_EDITOR_BASE,REDROCK_TOWN_EDITOR_BASE,REDROCK_STANDARD_EDITOR_BASE,REDROCK_COMPLETE_EDITOR_BASE,REDROCK_CITY_LIFE_EDITOR_BASE):
        editor_manifest = ROOT / editor_base / "resource-pack.json"
        editor_pack = json.loads(editor_manifest.read_text("utf-8")) if editor_manifest.is_file() else {}
        editor_rows.extend({**r,"_layout_rejected":editor_pack.get("status")=="USER_REJECTED_ASSEMBLY_NOT_A_DESIGN_BASELINE","_image_count":editor_pack.get("validated_image_count",9),"_status_label":editor_pack.get("resource_status_label","赤岩编辑草案 · 已装配")} for r in editor_pack.get("assets",[]))
    editor_assets = {r["output"]: r for r in editor_rows}
    editor_sources = {r["source"]: r for r in editor_rows}
    editor_sources.update({r["parent_source"]:r for r in editor_rows if r.get("parent_source")})
    for base in (*REDROCK_BASES, REDROCK_DERIVED_BASE,REDROCK_JOINT_DERIVED_BASE):
        redrock_manifest = ROOT / base / "resource-pack.json"
        if redrock_manifest.is_file():
            for row in json.loads(redrock_manifest.read_text("utf-8"))["assets"]:
                path = ROOT / row["output"]
                if hashlib.sha256(path.read_bytes()).hexdigest() != row["sha256"]:
                    raise RuntimeError("Redrock native source differs: " + row["output"])
                paths.add(path)
                redrock_assets[row["output"]] = row
    for design_manifest in design_manifests:
        if design_manifest.is_file():
            for row in json.loads(design_manifest.read_text("utf-8"))["items"].values():
                if row.get("output"):
                    design_path = ROOT / row["output"]
                    if hashlib.sha256(design_path.read_bytes()).hexdigest() != row["sha256"]:
                        raise RuntimeError("Design source differs: " + row["output"])
                    paths.add(design_path)
                    design_assets[row["output"]] = row
    other_manifest = ROOT / OTHER_CITY_BASE / "manifest.json"
    other_assets = {r["output"]: r for r in json.loads(other_manifest.read_text("utf-8"))["assets"]} if other_manifest.is_file() else {}
    world_manifest = ROOT / WORLD100_BASE / "manifest.json"
    if world_manifest.is_file():
        world_rows = json.loads(world_manifest.read_text("utf-8"))["assets"]
        other_assets.update({r["output"]: r for r in world_rows})
        corrections = ROOT / WORLD100_BASE / "corrections.json"
        review = ROOT / WORLD100_BASE / "xueying_correction_review.json"
        if corrections.is_file() and review.is_file() and json.loads(review.read_text("utf-8")).get("current_candidate"):
            for corrected in json.loads(corrections.read_text("utf-8"))["assets"]:
                parent = next(r for r in world_rows if r["id"] == corrected["parent_id"])
                other_assets[parent["output"]] = {**parent, "rejected": True, "label": parent["label"] + "·持剑初版弃用"}
                other_assets[corrected["output"]] = corrected
    old_cache = json.loads(CACHE.read_text("utf-8")) if CACHE.is_file() else {}
    placewalk_manifest = ROOT / PLACEWALK_BASE / "manifest.json"
    if placewalk_manifest.is_file():
        other_assets.update({r["output"]: r for r in json.loads(placewalk_manifest.read_text("utf-8"))["assets"]})
        for ledger_name in ("walk-successors.json", "walk-frames.json", "walk-guided-frames.json"):
            ledger_path = ROOT / PLACEWALK_BASE / ledger_name
            if ledger_path.is_file(): other_assets.update({r["output"]: r for r in json.loads(ledger_path.read_text("utf-8"))["assets"]})
        for rpath, row in list(other_assets.items()):
            if rpath.startswith(PLACEWALK_BASE) and row["kind"] == "npc_walk" and row.get("sha256"):
                other_assets[rpath] = {**row, "rejected": True, "label": row["label"] + "·相位失败保留", "rejection_label": "弃用序列 · 相位重复", "rejection_reason": "不可选用为合格4相行走：整张sheet主要重复两种着地姿态，缺明确经过相位。原图留存追溯，改为逐帧生成。"}
            elif rpath.startswith(PLACEWALK_BASE) and row["kind"] == "npc_walk_frames" and row["id"].endswith("_v3") and row.get("sha256"):
                other_assets[rpath] = {**row, "rejected": True, "label": row["label"] + "·换脚失败保留", "rejection_label": "弃用帧 · 未按相位换脚", "rejection_reason": "不可选用为合格行走相位：首组逐帧仍偏同一只脚向前，接触与经过未清楚分开。保留原失败，另加姿态参照校正。"}
    new_cache: dict = {}
    records = []
    for path in sorted(paths):
        # Adoption ledgers may also contain Godot materials. They remain in the
        # ledger, but are not raster/audio media and cannot be opened by Pillow.
        if path.suffix.lower() not in inventory.MEDIA | inventory.AUDIO:
            continue
        kind = category(path)
        status, label = state(path, approved)
        is_audio = path.suffix.lower() in inventory.AUDIO
        thumb, size = ("", []) if is_audio else thumbnail(path, kind, old_cache, new_cache)
        rpath = inventory.res(path) if path.is_relative_to(GAME) else relative(path)
        consumers = sorted(inventory.refs.get(rpath, []))
        consumers = [{"label": x, "url": href(inventory.local(x))} for x in consumers[:12]]
        notes = []
        concept = design_assets.get(relative(path))
        redrock = redrock_assets.get(relative(path))
        if status == "candidate": notes.append("独立候选；文件存在或静态引用不代表正式采用。")
        elif status == "referenced": notes.append("源码或元数据中的静态引用；可能被运行时覆盖或条件分支控制。")
        elif status == "unconfirmed": notes.append("未检出完整路径引用；动态拼接资源仍可能使用，不据此认定废弃。")
        if kind == "music": notes.append("实际选曲以 MusicCatalog 为准；洛阳四街区当前共用 city_bianzhou。")
        if "20261019y" in relative(path): notes.append("军士差异入口关闭；两版walk未获准入。")
        if kind == "voice": notes.append("DialogPlayer按章节、对白ID、说话人和节点/情绪动态取音；存在文件不等于整段已配齐。")
        if concept:
            notes = ["内置原生整体设计图；待用户审阅，未接入游戏。不是地图模块、精灵或可走背景。",
                     "已保留原PNG与完整提示词；建筑/场景物件/地图待机行走/立绘另见门派与西域设计制作清单。",
                     "西域两镇为设计暂名，不代表新增正式地图或剧情。" if path.stem.startswith(("oasis_", "redrock_")) else "按已有地点功能设计，不变更门派角色与剧情。"]
            if relative(path).startswith("assets/raw/sect_remaining_designs_20261029l/"):
                label="其余门派 · 总规设计候选"
                notes=["华山险峰剑院、古峰山野石寨、凌月寒潭竹楼；现有门派设定下的新总规。各1次内置生成，原PNG与完整提示词保留。", "当前0游戏消费者；场景模块、地图待机与行走精灵、肖像和室外地图尚未制作，不裁总图充当模块。", "阶口、崖径、桥头与墙体接缝必须在模块阶段按人物脚体校验。施工清单：docs/changes/sect-remaining-designs-20261029l.md"]
                if path.stem.startswith("huashan_") and (ROOT/"game/art/modules/huashan_map_20261029m/resource-pack.json").is_file():
                    label="华山总规 · 室外首版已创建"
                    notes=["29m按本图新制8个原生组件，六区/五阶口/0-240-480高程独立F6场景已创建。原总规仍0直接游戏消费者，不裁成组件。", "连续山门到主堂/两侧支路/回到入口通过；崖面连续化，房型分级。仍有院落密度、山体边缘与总规差异；门派NPC/内景业务/正式世界未接。docs/changes/huashan-map-20261029m.md"]
            if relative(path).startswith("assets/raw/sect_redesign_20261029j/") and sect_assets:
                label="总规已确认 · 门派室外首版已创建"
                notes=["用户已确认按此设计改造，29k武当与茗雾独立可编辑地图已创建。原设计图仍0直接游戏消费者，不裁作组件或铺成背景。", "新组件、真实台地与阶口、连续行走与双桥已验证；构图密度和院落细节尚有差距，非完整设计还原终验。门派NPC、室内与正式世界入口未接。docs/changes/sect-maps-20261029k.md"]
            if relative(path).startswith(DESERT_DESIGN_BASE+"/"):
                notes = ["按用户要求另做的黄沙土坯沙漠城市总规，区别于赤岩峡谷关镇；概念设计待审阅，0游戏消费者。", "沙路城门、遮阳巷市、驼队客院、井台蓄水、土坯民居、防沙工坊六区；原PNG及完整提示词保留。", "未创建正式地点ID、世界入口或剧情；原图不当作可走背景或拆图组件。记录：docs/desert-town-design-20261029c.md"]
                if (ROOT/DESERT_DESIGN_BASE/"selected-design-authorization.json").is_file():
                    label="总规已确认 · 独立六区地图已创建"
                    notes=["用户已确认此总规并授权创建独立沙漠城，29d六区可编辑场景已建；此总规仍非游戏贴图，0直接游戏消费者。", "原PNG与提示词保留；正式世界地点ID、入口和剧情未创建。实施：docs/changes/desert-town-20261029d.md"]
            if path.stem.startswith("redrock_") and (ROOT / REDROCK_BASE / "selected-design-authorization.json").is_file():
                label = "制作方向已选定 · 未接入"
                notes = ["用户已选择此图开始赤岩关镇制作；首批峡口关门资源另列，未切换正式场景。", "图中少量中原瓦檐不延用，新岗楼改平顶。其余三套设计不继承此选择。"]
            if relative(path).startswith(MIAO_DESIGN_BASE+"/"):
                label="苗族风情山城 · 总规设计候选"
                notes=["内置原生六区总规：山口寨门、临溪街市、芦笙坪、蜡染绣坊、吊脚民巷、梯田粮院。依山木构、短阶台地、沿溪街市与桥路环线，区别于沙漠土坯城。", "雷山苗寨建筑与苗族蜡染/芦笙非遗资料作参考，布局为原创游戏设计，不作为现实某寨或全部苗族风格的复刻。", "1次内置生成；原RGB不改，0游戏消费者；未建Godot场景、正式地点ID、剧情或NPC动画。整图不裁作组件/精灵；模块、桥头高差和行走碰撞另验。记录：docs/miao-town-design-20261029e.md"]
                if (ROOT/MIAO_DESIGN_BASE/"selected-design-authorization.json").is_file():
                    label="总规已确认 · 六区编辑地图已创建"
                    notes=["用户已确认按此总规创建山城；29f独立六区编辑地图已发布，设计原图仍0直接游戏消费者。", "另制26张原生模块/地图精灵/同人肖像，三桥四短阶与一缓存木楼前厅已运行；未创建正式地点ID、世界入口或剧情。实施：docs/changes/miao-town-20261029f.md"]
                if recompose_keys:
                    label="总规已确认 · 按原稿重排中"
                    notes=["用户指出29f实景偏离原稿，29g已另存溪谷斜穿/高脚铺街/土坪与错落房组的重排版；原图仍0直接游戏消费者。", "新增6独立原生组件，复用既有精灵与肖像；仍有山体起伏、建筑角度和密度差距，未授设计还原或整城最终ART。docs/changes/miao-recompose-20261029g.md"]
                if variety_f_keys:
                    label="总规已确认 · 建筑差异版已创建"
                    notes=["用户继续指出建筑相似/大小统一，29h另制5种不同结构建筑并替换12处；沿用斜溪/土坪/高脚铺街，原设计仍0直接游戏消费者。", "宽木厅/窄高三层楼/低宅/转角作坊/小粮棚形成体量层级；连续山势及全部设计还原未授。docs/changes/miao-building-variety-20261029h.md"]
                if terrain_pack:
                    label="总规已确认 · 三级台地与必经楼梯版已创建"
                    notes=["29i纠正旧版只有装饰楼梯/平地：0/120/240三级台地、连续坎界与4阶口；默认出生点真实行走经两阶至上层民巷，楼梯成为必要通路。", "复用34张原生图，0新PNG；旧设计仍0直接游戏消费者，非整城设计还原终验。docs/changes/miao-terrain-20261029i.md"]
        asset = other_assets.get(relative(path))
        if asset:
            if asset.get("rejected"):
                status, label = "rejected", asset.get("rejection_label", "弃用原稿 · 武器不符")
                notes = []
                notes.append(asset.get("rejection_reason", "不可选用：薛影被添加长剑，违反空手设定；使用另存的空手修正版。保留此图仅供追溯。"))
            batch_label = "地图行走与可放置补充原图；" if relative(path).startswith(PLACEWALK_BASE) else ("百图扩充原图；" if relative(path).startswith(WORLD100_BASE) else "首批其他城镇原图；")
            notes.append(batch_label + "未导入、未接入游戏。")
            if relative(path).startswith(PLACEWALK_BASE):
                notes.append(asset["intended_use"])
                if asset["kind"].startswith("npc_walk"):
                    notes.append("仅下行4帧序列候选，非四向；相位与运行锚点结论看本批walk-review。配套待机：" + asset["reference"])
                    if asset["kind"] == "npc_walk_frames" and asset["id"].endswith("_v4"):
                        notes.append("动画为缩放/平移对齐查看版；原始播放另存，原PNG有尺度/脚位漂移，未制作合格运行atlas。诊断alpha128包围盒只用于预览适配，不替代完整A>0留白检查。")
                else:
                    notes.append("放置到场景/大世界的实体组件，不是背包图标；未绑定采集、奖励或碰撞。")
            if not asset.get("metrics", {}).get("margin_10_percent_pass"):
                notes.append("完整alpha留白未达10%，保留原失败；不得直接作为合格运行图。")
            if asset["kind"] in ("npc_sprites", "enemies", "monsters", "animals", "human_enemies", "story_bosses"):
                notes.append("仅单帧静态候选，不代表行走或攻击动画完成。")
            if asset.get("tier") == "elite": notes.append("精英定位：野外练级高品质怪物；尚未新增遭遇、数值或掉落。")
            if asset.get("tier") == "story_boss": notes.append("Boss定位：已有剧情Boss角色；不作为野外精英。")
            if asset.get("kind") == "animals": notes.append("用户指定动物视觉储备；未新增剧情动物Boss或生态分布。")
            if asset.get("id") == "world100_20261022_boss_masked_killer_leader_v1": notes.append("有限视觉复核：当前朝屏幕右，战斗朝向待验。")
            if asset.get("id") == "world100_20261022_animal_fox_elite_01_v1": notes.append("有限视觉复核：与普通红狐的精英辨识差异偏弱，待强化。")
            if asset.get("id") == "world100_20261022_animal_wild_dog_elite_02_v1": notes.append("有限视觉复核：外形偏狼，野狗物种辨识待复核。")
            if "world100_20261022_npc_linxi_vendor_" in asset.get("id", ""): notes.append("沿用既有男行商身份；线描比本批其他NPC更强，风格统一待验。")
            if asset["sources"]: notes.append("设计依据（非当前消费者）：" + "、".join(asset["sources"]))
        seconds = None
        if path.suffix.lower() == ".wav":
            try:
                with wave.open(str(path), "rb") as wav: seconds = round(wav.getnframes() / wav.getframerate(), 2)
            except (wave.Error, EOFError): pass
        records.append({"id": hashlib.sha256(relative(path).encode()).hexdigest()[:24], "name": concept["name"] if concept else (asset["label"] if asset else path.stem),
                        "category": kind, "categoryLabel": CATEGORIES[kind], "group": group(path, kind) + (" / 弃用原稿" if asset and asset.get("rejected") else ""),
                        "path": rpath, "diskPath": relative(path), "url": href(path), "thumbnail": thumb,
                        "media": "audio" if is_audio else "image", "size": size, "bytes": path.stat().st_size,
                        "format": path.suffix[1:].upper(), "duration": seconds, "status": status,
                        "statusLabel": label, "usage": consumers, "usageCount": len(inventory.refs.get(rpath, [])),
                        "sceneIds": sorted(inventory.scene_refs.get(rpath, [])), "note": " ".join(notes)})
        if redrock:
            records[-1].update(name=redrock["label"], status="rejected" if redrock.get("rejected") else "candidate",
                               statusLabel="首稿保留 · 门洞不足" if redrock.get("rejected") else "赤岩候选 · 未接入",
                               note=redrock["review_note"] + (" 原生PNG未修改；完整A>0四边留白不足10%，未导入或绑定游戏。" if "transparent" not in redrock else " 原生PNG未修改；未导入或绑定游戏。" + ("完整A>0四边留白不足10%。" if redrock["transparent"] else "")))
            if redrock.get("derivation"):
                records[-1].update(group=REDROCK_GROUPS[redrock["kind"]], statusLabel="留白派生 · 未接入",
                                   note=redrock["review_note"] + " 摆放时保原像素缩放并补偿留白偏移；未授完整门户、稳定动画或正式运行准入。")
            if redrock.get("animation_preview"):
                records[-1]["animationPreview"] = href(ROOT / redrock["animation_preview"])
            if redrock["kind"] == "design":
                records[-1].update(statusLabel="设计已确认 · 试拼中" if redrock.get("approved_for_trial") else "重设计提案 · 待审阅", note=redrock["review_note"])
            if relative(path).startswith(REDROCK_TRIAL_BASE+"/"):
                records[-1].update(statusLabel="结构试拼 · 未正式接入",note="用户已确认d版设计后制作的三块结构候选；仅在隔离原生预览中只读ImageTexture试拼，未导入game。原PNG未裁切/拉伸/改像素，完整A1留白仍未达10%；墙道/垛口/光影和正式五锚点接口仍待适配。 实际试拼与记录：docs/redrock-joint-trial-20261023e.md")
            if relative(path).startswith(REDROCK_DESERT_LIFE_BASE + "/"):
                margin_ok = redrock["metrics"]["margin_10_percent_pass"]
                records[-1].update(statusLabel="沙漠生活组件 · 待装配",
                                   note=redrock["review_note"] + " 原生PNG字节保持；当前游戏消费者为0。" + ("完整A>0留白通过10%。" if margin_ok else "完整A>0留白不足10%，不得直接视为合格运行图。") + " 清单：docs/redrock-desert-life-20261025a.md")
            if relative(path).startswith(REDROCK_TOWN_BASE + "/"):
                records[-1].update(statusLabel="六区装配原图 · 未正式准入",note=redrock["review_note"] + " 内置新原图完整A1留白不足10%；只经字节相同工程副本用于布局草案，未本地像素处理。")
        if asset and relative(path).startswith(PLACEWALK_BASE) and asset["kind"].startswith("npc_walk"):
            records[-1]["group"] = "地图行走精灵 / " + asset["label"].replace("地图下行4帧", "")
            preview = ROOT / "assets/previews/world_placeables_walk_20261022" / (asset["id"] + ".gif")
            if preview.is_file() and not asset.get("rejected"): records[-1]["animationPreview"] = href(preview)
            if asset["kind"] == "npc_walk_frames":
                records[-1]["group"] = "地图行走精灵 / " + asset["label"].split("·", 1)[0]
                preview = ROOT / "assets/previews/world_placeables_walk_20261022" / (asset["family"] + "_walk_down.gif")
                if asset["frame_index"] == 1 and preview.is_file() and not asset.get("rejected"): records[-1]["animationPreview"] = href(preview)
        editor_copy = editor_assets.get(relative(path))
        editor_source = editor_sources.get(relative(path))
        if editor_copy or editor_source:
            row = editor_copy or editor_source
            consumer = {"label": row["scene"], "url": href(inventory.local(row["scene"]))}
            if editor_copy:
                editor_category = {"npc_sprite": "npc", "npc_walk": "npc", "portrait": "portrait"}.get(row["kind"], "map")
                records[-1].update(name=row["label"], category=editor_category,
                                   categoryLabel=CATEGORIES[editor_category],
                                   group=REDROCK_GROUPS[row["kind"]] + " / 编辑器草案",
                                   status="candidate", statusLabel=row["_status_label"],
                                   note=f"已装配到独立原生节点场景，可在编辑器修改/F6预览；贴图与来源PNG字节一致，{row['_image_count']}图隔离导入RGBA精确。仅峡口首段草案，未接入正式世界；精灵仅待机，行走序列未启用。 来源：" + row["source"])
            else:
                records[-1].update(status="candidate", statusLabel="原图来源 · 编辑草案引用",
                                   note="此图通过字节一致的工程副本供赤岩峡口编辑草案使用；原PNG保持。副本：" + row["output"] + "。未接入正式世界，原有步态/组件和完整门户限制不因本次草案自动解除。")
            records[-1]["usage"] = [consumer]
            records[-1]["usageCount"] = 1
            if editor_copy:
                scene_uses = {consumer["label"]: consumer}
                for direct in inventory.refs.get(rpath, []):
                    if direct.endswith(".tscn"):
                        scene_uses[direct] = {"label":direct,"url":href(inventory.local(direct))}
                records[-1]["usage"] = list(scene_uses.values())
                records[-1]["usageCount"] = len(scene_uses)
            if row["scene"] == "res://scenes/drafts/redrock_town_20261028a/redrock_town.tscn":
                records[-1].update(statusLabel="六区编辑草案 · 已装配" if editor_copy else "原图来源 · 六区草案引用",
                                   note="供赤岩六区可编辑布局草案使用，20图隔离导入RGBA精确；贴图与来源PNG字节相同，原A1失败/未正式准入状态不被装配洗成通过。六区动线/40实例，世界入口、室内、任务及稳定行走未接。 来源：" + row["source"] + "；记录：docs/redrock-town-20261028a.md")
            if "redrock_luoyang_standard_20261028b" in row["scene"]:
                records[-1].update(statusLabel="生活街段与前厅 · 编辑草案" if editor_copy else "原图来源 · 生活街段引用",note="28图字节原样供四院/独立驿舍前厅，同角色进返与静态保持已独立实测；地图待机/肖像同人，正式服务/剧情/行走未接。原A1候选失败不因装配晋升。来源："+row["source"]+"；记录：docs/redrock-luoyang-standard-20261028b.md")
            if "redrock_desert_complete_20261028d" in row["scene"]:
                records[-1].update(statusLabel="六区与关外商路 · 已装配" if editor_copy else "原图来源 · 完整地图引用",note="供六区与关外商路地图装配：连续峡壁/石阶/两室内、正式主角与居民行走、沙狐普通动物序列；17新增工程图RGBA精确。石匠左向由原生右向在运行时镜像，原PNG不变。正式世界入口、任务战斗和A1美术准入未授。来源："+row["source"]+"；记录：docs/redrock-desert-complete-20261028d.md")
            if row["output"].startswith(REDROCK_CITY_LIFE_EDITOR_BASE+"/"):
                records[-1].update(statusLabel="街坊铺地 · 已用于编辑地图" if editor_copy else "原生铺地来源 · 编辑地图引用",note="原生砂岩小石板材质，街巷与四院采用512周期采样；RGB原样复制，隔离导入RGBA精确。2间新增民居、22组生活陈设和4名复用精灵巡行人物已装配；旧三阶分层保持。此不透明地表不适用透明组件A1留白。正式世界、剧情战斗及整城艺术终验仍待。来源："+row["source"]+"；记录：docs/changes/redrock-city-life-20261029a.md")
            if not editor_copy and not row["_layout_rejected"]:
                source_rows = [r for r in editor_rows if not r["_layout_rejected"] and relative(path) in (r["source"], r.get("parent_source"))]
                consumers_by_scene = {r["scene"]: {"label":r["scene"],"url":href(inventory.local(r["scene"]))} for r in source_rows}
                for source_row in source_rows:
                    output_key = inventory.res(inventory.local(source_row["output"]))
                    for direct in inventory.refs.get(output_key, []):
                        if direct.endswith(".tscn"):
                            consumers_by_scene[direct] = {"label":direct,"url":href(inventory.local(direct))}
                records[-1]["usage"] = list(consumers_by_scene.values())
                records[-1]["usageCount"] = len(consumers_by_scene)
            if not editor_copy and row.get("parent_source")==relative(path):
                records[-1].update(statusLabel="原生来源 · 派生供工程草案",note="用户许可仅增加透明画布后，通过派生供f版工程结构草案使用；原PNG及全部原RGBA保持，原图的A1失败仍保留。工程副本："+row["output"])
            if row["_layout_rejected"]:
                records[-1].update(statusLabel="旧拼装 · 用户否定" if editor_copy else "来源保留 · 旧布局弃用",
                                   note="用户已否定c版装配：岗楼孤立、墙体未形成连接，当前仅保留追溯，不继续采用该布局。旧通行/导入检查不等于艺术通过。素材可另行评估复用；关门/岗楼/墙体接口需按d版整体设计重做。旧消费者：" + row["scene"])
        bianzhou = bianzhou_assets.get(relative(path))
        if bianzhou:
            source = bianzhou["sourcePath"]
            child_uses = {child: {"label": child, "url": href(ROOT / child)} for child in bianzhou["children"]}
            child_uses.update({use["label"]: use for use in records[-1]["usage"]})
            records[-1].update(name=bianzhou["name"], group=bianzhou["group"], status=bianzhou["status"],
                               statusLabel=bianzhou["statusLabel"], sha256=bianzhou["sha256"], sourcePath=source,
                               note=bianzhou["note"] + (" 来源：" + source if source else "") + " 本批七次内置生成/编辑；实际model/provider/cost未返回，保持未知。",
                               usage=list(child_uses.values()), usageCount=len(child_uses),
                               generation={"backend": "builtin_image_gen", "model": None, "provider": None, "cost": None})
        desert = desert_city_assets.get(relative(path))
        if desert:
            game_copy=relative(path).startswith(DESERT_CITY_BASES[2]+"/")
            derived=relative(path).startswith(DESERT_CITY_BASES[1]+"/")
            rejected=bool(desert.get("rejected"))
            scene="res://scenes/drafts/desert_town_20261029d/desert_town.tscn"
            consumer={"label":scene,"url":href(inventory.local(scene))}
            stage="工程运行图" if game_copy else ("留白派生" if derived else "原生来源")
            note="黄沙土坯独立城镇，六区/三个民院/客院与井院，默认正式主角跟随与行走、六名复用居民巡行和一缓存前厅。"
            if rejected:
                note="首稿城廓内部进深不足，保留追溯，未用于新城；使用独立登记的enclosure_v2后继。"
            elif game_copy:
                note+=" 13新工程图隔离导入RGBA精确；透明图仅补RGBA0留白、原RGBA保持，原RAW的A1失败未洗白。"
            elif derived:
                note+=" 透明组件仅增RGBA0画布，完整A>0边距通过10%；黄沙材质字节原样复制。经工程副本供场景引用。"
            else:
                note+=" 原PNG保持；透明RAW完整A1边距仍失败，通过授权透明留白派生间接供工程使用。"
            note+=" 29j已接正式世界与进返，剧情/经济/战斗未新增，非整城最终ART。记录：docs/changes/desert-town-20261029d.md"
            if desert_rework_assets and desert["key"] == "enclosure_v2":
                rejected=True
                note="29o已退掉整圈城廓放大5倍的场景用法，改为独立原生城门、正墙、两向侧墙与圆堡。此旧图保留追溯；旧ext_resource声明不代表仍有显示节点。大地图也改用专用完整微缩城市。docs/changes/desert-city-native-rework-20261029o.md"
            records[-1].update(name=desert["label"],group=DESERT_CITY_GROUPS[desert["kind"]]+" / "+stage,
                status="rejected" if rejected else "candidate",
                statusLabel=("旧整圈城廓 · 已停用" if desert_rework_assets and desert["key"] == "enclosure_v2" else "首稿保留 · 内部进深不足") if rejected else ("六区可编辑地图 · 已装配" if game_copy else stage+" · 编辑地图引用"),
                note=note,sha256=desert["sha256"],usage=[] if rejected else [consumer],usageCount=0 if rejected else 1)
        miao = miao_city_assets.get(relative(path))
        if miao:
            revised=miao.get('_recompose',False)
            varied=miao.get('_variety',False)
            game_copy=relative(path).startswith((MIAO_CITY_BASES[2]+"/",MIAO_RECOMPOSE_BASES[2]+"/",MIAO_VARIETY_BASES[2]+"/"))
            derived=relative(path).startswith((MIAO_CITY_BASES[1]+"/",MIAO_RECOMPOSE_BASES[1]+"/",MIAO_VARIETY_BASES[1]+"/"))
            stage="工程运行图" if game_copy else ("留白派生" if derived else "原生来源")
            scene="res://scenes/drafts/"+('miao_building_variety_20261029h' if varied else ('miao_recompose_20261029g' if revised else 'miao_town_20261029f'))+"/miao_town.tscn"
            if varied:
                note="29h建筑差异版：5种新原生结构替换12处同尺度楼型，宽公共木厅、窄高三层楼、低单间宅、转角作坊、小高脚粮棚。新高度约200—690px，成人门约105—120px；小粮棚为储藏舱，不是缩小成人房。5透明仅增RGBA0留白，原RGBA精同，原A1失败保留。"
            elif revised:
                note="29g按原稿重排：溪谷左上至右下、36民居含8高脚楼、6铺位架空木街、土坪/苔岩/叠瀑与沿坡梯田。新增6原生图，5透明仅RGBA0补白/原RGBA保持，林下底材原样复制；三桥四阶/铺街行走与重定位前厅已运行。"
            else:
                note="29f历史首版资源：原布局37民居、三桥四短阶、绣坊与梯田；用户指出实景偏离总规，旧布局保留追溯。26原生/23透明仅RGBA0留白，原RGBA保持，RAW原A1失败保留。"
                if miao['key'] in recompose_keys:note+=" 本图亦经工程副本被29g重排版复用。"
            if miao['key'] in ['man_walk','woman_walk','side_stride']:
                note+=" 原4×4仅取四向待机；实际侧行使用独立4相，向左运行镜像；原上下行走未采用，非原生四向walk合格。"
            if miao['key']=='man_portrait':note+=" 男工肖像为原生腰部裁切构图，不是全身立绘。"
            note+=" 默认正式冷孤云四向待机/行走，8居民复用2身份侧行四相/左镜像、一缓存前厅；正式世界/剧情/经济/战斗未接，非设计还原终验。旧f/g/h四阶检查仅证明平面通行，未证明高差。docs/changes/miao-recompose-20261029g.md"
            category_id='npc' if miao['kind']=='npc_walk' else ('portrait' if miao['kind']=='portrait' else 'map')
            consumers=[{'label':scene+('（经工程副本）' if not game_copy else ''),'url':href(inventory.local(scene))}]
            if not revised and miao['key'] in recompose_keys:
                current="res://scenes/drafts/miao_recompose_20261029g/miao_town.tscn"
                consumers.append({'label':current+'（重排版）','url':href(inventory.local(current))})
            if not varied and miao['key'] in (variety_g_keys if revised else variety_f_keys):
                current="res://scenes/drafts/miao_building_variety_20261029h/miao_town.tscn"
                consumers.append({'label':current+'（建筑差异版）','url':href(inventory.local(current))})
            if varied:note+=" 当前差异版：docs/changes/miao-building-variety-20261029h.md。公共木厅/新楼仅外观，未新增业务或内景。"
            family='miao_building_variety_20261029h' if varied else ('miao_recompose_20261029g' if revised else 'miao_town_20261029f')
            terrain_used=miao['key'] in terrain_pack.get('reused_asset_keys',{}).get(family,[])
            if terrain_used:
                current=terrain_pack['scene']
                consumers.append({'label':current+'（三级台地/必经石阶版）','url':href(inventory.local(current))})
                note+=" 当前29i按真实0/120/240台地分配房屋/居民高程，连续坎界封口，仅4阶口连通上下层。石阶连续抬脚/侧墙与非阶坎阻挡、默认出生点连续上两阶已验证；0PNG处理。docs/changes/miao-terrain-20261029i.md"
                if terrain_pack.get('revision')=='lanxi_revision_20261030l':
                    note+=" 当前30l岚溪寨正式版：建筑完整不透明，遮挡处仅主角半透明；变形薄墙退为166段完整等比苔石坡岸，5屋3杂物退离边界，四阶实走及原World/木楼前厅往返通过。0新图/0PNG改写。docs/changes/lanxi-occlusion-and-banks-20261030l.md"
            records[-1].update(name=miao['label'],category=category_id,group=MIAO_CITY_GROUPS[miao['kind']]+" / "+stage,
                status='candidate',statusLabel=("三级台地版 · 当前复用" if terrain_used else ("建筑差异版 · 保留" if varied else ("原稿重排版 · 保留复用" if revised else "旧布局资源 · 保留复用"))) if game_copy else stage+" · 编辑地图引用",
                note=note,sha256=miao['sha256'],usage=consumers,usageCount=len(consumers),
                generation={'backend':'builtin_image_gen','model':None,'provider':None,'cost':None})
            if terrain_used and terrain_pack.get('revision')=='lanxi_revision_20261030l':
                records[-1].update(status='referenced',statusLabel='岚溪寨正式版 · 原生坡岸/主角半透明')
        sect = sect_assets.get(relative(path))
        if sect:
            kind_labels = {"building":"建筑与院界", "ground":"道路与地表", "vegetation":"松林与茶垄", "landform":"灰岩山体", "scene_prop":"场景可放置陈设"}
            faction = {"wudang":"武当派","mingwu":"茗雾山庄","huashan":"华山派","lingyue":"凌月派","lieyun":"烈云谷"}[sect["sect"]]
            if sect["key"] == "quiet_ground": faction = "两派共用"
            uses = [{"label":scene,"url":href(inventory.local(scene))} for scene in sect["scenes"]]
            records[-1].update(name=sect["label"], category="map", categoryLabel=CATEGORIES["map"],
                group=faction+" / "+kind_labels[sect["kind"]]+" / "+sect["phase"], status="candidate",
                statusLabel="可编辑门派地图 · 已装配" if sect["phase"]=="工程运行图" else sect["phase"]+" · 编辑地图引用",
                note="按29j确认设计制作：武当三级山台、茗雾低台茶院，每派4处必要石阶，双桥接平路；正式主角连续入口到厅与侧路返回已验证。12新原生组件，透明图仅补RGBA0留白、原RGBA不变；原RAW留白失败仍保留。当前为可试玩室外首版，门派NPC、室内服务、正式世界入口未接，非完整设计还原终验。记录：docs/changes/sect-maps-20261029k.md。原图："+sect["source"],
                usage=uses, usageCount=len(uses), sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                generation={"backend":"builtin_image_gen","model":None,"provider":None,"cost":None})
            if sect["sect"]=="huashan":
                records[-1]["note"]="29m华山险峰剑院室外首版：新制主堂/山门/长舍/两层书舍/灶房/剑架/花岗岩/灰石地面共8图，7透明只增加RGBA0留白，原RGBA保持，原A1失败保留。五阶口/三级地形/连续崖缘，正式冷孤云连续走完全环线及保存重开通过；不是完整设计还原，NPC/内景/正式世界未接。docs/changes/huashan-map-20261029m.md。原图："+sect["source"]
            if "sect_completion_20261030a" in sect["output"]:
                records[-1].update(status="referenced",statusLabel="正式门派室外入口已接入",note="凌月寒潭竹院、烈云灰岩木寨，7张独立原生组件，只增加RGBA0留白，原RGBA保持，原A1失败保留。三级真实地形与必经石阶；原对话、开放条件、内院进返及高地箭头已实机验证。茗雾复用既有茶院模块并接入原入口。原剧情内院沿用，本批未重做。docs/changes/town-layout-and-sect-entries-20261030a.md。原图："+sect["source"])
        if current_sect:
            runtime_path = sect["output"] if sect else relative(path)
            current_uses = current_sect.get("reused_consumers", {}).get(runtime_path, [])
            if current_uses:
                uses_by_label = {use["label"]: use for use in records[-1]["usage"]}
                for use in current_uses: uses_by_label[use] = {"label": use, "url": href(inventory.local(use))}
                records[-1].update(usage=list(uses_by_label.values()),usageCount=len(uses_by_label),status="referenced",statusLabel="30a正式门派室外复用")
                records[-1]["note"]="当前30a：已被新门派室外场景实际装配并接入原地点入口；原对话/内院业务保留，PNG未改。docs/changes/town-layout-and-sect-entries-20261030a.md。以下为历史制作说明："+records[-1]["note"]
        # Preserve older consumers while adding the new independent scene references.
        native_city = desert_rework_assets.get(relative(path))
        if native_city:
            uses = [{"label": scene + ("（经工程副本）" if native_city["phase"] != "工程运行图" else ""), "url": href(inventory.local(scene))} for scene in native_city["scenes"]]
            label = "大地图 / 完整城市微缩图" if native_city["kind"] == "world_landmark" else ("赤岩镇 / 原生短崖与收口" if native_city["kind"] == "terrain" else "沙漠城 / 分段土坯城廓")
            records[-1].update(name=native_city["label"], category="map", categoryLabel=CATEGORIES["map"],
                group=label+" / "+native_city["phase"], status="referenced", statusLabel="29o正式场景已使用" if native_city["phase"] == "工程运行图" else native_city["phase"]+" · 正式场景来源",
                note="本批8张独立原生图，各1次内置生成；只增加RGBA0透明留白，原RGBA完整保留。赤岩外围崖、沙漠城廓/院墙/沙丘取消大于1倍显示；世界两城改用统一0.46倍完整微缩图。正式World真实进返与新门脚通过，正常镜头已核；不代表整城密度或设计稿完全还原。侧墙按两轴收缩适配城界，无纹理放大。docs/changes/desert-city-native-rework-20261029o.md。原图："+native_city["source"],
                usage=uses, usageCount=len(uses), sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                generation={"backend":"builtin_image_gen","model":None,"provider":None,"cost":None})
        sect_uses = [use for use in inventory.refs.get(rpath, []) if any(batch in use for batch in ["/sect_maps_20261029k/","/huashan_map_20261029m/"]) and use.endswith(".tscn")]
        if sect_uses and not sect:
            uses_by_label = {use["label"]:use for use in records[-1]["usage"]}
            for use in sect_uses: uses_by_label[use]={"label":use,"url":href(inventory.local(use))}
            records[-1]["usage"]=list(uses_by_label.values());records[-1]["usageCount"]=len(uses_by_label)
        settlement = settlement_assets.get(relative(path))
        if settlement:
            design = settlement["phase"] == "设计参考"
            uses = [{"label": scene, "url": href(inventory.local(scene))} for scene in settlement["scenes"]]
            settlement_category = "design" if design else "map"
            records[-1].update(name=settlement["label"],category=settlement_category,categoryLabel=CATEGORIES[settlement_category],
                group="白鹿渡 / 东海埠 / 林西村 / 竹尾村 / "+("总规设计" if design else settlement["kind"])+" / "+settlement["phase"],
                status="candidate" if design else "referenced",statusLabel="设计参考 · 未裁作模块" if design else "30e正式室外已装配",
                usage=uses,usageCount=len(uses),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                note="四地室外改造，共6个布局接入7个原场景ID，原人物、对话、任务条件和室内入口保留。4张新模块仅增加RGBA0留白，原RGBA完整保留；4张设计仅作参考。布局为室外首版，非完整设计密度或新室内制作。docs/changes/four-settlements-remodel-20261030e.md。",
                generation={"backend":"builtin_image_gen","model":None,"provider":None,"cost":None})
        new_uses = settlement_pack.get("reused_consumers", {}).get(relative(path), [])
        if new_uses:
            uses = {r["label"]:r for r in records[-1]["usage"]}
            for scene in new_uses: uses[scene] = {"label":scene,"url":href(inventory.local(scene))}
            records[-1].update(usage=list(uses.values()),usageCount=len(uses),status="referenced",statusLabel="30e村镇室外复用")
            records[-1]["note"]="当前白鹿渡、东海埠、林西村或竹尾村室外复用；原PNG未改。"+records[-1]["note"]
    drifted = [relative(p) for p, digest in inventory.snapshots.items() if hashlib.sha256(p.read_bytes()).hexdigest() != digest]
    if drifted: raise RuntimeError("Sources changed during inventory: " + ", ".join(drifted[:10]))
    THUMBS.mkdir(parents=True, exist_ok=True)
    CACHE.write_text(json.dumps(new_cache, ensure_ascii=False, indent=2) + "\n", "utf-8")
    return {"generatedAt": datetime.now(ZoneInfo("Asia/Shanghai")).strftime("%Y-%m-%d %H:%M +08:00"),
            "categories": [{"id": k, "name": v, "count": sum(r["category"] == k for r in records)} for k, v in CATEGORIES.items()],
            "records": records, "summary": {"total": len(records), "images": sum(r["media"] == "image" for r in records),
                                         "audio": sum(r["media"] == "audio" for r in records), "states": dict(Counter(r["status"] for r in records))}}


if __name__ == "__main__":
    result = build()
    print(json.dumps(result["summary"], ensure_ascii=False))
