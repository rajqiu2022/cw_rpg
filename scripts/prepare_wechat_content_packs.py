from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from pathlib import Path


PACK_IDS = ("common", "chapter1_start", "chapter1_late", "chapter2", "chapter3")
CHAPTER3_MARKERS = (
    "ch3_", "wulin", "huashan", "wudang", "gufeng", "mingwu", "examiner",
)
CHAPTER2_MARKERS = (
    "ch2_", "lingyue", "masked_killer", "river_camp", "bandit_cave",
)
CHAPTER1_LATE_MARKERS = (
    "ch1_s2_", "ch1_s3_", "ch1_s4_", "ch1_zhuwei", "ch1_forest",
    "zhuwei", "west_ruin", "ruin_inner", "beast_cave", "cave_deep",
    "cave_mine", "cave_water", "zhao_wuji", "zhao_", "wild_wolf", "dojo_",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Partition the WeChat trial staging project into common and chapter art packs.")
    parser.add_argument("--game-root", type=Path, default=Path(__file__).resolve().parents[1] / "game")
    parser.add_argument("--cdn-base-url", default="http://127.0.0.1:8000/packs/")
    parser.add_argument("--finalize-only", action="store_true")
    return parser.parse_args()


def pack_owner(relative: str) -> str:
    value = relative.replace("\\", "/")
    lower = value.lower()
    if not lower.startswith("art/"):
        return "common"
    if lower.startswith(("art/ui/", "art/fonts/", "art/audio/free/", "art/loading/")):
        return "common"
    if lower.startswith("art/background_chunks/world_map_jianghu_v11/mobile/"):
        return "common"
    if lower.startswith("art/audio/bgm/"):
        if any(marker in lower for marker in ("cave_ominous", "forest_mystery", "market_lively", "battle_boss")):
            return "chapter1_late"
        if "battle_river" in lower:
            return "chapter2"
        if "city_ceremony" in lower:
            return "chapter3"
        return "chapter1_start"
    if lower.startswith("art/audio/voices/"):
        parts = lower.split("/")
        group = parts[3] if len(parts) > 3 else ""
        if group == "ch3":
            return "chapter3"
        if group == "ch2":
            return "chapter2"
        if group == "int":
            return "chapter1_late"
        if group == "ch1" and any(marker in lower for marker in CHAPTER1_LATE_MARKERS):
            return "chapter1_late"
        return "chapter1_start"
    if any(marker in lower for marker in ("protagonist", "hero_idle_")):
        return "common"
    if any(marker in lower for marker in ("weapon_variants/lengguyun", "standard_v5/lengguyun")):
        return "chapter1_start"
    if lower.startswith("art/battle_vfx/weapon_tiers_v1/"):
        if "tier3" in lower:
            return "chapter3"
        if "tier2" in lower:
            return "chapter2"
        return "chapter1_start"
    if lower.startswith("art/battle_vfx/skill_unique_v1/"):
        if any(marker in lower for marker in ("shadow_swallow",)):
            return "chapter3"
        if any(marker in lower for marker in ("bamboo_rain", "circling_breath")):
            return "chapter2"
        if any(marker in lower for marker in CHAPTER1_LATE_MARKERS):
            return "chapter1_late"
        return "chapter1_start"
    if lower.startswith("art/sprites/battle/candidates/masked_bandit"):
        return "chapter2"
    if lower.startswith("art/backgrounds/"):
        if "bg_main_menu" in lower:
            return "common"
        if any(marker in lower for marker in ("bg_world_map_jianghu_v11_2304", "world_map_jianghu_walk_v11", "bg_battle_bamboo_day_v1")):
            # These two are static ext_resources of common PackedScenes.
            return "common"
        if any(marker in lower for marker in ("bg_world_map", "bg_battle_")):
            return "chapter1_start"
        if "bg_interior_bandit_cave" in lower:
            return "chapter1_late"
        if any(marker in lower for marker in CHAPTER3_MARKERS):
            return "chapter3"
        if any(marker in lower for marker in CHAPTER2_MARKERS):
            return "chapter2"
        if any(marker in lower for marker in CHAPTER1_LATE_MARKERS) or lower.startswith("art/backgrounds/bg_interior_"):
            return "chapter1_late"
        return "chapter1_start"
    if lower.startswith("art/navigation_masks/"):
        if "world_map_jianghu_walk_v11" in lower:
            # The M-key map scene and the world-map field are both in the
            # common boot pack, so their pixel navigation mask must be mounted
            # before any chapter pack is requested.
            return "common"
        if "ch3_" in lower:
            return "chapter3"
        if "ch2_" in lower:
            return "chapter2"
        if any(marker in lower for marker in CHAPTER1_LATE_MARKERS):
            return "chapter1_late"
        return "chapter1_start"
    if lower.startswith("art/modules/"):
        # linxi_main_street.tscn owns these as static ext_resources, so the
        # Web exporter must see them before any chapter pack is mounted.
        return "common"
    if lower.startswith("art/props/"):
        return "chapter1_start"
    if any(marker in lower for marker in CHAPTER3_MARKERS):
        return "chapter3"
    if any(marker in lower for marker in CHAPTER2_MARKERS):
        return "chapter2"
    if any(marker in lower for marker in CHAPTER1_LATE_MARKERS):
        return "chapter1_late"
    # Ambiguous NPCs, first-chapter companions, early enemies and their VFX
    # belong to the chapter-one startup segment. Packs stay mounted, so the
    # late chapter-one segment and later chapters can reuse them.
    return "chapter1_start"


def safe_rebuild_root(path: Path, expected_parent: Path, expected_name: str) -> None:
    path = path.resolve()
    if path.parent != expected_parent.resolve() or path.name != expected_name:
        raise SystemExit(f"Refusing unsafe generated directory: {path}")
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def copy_file(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)


def minimal_project_text(pack_id: str) -> str:
    return "\n".join([
        "; Generated chapter content-pack import project.",
        "config_version=5",
        "",
        "[application]",
        f'config/name="云影侠传-{pack_id}"',
        'config/features=PackedStringArray("4.6", "GL Compatibility")',
        "",
        "[rendering]",
        'renderer/rendering_method="gl_compatibility"',
        'renderer/rendering_method.mobile="gl_compatibility"',
        "",
    ])


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def runtime_manifest(base_url: str, pack_dir: Path) -> dict:
    packs: dict[str, dict] = {}
    chapter_specs = (
        ("chapter1_start", [1], "林西启动段"),
        ("chapter1_late", [1], "竹尾后山段"),
        ("chapter2", [2], "第二章"),
        ("chapter3", [3], "第三章"),
    )
    for pack_id, chapters, display_name in chapter_specs:
        path = pack_dir / f"{pack_id}.pck"
        packs[pack_id] = {
            "file": path.name,
            "sha256": sha256(path) if path.exists() else "",
            "bytes": path.stat().st_size if path.exists() else 0,
            "chapters": chapters,
            "displayName": display_name,
        }
    return {"version": 1, "baseUrl": base_url.rstrip("/") + "/", "packs": packs}


def main() -> int:
    args = parse_args()
    game_root = args.game_root.resolve()
    build_root = game_root / "build"
    stage_root = build_root / "wechat_stage"
    stage_manifest_path = build_root / "wechat_stage_manifest.json"
    projects_root = build_root / "wechat_pack_projects"
    pack_output = build_root / "wechat_packs"
    report_path = build_root / "wechat_content_pack_manifest.json"
    common_runtime_manifest = projects_root / "common" / "config" / "wechat_content_packs.json"

    if args.finalize_only:
        manifest = runtime_manifest(args.cdn_base_url, pack_output)
        common_runtime_manifest.parent.mkdir(parents=True, exist_ok=True)
        common_runtime_manifest.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
        report = json.loads(report_path.read_text(encoding="utf-8"))
        report["runtimeManifest"] = manifest
        report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        print(json.dumps(manifest, ensure_ascii=False))
        return 0

    if not stage_manifest_path.exists() or not stage_root.exists():
        raise SystemExit("Run prepare_wechat_trial_stage.py before partitioning content packs.")
    safe_rebuild_root(projects_root, build_root, "wechat_pack_projects")
    safe_rebuild_root(pack_output, build_root, "wechat_packs")
    stage_manifest = json.loads(stage_manifest_path.read_text(encoding="utf-8"))
    ownership: dict[str, list[str]] = {pack_id: [] for pack_id in PACK_IDS}
    for relative in stage_manifest.get("files", []):
        source = stage_root / relative
        if not source.exists() or not source.is_file():
            continue
        ownership[pack_owner(relative)].append(relative)

    for pack_id in PACK_IDS:
        project_root = projects_root / pack_id
        project_root.mkdir(parents=True, exist_ok=True)
        if pack_id == "common":
            for relative in ownership[pack_id]:
                copy_file(stage_root / relative, project_root / relative)
        else:
            (project_root / "project.godot").write_text(minimal_project_text(pack_id), encoding="utf-8")
            copy_file(game_root / "export_presets.cfg", project_root / "export_presets.cfg")
            for relative in ownership[pack_id]:
                copy_file(stage_root / relative, project_root / relative)

    placeholder_manifest = runtime_manifest(args.cdn_base_url, pack_output)
    common_runtime_manifest.parent.mkdir(parents=True, exist_ok=True)
    common_runtime_manifest.write_text(json.dumps(placeholder_manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    summary: dict[str, dict] = {}
    for pack_id, files in ownership.items():
        size = sum((stage_root / relative).stat().st_size for relative in files)
        summary[pack_id] = {"files": len(files), "sourceBytes": size, "sourceMiB": round(size / 1024 / 1024, 2)}
    report = {
        "version": 1,
        "scope": "wechat-trial-common-plus-chapters-1-3",
        "projectsRoot": str(projects_root),
        "packOutput": str(pack_output),
        "ownership": summary,
        "files": ownership,
        "runtimeManifest": placeholder_manifest,
    }
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False))
    print(f"Report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
