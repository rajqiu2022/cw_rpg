"""
基于参考图生成明亮绿色主菜单背景
以 ui_cold_wuxia_main_menu_hover_load_gpt_v1.png 为参考，改为明亮翠绿色调
"""
import os, sys, time, base64, httpx, io
from pathlib import Path
from dotenv import load_dotenv
from PIL import Image

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

TOKEN = os.getenv("OPENAI_API_KEY", "")
if not TOKEN:
    print("ERROR: OPENAI_API_KEY not set in .env")
    sys.exit(1)

# 参考图路径
REF_IMAGE = Path(__file__).resolve().parent.parent / "assets" / "_archive" / "main_menu_hover_unwanted" / "ui_cold_wuxia_main_menu_hover_load_gpt_v1.png"

PROMPT = """Transform this Chinese wuxia game main menu image into a BRIGHTER version with a BLUE-dominant, green-accent color palette (similar to classic wuxia game art):

KEEP UNCHANGED:
- The male swordsman character on the left side (his pose, face, hair, costume design - keep him exactly as-is)
- The overall Chinese wuxia martial arts game aesthetic
- The composition layout with character on left, open space on right for UI

TITLE DESIGN (CRITICAL - must match this style exactly):
- The "云影侠传" title must be displayed on a DARK WOODEN PLAQUE/SIGNBOARD (黑色/深棕色木质匾额) at the top center
- The 4 Chinese characters "云影侠传" must be in GOLDEN/GILDED color (金色大字) on the dark plaque
- The plaque should have decorative green vines/leaves growing on its edges
- A jade pendant (翠玉坠子) hanging from the bottom of the plaque
- NO sword through the text, NO blue calligraphy style - it must be gold text on dark wooden board
- This plaque style is like a traditional Chinese inn signboard (客栈招牌)

COLOR PALETTE (CRITICAL - follow this ratio strictly):
- 65% BLUE tones: cerulean sky, blue-tinted distant mountains with morning mist, soft blue atmospheric haze, blue-grey stone paths
- 20% GREEN accents: bamboo stalks on the LEFT and RIGHT edges only (not everywhere), some green leaves on trees
- 15% WARM highlights: golden sunlight from above, warm brown traditional rooftops in the far distance
- The swordsman's outfit should remain DARK NAVY BLUE (深蓝/藏蓝), NOT green
- Mountains and distant landscape: blue-grey with misty fog (NOT green mountains)
- DO NOT make everything green - green is ONLY for bamboo edges and a few leaves

CHANGE - LIGHTING:
- Change from dark nighttime to bright DAYTIME with soft diffused sunlight from the upper area
- The overall scene should feel bright, airy, and serene - like an early morning in misty mountains
- Soft white/blue atmospheric mist between mountain layers
- Everything should be well-lit but with a cool blue-dominant tone (not warm/orange)

CHANGE - ATMOSPHERE:
- Misty blue mountains fading into the distance (like Chinese ink wash painting style)
- A few white cranes or birds flying in the sky
- Traditional Chinese architecture (pavilion/temple) visible in the misty far background
- Subtle waterfall in the distance
- Floating leaves or petals (sparse, not dense)

CHANGE - REMOVE UI ELEMENTS:
- Remove all button boxes and Chinese text buttons (新游戏/读取存档/离开) from center-right area
- Keep that area clean/empty (game code will add buttons dynamically)
- Keep the "云影侠传" dark wooden plaque with gold text at top center

STYLE: High-quality Chinese wuxia game key art. Semi-realistic digital painting with a serene, ethereal blue-mist atmosphere. Like a classic martial arts drama poster - elegant, not overly saturated. The feeling should be heroic yet peaceful, with depth created by layers of misty blue mountains."""

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "raw" / "scene_background"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
OUTPUT_FILE = OUTPUT_DIR / "ui_main_menu_blue_green_v3.png"

