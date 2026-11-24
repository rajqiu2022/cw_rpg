"""Render the approved world-map topology before painted art is generated.

This blueprint is deliberately gameplay-first: roads are the walkable network;
mountains, forests and water are blockers.  The painter receives this image as
an authoritative composition reference, while Godot uses the same coordinates
from ``world_map_jianghu_layout_v4.tres``.
"""

from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "processed" / "scene" / "world_map_v4"
OUT_PATH = OUT_DIR / "world_map_walkability_design_v4.png"
SIZE = (2304, 1536)

NODES = {
    # Playable settlements / sects
    "凌月山": (0.14, 0.17),
    "华山": (0.13, 0.40),
    "武当山": (0.54, 0.16),
    "古月峰": (0.48, 0.40),
    "洛阳": (0.72, 0.45),
    "林西村": (0.16, 0.75),
    "竹尾村": (0.29, 0.70),
    "茗雾山": (0.82, 0.78),
    # Expansion anchors; visible geography now, content can be added later.
    "白鹿渡": (0.51, 0.72),
    "清河镇": (0.66, 0.79),
    "雁门关": (0.82, 0.18),
    "东海埠": (0.91, 0.56),
}

WILDS = {
    "北林旧道 2~5": (0.34, 0.22),
    "后山洞窟 2~3": (0.33, 0.56),
    "竹影密林 2~4": (0.36, 0.67),
    "城西废宅 3~5": (0.39, 0.58),
    "河谷营地 4~6": (0.56, 0.54),
    "洛阳漕渠 4~7": (0.80, 0.55),
    "古寺地道 5~9": (0.84, 0.67),
    "云岭险道 8~12": (0.64, 0.31),
    "海崖古港 10~16": (0.88, 0.43),
}

# Each polyline is a continuous road.  Only these corridors are walkable.
ROUTES = [
    # Southwest first-chapter cluster: Linxi and Zhuwei are direct neighbours.
    [(0.16, 0.75), (0.22, 0.72), (0.29, 0.70), (0.36, 0.67)],
    [(0.29, 0.70), (0.33, 0.62), (0.33, 0.56)],
    [(0.36, 0.67), (0.39, 0.58), (0.47, 0.60), (0.51, 0.72)],
    # Western mountain road.
    [(0.16, 0.75), (0.11, 0.61), (0.13, 0.40), (0.14, 0.17)],
    [(0.14, 0.17), (0.24, 0.18), (0.34, 0.22), (0.44, 0.20), (0.54, 0.16)],
    # Central spine and river crossing.
    [(0.34, 0.22), (0.40, 0.31), (0.48, 0.40), (0.56, 0.54), (0.51, 0.72)],
    [(0.48, 0.40), (0.58, 0.43), (0.72, 0.45)],
    [(0.54, 0.16), (0.64, 0.31), (0.72, 0.45)],
    # Eastern city, coast and southeast mist mountain.
    [(0.72, 0.45), (0.80, 0.55), (0.91, 0.56)],
    [(0.80, 0.55), (0.84, 0.67), (0.82, 0.78)],
    [(0.51, 0.72), (0.66, 0.79), (0.82, 0.78)],
    [(0.72, 0.45), (0.79, 0.33), (0.82, 0.18)],
    [(0.82, 0.18), (0.87, 0.30), (0.88, 0.43), (0.91, 0.56)],
]


def px(point: tuple[float, float]) -> tuple[int, int]:
    return int(point[0] * SIZE[0]), int(point[1] * SIZE[1])


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        Path("C:/Windows/Fonts/msyhbd.ttc" if bold else "C:/Windows/Fonts/msyh.ttc"),
        Path("C:/Windows/Fonts/simhei.ttf"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def label(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, fill: str) -> None:
    f = font(27, True)
    bbox = draw.textbbox((0, 0), text, font=f, stroke_width=2)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x, y = xy[0] - w // 2, xy[1] + 24
    draw.rounded_rectangle((x - 8, y - 5, x + w + 8, y + h + 7), 8, fill=(13, 21, 24, 224))
    draw.text((x, y), text, font=f, fill=fill, stroke_width=2, stroke_fill="#0a0f12")


def draw_routes(draw: ImageDraw.ImageDraw, routes: Iterable[list[tuple[float, float]]]) -> None:
    for route in routes:
        points = [px(point) for point in route]
        draw.line(points, fill="#1b2830", width=52, joint="curve")
        draw.line(points, fill="#e6c77b", width=36, joint="curve")
        for point in points:
            draw.ellipse((point[0] - 18, point[1] - 18, point[0] + 18, point[1] + 18), fill="#e6c77b")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    image = Image.new("RGB", SIZE, "#273934")
    draw = ImageDraw.Draw(image, "RGBA")

    # Gameplay blockers: mountains, forests and water.  These are composition
    # zones, not collision polygons; the final collision is the road network.
    draw.polygon([px(p) for p in [(0.00, 0.00), (0.30, 0.00), (0.24, 0.47), (0.00, 0.58)]], fill="#4c4037")
    draw.polygon([px(p) for p in [(0.29, 0.00), (0.68, 0.00), (0.59, 0.35), (0.38, 0.32)]], fill="#355346")
    draw.polygon([px(p) for p in [(0.00, 0.82), (0.34, 0.77), (0.45, 1.00), (0.00, 1.00)]], fill="#375240")
    draw.polygon([px(p) for p in [(0.73, 0.00), (1.00, 0.00), (1.00, 0.43), (0.88, 0.37)]], fill="#4b413b")
    draw.polygon([px(p) for p in [(0.92, 0.30), (1.00, 0.34), (1.00, 1.00), (0.86, 1.00), (0.88, 0.72)]], fill="#2e6a78")
    draw.polygon([px(p) for p in [(0.57, 0.36), (0.64, 0.40), (0.69, 0.58), (0.62, 0.70), (0.55, 0.62)]], fill="#2e6a78")

    draw_routes(draw, ROUTES)

    for name, point in NODES.items():
        x, y = px(point)
        planned = name in {"白鹿渡", "清河镇", "雁门关", "东海埠"}
        fill = "#83919a" if planned else "#d8503d"
        draw.ellipse((x - 23, y - 23, x + 23, y + 23), fill=fill, outline="#f5e9c7", width=5)
        label(draw, (x, y), name + (" · 预留" if planned else ""), fill)

    for name, point in WILDS.items():
        x, y = px(point)
        draw.polygon([(x, y - 22), (x + 22, y), (x, y + 22), (x - 22, y)], fill="#e6a93f", outline="#fff0b2")
        label(draw, (x, y), name, "#e6a93f")

    title_font = font(46, True)
    draw.rounded_rectangle((48, 38, 935, 116), 18, fill=(8, 15, 19, 225), outline="#9db8b4", width=3)
    draw.text((72, 51), "江湖大地图 v4｜先路线、后绘景", font=title_font, fill="#f0dfb0")
    legend_font = font(24)
    draw.rounded_rectangle((1570, 1320, 2250, 1488), 16, fill=(8, 15, 19, 220), outline="#9db8b4", width=3)
    draw.text((1595, 1340), "浅金路：唯一可行走区域", font=legend_font, fill="#e6c77b")
    draw.text((1595, 1380), "红点：已接入据点　灰点：扩展预留", font=legend_font, fill="#d7e0df")
    draw.text((1595, 1420), "橙菱：野外场景（标注建议等级）", font=legend_font, fill="#e6a93f")
    image.save(OUT_PATH, optimize=True)
    print(OUT_PATH)


if __name__ == "__main__":
    main()
