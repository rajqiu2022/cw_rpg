#!/usr/bin/env python3
"""Build an offline quest atlas from the live Godot content graph.

The generator links QuestDef resources to dialogue nodes, scenes, flags,
enemies and item rewards.  It deliberately reports unlinked definitions
instead of pretending that every .tres file is reachable in the game.
"""

from __future__ import annotations

import json
import re
from collections import defaultdict
from datetime import datetime
from html import escape
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
DATA = GAME / "data"
TEMPLATE = ROOT / "docs" / "quest-catalog.template.html"
OUTPUT = ROOT / "docs" / "quest-catalog.html"
CHAPTER_ONE_PLAN = DATA / "chapters" / "chapter_1_content_plan.tres"

# Compatibility resources remain on disk for old saves and migration tests, but
# they are not part of the current playable canon. Keep them visible in the
# owner-facing catalogue with an explicit state instead of misreporting an
# orphaned legacy DialogScript as a live quest entry.
RETIRED_DIALOG_IDS = {
    "ch1_road_after_thug",
    "ch1_forest_yuewuxing",
    "ch1_forest_yuewuxing_talk",
    "ch1_forest_victory",
}


def side_quest_resolutions() -> dict[str, dict]:
    """Read producer decisions for chapter-one side-quest drafts."""
    if not CHAPTER_ONE_PLAN.exists():
        return {}
    source = read(CHAPTER_ONE_PLAN)
    match = re.search(
        r"side_quest_decisions\s*=\s*Array\[Dictionary\]\(\[(.*?)\]\)\s*\nleveling_scene_ids",
        source,
        re.DOTALL,
    )
    if not match:
        return {}
    result: dict[str, dict] = {}
    for block in re.findall(r"\{([^{}]+)\}", match.group(1)):
        def field(key: str) -> str:
            value = re.search(rf'"{re.escape(key)}"\s*:\s*"([^"]*)"', block)
            return value.group(1) if value else ""

        quest_id = field("quest_id")
        if not quest_id:
            continue
        target = re.search(r'"target_chapter"\s*:\s*(\d+)', block)
        result[quest_id] = {
            "decision": field("decision"),
            "targetChapter": int(target.group(1)) if target else 0,
            "replacementId": field("replacement_id"),
            "reason": field("reason"),
        }
    return result


def quest_state_label(quest: dict) -> str:
    if quest.get("retired"):
        return "兼容旧线"
    if quest.get("linked"):
        return "已接入"
    if quest.get("resolved"):
        return "规划已处理"
    return "待接入"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig")


def rhs(source: str, key: str) -> str:
    match = re.search(rf"(?m)^{re.escape(key)}\s*=\s*(.+)$", source)
    return match.group(1).strip() if match else ""


def string_value(source: str, key: str, default: str = "") -> str:
    match = re.match(r'&?"(.*)"$', rhs(source, key))
    if not match:
        return default
    return match.group(1).replace(r"\n", "\n").replace(r'\"', '"')


def int_value(source: str, key: str, default: int = 0) -> int:
    match = re.match(r"-?\d+", rhs(source, key))
    return int(match.group(0)) if match else default


def bool_value(source: str, key: str, default: bool = False) -> bool:
    value = rhs(source, key).lower()
    if value == "true":
        return True
    if value == "false":
        return False
    return default


def string_array(source: str, key: str) -> list[str]:
    value = rhs(source, key)
    return [
        item.replace(r"\n", "\n").replace(r'\"', '"')
        for item in re.findall(r'&?"([^"\\]*(?:\\.[^"\\]*)*)"', value)
    ]


def dict_entries(source: str, key: str) -> list[dict]:
    value = rhs(source, key)
    result: list[dict] = []
    for block in re.findall(r"\{([^{}]*)\}", value):
        item = re.search(r'"(?:id|item_id)"\s*:\s*"([^"]+)"', block)
        if not item:
            continue
        count = re.search(r'"count"\s*:\s*(\d+)', block)
        result.append({"id": item.group(1), "count": int(count.group(1)) if count else 1})
    return result


def unique(values: list[str]) -> list[str]:
    return list(dict.fromkeys(value for value in values if value))


