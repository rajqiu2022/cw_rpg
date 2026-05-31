"""PIL 生成 HUD 面板：角色信息 + 场景名牌。暗铁金属雕刻风格，与按钮一致。"""

from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
GAME_DIR = ROOT / "game" / "art" / "ui" / "field_hud" / "v1"
TOOLS_DIR = ROOT / "tools" / "ui_field_hud_v1"
SIZE = (650, 188)
SCENE_SIZE = (543, 63)

# Cold wuxia palette — matching the button frame and style guide
INK_BLACK = (10, 15, 20)
DARK_IRON = (24, 34, 42)
IRON_MID = (30, 42, 52)
COLD_STEEL = (84, 113, 135)
FROST_HIGHLIGHT = (143, 178, 200)
JADE_CYAN = (91, 180, 184)
DARK_RED = (90, 21, 34)
SHADOW_DARK = (6, 10, 14)


def _draw_metal_frame(draw: ImageDraw.Draw, rect: tuple[int, int, int, int],
                       recessed: bool = True):
    """Draw a dark metal frame with cold steel beveled edges.

    Uses the same engraved/recessed metal style as our button text fix.
    """
    x1, y1, x2, y2 = rect
    # Outer dark shadow
    draw.rectangle([x1 + 2, y1 + 2, x2 + 2, y2 + 2], fill=SHADOW_DARK + (80,))
    # Main dark iron fill
    draw.rectangle([x1, y1, x2, y2], fill=DARK_IRON + (255,))

    if recessed:
        # Inner shadow at top-left (recessed edge)
        draw.rectangle([x1 + 1, y1 + 1, x2 - 1, y2 - 1],
                        fill=IRON_MID + (255,),
                        outline=SHADOW_DARK + (120,))
        # Bottom-right highlight
        draw.line([(x1 + 2, y2 - 2), (x2 - 2, y2 - 2)], fill=FROST_HIGHLIGHT + (40,), width=1)
        draw.line([(x2 - 2, y1 + 2), (x2 - 2, y2 - 2)], fill=FROST_HIGHLIGHT + (40,), width=1)
    else:
        # Top-left highlight (raised edge)
        draw.line([(x1 + 1, y1 + 1), (x2 - 1, y1 + 1)], fill=FROST_HIGHLIGHT + (60,), width=1)
        draw.line([(x1 + 1, y1 + 1), (x1 + 1, y2 - 1)], fill=FROST_HIGHLIGHT + (60,), width=1)
        # Bottom-right shadow
        draw.line([(x1 + 1, y2 - 1), (x2 - 1, y2 - 1)], fill=SHADOW_DARK + (80,), width=1)
        draw.line([(x2 - 1, y1 + 1), (x2 - 1, y2 - 1)], fill=SHADOW_DARK + (80,), width=1)

    # Cold steel border
    draw.rectangle([x1, y1, x2, y2], outline=COLD_STEEL + (180,), width=1)


