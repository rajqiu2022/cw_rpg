"""Slice the generated quest UI candidate atlases into Godot-ready textures."""

from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "assets" / "raw" / "ui" / "quest"
OUT = ROOT / "game" / "art" / "ui" / "quest" / "runtime_v1"


def _remove_connected_matte(image: Image.Image) -> Image.Image:
    """Turn only edge-connected black atlas matte transparent."""
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    queue: deque[tuple[int, int]] = deque()
    seen: set[tuple[int, int]] = set()

    def is_matte(x: int, y: int) -> bool:
        r, g, b, _a = pixels[x, y]
        return r < 22 and g < 25 and b < 28

    for x in range(width):
        queue.extend(((x, 0), (x, height - 1)))
    for y in range(height):
        queue.extend(((0, y), (width - 1, y)))

    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or not (0 <= x < width and 0 <= y < height):
            continue
        seen.add((x, y))
        if not is_matte(x, y):
            continue
        pixels[x, y] = (*pixels[x, y][:3], 0)
        queue.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return image


def _slice(source_name: str, boxes: list[tuple[int, int, int, int]], names: list[str]) -> None:
    source = Image.open(RAW / source_name)
    for box, name in zip(boxes, names, strict=True):
        result = _remove_connected_matte(source.crop(box))
        result.save(OUT / name)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "panel_bg_v5.png").write_bytes((RAW / "ui_quest_runtime_panel_v5.png").read_bytes())

    _slice(
        "ui_quest_primary_tab_atlas_v1.png",
        [(18, 415, 375, 590), (395, 415, 770, 590), (780, 415, 1145, 590), (1152, 415, 1532, 590)],
        ["primary_normal.png", "primary_selected.png", "primary_hover.png", "primary_pressed.png"],
    )
    _slice(
        "ui_quest_secondary_tab_atlas_v1.png",
        [(35, 420, 390, 590), (405, 420, 770, 590), (780, 420, 1145, 590), (1155, 420, 1525, 590)],
        ["secondary_normal.png", "secondary_selected.png", "secondary_hover.png", "secondary_pressed.png"],
    )
    _slice(
        "ui_quest_chapter_dropdown_atlas_v1.png",
        [(20, 410, 505, 610), (520, 410, 1010, 610), (1025, 410, 1520, 610)],
        ["chapter_normal.png", "chapter_hover.png", "chapter_open.png"],
    )
    _slice(
        "ui_quest_reward_slot_atlas_v1.png",
        [(45, 400, 510, 830), (530, 400, 1010, 830), (1020, 400, 1510, 830)],
        ["reward_normal.png", "reward_hover.png", "reward_selected.png"],
    )
    _slice(
        "ui_quest_track_button_atlas_v1.png",
        [(15, 405, 510, 630), (515, 405, 1015, 630), (1020, 405, 1525, 630)],
        ["track_normal.png", "track_hover.png", "track_pressed.png"],
    )


if __name__ == "__main__":
    main()
