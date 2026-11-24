"""Build realistic gameplay backgrounds without a style-changing AI upscaler.

The reviewed ImageGen sources are already 1536x1024. Runtime maps need larger
logical canvases for camera travel, so this build performs geometry-only
Lanczos enlargement. In particular it must never use the anime Real-ESRGAN
checkpoint that previously introduced cartoon outlines and painted colour
patches into otherwise realistic sources.
"""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/raw/scene_background/scene_realism_v5"
SECT_OUTPUT = ROOT / "game/art/backgrounds/sect_maps_v5"
CITY_OUTPUT = ROOT / "game/art/backgrounds/openworld_cities_v3"


def resize(source_name: str, output: Path, size: tuple[int, int]) -> None:
    source = SOURCE / source_name
    image = Image.open(source).convert("RGB")
    runtime = image.resize(size, Image.Resampling.LANCZOS)
    output.parent.mkdir(parents=True, exist_ok=True)
    runtime.save(output, optimize=True, compress_level=6)
    print(f"{output.relative_to(ROOT)} {runtime.width}x{runtime.height}")


def main() -> None:
    resize(
        "bg_huashan_gate_v5_source.png",
        SECT_OUTPUT / "bg_huashan_gate_v5_3072.png",
        (3072, 2048),
    )
    resize(
        "bg_wudang_taiji_court_v5_source.png",
        SECT_OUTPUT / "bg_wudang_taiji_court_v5_3072.png",
        (3072, 2048),
    )
    resize(
        "bg_wudang_gate_v5_source.png",
        SECT_OUTPUT / "bg_wudang_gate_v5_3072.png",
        (3072, 2048),
    )
    resize(
        "bg_wudang_purple_cloud_court_v5_source.png",
        SECT_OUTPUT / "bg_wudang_purple_cloud_court_v5_3072.png",
        (3072, 2048),
    )
    resize(
        "bg_huashan_sword_terrace_v5_source.png",
        SECT_OUTPUT / "bg_huashan_sword_terrace_v5_3072.png",
        (3072, 2048),
    )
    resize(
        "bg_huashan_waterfall_terrace_v5_source.png",
        SECT_OUTPUT / "bg_huashan_waterfall_terrace_v5_3072.png",
        (3072, 2048),
    )
    resize(
        "bg_luoyang_south_market_v2_source.png",
        CITY_OUTPUT / "bg_luoyang_south_market_v2_2304.png",
        (2304, 1536),
    )


if __name__ == "__main__":
    main()
