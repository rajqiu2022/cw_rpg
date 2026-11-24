"""Prepare reviewed chest and narration-frame art for Godot runtime use."""

from pathlib import Path
import shutil

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
CHEST_SOURCE = ROOT / "assets/processed/ui_icon/chest/v1/prop_chest_tiers_runtime_v1_alpha.png"
CHEST_PROCESSED = ROOT / "assets/processed/ui_icon/chest/v1/sliced"
CHEST_RUNTIME = ROOT / "game/art/modules/prop"
NARRATION_SOURCE = ROOT / "assets/raw/ui_dialog/narration/v1/ui_dialog_narration_frame_v1.png"
NARRATION_RUNTIME = ROOT / "game/art/ui/field_hud/v2/hud_dialog_narration_frame_v1.png"

CHEST_IDS = ("chest_normal_closed_v1", "chest_advanced_closed_v1", "chest_rare_closed_v1")
ALPHA_THRESHOLD = 28
PADDING = 18
# The generation prompt reserves this exact area for the single narration frame.
NARRATION_CROP = (15, 304, 1521, 728)
NARRATION_SIZE = (1534, 343)


def _trim_alpha(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A").point(lambda value: 255 if value > ALPHA_THRESHOLD else 0)
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError("No opaque pixels remain after alpha thresholding")
    left = max(0, bounds[0] - PADDING)
    top = max(0, bounds[1] - PADDING)
    right = min(image.width, bounds[2] + PADDING)
    bottom = min(image.height, bounds[3] + PADDING)
    return image.crop((left, top, right, bottom))


def deploy_chests() -> None:
    if not CHEST_SOURCE.exists():
        raise FileNotFoundError(
            "Chest source must be chroma-keyed before slicing: %s" % CHEST_SOURCE
        )
    source = Image.open(CHEST_SOURCE).convert("RGBA")
    cell_width = source.width // len(CHEST_IDS)
    CHEST_PROCESSED.mkdir(parents=True, exist_ok=True)
    CHEST_RUNTIME.mkdir(parents=True, exist_ok=True)
    for index, asset_id in enumerate(CHEST_IDS):
        left = index * cell_width
        right = source.width if index == len(CHEST_IDS) - 1 else left + cell_width
        output = _trim_alpha(source.crop((left, 0, right, source.height)))
        processed_path = CHEST_PROCESSED / f"{asset_id}.png"
        runtime_path = CHEST_RUNTIME / processed_path.name
        output.save(processed_path)
        shutil.copy2(processed_path, runtime_path)
        print(f"{asset_id}: {output.width}x{output.height}")


def deploy_narration_frame() -> None:
    source = Image.open(NARRATION_SOURCE).convert("RGBA")
    frame = source.crop(NARRATION_CROP).resize(NARRATION_SIZE, Image.Resampling.LANCZOS)
    pixels = frame.load()
    for y in range(frame.height):
        for x in range(frame.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha > 0 and red > 242 and green > 242 and blue > 242:
                pixels[x, y] = (red, green, blue, 0)
    NARRATION_RUNTIME.parent.mkdir(parents=True, exist_ok=True)
    frame.save(NARRATION_RUNTIME)
    print(f"narration frame: {frame.width}x{frame.height}")


if __name__ == "__main__":
    deploy_chests()
    deploy_narration_frame()
