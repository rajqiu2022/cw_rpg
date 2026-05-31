"""
gen_inventory_ui.py — 背包界面全套 UI 素材生成

生成清单：
  1. panel_bg — 干净底图 1280×720，冷冰川风格，无 UI 元素
  2. Tab 按钮 — 5 类 × 3 态，160×52
  3. 功能按钮 — 使用/装备/丢弃/关闭 × 3 态，130×52
  4. 道具图标 — 8 个分类图标，1024→256
  5. 道具格子 — 默认/选中/空，88×88

用法：
  python scripts/gen_inventory_ui.py --bg        # 只生成底图
  python scripts/gen_inventory_ui.py --tabs      # 只生成 tab
  python scripts/gen_inventory_ui.py --buttons   # 只生成功能按钮
  python scripts/gen_inventory_ui.py --icons     # 只生成图标
  python scripts/gen_inventory_ui.py --cells     # 只生成格子
  python scripts/gen_inventory_ui.py --all       # 全部
"""

from __future__ import annotations

import base64, io, os, sys, time, glob
from pathlib import Path

for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        try:
            _stream.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass

import httpx
from dotenv import load_dotenv
from PIL import Image, ImageDraw, ImageFont, ImageEnhance, ImageFilter

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

API_KEY = os.getenv("OPENAI_API_KEY", "")
BASE_URL = os.getenv("OPENAI_BASE_URL", "")
MODEL = os.getenv("OPENAI_IMAGE_MODEL", "gpt-image-2")
ART_DIR = PROJECT_ROOT / "game" / "art" / "ui" / "inventory"

# -- 风格锚点 --
STYLE = (
    "Dark Chinese wuxia dark fantasy UI. Deep navy black (#0a101a) base, "
    "ornate dark gold (#c9a13b) accents, frosted dark glass, "
    "dark steel borders with warm gold edge, "
    "Chinese cloud scroll (ruyi) decorative motifs. "
    "Matte dark surfaces with cold inner shadows. "
    "Elegant, mysterious imperial wuxia aesthetic."
)


def call_alapi(prompt: str, size: str = "1024x1024", quality: str = "high", ref_b64: str = "") -> bytes | None:
    url = f"{BASE_URL}/images/generations"
    headers = {"token": API_KEY, "Content-Type": "application/json"}
    payload = {"model": MODEL, "prompt": prompt, "n": 1, "size": size, "quality": quality}
    if ref_b64:
        payload["image"] = [{"type": "input_image", "data": ref_b64}]
    print(f"  [API] {size} {quality} — {prompt[:100]}...")
    start = time.time()
    try:
        with httpx.Client(timeout=httpx.Timeout(300, connect=30)) as client:
            resp = client.post(url, headers=headers, json=payload)
    except Exception as e:
        print(f"  [ERR] {e}")
        return None
    print(f"  [*] {resp.status_code} in {time.time() - start:.1f}s")
    if resp.status_code != 200:
        print(f"  [ERR] {resp.text[:500]}")
        return None
    data = resp.json()
    items = None
    d = data.get("data")
    if isinstance(d, dict) and "data" in d:
        items = d["data"]
    elif isinstance(d, list):
        items = d
    if not items:
        print(f"  [ERR] No items: {str(data)[:300]}")
        return None
    first = items[0]
    if isinstance(first, dict):
        if "b64_json" in first:
            return base64.b64decode(first["b64_json"])
        if "url" in first:
            with httpx.Client(timeout=60) as dl:
                return dl.get(first["url"]).content
    return None


def find_font(size: int = 13) -> ImageFont.FreeTypeFont | None:
    for p in ["C:/Windows/Fonts/simhei.ttf", "C:/Windows/Fonts/msyh.ttc",
              "C:/Windows/Fonts/simsun.ttc", "C:/Windows/Fonts/simkai.ttf"]:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return None


