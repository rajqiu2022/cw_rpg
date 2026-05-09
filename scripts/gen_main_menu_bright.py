"""
生成明亮绿蓝融合色调的主菜单背景图 v2
蓝色冷色调 50% + 翠绿色 50%，人物中国古代武侠风（非日漫）
"""
import os, sys, time, base64, httpx
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

TOKEN = os.getenv("OPENAI_API_KEY", "")
if not TOKEN:
    print("ERROR: OPENAI_API_KEY not set in .env")
    sys.exit(1)

PROMPT = """Chinese wuxia martial arts game main menu screen, 1536x1024, digital painting combining traditional Chinese ink-wash (水墨) with realistic game art:

COLOR PALETTE (50% cool blue + 50% jade green):
- Background: misty blue-green mountains with cyan fog and jade-tinted bamboo forest
- Sky: gradient from cerulean blue at top to teal-green at horizon
- Overall tone: cool and refreshing, balanced between sapphire blue and emerald green

COMPOSITION:
- Top center: horizontal stone plaque with gold Chinese calligraphy title "云影侠传"
- Center area left open for UI buttons (do NOT draw any buttons or text boxes in center)
- Characters positioned at left 1/4 and right 1/4 of the image

CHARACTERS (Chinese wuxia style - heroic and handsome, NOT Japanese anime):
- Left side: young male swordsman, age 20-22, tall and lean athletic build (not bulky), handsome sharp face with sword-eyebrows (剑眉星目), NO facial hair, NO stubble, clean-shaven youthful look but with determined fierce eyes. Hair in neat high ponytail with a jade crown, some strands flowing in wind. Wearing elegant dark-blue hanfu robe with silver embroidery over light armor, jade pendant at waist, a sheathed straight jian sword in left hand held casually. Standing with confident posture, one hand behind back. Think young Linghu Chong / Yang Guo archetype - dashing and spirited young hero.
- Right side: beautiful female martial artist, age 19-21, slender graceful figure, strikingly beautiful face with phoenix eyes and defined features - pretty but with sharp warrior spirit in her gaze. Hair in flowing half-up style with jade hairpins and silk ribbons, some hair cascading over shoulders. Wearing white silk hanfu dress with blue-green gradient embroidery, light leather waist corset, flowing sleeves. BOTH HANDS clearly visible: right hand holding a thin elegant sword (薄剑) pointed down, left hand relaxed at her side. Only TWO arms total, TWO hands total - anatomically correct human figure. Think Zhao Min / Xiao Longnu archetype - beautiful, elegant, but dangerous.

BACKGROUND DETAILS:
- Layered misty mountains in blue-grey tones with clouds
- Ancient pine trees and bamboo grove with blue-green tones
- Stone platform or cliff edge where characters stand
- Distant waterfall with blue-white spray
- A few birds (cranes or swallows) flying in the sky

ANATOMY CRITICAL: Each character has exactly TWO arms and TWO hands. No extra limbs. Hands are clearly drawn with five fingers each. Check anatomy carefully.

STYLE: High-quality Chinese wuxia game promotional art, semi-realistic proportions (NOT anime proportions), detailed clothing and hair physics, ink-wash texture in background but characters rendered with clear sharp details. Characters are YOUNG and HANDSOME/BEAUTIFUL but with Chinese classical aesthetics (not Korean/Japanese pretty-boy style). Think Chinese wuxia drama poster (仙剑奇侠传/天涯明月刀 game art style)."""

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "raw" / "scene_background"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
OUTPUT_FILE = OUTPUT_DIR / "ui_main_menu_blue_green_blend_v4.png"

def main():
    print(f"[gen] Generating main menu background (blue-green blend v4 - young heroic wuxia)...")
    print(f"[gen] Using ALAPI gpt-image-1...")
    
    url = "https://v3.alapi.cn/api/ai/images/generations"
    headers = {"token": TOKEN, "Content-Type": "application/json"}
    payload = {
        "model": "gpt-image-2",
        "prompt": PROMPT,
        "n": 1,
        "size": "1536x1024",
        "quality": "high"
    }
    
    t0 = time.time()
    with httpx.Client(timeout=httpx.Timeout(300, connect=30)) as client:
        resp = client.post(url, json=payload, headers=headers)
    elapsed = time.time() - t0
    
    if resp.status_code != 200:
        print(f"[gen] ERROR: HTTP {resp.status_code}")
        print(resp.text[:500])
        sys.exit(1)
    
    data = resp.json()
    print(f"[gen] Full response: code={data.get('code')}, message={data.get('message')}, success={data.get('success')}")
    if data.get("data") is None:
        print(f"[gen] ERROR: API returned null data. Full: {str(data)[:500]}")
        sys.exit(1)
    print(f"[gen] data type: {type(data['data'])}, preview: {str(data['data'])[:200]}")
    
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
        img_resp = httpx.get(item["url"], timeout=60)
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
