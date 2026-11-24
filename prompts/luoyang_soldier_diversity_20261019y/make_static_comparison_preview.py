"""Package the four accepted 160px static candidates into a 3x nearest preview."""
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
source = ROOT / "assets/previews/sprite/luoyang_soldier_diversity_20261019y/four_static_candidates_actual_pixels.png"
target = ROOT / "assets/previews/sprite/luoyang_soldier_diversity_20261019y/four_static_candidates_3x_nearest_technical_preview.png"
image = Image.open(source).convert("RGBA")
if image.size != (640, 160):
    raise ValueError(f"unexpected source preview size {image.size}")
image.resize((1920, 480), Image.Resampling.NEAREST).save(target, format="PNG")
print(target.relative_to(ROOT).as_posix())
