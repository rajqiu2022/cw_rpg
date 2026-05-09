"""
将 gen_assets.py 生成的场景背景 PNG 部署到 game/art/backgrounds/。
在 gen_assets.py 执行成功后运行本脚本。

Usage:
    python scripts/deploy_scene_backgrounds.py [--dry-run]
"""

import shutil
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_ROOT / "assets" / "raw" / "scene_background"
DEST_DIR = PROJECT_ROOT / "game" / "art" / "backgrounds"

# 映射：raw 文件名 → game/art/backgrounds 下的目标文件名
DEPLOY_MAP = {
    "scene_ch1_s1_road.png": "bg_ch1_s1_road.png",
    "scene_zhuwei_main_street.png": "bg_zhuwei_main_street.png",
    "scene_west_ruin.png": "bg_west_ruin.png",
    "scene_battle_bamboo_road.png": "bg_battle_default.png",
}


def main():
    dry_run = "--dry-run" in sys.argv

    DEST_DIR.mkdir(parents=True, exist_ok=True)

    deployed = 0
    skipped = 0

    for src_name, dst_name in DEPLOY_MAP.items():
        src = RAW_DIR / src_name
        dst = DEST_DIR / dst_name

        if not src.exists():
            print(f"  [跳过] {src_name} 尚未生成")
            skipped += 1
            continue

        if dry_run:
            print(f"  [dry-run] {src_name} → {dst.relative_to(PROJECT_ROOT)}")
        else:
            shutil.copy2(src, dst)
            print(f"  [部署] {src_name} → {dst.relative_to(PROJECT_ROOT)}")
        deployed += 1

    print(f"\n完成：部署 {deployed} 张，跳过 {skipped} 张" +
          (" (dry-run 模式)" if dry_run else ""))


if __name__ == "__main__":
    main()
