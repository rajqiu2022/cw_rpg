"""Slice 4-color × 3-state button sheet into per-button PNGs and 3-state strips.

Source: images/20260529_152549_6efbbb23.png (1024×1024, RGB with checker bg)
Layout: 4 columns (green / blue / red / gray) × 3 rows (normal / hover / pressed)

Outputs:
  assets/library/ui/buttons/cloud/
    btn_<color>_normal.png
    btn_<color>_hover.png
    btn_<color>_pressed.png
    btn_<color>_3state.png   # vertical strip: normal | hover | pressed
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "images" / "20260529_152549_6efbbb23.png"
OUT = ROOT / "assets" / "library" / "ui" / "buttons" / "cloud"
OUT.mkdir(parents=True, exist_ok=True)

COLORS = ["green", "blue", "red", "gray"]
STATES = ["normal", "hover", "pressed"]


def make_alpha(img: Image.Image) -> Image.Image:
    """Convert checker-pattern background (light grey/white) to transparent."""
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, _ = px[x, y]
            # Checker bg: (237,237,237) and (254,254,254). Treat near-white as bg.
            if r >= 225 and g >= 225 and b >= 225 and abs(r - g) < 10 and abs(g - b) < 10:
                px[x, y] = (0, 0, 0, 0)
    return img


def find_rows(mask_per_row: list[bool]) -> list[tuple[int, int]]:
    """Group consecutive True rows into (top, bottom) ranges."""
    runs: list[tuple[int, int]] = []
    start = None
    for i, v in enumerate(mask_per_row):
        if v and start is None:
            start = i
        elif not v and start is not None:
            runs.append((start, i - 1))
            start = None
    if start is not None:
        runs.append((start, len(mask_per_row) - 1))
    return runs


def detect_grid(img: Image.Image) -> tuple[list[tuple[int, int]], list[tuple[int, int]]]:
    """Return (row_ranges, col_ranges) from alpha channel."""
    w, h = img.size
    alpha = img.split()[-1].load()
    row_has = [any(alpha[x, y] > 16 for x in range(w)) for y in range(h)]
    col_has = [any(alpha[x, y] > 16 for y in range(h)) for x in range(w)]
    return find_rows(row_has), find_rows(col_has)


def main() -> None:
    print(f"[load] {SRC}")
    img = Image.open(SRC)
    img = make_alpha(img)

    rows, cols = detect_grid(img)
    print(f"[detect] rows={rows}")
    print(f"[detect] cols={cols}")

    if len(rows) != 3 or len(cols) != 4:
        raise SystemExit(
            f"Unexpected grid: {len(rows)} rows × {len(cols)} cols (need 3×4). "
            "Check threshold."
        )

    # Use the maximum bbox among all 12 cells so every button strip has the
    # same dimensions (good for AtlasTexture / NinePatchRect).
    cell_w = max(c2 - c1 + 1 for c1, c2 in cols)
    cell_h = max(r2 - r1 + 1 for r1, r2 in rows)
    pad = 4  # small breathing room
    cell_w += pad * 2
    cell_h += pad * 2
    print(f"[size] cell = {cell_w} × {cell_h} (incl. {pad}px padding)")

    crops: dict[str, dict[str, Image.Image]] = {c: {} for c in COLORS}

    for ri, (r1, r2) in enumerate(rows):
        cy = (r1 + r2) // 2
        for ci, (c1, c2) in enumerate(cols):
            cx = (c1 + c2) // 2
            left = cx - cell_w // 2
            top = cy - cell_h // 2
            box = (left, top, left + cell_w, top + cell_h)
            crop = img.crop(box)

            color = COLORS[ci]
            state = STATES[ri]
            out_path = OUT / f"btn_{color}_{state}.png"
            crop.save(out_path)
            crops[color][state] = crop
            print(f"[save] {out_path.relative_to(ROOT)}  bbox={box}")

    # Build vertical 3-state strips per color (normal / hover / pressed top→bottom)
    for color in COLORS:
        strip = Image.new("RGBA", (cell_w, cell_h * 3), (0, 0, 0, 0))
        for i, state in enumerate(STATES):
            strip.paste(crops[color][state], (0, cell_h * i))
        strip_path = OUT / f"btn_{color}_3state.png"
        strip.save(strip_path)
        print(f"[strip] {strip_path.relative_to(ROOT)}  size={strip.size}")

    print("[done]")


if __name__ == "__main__":
    main()