def excerpt(value: str, length: int = 42) -> str:
    clean = re.sub(r"\s+", " ", re.sub(r"\[[^]]+\]", "", value)).strip()
    return clean if len(clean) <= length else clean[:length] + "…"


def balanced_dicts(source: str) -> list[str]:
    """Extract every balanced {...} block while respecting quoted strings."""
    stack: list[int] = []
    blocks: list[str] = []
    quoted = False
    escaped = False
    for index, char in enumerate(source):
        if escaped:
            escaped = False
            continue
        if char == "\\" and quoted:
            escaped = True
            continue
        if char == '"':
            quoted = not quoted
            continue
        if quoted:
            continue
        if char == "{":
            stack.append(index)
        elif char == "}" and stack:
            start = stack.pop()
            blocks.append(source[start : index + 1])
    return blocks


def resource_names() -> tuple[dict[str, str], dict[str, str], dict[str, str]]:
    item_names: dict[str, str] = {}
    for folder in ("items", "equipment"):
        for path in sorted((DATA / folder).glob("*.tres")):
            source = read(path)
            item_id = string_value(source, "item_id", path.stem)
            item_names[item_id] = string_value(source, "display_name", item_id)
    enemy_names: dict[str, str] = {}
    for path in sorted((DATA / "enemies").glob("*.tres")):
        source = read(path)
        enemy_id = string_value(source, "enemy_id", path.stem)
        enemy_names[enemy_id] = string_value(source, "display_name", enemy_id)
    skill_names: dict[str, str] = {}
    for path in sorted((DATA / "skills").glob("*.tres")):
        source = read(path)
        skill_id = string_value(source, "skill_id", path.stem)
        skill_names[skill_id] = string_value(source, "display_name", skill_id)
    return item_names, enemy_names, skill_names


def dialogue_index() -> tuple[dict[str, dict], dict[str, list[dict]], dict[str, list[dict]], dict[str, list[dict]], dict[str, list[dict]]]:
    dialogs: dict[str, dict] = {}
    accept: dict[str, list[dict]] = defaultdict(list)
    complete: dict[str, list[dict]] = defaultdict(list)
    flag_sources: dict[str, list[dict]] = defaultdict(list)
    item_sources: dict[str, list[dict]] = defaultdict(list)
    for path in sorted((DATA / "dialogs").glob("*.tres")):
        source = read(path)
        dialog_id = string_value(source, "dialog_id", path.stem)
        if dialog_id in RETIRED_DIALOG_IDS:
            continue
        nodes: list[dict] = []
        for block in re.split(r"(?=\n\[sub_resource)", source):
            node_id = string_value(block, "node_id")
            if not node_id:
                continue
            speaker = string_value(block, "speaker") or "旁白"
            text = string_value(block, "text")
            node = {
                "dialogId": dialog_id,
                "dialogFile": path.name,
                "nodeId": node_id,
                "speaker": speaker,
                "text": excerpt(text),
            }
            nodes.append(node)
            accepted = string_value(block, "accept_quest")
            finished = string_value(block, "complete_quest")
            if accepted:
                accept[accepted].append(node)
            if finished:
                complete[finished].append(node)
            for entry in re.findall(r'"key"\s*:\s*"([^"]+)"\s*,\s*"value"\s*:\s*true', rhs(block, "set_flags")):
                flag_sources[entry].append(node)
            for entry in re.findall(r'"set_flag"\s*:\s*\{[^{}]*"([^"]+)"\s*:\s*true', rhs(block, "choices")):
                flag_sources[entry].append(node)
            for entry in dict_entries(block, "give_items"):
                item_sources[entry["id"]].append(node)
        dialogs[dialog_id] = {"id": dialog_id, "file": path.name, "nodes": nodes}
    return dialogs, accept, complete, flag_sources, item_sources


