"""gen_equip_icons.py — 为所有装备生成独立图标"""
import os, sys, time, io, re
from pathlib import Path
import httpx, numpy as np
from dotenv import load_dotenv
from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

KEY = os.getenv("OPENAI_API_KEY", "")
BASE_URL = os.getenv("OPENAI_BASE_URL", "")
URL = f"{BASE_URL}/images/generations"
HEADERS = {"token": KEY, "Content-Type": "application/json"}

EQ_DIR = PROJECT_ROOT / "game" / "data" / "equipment"
ICON_DIR = PROJECT_ROOT / "game" / "art" / "ui" / "inventory" / "icons"
ICON_DIR.mkdir(parents=True, exist_ok=True)

def make_prompt(name: str, desc: str) -> str:
    return (
        f"Chinese wuxia RPG equipment icon. {name}. {desc} "
        f"Dark wuxia fantasy style. Detailed, game-ready. "
        f"No text, no labels, no UI frames. "
        f"Pure white (#FFFFFF) background. Isolated item."
    )

items = []
for f in sorted(EQ_DIR.glob("*.tres")):
    content = f.read_text(encoding="utf-8")
    nm = re.search(r'display_name = "(.+?)"', content)
    dm = re.search(r'description = "(.+?)"', content)
    ip = re.search(r'icon_path = "(.+?)"', content)
    if nm and (not ip or ip.group(1) == ""):
        items.append((f, nm.group(1), dm.group(1) if dm else ""))

print(f"Generating {len(items)} equipment icons...")
total = len(items)
for i, (tres_path, name, desc) in enumerate(items):
    item_id = tres_path.stem
    prompt = make_prompt(name, desc)
    
    print(f"[{i+1}/{total}] {item_id}: {name}")
    sys.stdout.flush()
    
    payload = {"model": "gpt-image-2", "prompt": prompt, "n": 1, "size": "1024x1024", "quality": "medium"}
    
    try:
        with httpx.Client(timeout=httpx.Timeout(300, connect=30)) as client:
            resp = client.post(URL, headers=HEADERS, json=payload)
        
        if resp.status_code != 200:
            print(f"  API ERR {resp.status_code}: {resp.text[:100]}")
            continue
        
        j = resp.json()
        d = j.get("data")
        items_data = d.get("data") if isinstance(d, dict) and "data" in d else (d if isinstance(d, list) else None)
        if not items_data:
            print(f"  No data")
            continue
        
        img_url = items_data[0].get("url", "")
        r = httpx.get(img_url, timeout=60)
        img = Image.open(io.BytesIO(r.content)).convert("RGBA")
        
        arr = np.array(img)
        white = (arr[:,:,0] > 220) & (arr[:,:,1] > 220) & (arr[:,:,2] > 220)
        arr[white, 3] = 0
        
        alpha = arr[:,:,3]
        rows = np.any(alpha > 0, axis=1); cols = np.any(alpha > 0, axis=0)
        if rows.any():
            y0, y1 = np.where(rows)[0][[0, -1]]; x0, x1 = np.where(cols)[0][[0, -1]]
            pad = 10
            y0, y1 = max(0, y0-pad), min(arr.shape[0]-1, y1+pad)
            x0, x1 = max(0, x0-pad), min(arr.shape[1]-1, x1+pad)
            img = Image.fromarray(arr).crop((x0, y0, x1+1, y1+1))
        
        icon_path = f"res://art/ui/inventory/icons/icon_{item_id}.png"
        img.resize((256, 256), Image.LANCZOS).save(ICON_DIR / f"icon_{item_id}.png", "PNG")
        img.resize((64, 64), Image.LANCZOS).save(ICON_DIR / f"icon_{item_id}_sm.png", "PNG")
        
        content = tres_path.read_text(encoding="utf-8")
        content = content.replace('icon_path = ""', f'icon_path = "{icon_path}"')
        tres_path.write_text(content, encoding="utf-8")
        
        print(f"  OK")
        
    except Exception as e:
        print(f"  ERR: {e}")

print(f"\nDone! {total} equipment icons generated.")
