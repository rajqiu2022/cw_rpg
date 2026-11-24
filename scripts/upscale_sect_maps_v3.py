"""Neural-detail upscale for the v3 Huashan/Wudang zone backgrounds.

The built-in image generator currently returns 1536x1024 sources.  These
scrolling maps are consumed at 3072x2048, so use the project's reviewed
Real-ESRGAN model instead of ordinary interpolation.  The same pass rebuilds
the v10 world-map desktop source at 3x to avoid magnifying the 2304 preview.
"""

from __future__ import annotations

import os
import argparse
import sys
import types
from pathlib import Path

import cv2
import torch
from PIL import Image
from torchvision.transforms.functional import rgb_to_grayscale


shim = types.ModuleType("torchvision.transforms.functional_tensor")
shim.rgb_to_grayscale = rgb_to_grayscale
sys.modules[shim.__name__] = shim

from basicsr.archs.rrdbnet_arch import RRDBNet  # noqa: E402
from realesrgan import RealESRGANer  # noqa: E402
from build_world_map_v10_assets import build_mask, enhance_roads, sha256  # noqa: E402


ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "assets/raw/scene_background/sect_maps_v3"
RUNTIME = ROOT / "game/art/backgrounds/sect_maps_v3"
MODEL = (
    Path(os.environ.get("LOCALAPPDATA", ""))
    / "Codex/models/realesrgan/RealESRGAN_x4plus_anime_6B.pth"
)

SOURCES = {
    "bg_huashan_gate_v3_source.png": "bg_huashan_gate_v3_3072.png",
    "bg_huashan_sword_terrace_v3_source.png": "bg_huashan_sword_terrace_v3_3072.png",
    "bg_huashan_waterfall_terrace_v3_source.png": "bg_huashan_waterfall_terrace_v3_3072.png",
    "bg_wudang_gate_v3_source.png": "bg_wudang_gate_v3_3072.png",
    "bg_wudang_taiji_court_v3_source.png": "bg_wudang_taiji_court_v3_3072.png",
    "bg_wudang_purple_cloud_court_v3_source.png": "bg_wudang_purple_cloud_court_v3_3072.png",
}

WORLD_SOURCE = (
    ROOT
    / "assets/raw/scene_background/world_map_v10_open_plain/bg_world_map_jianghu_v10_source.png"
)
WORLD_HD = (
    ROOT
    / "assets/raw/scene_background/world_map_v10_open_plain/bg_world_map_jianghu_v10_pc_4608.png"
)
WORLD_REPORT = ROOT / "assets/processed/scene/world_map_v10/navigation_validation.json"


def upsampler() -> RealESRGANer:
    if not MODEL.is_file():
        raise FileNotFoundError(f"Missing reviewed Real-ESRGAN model: {MODEL}")
    network = RRDBNet(
        num_in_ch=3,
        num_out_ch=3,
        num_feat=64,
        num_block=6,
        num_grow_ch=32,
        scale=4,
    )
    return RealESRGANer(
        scale=4,
        model_path=str(MODEL),
        model=network,
        tile=384,
        tile_pad=24,
        pre_pad=0,
        half=torch.cuda.is_available(),
    )


def enhance(engine: RealESRGANer, source: Path, output: Path, scale: float) -> None:
    image = cv2.imread(str(source), cv2.IMREAD_COLOR)
    if image is None:
        raise RuntimeError(f"Could not read {source}")
    restored, _ = engine.enhance(image, outscale=scale)
    output.parent.mkdir(parents=True, exist_ok=True)
    if not cv2.imwrite(str(output), restored, [cv2.IMWRITE_PNG_COMPRESSION, 5]):
        raise RuntimeError(f"Could not write {output}")
    print(f"{output.relative_to(ROOT)} {restored.shape[1]}x{restored.shape[0]}")


def refresh_world_report() -> None:
    if not WORLD_REPORT.is_file():
        return
    import json

    report = json.loads(WORLD_REPORT.read_text(encoding="utf-8"))
    report["desktop_background_sha256"] = sha256(WORLD_HD)
    report["desktop_upscale"] = "RealESRGAN_x4plus_anime_6B outscale=3; route overlay restored"
    WORLD_REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--world-only",
        action="store_true",
        help="Only rebuild the neural-detail v10 world-map desktop source.",
    )
    parser.add_argument(
        "--refresh-report-only",
        action="store_true",
        help="Refresh the final desktop hash after an already completed upscale.",
    )
    args = parser.parse_args()
    if args.refresh_report_only:
        refresh_world_report()
        return
    engine = upsampler()
    if not args.world_only:
        for source_name, output_name in SOURCES.items():
            enhance(engine, RAW / source_name, RUNTIME / output_name, 2.0)
    enhance(engine, WORLD_SOURCE, WORLD_HD, 3.0)
    world = Image.open(WORLD_HD).convert("RGB")
    _mask, route_mask = build_mask(world.size)
    enhance_roads(world, route_mask).save(WORLD_HD, optimize=True, compress_level=5)
    print(f"{WORLD_HD.relative_to(ROOT)} road-overlay-restored")
    refresh_world_report()


if __name__ == "__main__":
    main()
