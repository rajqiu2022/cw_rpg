"""Build the desktop resource manifest from Godot runtime roots and byte-checked receipts."""

import argparse
import collections
import os
import re
import shutil
import struct
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
TEXT = {
    ".gd",
    ".gdshader",
    ".gdshaderinc",
    ".tscn",
    ".tres",
    ".json",
    ".cfg",
    ".godot",
    ".import",
}
ASSET = TEXT | {
    ".png",
    ".jpg",
    ".webp",
    ".svg",
    ".ogg",
    ".mp3",
    ".wav",
    ".ttf",
    ".otf",
    ".bin",
    ".res",
    ".rf",
    ".bytes",
    ".dat",
    ".mask",
    ".exr",
    ".woff2",
}
PATH = re.compile(rb"res://([a-zA-Z0-9_./%+@-]+)")
LOCAL = re.compile(rb"""["']([a-zA-Z0-9_./%+-]+\.[a-zA-Z0-9_]+)["']""")


def collect(work, city_paths):
    files = {}
    queue = collections.deque()
    allowed_cache = {
        ".ctex",
        ".sample",
        ".oggvorbisstr",
        ".mp3str",
        ".fontdata",
        ".translation",
        ".res",
        ".s3tc",
        ".scn",
    }

    def archived(key):
        low = key.lower()
        return (
            any(
                x in low
                for x in [
                    "/capture/",
                    "/prototypes/",
                    "/reference/",
                    "/primary/",
                    "/before_files/",
                    "/screenshots/",
                    "/.godot/editor/",
                ]
            )
            or re.search(r"world_map_v15_complete_v[5-8]/", low)
            or (
                low.startswith("build/")
                and any(
                    x in low.split("/")[1]
                    for x in [
                        "_regional",
                        "_qa",
                        "_proposal",
                        "_preview",
                        "before_grey",
                        "before_roof",
                        "trial_preview",
                        "material_candidate",
                    ]
                )
            )
            or "/luoyang_modular_v3_street_detail_proposal/" in low
            or "/luoyang_modular_v3_wall_street_proposal/" in low
        )

    def add(key, src=None):
        key = key.replace("\\", "/").strip("/")
        if not key or key in files or ".." in key.split("/"):
            return
        extension = Path(key).suffix.lower()
        if not src and (
            archived(key)
            or extension
            not in ASSET | allowed_cache | {".sha256", ".tsv", ".txt", ".rgf"}
        ):
            return
        path = src or GAME / key
        if not path.is_file():
            return
        files[key] = path
        suffix = path.suffix.lower()
        if (suffix in TEXT or suffix == ".bin") and not re.search(
            r"/(?:[^/]*backup[^/]*|snapshots?|old_sources?)/", key, re.I
        ):
            queue.append((key, path))
        if suffix in ASSET and (GAME / (key + ".import")).is_file():
            add(key + ".import")

    def seed(folder, skip):
        for base, dirs, names in os.walk(GAME / folder):
            dirs[:] = [d for d in dirs if d not in skip]
            for name in names:
                p = Path(base) / name
                if p.suffix.lower() in ASSET and p.suffix != ".import":
                    add(p.relative_to(GAME).as_posix())

    for directory, skip in [
        ("scripts", {"dev", "tools", "drafts"}),
        ("data", {"maps"}),
        ("scenes", {"drafts"}),
        ("config", set()),
        ("art", {"maps", "candidates", "_backup"}),
        ("shaders", set()),
    ]:
        seed(directory, skip)
    for path in [
        "project.godot",
        "icon.svg",
        "default_bus_layout.tres",
        ".godot/uid_cache.bin",
        ".godot/scene_groups_cache.cfg",
    ]:
        add(path)
    original = (GAME / ".godot/global_script_class_cache.cfg").read_text(
        encoding="utf-8"
    )

    def canonical(m):
        key = m[1]
        if "/scripts/" in key and key.startswith("build/"):
            p = "scripts/" + key.rsplit("/scripts/", 1)[1]
            if (GAME / p).is_file():
                key = p
        add(key)
        return '"path": "res://' + key + '"'

    cache = work / "global_script_class_cache.cfg"
    cache.write_text(
        re.sub(r'"path": "res://([^"]+)"', canonical, original), encoding="utf-8"
    )
    add(".godot/global_script_class_cache.cfg", cache)
    while queue:
        key, p = queue.popleft()
        if key == ".godot/uid_cache.bin" or (
            p.suffix == ".json"
            and any(
                x in p.name.lower()
                for x in [
                    "proof",
                    "receipt",
                    "read_only",
                    "readonly",
                    "art_contract",
                    "source_contract",
                    "executed_builder",
                    "terminal_qa",
                    "audit",
                    "rollout_report",
                    "handoff",
                    "capture_manifest",
                ]
            )
        ):
            continue
        raw = p.read_bytes()
        if p.suffix == ".import":
            # Quoted remap paths may contain spaces and CJK filenames.
            for dest in re.findall(
                r'^path(?:\.[^=]+)?="res://([^"]+)"', raw.decode("utf-8-sig"), re.M
            ):
                add(dest)
                if dest not in files:
                    raise FileNotFoundError(f"{key} -> {dest}")
            continue
        refs = {m.decode() for m in PATH.findall(raw)}
        parents = {key.rpartition("/")[0]}
        for target in refs:
            if target.endswith("/"):
                parents.add(target.rstrip("/"))
            else:
                add(target)
        # Builders frequently form filenames with ROOT + "name.bin" (including pinned metadata).
        if p.suffix in {".gd", ".json"}:
            for m in set(LOCAL.findall(raw)):
                rel = m.decode()
                if rel.startswith((".", "/")) or ":" in rel:
                    continue
                if Path(rel).suffix.lower() not in ASSET:
                    continue
                for parent in parents:
                    target = (parent + "/" + rel).strip("/")
                    if "%" in target:
                        glob = re.sub(r"%[-0-9.]*[ds]", "*", target)
                        if "*" in glob:
                            for match in GAME.glob(re.sub(r"\*+", "*", glob)):
                                add(match.relative_to(GAME).as_posix())
                    else:
                        add(target)
    # These byte-checked inputs include historic snapshots and native meshes.
    # Preserve their exact content, without treating evidence files as new entry points.
    for key in city_paths.read_text("utf-8").splitlines():
        if key.startswith(("/", "\\")) or ":" in key or ".." in key.split("/"):
            raise ValueError(f"Invalid city identity path: {key}")
        path = GAME / key
        if not path.is_file():
            raise FileNotFoundError(path)
        files.setdefault(key, path)
    # Validate import remaps after merging the independently enumerated city leaves.
    for key, source in list(files.items()):
        if not key.endswith(".import"):
            continue
        for dest in re.findall(
            r'^path(?:\.[^=]+)?="res://([^"]+)"', source.read_text("utf-8-sig"), re.M
        ):
            compiled = GAME / dest
            if not compiled.is_file():
                raise FileNotFoundError(f"{key} -> {dest}")
            files.setdefault(dest, compiled)
    return files


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--work", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--editor", type=Path, required=True)
    parser.add_argument("--template", type=Path, required=True)
    parser.add_argument("--list-only", action="store_true")
    a = parser.parse_args()
    a.work = a.work.resolve()
    a.output = a.output.resolve()
    packer_project = a.work / "project.godot"
    settings = "config_version=5\n"
    if a.work == a.output or (
        packer_project.exists() and packer_project.read_text("utf8") != settings
    ):
        parser.error("Select a separate scratch directory for --work.")
    with a.template.open("rb") as template:
        template.seek(0x3C)
        header = template.read(4)
        if len(header) != 4:
            parser.error("Invalid Windows template.")
        template.seek(struct.unpack("<I", header)[0])
        if template.read(6) != b"PE\0\0\x64\x86":
            parser.error("The Windows template must be an AMD64 executable.")
    a.work.mkdir(parents=True, exist_ok=True)
    a.output.mkdir(parents=True, exist_ok=True)
    city_paths = a.work / "city-paths.txt"
    # Running the source enumerator uses its own profile, separate from the player's slots.
    env = dict(
        os.environ,
        APPDATA=str(a.work / "profile/roaming"),
        LOCALAPPDATA=str(a.work / "profile/local"),
    )
    subprocess.run(
        [
            str(a.editor),
            "--headless",
            "--path",
            str(GAME),
            "--script",
            str(ROOT / "scripts/windows_city_resources.gd"),
            "--",
            str(city_paths),
        ],
        check=True,
        env=env,
    )
    files = collect(a.work, city_paths)
    manifest = a.work / "files.tsv"
    with manifest.open("w", encoding="utf-8", newline="\n") as f:
        for k, p in sorted(files.items()):
            f.write(k + "\t" + p.as_posix() + "\n")
    sizes = collections.Counter()
    for k, p in files.items():
        sizes[k.partition("/")[0]] += p.stat().st_size
    print(len(files), dict(sizes), flush=True)
    if a.list_only:
        return
    packer_project.write_text(settings, encoding="utf-8")
    temp = a.work / "YunYing.pck"
    subprocess.run(
        [
            str(a.editor),
            "--headless",
            "--path",
            str(a.work),
            "--script",
            str(ROOT / "scripts" / "pack_windows_runtime.gd"),
            "--",
            str(manifest),
            str(temp),
        ],
        check=True,
    )
    shutil.move(str(temp), str(a.output / "YunYing.pck"))
    shutil.copyfile(a.template, a.output / "YunYing.exe")
    shutil.copyfile(a.work / "ENGINE-NOTICES.txt", a.output / "ENGINE-NOTICES.txt")


if __name__ == "__main__":
    main()
