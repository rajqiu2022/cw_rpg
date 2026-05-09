"""
gen_menu_buttons_gpt.py — 用 gpt-image-2 生成武侠风格主菜单按钮

流程：
1. 以 assets/raw/ui/btn_menu_3states.png 为参考，生成 3 张按钮底框（normal/hover/pressed）
2. 生成 3 张书法文字贴图（新游戏/读取存档/离开）
3. 用 Pillow 合成最终 9 张按钮（3 底框 × 3 文字）

输出：game/art/ui/main_menu/buttons/final/btn_<name>_<state>.png
"""

from __future__ import annotations

import asyncio
import base64
import os
import sys
import time
from pathlib import Path

# Fix Windows console encoding
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        try:
            _stream.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass

from dotenv import load_dotenv
from openai import AsyncOpenAI
from PIL import Image
import io

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

# --- Config ---
API_KEY = os.getenv("OPENAI_API_KEY", "")
BASE_URL = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")
MODEL = os.getenv("OPENAI_IMAGE_MODEL", "gpt-image-2")

REFERENCE_IMG = PROJECT_ROOT / "assets" / "raw" / "ui" / "btn_menu_3states.png"
OUTPUT_DIR = PROJECT_ROOT / "game" / "art" / "ui" / "main_menu" / "buttons" / "final"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Button specs
BUTTONS = [
    ("new_game", "新游戏"),
    ("continue", "读取存档"),
    ("quit", "离开"),
]

STATES = ["normal", "hover", "pressed"]


async def generate_image(client: AsyncOpenAI, prompt: str, reference_path: Path | None = None, size: str = "1536x1024", quality: str = "medium", background: str = "transparent") -> bytes | None:
    """Call gpt-image-2 to generate an image, optionally with reference."""
    
    kwargs = {
        "model": MODEL,
        "prompt": prompt,
        "size": size,
        "quality": quality,
    }
    
    # gpt-image-2 supports background parameter
    if background:
        kwargs["background"] = background
    
    print(f"  Calling API: size={size}, quality={quality}, bg={background}")
    print(f"  Prompt: {prompt[:120]}...")
    
    try:
        response = await client.images.generate(**kwargs)
        
        # Extract image data
        data = response.data
        if not data:
            print("  [ERROR] No data in response")
            return None
        
        item = data[0]
        
        # Try b64_json first
        b64 = getattr(item, "b64_json", None)
        if b64:
            return base64.b64decode(b64)
        
        # Try URL
        url = getattr(item, "url", None)
        if url:
            import httpx
            async with httpx.AsyncClient(timeout=60) as http:
                resp = await http.get(url)
                resp.raise_for_status()
                return resp.content
        
        print("  [ERROR] No b64_json or url in response item")
        return None
        
    except Exception as e:
        print(f"  [ERROR] API call failed: {type(e).__name__}: {e}")
        return None


async def generate_button_frames(client: AsyncOpenAI) -> dict[str, Path]:
    """Generate 3 button frames (normal, hover, pressed) using gpt-image-2."""
    
    results = {}
    
    prompts = {
        "normal": (
            "A single horizontal game UI button frame on a completely transparent background. "
            "The button is a dark slate-colored panel with an ornate silver metal border featuring "
            "Chinese cloud scroll (如意云纹) decorations at all four corners. "
            "The top center has an elegant emerald/jade gemstone set in a silver filigree mount. "
            "The interior has a subtle dark bamboo leaf texture pattern. "
            "Style: Chinese wuxia RPG game UI, dark fantasy, antique metalwork. "
            "The button should be horizontally elongated (about 3:1 ratio). "
            "No text, no characters, just the empty frame. "
            "Transparent PNG background."
        ),
        "hover": (
            "A single horizontal game UI button frame on a completely transparent background. "
            "Same design as a Chinese wuxia RPG button but in HOVER/ACTIVE state: "
            "The border glows with cyan/teal luminescence. The emerald gemstone at top center glows bright cyan. "
            "The metal frame has a cyan-blue aura/glow effect around it. "
            "Interior panel is slightly lighter with visible cyan energy wisps. "
            "Chinese cloud scroll (如意云纹) decorations at corners are illuminated in cyan. "
            "Style: Chinese wuxia RPG game UI with magical glow effect. "
            "Horizontally elongated (about 3:1 ratio). "
            "No text, no characters, just the glowing frame. "
            "Transparent PNG background."
        ),
        "pressed": (
            "A single horizontal game UI button frame on a completely transparent background. "
            "Same design as a Chinese wuxia RPG button but in PRESSED/SELECTED state: "
            "The border is warm gold/amber colored instead of silver. "
            "The gemstone at top center is an amber/topaz gem instead of emerald. "
            "Gold filigree decorations with Chinese cloud scroll (如意云纹) at corners. "
            "Interior panel is slightly darkened. "
            "Style: Chinese wuxia RPG game UI, golden ornate variant. "
            "Horizontally elongated (about 3:1 ratio). "
            "No text, no characters, just the golden frame. "
            "Transparent PNG background."
        ),
    }
    
    for state, prompt in prompts.items():
        print(f"\n[Frame] Generating {state} frame...")
        img_bytes = await generate_image(
            client, prompt,
            size="1536x1024",  # Wide format for button
            quality="medium",
            background="transparent",
        )
        if img_bytes:
            # Save raw frame
            out_path = OUTPUT_DIR / f"frame_{state}.png"
            out_path.write_bytes(img_bytes)
            results[state] = out_path
            print(f"  [OK] Saved: {out_path.name}")
        else:
            print(f"  [FAIL] Could not generate {state} frame")
        
        # Small delay between calls
        await asyncio.sleep(2)
    
    return results


