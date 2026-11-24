"""Convert one AI 4x4 or 8x4 character atlas into stable 160px field strips."""

from __future__ import annotations

import argparse
import colorsys
from collections import deque
from pathlib import Path

from PIL import Image


DEFAULT_DIRECTIONS = ("down", "up", "right", "left")
CANVAS = 160
BODY_HEIGHT = 140
BOTTOM_MARGIN = 8
CHROMA = (255, 0, 255)


def remove_chroma(image: Image.Image, tolerance: int = 76) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    queue: deque[tuple[int, int]] = deque()
    seen: set[tuple[int, int]] = set()

    corner = pixels[0, 0][:3]
    # Generated chroma plates are not always byte-exact #FF00FF. Detect the
    # saturated magenta family as well, otherwise one cell can retain an opaque
    # pink rectangle while neighbouring cells key correctly.
    is_magenta_source = (
        sum(abs(corner[index] - CHROMA[index]) for index in range(3)) <= tolerance
        or (corner[0] >= 180 and corner[2] >= 180 and corner[1] <= 100)
    )
    if is_magenta_source:
        # Remove the semi-transparent magenta halo generated around some
        # figures as well as the flat key itself.
        for y in range(height):
            for x in range(width):
                r, g, b, _a = pixels[x, y]
                is_key = abs(r - CHROMA[0]) + abs(g - CHROMA[1]) + abs(b - CHROMA[2]) <= tolerance
                is_magenta_spill = r > 45 and b > 100 and g < 85 and abs(r - b) < 150
                hue, saturation, value = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
                is_magenta_hue = 0.78 <= hue <= 0.96 and saturation >= 0.45 and value >= 0.28
                if is_key or is_magenta_spill or is_magenta_hue:
                    pixels[x, y] = (r, g, b, 0)

    def is_background(x: int, y: int) -> bool:
        r, g, b, _a = pixels[x, y]
        if is_magenta_source:
            return abs(r - CHROMA[0]) + abs(g - CHROMA[1]) + abs(b - CHROMA[2]) <= tolerance
        # Some providers sanitize a chroma-key request into a neutral grey
        # checker/grid. The generated characters use saturated cloth and skin,
        # so an edge-connected neutral grey is safe to discard.
        return max(r, g, b) - min(r, g, b) <= 14 and (r + g + b) // 3 >= 50

    def enqueue(x: int, y: int) -> None:
        if (x, y) not in seen and is_background(x, y):
            seen.add((x, y))
            queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)
    while queue:
        x, y = queue.popleft()
        pixels[x, y] = (*pixels[x, y][:3], 0)
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height:
                enqueue(nx, ny)
    return image


def keep_largest_component(image: Image.Image) -> Image.Image:
    pixels = image.load()
    width, height = image.size
    seen: set[tuple[int, int]] = set()
    components: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            if (x, y) in seen or pixels[x, y][3] == 0:
                continue
            queue: deque[tuple[int, int]] = deque([(x, y)])
            seen.add((x, y))
            component: list[tuple[int, int]] = []
            while queue:
                cx, cy = queue.popleft()
                component.append((cx, cy))
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in seen and pixels[nx, ny][3] > 0:
                        seen.add((nx, ny))
                        queue.append((nx, ny))
            components.append(component)
    if not components:
        raise ValueError("sprite cell is empty after chroma removal")
    for component in components:
        # Thin hair locks, a separated hand and the sword hilt can become
        # detached after chroma removal. Keep all visible silhouette pieces;
        # only discard tiny single-pixel compression flecks.
        if len(component) < 24:
            for x, y in component:
                r, g, b, _a = pixels[x, y]
                pixels[x, y] = (r, g, b, 0)
    return image


