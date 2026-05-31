"""
Generate 16 walk right frames using n=4 (4 images per API call × 4 batches).
"""
import os, sys, io, base64, json
from pathlib import Path
from PIL import Image
import httpx
from dotenv import load_dotenv

PROJECT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT / '.env')
load_dotenv(PROJECT / '.env.local', override=True)

API_KEY = os.getenv('OPENAI_API_KEY')
BASE_URL = (os.getenv('OPENAI_BASE_URL') or 'https://v3.alapi.cn/api/ai').rstrip('/')
MODEL = os.getenv('OPENAI_IMAGE_MODEL', 'gpt-image-2')

OUT_DIR = PROJECT / 'assets' / 'raw' / 'sprite' / 'lengguyun'
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Reference image as base64
ref_path = PROJECT / 'assets' / 'processed' / 'characters' / 'protagonist_portrait_full.png'
ref_img = Image.open(ref_path).convert('RGB')
ref_img.thumbnail((1280, 1280), Image.LANCZOS)
buf = io.BytesIO()
ref_img.save(buf, format='JPEG', quality=88)
ref_b64 = base64.b64encode(buf.getvalue()).decode('ascii')

# 4 batches of 4 frames each = 16 frames
batches = [
    {
        'batch': 1,
        'frames': [
            '右向行走第1帧：左脚抬起迈步，右脚着地支撑',
            '右向行走第2帧：左脚前伸，右脚支撑过渡',
            '右向行走第3帧：过渡帧，双脚交错重心居中',
            '右向行走第4帧：右脚抬起迈步，左脚着地支撑',
        ]
    },
    {
        'batch': 2,
        'frames': [
            '右向行走第5帧：右脚前伸迈出，左脚支撑',
            '右向行走第6帧：过渡帧，双脚交错',
            '右向行走第7帧：左脚再次抬起迈步',
            '右向行走第8帧：右脚落地，接近第1帧姿态形成循环',
        ]
    },
    {
        'batch': 3,
        'frames': [
            '右向行走第9帧：左脚抬起迈步（步幅略大）',
            '右向行走第10帧：左脚前伸过渡',
            '右向行走第11帧：过渡帧，双脚交错',
            '右向行走第12帧：右脚抬起迈步',
        ]
    },
    {
        'batch': 4,
        'frames': [
            '右向行走第13帧：右脚前伸过渡',
            '右向行走第14帧：过渡帧，双脚交错',
            '右向行走第15帧：左脚抬起迈步',
            '右向行走第16帧：右脚落地，回到第1帧完成循环',
        ]
    },
]

LEGEND = """
冷孤云，二十岁青年男子，黑发束于脑后系一条简素深色发带，面庞轮廓分明棱角硬朗，
浓眉入鬓、眼神冷峻坚毅，身着深灰色布袍内衬白色中衣，腰间束带悬一柄长剑，
腰侧挂一只青瓷酒葫芦，体格修长矫健。
"""

STYLE = "90年代中国港式武侠漫画美术风格，2.5D漫画质感，墨线分明清晰，厚涂上色、色彩饱和鲜艳明亮。"

def call_api(prompt: str, n: int = 4) -> list[bytes]:
    """Call ALAPI generations endpoint with n images."""
    payload = {
        'model': MODEL,
        'prompt': prompt,
        'n': n,
        'size': '1024x1024',
        'quality': 'high',
        'image': [{'type': 'base64', 'data': ref_b64}],
    }

    url = BASE_URL
    if not url.endswith('/images/generations'):
        url = f'{url}/images/generations'

    print(f'  Calling {url}...')
    resp = httpx.post(url, headers={'token': API_KEY, 'Content-Type': 'application/json'},
                      json=payload, timeout=httpx.Timeout(300, connect=30))
    resp.raise_for_status()
    data = resp.json()

    if data.get('code') not in (None, 200):
        raise RuntimeError(f"API error: {data.get('message', 'unknown')}")

    # Extract all images
    items = data.get('data', {}).get('data', data.get('data', []))
    if isinstance(items, dict):
        items = [items]

    images = []
    for item in items:
        b64 = item.get('b64_json')
        url_val = item.get('url')
        if b64:
            images.append(base64.b64decode(b64))
        elif url_val:
            r = httpx.get(url_val, timeout=120)
            r.raise_for_status()
            images.append(r.content)

    return images

# Process each batch
frame_idx = 1
for batch in batches:
    bn = batch['batch']
    print(f'\n=== Batch {bn}/4 ===')

    frames_desc = '\n'.join(f'  {i+1}. {d}' for i, d in enumerate(batch['frames']))
    prompt = f"""{STYLE}

生成同一个武侠游戏角色的4个行走动画帧。角色必须完全一致：{LEGEND}

角色与参考图保持完全一致的长相、发型、服装、武器。

4个帧分别描述如下（每个帧是独立的一张图）：
{frames_desc}

每帧要求：
- 1024×1024，纯白色背景 #FFFFFF
- 角色高度约占画布 50%~55%，水平居中
- 双脚在画布底部约 10%~15% 处
- 武侠轻快步伐，手臂自然摆动，衣摆披风微飘
- 所有帧的角色体型、比例、位置完全一致

不要水印、签名、繁体中文。"""

    try:
        images = call_api(prompt, n=4)
        print(f'  Got {len(images)} images')
        for img_bytes in images:
            out_path = OUT_DIR / f'sprite_lengguyun_walk_right_v10_f{frame_idx}.png'
            out_path.write_bytes(img_bytes)
            print(f'  Saved F{frame_idx}: {out_path}')
            frame_idx += 1
    except Exception as e:
        print(f'  ERROR: {e}')
        # Continue with next batch

print(f'\nDone. Generated {frame_idx-1} frames.')
