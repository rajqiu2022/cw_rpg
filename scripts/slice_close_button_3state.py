"""Slice the diablo-style CLOSE BUTTON 3-state sheet.

Source: images/20260530_231226_ccdeae88.png (1024×1024, RGB)
Background: PURE BLACK (RGB ≤ 4 everywhere outside the buttons).
Foreground: ornate metallic frame with red gem on top + 'X' icon.

Layout: 1 row × 3 columns.
  col 0 (left)   - red lit, bright gold X        → HOVER
  col 1 (middle) - dark red, off-white X         → NORMAL  (resting)
  col 2 (right)  - black/grey, dim X             → PRESSED (pushed down)

Strategy
--------
Per-button strategy uses a flood-fill from the cropped tile's outer
border. Only pixels that:
  • are dark (luma ≤ 12 AND chroma ≤ 6) AND
  • are connected (4-neighbourhood) to the border through other dark
    pixels
are knocked out. This keeps even the deepest interior shadows of the
button panel (which would otherwise share RGB with the surrounding
black background) intact.
"""
from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "images" / "20260530_231226_ccdeae88.png"
OUT = ROOT / "assets" / "library" / "ui" / "buttons" / "close"
OUT.mkdir(parents=True, exist_ok=True)

STATE_BY_COL = ["hover", "normal", "pressed"]
STRIP_ORDER = ["normal", "hover", "pressed"]


# ---------------------------------------------------------------------------
# Pixel test
# ---------------------------------------------------------------------------

def is_darkish(r: int, g: int, b: int) -> bool:
    """Pixel that is dark enough to plausibly be the black background.

    Tightened to luma ≤ 5: the source's true black gaps measure 0..4, while
    the *darkest* pressed-button interior pixels measure 6..16. So 5 is
    a safe cut-off that splits true background from button shadow.
    """
    luma = max(r, g, b)
    chroma = luma - min(r, g, b)
    return luma <= 5 and chroma <= 4


def is_strong_fg(r: int, g: int, b: int) -> bool:
    """Used for layout detection only."""
    return max(r, g, b) >= 30


# ---------------------------------------------------------------------------
# Layout detection
# ---------------------------------------------------------------------------

def find_runs(values: list[int], thr: int, min_len: int) -> list[tuple[int, int]]:
    out: list[tuple[int, int]] = []
    s: int | None = None
    for i, v in enumerate(values):
        if v > thr and s is None:
            s = i
        elif v <= thr and s is not None:
            if i - s >= min_len:
                out.append((s, i - 1))
            s = None
    if s is not None and len(values) - s >= min_len:
        out.append((s, len(values) - 1))
    return out


def detect_grid(img: Image.Image) -> tuple[tuple[int, int], list[tuple[int, int]]]:
    w, h = img.size
    px = img.load()
    row_count = [0] * h
    col_count = [0] * w
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if is_strong_fg(r, g, b):
                row_count[y] += 1
                col_count[x] += 1
    rows = find_runs(row_count, thr=5, min_len=40)
    cols = find_runs(col_count, thr=3, min_len=40)
    if not rows:
        raise SystemExit("no row range detected")
    if len(cols) != 3:
        raise SystemExit(f"expected 3 columns, got {len(cols)}: {cols}")
    return rows[0], cols


# ---------------------------------------------------------------------------
# Crop + alpha (border flood-fill)
# ---------------------------------------------------------------------------

def cut_with_alpha(src_rgb: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    crop = src_rgb.crop(box).convert("RGBA")
    w, h = crop.size
    px = crop.load()

    # Pre-compute "dark" mask.
    dark = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b, _ = px[x, y]
            dark[y][x] = is_darkish(r, g, b)

    # 4-neighbour BFS from every border pixel that is dark.
    visited = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        for y in (0, h - 1):
            if dark[y][x] and not visited[y][x]:
                visited[y][x] = True
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if dark[y][x] and not visited[y][x]:
                visited[y][x] = True
                q.append((x, y))

    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and not visited[ny][nx] and dark[ny][nx]:
                visited[ny][nx] = True
                q.append((nx, ny))

    # Anything reached by the flood fill is background → alpha 0.
    for y in range(h):
        for x in range(w):
            if visited[y][x]:
                r, g, b, _ = px[x, y]
                px[x, y] = (r, g, b, 0)
            # else keep original (alpha 255 from .convert('RGBA') of RGB).

    return crop


def trim_transparent(img: Image.Image, pad: int = 2) -> Image.Image:
    bbox = img.getbbox()
    if bbox is None:
        return img
    l, t, r, b = bbox
    l = max(0, l - pad)
    t = max(0, t - pad)
    r = min(img.width, r + pad)
    b = min(img.height, b + pad)
    return img.crop((l, t, r, b))


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    print(f"[load] {SRC}")
    src = Image.open(SRC).convert("RGB")
    (r1, r2), cols = detect_grid(src)
    print(f"[detect] row = ({r1}, {r2})")
    print(f"[detect] cols = {cols}")

    pad_x = 8
    pad_y = 8

    raw: dict[str, Image.Image] = {}
    for ci, (c1, c2) in enumerate(cols):
        state = STATE_BY_COL[ci]
        box = (
            max(0, c1 - pad_x),
            max(0, r1 - pad_y),
            min(src.width, c2 + 1 + pad_x),
            min(src.height, r2 + 1 + pad_y),
        )
        img = cut_with_alpha(src, box)
        img = trim_transparent(img, pad=2)
        raw[state] = img
        print(f"[crop] {state}: bbox={box}  trimmed={img.size}")

    tw = max(im.width for im in raw.values())
    th = max(im.height for im in raw.values())
    print(f"[size] unified cell = {tw} × {th}")

    final: dict[str, Image.Image] = {}
    for state, im in raw.items():
        canvas = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
        ox = (tw - im.width) // 2
        oy = (th - im.height) // 2
        canvas.paste(im, (ox, oy), im)
        out_path = OUT / f"btn_close_{state}.png"
        canvas.save(out_path)
        final[state] = canvas
        print(f"[save] {out_path.relative_to(ROOT)}")

    strip = Image.new("RGBA", (tw, th * len(STRIP_ORDER)), (0, 0, 0, 0))
    for i, state in enumerate(STRIP_ORDER):
        strip.paste(final[state], (0, th * i), final[state])
    strip_path = OUT / "btn_close_3state.png"
    strip.save(strip_path)
    print(f"[strip] {strip_path.relative_to(ROOT)}  size={strip.size}  order={STRIP_ORDER}")
    print("[done]")


if __name__ == "__main__":
    main()