def compress_reference_image(img_path, max_size_kb=800):
    """压缩参考图到合理大小，避免上传超时"""
    img = Image.open(img_path)
    # 缩小到 1024 宽度
    if img.width > 1024:
        ratio = 1024 / img.width
        new_size = (1024, int(img.height * ratio))
        img = img.resize(new_size, Image.LANCZOS)
    
    # JPEG 压缩
    buf = io.BytesIO()
    img.convert("RGB").save(buf, format="PNG", optimize=True)
    result = buf.getvalue()
    print(f"[gen] Compressed reference: {len(result)/1024:.0f} KB ({img.size[0]}x{img.size[1]})")
    return result


def main():
    print(f"[gen] Generating bright green main menu from reference image...")
    print(f"[gen] Reference: {REF_IMAGE.name}")
    
    if not REF_IMAGE.exists():
        print(f"[gen] ERROR: Reference image not found: {REF_IMAGE}")
        sys.exit(1)
    
    # 压缩参考图
    ref_bytes = compress_reference_image(REF_IMAGE)
    ref_b64 = base64.b64encode(ref_bytes).decode()
    print(f"[gen] Encoded base64 size: {len(ref_b64)/1024:.0f} KB")
    
    url = "https://v3.alapi.cn/api/ai/images/generations"
    headers = {"token": TOKEN, "Content-Type": "application/json"}
    
    # 使用 gpt-image-2 带参考图的方式
    payload = {
        "model": "gpt-image-2",
        "prompt": PROMPT,
        "n": 1,
        "size": "1536x1024",
        "quality": "high",
        "image": [
            {
                "type": "base64",
                "data": ref_b64
            }
        ]
    }
    
    # 重试机制
    max_retries = 3
    for attempt in range(max_retries):
        t0 = time.time()
        print(f"[gen] Attempt {attempt+1}/{max_retries} - Sending to ALAPI...")
        try:
            with httpx.Client(timeout=httpx.Timeout(300, connect=30)) as client:
                resp = client.post(url, json=payload, headers=headers)
            elapsed = time.time() - t0
            break
        except (httpx.RemoteProtocolError, httpx.ReadTimeout, httpx.ConnectTimeout) as e:
            elapsed = time.time() - t0
            print(f"[gen] Attempt {attempt+1} failed after {elapsed:.1f}s: {type(e).__name__}: {e}")
            if attempt < max_retries - 1:
                print(f"[gen] Retrying in 5s...")
                time.sleep(5)
            else:
                print(f"[gen] All {max_retries} attempts failed.")
                sys.exit(1)
    
    if resp.status_code != 200:
        print(f"[gen] ERROR: HTTP {resp.status_code}")
        print(resp.text[:500])
        sys.exit(1)
    
    data = resp.json()
    print(f"[gen] Response: code={data.get('code')}, time={elapsed:.1f}s")
    
    if data.get("code") != 200:
        print(f"[gen] API Error: {data.get('message', 'unknown')}")
        print(f"[gen] Full: {str(data)[:500]}")
        sys.exit(1)
    
    # ALAPI 返回格式: {"code":200,"data":{"data":[{"url":"..."}]}}
    if "data" in data and isinstance(data.get("data"), dict) and "data" in data["data"]:
        items = data["data"]["data"]
    elif "data" in data:
        items = data["data"] if isinstance(data["data"], list) else [data["data"]]
    else:
        print(f"[gen] Unexpected response: {str(data)[:300]}")
        sys.exit(1)
    
    item = items[0]
    
    if "b64_json" in item and item["b64_json"]:
        img_bytes = base64.b64decode(item["b64_json"])
    elif "url" in item and item["url"]:
        print(f"[gen] Downloading from URL...")
        img_resp = httpx.get(item["url"], timeout=120)
        img_bytes = img_resp.content
    else:
        print(f"[gen] No image data in response")
        sys.exit(1)
    
    OUTPUT_FILE.write_bytes(img_bytes)
    size_mb = len(img_bytes) / 1024 / 1024
    print(f"[gen] Done in {elapsed:.1f}s, saved {OUTPUT_FILE.name} ({size_mb:.2f} MB)")
    print(f"[gen] Output: {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
