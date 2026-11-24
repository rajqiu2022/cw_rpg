"""Create 3072x2048 city maps without restyling the ImageGen source.

The previous implementation used the ``anime_6B`` Real-ESRGAN checkpoint.
That checkpoint invents hard ink edges and flattened colour patches, which made
the accepted realistic sources look like oil-painted/anime art in game.  City
maps need geometric enlargement, not a second generative art pass, so the
runtime build now uses deterministic Lanczos resampling only.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets/raw/scene_background/openworld_cities_v2"
RUNTIME_DIR = ROOT / "game/art/backgrounds/openworld_cities_v2"
RUNTIME_SIZE = (3072, 2048)


def main() -> None:
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    for source in sorted(SOURCE_DIR.glob("*_source.png")):
        image = Image.open(source).convert("RGB")
        restored = image.resize(RUNTIME_SIZE, Image.Resampling.LANCZOS)
        output = RUNTIME_DIR / source.name.replace("_source", "_3072")
        restored.save(output, optimize=True, compress_level=6)
        print(f"{output.relative_to(ROOT)} {restored.width}x{restored.height}")


if __name__ == "__main__":
    main()
