from pathlib import Path

import cv2
import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "assets" / "raw" / "sprite" / "enemy_foot_repair_codex_builtin_v1"
OUT_ROOT = ROOT / "game" / "art" / "sprites" / "battle" / "standard_v3"


def extract_checkerboard_subject(source: Path) -> Image.Image:
    image = Image.open(source).convert("RGBA")
    rgba = np.asarray(image).copy()
    rgb = rgba[:, :, :3].astype(np.int16)
    channel_range = rgb.max(axis=2) - rgb.min(axis=2)
    # Built-in edits occasionally bake the transparency checkerboard. It is
    # always bright and neutral; the character and weapon are darker or have
    # appreciable colour separation.
    background = (rgb.min(axis=2) > 218) & (channel_range < 14)
    candidate = (~background).astype(np.uint8)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(candidate, 8)
    if count <= 1:
        raise RuntimeError(f"No foreground component found in {source}")
    largest = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    component = labels == largest
    mask = component.astype(np.uint8) * 255
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    mask = cv2.GaussianBlur(mask, (3, 3), 0.6)
    # Never let the soft edge expand into the bright checker cells; doing so
    # creates a white fringe after downscaling.
    mask[~component] = 0
    rgba[:, :, 3] = mask
    rgba[mask == 0, :3] = 0
    return Image.fromarray(rgba, "RGBA")


def normalize_frame(image: Image.Image) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError("Empty repaired sprite")
    crop = image.crop(bbox)
    target_height = 340
    target_width = min(476, round(crop.width * target_height / crop.height))
    crop = crop.resize((target_width, target_height), Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", (512, 384), (0, 0, 0, 0))
    x = (512 - crop.width) // 2
    y = 366 - crop.height
    frame.alpha_composite(crop, (x, y))
    return frame


def build_ready_set(enemy_id: str, source_name: str) -> None:
    source = RAW / source_name
    frame = normalize_frame(extract_checkerboard_subject(source))
    output_dir = OUT_ROOT / enemy_id
    output_dir.mkdir(parents=True, exist_ok=True)
    for index in range(1, 5):
        output = output_dir / f"{enemy_id}_ready_{index:02d}.png"
        frame.save(output, optimize=True)
        print(output)


def main() -> None:
    build_ready_set("bandit_mountain", "bandit_mountain_ready_source_v1.png")
    build_ready_set("zhuwei_bandit", "zhuwei_bandit_ready_source_v1.png")


if __name__ == "__main__":
    main()
