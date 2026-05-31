"""Deploy AI-generated panels: crop, soften edges, save to game dir."""

from pathlib import Path
import numpy as np
from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "assets" / "raw" / "ui_frame"
GAME_DIR = ROOT / "game" / "art" / "ui" / "field_hud" / "v1"
TOOLS_DIR = ROOT / "tools" / "ui_field_hud_v1"

SPECS = {
    "char": {
        "raw": "ui_hud_char_info_raw_v1.png",
        "game": "hud_player_panel.png",
        # Crop around the character panel area (full 1536x1024 canvas)
        "crop": (40, 15, 1450, 420),
        "size": (650, 188),
        "brightness": 1.20,
    },
    "scene": {
        "raw": "ui_hud_scene_plaque_raw_v1.png",
        "game": "hud_scene_title.png",
        "crop": (100, 25, 1410, 215),
        "size": (543, 63),
        "brightness": 1.28,
    },
}


def soften_edges(img: Image.Image, fade_px: int = 4) -> Image.Image:
    """Add subtle edge fade for better blending with game background."""
    arr = np.array(img.convert("RGBA")).astype(np.float32)
    h, w = arr.shape[:2]
    alpha = np.full((h, w), 255.0, dtype=np.float32)

    for i in range(fade_px):
        v = (i + 1) / (fade_px + 1) * 255
        alpha[i, :] = np.minimum(alpha[i, :], v)
        alpha[h - 1 - i, :] = np.minimum(alpha[h - 1 - i, :], v)
        alpha[:, i] = np.minimum(alpha[:, i], v)
        alpha[:, w - 1 - i] = np.minimum(alpha[:, w - 1 - i], v)

    arr[:, :, 3] = alpha
    return Image.fromarray(arr.clip(0, 255).astype("uint8"), "RGBA")


def main():
    GAME_DIR.mkdir(parents=True, exist_ok=True)

    for key, s in SPECS.items():
        src = RAW_DIR / s["raw"]
        if not src.exists():
            print(f"[{key}] MISSING: {src}")
            continue

        img = Image.open(src).convert("RGB")
        cropped = img.crop(s["crop"])
        resized = cropped.resize(s["size"], Image.Resampling.LANCZOS)
        brightened = ImageEnhance.Brightness(resized).enhance(s["brightness"])
        final = soften_edges(brightened, fade_px=5)

        game_path = GAME_DIR / s["game"]
        final.save(game_path)
        print(f"[{key}] {s['size']} → {game_path}")

        # Also save preview
        preview = TOOLS_DIR / s["game"]
        final.save(preview)

    print("Done.")


if __name__ == "__main__":
    main()
