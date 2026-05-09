"""
gen_main_menu_bg_clean.py — 生成干净的主菜单背景（无按钮）
只保留：蓝色仙侠山水 + 蓝衣剑客 + 金色书法标题
按钮由游戏代码独立叠加，背景图上不画任何按钮。
"""

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

import httpx

API_KEY = os.getenv("OPENAI_API_KEY", "")
BASE_URL = os.getenv("OPENAI_BASE_URL", "")
MODEL = os.getenv("OPENAI_IMAGE_MODEL", "gpt-image-2")

OUTPUT_DIR = PROJECT_ROOT / "assets" / "raw" / "scene_background"
OUTPUT_FILE = OUTPUT_DIR / "ui_main_menu_bg_clean_v6.png"
# 同时复制到游戏目录
GAME_OUTPUT = PROJECT_ROOT / "game" / "art" / "backgrounds" / "bg_main_menu_v6_clean.png"

# Prompt: 只有背景+人物+标题，明确指示 NO BUTTONS / NO UI ELEMENTS
PROMPT = """Chinese wuxia martial arts game main menu BACKGROUND ONLY, 1536x1024 landscape format.

IMPORTANT: This image is ONLY the background. Do NOT include any buttons, menu items, UI panels, or interactive elements. The right side of the image should be open scenic space with NO text or UI overlays.

BACKGROUND: Misty blue-toned mountain landscape with floating clouds, distant waterfalls cascading down steep peaks, ancient pine trees silhouetted against twilight sky. Cool blue-green color palette with subtle warm highlights from a setting sun. Ethereal, painterly Chinese ink wash style with modern game art polish. The scene extends fully across the entire image without any UI elements blocking it.

LEFT SIDE CHARACTER (occupying left 35%): A lone swordsman in flowing blue robes standing on a cliff edge, viewed from behind at 3/4 angle, long hair blowing in the wind, a sheathed sword on his back. He gazes into the vast mountain vista. Anime-influenced wuxia character design.

TOP CENTER TITLE: Large ornate Chinese calligraphy characters "云影侠传" (Cloud Shadow Swordsman) in brilliant gold with metallic sheen and dark stroke outlines. A decorative horizontal sword pierces through the title horizontally. Small jade/emerald pendants hang from the sword. The title has a subtle golden glow aura. Style: epic game logo with traditional calligraphy brush strokes.

RIGHT SIDE: Open scenic vista continuing the mountain landscape. Beautiful misty peaks, floating clouds, and distant waterfalls. NO buttons, NO text, NO UI elements on the right side — just pure scenic beauty that will have game buttons overlaid programmatically later.

COMPOSITION: Swordsman on the left 35%, title at top center, the remaining right and center area is all open mountain scenery. The mood is epic, mysterious, serene, and inviting.

STYLE: High quality 2D game art, semi-realistic with anime influence, rich detail, professional game background art, Chinese martial arts fantasy aesthetic. Cinematic composition suitable for a game menu background."""


def generate():
    """Call ALAPI gpt-image-2 to generate clean background."""
    print(f"[*] Generating CLEAN main menu background (no buttons)")
    print(f"    Model: {MODEL}")
    print(f"    Base URL: {BASE_URL}")
    print(f"    Output: {OUTPUT_FILE}")
    print(f"    Game copy: {GAME_OUTPUT}")
    print()

    # ALAPI uses 'token' header
    is_alapi = "alapi.cn" in BASE_URL

    if is_alapi:
        url = f"{BASE_URL}/images/generations"
        headers = {
            "token": API_KEY,
            "Content-Type": "application/json",
        }
    else:
        url = f"{BASE_URL}/images/generations"
        headers = {
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json",
        }

    payload = {
        "model": MODEL,
        "prompt": PROMPT,
        "n": 1,
        "size": "1536x1024",
        "quality": "high",
    }

    print("[*] Sending request (this may take 30-60s)...")
    start = time.time()

    with httpx.Client(timeout=httpx.Timeout(600, connect=60, read=600)) as client:
        resp = client.post(url, headers=headers, json=payload)

    elapsed = time.time() - start
    print(f"[*] Response received in {elapsed:.1f}s, status={resp.status_code}")

    if resp.status_code != 200:
        print(f"[ERROR] API returned {resp.status_code}")
        print(resp.text[:2000])
        return False

    data = resp.json()

    # ALAPI response format: {"code": 200, "data": {"data": [{"url": "..."}]}}
    # or standard OpenAI: {"data": [{"b64_json": "...", "url": "..."}]}
    image_data = None

    if "data" in data and isinstance(data["data"], dict) and "data" in data["data"]:
        # ALAPI nested format
        items = data["data"]["data"]
        if items and "url" in items[0]:
            img_url = items[0]["url"]
            print(f"[*] Downloading image from URL...")
            with httpx.Client(timeout=60) as dl:
                img_resp = dl.get(img_url)
                image_data = img_resp.content
        elif items and "b64_json" in items[0]:
            image_data = base64.b64decode(items[0]["b64_json"])
    elif "data" in data and isinstance(data["data"], list):
        # Standard OpenAI format
        item = data["data"][0]
        if "b64_json" in item:
            image_data = base64.b64decode(item["b64_json"])
        elif "url" in item:
            print(f"[*] Downloading image from URL...")
            with httpx.Client(timeout=60) as dl:
                img_resp = dl.get(item["url"])
                image_data = img_resp.content

    if not image_data:
        print("[ERROR] Could not extract image from response")
        print(f"Response keys: {list(data.keys())}")
        if "data" in data:
            print(f"data type: {type(data['data'])}")
            if isinstance(data["data"], dict):
                print(f"data.keys: {list(data['data'].keys())}")
        return False

    # Save to assets/raw
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_bytes(image_data)
    size_kb = len(image_data) / 1024
    print(f"\n[OK] Saved raw: {OUTPUT_FILE} ({size_kb:.0f} KB)")

    # Copy to game/art/backgrounds/
    GAME_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    GAME_OUTPUT.write_bytes(image_data)
    print(f"[OK] Saved game: {GAME_OUTPUT} ({size_kb:.0f} KB)")

    print(f"     Time: {elapsed:.1f}s")
    print(f"\n[DONE] Clean background generated successfully!")
    print(f"       Next: update main_menu.gd to use 'bg_main_menu_v6_clean.png'")
    return True


if __name__ == "__main__":
    success = generate()
    if not success:
        sys.exit(1)
