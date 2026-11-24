from __future__ import annotations

import argparse
import json
import re
import shutil
from collections import deque
from datetime import datetime, timezone
from pathlib import Path


TEXT_SUFFIXES = {".gd", ".tscn", ".tres", ".godot", ".cfg", ".json"}
SKIP_SUFFIXES = {".import", ".tmp"}
RES_PATH_RE = re.compile(r"res://([^\"'\s\)\],]+)")
TOKEN_RE = re.compile(r"[A-Za-z][A-Za-z0-9_]{2,}")
EXT_RESOURCE_UID_RE = re.compile(r'(\[ext_resource\b[^\]\n]*?)\s+uid="uid://[^"]+"')
VOICE_GROUPS = ("ch1", "ch2", "ch3", "lin", "int")
DYNAMIC_DIRECTORY_EXACT = {
    "art/ui/button",
    "art/ui/field_hud/v1",
    "art/ui/quest/runtime_v1",
    "art/ui/skill/runtime_v2",
    "art/ui/skill/text_only_runtime_v1",
}
TRIAL_BLOCKED_DATA_IDS = {
    # These are awarded only after the trial's third-chapter boundary. Their
    # definitions remain in the desktop project but not in the trial PCK.
    "canghai_zhenyue_palms",
    "huilan_redirecting_art",
    "jingang_tempered_meridians",
    "wanxiang_breaking_sword",
    "xuanshuang_hidden_current",
}
TRIAL_BLOCKED_ART_PARTS = (
	"/background_chunks/world_map_jianghu_v11/desktop/",
    "/canghai_zhenyue_",
    "/huilan_redirecting_",
    "/jingang_tempered_",
    "/wanxiang_breaking_",
    "/xuanshuang_hidden_",
    "/bg_main_menu_gpt_v5.png",
    "/bg_main_menu_gpt_v6.png",
    "/bg_main_menu_gpt_v7_clean.png",
    "/bg_main_menu_v5.png",
    "/battle_arenas_v2/bg_battle_city_street_v1.jpg",
    "/battle_arenas_v2/bg_battle_snow_peak_v1.jpg",
    "/battle_arenas_v2/bg_battle_grassland_v1.jpg",
)
TOKEN_SCANNED_SCRIPTS = {
    "game_state.gd",
    "inventory.gd",
    "main_menu.gd",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build a clean Godot staging project for the chapters 1-3 WeChat trial.")
    parser.add_argument("--game-root", type=Path, default=Path(__file__).resolve().parents[1] / "game")
    parser.add_argument("--stage-root", type=Path)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def is_trial_scene(stem: str) -> bool:
    return (
        stem.startswith(("ch1_", "ch2_", "ch3_", "linxi_"))
        or stem in {"world_map_jianghu", "interior_inn_hall", "interior_martial_hall", "interior_bandit_cave"}
    )


def is_future_chapter_name(name: str) -> bool:
    return re.search(r"(?:^|_)(?:q_)?ch(?:[4-9]|[1-9][0-9])(?:_|$)", name) is not None


def is_allowed_data_file(path: Path, game_root: Path) -> bool:
    try:
        relative = path.relative_to(game_root / "data")
    except ValueError:
        return True
    if not relative.parts:
        return True
    category = relative.parts[0]
    stem = path.stem
    if stem in TRIAL_BLOCKED_DATA_IDS:
        return False
    if category == "scenes":
        return is_trial_scene(stem)
    if category == "chapters":
        return stem in {"chapter_1_content_plan", "chapter_2_content_plan", "chapter_3_content_plan"}
    if category == "quests":
        return stem.startswith(("q_ch1_", "q_ch2_", "q_ch3_", "q_secret_", "q_legend_"))
    # SceneRouter and the content catalog intentionally know about future
    # chapters.  Token scanning those scripts must not pull their runtime data
    # into the chapters 1-3 package.
    return not is_future_chapter_name(stem)


def is_allowed_art_file(path: Path, game_root: Path) -> bool:
    try:
        relative = "/" + path.relative_to(game_root).as_posix()
    except ValueError:
        return True
    if not relative.startswith("/art/"):
        return True
    return not any(part in relative for part in TRIAL_BLOCKED_ART_PARTS)


def is_allowed_dynamic_tree(relative_dir: str) -> bool:
    if relative_dir in DYNAMIC_DIRECTORY_EXACT:
        return True
    # Runtime builds animation file names below these concrete actor roots.
    # A reference to a child directory is safe; a reference to the entire
    # catalog root is not.
    for root in ("art/characters/weapon_variants", "art/sprites/battle"):
        if relative_dir.startswith(root + "/"):
            return True
    return False


def copyable(path: Path) -> bool:
    return (
        path.is_file()
        and path.stat().st_size > 0
        and path.suffix not in SKIP_SUFFIXES
        and not path.name.endswith(".import")
        and ".godot" not in path.parts
        and "build" not in path.parts
    )


def should_scan_data_tokens(path: Path, game_root: Path) -> bool:
    # Resource files form the authored dependency graph. Most scripts only
    # contain generic catalog examples or debug scanners; treating every word
    # in those files as a resource id drags the whole game into the trial.
    try:
        relative = path.relative_to(game_root / "data")
    except ValueError:
        relative = None
    if relative is not None and relative.parts and relative.parts[0] == "quests":
        if path.stem.startswith(("q_legend_", "q_secret_")):
            return False
    if path.suffix != ".gd":
        return True
    return path.name in TOKEN_SCANNED_SCRIPTS


def main() -> int:
    args = parse_args()
    game_root = args.game_root.resolve()
    build_root = (game_root / "build").resolve()
    stage_root = (args.stage_root or build_root / "wechat_stage").resolve()
    report_path = (args.report or build_root / "wechat_stage_manifest.json").resolve()
    if stage_root.parent != build_root or stage_root.name != "wechat_stage":
        raise SystemExit(f"Refusing unsafe stage path: {stage_root}")

    data_index: dict[str, Path] = {}
    for path in (game_root / "data").rglob("*.tres"):
        data_index.setdefault(path.stem, path.resolve())

    selected: set[Path] = set()
    queue: deque[Path] = deque()

    def add_file(path: Path) -> None:
        path = path.resolve()
        if (
            not copyable(path)
            or path in selected
            or not is_allowed_data_file(path, game_root)
            or not is_allowed_art_file(path, game_root)
        ):
            return
        try:
            path.relative_to(game_root)
        except ValueError:
            return
        selected.add(path)
        queue.append(path)

    def add_tree(root: Path) -> None:
        if not root.exists():
            return
        for path in root.rglob("*"):
            add_file(path)

    for root_file in ("project.godot", "export_presets.cfg", "default_bus_layout.tres", "icon.svg"):
        add_file(game_root / root_file)
    add_tree(game_root / "scripts")
    add_tree(game_root / "scenes")
    add_tree(game_root / "addons")

    for path in (game_root / "data" / "scenes").glob("*.tres"):
        if is_trial_scene(path.stem):
            add_file(path)
    for chapter in (1, 2, 3):
        add_file(game_root / "data" / "chapters" / f"chapter_{chapter}_content_plan.tres")
    for prefix in ("q_ch1_", "q_ch2_", "q_ch3_", "q_secret_", "q_legend_"):
        for path in (game_root / "data" / "quests").glob(f"{prefix}*.tres"):
            add_file(path)
    for directory in ("companions", "npcs", "statuses"):
        add_tree(game_root / "data" / directory)

    # Voice paths are resolved from dialog id/speaker at runtime and therefore
    # cannot be found by Godot's static dependency graph.
    for group in VOICE_GROUPS:
        add_tree(game_root / "art" / "audio" / "voices" / group)

    while queue:
        current = queue.popleft()
        if current.suffix not in TEXT_SUFFIXES:
            continue
        try:
            text = current.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for raw_res_path in RES_PATH_RE.findall(text):
            clean = raw_res_path.replace("\\", "/").rstrip(".,;")
            referenced = (game_root / clean).resolve()
            if referenced.is_dir():
                relative_dir = referenced.relative_to(game_root).as_posix().rstrip("/")
                if is_allowed_dynamic_tree(relative_dir):
                    add_tree(referenced)
            else:
                add_file(referenced)
        if current.parent == game_root / "data" / "skills":
            unique_vfx = game_root / "art" / "battle_vfx" / "skill_unique_v1" / f"vfx_{current.stem}_4frame_v1.png"
            add_file(unique_vfx)
        if should_scan_data_tokens(current, game_root):
            for token in TOKEN_RE.findall(text):
                indexed = data_index.get(token)
                if indexed is not None:
                    add_file(indexed)

    stripped_uid_hints = 0
    if not args.dry_run:
        if stage_root.exists():
            shutil.rmtree(stage_root)
        stage_root.mkdir(parents=True, exist_ok=True)
        for source in sorted(selected):
            relative = source.relative_to(game_root)
            destination = stage_root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
        # A clean staging import generates its own UID cache. Keep stable text
        # paths authoritative and remove copied UID hints so the exporter does
        # not emit hundreds of harmless "invalid UID" warnings.
        for destination in list(stage_root.rglob("*.tscn")) + list(stage_root.rglob("*.tres")):
            text = destination.read_text(encoding="utf-8", errors="ignore")
            rewritten, count = EXT_RESOURCE_UID_RE.subn(r"\1", text)
            if count > 0:
                destination.write_text(rewritten, encoding="utf-8")
                stripped_uid_hints += count

    selected_bytes = sum(path.stat().st_size for path in selected)
    all_runtime_files = [
        path for path in game_root.rglob("*")
        if copyable(path) and "screenshots" not in path.parts
    ]
    all_runtime_bytes = sum(path.stat().st_size for path in all_runtime_files)
    by_top: dict[str, dict[str, int]] = {}
    for path in selected:
        relative = path.relative_to(game_root)
        top = relative.parts[0]
        bucket = by_top.setdefault(top, {"files": 0, "bytes": 0})
        bucket["files"] += 1
        bucket["bytes"] += path.stat().st_size
    report = {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "scope": "wechat-trial-chapters-1-3",
        "stageRoot": str(stage_root),
        "selectedFiles": len(selected),
        "selectedBytes": selected_bytes,
        "selectedMiB": round(selected_bytes / 1024 / 1024, 2),
        "projectBytesWithoutScreenshots": all_runtime_bytes,
        "reductionPercent": round((1.0 - selected_bytes / max(1, all_runtime_bytes)) * 100.0, 2),
        "strippedUidHints": stripped_uid_hints,
        "byTopDirectory": by_top,
        "files": [str(path.relative_to(game_root)).replace("\\", "/") for path in sorted(selected)],
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({key: report[key] for key in ("scope", "selectedFiles", "selectedMiB", "reductionPercent", "stageRoot")}, ensure_ascii=False))
    print(f"Report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