async def generate_text_images(client: AsyncOpenAI) -> dict[str, Path]:
    """Generate calligraphy text images for each button."""
    
    results = {}
    
    for btn_key, btn_text in BUTTONS:
        print(f"\n[Text] Generating calligraphy for '{btn_text}'...")
        
        prompt = (
            f"Chinese calligraphy text '{btn_text}' written in elegant white brush calligraphy (书法) style "
            f"on a completely transparent background. "
            f"The characters should be bold, flowing, and artistic - typical of wuxia game title fonts. "
            f"White/silver colored strokes with slight ink splatter effects. "
            f"Only the text, nothing else. Centered composition. "
            f"Transparent PNG background."
        )
        
        img_bytes = await generate_image(
            client, prompt,
            size="1024x1024",
            quality="medium",
            background="transparent",
        )
        if img_bytes:
            out_path = OUTPUT_DIR / f"text_{btn_key}.png"
            out_path.write_bytes(img_bytes)
            results[btn_key] = out_path
            print(f"  [OK] Saved: {out_path.name}")
        else:
            print(f"  [FAIL] Could not generate text for '{btn_text}'")
        
        await asyncio.sleep(2)
    
    return results


def composite_buttons(frames: dict[str, Path], texts: dict[str, Path]):
    """Composite frame + text into final button images."""
    
    # Target button size (matching our game layout)
    BTN_W, BTN_H = 620, 186
    
    print("\n[Composite] Combining frames + text...")
    
    for btn_key, btn_text in BUTTONS:
        if btn_key not in texts:
            print(f"  [SKIP] No text image for {btn_key}")
            continue
        
        text_img = Image.open(texts[btn_key]).convert("RGBA")
        
        for state in STATES:
            if state not in frames:
                print(f"  [SKIP] No frame for {state}")
                continue
            
            frame_img = Image.open(frames[state]).convert("RGBA")
            
            # Resize frame to button size
            frame_resized = frame_img.resize((BTN_W, BTN_H), Image.LANCZOS)
            
            # Resize text to fit inside frame (with padding)
            text_area_w = int(BTN_W * 0.6)
            text_area_h = int(BTN_H * 0.55)
            text_resized = text_img.resize((text_area_w, text_area_h), Image.LANCZOS)
            
            # Composite: frame as base, text centered on top
            result = frame_resized.copy()
            text_x = (BTN_W - text_area_w) // 2
            text_y = (BTN_H - text_area_h) // 2 + 5  # Slightly lower to account for top gem
            result.paste(text_resized, (text_x, text_y), text_resized)
            
            # Save final button
            out_name = f"btn_{btn_key}_{state}.png"
            out_path = OUTPUT_DIR / out_name
            result.save(out_path, "PNG")
            print(f"  [OK] {out_name} ({BTN_W}x{BTN_H})")
    
    print("\n[DONE] All buttons generated!")


async def main():
    print("=" * 60)
    print("  GPT-Image-2 Wuxia Button Generator")
    print("=" * 60)
    print(f"  Model: {MODEL}")
    print(f"  Base URL: {BASE_URL}")
    print(f"  Reference: {REFERENCE_IMG.name}")
    print(f"  Output: {OUTPUT_DIR}")
    print("=" * 60)
    
    import httpx
    client = AsyncOpenAI(
        api_key=API_KEY,
        base_url=BASE_URL,
        http_client=httpx.AsyncClient(timeout=httpx.Timeout(300, connect=30)),
    )
    
    # Step 1: Generate button frames
    print("\n### STEP 1: Generate Button Frames ###")
    frames = await generate_button_frames(client)
    
    if not frames:
        print("\n[FATAL] No frames generated. Check API key / balance.")
        return
    
    # Step 2: Generate text images
    print("\n### STEP 2: Generate Calligraphy Text ###")
    texts = await generate_text_images(client)
    
    if not texts:
        print("\n[FATAL] No text images generated. Check API key / balance.")
        return
    
    # Step 3: Composite
    print("\n### STEP 3: Composite Final Buttons ###")
    composite_buttons(frames, texts)


if __name__ == "__main__":
    asyncio.run(main())
