#!/usr/bin/env python3
"""Build the repository resource reuse document without loading Godot or changing assets."""
from __future__ import annotations

import hashlib
import json
import re
import struct
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo
from world100_asset_selection import select_assets

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
OUTPUT = ROOT / "docs/resource-reuse-index.md"
MEDIA = {".png", ".jpg", ".jpeg", ".webp"}
AUDIO = {".wav", ".mp3", ".ogg"}
TEXT = {".gd", ".tres", ".tscn", ".json"}
REF = re.compile(r'res://[^"\s<>\\]+')
snapshots: dict[Path, str] = {}
refs: dict[str, set[str]] = defaultdict(set)
scene_refs: dict[str, set[str]] = defaultdict(set)
lines: list[str] = []
missing: set[str] = set()
inventoried: set[Path] = set()


def read(path: Path) -> str:
    data = path.read_bytes()
    snapshots[path] = hashlib.sha256(data).hexdigest()
    return data.decode("utf-8-sig", errors="replace")


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def res(path: Path) -> str:
    return "res://" + path.relative_to(GAME).as_posix()


def local(value: str) -> Path:
    return GAME / value[6:] if value.startswith("res://") else ROOT / value


def link(value: str | Path) -> str:
    path = value if isinstance(value, Path) else local(value)
    label = res(path) if path.is_relative_to(GAME) else rel(path)
    return f"[{label}](<{path.as_posix()}>)"


def file_cell(value: str) -> str:
    if not value:
        return "—"
    path = local(value)
    if not path.is_file():
        missing.add(value)
        return f"`{value}`（路径未找到）"
    return link(path)


def table(headers: list[str], rows: list[list[str]]) -> None:
    lines.extend(["| " + " | ".join(headers) + " |", "| " + " | ".join(["---"] * len(headers)) + " |"])
    for row in rows:
        lines.append("| " + " | ".join(str(v).replace("|", "\\|").replace("\n", " ") for v in row) + " |")
    lines.append("")


def section(title: str, content: str = "") -> None:
    lines.extend([title, ""])
    if content:
        lines.extend([content, ""])


def assignment(text: str, key: str) -> str:
    m = re.search(r'(?m)^' + re.escape(key) + r'\s*=\s*&?"([^"\n]*)"', text)
    return m.group(1) if m else ""


def files(base: str, suffixes: set[str]) -> list[Path]:
    return sorted(p for p in (ROOT / base).rglob("*") if p.is_file() and p.suffix.lower() in suffixes)


def image_size(path: Path) -> str:
    # Only read PNG headers; this inventory does not decode/edit large images.
    try:
        with path.open("rb") as handle:
            header = handle.read(24)
        if header[:8] == b"\x89PNG\r\n\x1a\n":
            w, h = struct.unpack(">II", header[16:24])
            return f"{w}×{h}"
    except OSError:
        pass
    return "—"


def use_cell(path: Path) -> str:
    key = res(path)
    if key in {
        "res://art/modules/luoyang_market_space_20261024b/apothecary_complete_v2.png",
        "res://art/modules/luoyang_market_space_20261024b/bookshop_complete_v2.png",
    }:
        return "24b固定binding与南市原生Scene消费：" + file_cell("res://build/luoyang_city_space_20261024b_source01/runtime_READY02/market_space_binding_READY.json") + "；不是普通静态路径扫描结论。"
    direct = sorted(scene_refs[key])
    consumers = sorted(refs[key])
    if direct:
        return "场景配置：" + "、".join(f"`{v}`" for v in direct[:4]) + (f" 等{len(direct)}处" if len(direct) > 4 else "")
    if consumers:
        return "静态引用：" + "、".join(link(local(v)) for v in consumers[:2]) + (f"；共{len(consumers)}源" if len(consumers) > 2 else "")
    return "未检出完整路径静态引用；可能动态拼接，待选用核对"


def scan_sources() -> tuple[dict[Path, str], dict[Path, str]]:
    sources = []
    for folder in ["game/scripts", "game/data", "game/scenes"]:
        for path in files(folder, TEXT):
            parts = path.relative_to(GAME).parts
            if "dev" in parts or any(x.startswith(".") or "backup" in x.lower() for x in parts):
                continue
            sources.append(path)
    texts = {p: read(p) for p in sources}
    for path, text in texts.items():
        consumer = res(path)
        if path.suffix == ".gd":
            text = "\n".join(line for line in text.splitlines() if not line.lstrip().startswith("#"))
        elif path.suffix == ".json":
            # Hash/source/proof dictionaries are provenance, not texture usage.
            try:
                obj = json.loads(text)
            except ValueError:
                continue
            values = []

            def walk(value, key=""):
                if key in {"source_sha256", "sources", "historical_publication_sources_not_claimed_current", "runtime_source_successions"}:
                    return
                if isinstance(value, dict):
                    for k, v in value.items():
                        walk(v, k)
                elif isinstance(value, list):
                    for item in value:
                        walk(item, key)
                elif isinstance(value, str) and value.startswith("res://"):
                    values.append(value)
            walk(obj)
            text = json.dumps(values)
        for match in REF.findall(text):
            refs[match].add(consumer)
        if path.parent == GAME / "data/scenes":
            sid = assignment(texts[path], "scene_id") or path.stem
            for target in REF.findall(texts[path]):
                scene_refs[target].add(sid)
    return texts, {p: t for p, t in texts.items() if p.is_relative_to(GAME / "data/scenes")}


def resource_table(paths: list[Path], status="") -> None:
    rows = []
    for path in paths:
        inventoried.add(path)
        kind = status
        if "candidates" in path.parts:
            kind = "候选目录；未视作正式"
        elif "20261019y" in path.as_posix():
            kind = "军士差异候选；两index=false；walk未通过"
        rows.append([link(path), image_size(path), kind or "状态见引用；静态引用不等于正式验收", use_cell(path)])
    table(["完整资源路径", "像素尺寸", "当前状态", "使用位置或引用入口"], rows)


