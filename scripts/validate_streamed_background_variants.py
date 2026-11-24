"""Validate chunk geometry and lossless reconstruction of the mobile source."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageChops


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--mobile-source", type=Path, required=True)
    parser.add_argument("--desktop-source", type=Path, required=True)
    return parser.parse_args()


def reconstruct(root: Path, entries: list[dict[str, object]], logical_size: tuple[int, int], scale: float) -> Image.Image:
    canvas = Image.new("RGB", (round(logical_size[0] * scale), round(logical_size[1] * scale)))
    for entry in entries:
        tile = Image.open(root / str(entry["file"])).convert("RGB")
        left, top = (round(value * scale) for value in entry["draw_position"])
        canvas.paste(tile, (left, top))
    return canvas


def main() -> None:
    args = parse_args()
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    logical_size = tuple(manifest["logical_size"])
    mobile_source = Image.open(args.mobile_source).convert("RGB")
    desktop_source = Image.open(args.desktop_source).convert("RGB")
    mobile_scale = mobile_source.width / logical_size[0]
    desktop_scale = desktop_source.width / logical_size[0]
    if mobile_source.size != (logical_size[0], logical_size[1]):
        raise SystemExit("mobile source does not match logical size")
    if abs(desktop_scale - desktop_source.height / logical_size[1]) > 0.0001:
        raise SystemExit("desktop source uses non-uniform scaling")
    mobile = reconstruct(args.manifest.parent / "mobile", manifest["mobile"], logical_size, mobile_scale)
    desktop = reconstruct(args.manifest.parent / "desktop", manifest["desktop"], logical_size, desktop_scale)
    if ImageChops.difference(mobile, mobile_source).getbbox() is not None:
        raise SystemExit("mobile chunks do not reconstruct the source exactly")
    if ImageChops.difference(desktop, desktop_source).getbbox() is not None:
        raise SystemExit("desktop chunks do not reconstruct the source exactly")
    print(
        json.dumps(
            {
                "logicalSize": logical_size,
                "mobileScale": mobile_scale,
                "desktopScale": desktop_scale,
                "mobileChunks": len(manifest["mobile"]),
                "desktopChunks": len(manifest["desktop"]),
                "exactReconstruction": True,
            }
        )
    )


if __name__ == "__main__":
    main()
