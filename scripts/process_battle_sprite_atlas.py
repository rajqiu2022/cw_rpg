"""Split a 4x5 chroma-key battle atlas into normalized Godot frames.

Rows are ready, move, attack, hit and defeat.  Every frame uses the same
scale derived from the standing rows so action poses never change body size.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image


STATE_NAMES = ("ready", "move", "attack", "hit", "defeat")
CANVAS_SIZE = (512, 384)
TARGET_STANDING_HEIGHT = 300


def remove_magenta(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, alpha = pixels[x, y]
            magenta_distance = max(abs(red - 255), green, abs(blue - 255))
            is_magenta_family = red > 45 and blue > 45 and green < min(red, blue) * 0.62
            if magenta_distance < 52:
                pixels[x, y] = (red, green, blue, 0)
            elif is_magenta_family:
                # Feather anti-aliased chroma edges instead of leaving a halo.
                edge_alpha = max(0, min(255, round(green * 2.2)))
                neutral = min(red, blue, max(green, 24))
                pixels[x, y] = (neutral, green, neutral, min(alpha, edge_alpha))
    return rgba


def keep_largest_component(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    visible = alpha.load()
    visited: set[tuple[int, int]] = set()
    components: list[list[tuple[int, int]]] = []
    for y in range(image.height):
        for x in range(image.width):
            if visible[x, y] < 24 or (x, y) in visited:
                continue
            component: list[tuple[int, int]] = []
            queue = deque([(x, y)])
            visited.add((x, y))
            while queue:
                current = queue.popleft()
                component.append(current)
                cx, cy = current
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if 0 <= nx < image.width and 0 <= ny < image.height and (nx, ny) not in visited and visible[nx, ny] >= 24:
                        visited.add((nx, ny))
                        queue.append((nx, ny))
            components.append(component)
    if not components:
        return image
    keep = set(max(components, key=len))
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            if (x, y) not in keep:
                red, green, blue, _alpha = pixels[x, y]
                pixels[x, y] = (red, green, blue, 0)
    return image


def adaptive_cuts(image: Image.Image, segments: int, axis: str, search_radius: int) -> list[int]:
    """Find cell boundaries in the empty gutters around nominal grid cuts."""
    alpha = image.getchannel("A")
    length = image.height if axis == "y" else image.width
    cross_length = image.width if axis == "y" else image.height
    occupancy: list[int] = []
    for coordinate in range(length):
        visible = 0
        for cross_coordinate in range(cross_length):
            pixel = alpha.getpixel((cross_coordinate, coordinate) if axis == "y" else (coordinate, cross_coordinate))
            if pixel >= 24:
                visible += 1
        occupancy.append(visible)

    cuts = [0]
    for index in range(1, segments):
        expected = round(index * length / segments)
        start = max(cuts[-1] + 1, expected - search_radius)
        end = min(length - 1, expected + search_radius)
        minimum = min(occupancy[start:end + 1])
        candidates = [coordinate for coordinate in range(start, end + 1) if occupancy[coordinate] == minimum]
        runs: list[list[int]] = []
        for coordinate in candidates:
            if not runs or coordinate != runs[-1][-1] + 1:
                runs.append([coordinate])
            else:
                runs[-1].append(coordinate)
        best_run = min(runs, key=lambda run: (abs((run[0] + run[-1]) / 2 - expected), -len(run)))
        cuts.append(round((best_run[0] + best_run[-1]) / 2))
    cuts.append(length)
    return cuts


def split_cells(atlas: Image.Image, row_count: int = 5) -> list[list[Image.Image]]:
    cells: list[list[Image.Image]] = []
    row_cuts = adaptive_cuts(atlas, row_count, "y", 70)
    for row in range(row_count):
        row_cells: list[Image.Image] = []
        top = row_cuts[row]
        bottom = row_cuts[row + 1]
        row_image = atlas.crop((0, top, atlas.width, bottom))
        column_cuts = adaptive_cuts(row_image, 4, "x", 90)
        for column in range(4):
            left = column_cuts[column]
            right = column_cuts[column + 1]
            row_cells.append(keep_largest_component(row_image.crop((left, 0, right, row_image.height))))
        cells.append(row_cells)
    return cells


def content_box(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError("atlas cell has no visible sprite")
    return bbox


def normalize_cells(
    cells: list[list[Image.Image]],
    output_dir: Path,
    prefix: str,
    state_names: tuple[str, ...] = STATE_NAMES,
) -> None:
    # The ready row is the only reliable standing-height reference. Attack and
    # hit poses may crouch or stretch, so mixing them into the median can make
    # the entire actor up to 350px tall and inconsistent with existing units.
    if "ready" in state_names:
        scale_rows = [state_names.index("ready")]
    else:
        scale_rows = range(len(cells))
    standing_heights = [
        content_box(cells[row][column])[3] - content_box(cells[row][column])[1]
        for row in scale_rows
        for column in range(4)
    ]
    standing_heights.sort()
    median_height = standing_heights[len(standing_heights) // 2]
    uniform_scale = TARGET_STANDING_HEIGHT / max(1, median_height)

    output_dir.mkdir(parents=True, exist_ok=True)
    for row, state in enumerate(state_names):
        for column, cell in enumerate(cells[row], start=1):
            bbox = content_box(cell)
            sprite = cell.crop(bbox)
            scaled_size = (
                max(1, round(sprite.width * uniform_scale)),
                max(1, round(sprite.height * uniform_scale)),
            )
            if scaled_size[0] > 480 or scaled_size[1] > 350:
                fit = min(480 / scaled_size[0], 350 / scaled_size[1])
                scaled_size = (round(scaled_size[0] * fit), round(scaled_size[1] * fit))
            sprite = sprite.resize(scaled_size, Image.Resampling.LANCZOS)
            canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
            x = (CANVAS_SIZE[0] - sprite.width) // 2
            y = CANVAS_SIZE[1] - sprite.height - 12
            canvas.alpha_composite(sprite, (x, y))
            canvas.save(output_dir / f"{prefix}_{state}_{column:02d}.png")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("atlas", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("prefix")
    parser.add_argument(
        "--states",
        default=",".join(STATE_NAMES),
        help="Comma-separated row names from top to bottom; defaults to ready,move,attack,hit,defeat",
    )
    args = parser.parse_args()

    state_names = tuple(state.strip() for state in args.states.split(",") if state.strip())
    if not state_names:
        parser.error("--states must include at least one row name")
    atlas = remove_magenta(Image.open(args.atlas))
    normalize_cells(split_cells(atlas, len(state_names)), args.output_dir, args.prefix, state_names)


if __name__ == "__main__":
    main()
