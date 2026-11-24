#!/usr/bin/env python3
"""Build the offline chapter-by-chapter player progression guide.

The page joins the curated eight-chapter storyline with live quest, skill and
equipment resources.  It deliberately distinguishes exact stage rewards from
the broader chapter collection pool so the guide never promises an item at the
wrong main-quest node.
"""

from __future__ import annotations

import json
from datetime import datetime
from html import escape
from pathlib import Path

from build_arsenal_catalog import build_equipment, build_skills
from build_quest_catalog import build as build_quests
from build_storyline_catalog import build as build_stories


ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "docs" / "stage-progression-catalog.template.html"
OUTPUT = ROOT / "docs" / "stage-progression-catalog.html"

IGNORED_SPEAKERS = {
    "", "旁白", "冷孤云", "系统", "自动结算", "内容决策",
    "未发现运行时接取节点", "剧情自动推进", "场景事件",
}


def unique(values: list[str]) -> list[str]:
    return list(dict.fromkeys(value.strip() for value in values if value and value.strip()))


def speaker(label: str) -> str:
    value = label.split(" · ", 1)[0].strip()
    return "" if value in IGNORED_SPEAKERS or value.startswith("系统") else value


def reward_entries(quest: dict, equipment: dict[str, dict], skills: dict[str, dict]) -> dict:
    result = {"skills": [], "equipment": [], "items": [], "gold": quest["rewards"]["gold"], "exp": quest["rewards"]["exp"]}
    for reward in quest["rewards"]["skills"]:
        row = skills.get(reward["id"], {})
        result["skills"].append({
            "id": reward["id"],
            "name": reward["name"],
            "school": reward.get("faction") or row.get("category", "江湖传承").split(" · ", 1)[0],
            "kind": "心法" if row.get("heartArt") else "武功",
            "quality": row.get("quality", ""),
            "icon": row.get("icon", ""),
            "iconExists": bool(row.get("iconExists")),
        })
    for reward in quest["rewards"]["items"]:
        entry = {"id": reward["id"], "name": reward["name"], "count": reward["count"]}
        if reward["id"] in equipment:
            row = equipment[reward["id"]]
            entry.update({"quality": row["quality"], "category": row["category"], "icon": row["icon"], "iconExists": row["iconExists"]})
            result["equipment"].append(entry)
        else:
            result["items"].append(entry)
    return result


def acquisition_rewards(quest: dict, equipment: dict[str, dict], skills: dict[str, dict]) -> dict:
    """Resolve items granted by dialog/learning routes named after this quest."""
    result = {"skills": [], "equipment": [], "items": [], "gold": 0, "exp": 0}
    needle = quest["title"]
    for row in skills.values():
        if row["available"] and any(needle in method for method in row["acquisition"]):
            result["skills"].append({
                "id": row["id"], "name": row["name"],
                "school": row["category"].split(" · ", 1)[0],
                "kind": "心法" if row["heartArt"] else "武功",
                "quality": row["quality"], "icon": row["icon"], "iconExists": row["iconExists"],
            })
    for row in equipment.values():
        if row["available"] and any(needle in method for method in row["acquisition"]):
            result["equipment"].append({
                "id": row["id"], "name": row["name"], "count": 1,
                "quality": row["quality"], "category": row["category"],
                "icon": row["icon"], "iconExists": row["iconExists"],
            })
    return result


def combine_rewards(primary: dict, extra: dict) -> dict:
    merged = {"gold": primary.get("gold", 0), "exp": primary.get("exp", 0)}
    for group in ("skills", "equipment", "items"):
        by_id = {entry["id"]: entry for entry in primary[group]}
        by_id.update({entry["id"]: entry for entry in extra[group]})
        merged[group] = list(by_id.values())
    return merged


