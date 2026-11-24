"""Build the approved realistic v4 Huashan/Wudang runtime backgrounds.

The built-in image generator returns 1536x1024 sources.  The two multi-screen
sect routes consume native 3072x2048 art, so use the repository's reviewed
Real-ESRGAN model rather than ordinary interpolation.
"""

from pathlib import Path

from upscale_sect_maps_v3 import ROOT, enhance, upsampler


RAW = ROOT / "assets/raw/scene_background/sect_maps_v4"
RUNTIME = ROOT / "game/art/backgrounds/sect_maps_v4"

SOURCES = {
    "bg_huashan_gate_v4_source.png": "bg_huashan_gate_v4_3072.png",
    "bg_huashan_sword_terrace_v4_source.png": "bg_huashan_sword_terrace_v4_3072.png",
    "bg_huashan_waterfall_terrace_v4_source.png": "bg_huashan_waterfall_terrace_v4_3072.png",
    "bg_wudang_gate_v4_source.png": "bg_wudang_gate_v4_3072.png",
    "bg_wudang_taiji_court_v4_source.png": "bg_wudang_taiji_court_v4_3072.png",
    "bg_wudang_purple_cloud_court_v4_source.png": "bg_wudang_purple_cloud_court_v4_3072.png",
}


def main() -> None:
    engine = upsampler()
    for source_name, output_name in SOURCES.items():
        enhance(engine, RAW / source_name, RUNTIME / output_name, 2.0)


if __name__ == "__main__":
    main()