def scene_index(dialogs: dict[str, dict], enemy_names: dict[str, str]) -> tuple[dict[str, dict], dict[str, list[dict]], dict[str, list[dict]]]:
    scenes: dict[str, dict] = {}
    dialog_scenes: dict[str, list[dict]] = defaultdict(list)
    enemy_scenes: dict[str, list[dict]] = defaultdict(list)
    dialog_ids = set(dialogs)
    enemy_ids = set(enemy_names)

    for path in sorted((DATA / "scenes").glob("*.tres")):
        source = read(path)
        scene_id = string_value(source, "scene_id", path.stem)
        scene_name = string_value(source, "display_name", scene_id)
        combined = source
        for resource_path in re.findall(r'path="res://data/maps/([^"]+\.tres)"', source):
            linked = DATA / "maps" / resource_path
            if linked.exists():
                combined += "\n" + read(linked)
        tokens = set(re.findall(r'"([^"]+)"', combined))
        tokens.update(re.findall(r'"(?:action|interaction_action)"\s*:\s*"dialog:([^"]+)"', combined))
        scene = {"id": scene_id, "name": scene_name, "file": path.name}
        scenes[scene_id] = scene

        for dialog_id in sorted(dialog_ids & tokens):
            contexts: list[dict] = []
            for block in balanced_dicts(combined):
                if f'"{dialog_id}"' not in block and f'"dialog:{dialog_id}"' not in block:
                    continue
                actor = (
                    re.search(r'"npc_name"\s*:\s*"([^"]+)"', block)
                    or re.search(r'"label"\s*:\s*"([^"]+)"', block)
                )
                conditions = re.findall(r'"require_flag"\s*:\s*"([^"]+)"', block)
                for raw in re.findall(r'"require_flags"\s*:\s*\[([^]]*)\]', block):
                    conditions.extend(re.findall(r'"([^"]+)"', raw))
                contexts.append({
                    "actor": actor.group(1) if actor else "",
                    "conditions": unique(conditions),
                })
            if not contexts:
                contexts = [{"actor": "", "conditions": []}]
            for context in contexts:
                dialog_scenes[dialog_id].append({**scene, **context})

        for enemy_id in sorted(enemy_ids & tokens):
            enemy_scenes[enemy_id].append(scene)

    for values in dialog_scenes.values():
        seen: set[tuple] = set()
        values[:] = [
            value for value in values
            if not ((
                value["id"], value["actor"], tuple(value["conditions"])
            ) in seen or seen.add((value["id"], value["actor"], tuple(value["conditions"]))))
        ]
    return scenes, dialog_scenes, enemy_scenes


def chapter_of(quest_id: str) -> tuple[int, str]:
    match = re.match(r"q_ch(\d+)_", quest_id)
    if match:
        chapter = int(match.group(1))
        return chapter, f"第{chapter}章"
    return 99, "秘闻"


def trigger_label(trigger: str, scenes: dict[str, dict], item_names: dict[str, str], enemy_names: dict[str, str]) -> str:
    kind, _, value = trigger.partition(":")
    labels = {
        "flag_set": "剧情旗标",
        "enemy_defeated": "击败敌人",
        "scene_entered": "进入地图",
        "item_picked_up": "取得物品",
        "npc_talked_to": "与人物交谈",
    }
    display = value
    if kind == "scene_entered" and value in scenes:
        display = scenes[value]["name"]
    elif kind == "enemy_defeated":
        display = enemy_names.get(value, value)
    elif kind == "item_picked_up":
        display = item_names.get(value, value)
    return f"{labels.get(kind, kind)} · {display}"


def attach_map(node: dict, dialog_scenes: dict[str, list[dict]]) -> list[dict]:
    result: list[dict] = []
    for scene in dialog_scenes.get(node["dialogId"], []):
        result.append({
            "id": scene["id"],
            "name": scene["name"],
            "actor": scene["actor"] or node["speaker"],
            "conditions": scene["conditions"],
        })
    return result