def main() -> None:
    # main can also be called by a documentation check in a long-lived process.
    snapshots.clear(); refs.clear(); scene_refs.clear(); lines.clear(); missing.clear(); inventoried.clear()
    texts, scenes = scan_sources()
    modules = files("game/art/modules", MEDIA)
    chars = files("game/art/characters", MEDIA)
    audio = files("game/art/audio", AUDIO)
    backgrounds = files("game/art/backgrounds", MEDIA)
    battle = files("game/art/sprites/battle", MEDIA)
    now = datetime.now(ZoneInfo("Asia/Shanghai")).strftime("%Y-%m-%d %H:%M:%S +08:00")
    section("# 地图 音频和 NPC 资源复用索引", f"更新快照：{now}。工程根目录：`F:/Code/RPG_GAME`。Godot 的 `res://` 对应本仓库 `game/`；表中完整路径可点击，也可直接复制到资源字段。")
    section("## 使用方法与状态口径", "先按用途查快速入口，再进入对应明细。新模块优先复用已验收组件的运行版与原有装配方式。洛阳磁盘当前已有 **AP 统一八外场候选部署**，整城实际验收仍在进行；AO 两门脸、AN 宅园等下列记录是已验收的历史组件层，不能据此推定AP当前整城可用。采用状态需结合 `docs/current-progress.md` 最新快照与启用入口逐项确认；静态清点没有启动游戏或重新验收地图。")
    table(["标记", "含义"], [
        ["正式接入", "有已完成项目记录及启用入口；描述现有采用状态，不重新授予验收结论。"],
        ["场景配置 / 静态引用", "源码、TRES 或元数据中可定位的路径引用；可能经过运行时覆盖、剧情门禁或关闭的分支。"],
        ["候选 / 试听", "存在文件或配置，尚未正式接入；失败版本和未授权处理的原图也保留。"],
        ["未检出完整路径静态引用", "本次静态源范围未匹配该完整路径；不能据此判断废弃，目录拼接/原生二进制/导出包也会消费资源。"],
    ])
    lines.extend(["目录： [快速入口](#快速入口) · [地图与场景](#地图与场景) · [地图组件明细](#地图组件明细) · [音乐音效与配音](#音乐音效与配音) · [npc-精灵与立绘](#npc-精灵与立绘) · [原图与候选库](#原图与候选库) · [维护与核验](#维护与核验)", ""])
    section("## 快速入口")
    quick = [
        ["村庄建筑、道路、植被与箱罐", "game/art/modules/building", "game/art/modules/ground", "game/art/modules/prop", "game/art/modules/veg"],
        ["洛阳室外建筑与生活物件", "game/art/modules/luoyang_assembled_20261016b", "game/art/modules/luoyang_district_life_20261016f"],
        ["洛阳室内壳、家具", "game/art/modules/luoyang_assembled_interiors_20261016g", "game/data/maps/luoyang_estate_rooms_20261021am/registry.json"],
        ["码头与作业物件", "game/art/modules/luoyang_docks_office_20261016h", "game/data/maps/luoyang_docks_workyard_20261019ac"],
        ["湿岸、车辙、绳缆、南市磨损", "game/art/modules/luoyang_shore_market_20261020ae"],
        ["宅园主厅、厢房、廊、花床", "game/art/modules/luoyang_estate_components_20261021am"],
        ["南市药铺、书斋门脸", "game/art/modules/luoyang_market_two_shops_20261021ao"],
        ["南市完整药铺、书斋（24b后继）", "game/art/modules/luoyang_market_space_20261024b", "game/build/luoyang_city_space_20261024b_source01/runtime_READY02/market_space_binding_READY.json"],
        ["世界拼装与分块", "game/art/modules/world_map_v13", "game/art/maps/world_map_v15_complete_v9c", "game/data/background_sets/world_map_jianghu_v15_streamed.tres"],
        ["认可音乐库", "game/art/audio/bgm/wuxia_20261011", "game/scripts/audio/music_catalog.gd"],
        ["战斗/UI音效", "game/art/audio/free", "game/scripts/autoload/audio_manager.gd"],
        ["场景NPC精灵与肖像", "game/art/characters", "game/art/characters/portraits", "game/data/npcs/npc_catalog.tres"],
        ["码头搬运工同人精灵与肖像", "game/art/characters/luoyang_docks_roles_20261019ad", "game/art/characters/portraits/luoyang_docks_roles_20261019ad"],
        ["战斗角色动作帧", "game/art/sprites/battle", "game/data/enemies"],
    ]
    table(["新模块需要什么", "查找路径"], [[row[0], "<br>".join(link(v) for v in row[1:])] for row in quick])
    table(["盘点范围", "文件数", "说明"], [
        ["地图模块运行图", str(len(modules)), "art/modules 中 PNG/JPG；不含 .import/.ctex、原图与地图历史捕获。"],
        ["背景运行图", str(len(backgrounds)), "art/backgrounds；包含旧版、预览和战斗背景，见逐项引用。"],
        ["SceneScript 资源", str(len(scenes)), "递归场景资源，含顶层及候选/室内子目录；不等于全部当前可达场景。"],
        ["工程音频", str(len(audio)), "全部可播放 WAV/MP3/OGG；其中对白文件单列，不按文件数推断音色数。"],
        ["characters 图像", str(len(chars)), "含NPC、立绘、主角、武器变体和旧版；按目录分组。"],
        ["battle 动作图", str(len(battle)), "按角色动作目录列文件；与探索NPC精灵分开引用。"],
    ])
    section("## 地图与场景")
    section("### 正式装配和候选入口", "洛阳场景 TRES 中的旧底图/布局会被正式运行包替换。新模块不能仅复制一张背景：同时核对布局、walk mask、对象脚底碰撞、遮挡、门户返脚与音频。带历史名称 candidate 的合同也可能已被正式入口采用，应以入口与当前记录共同判断。")
    entries = [
        ("AP统一八外场", "game/scripts/city/luoyang_full_city_index_20261022ap.gd", "已部署候选；当前入城/门户/艺术验收进展见current-progress，不授整城完成"),
        ("四街区预计算包", "game/scripts/city/luoyang_precomputed_bundle_index_20261018r.gd", "正式；四区 manifest 指向 layout_bundle_20261018t_retry2，各后继在下列入口叠加"),
        ("码头撤重复仓", "game/scripts/city/luoyang_docks_district08_index_20261019aa.gd", "正式 AA/AB"),
        ("码头装卸物件", "game/scripts/city/luoyang_docks_workyard_index_20261019ac.gd", "正式 AC"),
        ("码头NPC工种", "game/scripts/city/luoyang_docks_roles_index_20261019ad.gd", "正式 AD；3 carrier，共用一套同人视觉"),
        ("湿岸细节", "game/scripts/city/luoyang_docks_shore_index_20261020ae.gd", "正式 AE"),
        ("南市地面磨损", "game/scripts/city/luoyang_market_ground_index_20261020ae.gd", "正式 AE"),
        ("南市独立药/书门脸", "game/scripts/city/luoyang_market_two_shops_index_20261021ao.gd", "正式 AO"),
        ("南市完整药/书店与街坊后继", "game/scripts/city/luoyang_precomputed_bundle_20261018r.gd", "24b已写正式并实际可见；旧AO门脸被完整建筑替代，AO室内原生保留；非全城艺术验收"),
        ("南市43街坊（24e父层）", "game/build/luoyang_city_revision_20261024e_source01/runtime_ready03/market_block_session_READY.gd", "不可变父层由25g完整继承校验；原两列三层/6门返脚保留，当前直接运行入口为下列45院廊后继；非整城完成"),
        ("南市45街坊与两院檐廊（25g现役）", "game/build/luoyang_market_courtyard_links_20261025g_system01/runtime02_READY/market_courtyard_session_READY.gd", "已接正式C/DT/Field/G/ENV；两灰瓦四柱廊＋低前界、布架药台，原门NPC和25f材料不变。实际122888为77/0，两明确inspection后44px真INPUT、20Physics/局部人物ghost与一原图；仅两院连接，非全城密度或加载达标"),
        ("南市五用途地面（24e历史）", "game/build/luoyang_city_blocks_20261024e_system01/market_purpose_layer04_readable_profiles_NOTREADY.gd", "原profile04实际94260已过；当前ENV已由25f材料后继替代，原文件/来源叶保留，非当前有效材质入口"),
        ("南市街面材料层级（25f现役）", "game/build/luoyang_street_materials_20261025f_system01/material_revision02/market_purpose_layer_BUILD.gd", "正式ENV采用；主街.16、铺前.12转90°、服务巷.14与纹理沟肩、真实土院.10，仍6Sprite/3独立旧纹理。实际67044为55/0与单图，43建筑/NAV/门/NPC不变；只材料局部，不授全城密度或新加载性能"),
        ("码头两铺/北仓比例（24e）", "game/build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/runtime02_READY/docks_frontage_session_READY.gd", "已接正式C/DT/Field/G；两铺145px门/北仓西移116px，原29+DG10全导航。实际21392为114/0，三明确inspection后短INPUT及仓门同live返638610；仅局部比例/北图，非整区ART或连续旅行"),
        ("宅园与主厅", "game/scripts/city/luoyang_estate_index_20261021am.gd", "正式 AN（沿用AM目录名）"),
        ("十二室内目录", "game/scripts/city/luoyang_layout_room_index_20261018t.gd", "正式；由 Estate registry_source 返回包含 AN/AO 后继的注册表"),
        ("古寺拼装", "game/scripts/city/luoyang_temple_assembly_20261016.gd", "正式；组件目录 ancient_temple_assembled_20261016"),
        ("军士动作差异", "game/scripts/city/luoyang_military_presentation_index_20261019y.gd", "关闭；两版walk被拒"),
        ("军士静态差异", "game/scripts/city/luoyang_military_static_presentation_index_20261019y.gd", "旧y模块关闭；AP独立采用其中4静态图到5个固定NPC，非启用旧y整包；移动军士仍原walk"),
    ]
    entry_rows = []
    for name, path, status in entries:
        p = local(path)
        text = texts.get(p, "")
        flag = re.search(r'FORMAL_ENABLED\s*(?::=|=)\s*(true|false)', text)
        paths = list(dict.fromkeys(x for x in REF.findall(text) if x.endswith(".json")))
        entry_rows.append([name, file_cell(path), flag.group(1) if flag else "函数/上层控制", status, "<br>".join(file_cell(x) for x in paths[:5]) or "由脚本函数解析"])
    table(["模块", "控制入口", "启用常量", "当前使用情况", "入口内登记的清单"], entry_rows)
    section("### 当前十二室内引用", "当前启用宅园，室内注册表取 `game/data/maps/luoyang_estate_rooms_20261021am/registry.json`；AO 已将药/书两间的返回信息迁至 two_shops/rooms。以下从当前表读取，不从旧十一室内清单推定。")
    reg_path = GAME / "data/maps/luoyang_estate_rooms_20261021am/registry.json"
    registry = json.loads(texts.get(reg_path) or read(reg_path))
    room_rows = []
    for sid, row in sorted(registry.get("rooms", {}).items()):
        geo = row.get("geometry", {})
        room_rows.append([f"`{sid}`", file_cell(row.get("scene_path", "")), file_cell(row.get("layout_path", "")), "开启" if row.get("door_enabled") else "见门户控制", "<br>".join(file_cell(v) for v in geo.values() if isinstance(v, str) and v.startswith("res://")) or "见注册表 geometry"])
    table(["室内ID", "场景路径", "布局路径", "门户登记", "原生几何/包"], room_rows)
    # 25h limited adoption snapshot: manual status, never auto-promote from file existence.
    section("### 25h四室店主、商店与客栈服务（正式有限实测）", "本节只登记本轮四个服务身份；已随本轮精28来源闭包正式部署，原十二室内Scene/layout/native与室内几何不重编。parse03实际92432自然0/45检查0/1358ms；服务纯计划20例/28检查0保留。正式有限实测：shops_remaining02实际110632_2804自然0/294检查0/14973ms，inn_remaining02实际20988_2784自然0/351检查0/9581ms。剩余键只补未过组件，旧FAIL与前缀事实仍保留；不授全城ART、所有库存平衡或冷加载达标。")
    service_author25h = json.loads(read(local("res://build/luoyang_indoor_services_20261025h_system01/services_author05_CANDIDATE.json")))
    if service_author25h.get("fees") != {"meal": 5, "rest": 20} or len(service_author25h.get("rooms", {})) != 4:
        raise RuntimeError("25h service index snapshot mismatch; inspect the admitted author before updating index")
    service_rows25h = []
    service_labels25h = {"inn": "客栈掌柜（新增身份）", "pawn": "当铺掌柜（新增身份）", "herbal": "药铺药师（新增身份）", "smith": "原铁匠唯一ID（复用，不再加第二人）"}
    for service_sid25h, service_row25h in sorted(service_author25h["rooms"].items()):
        service_rows25h.append([
            service_labels25h[service_row25h["role"]] + "<br>\x60" + service_row25h["npc_id"] + "\x60",
            "\x60" + service_sid25h + "\x60<br>脚=" + str(service_row25h["foot"]) + "；接待=" + str(service_row25h["approach"]),
            file_cell(service_row25h["sprite_path"]),
            file_cell(service_row25h["portrait_path"]),
            "既有下向idle复用；3新身份＋原唯一smith已正式有限实测；未新增walk/同人动画",
        ])
    table(["服务身份 / NPC ID", "精确房间 / 作者脚", "复用场景精灵", "对话肖像", "采用边界"], service_rows25h)
    table(["本轮资源", "可直接引用路径", "状态与使用边界"], [
        ["当铺普通买卖", file_cell("res://data/shops/luoyang_services_20261025h/pawn.tres"), "12既有equipment SKU；现银买卖/原价，不提供借贷或当票；新ShopDef已由Root精复制并正式接线；ShopUI打开、关闭与返回通过；未执行实际买卖/库存经济平衡未验"],
        ["药铺买卖", file_cell("res://data/shops/luoyang_services_20261025h/herbal.tres"), "7既有item SKU；原价/原Inventory/ShopUI，库存资源未改；ShopUI打开、关闭与返回通过；未执行实际买卖/库存经济平衡未验"],
        ["铁匠买卖", file_cell("res://data/shops/luoyang_services_20261025h/smith.tres"), "16既有equipment SKU；原铁匠ID接服务，原价/原ShopUI；ShopUI打开、关闭与返回通过；未执行实际买卖/库存经济平衡未验"],
        ["客栈掌柜新专属肖像", file_cell("res://art/characters/portraits/luoyang_services_20261025h/portrait_innkeeper_v1.png"), "成熟蓝衣米围裙掌柜；1254²，Root看原图并唯一隔离4696/83检查0/全RGBA精同、2导入叶已晋升；不是旧generic vendor；已随本轮掌柜真实对白有限实测，不授所有复用角色的新同人美术信用"],
        ["四房作者与分房来源合同", file_cell("res://build/luoyang_indoor_services_20261025h_system01/services_author05_CANDIDATE.json"), "195固定普通叶；四scope加共享helper/author后8/91/74/104；其他8室不拉入商店SKU域；来源检查不替代原native/storage门禁"],
        ["服务事务 / 动态对白 / 失效清理", file_cell("res://build/luoyang_indoor_services_20261025h_system01/runtime_READY02/services_runtime_READY.gd"), "本轮正式有限实测；打尖5金/住宿20金；确认后重核当前全队Stats/金钱；请求一次消费，离室/战斗失效且只清自己dialog"],
        ["室内G与Field有限接点", file_cell("res://build/luoyang_indoor_services_20261025h_system01/runtime_READY02/G_READY.gd") + "<br>" + file_cell("res://build/luoyang_indoor_services_20261025h_system01/Field_services03_CANDIDATE.gd"), "G原flat/C自然来源接口保留，仅精4房额外FIRST/FINAL；原smith保持唯一，原3空室各加1人；新服务本轮正式有限实测通过，边界仅精4服务房"],
    ])
    lines.extend([
        "客栈打尖5金：全队生命/内力各按当前上限25%向下取整、至少1并clamp；住宿20金：全队hp/mp精确满值（同行hp0亦可恢复，战斗中不执行）。全队已满不扣钱，拒绝/不足金无副作用；同请求不二扣，合法新菜单可再请求。不调用refresh_derived，不改存档schema。",
        "局部ART限制：客栈快速连续测试时，黄色反馈文字在同位置叠加；未构成功能FAIL，但反馈排版尚未全通过。",
        "",
        "对白由helper运行时生成原生DialogScript，dialog_id按Field实例与菜单serial唯一；节点hero→menu→meal_confirm/rest_confirm→meal_commit/rest_commit，或menu→shop/leave。主角一句后显示真实店主肖像，不新增静态对白TRES或任何配音/音频；不能因新文本列为已配音。三商店继续原ShopUI，关闭后允许同房ID合法返脚但新Field owner；客栈本地服务必须同owner。",
        "",
    ])
    section("### 25h园林真河桥与茶楼（正式有限实测）", "本条来自Source固定作者/完成出版/binding并已随本轮精28正式部署，不从旧景观桥开support推定可走。Root已看overview52272/EE5FA；正式Garden实际98276_2756自然0/216检查0。只授本轮桥两岸/亭茶楼与有限Field检查，不授全园林/全城ART、冷加载达标或世界水桥完成。")
    garden_binding25h = json.loads(read(local("res://build/luoyang_garden_river_20261025h_source01/runtime02_READY/garden_river_binding_READY.json")))
    if len(garden_binding25h.get("required_sources", {})) != 46:
        raise RuntimeError("25h Garden required-source snapshot changed; update the manual limited entry first")
    table(["园林入口", "固定路径", "有限状态"], [
        ["作者", file_cell("res://build/luoyang_garden_river_20261025h_source01/author_river_bridge03_NOTREADY.json"), "北入水湾/南端止旧南路前，保原两portal；复用原石桥/亭、东岸两层茶楼，无新室内假门"],
        ["实际完成出版", file_cell("res://build/luoyang_garden_river_20261025h_source01/metadata_array04/ROOT_READY/reports/115844/result.json"), "strict source typed Scene/layout与packet出版完成；另有本轮216检查0有限Field实测，不将CPU出版泛称全程旅行"],
        ["Family候选", file_cell("res://build/luoyang_garden_river_20261025h_source01/runtime02_READY/Family_garden_river_READY.gd"), "已随本轮精28来源闭包正式部署；本索引只记录，不执行部署"],
        ["NativeGeometry视觉候选", file_cell("res://build/luoyang_garden_river_20261025h_source01/runtime01_NOTREADY/NativeGeometry_garden_river_CANDIDATE.gd"), "仅固定新Garden消费链；不拿旧景观桥/旧岸图作新通行信用"],
        ["绑定与完整46required", file_cell("res://build/luoyang_garden_river_20261025h_source01/runtime02_READY/garden_river_binding_READY.json"), "required_sources=46；56visual/16solid/2portal，精child工件路径见binding；本轮正式有限实测已过；原文件名NOTREADY/READY本身仍不等于采用证明"],
    ])
    section("### 场景资源逐项索引", "顶层为路由可查的作者配置，子目录为独立拼装/候选来源；两者都不自动等于当前实际画面。洛阳四区、宅园、室内请优先使用上方正式入口。音乐列给出 MusicCatalog 解析后的路径，保留原字段供核对。")
    music = texts[GAME / "scripts/audio/music_catalog.gd"]
    def block(name):
        m = re.search(r'const ' + name + r'\s*:=\s*([\[{])(.*?)[\]}]', music, re.S)
        return m.group(2) if m else ""
    track_ids = re.findall(r'&"([^"]+)"', block("TRACK_IDS"))
    scene_tracks = dict(re.findall(r'&"([^"]+)"\s*:\s*&"([^"]+)"', block("SCENE_TRACKS")))
    legacy = dict(re.findall(r'"(res://[^"]+)"\s*:\s*&"([^"]+)"', block("LEGACY_EXPLORATION_TRACKS")))
    day_ids = re.findall(r'&"([^"]+)"', block("LINXI_DAY_SCENES"))
    resolved_scenes = defaultdict(list)
    scene_rows = []
    for path, text in sorted(scenes.items()):
        sid = assignment(text, "scene_id") or path.stem
        bgm = assignment(text, "bgm_path")
        actual = "res://art/audio/bgm/wuxia_20261011/" + scene_tracks[sid] + ".wav" if sid in scene_tracks else ("res://art/audio/bgm/bgm_village_day_v4.wav" if sid in day_ids else ("res://art/audio/bgm/wuxia_20261011/" + legacy[bgm] + ".wav" if bgm in legacy else bgm))
        resolved_scenes[actual].append(sid)
        ext = dict(re.findall(r'\[ext_resource[^\n]*path="([^"]+)"[^\n]*id="([^"]+)"', text))
        id_to_path = {v: k for k, v in ext.items()}
        layout_m = re.search(r'(?m)^map_layout\s*=\s*ExtResource\("([^"]+)"\)', text)
        stream_m = re.search(r'(?m)^streamed_background\s*=\s*ExtResource\("([^"]+)"\)', text)
        bound = [file_cell(id_to_path[m.group(1)]) for m in [layout_m, stream_m] if m and m.group(1) in id_to_path]
        state = "顶层作者配置；可受运行包覆盖" if path.parent == GAME / "data/scenes" else "子目录拼装/候选；是否采用看正式入口"
        scene_rows.append([assignment(text, "display_name") + f"<br>`{sid}`", link(path), file_cell(assignment(text, "background_path")), "<br>".join(bound) or "—", file_cell(actual) + (f"<br>原字段 `{bgm}`" if bgm and bgm != actual else ""), state])
    table(["场景名称 / ID", "SceneScript", "背景/预览字段", "布局与分块集", "解析后音乐", "当前使用情况"], scene_rows)
    section("### 大型地图包与历史版本", "这些目录包含成千上万的分块、地表通道、原生纹理与捕获文件，按资源包登记。每个包的完整叶路径以其 source/art_contract/streamed 集登记为准；不要把整包的贴图当独立通用地砖。世界当前 TRES 指向 V15 V9C；旧 V6/V7/V8 作为历史/对照保留。")
    packs = []
    maps_root = GAME / "art/maps"
    for path in sorted(p for p in maps_root.iterdir() if p.is_dir()):
        counts = Counter(p.suffix for p in path.rglob("*") if p.is_file() and p.suffix not in {".import", ".uid"})
        state = "历史/候选目录；未据版本号认定采用"
        if path.name == "world_map_v15_complete_v9c": state = "当前世界场景 background/streamed 作者绑定；整包依赖原合同"
        elif path.name == "luoyang_modular_v3": state = "洛阳v3基础素材/几何来源；正式画面由后继组合"
        elif "proposal" in path.name: state = "提案候选，不能直接替换正式"
        packs.append([link(path), "、".join(f"{k or '无扩展名'} {v}" for k, v in counts.most_common(5)), state])
    table(["地图包路径", "非导入文件构成", "使用情况"], packs)
    section("### 背景与战斗底图明细")
    resource_table(backgrounds)
    section("## 地图组件明细", "按目录列出全部模块运行图，给出真实像素尺寸和静态消费者。组件复用要沿原 render_size_px/scale、脚锚、solid、Y深度和局部alpha方式；换到新地图后重新校核门净高与角色脚底净空。不要复用旧 map_layout 的坐标去配另一张图。")
    by_module = defaultdict(list)
    for path in modules:
        key = path.relative_to(GAME / "art/modules").parts[0]
        by_module[key if path.parent != GAME / "art/modules" else "根目录"].append(path)
    for group, paths in sorted(by_module.items()):
        section("### " + group)
        state = ""
        if group in {"luoyang_estate_components_20261021am", "luoyang_market_two_shops_20261021ao", "luoyang_shore_market_20261020ae"}:
            state = "已正式组件；新布局仍需重新验证"
        if group == "luoyang_market_space_20261024b":
            state = "24b完整商铺已正式可见；净门145，真实脚锚/碰撞/返回投影在固定binding；原图保留，用户许可仅外围弱alpha清理与补白。非整张可走背景。"
        if group.startswith("luoyang_gate_fortification_v"):
            state = "多代门楼素材；按实际正式入口择用，不能按最高版本直接替换"
        resource_table(paths, state)
    section("### 原生 Atlas 与地材资源", "这些是模块库中的原生资源文件，复用时保留纹理类型与区域定义，不把Atlas当整张PNG处理。")
    natives = files("game/art/modules", {".res", ".tres"})
    table(["原生资源", "当前引用"], [[link(p), use_cell(p)] for p in natives])
    section("### 生活物件的装配参数", "从现有 district_life 作者表读取贴图、源图脚锚与脚底实体。参数处于素材像素空间，世界脚位和缩放仍由每个placement决定；不能只带走PNG而遗漏碰撞/遮挡定义。")
    district = json.loads(texts[GAME / "data/maps/luoyang_district_life_20261016f/author.json"])
    asset_rows = []
    for aid, row in sorted(district.get("assets", {}).items()):
        placements = []
        for sid, spec in district.get("districts", {}).items():
            for obj in spec.get("placements", []):
                if obj.get("asset_id") == aid:
                    placements.append(f"`{sid}` / `{obj.get('id')}` / scale={obj.get('scale')}")
        asset_rows.append([f"`{aid}`", file_cell(row.get("texture", "")), str(row.get("source_ground_anchor_px", "见作者")), str(len(row.get("ground_solid_polygons_px", []))) + "个多边形", "<br>".join(placements[:4]) + (f"<br>共{len(placements)}处" if len(placements) > 4 else "")])
    table(["组件ID", "贴图", "素材脚锚px", "脚底实体", "现有作者使用位置与比例"], asset_rows)
    section("### 其他地图物件和导航素材")
    for base in ["game/art/props", "game/art/navigation_masks"]:
        section("#### " + base)
        resource_table(files(base, MEDIA))
    section("### 洛阳地图包中被引用的图像", "部分建筑、城墙、树、铺装与船存放在 art/maps，并不在 art/modules 中。以下列出本次源范围引用到的完整图像路径；其中 proposal 名称可能属于正式链的历史依赖，也可能是未采用提案，必须按消费者入口核对。其余捕获叶已按上方地图包目录归档。")
    map_images = sorted({local(key) for key in refs if key.startswith("res://art/maps/luoyang") and Path(key).suffix.lower() in MEDIA and local(key).is_file()})
    resource_table(map_images)
    section("## 音乐音效与配音")
    section("### 正式选曲与调用", "`AudioManager` 监听场景切换，调用 `MusicCatalog.scene_bgm(scene_id, legacy_path)`。目前认可库有23首循环，目录 `res://art/audio/bgm/wuxia_20261011/`。林西日间使用完整曲 `bgm_linxi_village_full_20261111.wav`；洛阳四个旧街区临时共用 `city_bianzhou.wav`，不能把文件名 city_luoyang 当作它们实际正在播放的曲目。")
    track_rows = [
        ["《破晓出关》", file_cell("res://art/audio/bgm/bgm_title_mountain_dawn_20261114.wav"),
         "开始界面", "正式使用；独立作曲，约90秒，整曲循环"],
        ["林西村日间完整曲", file_cell("res://art/audio/bgm/bgm_linxi_village_full_20261111.wav"),
         "林西日间场景", "正式使用；整曲循环"],
        ["《仗剑入江湖》", file_cell("res://art/audio/bgm/bgm_title_sword_journey_20261113.wav"),
         "原开始界面", "历史版本，保留供复用"],
    ]
    for tid in track_ids:
        p = GAME / f"art/audio/bgm/wuxia_20261011/{tid}.wav"
        users = sorted(set(resolved_scenes.get(res(p), [])))
        track_rows.append([f"`{tid}`", file_cell(res(p)), "、".join(f"`{x}`" for x in users) if users else "目录登记；对白/战斗/默认入口按对应调用选择", "认可库；场景/对白/战斗选择见 MusicCatalog"])
    table(["曲目ID", "运行路径", "场景静态解析结果", "当前使用情况"], track_rows)
    section("### 调用范例", "以下调用签名取自现有 AudioManager；场景常驻音乐优先填 `SceneScript.bgm_path`，环境底噪填 `ambience_path`。")
    lines.extend(['```gdscript', '# 单次音效', 'AudioManager.play_sfx("res://art/audio/free/sfx_blade_light_wuxia_v2.wav")', '# 指定BGM（默认会循环）', 'AudioManager.play_bgm("res://art/audio/bgm/wuxia_20261011/city_bianzhou.wav")', '# 环境循环，第二参为相对dB', 'AudioManager.play_ambience("res://art/audio/ambience/amb_rain_mountain_soft_v1.wav", -14.0)', '```', ''])
    section("### 战斗与UI音效选择", "技能可通过 cast_sfx_path / impact_sfx_path 显式覆盖；未显式填写时由战斗控制器按现有规则兜底。下列取自 AudioManager 常量，不代表暗器/短刃等所有武器已经具备独立音色。")
    am = texts[GAME / "scripts/autoload/audio_manager.gd"]
    cue_rows = []
    for name, path in re.findall(r'(?m)^const\s+([A-Z_]*(?:SFX|MUSIC))\s*:=\s*"(res://[^"]+)"', am):
        cue_rows.append([f"`{name}`", file_cell(path), "现有默认/武器分支；以实际调用参数为准"])
    table(["用途常量", "路径", "使用情况"], cue_rows)
    skill_rows = []
    for path, text in sorted(texts.items()):
        if path.parent != GAME / "data/skills": continue
        cast = assignment(text, "cast_sfx_path"); hit = assignment(text, "impact_sfx_path")
        if cast or hit:
            skill_rows.append([assignment(text, "display_name") + f"<br>`{path.stem}`", link(path), file_cell(cast), file_cell(hit)])
    table(["显式配音效技能", "数据入口", "施放", "命中"], skill_rows)
    section("### 工程内非对白音频全表", "包括现役、历史和测试文件。显式记录的消费者可以定位，但旧BGM可能已经被 MusicCatalog 重定向。")
    rows = []
    for path in audio:
        if path.is_relative_to(GAME / "art/audio/voices"):
            continue
        inventoried.add(path)
        state = "引用见末列；旧版不自动视为现役"
        if path.parent.name == "wuxia_20261011": state = "认可循环库"
        if "test" in path.stem: state = "测试音；新内容勿选"
        rows.append([link(path), f"{path.stat().st_size / 1024:.1f} KiB", state, use_cell(path)])
    table(["完整音频路径", "大小", "状态", "消费者"], rows)
    section("### 对白配音全路径", "声音由 DialogPlayer 按节点动态拼接。基本目录为 `res://art/audio/voices/<dialog_id前3字符>/<dialog_id>/`；先试 `<speaker>_<node>_seg01_dialog.mp3` 等分段，再试 `<speaker>_<node>_e<emotion>.mp3`，最后普通 `<speaker>_<node>.mp3`；括号旁白另有 `_narr.mp3`。实际分段顺序需和正文一致。以下每一行列出实际文件，不把目录存在当作整段已配齐。")
    audit_path = ROOT / "assets/processed/audio/wuxia_expansion_qa_20261022/inventory_retry1.json"
    selected_voice: set[str] = set()
    if audit_path.is_file():
        audit = json.loads(read(audit_path))
        for row in audit.get("dialog_nodes", []):
            selected_voice.update(v.replace("\\", "/") for v in row.get("selected_disk_files", []))
        lines.extend([f"现有专用音频审计见 {link(audit_path)}；它会区分完整分段与缺配节点。该审计是当时的静态快照，以下文件表重新扫描当前磁盘。", ""])
    voice_groups = defaultdict(list)
    for path in audio:
        if path.is_relative_to(GAME / "art/audio/voices"):
            voice_groups[path.parent].append(path)
    for parent, paths in sorted(voice_groups.items()):
        section("#### " + parent.relative_to(GAME / "art/audio/voices").as_posix())
        table(["完整配音路径", "当前使用情况"], [[link(p), "已有专用审计静态选中；受当前节点/情绪/分段条件控制" if rel(p) in selected_voice else "现有声音；旧专用审计未选中或需运行上下文，不判废弃"] for p in paths])
        inventoried.update(paths)
    section("### 10月22日新增音频候选", "以下只列本次扫描已落盘的可播放文件，生成中的计划不计入成品；都位于 assets/processed，尚未正式安装到 game/art/audio。试听通过与正式接线需分别确认；原音频与场景字段不因这份文档改变。")
    for base in ["assets/processed/audio/wuxia_expansion_20261022", "assets/processed/audio/wuxia_voice_sfx_expansion_20261022"]:
        paths = files(base, AUDIO)
        section("#### " + base, f"本次快照可播放文件数：{len(paths)}。")
        table(["候选路径", "当前使用情况"], [[link(p), "试听/生成候选；未正式接入"] for p in paths])
    section("## NPC 精灵与立绘")
    section("### 读取优先级与复用方法", "探索角色由 `NPCNode` 加载 sprite_path / walk_sprite_path。横向等格条通常以宽÷高决定 hframes；表中的像素尺寸只描述文件，不证明真步态、四方向或循环质量。1f idle 可以静止使用，不能当行走图。portrait_path 为对话立绘/头像，不能当场景行走精灵。")
    section("### 24b主角开场与生活对话、24c书生肖像", "Field当前接入npc_conversation_CANDIDATE.gd：真实NPC交互先显示主角立绘，再切实际说话人。仅精确认证的零副作用日常菜单改为直说，任务/交易/文化话题保留选择。菜贩两次实际对话已见正确女性立绘、家常与有归属的不可靠传闻；24c南市书生已接入白袍抱书角色匹配的专属立绘，实际51180检查35/0，主角开场→书生菜单TextureRect真实可见→离开。新文本及新立绘均没有新配音，不能称全部NPC媒体已改。")
    table(["采用组件", "路径", "边界"], [
        ["交互开场/六条传闻", file_cell("res://build/luoyang_city_revision_20261024b_dialog01/npc_conversation_CANDIDATE.gd"), "已由正式Field调用；无保存/任务奖励改动，不是DP全局替换。"],
        ["菜贩实际对话立绘", file_cell("res://art/characters/portraits/street_expansion_v1/portrait_vegetable_seller_v1.png"), "复用既有女性立绘；精灵family匹配，24b实际TextureRect可见。"],
        ["南市书生专属立绘（24c）", file_cell("res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png"), "原图EBD60B64无裁切/改色；正式Field按场景+ID绑定，主角开场后显示本人。不是通用脸或新配音。"],
    ])
    lines.extend(["场景 `npcs` 还会经过洛阳Task/生活角色投影，再按 scene_id 匹配 `npc_catalog.tres`，并经过Field专用处理及文化话题包装；原TRES对白ID不一定是最终runtime primary。地面锚定的 harbour/district 生活NPC会避开通用catalog覆盖。仅查场景TRES不完整。对话节点自身 portrait_path 优先，随后才考虑交互NPC及角色默认头像。", "", "复用角色时同时取同人 idle、walk、portrait 与 conversation_sprite_paths。新身份沿项目设计另行确认，勿只改名字借用重要角色立绘。当前码头3名carrier共用 strong_carrier 视觉；旧y军士模块仍关闭，但AP独立采用4静态图覆盖5个固定军士，移动军士walk尚未改造。", ""])
    table(["用途", "入口"], [["NPC注册覆盖", file_cell("res://data/npcs/npc_catalog.tres")], ["精灵与动画加载", file_cell("res://scripts/field/npc_node.gd")], ["NPC装配与兜底肖像", file_cell("res://scripts/field/field_walkable_controller.gd")], ["对白节点肖像与声音", file_cell("res://scripts/autoload/dialog_player.gd")], ["码头身份替换", file_cell("res://scripts/city/luoyang_docks_roles_20261019ad.gd")]])
    section("### AP62书生与百工生活组件采用边界", "2026-10-24最小接线及64来源分类修复已写正式。65南市默认可动首绘11.384491秒（未达10秒），书生新图/成年比例/脚位/原体尺已实际加载；该轮旧对白ID期待FAIL保。66仅正确Task primary+相机图35项零失败，原相机恢复且Player/游戏状态不变，退出C0000005仍非clean，不能标全轮通过。百工原生136/31已实际加载，长凳静止帧114像素仅人物ghost已见；两个整体FAIL保留并停止再测。不授整城验收。")
    table(["组件", "完整运行路径", "消费者与当前状态"], [
        ["抱书书生单帧", file_cell("res://art/characters/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png"), "Field exact南市/luoyang_paper_scholar覆盖；140×.82成年校准、原body/脚已实际加载。Task投影后的主对白为luoyang_city_tasks_20261016/paper_offer，文化包装保留它；不是新walk、立绘或配音。"],
        ["洗布盆（复用淬水盆）", file_cell("res://art/modules/luoyang_assembled_20261016b/quench_tub_v1.png"), "百工两盆固定脚位/scale.085，完整源图复用；实际碰撞与仅人物局部ghost通过，物件不淡化。"],
        ["井边茶桌", file_cell("res://art/modules/luoyang_assembled_interiors_20261016g/dining_table_v1.png"), "百工独立低物件/scale.12；实际真INPUT正逆与仅人物局部ghost通过。"],
        ["井边长凳", file_cell("res://art/modules/luoyang_assembled_interiors_20261016g/long_bench_v1.png"), "百工独立低物件/scale.12；身份/碰撞/forward通过，静止帧114像素仅人物ghost、物件alpha1。两个整体测试FAIL保留，未执行的逆路不授通过；停止该项再测。"],
    ])
    ap_npc_author = local("res://build/luoyang_city_full_rollout_20261022ap_npc01/author.json")
    if ap_npc_author.is_file():
        ap_npc = json.loads(read(ap_npc_author))
        section("### AP独立静态外观覆盖", "下列7项是AP后置配置，不等于启用旧y模块或移动动画改造。四种军士静态图用于5个固定NPC，另修2名候检旅人。部分portrait仍借用整身精灵，不能视为专属立绘已完成；实际各区显示验收见current-progress。")
        table(["场景 / NPC", "覆盖Idle", "覆盖Portrait", "边界"], [
            [r["scene_id"] + " / " + r["npc_id"], file_cell(r["patch"].get("sprite_path", "")), file_cell(r["patch"].get("portrait_path", "")), "只静态外观；原body/脚/任务与移动军士walk不改"]
            for r in ap_npc["visual_rows"]])
    section("### 中央 NPC 绑定", "这里按完整profile逐条列出；scene_ids 限定同ID在哪些场景生效。空portrait表示由场景/对白/Field兜底，不擅自填成专属头像。")
    catalog_text = texts[GAME / "data/npcs/npc_catalog.tres"]
    profile_rows = []
    for item in re.findall(r'\[sub_resource[^\n]*\]\n(.*?)(?=\n\[|\Z)', catalog_text, re.S):
        nid = assignment(item, "npc_id")
        if not nid: continue
        scope = re.search(r'(?m)^scene_ids\s*=\s*(.*)', item)
        profile_rows.append([assignment(item, "display_name") + f"<br>`{nid}`", scope.group(1) if scope else "全部场景", file_cell(assignment(item, "sprite_path")), file_cell(assignment(item, "walk_sprite_path")), file_cell(assignment(item, "portrait_path")), assignment(item, "movement_mode") or "idle"])
    table(["NPC", "生效场景", "Idle", "Walk", "立绘", "移动模式"], profile_rows)
    section("### 洛阳动态生活NPC与正式覆盖", "这里补充场景TRES里没有的生活NPC。district_life读取作者crowd；harbour_life按代码spec投影；码头两岗位随后由office替换；三carrier由AD覆盖。表中明确区分历史基础绑定与已知后置覆盖；AP部署还会叠加自身NPC与静态差异，实际当前显示须沿AP清单核对，不能将本表视为完整最终角色投影或整城验收。")
    dc = texts[GAME / "scripts/city/luoyang_district_life_crowd_20261016f.gd"]
    hc = texts[GAME / "scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd"]
    def constants(text):
        return dict(re.findall(r'(?m)^const\s+(\w+)\s*(?::=|=)\s*"(res://[^"]+)"', text))
    dconst = constants(dc); hconst = constants(hc)
    family_keys = {"merchant": "MERCHANT_IDLE", "guard": "GUARD_IDLE", "farmer": "FARMER", "waiter": "WAITER", "vendor": "VENDOR"}
    dynamic_rows = []
    for sid, spec in sorted(district.get("districts", {}).items()):
        for row in spec.get("crowd", []):
            family = row.get("family", "")
            idle = dconst.get(family_keys.get(family, ""), "")
            moving = row.get("distance_px", 0) > 0
            walk = dconst.get("GUARD_WALK" if family == "guard" else "MERCHANT_WALK", "") if moving else ""
            dynamic_rows.append([f"`{sid}`", row.get("name", "") + f"<br>`district_life_{row.get('id', '')}`", file_cell(idle), file_cell(walk), "Field按ID兜底", "district_life 基础绑定；不套通用catalog"])
    ad = json.loads(texts[GAME / "data/luoyang_docks_roles_20261019ad/manifest.json"])
    ad_roles = {row["npc_id"]: row["patch"] for row in ad.get("roles", [])}
    office = json.loads(texts[GAME / "data/maps/luoyang_docks_office_20261016h/author.json"])
    office_roles = {nid: {"sprite_path": value["texture"]} for nid, value in office.get("roles", {}).items()}
    def generic_portrait(nid):
        # Exact current Field fallback: ID only, not display name or guessed sex.
        value = nid.lower()
        family = "young_man"
        if any(token in value for token in ["woman", "妇", "guest"]): family = "young_woman"
        elif any(token in value for token in ["old", "elder", "keeper", "掌柜"]): family = "older_man"
        elif any(token in value for token in ["vendor", "wife"]): family = "older_woman"
        return "res://art/characters/portraits/generic/portrait_generic_" + family + "_v1.png"
    for row in dynamic_rows:
        nid = re.search(r'`([^`]+)`', row[1]).group(1)
        row[4] = file_cell(generic_portrait(nid)) + "<br>Field按ID兜底"
    for branch, sid in [(0, "ch4_s0_luoyang_gate"), (1, "ch4_s2_canal_docks")]:
        m = re.search(r'if id==A.IDS\[' + str(branch) + r'\]: return \[(.*?)(?=\n\tif |\n\treturn \[\])', hc, re.S)
        stationary = 0
        for rid, name, x, y, distance, moving, guard in re.findall(r'\["([^"]+)","([^"]+)",\[([\d.]+),([\d.]+)\],([\d.]+),(true|false),(true|false)\]', m.group(1) if m else ""):
            nid = "harbour_life_" + rid
            idle = hconst["GUARD_IDLE" if guard == "true" else "MERCHANT_IDLE"]
            if moving == "false" and guard == "false":
                idle = hconst["FARMER" if stationary % 2 == 0 else "WAITER"]; stationary += 1
            walk = hconst["GUARD_WALK" if guard == "true" else "MERCHANT_WALK"] if moving == "true" else ""
            patch = ad_roles.get(nid) or office_roles.get(nid) or {}
            idle = patch.get("sprite_path", idle); walk = patch.get("walk_sprite_path", walk)
            portrait = patch.get("portrait_path", "")
            state = "AD正式覆盖；同人1idle+4walk+portrait" if nid in ad_roles else ("office正式岗位覆盖" if nid in office_roles else "harbour基础绑定；Field按ID兜底肖像")
            dynamic_rows.append([f"`{sid}`", name + f"<br>`{nid}`", file_cell(idle), file_cell(walk), file_cell(portrait) if portrait else file_cell(generic_portrait(nid)) + "<br>Field按ID兜底", state])
    table(["场景", "动态NPC", "Idle", "Walk", "立绘", "当前使用情况"], dynamic_rows)
    section("### 场景作者 NPC 绑定", "列场景原始绑定，不冒充运行时最终角色：catalog、Field专用覆盖、洛阳crowd/AD以及剧情切换仍可能覆盖。可由NPC ID反查角色位置，再在后面的图像表查同人资源。")
    npc_rows = []
    for path, text in sorted(scenes.items()):
        sid = assignment(text, "scene_id") or path.stem
        # Balanced dictionary extraction keeps nested conversation paths intact.
        marker = re.search(r'(?m)^npcs\s*=', text)
        if not marker: continue
        tail = text[marker.end():]
        end = re.search(r'\n[a-zA-Z_]\w*\s*=', tail)
        tail = tail[:end.start()] if end else tail
        depth = 0; start = -1; quoted = False; escaped = False
        blocks = []
        for i, ch in enumerate(tail):
            if quoted:
                if escaped: escaped = False
                elif ch == "\\": escaped = True
                elif ch == '"': quoted = False
            elif ch == '"': quoted = True
            elif ch == "{":
                if depth == 0: start = i
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0: blocks.append(tail[start:i+1])
        for item in blocks:
            def val(key):
                m = re.search(r'"' + key + r'"\s*:\s*&?"([^"\n]*)"', item)
                return m.group(1) if m else ""
            if not val("npc_id"): continue
            npc_rows.append([f"`{sid}`<br>{link(path)}", val("npc_name") + f"<br>`{val('npc_id')}`", file_cell(val("sprite_path")), file_cell(val("walk_sprite_path")), file_cell(val("portrait_path")), "`" + val("dialog_id") + "`" if val("dialog_id") else "无显式对白ID"])
    table(["来源场景", "NPC名称 / ID", "配置Idle", "配置Walk", "配置立绘", "对白"], npc_rows)
    section("### 图像库存与当前引用", "此表覆盖 characters 全部图像，保留旧版与候选。主角 weapon_variants/walk_frames 属玩家资源，单独列在末尾，避免当NPC公用素材。未检出字面引用的方向图仍可能被方向文件名规则加载。")
    char_groups = defaultdict(list)
    for path in chars:
        parts = path.relative_to(GAME / "art/characters").parts
        group = parts[0] if len(parts) > 1 else ("根目录立绘" if "portrait" in path.name else "根目录精灵与角色")
        char_groups[group].append(path)
    for group, paths in sorted(char_groups.items()):
        section("#### " + group)
        resource_table(paths)
    section("### 战斗角色动作库", "探索NPC的idle/walk与战斗 ready/attack/hit/defeat 分开。下表按动作文件的所在目录分组，列出全部图像文件名；完整路径=该行目录+文件名。敌人实际使用的动作以 `game/data/enemies/*.tres` 中 battle_actor_path/attack_frame_paths/hit_frame_paths/defeat_frame_paths 为准，不按目录最新版本猜测。")
    battle_groups = defaultdict(list)
    for path in battle:
        battle_groups[path.parent].append(path)
        inventoried.add(path)
    table(["目录路径", "实际文件名（拼接目录得到完整路径）", "静态引用文件数"], [[link(parent), "<br>".join(f"`{p.name}`" for p in paths), str(sum(bool(refs[res(p)]) for p in paths)) + "/" + str(len(paths))] for parent, paths in sorted(battle_groups.items())])
    section("## 原图与候选库", "新模块实际引用优先使用 game 内运行版。assets/raw 是不可覆盖的来源，assets/processed 是处理/试听/候选产物，build 也有正式运行依赖与历史失败证据，不能按目录名批量清理或搬迁。本次仅建索引，所有原路径保留。")
    raw_groups = ["assets/raw/scene", "assets/raw/scene_background", "assets/raw/scene_module", "assets/raw/scene_prop", "assets/raw/character", "assets/raw/character_portrait", "assets/raw/sprite", "assets/raw/sprite_sheet", "assets/raw/audio", "assets/raw/luoyang_city_full_rollout_20261022ap", "assets/raw/luoyang_soldier_diversity_20261019y", "assets/raw/luoyang_resident_life_20261019v", "assets/raw/luoyang_market_two_shops_20261021ao", "assets/raw/luoyang_estate_components_20261021aj", "assets/raw/luoyang_estate_courtyard_20261021am", "assets/raw/luoyang_city_space_20261024b"]
    table(["原始库路径", "当前使用情况"], [[link(p), "AP原始来源；部分后继已随候选部署，逐图采用/许可状态见AP专题，不授整个目录正式可用" if "20261022ap" in p else "生成原图/来源；不把原图目录整体视为合格或正式运行素材"] for p in raw_groups if local(p).is_dir()])
    section("### AP已落盘派生图候选", "仅登记处理库路径和文件尺寸；出现clean/padded文件名不代表正式准入，也不改变原图许可或AP启用状态。")
    base = "assets/processed/luoyang_city_full_rollout_20261022ap"
    if local(base).is_dir():
        table(["候选图路径", "尺寸", "使用情况"], [[link(p), image_size(p), "AP派生来源；候选部署的逐图采用须核AP清单，未授整个目录运行合格"] for p in files(base, MEDIA)])
    other_manifest = local("assets/raw/other_city_modules_20261022/manifest.json")
    if other_manifest.is_file():
        other = json.loads(other_manifest.read_text("utf-8"))
        section("### 其他城镇首批模块素材", "汴州、金陵、襄州、清河、雁门与通用候选，按城镇/类别存放。下表来源是设计依据，不是当前游戏消费者；全部未导入、未正式绑定。单帧精灵或战斗待机不代表动画完成。完整alpha留白失败仍保留，不因进入索引晋升。")
        lines.extend(["制作方案与接入待办见 [其他城镇模块素材](other-city-modules-plan-20261022.md)，图鉴中可筛选“新增候选 / 其他城镇”。", ""])
        table(["素材 / 类别", "完整路径", "尺寸", "当前使用情况", "设计依据 / 参考"], [
            [r["label"] + "<br>" + r["city"] + " / " + r["kind"], file_cell(r["output"]), image_size(local(r["output"])),
             "候选；未接入；" + ("完整alpha留白≥10%" if r.get("metrics", {}).get("margin_10_percent_pass") else "完整alpha留白不足10%"),
             "<br>".join(file_cell(p) for p in r["sources"]) + ("<br>同人参考：" + file_cell(r["reference_input"]["path"]) if r.get("reference_input") else "")]
            for r in other["assets"] if local(r["output"]).is_file()])
    world_manifest = local("assets/raw/world_expansion_100_20261022/manifest.json")
    if world_manifest.is_file():
        world = json.loads(world_manifest.read_text("utf-8"))
        generated = [r for r in world["assets"] if local(r["output"]).is_file()]
        generated, rejected = select_assets(ROOT, generated)
        section("### 百图扩充：建筑、道具、NPC与分级敌人", "本批计划新增100张，以下仅列实际落盘图。普通/精英/剧情Boss分开；精英是野外练级高品质怪物，Boss沿现有剧情定义。动物视觉储备不等于已增加遭遇或剧情动物Boss。全部为未导入候选，单帧不证明动画。")
        lines.extend([f"当前主体候选 {len(generated)}/100；另保留 {len(rejected)} 张弃用历史原稿。完整清单见 [百图扩充方案](world-expansion-100-20261022.md) 和 [当前选择清单](../assets/raw/world_expansion_100_20261022/current-candidates.json)。图鉴搜索“百图扩充”可按类别、物种和分级查看缩略图。", ""])
        table(["素材", "类别 / 分级", "完整路径", "尺寸", "当前使用情况", "设计依据 / 身份参考"], [
            [r["label"], r["kind"] + " / " + (r["tier"] or r["city"]), file_cell(r["output"]), image_size(local(r["output"])),
             "未接入；" + ("完整alpha留白≥10%，仍待用途验收" if r.get("metrics", {}).get("margin_10_percent_pass") else "完整alpha留白未达10%"),
             "<br>".join(file_cell(p) for p in r["sources"]) + ("<br>身份参考：" + file_cell(r["reference_input"]["path"]) if r.get("reference_input") else "")]
            for r in generated])
        if rejected:
            lines.extend(["弃用稿只供追溯，不能作为可引用候选：", ""])
            table(["弃用原稿", "完整路径", "原因 / 当前替代"], [
                [r["label"], file_cell(r["output"]), "误添长剑，违反薛影空手设定；当前替代：" + file_cell(next(n["output"] for n in generated if n["id"] == r["superseded_by"]))]
                for r in rejected])
    placewalk_path = local("assets/raw/world_placeables_walk_20261022/current-candidates.json")
    if placewalk_path.is_file():
        pack = json.loads(placewalk_path.read_text("utf-8"))
        section("### 地图行走精灵与场景可放置补充", "明确区分背包物件外观和地图实体：本批24个可放置组件（8生活摆件、8野外物件、8小建筑）；10名既有NPC另制每人4张独立原生行走帧，配套待机沿上一批。不是立绘，也不代表四向或运行atlas完成。")
        lines.extend(["当前64张PNG＝24物件＋40行走帧；另留8张相位失败原稿。动画有原始播放和缩放/平移对齐查看两版，后者不是规范化运行资源，也不替代完整A>0留白检查。完整说明见 [本批README](../assets/raw/world_placeables_walk_20261022/README.md)。", ""])
        table(["地图可放置物件", "用途", "完整路径", "尺寸", "当前使用情况"], [
            [r["label"], r["intended_use"], file_cell(r["output"]), image_size(local(r["output"])), "未接入；尺度/接触脚/碰撞/互动待验"]
            for r in pack["assets"] if r["kind"] != "npc_walk_frames"])
        table(["NPC地图行走", "配套待机", "4张原生帧（顺序1→4）", "查看动画", "当前使用情况"], [
            [f["family"], file_cell(f["idle_path"]), "<br>".join(file_cell(p) for p in f["frames"]),
             "对齐查看：" + file_cell(f["aligned_preview"]) + "<br>原始：" + file_cell(f["raw_preview"]),
             "下行候选；原图有尺度/脚位漂移，未合格运行atlas/未接入；相位结论看walk-review"]
            for f in pack["families"]])
        table(["相位失败原稿（不推荐引用）", "完整路径", "原因"], [
            [r["label"], file_cell(r["output"]), "两相重复或逐帧仍同脚在前；原图保留，当前用姿态参照版独立帧"]
            for r in pack["history"]])
    design_manifest = local("assets/raw/sect_western_map_designs_20261022d/manifest.json")
    if design_manifest.is_file():
        designs = json.loads(read(design_manifest))["items"].values()
        section("### 武当、茗雾与西域城镇整体设计", "本批4张内置原生总览中，2026-10-23用户已选赤岩开始制作，其他3张仍待审阅；均未接入游戏，不能当可走背景、拆分模块或NPC动画。西域两镇为设计暂名，未新增正式场景/剧情。")
        lines.extend(["分区、风格差异、建筑/场景物件/地图精灵与立绘后续制作清单见 [门派与西域地图设计](sect-western-map-designs-20261022d.md)。图鉴新增“地图设计图”类别，缩略图可沿既有放大入口查看原图。", ""])
        table(["设计", "原图完整路径", "尺寸", "当前使用情况", "提示词"], [
            [r["name"], file_cell(r["output"]), image_size(local(r["output"])), "已选制作方向；入口资源候选另列，未接入" if r["id"].startswith("redrock_") else "设计提案待审；未拆件/未接入", file_cell(r["prompt"])]
            for r in designs if r.get("output")])
    desert_design_manifest = local("assets/raw/desert_town_design_20261029c/manifest.json")
    if desert_design_manifest.is_file():
        designs = json.loads(read(desert_design_manifest))["items"].values()
        section("### 独立沙漠商城总规（2026-10-29c）", "用户明确区分赤岩与另一座沙漠城市后新作。29d用户已确认按此总规创建六区独立编辑地图；此设计原图仍0直接游戏消费者，不创建正式地图ID或以总览充可走背景。")
        lines.extend(["[六区设计、差异与后续模块清单](desert-town-design-20261029c.md)。", ""])
        table(["设计", "原PNG", "尺寸", "使用情况"], [[r["name"],file_cell(r["output"]),image_size(local(r["output"])),"内置生成1次；原像素保持；用户已确认制作方向"] for r in designs if r.get("output")])
    miao_design_manifest = local("assets/raw/miao_town_design_20261029e/manifest.json")
    if miao_design_manifest.is_file():
        designs=json.loads(read(miao_design_manifest))["items"].values()
        section("### 苗族风情山城总规（2026-10-29e）", "原创山地木构城市总规：山口寨门、临溪街市、芦笙坪、蜡染绣坊、吊脚民巷、梯田粮院。雷山吊脚楼与蜡染/芦笙官方非遗资料作建筑及生活参考，不冒现实某寨复刻。29f用户已确认并创建独立六区编辑地图；此原生RGB总规不修改，仍0直接游戏消费者，正式地点ID未创建。")
        lines.extend(["[设计图、分区模块清单与文化来源](miao-town-design-20261029e.md)；[图鉴缩略与点击放大](equipment-skill-catalog.html#resources)。", ""])
        table(["设计","原PNG完整路径","尺寸","当前使用","完整提示词"],[[r["name"],file_cell(r["output"]),image_size(local(r["output"])),"用户已确认制作方向；另制原生组件，不直接用作游戏贴图",file_cell(r["prompt"])] for r in designs if r.get("output")])
    redrock_path = local("assets/raw/redrock_gate_resources_20261023a/resource-pack.json")
    if redrock_path.is_file():
        pack = json.loads(read(redrock_path))
        section("### 赤岩关镇01峡口关门首批资源", "用户已选赤岩总览为制作方向。13张原图=12当前候选（4建筑/墙体、2地图实体、1待机、4下行帧、1同人立绘）+1门洞不足首稿。全部未接入；完整alpha留白失败，行走有脚位漂移，不能直接当合格运行atlas。")
        lines.extend(["平面、原图、动画查看与限制见 [赤岩首批制作记录](redrock-gate-resources-20261023a.md)。", ""])
        table(["素材 / 类别", "完整路径", "尺寸", "当前使用情况", "配套参考"], [
            [r["label"] + "<br>" + r["kind"], file_cell(r["output"]), image_size(local(r["output"])),
             ("首稿保留，不推荐复用；" if r.get("rejected") else "候选未接入；") + r["review_note"],
             file_cell(r["reference"]) + ("<br>原始动画：" + file_cell(r["animation_preview"]) if r.get("animation_preview") else "")]
            for r in pack["assets"]])
    redrock_ground_path = local("assets/raw/redrock_ground_resources_20261023b/resource-pack.json")
    if redrock_ground_path.is_file():
        pack = json.loads(read(redrock_ground_path))
        section("### 赤岩关口地表、坡道与脚锚修订", "本轮新增5张原生候选：2不透明地表、坡道、护栏、第4行走帧修版；任务登记在独立art工作区，不改工程根tasks或操作洛阳进程。此5图未纳入后续旧12图的本地处理许可，原限制保留。")
        lines.extend(["来源、使用状态和并行边界见 [赤岩地面与并行推进](redrock-ground-parallel-20261023b.md)。", ""])
        table(["素材", "完整路径", "尺寸", "当前使用情况"], [[r["label"], file_cell(r["output"]), image_size(local(r["output"])), "未接入；" + r["review_note"]] for r in pack["assets"]])
    redrock_derived_path = local("assets/processed/redrock_gate_20261023b/resource-pack.json")
    if redrock_derived_path.is_file():
        pack = json.loads(read(redrock_derived_path))
        section("### 赤岩12张用户授权透明留白派生", "用户已明确允许精确处理，12原图保留；仅补透明画布，另只清理关门声明矩形内352个alpha1–3。12派生完整A1留白≥10%，不改变步态/门底形制、碰撞或正式采用状态。后续组件适配可优先查看这些派生及其source_offset，不能重新fit全画布缩小主体。")
        lines.extend(["处理与105项独立核验见 [赤岩授权本地处理](redrock-local-processing-20261023b.md)。", ""])
        table(["素材", "派生路径", "原图来源", "尺寸", "当前使用情况"], [
            [r["label"], file_cell(r["output"]), file_cell(r["source"]), image_size(local(r["output"])), r["review_note"]]
            for r in pack["assets"]])
    redrock_editor_path = local("game/art/modules/redrock_gate_20261023c/resource-pack.json")
    if redrock_editor_path.is_file():
        pack = json.loads(read(redrock_editor_path))
        section("### 赤岩峡口：已写入编辑器工程的首段草案", "2026-10-23新增独立原生节点Scene，9图工程副本与来源字节一致。可打开下列场景/F6预览；关门、厚墙、岗楼、饮水/候检和匿名待机精灵有原生碰撞及角色通行检查。仅编辑草案，未加入世界路由；峡壁、层台街坊和稳定行走尚待补齐。")
        rejected = pack.get("status") == "USER_REJECTED_ASSEMBLY_NOT_A_DESIGN_BASELINE"
        if rejected:
            lines.extend(["**当前结论：用户否定该装配，关墙/岗楼没有正确连接；本节旧Scene和测试仅留追溯，不是继续制作的设计基线。** 新提案见[峡口连接重设计](redrock-gate-redesign-20261023d.md)。", ""])
        lines.extend(["场景：" + file_cell(pack["scene"]) + "；[制作与核验记录](redrock-editor-gate-20261023c.md)。", ""])
        table(["素材", "工程引用路径", "来源PNG", "当前消费者与状态"], [[r["label"], file_cell(r["output"]), file_cell(r["source"]), pack["scene"] + ("；用户否定旧布局，保留追溯" if rejected else "；已装配编辑草案，未正式接入")] for r in pack["assets"]])
    redesign_path = local("assets/raw/redrock_gate_redesign_20261023d/resource-pack.json")
    if redesign_path.is_file():
        pack = json.loads(read(redesign_path))
        approved=pack.get("status")=="DESIGN_DIRECTION_APPROVED_FOR_COMPONENT_TRIAL"
        section("### 赤岩峡口：连体关防重设计提案", "旧c版墙体连接已被用户否定。新图定义峡壁—墙—岗楼—门关连续关系、内侧折返与路侧作业凹位；"+("用户已确认设计方向，进入e版三块结构试拼。" if approved else "仍待用户审阅。")+"不是可走底图，不直接裁图当组件。")
        table(["设计", "原生图完整路径", "尺寸", "使用状态"], [[r["label"], file_cell(r["output"]), image_size(local(r["output"])), "已确认设计方向，三块试拼中" if approved else "整体重设计提案，未覆盖旧Scene/未拆件"] for r in pack["assets"]])
    trial_path=local("assets/raw/redrock_joint_trial_20261023e/resource-pack.json")
    if trial_path.is_file():
        pack=json.loads(read(trial_path))
        section("### 赤岩三块关防结构试拼", "连体核心＋左墙翼岩肩＋右转墙翼岩肩，原图由隔离Scene只读加载为ImageTexture。34项原生检查/1558运动采样通过，门洞与两处墙面接缝有实际图；留白/完整五锚点/墙道光影仍待。未正式导入game。")
        lines.extend(["实际Scene："+file_cell("assets/staging/redrock_joint_trial_20261023e/trial_project/trial.tscn")+"；[试拼记录](redrock-joint-trial-20261023e.md)。",""])
        table(["模块","原PNG路径","尺寸","消费者与当前状态"],[[r["label"],file_cell(r["output"]),image_size(local(r["output"])),"隔离trial_project/trial.tscn；原图试拼，完整A1留白FAIL，未正式接入"] for r in pack["assets"]])
    joint_editor=local("game/art/modules/redrock_joint_editor_20261023f/resource-pack.json")
    if joint_editor.is_file():
        pack=json.loads(read(joint_editor))
        section("### 赤岩连体关防：授权留白后已接入工程的结构草案", "用户明确允许本批3图仅透明扩画布，3原图全部RGBA保持；核心2282×1141、两翼1976×1318，完整A1边距通过。新独立原生Scene可在主工程打开/F6，67项隔离检查/1558motion、5图导入RGBA精确。仅结构编辑草案，未加入世界路由，地形/层台/陈设/稳定walk仍待。旧c拒绝状态不变。")
        lines.extend(["当前Scene："+file_cell(pack["scene"])+"；[处理/接入记录](redrock-joint-editor-20261023f.md)。",""])
        table(["资源","工程路径","来源PNG","消费者与状态"],[[r["label"],file_cell(r["output"]),file_cell(r["source"]),pack["scene"]+"；已接入工程结构草案，未接世界"] for r in pack["assets"]])
        processed=json.loads(read(local("assets/processed/redrock_joint_trial_20261023e/resource-pack.json")))
        table(["授权派生","路径","原图","使用状态"],[[r["label"],file_cell(r["output"]),file_cell(r["source"]),"本次3图仅padding；原RGBA保持，供f版Scene"] for r in processed["assets"]])
    desert_life_path = local("assets/raw/redrock_desert_life_20261025a/resource-pack.json")
    if desert_life_path.is_file():
        pack = json.loads(read(desert_life_path))
        section("### 赤岩沙漠生活组件（2026-10-25a）", "新增3建筑、3场景实体和2植被原生透明候选；不是背包图标。当前游戏消费者为0，尚未导入、绑定碰撞或启用交互。原PNG保留，完整A>0留白与比例/遮挡仍需按逐件结论准入。")
        lines.extend(["[本批路径、用途与检查记录](redrock-desert-life-20261025a.md)；[图鉴缩略图与原图放大](equipment-skill-catalog.html#resources)。", ""])
        table(["组件", "原PNG路径", "尺寸", "计划放置（非当前使用）", "当前状态"], [[r["label"], file_cell(r["output"]), image_size(local(r["output"])), r["intended_use"], "原生候选；游戏引用0；完整A1留白" + ("通过" if r["metrics"]["margin_10_percent_pass"] else "FAIL保留")] for r in pack["assets"]])
    redrock_town_pack = local("game/art/modules/redrock_town_20261028a/resource-pack.json")
    if redrock_town_pack.is_file():
        pack = json.loads(read(redrock_town_pack))
        section("### 赤岩关镇六区编辑布局（2026-10-28a）", "原生可编辑/F6：关门、民巷、驿舍马院、修坊、水院、望关台；40实例/20贴图、主路与支路的35×25足底体独立验证。20贴图字节原样供布局，含未正式A1准入候选，不能称正式世界或全城艺术完成。")
        lines.extend(["场景：" + file_cell("game/scenes/drafts/redrock_town_20261028a/redrock_town.tscn") + "；[实施/验证/并行边界](redrock-town-20261028a.md)。", ""])
        table(["资源", "工程路径", "来源PNG", "当前消费者"], [[r["label"], file_cell(r["output"]), file_cell(r["source"]), pack["scene"] + "；六区编辑布局草案，未接正式世界"] for r in pack["assets"]])
    redrock_standard = local("game/art/modules/redrock_luoyang_standard_20261028b/resource-pack.json")
    if redrock_standard.is_file():
        pack = json.loads(read(redrock_standard))
        section("### 赤岩生活街段与驿舍前厅（2026-10-28b）", "对照洛阳规范：四处真实院界/道路分级，驿舍主门进一处独立前厅并原脚同角色返回，桌柜凳架实际碰撞，普通中年女掌柜待机与肖像同人。79新检查与最终比例负控通过，未接正式世界/收费服务/剧情或稳定行走。原PNG无本地处理，A1失败仍保持。")
        lines.extend(["[当前场景/来源/使用与证据](redrock-luoyang-standard-20261028b.md)。", ""])
        table(["资源", "工程PNG", "原PNG来源", "当前消费者"], [[r["label"],file_cell(r["output"]),file_cell(r["source"]),r["scene"]+"；本地编辑草案"] for r in pack["assets"]])
    redrock_complete = local("game/art/modules/redrock_desert_complete_20261028d/resource-pack.json")
    if redrock_complete.is_file():
        pack = json.loads(read(redrock_complete))
        section("### 赤岩六区与关外商路（2026-10-28d）", "连续峡壁、原关楼、阶街石阶/侧向民居与商棚、驿舍和民居两处缓存室内；正式主角默认跟随，商旅/石匠和沙狐原生区域序列驱动。原PNG保持，17新增工程图RGBA精确；石匠左向运行时镜像，不宣称四向全新原画。正式世界/剧情战斗与A1美术准入尚未授。")
        lines.extend(["[当前场景、原图路径、使用状态与验证](redrock-desert-complete-20261028d.md)。", ""])
        table(["资源", "工程PNG", "原PNG", "当前消费者"], [[r["label"],file_cell(r["output"]),file_cell(r["source"]),r["scene"]+"；六区与关外商路装配"] for r in pack["assets"]])
    redrock_city_life = local("game/art/modules/redrock_city_life_20261029a/resource-pack.json")
    if redrock_city_life.is_file():
        pack = json.loads(read(redrock_city_life))
        section("### 赤岩街坊生活续改（2026-10-29a）", "同一赤岩六区场景：新增2间民居、22组生活陈设和4名复用原生精灵巡行人物；砂岩小石板材质用于街巷与四院，512周期采样，主角与三阶分层保持。正式世界/剧情/经济/战斗仍未接入，本批不授整城最终美术。")
        lines.extend(["[改造与验证记录](changes/redrock-city-life-20261029a.md)。", ""])
        table(["资源", "工程PNG", "原生PNG", "当前消费者"], [[r["label"],file_cell(r["output"]),file_cell(r["source"]),r["scene"]+"；原生材质不改RGB"] for r in pack["assets"]])
    desert_city=local("game/art/modules/desert_town_20261029d/resource-pack.json")
    if desert_city.is_file():
        pack=json.loads(read(desert_city))
        section("### 新沙漠城镇六区与前厅（2026-10-29d）", "独立黄沙土坯城：六区、三个民居院、井院与驼院、主角跟随/四向行走、六名复用居民巡行、一处缓存客栈前厅。13新运行图，14次独立内置生成含1城廓进深不足首稿；原RAW保持，12透明组件仅补RGBA0留白，全部原RGBA保持。正式世界/剧情战斗未接，非整城最终ART。")
        lines.extend(["场景："+file_cell(pack["scene"])+"；[创建、使用与检查记录](changes/desert-town-20261029d.md)；[缩略图与原图放大](equipment-skill-catalog.html#resources)。",""])
        table(["资源 / 类别","原PNG","授权留白派生","工程运行PNG","当前使用"],[[r["label"]+" / "+r["kind"],file_cell(r["parent_source"]),file_cell(r["source"]),file_cell(r["output"]),pack["scene"]+"；新城编辑地图使用，原A1失败保留"] for r in pack["assets"]])
        table(["复用地图精灵 / 肖像 / 物件","使用范围"],[[file_cell("res://"+p),"新城同场景复用；不是本批新生图，工人左向仍用原生右向运行时镜像"] for p in pack["reused_existing_art"]])
    miao_city=local("game/art/modules/miao_town_20261029f/resource-pack.json")
    if miao_city.is_file():
        pack=json.loads(read(miao_city))
        section("### 苗风山城六区与木楼前厅（2026-10-29f）", "按已确认总规创建独立编辑地图：37民居、3双铺、2绣坊、3粮仓，三桥四短阶、梯田/溪岸与芦笙制作架；正式冷孤云四向待机行走，8居民复用2身份巡行、一缓存木楼前厅与女掌柜。26张新原生图，23透明图仅补RGBA0留白，原RGBA保持；原完整A1失败保留。原4×4 NPC图仅采用四向待机，真实行走来自独立侧行四相，左向运行镜像；上下walk未采用。正式世界/剧情/经济/战斗未接，非整城最终ART。")
        lines.extend(["场景："+file_cell(pack['scene'])+"；[创建、控制与检查记录](changes/miao-town-20261029f.md)；[图鉴缩略与原图放大](equipment-skill-catalog.html#resources)。", ""])
        table(["资源 / 类别","原PNG","授权留白派生","工程运行PNG","当前使用"],[[r['label']+" / "+r['kind'],file_cell(r['parent_source']),file_cell(r['source']),file_cell(r['output']),pack['scene']+"；独立地图引用，RAW原A1失败保留"] for r in pack['assets']])
        table(["复用既有图像","使用范围"],[[file_cell('res://'+p),"已有家具/正式主角依赖；本批不改原文件，不计入26新生图"] for p in pack['reused_existing_art']])
    miao_recompose=local("game/art/modules/miao_recompose_20261029g/resource-pack.json")
    if miao_recompose.is_file():
        pack=json.loads(read(miao_recompose))
        section("### 苗风山城按原稿重排（2026-10-29g，历史布局）", "用户指出29f实景与总规相差较大；旧布局保留，29g另存溪谷斜穿、中央土坪、架空铺街、沿坡房组与梯田的36民居重排版。新增6native：高脚木楼/三铺木街/临溪栈道/苔岩曲坡/叠瀑/林下底材；5透明只补RGBA0，原RGBA保持。65/6首FAIL保、14/0局部后继通过，三桥四阶/铺街/重定位前厅已实机。29h用户指出楼型与大小相近，继续另存建筑差异版；山势/密度/正式世界与剧情未完成。")
        lines.extend(["当前场景："+file_cell(pack['scene'])+"；[原稿差异与重排记录](changes/miao-recompose-20261029g.md)。29f条目为历史，资源可以复用，不再作为已符合总规的布局。", ""])
        table(["新增原生组件","原图","授权派生","工程图","当前使用"],[[r['label'],file_cell(r['parent_source']),file_cell(r['source']),file_cell(r['output']),pack['scene']] for r in pack['assets']])
        previous=json.loads(read(local(pack['previous_pack'])))
        table(["复用29f资源","工程完整路径","当前消费者"],[[r['label'],file_cell(r['output']),pack['scene']+"；PNG不改，NPC仍仅采用侧行四相/左镜像"] for r in previous['assets'] if r['key'] in pack['reused_previous_asset_keys']])
    miao_variety=local("game/art/modules/miao_building_variety_20261029h/resource-pack.json")
    if miao_variety.is_file():
        pack=json.loads(read(miao_variety))
        section("### 苗风山城建筑差异版（2026-10-29h，历史建筑基线）", "用户指出建筑相似且同尺度，另制5种独立原生建筑并替换12处：宽木厅、窄高三层木楼、单间低宅、转角长廊作坊、小高脚粮棚；高度200—690px，成人门105—120px，粮棚明确为附属储藏舱。原生图各内置1次、仅RGBA0留白，原RGBA精同/原A1失败保。62项新占地/通路/导入检查及6项厅前真移动/树冠窗口/实景脚点过；旧四阶仍是平面通行，不是高差证明。29i另存三级台地修正，建筑原图继续复用；正式World/剧情服务与整城ART未授。")
        lines.extend(["当前场景："+file_cell(pack['scene'])+"；[体量、使用与检查记录](changes/miao-building-variety-20261029h.md)。", ""])
        table(["差异建筑","原生来源","授权派生","工程PNG","当前使用"],[[r['label'],file_cell(r['parent_source']),file_cell(r['source']),file_cell(r['output']),pack['scene']] for r in pack['assets']])
        for version,field in [('miao_town_20261029f','reused_29f_asset_keys'),('miao_recompose_20261029g','reused_29g_asset_keys')]:
            previous=json.loads(read(local('game/art/modules/'+version+'/resource-pack.json')))
            table(["复用"+version,"完整工程路径","当前消费者"],[[r['label'],file_cell(r['output']),pack['scene']+"；原PNG保持"] for r in previous['assets'] if r['key'] in pack[field]])
    miao_terrain=local("game/art/modules/miao_terrain_20261029i/resource-pack.json")
    if miao_terrain.is_file():
        pack=json.loads(read(miao_terrain))
        if pack.get('revision')=='lanxi_revision_20261030l':
            section("### 岚溪寨遮挡与坡岸优化（2026-10-30l，正式入口）", "openworld_lanxi_zhai 当前使用原三级台地场景。建筑全部不透明，仅主角遮挡影像alpha0.42；88个变形石墙立面退为166段完整等比苔石坡岸，5栋房屋/3件陈设让开边界，四处阶口保持真实上下层通路。已实际通过原World与木楼前厅进返，原PNG全部保持；不是林西村。详 changes/lanxi-occlusion-and-banks-20261030l.md。下列29i说明为历史施工记录，正式状态以本段为准。")
        section("### 苗风山城三级台地与必要石阶（2026-10-29i，当前编辑版本）", "纠正地形平坦与装饰楼梯：0/120/240三级台地，连续挡土坎、分层真实碰撞、4个上下层阶口；人物沿踏面连续升降，侧墙与非阶坎阻挡。默认出生点用真实Godot键事件连续走过两阶到达上层民巷；无途中瞬移。台地/坎界/阶口已保存为场景节点，F6跟随正式主角。复用34张原生PNG，0新增图/0像素处理/0新导入；仅新专有场景，不接正式World。")
        lines.extend(["当前场景："+file_cell(pack['scene'])+"；高程与阶口唯一数据："+file_cell(pack['terrain_data'])+"；[路径/高程/失败与验证记录](changes/miao-terrain-20261029i.md)。", ""])
        table(["必要阶口","连接","高处地面脚点","低处地面脚点"],[[r['label'],str(r['low'])+'层 → '+str(r['high'])+'层',str(r['top']),str(r['bottom'])] for r in pack['ramps']])
        for version,keys in pack['reused_asset_keys'].items():
            previous=json.loads(read(local('game/art/modules/'+version+'/resource-pack.json')))
            table(["复用组件","完整工程PNG路径","当前使用"],[[r['label'],file_cell(r['output']),pack['scene']+"；原PNG字节保持；分层碰撞与视觉投影由terrain.json驱动"] for r in previous['assets'] if r['key'] in keys])
    sect_pack_path=local("game/art/modules/sect_maps_20261029k/resource-pack.json")
    if sect_pack_path.is_file():
        pack=json.loads(read(sect_pack_path))
        section("### 武当与茗雾门派室外地图（2026-10-29k）", "用户确认29j设计后落地的独立F6场景。武当铜绿瓦/松崖三级山台0/180/360；茗雾白墙深瓦/茶圃双桥/低台0/60/120。每派4个真实上下层阶口，主角入口到主厅与侧路返回连续行走通过。12新原生图，11透明仅增加RGBA0留白，原RGBA保持。门派NPC、室内服务、正式世界入口未接；当前室外首版，不等于设计密度和最终美术完成。")
        lines.extend(["[实施与失败记录](changes/sect-maps-20261029k.md)。当前场景："+"、".join(file_cell('game/'+scene) for scene in pack['scenes'].values()),""])
        table(["类别 / 模块","原图路径","派生 / 工程路径","当前使用"],[[r['kind']+' / '+r['label'],file_cell(r['source']),file_cell(r['processed'])+'<br>'+file_cell(r['output']),'、'.join(r['scenes'])] for r in pack['assets']])
    section("## 维护与核验")
    lines.extend(["更新命令（只读取资源并重建本文件）：", "", "```powershell", "python scripts/build_resource_reuse_index.py", "```", "", "新增或替换资源后，先维护对应模块 manifest/index/catalog，再重建本索引；启用状态与候选结论需结合当时 current-progress 和专题记录复核。生成器中的正式状态说明是人工维护字段，不会因发现新文件自动晋升。", "", "扫描源范围：game/scripts（排除dev与备份）、game/data、game/scenes 中的 GD/TRES/TSCN/JSON。JSON来源hash字典不当作使用引用；运行时拼接、二进制原生包、导出PCK和实际剧情可达性未由此静态扫描穷举。地图整包分块按目录登记，模块运行图、背景、characters图像及工程音频逐文件列出，战斗帧按目录列完整文件名。", ""])
    changed = [rel(p) for p, sha in snapshots.items() if hashlib.sha256(p.read_bytes()).hexdigest() != sha]
    if changed:
        raise RuntimeError("Sources changed during scan; retry without writing document: " + ", ".join(changed[:10]))
    uncovered = set(modules + chars + audio + backgrounds + battle) - inventoried
    remaining_sect_manifest=local("assets/raw/sect_remaining_designs_20261029l/manifest.json")
    if remaining_sect_manifest.is_file():
        plans=json.loads(read(remaining_sect_manifest))
        section("### 华山、古峰、凌月总规（2026-10-29l）", "其余三派设计：险峰剑院/山野石寨/寒潭竹楼。3张原生总规本身0游戏消费者；华山29m已创建室外首版，凌月30a已装配并接入原入口，古峰仍待模块施工。三派专用新人物与同人肖像待补。不得裁整图充模块。")
        table(["门派设计", "完整原图路径", "当前使用情况"], [[r['name'],file_cell(r['output']),"总规设计参考；0游戏消费者"] for r in plans['assets']])
        lines.extend(["[审图差异与持续施工清单](changes/sect-remaining-designs-20261029l.md)。", ""])
    huashan_pack=local("game/art/modules/huashan_map_20261029m/resource-pack.json")
    if huashan_pack.is_file():
        pack=json.loads(read(huashan_pack))
        section("### 华山险峰剑院室外首版（2026-10-29m）", "独立F6场景：六区、5处真实上下阶口、0/240/480三级、连续崖缘。主角真实连续全环线36检查0失败；保存重开8检查0失败。8新原生图/7透明只加RGBA0留白。门派NPC、室内业务与正式世界入口未接，密度与山体细节非完整设计还原。")
        table(["资源", "原PNG", "派生PNG", "工程PNG", "当前消费者"], [[r['label'],file_cell(r['source']),file_cell(r['processed']),file_cell(r['output']),'; '.join(r['scenes'])] for r in pack['assets']])
        lines.extend(["[实施、失败保留与实机图](changes/huashan-map-20261029m.md)。", ""])
    native_city_pack=local("game/art/modules/desert_city_rework_20261029o/resource-pack.json")
    if native_city_pack.is_file():
        pack=json.loads(read(native_city_pack))
        section("### 赤岩、沙漠城原生像素返工（2026-10-29o）", "8张新原生图，原RGBA只补透明留白。赤岩短崖拼接/侧崖原生重复，沙漠独立门墙塔取代5倍整圈图，院墙缩回原生、沙丘分段；World两城各用统一0.46倍完整微缩图，保留原入口脚位。57项正式检查通过/两城真实进返；不等于整城密度与设计稿完全还原。旧enclosure_v2显示已停用，仅历史来源保留。")
        table(["分类 / 资源", "原PNG路径", "透明留白派生", "工程PNG", "当前消费者"], [[r['kind']+' / '+r['label'],file_cell(r['source']),file_cell(r['processed']),file_cell(r['output']),'; '.join(r['scenes'])] for r in pack['assets']])
        lines.extend(["[实机与检查记录](changes/desert-city-native-rework-20261029o.md)；[分类缩略图与点击放大](equipment-skill-catalog.html#resources)。", ""])
    completion_pack=local("game/art/modules/sect_completion_20261030a/resource-pack.json")
    if completion_pack.is_file():
        pack=json.loads(read(completion_pack))
        section("### 凌月、烈云、茗雾正式室外入口（2026-10-30a，当前）", "凌月寒潭竹院0/90/180、烈云灰岩木寨0/120/240、茗雾白墙茶院0/60/120，各4处必要阶口。7张新增原生组件仅RGBA0补白；茗雾复用29k组件。保留原NPC、对话与开放条件，3处原入口已加载新场景，内院往返与高地箭头通过。原剧情内院未重做，不代表全剧情或设计还原终验。")
        table(["类别 / 资源", "原PNG", "派生PNG", "工程PNG", "当前实际消费者"], [[r['kind']+' / '+r['label'],file_cell(r['source']),file_cell(r['processed']),file_cell(r['output']),'; '.join(r['scenes'])] for r in pack['assets']])
        table(["复用既有图", "本批实际装配场景"],[[file_cell(p),'; '.join(uses)] for p,uses in pack['reused_consumers'].items()])
        lines.extend(["[本批场景修复、原生资源和实机验证](changes/town-layout-and-sect-entries-20261030a.md)。沙漠四院消除后墙穿楼，城门保持不透明/仅主角半透明；赤岩0/240/330连续高台与三阶已正式修复。", ""])
    settlements_pack=local("game/art/modules/four_settlements_20261030e/resource-pack.json")
    if settlements_pack.is_file():
        pack=json.loads(read(settlements_pack))
        section("### 白鹿渡、东海埠、林西村、竹尾村（2026-10-30e，当前室外）", "六个原生布局接入七个原场景ID：两处渡港、林西三个片区及竹尾两个剧情阶段。保留原人物、对白、任务开放条件和室内；模块不放大，木栈台可走、水域阻挡、必要阶口连接实际高地。4张新模块仅增加透明留白；4张设计参考不裁切充当模块。当前室外首版，非完整设计密度终验。")
        table(["类别 / 资源", "原PNG", "透明留白派生", "工程PNG", "当前消费者"],[[r['kind']+' / '+r['label'],file_cell(r['source']),file_cell(r['processed']),file_cell(r['output']),'; '.join(r['scenes'])] for r in pack['assets']])
        table(["设计参考", "路径", "使用状态"],[[r['label'],file_cell(r['output']),'布局参考；无PNG运行消费者'] for r in pack['designs']])
        table(["复用既有PNG", "本批实际装配场景"],[[file_cell(p),'; '.join(uses)] for p,uses in pack['reused_consumers'].items()])
        lines.extend(["[改造与验证记录](changes/four-settlements-remodel-20261030e.md)；[分类缩略图与点击放大](equipment-skill-catalog.html#resources)。", ""])
    if uncovered:
        raise RuntimeError("Inventory coverage incomplete: " + ", ".join(rel(p) for p in sorted(uncovered)))
    lines.extend([f"本次读取并复核了 {len(snapshots)} 份文本来源，扫描期间SHA无变化。资源文件仅做目录/尺寸/字节观察，未解码重写、导入、移动或启动Godot。", ""])
    section("### 明确路径缺口", "以下是表中显式配置但磁盘未找到的文件；保留原值供后续修复。目录项、空配置和动态模板不计为缺失。")
    if missing:
        table(["路径", "处理"], [[f"`{p}`", "引用前核对原消费者；本次未改配置"] for p in sorted(missing)])
    else:
        lines.extend(["本次逐项表中的显式文件路径均存在。", ""])
    OUTPUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps({"output": rel(OUTPUT), "lines": len(lines), "bytes": OUTPUT.stat().st_size, "text_sources_checked": len(snapshots), "scene_resources": len(scenes), "scene_npc_rows": len(npc_rows), "dynamic_npc_rows": len(dynamic_rows), "module_images": len(modules), "character_images": len(chars), "audio_files": len(audio), "missing_explicit_paths": sorted(missing)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