def _draw_recessed_slot(draw: ImageDraw.Draw, rect: tuple[int, int, int, int],
                         tint: tuple[int, int, int, int] | None = None):
    """Draw a recessed slot/bar carved into the metal."""
    x1, y1, x2, y2 = rect
    # Dark cavity
    interior = IRON_MID if tint is None else (
        min(255, IRON_MID[0] + tint[0] // 4),
        min(255, IRON_MID[1] + tint[1] // 4),
        min(255, IRON_MID[2] + tint[2] // 4),
    )
    draw.rectangle([x1, y1, x2, y2], fill=interior + (255,))
    # Inner shadow at top-left
    draw.line([(x1, y1), (x2 - 1, y1)], fill=SHADOW_DARK + (120,), width=1)
    draw.line([(x1, y1), (x1, y2 - 1)], fill=SHADOW_DARK + (120,), width=1)
    # Highlight at bottom-right
    draw.line([(x1 + 1, y2 - 1), (x2 - 1, y2 - 1)], fill=FROST_HIGHLIGHT + (50,), width=1)
    draw.line([(x2 - 1, y1 + 1), (x2 - 1, y2 - 1)], fill=FROST_HIGHLIGHT + (50,), width=1)
    if tint:
        # Tinted bottom edge for the slot interior
        draw.line([(x1 + 1, y2 - 2), (x2 - 2, y2 - 2)], fill=tint, width=1)


def _draw_avatar_circle(draw: ImageDraw.Draw, cx: int, cy: int, r: int):
    """Draw a circular recessed avatar frame."""
    # Outer rim shadow
    draw.ellipse([cx - r - 2, cy - r - 2, cx + r + 2, cy + r + 2],
                  fill=None, outline=SHADOW_DARK + (90,), width=2)
    # Outer rim — cold steel
    draw.ellipse([cx - r - 1, cy - r - 1, cx + r + 1, cy + r + 1],
                  fill=None, outline=COLD_STEEL + (200,), width=2)
    # Inner rim — dark iron
    draw.ellipse([cx - r, cy - r, cx + r, cy + r],
                  fill=IRON_MID + (255,),
                  outline=FROST_HIGHLIGHT + (30,), width=1)
    # Recessed center — near black
    draw.ellipse([cx - r + 3, cy - r + 3, cx + r - 3, cy + r - 3],
                  fill=INK_BLACK + (255,))
    # Inner shadow at top-left of recess
    draw.arc([cx - r + 2, cy - r + 2, cx + r - 2, cy + r - 2],
              start=210, end=300, fill=SHADOW_DARK + (80,), width=1)


def _add_noise(img: Image.Image, intensity: int = 8) -> Image.Image:
    """Add subtle grain to match the button metal texture."""
    arr = np.array(img.convert("RGBA")).astype(np.float32)
    noise = np.random.RandomState(42).randint(0, intensity, (arr.shape[0], arr.shape[1]), dtype=np.uint8)
    mask = arr[:, :, 3] > 10
    for c in range(3):
        arr[mask, c] = np.clip(arr[mask, c] + noise[mask].astype(np.float32) - intensity / 2, 0, 255)
    return Image.fromarray(arr.clip(0, 255).astype("uint8"), "RGBA")


def make_char_panel() -> Image.Image:
    """Generate the top-left character info panel."""
    img = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Main panel background with metal frame
    _draw_metal_frame(draw, (0, 2, SIZE[0], SIZE[1] - 2))

    # Avatar circle — left side, centered vertically
    avatar_cx, avatar_cy, avatar_r = 80, SIZE[1] // 2, 60
    _draw_avatar_circle(draw, avatar_cx, avatar_cy, avatar_r)

    # HP bar slot — right of avatar
    bar_x = 168
    bar_w = 310
    bar_h = 24
    hp_y = 42
    _draw_recessed_slot(draw, (bar_x, hp_y, bar_x + bar_w, hp_y + bar_h),
                         tint=DARK_RED + (120,))

    # MP bar slot — below HP
    mp_y = 78
    _draw_recessed_slot(draw, (bar_x, mp_y, bar_x + bar_w, mp_y + bar_h),
                         tint=JADE_CYAN + (100,))

    # Level badge — right side, between bars
    lvl_x = bar_x + bar_w + 42
    lvl_y = 42
    lvl_s = 60
    _draw_recessed_slot(draw, (lvl_x, lvl_y, lvl_x + lvl_s, lvl_y + lvl_s))
    # Small frost dot in center of level badge
    draw.ellipse([lvl_x + lvl_s // 2 - 6, lvl_y + lvl_s // 2 - 6,
                  lvl_x + lvl_s // 2 + 6, lvl_y + lvl_s // 2 + 6],
                  fill=FROST_HIGHLIGHT + (50,))

    # Name slot — above bars, right of avatar
    name_y = 16
    name_h = 18
    _draw_recessed_slot(draw, (bar_x, name_y, bar_x + 200, name_y + name_h))

    # Gold slot — small, below bars
    gold_w = 110
    _draw_recessed_slot(draw, (bar_x, mp_y + bar_h + 8, bar_x + gold_w, mp_y + bar_h + 8 + 18))

    return _add_noise(img)


def make_scene_plaque() -> Image.Image:
    """Generate the top-right scene name plaque."""
    img = Image.new("RGBA", SCENE_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Main plaque
    _draw_metal_frame(draw, (0, 2, SCENE_SIZE[0], SCENE_SIZE[1] - 2))

    # Recessed text area
    margin = 10
    text_area = (margin, 12, SCENE_SIZE[0] - margin, SCENE_SIZE[1] - 14)
    _draw_recessed_slot(draw, text_area)

    # Tiny jade studs at left/right ends of recessed area
    stud_r = 4
    stud_y = SCENE_SIZE[1] // 2
    for sx in [margin + 16, SCENE_SIZE[0] - margin - 16]:
        draw.ellipse([sx - stud_r, stud_y - stud_r, sx + stud_r, stud_y + stud_r],
                      fill=JADE_CYAN + (80,))

    return _add_noise(img, intensity=6)


def main():
    GAME_DIR.mkdir(parents=True, exist_ok=True)

    # Character panel
    char_panel = make_char_panel()
    char_panel.save(GAME_DIR / "hud_player_panel.png")
    char_panel.save(TOOLS_DIR / "hud_player_panel.png")
    print(f"Char panel: {SIZE} → {GAME_DIR / 'hud_player_panel.png'}")

    # Scene plaque
    plaque = make_scene_plaque()
    plaque.save(GAME_DIR / "hud_scene_title.png")
    plaque.save(TOOLS_DIR / "hud_scene_title.png")
    print(f"Scene plaque: {SCENE_SIZE} → {GAME_DIR / 'hud_scene_title.png'}")

    print("Done.")


if __name__ == "__main__":
    main()