def build() -> list[dict]:
    item_names, enemy_names, skill_names = resource_names()
    dialogs, accepted, completed, flag_sources, item_sources = dialogue_index()
    scenes, dialog_scenes, enemy_scenes = scene_index(dialogs, enemy_names)
    rows: list[dict] = []
    resolutions = side_quest_resolutions()
    canon = json.loads(read(ROOT / "docs/storyline-data.json"))
    retired_ids = {qid for chapter in canon["chapters"] for qid in chapter.get("legacyQuestIds", [])}

    for path in sorted((DATA / "quests").glob("*.tres")):
        source = read(path)
        quest_id = string_value(source, "quest_id", path.stem)
        title = string_value(source, "title", quest_id)
        chapter_sort, chapter = chapter_of(quest_id)
        chapter_independent = bool_value(source, "chapter_independent")
        if chapter_independent:
            chapter_sort, chapter = 0, "开放世界"
        kind = "主线" if int_value(source, "kind", 1) == 0 else ("奇遇" if chapter_independent else ("秘闻" if chapter == "秘闻" else "支线"))
        triggers = string_array(source, "completion_triggers")
        auto_accept_triggers = string_array(source, "auto_accept_triggers")
        accept_nodes = accepted.get(quest_id, [])
        complete_nodes = completed.get(quest_id, [])

        starts: list[dict] = []
        finishes: list[dict] = []
        map_entries: list[dict] = []
        gates: list[str] = []
        for node in accept_nodes:
            attached = attach_map(node, dialog_scenes)
            map_entries.extend(attached)
            for scene in attached:
                gates.extend(scene["conditions"])
            starts.append({
                "label": f'{node["speaker"]} · {node["dialogId"]}/{node["nodeId"]}',
                "text": node["text"],
                "maps": unique([scene["name"] for scene in attached]),
            })
        for trigger in auto_accept_triggers:
            kind_id, _, value = trigger.partition(":")
            linked_nodes: list[dict] = flag_sources.get(value, []) if kind_id == "flag_set" else []
            linked_maps: list[dict] = []
            for node in linked_nodes:
                linked_maps.extend(attach_map(node, dialog_scenes))
            map_entries.extend(linked_maps)
            starts.append({
                "label": f"系统自动接取 · {trigger_label(trigger, scenes, item_names, enemy_names)}",
                "text": "首个跨章线索完成后自动加入任务日志。",
                "maps": unique([scene["name"] for scene in linked_maps]),
            })
        for node in complete_nodes:
            attached = attach_map(node, dialog_scenes)
            map_entries.extend(attached)
            finishes.append({
                "label": f'{node["speaker"]} · {node["dialogId"]}/{node["nodeId"]}',
                "text": node["text"],
                "maps": unique([scene["name"] for scene in attached]),
            })

        trigger_details: list[dict] = []
        for trigger in triggers:
            kind_id, _, value = trigger.partition(":")
            linked_maps: list[dict] = []
            linked_nodes: list[dict] = []
            if kind_id == "scene_entered" and value in scenes:
                linked_maps.append({**scenes[value], "actor": "", "conditions": []})
            elif kind_id == "enemy_defeated":
                linked_maps.extend({**scene, "actor": "", "conditions": []} for scene in enemy_scenes.get(value, []))
            elif kind_id == "flag_set":
                linked_nodes = flag_sources.get(value, [])
                for node in linked_nodes:
                    linked_maps.extend(attach_map(node, dialog_scenes))
            elif kind_id == "item_picked_up":
                linked_nodes = item_sources.get(value, [])
                for node in linked_nodes:
                    linked_maps.extend(attach_map(node, dialog_scenes))
            map_entries.extend(linked_maps)
            trigger_details.append({
                "raw": trigger,
                "label": trigger_label(trigger, scenes, item_names, enemy_names),
                "maps": unique([entry["name"] for entry in linked_maps]),
            })

        map_names = unique([entry["name"] for entry in map_entries])
        map_ids = unique([entry["id"] for entry in map_entries])
        reward_items = []
        for entry in dict_entries(source, "reward_items"):
            reward_items.append({
                "id": entry["id"],
                "name": item_names.get(entry["id"], entry["id"]),
                "count": entry["count"],
            })
        reward_skills = [
            {"id": skill_id, "name": skill_names.get(skill_id, skill_id), "faction": ""}
            for skill_id in string_array(source, "reward_skills")
        ]
        faction_labels = {"wudang": "武当", "huashan": "华山", "gufeng": "古峰", "lingyue": "凌月", "mingwu": "茗雾", "wanderer": "无门派"}
        faction_value = rhs(source, "reward_skills_by_faction")
        for faction_id, skills_raw in re.findall(r'"([^"]+)"\s*:\s*Array\[StringName\]\(\[([^]]*)\]\)', faction_value):
            for skill_id in re.findall(r'&"([^"]+)"', skills_raw):
                reward_skills.append({
                    "id": skill_id,
                    "name": skill_names.get(skill_id, skill_id),
                    "faction": faction_labels.get(faction_id, faction_id),
                })
        flag_labels = {"wudang_route_taiji": "武当·太极拳支路", "wudang_route_mian": "武当·绵掌支路"}
        flag_value = rhs(source, "reward_skills_by_flag")
        for flag_id, skills_raw in re.findall(r'"([^"]+)"\s*:\s*Array\[StringName\]\(\[([^]]*)\]\)', flag_value):
            for skill_id in re.findall(r'&"([^"]+)"', skills_raw):
                reward_skills.append({
                    "id": skill_id,
                    "name": skill_names.get(skill_id, skill_id),
                    "faction": flag_labels.get(flag_id, flag_id),
                })
        retired = quest_id in retired_ids
        resolution = resolutions.get(quest_id, {})
        resolved = resolution.get("decision") in {"merge", "migrate"}
        linked = bool(starts) and not retired
        if resolved and not starts:
            decision_label = "迁至第%d章" % resolution["targetChapter"] if resolution["decision"] == "migrate" else "并入现有任务"
            replacement = resolution.get("replacementId", "")
            if replacement:
                decision_label += " · %s" % replacement
            starts = [{"label": "内容决策 · %s" % decision_label, "text": resolution.get("reason", ""), "maps": []}]
        rows.append({
            "id": quest_id,
            "title": title,
            "kind": kind,
            "chapter": chapter,
            "chapterSort": chapter_sort,
            "chapterIndependent": chapter_independent,
            "linked": linked,
            "retired": retired,
            "resolved": resolved,
            "resolution": resolution,
            "source": f"game/data/quests/{path.name}",
            "descriptions": {
                "locked": string_value(source, "desc_not_started"),
                "active": string_value(source, "desc_in_progress"),
                "complete": string_value(source, "desc_completed"),
                "tracker": string_value(source, "tracker_hint"),
            },
            "starts": starts or [{"label": "未发现运行时接取节点", "text": "资源已定义，但当前对话与场景图中没有接取入口。", "maps": []}],
            "triggers": trigger_details or [{"raw": "", "label": "未配置自动完成条件", "maps": []}],
            "finishes": finishes,
            "maps": map_names,
            "mapIds": map_ids,
            "gates": unique(gates),
            "rewards": {
                "gold": int_value(source, "reward_gold"),
                "exp": int_value(source, "reward_exp"),
                "items": reward_items,
                "skills": reward_skills,
            },
        })

    rows.sort(key=lambda item: (item["chapterSort"], 0 if item["kind"] == "主线" else 1, item["id"]))
    return rows


