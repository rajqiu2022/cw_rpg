"""Neural 2x restoration for the accepted world-map master.

Uses the official Real-ESRGAN anime/illustration model.  The torchvision shim
keeps BasicSR 1.4.2 compatible with torchvision 0.21 without modifying the
installed package.
"""

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
SOURCE = ROOT / "assets" / "raw" / "scene_background" / "world_map_v5_codex_builtin" / "bg_world_map_v5_master.png"
OUTPUT = ROOT / "game" / "art" / "backgrounds" / "bg_world_map_jianghu_v5_realesrgan_hd.png"
MODEL = Path(os.environ.get("LOCALAPPDATA", "")) / "Codex" / "models" / "realesrgan" / "RealESRGAN_x4plus_anime_6B.pth"


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    if not MODEL.exists():
        raise FileNotFoundError(MODEL)
    network = RRDBNet(
        num_in_ch=3,
        num_out_ch=3,
        num_feat=64,
        num_block=6,
        num_grow_ch=32,
        scale=4,
    )
    upsampler = RealESRGANer(
        scale=4,
        model_path=str(MODEL),
        model=network,
        tile=512,
        tile_pad=24,
        pre_pad=0,
        half=torch.cuda.is_available(),
    )
    source = cv2.imread(str(SOURCE), cv2.IMREAD_COLOR)
    if source is None:
        raise RuntimeError(f"Could not read {SOURCE}")
    restored, _ = upsampler.enhance(source, outscale=2)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    if not cv2.imwrite(str(OUTPUT), restored, [cv2.IMWRITE_PNG_COMPRESSION, 5]):
        raise RuntimeError(f"Could not write {OUTPUT}")
    print(f"{OUTPUT} {restored.shape[1]}x{restored.shape[0]}")


if __name__ == "__main__":
    main()
