"""生成野外 HUD 面板 — gpt-image-2 @ 1536x1024 → 裁切 → PIL 后处理"""

from __future__ import annotations

import base64
import os
import sys
import time
from pathlib import Path

for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        try:
            _stream.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass

from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

import io
import httpx
import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

API_KEY = os.getenv("OPENAI_API_KEY", "")
BASE_URL = os.getenv("OPENAI_BASE_URL", "https://v3.alapi.cn/api/ai")
MODEL = os.getenv("OPENAI_IMAGE_MODEL", "gpt-image-2")
GEN_SIZE = "1536x1024"

RAW_DIR = PROJECT_ROOT / "assets" / "raw" / "ui_frame"
GAME_DIR = PROJECT_ROOT / "game" / "art" / "ui" / "field_hud" / "v1"
TOOLS_DIR = PROJECT_ROOT / "tools" / "ui_field_hud_v1"

STYLE = "Dark iron metal panel with cold steel blue edge highlights, recessed/engraved areas, subtle brushed metal grain, ancient Chinese iron plaque aesthetic. Cool dark blue-gray-black palette (#050A0F #182A35 #547187 #8FB2C8). No warm gold/orange. No English/Latin text."


# ——— Character info panel ———
# In-game placement: (0, 0, 650, 188). We'll crop to ~1300×400 from the 1536 canvas.
CHAR_PROMPT = f"""Chinese wuxia game UI character status panel. 1536x1024 canvas. The panel occupies the UPPER portion of the canvas only. The rest of the canvas (below the panel) should be plain dark near-black (#0A0F14), no features.

THE PANEL (top ~400px of the 1024-height canvas):
A dark horizontal character info plate, left-aligned, about 1300px wide x 350px tall.

MATERIAL: Dark iron-black obsidian metal plate with subtle brushed grain. Recessed inner area. Cold steel blue-gray beveled border edges with frost-blue rim highlights. Similar to ancient Chinese weapon inscription plates.

LAYOUT (left to right):
1. AVATAR CIRCLE (leftmost, ~220px diameter): Deeply recessed circular frame engraved into the metal. The interior is solid dark near-black (empty, to be filled by game portrait). The circular rim has subtle cold steel edge highlights catching light from top-left.

2. PLAYER NAME AREA (right of avatar): A subtle horizontal recessed slot, about 280px wide x 40px tall, dark interior. Sits above the status bars.

3. HP BAR (right side, top): A narrow horizontal groove carved into the metal, about 340px wide x 26px tall. The interior has a very subtle dark crimson-red tint (#4A1020 range). This is an HP/health indicator slot.

4. MP/ENERGY BAR (right side, below HP bar): Same dimensions as HP bar. The interior has a very subtle dark jade-cyan tint (#1A4045 range). This is an energy/MP indicator slot.

5. LEVEL BADGE (top-right corner): Small square recessed slot, ~50x50px, cold steel edge, dark interior.

6. GOLD/CURRENCY DISPLAY (below the bars, small): A tiny horizontal slot ~120px wide, subtle gold-tinted recess.

NO TEXT anywhere. No portrait in the circle. All slots are empty/dark. The entire lower half of the 1024-height canvas is plain dark (#0A0F14).
{STYLE}"""


# ——— Scene name plaque ———
# In-game placement: (1262, 21, 543, 63). We'll crop to ~1100×150.
SCENE_PROMPT = f"""Chinese wuxia game UI scene name plaque. 1536x1024 canvas. The plaque occupies the UPPER portion only. Rest is plain dark (#0A0F14).

THE PLAQUE (top ~200px of the 1024-height canvas):
A horizontal nameplate/plaque, centered, about 1100px wide x 100px tall.

DESIGN: Dark iron horizontal inscription board (匾额 style but small and minimal). Cold steel blue-gray metallic borders with subtle 3D bevel. The left and right ends have tiny cold metal cloud-motif studs or rivets.

INTERIOR: A deep recessed rectangular text area spanning most of the width, about 20px inset from borders. The recessed floor is slightly lighter gunmetal gray, creating an engraved slot for scene name text (rendered by game engine).

MINIMAL decoration. NO TEXT inside the recessed area. Clean, simple, grim.
{STYLE}"""