def static_card(quest: dict, index: int) -> str:
    maps = "".join(f"<span>{escape(name)}</span>" for name in quest["maps"]) or "<span>未关联地图</span>"
    starts = "".join(
        f'<li><strong>{escape(node["label"])}</strong><small>{escape(node["text"] or "无节点摘要")}'
        f'{" · " + escape(" / ".join(node["maps"])) if node["maps"] else ""}</small></li>'
        for node in quest["starts"]
    )
    triggers = "".join(
        f'<li><strong>{escape(trigger["label"])}</strong><small><code>{escape(trigger["raw"])}</code>'
        f'{" · " + escape(" / ".join(trigger["maps"])) if trigger["maps"] else ""}</small></li>'
        for trigger in quest["triggers"]
    )
    finishes = "".join(
        f'<li><strong>{escape(node["label"])}</strong><small>{escape(node["text"] or "无节点摘要")}'
        f'{" · " + escape(" / ".join(node["maps"])) if node["maps"] else ""}</small></li>'
        for node in quest["finishes"]
    ) or '<li><strong>自动结算</strong><small>满足完成条件后由 QuestManager 结算</small></li>'
    gates = "、".join(quest["gates"]) if quest["gates"] else "无额外入口旗标"
    rewards = []
    if quest["rewards"]["gold"]:
        rewards.append(f'{quest["rewards"]["gold"]} 金')
    if quest["rewards"]["exp"]:
        rewards.append(f'{quest["rewards"]["exp"]} 经验')
    rewards.extend(f'{item["name"]} ×{item["count"]}' for item in quest["rewards"]["items"])
    rewards.extend(
        f'领悟「{skill["name"]}」' + (f'（{skill["faction"]}限定）' if skill["faction"] else '')
        for skill in quest["rewards"]["skills"]
    )
    reward_html = " · ".join(map(escape, rewards)) if rewards else "无数值奖励"
    state = quest_state_label(quest)
    state_class = "legacy" if quest.get("retired") else ("live" if quest["linked"] else ("resolved" if quest.get("resolved") else "draft"))
    return f'''<article id="{escape(quest['id'], quote=True)}" class="quest-card" data-search="{escape((quest["title"] + " " + quest["id"] + " " + " ".join(quest["maps"])).lower(), quote=True)}" data-chapter="{escape(quest["chapter"], quote=True)}" data-kind="{escape(quest["kind"], quote=True)}" data-link="{state}" style="--delay:{min(index, 18) * 24}ms">
      <details><summary><span class="index">{index + 1:02d}</span><span class="summary-main"><span class="eyebrow">{escape(quest["chapter"])} · {escape(quest["kind"])}</span><strong>{escape(quest["title"])}</strong><code>{escape(quest["id"])}</code></span><span class="status {state_class}">{state}</span><span class="fold">＋</span></summary>
      <div class="quest-body"><div class="map-strip">{maps}</div><p class="objective">{escape(quest["descriptions"]["active"] or "暂无进行中说明")}</p>
      <div class="node-grid">
        <section><b>壹 · 接取</b><p class="stage-note">入口条件：{escape(gates)}</p><ul class="node-list">{starts}</ul></section>
        <section><b>贰 · 推进</b><p class="stage-note">{escape(quest["descriptions"]["tracker"] or "未配置追踪地点")}</p><ul class="node-list">{triggers}</ul></section>
        <section><b>叁 · 结案</b><p class="stage-note">{escape(quest["descriptions"]["complete"] or "暂无完成说明")}</p><ul class="node-list">{finishes}</ul></section>
      </div><div class="reward"><span>酬</span><strong>{reward_html}</strong></div><div class="source">{escape(quest["source"])}</div></div></details></article>'''