def anchored_frame(
    cell: Image.Image,
    bottom_margin: int = BOTTOM_MARGIN,
    preserve_cell_scale: bool = False,
) -> Image.Image:
    if bottom_margin < 0 or BODY_HEIGHT + bottom_margin > CANVAS:
        raise ValueError(
            f"bottom margin must be between 0 and {CANVAS - BODY_HEIGHT}, got {bottom_margin}"
        )
    cell = keep_largest_component(remove_chroma(cell))
    bbox = cell.getbbox()
    if bbox is None:
        raise ValueError("empty sprite frame")
    # Padding a frame after it has already been cut cannot restore an amputated
    # topknot or boot. Reject source cells whose visible content reaches the
    # crop boundary, so cross-cell body parts never get "washed clean" by the
    # runtime normalizer.
    safe_margin = max(4, round(min(cell.size) * 0.025))
    left, top, right, bottom = bbox
    margins = (left, top, cell.width - right, cell.height - bottom)
    if min(margins) < safe_margin:
        raise ValueError(
            f"source sprite touches a cell boundary: margins={margins}, required>={safe_margin}"
        )
    if preserve_cell_scale:
        # New 8x4 atlases are authored with identical square cells and shared
        # character scale. Resize the complete cell instead of fitting its
        # alpha bbox: bbox fitting would shrink the staff user merely because
        # the staff extends above the head.
        return cell.resize((CANVAS, CANVAS), Image.Resampling.LANCZOS)
    sprite = cell.crop(bbox)
    scale = BODY_HEIGHT / sprite.height
    sprite = sprite.resize((max(1, round(sprite.width * scale)), BODY_HEIGHT), Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    frame.alpha_composite(
        sprite,
        ((CANVAS - sprite.width) // 2, CANVAS - BODY_HEIGHT - bottom_margin),
    )
    return frame


def save_strip(frames: list[Image.Image], output: Path) -> None:
    strip = Image.new("RGBA", (CANVAS * len(frames), CANVAS), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        strip.alpha_composite(frame, (index * CANVAS, 0))
    output.parent.mkdir(parents=True, exist_ok=True)
    strip.save(output)


def adaptive_cuts(image: Image.Image, segments: int, axis: str, search_radius: int) -> list[int]:
    """Find empty gutters near nominal grid boundaries.

    Image generators often keep a visually regular 4x4 grid while letting a
    long staff or a pair of boots cross the exact quarter-pixel boundary. A
    fixed crop then amputates the character even though the source is intact.
    """
    alpha = image.getchannel("A")
    length = image.height if axis == "y" else image.width
    cross_length = image.width if axis == "y" else image.height
    occupancy: list[int] = []
    for coordinate in range(length):
        visible = 0
        for cross_coordinate in range(cross_length):
            point = (cross_coordinate, coordinate) if axis == "y" else (coordinate, cross_coordinate)
            if alpha.getpixel(point) >= 24:
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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--prefix", required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--preview", type=Path)
    parser.add_argument("--idle-from-source", action="store_true")
    parser.add_argument(
        "--directions",
        default=",".join(DEFAULT_DIRECTIONS),
        help="Comma-separated row order, for example down,up,left,right",
    )
    parser.add_argument(
        "--adaptive-grid",
        action="store_true",
        help="Find transparent gutters near the 4x4 boundaries instead of cutting at exact quarters",
    )
    parser.add_argument(
        "--columns",
        type=int,
        choices=(4, 8),
        help="Source atlas columns. Defaults to aspect-ratio inference (4 or 8).",
    )
    parser.add_argument(
        "--bottom-margin",
        type=int,
        default=BOTTOM_MARGIN,
        help=f"Transparent pixels below the feet (default: {BOTTOM_MARGIN})",
    )
    args = parser.parse_args()
    directions = tuple(value.strip() for value in args.directions.split(",") if value.strip())
    if len(directions) != 4 or set(directions) != {"down", "up", "left", "right"}:
        parser.error("--directions must contain down,up,left,right exactly once")
    atlas = Image.open(args.source).convert("RGBA")
    columns = args.columns
    if columns is None:
        inferred = round(atlas.width / atlas.height * 4)
        if inferred not in (4, 8):
            raise ValueError(
                f"Cannot infer a 4x4 or 8x4 atlas from {atlas.size}; pass --columns explicitly"
            )
        columns = inferred
    expected_ratio = columns / 4
    actual_ratio = atlas.width / atlas.height
    if abs(actual_ratio - expected_ratio) > 0.06:
        raise ValueError(
            f"Expected a {columns}x4 atlas near ratio {expected_ratio:.2f}, got {atlas.size}"
        )
    row_cuts = adaptive_cuts(atlas, 4, "y", max(24, atlas.height // 18)) if args.adaptive_grid else [
        round(index * atlas.height / 4) for index in range(5)
    ]
    preview = Image.new("RGBA", (CANVAS * columns, CANVAS * 4), (24, 22, 28, 255))
    for row, direction in enumerate(directions):
        row_image = atlas.crop((0, row_cuts[row], atlas.width, row_cuts[row + 1]))
        column_cuts = adaptive_cuts(row_image, columns, "x", max(16, atlas.width // (columns * 5))) if args.adaptive_grid else [
            round(index * atlas.width / columns) for index in range(columns + 1)
        ]
        frames = [
            anchored_frame(
                row_image.crop((
                    column_cuts[column],
                    0,
                    column_cuts[column + 1],
                    row_image.height,
                )),
                args.bottom_margin,
                columns == 8,
            )
            for column in range(columns)
        ]
        # An 8-column source is already the authored full cycle. Legacy 4-column
        # sources repeat the complete 4-pose cycle instead of holding every pose
        # twice; holding frames caused the feet to look almost motionless.
        walk = [frame.copy() for frame in frames]
        if columns == 4:
            walk.extend(frame.copy() for frame in frames)
        idle = [frames[index].copy() for index in range(4)] if args.idle_from_source else [frames[0].copy() for _ in range(4)]
        save_strip(walk, args.output_dir / f"{args.prefix}_walk_{direction}_25d_8f.png")
        save_strip(idle, args.output_dir / f"{args.prefix}_idle_{direction}_25d_4f.png")
        for column, frame in enumerate(frames):
            preview.alpha_composite(frame, (column * CANVAS, row * CANVAS))
    if args.preview:
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        preview.save(args.preview)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