# ——— Inventory panel ———
INVENTORY_PROMPT = f"""Chinese wuxia game inventory/backpack panel. 1536x1024 canvas.

THE PANEL (fills most of the canvas):
A large dark metal inventory screen panel, about 900px wide x 750px tall, centered.

MATERIAL: Dark iron-black obsidian metal with cold steel blue-gray borders and frost-blue edge highlights. Recessed interior areas.

LAYOUT:
- TOP: A horizontal title bar area (recessed, no text), about 60px tall, spanning the full panel width.
- LEFT SIDE: Vertical tab/category strip, about 100px wide, with 4 recessed tab slots stacked vertically (全部/药品/装备/剧情). Each tab slot is about 40px tall, with cold steel edges. NO TEXT inside tabs.
- CENTER: A grid of 24 item slots (6 columns x 4 rows). Each slot is about 80x80px square with cold metal borders, dark recessed interior. The slots have subtle dark iron separators between them. Empty slots show a very faint dark grid pattern.
- RIGHT SIDE: A tall vertical detail/info panel, about 200px wide, with a slightly lighter recessed area for item description. Dark interior.
- BOTTOM: A thin horizontal bar area with 2 small recessed slots (for gold/weight display), about 35px tall.

NO TEXT, NO ICONS, NO IMAGES inside slots or tabs. All slots are empty/dark recessed frames. The panel looks like a beautifully crafted dark metal cabinet with empty drawers waiting to be filled.
{STYLE}"""


PANELS = {
    "char_info": {
        "prompt": CHAR_PROMPT,
        "output_raw": "ui_hud_char_info_raw_v1.png",
        "output_game": "hud_player_panel.png",
        "crop_box": (60, 30, 1400, 430),  # (left, top, right, bottom) from 1536x1024
    },
    "scene_plaque": {
        "prompt": SCENE_PROMPT,
        "output_raw": "ui_hud_scene_plaque_raw_v1.png",
        "output_game": "hud_scene_title.png",
        "crop_box": (120, 30, 1380, 210),
    },
    "inventory": {
        "prompt": INVENTORY_PROMPT,
        "output_raw": "ui_inventory_panel_raw_v1.png",
        "output_game": None,  # inventory panel goes to a different dir
        "crop_box": (280, 100, 1260, 920),
    },
}


def _call_alapi(prompt: str, output_path: Path) -> bytes | None:
    url = f"{BASE_URL}/images/generations"
    headers = {"token": API_KEY, "Content-Type": "application/json"}
    payload = {"model": MODEL, "prompt": prompt, "n": 1, "size": GEN_SIZE, "quality": "high"}

    print(f"    Sending request...")
    start = time.time()
    with httpx.Client(timeout=httpx.Timeout(300, connect=30)) as client:
        resp = client.post(url, headers=headers, json=payload)
    elapsed = time.time() - start

    if resp.status_code != 200:
        print(f"    [ERROR] HTTP {resp.status_code}: {resp.text[:500]}")
        return None

    data = resp.json()
    if data.get("code") and data.get("code") != 200:
        print(f"    [ERROR] API code={data.get('code')}: {data.get('message', '')}")
        return None

    image_data = None
    if "data" in data:
        inner = data["data"]
        if isinstance(inner, dict) and "data" in inner:
            items = inner["data"]
        elif isinstance(inner, list):
            items = inner
        else:
            items = []

        if items:
            item = items[0]
            if "url" in item:
                print(f"    Downloading from URL...")
                with httpx.Client(timeout=60) as dl:
                    image_data = dl.get(item["url"]).content
            elif "b64_json" in item:
                image_data = base64.b64decode(item["b64_json"])

    if not image_data:
        print(f"    [ERROR] Could not extract image. Response: {json.dumps(data, ensure_ascii=False)[:500]}")
        return None

    RAW_DIR.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(image_data)
    size_kb = len(image_data) / 1024
    print(f"    Saved raw: {output_path} ({size_kb:.0f} KB, {elapsed:.0f}s)")
    return image_data


def _crop_and_save(image_data: bytes, crop_box: tuple[int, int, int, int],
                   game_name: str | None, key: str) -> None:
    """Crop from 1536x1024 raw, save processed version."""
    img = Image.open(io.BytesIO(image_data)) if isinstance(image_data, bytes) else None
    if img is None:
        return

    # Crop
    cropped = img.crop(crop_box)

    # Save processed copy alongside raw
    processed_path = RAW_DIR / PANELS[key]["output_raw"].replace("_raw_", "_")
    cropped.save(processed_path)
    print(f"    Cropped to {cropped.size}: {processed_path}")

    # Save to game dir
    if game_name:
        GAME_DIR.mkdir(parents=True, exist_ok=True)
        game_path = GAME_DIR / game_name
        cropped.save(game_path)
        print(f"    → Game: {game_path}")


def main():
    import io as _io

    for key, cfg in PANELS.items():
        print(f"\n{'='*60}")
        print(f"[{key}] → {cfg['output_raw']}")
        print(f"{'='*60}")

        raw_path = RAW_DIR / cfg["output_raw"]
        if raw_path.exists():
            print(f"    Raw exists, skipping generation. Delete to regenerate.")
            image_data = raw_path.read_bytes()
        else:
            image_data = _call_alapi(cfg["prompt"], raw_path)
            if image_data is None:
                print(f"    [FAILED] {key}")
                continue

        _crop_and_save(image_data, cfg["crop_box"], cfg["output_game"], key)

    print(f"\nDone. Raw: {RAW_DIR}  |  Game: {GAME_DIR}")


if __name__ == "__main__":
    import io
    main()
