from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "processed" / "scene" / "cave_maze_v1"
SIZE = (1536, 1024)


def font(size: int):
    candidates = [
        Path("C:/Windows/Fonts/msyh.ttc"),
        Path("C:/Windows/Fonts/simhei.ttf"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def poly(draw: ImageDraw.ImageDraw, points, fill, outline=None, width=4):
    pixels = [(round(x * SIZE[0]), round(y * SIZE[1])) for x, y in points]
    draw.polygon(pixels, fill=fill, outline=outline, width=width)


def marker(draw, pos, title, color):
    x, y = round(pos[0] * SIZE[0]), round(pos[1] * SIZE[1])
    draw.ellipse((x - 25, y - 25, x + 25, y + 25), fill=color, outline="#ffffff", width=4)
    draw.text((x + 34, y - 22), title, fill="#ffffff", font=font(27), stroke_width=3, stroke_fill="#111111")


def base(title, subtitle):
    image = Image.new("RGB", SIZE, "#111820")
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 0, SIZE[0] - 1, SIZE[1] - 1), outline="#708090", width=6)
    draw.text((42, 30), title, fill="#f5d58a", font=font(42))
    draw.text((44, 86), subtitle, fill="#bec8cf", font=font(24))
    return image, draw


def mine_gallery():
    image, draw = base("废弃矿道 · 行走区域", "入口在左下，深窟出口在右上；中央岩柱形成环路，宝箱为可选探索点")
    # Broad loop around a central rock pillar.
    poly(draw, [(0.08, 0.88), (0.08, 0.62), (0.18, 0.48), (0.28, 0.44), (0.36, 0.32),
                (0.60, 0.28), (0.73, 0.18), (0.91, 0.14), (0.94, 0.31), (0.78, 0.42),
                (0.62, 0.48), (0.48, 0.58), (0.34, 0.70), (0.23, 0.91)], "#5f8d64", "#b8e0a7")
    poly(draw, [(0.18, 0.48), (0.27, 0.26), (0.42, 0.18), (0.60, 0.28), (0.52, 0.43),
                (0.38, 0.50), (0.28, 0.61)], "#5f8d64", "#b8e0a7")
    poly(draw, [(0.34, 0.70), (0.48, 0.58), (0.62, 0.48), (0.73, 0.58), (0.61, 0.74),
                (0.47, 0.82)], "#5f8d64", "#b8e0a7")
    poly(draw, [(0.38, 0.50), (0.52, 0.43), (0.62, 0.48), (0.48, 0.58)], "#26343a", "#ff8d62")
    marker(draw, (0.12, 0.82), "返回入口营地", "#4fb4ff")
    marker(draw, (0.89, 0.22), "通往头狼深窟", "#ff6f61")
    marker(draw, (0.30, 0.27), "旧木箱", "#e8b85e")
    marker(draw, (0.68, 0.61), "废弃矿车", "#d28b48")
    return image


def waterway():
    image, draw = base("地下水道 · 行走区域", "入口在右下，深窟出口在左上；干燥岩台与踏石水路绕过地下水潭后汇合")
    poly(draw, [(0.92, 0.88), (0.90, 0.64), (0.79, 0.52), (0.69, 0.44), (0.57, 0.36),
                (0.43, 0.28), (0.25, 0.19), (0.08, 0.17), (0.07, 0.34), (0.24, 0.40),
                (0.39, 0.48), (0.56, 0.56), (0.72, 0.70), (0.80, 0.91)], "#5f8d64", "#b8e0a7")
    poly(draw, [(0.80, 0.91), (0.66, 0.84), (0.54, 0.75), (0.42, 0.64), (0.30, 0.55),
                (0.24, 0.40), (0.39, 0.48), (0.56, 0.56), (0.72, 0.70)], "#5f8d64", "#b8e0a7")
    poly(draw, [(0.36, 0.56), (0.43, 0.43), (0.58, 0.43), (0.66, 0.58), (0.56, 0.71),
                (0.42, 0.67)], "#254b59", "#6dd4ee")
    marker(draw, (0.88, 0.82), "返回入口营地", "#4fb4ff")
    marker(draw, (0.12, 0.24), "通往头狼深窟", "#ff6f61")
    marker(draw, (0.68, 0.76), "遗落补给", "#e8b85e")
    return image


def deep_den():
    image, draw = base("头狼深窟 · 行走区域", "左右入口来自两条支路；中央为战斗区，击败头狼后调查封蜡货筒")
    poly(draw, [(0.06, 0.88), (0.08, 0.60), (0.20, 0.48), (0.34, 0.40), (0.66, 0.40),
                (0.80, 0.48), (0.92, 0.60), (0.94, 0.88), (0.78, 0.89), (0.68, 0.74),
                (0.32, 0.74), (0.22, 0.89)], "#5f8d64", "#b8e0a7")
    poly(draw, [(0.20, 0.48), (0.25, 0.20), (0.40, 0.12), (0.60, 0.12), (0.75, 0.20),
                (0.80, 0.48), (0.66, 0.40), (0.34, 0.40)], "#5f8d64", "#b8e0a7")
    marker(draw, (0.12, 0.82), "返回废弃矿道", "#4fb4ff")
    marker(draw, (0.88, 0.82), "返回地下水道", "#4fb4ff")
    marker(draw, (0.50, 0.45), "头狼战斗区", "#ff6f61")
    marker(draw, (0.50, 0.20), "封蜡货筒", "#e8b85e")
    return image


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    images = {
        "cave_mine_gallery_walkability_v1.png": mine_gallery(),
        "cave_waterway_walkability_v1.png": waterway(),
        "cave_deep_den_walkability_v1.png": deep_den(),
    }
    for name, image in images.items():
        image.save(OUT / name, optimize=True)
        print(OUT / name)


if __name__ == "__main__":
    main()
