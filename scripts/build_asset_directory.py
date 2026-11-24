"""Build a read-only inventory of desktop art and the local WeChat trial snapshots."""
from __future__ import annotations

import csv
import hashlib
import json
import os
import re
from collections import Counter, defaultdict, deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
OUTPUT = ROOT / "assets/catalog/resource_directory"
ART_SUFFIXES = {
    ".png", ".jpg", ".jpeg", ".webp", ".svg", ".gif", ".bmp", ".wav", ".ogg",
    ".mp3", ".flac", ".ttf", ".otf", ".res", ".tres", ".rf", ".gdshader",
    ".json", ".bin",
}
TEXT_SUFFIXES = {".gd", ".gdshader", ".tscn", ".tres", ".json", ".cfg", ".godot"}
RESOURCE_PATH = re.compile(rb"res://([^\x00-\x20\x22\x27,\)\]\}]+)")
ART_PATH = re.compile(rb'"(?:game/)?(art/[^\x00-\x20\x22\x27,\)\]\}]+)')
GROUPS = {
    "battle_vfx": "特效", "ui": "UI", "icons": "UI", "fonts": "UI", "loading": "UI",
    "maps": "场景地图", "background_chunks": "场景地图", "backgrounds": "场景地图",
    "modules": "场景地图", "props": "场景地图", "navigation_masks": "场景地图",
    "masks": "场景地图", "characters": "角色", "portraits": "角色", "sprites": "角色",
    "external": "外部资源",
}
MOBILE_PACKS = GAME / "build/wechat_pack_projects"
MOBILE_STAGE = GAME / "build/wechat_stage"
MOBILE_WRAPPER = GAME / "build/wechat_native_trial_v2"


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def walk(base: Path):
    """List files without visiting cache directories or junctions."""
    for directory, children, files in os.walk(base):
        children[:] = [
            n for n in children
            if not n.startswith(".") and not (Path(directory) / n).is_symlink()
        ]
        for name in files:
            yield Path(directory) / name


def is_art(path: Path) -> bool:
    return path.suffix.lower() in ART_SUFFIXES and not path.name.endswith(".meta.json")


def game_files(base: Path):
    for path in walk(base / "art"):
        if is_art(path):
            yield path.relative_to(base).as_posix(), path


def category(key: str) -> str:
    parts = key.split("/")
    if len(parts) < 2:
        return "其他"
    if parts[1] == "audio":
        return {"bgm": "音乐", "voices": "配音", "ambience": "环境音"}.get(parts[2], "音效")
    if key.startswith("art/backgrounds/bg_main_menu") or key.startswith("art/backgrounds/main_menu/"):
        return "UI"
    return GROUPS.get(parts[1], "其他")


def digest(path: Path) -> str:
    with path.open("rb") as handle:
        return hashlib.file_digest(handle, "sha256").hexdigest()


def scan_references(art_keys: set[str]):
    """Follow literal manifests and helpers linked by project code and authored data."""
    exact, prefixes = defaultdict(set), defaultdict(set)
    queue = deque([GAME / "project.godot"])
    for name in ("data", "scripts", "scenes", "config", "shaders"):
        for path in walk(GAME / name):
            parts = path.relative_to(GAME).parts
            if path.suffix in TEXT_SUFFIXES and not {"drafts", "dev", "tests"}.intersection(parts):
                queue.append(path)
    visited = set()
    while queue:
        path = queue.popleft()
        if path in visited or not path.is_file():
            continue
        visited.add(path)
        content = path.read_bytes()
        source = rel(path)
        keys = set(RESOURCE_PATH.findall(content))
        if path.suffix == ".json" and b'art/' in content:
            keys.update(ART_PATH.findall(content))
        for match in keys:
            key = match.decode("utf-8", errors="replace").rstrip(":;>")
            if ".." in key.split("/") or "\\" in key:
                continue
            if key in art_keys:
                exact[key].add(source)
            elif key.startswith("art/") and key.endswith("/") and len(key.strip("/").split("/")) >= 3:
                prefixes[key].add(source)
            target = GAME / key
            if key.startswith(("build/", "art/", "scenes/drafts/")) and target.suffix in TEXT_SUFFIXES and target not in visited:
                if target.is_file():
                    queue.append(target)
    return exact, prefixes


def desktop_channel(key: str) -> str:
    if key.startswith("art/background_chunks/") and "/desktop/" in key:
        return "桌面分块"
    if key.startswith("art/background_chunks/") and "/mobile/" in key:
        return "轻量分块，桌面也可回退"
    return ""


def reference(key: str, exact: dict, prefixes: dict):
    if key in exact:
        return "静态路径", sorted(exact[key])
    parts = key.split("/")
    matches = set()
    for i in range(3, len(parts)):
        matches.update(prefixes.get("/".join(parts[:i]) + "/", ()))
    if matches:
        return "有目录入口，逐件待核", sorted(matches)
    return "待核", []


