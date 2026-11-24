#!/usr/bin/env python3
"""Validate the offline chapter-story catalogue and its core branches."""

from __future__ import annotations

import json
import re
from pathlib import Path

from build_storyline_catalog import build as build_stories


ROOT = Path(__file__).resolve().parents[1]
HTML = ROOT / "docs" / "equipment-skill-catalog.html"
QUEST_HTML = ROOT / "docs" / "quest-catalog.html"
CHAPTER_ONE_RETIRED = {
    "q_ch1_main_01_thug",
    "q_ch1_main_02_qingfeng",
    "q_ch1_side_yuewuxing",
}
CHAPTER_ONE_RESOLVED = {
    "q_ch1_side_04_tiger_hunt": ("migrate", 5, ""),
    "q_ch1_side_05_ancestral_theft": ("merge", 6, "q_ch6_side_02_home_belongings"),
    "q_ch1_side_07_village_duel": ("merge", 1, "q_ch1_side_09_martial_hall"),
}


def fail(message: str) -> None:
    raise AssertionError(message)


def main() -> None:
    html = HTML.read_text(encoding="utf-8")
    if re.search(r"__[A-Z0-9_]+__", html):
        fail("generated catalogue still contains template markers")
    if re.search(r"\b(fetch\s*\(|XMLHttpRequest|<script[^>]+src=)", html, re.IGNORECASE):
        fail("offline catalogue must not depend on network scripts or XHR")

    match = re.search(
        r'<script id="catalogData" type="application/json">(.*?)</script>',
        html,
        re.DOTALL,
    )
    if not match:
        fail("catalogData JSON block missing")
    data = json.loads(match.group(1))
    quests = data.get("quests", [])
    retired = {quest["id"] for quest in quests if quest.get("retired")}
    if retired != {qid for story in build_stories() for qid in story.get("legacyQuestIds", [])}:
        fail(f"chapter-one compatibility quest set drifted: {sorted(retired)}")
    if any(quest["linked"] for quest in quests if quest.get("retired")):
        fail("compatibility-only quests must never be reported as live content")
    resolved = {quest["id"]: quest.get("resolution", {}) for quest in quests if quest.get("resolved")}
    if set(resolved) != set(CHAPTER_ONE_RESOLVED):
        fail(f"chapter-one resolved side-quest set drifted: {sorted(resolved)}")
    for quest_id, expected in CHAPTER_ONE_RESOLVED.items():
        decision = resolved[quest_id]
        actual = (decision.get("decision"), decision.get("targetChapter"), decision.get("replacementId"))
        if actual != expected:
            fail(f"{quest_id} resolution drifted: expected {expected}, got {actual}")
    if any(quest["linked"] for quest in quests if quest.get("resolved")):
        fail("merged or migrated quests must not be reported as live content")
    stories = data.get("stories", [])
    rebuilt = build_stories()
    if stories != rebuilt:
        fail("embedded story payload is stale; rebuild the catalogue")
    if [story["number"] for story in stories] != list(range(1, 9)):
        fail("story chapters must be ordered 1 through 8")
    expected_titles = ["林西村下山", "竹尾风波", "入派抉择", "洛阳奇遇", "古峰残雪"]
    if [story["title"] for story in stories[:5]] != expected_titles:
        fail("playable chapter titles drifted from the current narrative baseline")
    for story in stories:
        if not story["available"] or story["plannedStages"] or not story["maps"]:
            fail(f"playable chapter {story['number']} lost its route")
        if set(story["mainQuestIds"]) & set(story.get("legacyQuestIds", [])):
            fail(f"legacy quests leaked into chapter {story['number']}")
    if sum(len(story["sideQuestIds"]) for story in stories) != 34:
        fail("chapter side quest count drifted from the verified content plans")

    if "q_ch5_side_02_patrol_blades" not in stories[4]["sideQuestIds"]:
        fail("chapter five lost the snow patrol quest")

    chapter_one_text = json.dumps(stories[0], ensure_ascii=False)
    if "悦无姮" in chapter_one_text or "凌月信物" in chapter_one_text:
        fail("legacy Yue Wuheng rescue content leaked into chapter 1")
    for story in stories:
        if not story["stages"] or not story["maps"] or not story["characters"]:
            fail(f"implemented chapter {story['number']} lacks stages, maps or characters")
        if any(not stage["summary"] for stage in story["stages"]):
            fail(f"implemented chapter {story['number']} contains an empty stage summary")

    core = {
        2: ("ch2_rescue_victory", "n4", 2),
        3: ("ch3_faction_choice", "start", 6),
        4: ("ch4_canal_result", "b", 2),
        5: ("ch5_disclosure_choice", "start", 2),
        7: ("ch7_route_choice", "choice", 2),
    }
    for number, (dialog_id, node_id, option_count) in core.items():
        matches = [choice for choice in stories[number - 1]["choices"] if choice.get("dialogId") == dialog_id and choice.get("nodeId") == node_id]
        if len(matches) != 1 or len(matches[0]["options"]) != option_count:
            fail(f"chapter {number} core choice {dialog_id}/{node_id} is incomplete")
        if any(not option["impact"] for option in matches[0]["options"]):
            fail(f"chapter {number} core choice has an option without persistent impact")
        if not matches[0]["converges"]:
            fail(f"chapter {number} core choice lacks a convergence note")

    if data["summary"]["stories"] != len(stories):
        fail("story summary count does not match payload")
    if data["summary"]["storiesImplemented"] != len(stories):
        fail("implemented story summary differs from chapter records")
    if data["summary"]["storyChoices"] != sum(story["choiceCount"] for story in stories):
        fail("story choice summary count does not match payload")
    if data["summary"]["questsLinked"] != sum(quest["linked"] for quest in quests):
        fail("linked quest summary count does not match current-canon payload")
    static_pattern = r'<article\b[^>]*\bdata-type="story"'
    if len(re.findall(static_pattern, html)) != len(stories):
        fail("static no-JavaScript story cards do not match payload")
    for key in ("equipment", "skills", "quests"):
        if not data.get(key):
            fail(f"existing {key} catalogue regressed to empty")

    quest_html = QUEST_HTML.read_text(encoding="utf-8")
    for quest_id in CHAPTER_ONE_RETIRED:
        pattern = rf'data-search="[^"]*\b{re.escape(quest_id)}\b[^"]*"[^>]*data-link="兼容旧线"'
        if not re.search(pattern, quest_html):
            fail(f"quest archive does not mark {quest_id} as compatibility-only")
    for quest_id in CHAPTER_ONE_RESOLVED:
        pattern = rf'data-search="[^"]*\b{re.escape(quest_id)}\b[^"]*"[^>]*data-link="规划已处理"'
        if not re.search(pattern, quest_html):
            fail(f"quest archive does not mark {quest_id} as resolved planning")

    static_story_cards = len(re.findall(static_pattern, html))
    implemented_count = sum(story["implementation"] == "implemented" for story in stories)
    partial_count = sum(story["implementation"] == "partial" for story in stories)
    planned_count = sum(story["implementation"] == "planned" for story in stories)
    print(
        "Story catalogue PASS: "
        f"chapters={len(stories)} implemented={implemented_count} partial={partial_count} planned={planned_count} "
        f"choices={data['summary']['storyChoices']} "
        f"static_cards={static_story_cards}"
    )


if __name__ == "__main__":
    main()