def main() -> None:
    quests = build()
    counts = {
        "total": len(quests),
        "main": sum(q["kind"] == "主线" for q in quests),
        "side": sum(q["kind"] != "主线" for q in quests),
        "linked": sum(q["linked"] for q in quests),
        "retired": sum(q.get("retired", False) for q in quests),
        "resolved": sum(q.get("resolved", False) for q in quests),
    }
    chapters = unique([q["chapter"] for q in quests])
    payload = json.dumps(quests, ensure_ascii=False).replace("</", r"<\/")
    html = read(TEMPLATE)
    replacements = {
        "__GENERATED_AT__": datetime.now().strftime("%Y-%m-%d %H:%M"),
        "__TOTAL__": str(counts["total"]),
        "__MAIN__": str(counts["main"]),
        "__SIDE__": str(counts["side"]),
        "__LINKED__": str(counts["linked"]),
        "__UNLINKED__": str(counts["total"] - counts["linked"] - counts["retired"] - counts["resolved"]),
        "__RETIRED__": str(counts["retired"]),
        "__RESOLVED__": str(counts["resolved"]),
        "__CHAPTER_OPTIONS__": "".join(f'<option value="{escape(ch, quote=True)}">{escape(ch)}</option>' for ch in chapters),
        "__QUEST_DATA__": payload,
        "__STATIC_CARDS__": "\n".join(static_card(q, index) for index, q in enumerate(quests)),
    }
    for marker, value in replacements.items():
        html = html.replace(marker, value)
    OUTPUT.write_text(html, encoding="utf-8")
    print(
        f"Wrote {OUTPUT.relative_to(ROOT)}: {counts['total']} quests, "
        f"{counts['main']} main, {counts['side']} side/secret, "
        f"{counts['linked']} linked, {counts['total'] - counts['linked'] - counts['retired'] - counts['resolved']} unlinked, "
        f"{counts['resolved']} resolved-planning, {counts['retired']} compatibility-only"
    )


if __name__ == "__main__":
    main()