def write_rows(name: str, header: list[str], rows) -> None:
    with (OUTPUT / name).open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(header)
        writer.writerows(rows)


def source_examples(sources) -> str:
    return " | ".join(sorted(sources)[:6])


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    desktop = dict(game_files(GAME))
    mobile = defaultdict(list)
    if MOBILE_PACKS.is_dir():
        for pack in sorted(MOBILE_PACKS.iterdir()):
            if not pack.is_dir():
                continue
            for key, path in game_files(pack):
                mobile[key].append((pack.name, path))
    for key, path in game_files(MOBILE_STAGE):
        if key not in mobile:
            mobile[key].append(("staging（未在分包目录找到）", path))
    exact, prefixes = scan_references(set(desktop))
    sheets = defaultdict(list)
    stats = Counter()
    map_packs = defaultdict(Counter)
    map_pins = defaultdict(set)
    for key in sorted(desktop.keys() | mobile.keys()):
        pc = desktop.get(key)
        phone = mobile.get(key, [])
        tag, refs = reference(key, exact, prefixes)
        pc_size = pc.stat().st_size if pc else 0
        state = desktop_channel(key)
        code = category(key)
        if pc and phone:
            # Compare every visible pack copy. A same-name variant needs its own path.
            same = all(
                pc_size == p.stat().st_size and digest(pc) == digest(p) for _, p in phone
            )
            sheet = "shared" if same else "mobile"
            relation = "同路径同字节" if same else "同路径，版本不同"
        elif phone:
            sheet, relation = "mobile", "仅在微信快照中找到"
        elif tag != "待核" or state:
            sheet, relation = "pc", "只在桌面源工程找到"
        else:
            sheet, relation = "review", "微信快照未找到"
        stats[sheet] += 1
        if key.startswith("art/maps/") and pc:
            parts = key.split("/")
            group = "/".join(parts[:4]) if len(parts) > 4 else "/".join(parts[:3])
            counts = map_packs[group]
            counts["files"] += 1
            counts["bytes"] += pc_size
            counts[tag] += 1
            counts["mobile"] += bool(phone)
            map_pins[group].update(refs)
            # Large map captures and tiled terrain are reusable as packs.
            # Keep individual rows for top-level entries and phone variants.
            if not phone and (len(parts) > 4 or key not in exact):
                stats["map_grouped"] += 1
                continue
        sheets[sheet].append([
            code, tag if pc else "快照内实物", relation, state,
            "res://" + key, rel(pc) if pc else "",
            " | ".join(rel(p) for _, p in phone),
            " | ".join(name for name, _ in phone),
            pc_size if pc else "", " | ".join(str(p.stat().st_size) for _, p in phone),
            len(refs), source_examples(refs),
        ])
    for folder in ("images", "audio"):
        for file in sorted(walk(MOBILE_WRAPPER / folder)):
            if not is_art(file):
                continue
            sheets["mobile"].append([
                "音效" if folder == "audio" else "UI", "微信原生试验外壳",
                "微信外壳资源", "", "", "", rel(file), "wechat_native_trial_v2",
                "", file.stat().st_size, 0, "",
            ])
            stats["wrapper"] += 1
    fields = [
        "类别", "桌面引用证据", "平台关系", "分支说明", "逻辑路径", "桌面文件路径",
        "微信快照文件路径", "微信包", "桌面字节", "微信字节", "引用源数", "引用入口示例",
    ]
    for name in ("pc", "mobile", "shared", "review"):
        write_rows(name + ".csv", fields, sorted(sheets[name]))
    write_rows(
        "map-packs.csv",
        ["桌面地图目录", "资源数", "总字节", "完整路径引用数", "目录入口数", "待核数", "微信快照同路径数", "引用源数", "引用入口示例"],
        (
            [group, row["files"], row["bytes"], row["静态路径"], row["有目录入口，逐件待核"],
             row["待核"], row["mobile"], len(map_pins[group]), source_examples(map_pins[group])]
            for group, row in sorted(map_packs.items())
        ),
    )
    archive = ROOT / "assets/retained/20261109/restore-manifest.json"
    archived = json.loads(archive.read_text(encoding="utf-8-sig")) if archive.is_file() else []
    write_rows("archive.csv", ["原路径", "归档路径", "字节", "SHA256"], (
        [item["original"], item["archived"], item["bytes"], item["sha256"]] for item in archived
    ))
    summary = {
        "desktop_art": len(desktop), "wechat_snapshot_art_paths": len(mobile),
        "classified_paths": dict(sorted(stats.items())),
        "csv_rows": {name: len(sheets[name]) for name in ("pc", "mobile", "shared", "review")},
        "map_pack_groups": len(map_packs), "archived_files": len(archived),
    }
    (OUTPUT / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

