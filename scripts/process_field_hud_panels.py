"""后处理 AI 生成的 HUD 面板：裁切 → 提亮 → 部署到游戏目录"""

from pathlib import Path
import numpy as np
from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "assets" / "raw" / "ui_frame"
GAME_DIR = ROOT / "game" / "art" / "ui" / "field_hud" / "v1"
TOOLS_DIR = ROOT / "tools" / "ui_field_hud_v1"

# In-game layout (1920×1080 canvas)
# Current placements from field_walkable_controller.gd
PANELS = {
    "char_info": {
        "source": RAW_DIR / "ui_hud_char_info_raw_v1.png",
        "game_name": "hud_player_panel.png",
        "crop": (60, 30, 1400, 430),       # from 1536×1024 raw
        "target_size": (650, 188),           # in-game size
        "brightness": 1.18,
    },
    "scene_plaque": {
        "source": RAW_DIR / "ui_hud_scene_plaque_raw_v1.png",
        "game_name": "hud_scene_title.png",
        "crop": (120, 30, 1380, 210),
        "target_size": (543, 63),
        "brightness": 1.22,
    },
    # Inventory panel is saved as concept reference only — not for production use.
    # Gemini review: edges are irregular, slots not 9-slice-able. Needs manual redraw.
    "inventory_ref": {
        "source": RAW_DIR / "ui_inventory_panel_raw_v1.png",
        "game_name": None,  # don't deploy to game dir — concept reference only
        "preview_name": "ref_inventory_concept_v1.png",  # save to tools dir
        "crop": (280, 100, 1260, 920),
        "target_size": (900, 750),
        "brightness": 1.15,
    },
}


def _clean_edges(img: Image.Image) -> Image.Image:
    """Feather the edges slightly so the panel blends better."""
    arr = np.array(img.convert("RGBA")).astype(np.float32)
    h, w = arr.shape[:2]
    # Add alpha channel, fading edges slightly
    alpha = np.ones((h, w), dtype=np.float32) * 255
    fade = min(6, h // 20, w // 20)
    if fade > 0:
        for i in range(fade):
            v = (i / fade) * 255
            alpha[i, :] = np.minimum(alpha[i, :], v)
            alpha[h - 1 - i, :] = np.minimum(alpha[h - 1 - i, :], v)
            alpha[:, i] = np.minimum(alpha[:, i], v)
            alpha[:, w - 1 - i] = np.minimum(alpha[:, w - 1 - i], v)
    arr[:, :, 3] = alpha
    return Image.fromarray(arr.clip(0, 255).astype("uint8"), "RGBA")


def main():
    GAME_DIR.mkdir(parents=True, exist_ok=True)

    for key, cfg in PANELS.items():
        print(f"\n[{key}]")
        source = cfg["source"]
        if not source.exists():
            print(f"  SOURCE MISSING: {source}")
            continue

        img = Image.open(source).convert("RGB")
        print(f"  Raw size: {img.size}")

        # Crop
        cropped = img.crop(cfg["crop"])
        print(f"  Cropped: {cropped.size}")

        # Resize
        target = cfg["target_size"]
        resized = cropped.resize(target, Image.Resampling.LANCZOS)
        print(f"  Resized: {resized.size}")

        # Brighten
        if cfg["brightness"] != 1.0:
            resized = ImageEnhance.Brightness(resized).enhance(cfg["brightness"])

        # Add alpha for edge blending
        final = _clean_edges(resized)

        # Save to game dir (only if designated)
        if cfg["game_name"]:
            game_path = GAME_DIR / cfg["game_name"]
            final.save(game_path)
            print(f"  → Game: {game_path}")

        # Save preview to tools dir
        preview_name = cfg.get("preview_name") or cfg.get("game_name")
        if preview_name:
            preview_path = TOOLS_DIR / preview_name
            final.save(preview_path)

    print(f"\nDone. Game dir: {GAME_DIR}")


if __name__ == "__main__":
    main()
