"""Slice the glowing-blue TAB menu button 3-state sheet.

Source: images/20260530_002251_fa94c029.png (1024×1024, RGB)
Background: CHECKER pattern, alternating LIGHT-GREY (~220,220,220) and
            WHITE (~254,254,254). Both have very low chroma & high luma.
Foreground: glowing blue glass plates. Interior is deep-blue
            (R<60, G<130, B<180, with B clearly dominant).

Layout: 1 column × 3 rows  (top→bottom: normal / hover / pressed).

Strategy
--------
1. Per-pixel background test:  high luma  AND  near-grey  ⇒ background
   (covers BOTH the light-grey and white squares of the checker).
2. Foreground confidence: blue dominance OR low luma.
3. Soft alpha gradient between them so the glow rim doesn't clip.

Outputs (assets/library/ui/buttons/tab/):
  btn_tab_normal.png
  btn_tab_hover.png
  btn_tab_pressed.png
  btn_tab_3state.png   (vertical strip, normal→hover→pressed)
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "images" / "20260530_002251_fa94c029.png"
OUT = ROOT / "assets" / "library" / "ui" / "buttons" / "tab"
OUT.mkdir(parents=True, exist_ok=True)

STATES = ["normal", "hover", "pressed"]


# ---------------------------------------------------------------------------
# Pixel classification
# ---------------------------------------------------------------------------

def pixel_alpha(r: int, g: int, b: int) -> int:
    """Return alpha to KEEP for this pixel (0 = bg, 255 = button)."""
    mx = max(r, g, b)
    mn = min(r, g, b)
    chroma = mx - mn
    luma = mx

    # ---- Background (light-grey OR white checker square) ----
    # Both are bright AND near-grey.
    if luma >= 200 and chroma <= 14:
        return 0

    # ---- Strong foreground ----
    blue_dom = b - max(r, g)
    if blue_dom >= 12:           # any clearly blue-tinted pixel
        return 255
    if luma <= 140:              # any dark pixel  (button frame / interior)
        return 255

    # ---- Soft transition (rim glow / anti-alias edge) ----
    # Pixels here are "kinda bright but not pure grey".
    # Map by chroma: chroma 0..14 → α 0..255 (already handled above for
    # luma≥200; here we cover luma 140..200).
    if 140 < luma < 200:
        if chroma <= 4:
            return 0
        if chroma >= 30:
            return 255
        return int((chroma - 4) * 255 / 26)

    # Bright but slightly tinted (luma≥200, chroma 14..30): soft edge
    if luma >= 200 and 14 < chroma <= 30:
        return int((chroma - 14) * 255 / 16)

    return 255


# ---------------------------------------------------------------------------
# Grid detection
# ---------------------------------------------------------------------------

def find_runs(mask: list[bool], min_len: int) -> list[tuple[int, int]]:
    runs: list[tuple[int, int]] = []
    s: int | None = None
    for i, v in enumerate(mask):
        if v and s is None:
            s = i
        elif not v and s is not None:
            if i - s >= min_len:
                runs.append((s, i - 1))
            s = None
    if s is not None and len(mask) - s >= min_len:
        runs.append((s, len(mask) - 1))
    return runs


def merge_close(runs: list[tuple[int, int]], gap: int) -> list[tuple[int, int]]:
    if not runs:
        return runs
    out = [runs[0]]
    for s, e in runs[1:]:
        ps, pe = out[-1]
        if s - pe <= gap:
            out[-1] = (ps, e)
        else:
            out.append((s, e))
    return out


def is_button_pixel(r: int, g: int, b: int) -> bool:
    """Heuristic: clearly NOT background (used only for grid detection)."""
    mx = max(r, g, b)
    mn = min(r, g, b)
    chroma = mx - mn
    luma = mx
    if luma >= 200 and chroma <= 14:
        return False
    if (b - max(r, g)) >= 12:
        return True
    if luma <= 140:
        return True
    return False


def detect_grid(img: Image.Image) -> tuple[list[tuple[int, int]], list[tuple[int, int]]]:
    w, h = img.size
    px = img.load()

    row_count = [0] * h
    col_count = [0] * w
    for y in range(h):
        rc = 0
        for x in range(w):
            r, g, b = px[x, y][:3]
            if is_button_pixel(r, g, b):
                rc += 1
                col_count[x] += 1
        row_count[y] = rc

    rows = merge_close(
        find_runs([c >= 30 for c in row_count], min_len=40),
        gap=20,
    )
    cols = merge_close(
        find_runs([c >= 6 for c in col_count], min_len=200),
        gap=40,
    )
    return rows, cols


# ---------------------------------------------------------------------------
# Cropping
# ---------------------------------------------------------------------------

def crop_with_alpha(src_rgb: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    crop = src_rgb.crop(box).convert("RGBA")
    px = crop.load()
    w, h = crop.size
    for y in range(h):
        for x in range(w):
            r, g, b, _ = px[x, y]
            px[x, y] = (r, g, b, pixel_alpha(r, g, b))
    return crop


def trim_transparent(img: Image.Image, pad: int = 4) -> Image.Image:
    """Trim fully-transparent borders, leaving `pad` px of margin."""
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
    rows, cols = detect_grid(src)
    print(f"[detect] rows = {rows}")
    print(f"[detect] cols = {cols}")

    if len(rows) != 3:
        raise SystemExit(f"Expected 3 row ranges, got {len(rows)}: {rows}")
    if not cols:
        raise SystemExit("No column range detected")

    c_left = min(c[0] for c in cols)
    c_right = max(c[1] for c in cols)

    # Big crop window first; we trim transparent edges afterwards.
    pad_x = 20
    pad_y = 16
    cell_h = max(r2 - r1 + 1 for r1, r2 in rows) + pad_y * 2

    raw_crops: list[Image.Image] = []
    for ri, (r1, r2) in enumerate(rows):
        cy = (r1 + r2) // 2
        left = max(0, c_left - pad_x)
        right = min(src.width, c_right + 1 + pad_x)
        top = max(0, cy - cell_h // 2)
        bottom = min(src.height, top + cell_h)
        box = (left, top, right, bottom)
        raw_crops.append(crop_with_alpha(src, box))
        print(f"[crop] {STATES[ri]}: bbox={box}")

    # Trim transparent borders to get tight, equal-sized cells.
    # pad=8 keeps a small margin so the top/right glow tips don't clip.
    trimmed = [trim_transparent(c, pad=8) for c in raw_crops]
    tw = max(c.width for c in trimmed)
    th = max(c.height for c in trimmed)
    print(f"[size] unified cell = {tw} × {th}")

    crops: dict[str, Image.Image] = {}
    for state, c in zip(STATES, trimmed):
        canvas = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
        ox = (tw - c.width) // 2
        oy = (th - c.height) // 2
        canvas.paste(c, (ox, oy), c)
        out_path = OUT / f"btn_tab_{state}.png"
        canvas.save(out_path)
        crops[state] = canvas
        print(f"[save] {out_path.relative_to(ROOT)}")

    strip = Image.new("RGBA", (tw, th * 3), (0, 0, 0, 0))
    for i, state in enumerate(STATES):
        strip.paste(crops[state], (0, th * i), crops[state])
    strip_path = OUT / "btn_tab_3state.png"
    strip.save(strip_path)
    print(f"[strip] {strip_path.relative_to(ROOT)}  size={strip.size}")
    print("[done]")


if __name__ == "__main__":
    main()
