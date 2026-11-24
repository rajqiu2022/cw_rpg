#!/usr/bin/env python3
"""Build the chapter-story payload used by the offline Jianghu catalogue.

The human-authored storyline file establishes the current narrative canon and
explicitly separates playable content from later design. Live QuestDef and
DialogNode resources are then resolved and validated so the webpage cannot
silently drift away from the game data.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from build_quest_catalog import build as build_quests, string_array


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "game" / "data"
STORYLINE = ROOT / "docs" / "storyline-data.json"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig")


def dialog_files() -> dict[str, Path]:
    result: dict[str, Path] = {}
    for path in sorted((DATA / "dialogs").glob("*.tres")):
        source = read(path)
        match = re.search(r'(?m)^dialog_id\s*=\s*&?"([^"]+)"', source)
        if match:
            result[match.group(1)] = path
    return result


def scene_index() -> dict[str, dict]:
    result: dict[str, dict] = {}
    for path in sorted((DATA / "scenes").glob("*.tres")):
        source = read(path)
        scene_match = re.search(r'(?m)^scene_id\s*=\s*&?"([^"]+)"', source)
        if not scene_match:
            continue
        name_match = re.search(r'(?m)^display_name\s*=\s*"([^"]+)"', source)
        scene_id = scene_match.group(1)
        result[scene_id] = {
            "id": scene_id,
            "name": name_match.group(1) if name_match else scene_id,
            "source": path.relative_to(ROOT).as_posix(),
        }
    return result


def validate_dialog_choice(dialog_id: str, node_id: str, expected: list[str], dialogs: dict[str, Path]) -> str:
    path = dialogs.get(dialog_id)
    if path is None:
        raise ValueError(f"story choice references missing dialog: {dialog_id}")
    source = read(path)
    target = None
    for block in re.split(r"(?=\n\[sub_resource)", source):
        match = re.search(r'(?m)^node_id\s*=\s*&?"([^"]+)"', block)
        if match and match.group(1) == node_id:
            target = block
            break
    if target is None:
        raise ValueError(f"story choice references missing node: {dialog_id}/{node_id}")
    actual = re.findall(r'"text"\s*:\s*"([^"]+)"', target)
    if actual != expected:
        raise ValueError(
            f"story choice options drifted for {dialog_id}/{node_id}: "
            f"expected {expected!r}, got {actual!r}"
        )
    return path.relative_to(ROOT).as_posix()


def quest_stage(quest: dict, branch: bool = False) -> dict:
    maps = [name for name in quest["maps"] if name and name != "未关联地图"]
    triggers = [entry["label"] for entry in quest["triggers"]]
    return {
        "id": quest["id"],
        "title": quest["title"],
        "summary": quest["descriptions"]["active"] or quest["descriptions"]["locked"],
        "tracker": quest["descriptions"]["tracker"],
        "maps": maps,
        "triggers": triggers,
        "linked": bool(quest["linked"]),
        "branch": branch,
        "source": quest["source"],
    }


def build() -> list[dict]:
    payload = json.loads(read(STORYLINE))
    chapters = payload.get("chapters", [])
    if [chapter.get("number") for chapter in chapters] != list(range(1, 9)):
        raise ValueError("story chapters must be unique and ordered from 1 through 8")

    quests = {quest["id"]: quest for quest in build_quests()}
    dialogs = dialog_files()
    scenes = scene_index()
    stories: list[dict] = []
    implemented_titles = {1: "林西村下山", 2: "竹尾风波", 3: "入派抉择", 4: "洛阳奇遇", 5: "古峰残雪", 6: "归村问师"}

    for raw in chapters:
        chapter = dict(raw)
        number = int(chapter["number"])
        implementation = chapter["implementation"]
        if implementation not in {"implemented", "partial", "planned"}:
            raise ValueError(f"chapter {number} has invalid implementation state: {implementation}")
        if number <= 5 and chapter["title"] != implemented_titles[number]:
            raise ValueError(f"chapter {number} must use current playable title {implemented_titles[number]}")
        if number <= 5 and implementation != "implemented":
            raise ValueError(f"chapter {number} is playable and must be marked implemented")
        main_ids = chapter.get("mainQuestIds", [])
        plan = read(DATA / "chapters" / f"chapter_{number}_content_plan.tres")
        # The plan lists IDs. The story follows the playable order (canal before temple).
        if sorted(main_ids) != sorted(string_array(plan, "main_quest_ids")):
            raise ValueError(f"chapter {number} main quest membership differs from the game")
        chapter["sideQuestIds"] = string_array(plan, "side_quest_ids")
        branch_ids = chapter.get("branchQuestIds", [])
        legacy_ids = chapter.get("legacyQuestIds", [])
        missing = [quest_id for quest_id in main_ids + branch_ids + legacy_ids if quest_id not in quests]
        if missing:
            raise ValueError(f"chapter {number} references missing quests: {', '.join(missing)}")
        stages = [quest_stage(quests[quest_id]) for quest_id in main_ids]
        branch_stages = [quest_stage(quests[quest_id], True) for quest_id in branch_ids]
        if implementation in {"implemented", "partial"} and (not stages or not all(stage["linked"] for stage in stages)):
            raise ValueError(f"{implementation} chapter {number} has an unlinked or empty main quest chain")
        if implementation == "planned" and main_ids:
            raise ValueError(f"planned chapter {number} must not present legacy QuestDef rows as current stages")

        scene_ids = chapter.get("mainSceneIds", [])
        missing_scenes = [scene_id for scene_id in scene_ids if scene_id not in scenes]
        if missing_scenes:
            raise ValueError(f"chapter {number} references missing scenes: {', '.join(missing_scenes)}")
        if implementation in {"implemented", "partial"} and not scene_ids:
            raise ValueError(f"{implementation} chapter {number} must list its reachable main scenes")

        choices = chapter.get("choices", [])
        for choice in choices:
            if len(choice.get("options", [])) < 2:
                raise ValueError(f"chapter {number} choice {choice.get('title')} needs at least two options")
            if choice.get("dialogId"):
                source = validate_dialog_choice(
                    choice["dialogId"],
                    choice["nodeId"],
                    [option["text"] for option in choice["options"]],
                    dialogs,
                )
                if source not in chapter["sources"]:
                    chapter["sources"].append(source)

        for source in chapter.get("sources", []):
            if not (ROOT / source).exists():
                raise ValueError(f"chapter {number} references missing source: {source}")
        if not chapter.get("regions") or not chapter.get("characters") or not chapter.get("playerActions"):
            raise ValueError(f"chapter {number} is missing regions, characters or player actions")

        category_by_state = {"implemented": "已实装", "partial": "制作中", "planned": "剧情规划"}
        status_by_state = {"implemented": "已实装", "partial": "部分实装", "planned": "剧情规划"}
        chapter.update({
            "id": f"story_chapter_{number}",
            "type": "story",
            "name": chapter["title"],
            "chapter": f"第{number}章",
            "chapterSort": number,
            "group": f"第{number}章",
            "category": category_by_state[implementation],
            "statusLabel": status_by_state[implementation],
            "available": implementation == "implemented",
            "stages": stages,
            "branchStages": branch_stages,
            "plannedStages": chapter.get("plannedStages", []),
            "maps": [scenes[scene_id] for scene_id in scene_ids],
            "legacyQuestCount": len(legacy_ids),
            "choiceCount": len(choices),
        })
        stories.append(chapter)
    return stories


if __name__ == "__main__":
    result = build()
    print(json.dumps(result, ensure_ascii=False, indent=2))
