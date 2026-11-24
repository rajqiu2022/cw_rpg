"""Render the authoritative v7 world-map painting reference.

This image is not runtime art. It is a gameplay-first composition guide for
ImageGen: every cream road is a required visible road and the colored gate
anchors are the only large-map destinations. The final runtime navigation mask
is rebuilt from the same route graph, never from hand-drawn shortcuts.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from build_world_map_v6_navigation import PORTALS, ROUTES


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "processed" / "scene" / "world_map_v7"
OUT = OUT_DIR / "world_map_v7_painting_reference.png"
SIZE = (1536, 1024)


def px(point: tuple[float, float]) -> tuple[int, int]:
    return round(point[0] * SIZE[0]), round(point[1] * SIZE[1])


def font(size: int) -> ImageFont.ImageFont:
    path = Path("C:/Windows/Fonts/msyhbd.ttc")
    return ImageFont.truetype(str(path), size) if path.exists() else ImageFont.load_default()


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    image = Image.new("RGB", SIZE, "#4c5a3f")
    draw = ImageDraw.Draw(image, "RGBA")

    # Broad terrain zoning gives the painter useful context without inventing
    # another route. These areas are all non-walkable in the final contract.
    draw.polygon([px(p) for p in [(0.00, 0.00), (0.30, 0.00), (0.25, 0.45), (0.00, 0.58)]], fill="#6b7480")
    draw.polygon([px(p) for p in [(0.28, 0.00), (0.70, 0.00), (0.64, 0.26), (0.36, 0.30)]], fill="#244a35")
    draw.polygon([px(p) for p in [(0.91, 0.00), (1.00, 0.00), (1.00, 1.00), (0.86, 1.00), (0.88, 0.33)]], fill="#275f74")
    draw.polygon([px(p) for p in [(0.47, 0.37), (0.58, 0.32), (0.66, 0.57), (0.58, 0.68), (0.48, 0.58)]], fill="#326f79")
    draw.polygon([px(p) for p in [(0.72, 0.66), (0.92, 0.63), (0.90, 0.91), (0.71, 0.89)]], fill="#33473b")

    # One exact, high-contrast road graph. The painter must preserve the centre
    # lines and junctions even when adding natural edge variation and texture.
    for route in ROUTES.values():
        points = [px(point) for point in route]
        draw.line(points, fill="#17232a", width=40, joint="curve")
        draw.line(points, fill="#f1d69a", width=27, joint="curve")
        for x, y in points:
            draw.ellipse((x - 14, y - 14, x + 14, y + 14), fill="#f1d69a")

    for entry in PORTALS:
        x, y = px(entry["pos"])
        planned = entry["id"] in {"bailu_ferry", "qinghe_town", "yanmen_pass", "east_sea_port"}
        fill = "#e4a146" if planned else "#bd463d"
        draw.ellipse((x - 17, y - 17, x + 17, y + 17), fill=fill, outline="#fff1c5", width=4)
        label = entry["label"]
        draw.text((x + 21, y - 13), label, font=font(18), fill="#fff6d7", stroke_width=3, stroke_fill="#111b20")

    draw.rectangle((18, 16, 680, 62), fill=(10, 18, 22, 226), outline="#d5bd7f", width=2)
    draw.text((34, 25), "V7硬参考：浅色道路必须逐段保留，禁止新增捷径", font=font(22), fill="#f2dfad")
    image.save(OUT, optimize=True)
    print(OUT)


if __name__ == "__main__":
    main()
