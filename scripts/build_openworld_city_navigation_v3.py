"""Build realistic runtime city/ferry art plus reviewed navigation masks.

White pixels are the only legal player-foot positions.  These masks deliberately
exclude decorative paving behind fences, roofs, market awnings and water even
when those pixels visually resemble ground.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
MASK_DIR = ROOT / "game/art/navigation_masks/openworld_city_v3"
REVIEW_DIR = ROOT / "assets/processed/scene/openworld_city_v3"


def polygon(draw: ImageDraw.ImageDraw, points: list[tuple[float, float]], size: tuple[int, int]) -> None:
    draw.polygon([(round(x * size[0]), round(y * size[1])) for x, y in points], fill=255)


def mask_for(
    name: str,
    regions: list[list[tuple[float, float]]],
    blocked: list[list[tuple[float, float]]] | None = None,
    size: tuple[int, int] = (768, 512),
) -> Image.Image:
    image = Image.new("L", size, 0)
    draw = ImageDraw.Draw(image)
    for region in regions:
        polygon(draw, region, size)
    for region in blocked or []:
        draw.polygon([(round(x * size[0]), round(y * size[1])) for x, y in region], fill=0)
    # Reserve a real foot-clearance margin around every fence, planter, roof and
    # quay edge.  The authored white lane is a center line area, not permission
    # for the actor sprite to overlap the neighbouring prop.
    image = image.filter(ImageFilter.MinFilter(7))
    image.save(MASK_DIR / f"{name}_walk_v3.png", optimize=True)
    return image


def review(name: str, background: Path, mask: Image.Image) -> None:
    base = Image.open(background).convert("RGBA")
    scaled = mask.resize(base.size, Image.Resampling.NEAREST)
    tint = Image.new("RGBA", base.size, (0, 245, 180, 0))
    tint.putalpha(scaled.point(lambda value: 86 if value else 0))
    Image.alpha_composite(base, tint).save(REVIEW_DIR / f"{name}_navigation_review.png", optimize=True)


def build_tree_mask() -> None:
    size = (768, 512)
    rgba = Image.new("RGBA", size, (255, 255, 255, 0))
    draw = ImageDraw.Draw(rgba)
    # The large lower-right校场 tree: several overlapping ellipses follow the
    # canopy instead of fading the nearby lantern, wall or stone paving.
    ellipses = [
        (0.470, 0.425, 0.600, 0.590),
        (0.535, 0.390, 0.690, 0.585),
        (0.500, 0.500, 0.675, 0.710),
        (0.590, 0.470, 0.735, 0.665),
    ]
    for x0, y0, x1, y1 in ellipses:
        draw.ellipse((round(x0 * size[0]), round(y0 * size[1]), round(x1 * size[0]), round(y1 * size[1])), fill=(255, 255, 255, 255))
    rgba.save(MASK_DIR / "xiangzhou_lower_tree_canopy_mask_v1.png", optimize=True)


def main() -> None:
    MASK_DIR.mkdir(parents=True, exist_ok=True)
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)

    city_sources = ROOT / "game/art/backgrounds/openworld_cities_v2"
    definitions = {
        "bianzhou": {
            "walk": [
            [(0.385, 0.0), (0.625, 0.0), (0.625, 1.0), (0.385, 1.0)],
            [(0.155, 0.275), (0.845, 0.275), (0.845, 0.690), (0.155, 0.690)],
            [(0.225, 0.215), (0.775, 0.215), (0.805, 0.320), (0.760, 0.755), (0.240, 0.755), (0.195, 0.320)],
            ],
            "blocked": [
                [(0.090, 0.360), (0.255, 0.360), (0.255, 0.625), (0.090, 0.625)],
                [(0.725, 0.285), (0.895, 0.285), (0.895, 0.585), (0.725, 0.585)],
                [(0.170, 0.665), (0.375, 0.665), (0.375, 0.825), (0.170, 0.825)],
                [(0.630, 0.665), (0.840, 0.665), (0.840, 0.825), (0.630, 0.825)],
            ],
        },
        "xiangzhou": {
            "walk": [
            [(0.455, 0.0), (0.645, 0.0), (0.665, 0.555), (0.555, 0.625), (0.445, 0.555)],
            [(0.045, 0.350), (0.390, 0.350), (0.390, 0.615), (0.045, 0.615)],
            [(0.270, 0.600), (0.640, 0.600), (0.640, 1.0), (0.270, 1.0)],
            [(0.315, 0.420), (0.565, 0.420), (0.565, 0.735), (0.315, 0.735)],
            [(0.560, 0.305), (0.660, 0.305), (0.660, 0.850), (0.560, 0.850)],
            ],
            "blocked": [
                [(0.025, 0.235), (0.420, 0.235), (0.420, 0.355), (0.025, 0.355)],
                [(0.405, 0.315), (0.505, 0.315), (0.505, 0.565), (0.405, 0.565)],
                [(0.665, 0.180), (1.000, 0.180), (1.000, 1.000), (0.665, 1.000)],
                [(0.355, 0.545), (0.545, 0.545), (0.545, 0.680), (0.355, 0.680)],
                [(0.000, 0.715), (0.265, 0.715), (0.265, 1.000), (0.000, 1.000)],
            ],
        },
        "jinling": {
            "walk": [
            [(0.275, 0.135), (0.725, 0.135), (0.780, 0.220), (0.745, 0.650), (0.255, 0.650), (0.215, 0.225)],
            [(0.330, 0.555), (0.670, 0.555), (0.670, 1.0), (0.330, 1.0)],
            [(0.000, 0.020), (0.165, 0.020), (0.235, 0.145), (0.185, 0.250), (0.000, 0.185)],
            ],
            "blocked": [
                [(0.225, 0.115), (0.410, 0.115), (0.410, 0.300), (0.225, 0.300)],
                [(0.655, 0.120), (0.805, 0.120), (0.805, 0.340), (0.655, 0.340)],
            ],
        },
        "bailu_ferry": {
            "walk": [
            [(0.115, 0.0), (0.285, 0.0), (0.400, 0.265), (0.325, 0.335), (0.175, 0.205), (0.110, 0.075)],
            [(0.235, 0.275), (0.410, 0.245), (0.475, 0.320), (0.490, 0.455), (0.505, 0.565), (0.475, 0.690), (0.275, 0.690), (0.235, 0.600)],
            [(0.285, 0.650), (0.445, 0.650), (0.495, 1.0), (0.355, 1.0)],
            ],
            "blocked": [
                [(0.000, 0.300), (0.225, 0.300), (0.225, 0.745), (0.000, 0.745)],
                [(0.430, 0.285), (0.615, 0.285), (0.615, 0.595), (0.430, 0.595)],
                [(0.180, 0.440), (0.345, 0.440), (0.345, 0.635), (0.180, 0.635)],
                [(0.385, 0.000), (0.720, 0.000), (0.720, 0.275), (0.385, 0.275)],
                [(0.000, 0.720), (0.255, 0.720), (0.255, 1.000), (0.000, 1.000)],
                [(0.555, 0.610), (1.000, 0.610), (1.000, 1.000), (0.555, 1.000)],
                [(0.615, 0.000), (1.000, 0.000), (1.000, 0.610), (0.615, 0.610)],
            ],
        },
    }

    for name in ("bianzhou", "xiangzhou", "jinling"):
        mask = mask_for(name, definitions[name]["walk"], definitions[name]["blocked"])
        filename = {
            "bianzhou": "bg_bianzhou_market_gameplay_v2_3072.png",
            "xiangzhou": "bg_xiangzhou_garrison_gameplay_v2_3072.png",
            "jinling": "bg_jinling_bridge_market_gameplay_v2_3072.png",
        }[name]
        review(name, city_sources / filename, mask)

    ferry_source = ROOT / "assets/raw/scene_background/bailu_ferry_v2/bg_bailu_ferry_gameplay_v2_source.png"
    ferry_runtime = ROOT / "game/art/backgrounds/openworld_ferry_v2/bg_bailu_ferry_gameplay_v2_3072.png"
    ferry_runtime.parent.mkdir(parents=True, exist_ok=True)
    Image.open(ferry_source).convert("RGB").resize((3072, 2048), Image.Resampling.LANCZOS).save(
        ferry_runtime, optimize=True, compress_level=6
    )
    ferry_mask = mask_for("bailu_ferry", definitions["bailu_ferry"]["walk"], definitions["bailu_ferry"]["blocked"])
    review("bailu_ferry", ferry_runtime, ferry_mask)
    build_tree_mask()


if __name__ == "__main__":
    main()
