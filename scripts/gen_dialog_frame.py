"""生成武侠风格对话框 UI 背景图"""
import os, base64, httpx
from pathlib import Path
from dotenv import load_dotenv
from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / '.env')

API_KEY = os.getenv('OPENAI_API_KEY')
BASE_URL = os.getenv('OPENAI_BASE_URL', '').rstrip('/')

PROMPT = """Game UI dialog box frame for a Chinese wuxia (martial arts) RPG game, cold color palette.

Design requirements:
- Horizontal rectangular frame, aspect ratio approximately 4:1
- Border style: thin dark steel-blue metal frame with subtle ice-blue glow at edges
- Corner decorations: small geometric angular metal pieces (like sword guards), dark gunmetal with faint cyan highlight
- Interior: nearly transparent dark blue-black gradient (very dark, barely visible fill)
- Top-left area: small speaker name plate area with angular metallic bracket
- Overall color palette: dark navy, steel blue, ice-cyan accents, NO gold/warm colors
- Style matches a cold/icy wuxia mountain theme — minimalist, sharp, elegant
- Thin 2-3px border lines, not thick ornate frames
- Clean crisp edges, modern game UI quality
- NO text, NO characters inside, just the empty frame decoration
- Transparent background (PNG alpha)
- High resolution
"""

OUTPUT_PATH = PROJECT_ROOT / 'game/art/ui/field_hud/v2/hud_dialog_frame.png'


def main():
    headers = {'Content-Type': 'application/json', 'token': API_KEY}
    payload = {
        'model': 'gpt-image-2',
        'prompt': PROMPT,
        'n': 1,
        'size': '1536x1024',
        'quality': 'medium',
    }

    print('Generating dialog frame UI...')
    resp = httpx.post(f'{BASE_URL}/images/generations', json=payload, headers=headers, timeout=120)
    data = resp.json()

    if resp.status_code != 200:
        print(f'Error {resp.status_code}: {str(data)[:300]}')
        return

    raw_data = data.get('data', data)
    if isinstance(raw_data, dict) and 'data' in raw_data:
        items = raw_data['data']
    elif isinstance(raw_data, list):
        items = raw_data
    else:
        items = [raw_data]

    item = items[0]

    if 'b64_json' in item:
        OUTPUT_PATH.write_bytes(base64.b64decode(item['b64_json']))
    elif 'url' in item:
        print('Downloading...')
        img_resp = httpx.get(item['url'], timeout=60)
        OUTPUT_PATH.write_bytes(img_resp.content)
    else:
        print(f'Unexpected: {str(item)[:200]}')
        return

    print(f'Saved raw: {OUTPUT_PATH}')

    # Crop to content and ensure proper aspect ratio for dialog
    img = Image.open(OUTPUT_PATH).convert('RGBA')
    # Keep full image but resize to suitable dialog dimensions
    # Target: ~1200x280 (wide dialog panel, 4:1 aspect)
    img = img.resize((1200, 280), Image.LANCZOS)
    img.save(OUTPUT_PATH)
    print(f'Final dialog frame: {OUTPUT_PATH} ({img.size})')


if __name__ == '__main__':
    main()