def stage_npcs(story: dict, quest: dict) -> list[dict]:
    text_parts = [quest["title"]]
    text_parts.extend(quest["descriptions"].values())
    for node in quest["starts"] + quest["finishes"]:
        text_parts.extend([node.get("label", ""), node.get("text", "")])
    haystack = " ".join(text_parts)
    names = [speaker(node.get("label", "")) for node in quest["starts"] + quest["finishes"]]
    names.extend(person["name"] for person in story["characters"] if person["name"] in haystack)
    roles = {person["name"]: person["role"] for person in story["characters"]}
    return [{"name": name, "role": roles.get(name, "任务相关人物")} for name in unique(names)]


def merge_collectibles(target: dict, rewards: dict, quest: dict) -> None:
    for group in ("skills", "equipment", "items"):
        for entry in rewards[group]:
            current = target[group].setdefault(entry["id"], {**entry, "sources": []})
            source = {"id": quest["id"], "title": quest["title"], "kind": quest["kind"]}
            if source not in current["sources"]:
                current["sources"].append(source)


def build() -> list[dict]:
    quests = build_quests()
    quest_by_id = {quest["id"]: quest for quest in quests}
    equipment = {row["id"]: row for row in build_equipment()}
    skills = {row["id"]: row for row in build_skills()}
    chapters: list[dict] = []

    for story in build_stories():
        number = story["number"]
        all_chapter_quests = [
            quest for quest in quests
            if quest["chapterSort"] == number and not quest["retired"] and not quest["resolved"]
        ]
        chapter_quests = [
            quest for quest in quests
            if quest["chapterSort"] == number and quest["linked"] and not quest["retired"] and not quest["resolved"]
        ]
        collection = {"skills": {}, "equipment": {}, "items": {}}
        for quest in chapter_quests:
            merge_collectibles(collection, reward_entries(quest, equipment, skills), quest)
        for quest in all_chapter_quests:
            merge_collectibles(collection, acquisition_rewards(quest, equipment, skills), quest)

        stages = []
        for index, raw_stage in enumerate(story["stages"] + story["branchStages"], 1):
            quest = quest_by_id[raw_stage["id"]]
            rewards = combine_rewards(reward_entries(quest, equipment, skills), acquisition_rewards(quest, equipment, skills))
            stages.append({
                **raw_stage,
                "index": index,
                "npcs": stage_npcs(story, quest),
                "rewards": rewards,
                "completion": quest["descriptions"]["complete"] or "完成当前阶段目标",
            })

        chapters.append({
            "number": number,
            "title": story["title"],
            "objective": story["objective"],
            "question": story["chapterQuestion"],
            "combatNotes": story.get("combatNotes", []),
            "status": story["statusLabel"],
            "implementation": story["implementation"],
            "regions": story["regions"],
            "npcs": story["characters"],
            "stages": stages,
            "collection": {key: list(value.values()) for key, value in collection.items()},
            "otherQuests": [
                {"id": quest["id"], "title": quest["title"], "kind": quest["kind"], "maps": quest["maps"]}
                for quest in chapter_quests if quest["id"] not in {stage["id"] for stage in stages}
            ],
        })

    if [chapter["number"] for chapter in chapters] != list(range(1, 9)):
        raise ValueError("progression guide must contain chapters 1 through 8")
    if any(not chapter["stages"] for chapter in chapters):
        raise ValueError("every chapter must expose at least one main progression stage")
    return chapters


