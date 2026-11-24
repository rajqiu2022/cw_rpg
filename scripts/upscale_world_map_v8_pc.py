"""Create the PC 2x source for the adopted v8 world map with Real-ESRGAN."""

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
SOURCE = ROOT / "game" / "art" / "backgrounds" / "region_masters_v2" / "bg_world_map_jianghu_v8_2304.png"
OUTPUT = ROOT / "assets" / "raw" / "scene_background" / "later_regions_codex_builtin_v2" / "bg_world_map_jianghu_v8_pc_4608.png"
MODEL = Path(os.environ.get("LOCALAPPDATA", "")) / "Codex" / "models" / "realesrgan" / "RealESRGAN_x4plus_anime_6B.pth"


def main() -> None:
    network = RRDBNet(num_in_ch=3, num_out_ch=3, num_feat=64, num_block=6, num_grow_ch=32, scale=4)
    upsampler = RealESRGANer(
        scale=4,
        model_path=str(MODEL),
        model=network,
        tile=384,
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