# ============================================================
# 1. 底图 — 1280×720 干净面板
# ============================================================
def generate_bg() -> bool:
    print("\n" + "=" * 60)
    print("1/5: PANEL BACKGROUND (1280x720)")
    print("=" * 60)

    prompt = (
        f"A clean empty game UI panel background for a Chinese wuxia RPG inventory screen. "
        f"1280x720 landscape format. "
        f"{STYLE} "
        f"The panel is a large rectangular dark container with ornate cold steel/cyan borders, "
        f"frosted glass matte interior surface, subtle snowflake pattern in corners. "
        f"Inner area is completely empty and dark — ready for UI elements to be placed on top. "
        f"No text, no buttons, no icons, no items, no characters. "
        f"Just the decorative panel frame and dark empty interior. "
        f"Game UI background element, isolated."
    )
    # use design reference
    ref_b64 = ""
    refs = glob.glob(str(PROJECT_ROOT / "images" / "*UI*.png"))
    if refs:
        from PIL import Image as PILImage
        ref_img = PILImage.open(refs[0]).convert("RGB")
        ref_img.thumbnail((1280, 1280), PILImage.LANCZOS)
        buf = io.BytesIO()
        ref_img.save(buf, "JPEG", quality=88)
        ref_b64 = base64.b64encode(buf.getvalue()).decode()
        print(f"  [REF] Design ref ({ref_img.size[0]}x{ref_img.size[1]} JPEG)")
    data = call_alapi(prompt, size="1536x1024", quality="high", ref_b64=ref_b64)
    if not data:
        print("[FAIL]")
        return False

    img = Image.open(io.BytesIO(data)).convert("RGBA")
    # Crop to 1280:720 ratio
    target = 1280 / 720
    w, h = img.size
    if w / h > target:
        nw = int(h * target)
        img = img.crop(((w - nw) // 2, 0, (w + nw) // 2, h))
    else:
        nh = int(w / target)
        img = img.crop((0, (h - nh) // 2, w, (h + nh) // 2))
    img = img.resize((1280, 720), Image.LANCZOS)

    path = ART_DIR / "panel_bg.png"
    img.save(path, "PNG")
    print(f"[OK] panel_bg.png ({img.size[0]}x{img.size[1]})")
    return True


# ============================================================
# 2. Tab 按钮 — 5 类 × 3 态
# ============================================================
TABS = [("tab_all", "全部"), ("tab_consumable", "消耗"), ("tab_equipment", "装备"),
        ("tab_key", "剧情"), ("tab_material", "材料")]
TAB_W, TAB_H = 160, 52


def generate_tab_base() -> Image.Image | None:
    prompt = (
        f"A single horizontal game UI tab button for a Chinese wuxia RPG inventory panel. "
        f"{STYLE} "
        f"Dark navy blue background with frosted ice texture, thin cold cyan (#3eb8c2) border. "
        f"Frost crystal or snowflake subtle corner decorations. Matte dark empty center area. "
        f"No text, no characters, just the decorative tab frame. "
        f"Approximately 3:1 width-to-height ratio. Transparent background preferred."
    )
    data = call_alapi(prompt, size="1024x1024", quality="high")
    if not data:
        return None
    img = Image.open(io.BytesIO(data)).convert("RGBA")
    target = TAB_W / TAB_H
    w, h = img.size
    if w / h > target:
        nw = int(h * target)
        img = img.crop(((w - nw) // 2, 0, (w + nw) // 2, h))
    else:
        nh = int(w / target)
        img = img.crop((0, (h - nh) // 2, w, (h + nh) // 2))
    return img.resize((TAB_W, TAB_H), Image.LANCZOS)


def create_tab_variants(base: Image.Image) -> dict[str, Image.Image]:
    font = find_font(13)
    if not font:
        font = ImageFont.load_default()
    results = {}
    for key, label in TABS:
        d = ImageDraw.Draw(base)
        bbox = d.textbbox((0, 0), label, font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        x, y = (TAB_W - tw) // 2, (TAB_H - th) // 2 - 1

        # Normal
        img_n = base.copy()
        d = ImageDraw.Draw(img_n)
        d.text((x + 1, y + 1), label, font=font, fill=(0, 0, 0, 160))
        d.text((x, y), label, font=font, fill=(150, 200, 210))
        results[f"{key}_normal.png"] = img_n

        # Selected (cyan glow)
        img_s = base.copy()
        overlay = Image.new("RGBA", img_s.size, (50, 170, 200, 45))
        img_s = Image.alpha_composite(img_s, overlay)
        glow = Image.new("RGBA", (img_s.width + 4, img_s.height + 4), (0, 0, 0, 0))
        bd = ImageDraw.Draw(glow)
        bd.rounded_rectangle((0, 0, glow.width - 1, glow.height - 1), radius=7,
                             outline=(50, 200, 220, 180), width=2)
        glow = glow.filter(ImageFilter.GaussianBlur(1.5))
        glow.paste(img_s, (2, 2), img_s)
        d = ImageDraw.Draw(glow)
        d.text((x + 3, y + 3), label, font=font, fill=(0, 0, 0, 200))
        d.text((x + 2, y + 2), label, font=font, fill=(180, 235, 250))
        results[f"{key}_selected.png"] = glow

        # Pressed (darker)
        img_p = base.copy()
        img_p = ImageEnhance.Brightness(img_p).enhance(0.7)
        overlay_p = Image.new("RGBA", img_p.size, (15, 30, 40, 55))
        img_p = Image.alpha_composite(img_p, overlay_p)
        d = ImageDraw.Draw(img_p)
        d.text((x + 1, y + 1), label, font=font, fill=(0, 0, 0, 160))
        d.text((x, y), label, font=font, fill=(110, 155, 170))
        results[f"{key}_pressed.png"] = img_p

    return results


def generate_tabs() -> bool:
    print("\n" + "=" * 60)
    print("2/5: TAB BUTTONS (5x3 states)")
    print("=" * 60)
    base = generate_tab_base()
    if not base:
        return False
    variants = create_tab_variants(base)
    (ART_DIR / "tabs").mkdir(parents=True, exist_ok=True)
    for name, img in variants.items():
        img.save(ART_DIR / "tabs" / name, "PNG")
        print(f"  [OK] {name}")
    return True


# ============================================================
# 3. 功能按钮 — 使用/装备/丢弃/关闭 × 3 态
# ============================================================
BTN_W, BTN_H = 130, 52
BTN_NAMES = ["btn_use", "btn_equip", "btn_drop", "btn_close"]


def generate_button_base() -> Image.Image | None:
    prompt = (
        f"A single horizontal game UI action button for a Chinese wuxia RPG inventory panel. "
        f"{STYLE} "
        f"Dark navy steel frame with cold cyan (#3eb8c2) edge highlight, "
        f"frosted dark glass interior, subtle inner bevel for depth. "
        f"Approximately 2.4:1 width-to-height ratio. "
        f"No text, no characters, just the empty button frame. "
        f"Transparent background preferred."
    )
    data = call_alapi(prompt, size="1024x1024", quality="high")
    if not data:
        return None
    img = Image.open(io.BytesIO(data)).convert("RGBA")
    target = BTN_W / BTN_H
    w, h = img.size
    if w / h > target:
        nw = int(h * target)
        img = img.crop(((w - nw) // 2, 0, (w + nw) // 2, h))
    else:
        nh = int(w / target)
        img = img.crop((0, (h - nh) // 2, w, (h + nh) // 2))
    return img.resize((BTN_W, BTN_H), Image.LANCZOS)


def create_button_variants(base: Image.Image) -> dict[str, Image.Image]:
    font = find_font(13)
    if not font:
        font = ImageFont.load_default()
    labels = {"btn_use": "使用", "btn_equip": "装备", "btn_drop": "丢弃", "btn_close": "关闭"}
    results = {}
    for name, label in labels.items():
        d = ImageDraw.Draw(base)
        bbox = d.textbbox((0, 0), label, font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        x, y = (BTN_W - tw) // 2, (BTN_H - th) // 2 - 1

        # Normal
        img_n = base.copy()
        d = ImageDraw.Draw(img_n)
        d.text((x + 1, y + 1), label, font=font, fill=(0, 0, 0, 160))
        d.text((x, y), label, font=font, fill=(180, 210, 220))
        results[f"{name}_normal.png"] = img_n

        # Hover (cyan glow)
        img_h = base.copy()
        overlay = Image.new("RGBA", img_h.size, (80, 200, 230, 40))
        img_h = Image.alpha_composite(img_h, overlay)
        glow = Image.new("RGBA", (img_h.width + 6, img_h.height + 6), (0, 0, 0, 0))
        bd = ImageDraw.Draw(glow)
        bd.rounded_rectangle((0, 0, glow.width - 1, glow.height - 1), radius=9,
                             outline=(60, 210, 230, 160), width=3)
        glow = glow.filter(ImageFilter.GaussianBlur(2))
        glow.paste(img_h, (3, 3), img_h)
        d = ImageDraw.Draw(glow)
        d.text((x + 4, y + 4), label, font=font, fill=(0, 0, 0, 200))
        d.text((x + 3, y + 3), label, font=font, fill=(200, 240, 255))
        results[f"{name}_hover.png"] = glow

        # Pressed (darker + cyan inner)
        img_p = base.copy()
        img_p = ImageEnhance.Brightness(img_p).enhance(0.6)
        overlay_p = Image.new("RGBA", img_p.size, (20, 40, 50, 60))
        img_p = Image.alpha_composite(img_p, overlay_p)
        d = ImageDraw.Draw(img_p)
        d.text((x + 1, y + 1), label, font=font, fill=(0, 0, 0, 160))
        d.text((x, y), label, font=font, fill=(120, 160, 180))
        results[f"{name}_pressed.png"] = img_p

    return results


def generate_buttons() -> bool:
    print("\n" + "=" * 60)
    print("3/5: FUNCTION BUTTONS (4x3 states)")
    print("=" * 60)
    base = generate_button_base()
    if not base:
        return False
    variants = create_button_variants(base)
    (ART_DIR / "buttons").mkdir(parents=True, exist_ok=True)
    for name, img in variants.items():
        img.save(ART_DIR / "buttons" / name, "PNG")
        print(f"  [OK] {name}")
    return True


# ============================================================
# 4. 道具图标 — 8 个分类图标 1024→256
# ============================================================
ICONS = [
    ("icon_sword", "weapon", "A finely crafted Chinese iron sword with a dark blade and simple wrapped hilt, wuxia style, isolated on pure white background, game item icon"),
    ("icon_armor", "armor", "A set of dark layered Chinese warrior armor with steel shoulder guards, wuxia style, isolated on pure white background, game item icon"),
    ("icon_potion", "potion", "A small blue-glazed ceramic medicine bottle with a red cork stopper, wuxia alchemy style, isolated on pure white background, game item icon"),
    ("icon_ore", "ore", "A rough chunk of dark iron ore with metallic silver veins, wuxia crafting material, isolated on pure white background, game item icon"),
    ("icon_scroll", "scroll", "A rolled ancient Chinese martial arts scroll tied with a dark blue silk ribbon, wuxia style, isolated on pure white background, game item icon"),
    ("icon_key", "key", "An ornate bronze key with cloud-scroll decorations, wuxia quest item, isolated on pure white background, game item icon"),
    ("icon_ring", "ring", "A dark jade ring carved with swirling cloud patterns, wuxia accessory, isolated on pure white background, game item icon"),
    ("icon_talisman", "talisman", "A yellow paper talisman with dark ink calligraphy marks, Taoist wuxia charm, isolated on pure white background, game item icon"),
]


def generate_icons() -> bool:
    print("\n" + "=" * 60)
    print("4/5: ITEM ICONS (8 icons)")
    print("=" * 60)

    (ART_DIR / "icons").mkdir(parents=True, exist_ok=True)

    for name, _category, desc in ICONS:
        prompt = (
            f"Chinese wuxia RPG game item icon. {desc}. "
            f"{STYLE} "
            f"The item should be centered, occupying about 60-70% of the frame. "
            f"Clean, detailed, game-ready. "
            f"No text, no labels, no UI frames — just the item itself. "
            f"Pure solid white (#FFFFFF) background for easy background removal."
        )
        data = call_alapi(prompt, size="1024x1024", quality="medium")
        if not data:
            print(f"  [FAIL] {name}")
            continue
        img = Image.open(io.BytesIO(data)).convert("RGBA")

        # Remove white background
        pixels = img.load()
        for y in range(img.height):
            for x in range(img.width):
                r, g, b, a = pixels[x, y]
                if r > 240 and g > 240 and b > 240:
                    pixels[x, y] = (r, g, b, 0)

        # Resize to 256x256 for detail view
        img_256 = img.resize((256, 256), Image.LANCZOS)
        img_256.save(ART_DIR / "icons" / f"{name}.png", "PNG")

        # Also save 64x64 for grid thumbnails
        img_64 = img.resize((64, 64), Image.LANCZOS)
        img_64.save(ART_DIR / "icons" / f"{name}_sm.png", "PNG")
        print(f"  [OK] {name}.png (256x256 + 64x64)")

    return True


# ============================================================
# 5. 道具格子 — default / selected / empty
# ============================================================
CELL_S = 88


def generate_cells() -> bool:
    print("\n" + "=" * 60)
    print("5/5: ITEM CELLS (3 states)")
    print("=" * 60)

    cell_specs = {
        "cell_default": (
            f"A single square inventory item slot in DEFAULT state. "
            f"{STYLE} "
            f"Dark navy semi-transparent interior with frosted glass texture, "
            f"subtle dark recessed border with thin cold cyan edge. "
            f"Slight sunk-in depth effect. Empty interior. "
            f"Perfect 1:1 square. Isolated game UI element. "
            f"No item, no text, just the empty slot frame."
        ),
        "cell_selected": (
            f"A single square inventory item slot in SELECTED/ACTIVE state. "
            f"{STYLE} "
            f"Bright cold cyan (#3eb8c2) glowing border around the edge. "
            f"Interior with subtle cyan gradient highlight. "
            f"Same frosted glass interior but lit with cyan ambient light. "
            f"Perfect 1:1 square. Isolated game UI element. "
            f"No item, no text, just the highlighted slot frame."
        ),
        "cell_empty": (
            f"A single square inventory item slot in EMPTY/DISABLED state. "
            f"{STYLE} "
            f"Darker, more opaque interior than default. "
            f"No highlight, very subtle dark border. "
            f"Slightly desaturated muted appearance. "
            f"Perfect 1:1 square. Isolated game UI element."
        ),
    }

    (ART_DIR / "cells").mkdir(parents=True, exist_ok=True)
    for name, prompt in cell_specs.items():
        data = call_alapi(prompt, size="1024x1024", quality="medium")
        if not data:
            print(f"  [FAIL] {name}")
            continue
        img = Image.open(io.BytesIO(data)).convert("RGBA")
        # Crop square from center
        w, h = img.size
        s = min(w, h)
        img = img.crop(((w - s) // 2, (h - s) // 2, (w + s) // 2, (h + s) // 2))
        img = img.resize((CELL_S, CELL_S), Image.LANCZOS)
        img.save(ART_DIR / "cells" / f"{name}.png", "PNG")
        print(f"  [OK] {name}.png")

    return True


# ============================================================
# Main
# ============================================================
def main():
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("--bg", action="store_true")
    p.add_argument("--tabs", action="store_true")
    p.add_argument("--buttons", action="store_true")
    p.add_argument("--cells", action="store_true")
    p.add_argument("--icons", action="store_true")
    p.add_argument("--all", action="store_true")
    args = p.parse_args()
    run = args.all or not (args.bg or args.tabs or args.buttons or args.icons or args.cells)

    print(f"Model: {MODEL}  |  Base URL: {BASE_URL}")

    if run or args.bg:
        generate_bg()
    if run or args.tabs:
        generate_tabs()
    if run or args.buttons:
        generate_buttons()
    if run or args.icons:
        generate_icons()
    if run or args.cells:
        generate_cells()

    print("\n[DONE]")


if __name__ == "__main__":
    main()