def build_open_world() -> dict:
    # Open-world play is broader than `chapter_independent`: the latter means
    # absolutely no chapter gate, while ordinary side quests remain freely
    # explorable after their region is introduced.  Both belong in this view.
    quests = [
        quest for quest in build_quests()
        if quest["kind"] != "主线" and quest["linked"] and not quest["retired"] and not quest["resolved"]
    ]
    equipment = {row["id"]: row for row in build_equipment()}
    skills = {row["id"]: row for row in build_skills()}
    collection = {"skills": {}, "equipment": {}, "items": {}}
    npcs: list[str] = []
    stages = []
    for index, quest in enumerate(quests, 1):
        rewards = combine_rewards(reward_entries(quest, equipment, skills), acquisition_rewards(quest, equipment, skills))
        merge_collectibles(collection, rewards, quest)
        names = [speaker(node.get("label", "")) for node in quest["starts"] + quest["finishes"]]
        npcs.extend(names)
        stages.append({
            "index": index, "id": quest["id"], "title": quest["title"], "kind": quest["kind"],
            "unlock": "全程开放" if quest["chapterIndependent"] else (f"{quest['chapter']}起开放" if quest["chapter"].startswith("第") else quest["chapter"]),
            "independent": bool(quest["chapterIndependent"]),
            "summary": quest["descriptions"]["active"] or quest["descriptions"]["locked"],
            "tracker": quest["descriptions"]["tracker"], "maps": quest["maps"], "rewards": rewards,
        })
    return {
        "npcs": unique(npcs), "stages": stages,
        "independentCount": sum(1 for quest in quests if quest["chapterIndependent"]),
        "regionalCount": sum(1 for quest in quests if not quest["chapterIndependent"]),
        "collection": {key: list(value.values()) for key, value in collection.items()},
    }


def reward_chip(entry: dict, kind: str) -> str:
    suffix = f' ×{entry["count"]}' if entry.get("count", 1) > 1 else ""
    meta = entry.get("kind") or entry.get("category") or "道具"
    return (
        f'<span class="reward-chip {kind}" title="{escape(entry.get("id", ""), quote=True)}">'
        f'<i>{escape(meta[:1])}</i><b>{escape(entry["name"])}{suffix}</b>'
        f'<small>{escape(meta)}</small></span>'
    )


def reward_block(rewards: dict) -> str:
    entries = []
    entries.extend(reward_chip(item, "skill") for item in rewards["skills"])
    entries.extend(reward_chip(item, "gear") for item in rewards["equipment"])
    entries.extend(reward_chip(item, "item") for item in rewards["items"])
    if rewards.get("gold"):
        entries.append(f'<span class="reward-chip currency"><i>金</i><b>{rewards["gold"]} 文</b><small>金钱</small></span>')
    if rewards.get("exp"):
        entries.append(f'<span class="reward-chip currency"><i>历</i><b>{rewards["exp"]}</b><small>经验</small></span>')
    return "".join(entries) or '<span class="no-reward">本节点不直接发奖，推进剧情或开启后续入口</span>'


def collection_column(title: str, entries: list[dict], kind: str) -> str:
    cards = []
    for entry in entries:
        sources = "、".join(source["title"] for source in entry["sources"])
        meta = entry.get("kind") or entry.get("category") or "任务道具"
        cards.append(
            f'<li><span class="mini-seal {kind}">{escape(meta[:1])}</span><div><b>{escape(entry["name"])}</b>'
            f'<small>{escape(meta)} · {escape(sources)}</small></div></li>'
        )
    body = "".join(cards) or '<li class="empty-entry">当前正典任务未配置该类奖励</li>'
    return f'<section><h4>{escape(title)} <em>{len(entries)}</em></h4><ul>{body}</ul></section>'


