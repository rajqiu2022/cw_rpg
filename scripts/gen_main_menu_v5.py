"""
gen_main_menu_v5.py — 直接调 ALAPI gpt-image-2 生成完整主菜单图
融合用户喜欢的三个风格元素：
1. 金色描边书法标题 + 剑穿过
2. 暗色金属边框 + 宝石装饰菜单按钮
3. 蓝色仙侠山水背景 + 蓝衣剑客人物
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
OUTPUT_FILE = OUTPUT_DIR / "ui_main_menu_full_v5.png"

# 完整的主菜单生成 prompt
PROMPT = """Chinese wuxia martial arts game main menu screen, 1536x1024 landscape format.

BACKGROUND: Misty blue-toned mountain landscape with floating clouds, distant waterfalls cascading down steep peaks, ancient pine trees silhouetted against twilight sky. Cool blue-green color palette with subtle warm highlights from a setting sun. Ethereal, painterly Chinese ink wash style with modern game art polish.

LEFT SIDE CHARACTER: A lone swordsman in flowing blue robes standing on a cliff edge, viewed from behind at 3/4 angle, long hair blowing in the wind, a sheathed sword on his back. He gazes into the vast mountain vista. Anime-influenced wuxia character design.

TOP CENTER TITLE: Large ornate Chinese calligraphy characters "云影侠传" (Cloud Shadow Swordsman) in brilliant gold with metallic sheen and dark stroke outlines. A decorative horizontal sword pierces through the title horizontally. Small jade/emerald pendants hang from the sword. The title has a subtle golden glow aura. Style: epic game logo with traditional calligraphy brush strokes.

RIGHT SIDE MENU BUTTONS (3 buttons stacked vertically, centered on right half):
1. "新游戏" (New Game) - Dark ornate metal frame button with emerald green gradient fill, small gem decorations on corners, gold Chinese text
2. "读取存档" (Load Game) - Same dark metal frame style with teal/cyan gradient fill, gem corner decorations, gold text
3. "离开" (Quit) - Same frame style with dark red/crimson gradient fill, gem corners, gold text

Button style: Each button has an elaborate dark metal border with rivets and small gemstones, slightly curved rectangular shape, the text is centered in gold calligraphy.

COMPOSITION: The swordsman occupies the left 40%, the title is at top center, buttons are on the right side vertically centered. The overall mood is epic, mysterious, and inviting. No UI chrome or modern elements outside the described components.

STYLE: High quality 2D game art, semi-realistic with anime influence, rich detail, professional game UI design, Chinese martial arts fantasy aesthetic."""


def generate():
    """Call ALAPI gpt-image-2 to generate the main menu."""
    print(f"[*] Generating main menu with model={MODEL}")
    print(f"    Base URL: {BASE_URL}")
    print(f"    Output: {OUTPUT_FILE}")
    print()

    # ALAPI uses 'token' header, not 'Authorization: Bearer'
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

    with httpx.Client(timeout=httpx.Timeout(300, connect=30)) as client:
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

    # Save
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_bytes(image_data)
    size_kb = len(image_data) / 1024
    print(f"\n[OK] Saved: {OUTPUT_FILE} ({size_kb:.0f} KB)")
    print(f"     Time: {elapsed:.1f}s")
    return True


if __name__ == "__main__":
    success = generate()
    if not success:
        sys.exit(1)
