"""Slice the generated skill UI panel and control atlas into runtime textures."""

from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "assets" / "raw" / "ui" / "skill"
OUT = ROOT / "game" / "art" / "ui" / "skill" / "runtime_v2"


def remove_connected_matte(image: Image.Image) -> Image.Image:
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


def slice_atlas(source_name: str, entries: list[tuple[str, tuple[int, int, int, int]]]) -> None:
    source = Image.open(RAW / source_name)
    for name, box in entries:
        remove_connected_matte(source.crop(box)).save(OUT / name)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "panel_bg_v3.png").write_bytes((RAW / "ui_skill_panel_runtime_v3.png").read_bytes())
    slice_atlas(
        "ui_skill_controls_runtime_v2.png",
        [
            ("primary_tab_normal.png", (25, 56, 384, 283)),
            ("primary_tab_selected.png", (788, 69, 1500, 274)),
            ("secondary_tab_01.png", (47, 319, 339, 393)),
            ("secondary_tab_02.png", (374, 319, 640, 393)),
            ("secondary_tab_03.png", (666, 319, 916, 393)),
            ("secondary_tab_04.png", (948, 320, 1192, 393)),
            ("secondary_tab_05.png", (1219, 320, 1481, 394)),
            ("skill_row_normal.png", (49, 434, 752, 592)),
            ("skill_row_selected.png", (786, 434, 1495, 592)),
            ("stat_cell.png", (51, 670, 304, 760)),
            ("skill_icon_frame.png", (378, 629, 555, 798)),
            ("faction_badge.png", (605, 625, 763, 798)),
            ("insight_strip.png", (817, 670, 1492, 765)),
            ("upgrade_normal.png", (48, 845, 380, 966)),
            ("upgrade_hover.png", (415, 840, 753, 970)),
            ("upgrade_pressed.png", (791, 845, 1117, 966)),
            ("upgrade_disabled.png", (1156, 845, 1473, 966)),
        ],
    )
    slice_atlas(
        "ui_skill_faction_crests_v1.png",
        [
            ("faction_wudang.png", (18, 330, 310, 700)),
            ("faction_huashan.png", (318, 330, 620, 700)),
            ("faction_gufeng.png", (625, 330, 925, 700)),
            ("faction_lingyue.png", (930, 330, 1225, 700)),
            ("faction_mingwu.png", (1230, 330, 1520, 700)),
        ],
    )


if __name__ == "__main__":
    main()