def chapter_html(chapter: dict) -> str:
    npc_cards = "".join(
        f'<li><b>{escape(person["name"])}</b><span>{escape(person["role"])}</span></li>'
        for person in chapter["npcs"]
    )
    stage_cards = []
    for stage in chapter["stages"]:
        npc_text = "".join(
            f'<span title="{escape(person["role"], quote=True)}">{escape(person["name"])}</span>' for person in stage["npcs"]
        ) or '<span class="muted">场景调查 / 战斗推进</span>'
        maps = "".join(f'<span>{escape(name)}</span>' for name in stage["maps"]) or '<span>未标注地图</span>'
        stage_cards.append(f'''
          <article class="stage-card{' branch' if stage['branch'] else ''}">
            <div class="stage-index"><small>阶段</small><b>{stage['index']:02d}</b></div>
            <div class="stage-main">
              <header><div><span class="stage-kind">{'关键分支' if stage['branch'] else '主要任务'}</span><h3>{escape(stage['title'])}</h3></div><code>{escape(stage['id'])}</code></header>
              <p>{escape(stage['summary'] or '沿当前线索继续调查。')}</p>
              <div class="stage-facts"><div><b>会遇到</b>{npc_text}</div><div><b>活动区域</b>{maps}</div></div>
              <div class="completion"><span>完成锚点</span><strong>{escape(stage['tracker'] or stage['completion'])}</strong></div>
              <div class="stage-rewards"><span>阶段所得</span><div>{reward_block(stage['rewards'])}</div></div>
            </div>
          </article>''')

    other = "".join(
        f'<li><span>{escape(quest["kind"])}</span><b>{escape(quest["title"])}</b><small>{escape(" / ".join(quest["maps"]) or "开放世界节点")}</small></li>'
        for quest in chapter["otherQuests"]
    ) or '<li class="empty-entry">本章暂无额外任务</li>'
    notes = chapter["combatNotes"]
    combat = ""
    if notes:
        paragraphs = "".join(f"<p>{escape(note)}</p>" for note in notes)
        combat = ('<section class="journey"><div class="section-title"><span>实战</span>'
                  f'<h3>挑战与配装</h3></div>{paragraphs}</section>')
    searchable = " ".join([
        *notes, chapter["title"], chapter["objective"], chapter["question"],
        *(person["name"] + " " + person["role"] for person in chapter["npcs"]),
        *(stage["title"] + " " + stage["summary"] for stage in chapter["stages"]),
        *(entry["name"] for group in chapter["collection"].values() for entry in group),
    ]).lower()
    return f'''
    <article class="chapter-sheet" id="chapter-{chapter['number']}" data-chapter="{chapter['number']}" data-search="{escape(searchable, quote=True)}">
      <header class="chapter-head">
        <div class="chapter-mark"><span>第</span><b>{chapter['number']}</b><span>章</span></div>
        <div><div class="chapter-meta"><span>{escape(chapter['status'])}</span><span>{escape(' · '.join(chapter['regions']))}</span></div><h2>{escape(chapter['title'])}</h2><p>{escape(chapter['objective'])}</p></div>
        <blockquote><span>本章悬问</span>{escape(chapter['question'])}</blockquote>
      </header>
      {combat}
      <section class="npc-ledger"><div class="section-title"><span>人物</span><h3>本阶段关键 NPC</h3><small>正典角色表</small></div><ul>{npc_cards}</ul></section>
      <section class="journey"><div class="section-title"><span>行程</span><h3>主要任务与完成锚点</h3><small>{len(chapter['stages'])} 个关键节点</small></div><div class="stage-line">{''.join(stage_cards)}</div></section>
      <section class="collection"><div class="section-title"><span>所得</span><h3>本章可习得与可获得</h3><small>汇总本章已接入主线、支线与秘闻奖励</small></div>
        <div class="collection-grid">
          {collection_column('武功与心法', chapter['collection']['skills'], 'skill')}
          {collection_column('装备', chapter['collection']['equipment'], 'gear')}
          {collection_column('道具', chapter['collection']['items'], 'item')}
        </div>
        <details class="other-quests"><summary>查看本章其他可完成任务 <b>{len(chapter['otherQuests'])}</b></summary><ul>{other}</ul></details>
      </section>
    </article>'''


