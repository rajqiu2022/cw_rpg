"""Create 3072x2048 runtime maps for the open-world city expansion."""

from __future__ import annotations

import os
import sys
import types
from pathlib import Path

import cv2
import torch
from torchvision.transforms.functional import rgb_to_grayscale


shim = types.ModuleType("torchvision.transforms.functional_tensor")
shim.rgb_to_grayscale = rgb_to_grayscale
sys.modules[shim.__name__] = shim

from basicsr.archs.rrdbnet_arch import RRDBNet  # noqa: E402
from realesrgan import RealESRGANer  # noqa: E402


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets/raw/scene_background/openworld_cities_v1"
RUNTIME_DIR = ROOT / "game/art/backgrounds/openworld_cities_v1"
MODEL = (
    Path(os.environ.get("LOCALAPPDATA", ""))
    / "Codex/models/realesrgan/RealESRGAN_x4plus_anime_6B.pth"
)


def main() -> None:
    network = RRDBNet(
        num_in_ch=3,
        num_out_ch=3,
        num_feat=64,
        num_block=6,
        num_grow_ch=32,
        scale=4,
    )
    engine = RealESRGANer(
        scale=4,
        model_path=str(MODEL),
        model=network,
        tile=384,
        tile_pad=24,
        pre_pad=0,
        half=torch.cuda.is_available(),
    )
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    for source in sorted(SOURCE_DIR.glob("*_source.png")):
        image = cv2.imread(str(source), cv2.IMREAD_COLOR)
        if image is None:
            raise RuntimeError(f"Could not read {source}")
        restored, _ = engine.enhance(image, outscale=2.0)
        output = RUNTIME_DIR / source.name.replace("_source", "_3072")
        if not cv2.imwrite(str(output), restored, [cv2.IMWRITE_PNG_COMPRESSION, 5]):
            raise RuntimeError(f"Could not write {output}")
        print(f"{output.relative_to(ROOT)} {restored.shape[1]}x{restored.shape[0]}")


if __name__ == "__main__":
    main()
