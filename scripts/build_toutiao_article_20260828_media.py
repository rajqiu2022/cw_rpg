"""Prepare the reviewed screenshots and animated VFX for the 2026-08-28 Toutiao draft."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageEnhance, ImageSequence


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "toutiao_images_2026-08-28"

STATIC = [
    ("01_battle_status.jpg", "game/screenshots/battle_zhuwei_cave_wolf_status_hover_1787422586.png", "战斗状态与敌我资源条"),
    ("02_battle_attack.jpg", "game/screenshots/battle_zhuwei_bandit_zhuwei_bandit_attack_1787537984.png", "多人战中的角色动作与命中特效"),
    ("03_damage_breakdown.png", "game/screenshots/gm_console_damage_1787541402.png", "统一伤害拆解面板"),
    ("04_skill_legendary.jpg", "game/screenshots/skill_legendary_detail_1787387772.png", "橙色绝学与武学系统界面"),
    ("05_world_map.jpg", "game/screenshots/field_world_map_jianghu_1787672732.png", "同源道路与Camera2D大地图"),
    ("06_cave_mine.jpg", "game/screenshots/field_ch1_s4_cave_mine_gallery_1787381985.png", "固定镜头洞窟支路"),
]

ANIMATED = [
    ("07_vfx_snow_blade.gif", "docs/assets/skill-vfx/snow_pass_returning_blade.webp", "断雪回锋四阶段特效"),
    ("08_vfx_hidden_darts.gif", "docs/assets/skill-vfx/blood_shadow_scattering_darts.webp", "暗器散射四阶段特效"),
    ("09_vfx_legendary_palm.gif", "docs/assets/skill-vfx/canghai_zhenyue_palms.webp", "绝学掌劲四阶段特效"),
]


def fit_frame(image: Image.Image, size: tuple[int, int] = (1280, 720)) -> Image.Image:
    source = image.convert("RGB")
    source.thumbnail(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", size, (7, 15, 19))
    canvas.paste(source, ((size[0] - source.width) // 2, (size[1] - source.height) // 2))
    return canvas


def build_static(name: str, source_path: str) -> None:
    source = Image.open(ROOT / source_path)
    target = OUT / name
    if target.suffix.lower() == ".png":
        # Keep the compact diagnostic UI lossless and enlarge it for reading.
        source.convert("RGBA").resize((960, 540), Image.Resampling.NEAREST).save(target, optimize=True)
    else:
        frame = ImageEnhance.Contrast(fit_frame(source)).enhance(1.03)
        frame.save(target, quality=89, optimize=True, progressive=True, subsampling=1)


def build_gif(name: str, source_path: str) -> None:
    source = Image.open(ROOT / source_path)
    frames: list[Image.Image] = []
    for frame in ImageSequence.Iterator(source):
        rgba = frame.convert("RGBA").resize((540, 540), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (720, 540), (5, 13, 17, 255))
        canvas.alpha_composite(rgba, ((720 - rgba.width) // 2, 0))
        frames.append(canvas.convert("RGB").quantize(colors=192, method=Image.Quantize.MEDIANCUT))
    if len(frames) < 2:
        raise RuntimeError(f"{source_path} is not animated")
    frames[0].save(OUT / name, save_all=True, append_images=frames[1:], duration=[180] * len(frames), loop=0, optimize=True, disposal=2)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, source, _caption in STATIC:
        build_static(name, source)
    for name, source, _caption in ANIMATED:
        build_gif(name, source)
    manifest = {
        "article": "docs/toutiao-article-battle-scene-skills-2026-08-28.md",
        "static": [{"file": name, "source": source, "caption": caption} for name, source, caption in STATIC],
        "animated": [{"file": name, "source": source, "caption": caption, "frames": 4, "frame_ms": 180} for name, source, caption in ANIMATED],
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Prepared {len(STATIC)} static images and {len(ANIMATED)} GIFs in {OUT}")


if __name__ == "__main__":
    main()