def open_world_html(data: dict) -> str:
    npcs = "".join(f"<span>{escape(name)}</span>" for name in data["npcs"]) or "<span>随线索逐步结识</span>"
    tasks = []
    for stage in data["stages"]:
        maps = " / ".join(name for name in stage["maps"] if name != "未关联地图") or "跨区域探索"
        tasks.append(
            f'<article><span>{stage["index"]:02d}</span><div><small>{escape(stage["unlock"])} · {escape(stage["kind"])} · {escape(maps)}</small>'
            f'<h3>{escape(stage["title"])}</h3><p>{escape(stage["summary"] or stage["tracker"] or "循江湖线索推进。")}</p>'
            f'<div class="world-rewards">{reward_block(stage["rewards"])}</div></div></article>'
        )
    searchable = " ".join(
        data["npcs"]
        + [stage["id"] + " " + stage["title"] + " " + stage["summary"] for stage in data["stages"]]
        + [entry["id"] + " " + entry["name"] for group in data["collection"].values() for entry in group]
    ).lower()
    return f'''
    <section class="open-world" id="open-world" data-chapter="world" data-search="{escape(searchable, quote=True)}">
      <header><div><span>自由探索任务总览</span><h2>开放世界奇遇</h2><p>包含 {data['independentCount']} 条从开局即可推进的全程开放长链，以及 {data['regionalCount']} 条随城市、村镇和门派区域开放后可自由完成的支线与秘闻；章节只标记最早开放阶段，不代表必须立刻完成。</p></div><b>∞</b></header>
      <div class="world-npcs"><strong>可能结识</strong>{npcs}</div>
      <div class="world-stage-list">{''.join(tasks)}</div>
      <div class="world-collection">
        {collection_column('可习得武功与心法', data['collection']['skills'], 'skill')}
        {collection_column('可获得装备', data['collection']['equipment'], 'gear')}
        {collection_column('可获得道具', data['collection']['items'], 'item')}
      </div>
    </section>'''


def main() -> None:
    chapters = build()
    open_world = build_open_world()
    counts = {
        "stages": sum(len(chapter["stages"]) for chapter in chapters) + len(open_world["stages"]),
        "npcs": len({person["name"] for chapter in chapters for person in chapter["npcs"]} | set(open_world["npcs"])),
        "skills": len({entry["id"] for chapter in chapters for entry in chapter["collection"]["skills"]} | {entry["id"] for entry in open_world["collection"]["skills"]}),
        "gear": len({entry["id"] for chapter in chapters for entry in chapter["collection"]["equipment"]} | {entry["id"] for entry in open_world["collection"]["equipment"]}),
        "items": len({entry["id"] for chapter in chapters for entry in chapter["collection"]["items"]} | {entry["id"] for entry in open_world["collection"]["items"]}),
    }
    nav = "".join(
        f'<button type="button" data-target="{chapter["number"]}"><span>{chapter["number"]:02d}</span>{escape(chapter["title"])}</button>'
        for chapter in chapters
    )
    payload = json.dumps({"chapters": chapters, "openWorld": open_world}, ensure_ascii=False).replace("</", r"<\/")
    replacements = {
        "__GENERATED_AT__": datetime.now().strftime("%Y-%m-%d %H:%M"),
        "__CHAPTER_COUNT__": str(len(chapters)), "__STAGE_COUNT__": str(counts["stages"]),
        "__NPC_COUNT__": str(counts["npcs"]), "__SKILL_COUNT__": str(counts["skills"]),
        "__GEAR_COUNT__": str(counts["gear"]), "__ITEM_COUNT__": str(counts["items"]),
        "__CHAPTER_NAV__": nav, "__STATIC_CHAPTERS__": "".join(chapter_html(chapter) for chapter in chapters),
        "__OPEN_WORLD__": open_world_html(open_world), "__PROGRESSION_DATA__": payload,
    }
    html = TEMPLATE.read_text(encoding="utf-8-sig")
    for marker, value in replacements.items():
        html = html.replace(marker, value)
    unresolved = [marker for marker in replacements if marker in html]
    if unresolved:
        raise ValueError(f"unresolved template markers: {unresolved}")
    OUTPUT.write_text(html, encoding="utf-8", newline="\n")
    print(
        f"Wrote {OUTPUT.relative_to(ROOT)}: {len(chapters)} chapters + open world, {counts['stages']} stages, "
        f"{counts['npcs']} NPCs, {counts['skills']} skills, {counts['gear']} equipment, {counts['items']} items"
    )


if __name__ == "__main__":
    main()
