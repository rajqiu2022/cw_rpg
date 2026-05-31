"""生成 NPC 单帧大图（512x512 风格，与主角一致）"""
import os, base64, json, sys
from pathlib import Path
import httpx
from dotenv import load_dotenv
from PIL import Image
import numpy as np

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / '.env')

API_KEY = os.getenv('OPENAI_API_KEY')
BASE_URL = os.getenv('OPENAI_BASE_URL', '').rstrip('/')

STYLE = (
    "90年代中国港式武侠漫画美术风格，2.5D漫画质感，墨线分明清晰，"
    "厚涂上色、色彩饱和鲜艳明亮，人物五官立体，衣袂飘动有动势。"
)

NPCS = {
    'xingfantian': {
        'prompt': f"""{STYLE}

生成一个游戏角色的全身立绘（面朝镜头正面站立，俯视3/4角度）：

角色：刑樊天，三十岁壮年男子剑侠，白色长衫蓝色下裳，腰佩长剑，黑色束发高冠，面容英武冷峻，体格高大挺拔，单手按剑柄，气质飘逸潇洒。

关键要求：
- 单个角色全身，从头到脚完整，身体各部位不能有缺损或穿透
- 衣物完整覆盖身体，不能有破洞或裸露穿透效果
- 角色轮廓清晰完整，边缘干净利落
- 纯透明背景（alpha通道透明）
- 角色居中，占画面75%高度，四周留出足够边距
- 无文字，无装饰边框
- 适合作为2D RPG游戏中的NPC精灵图
""",
        'output': 'game/art/characters/npc_xingfantian_new.png',
        'final': 'game/art/characters/npc_xingfantian_idle_8f.png',
    },
    'blacksmith_liu': {
        'prompt': f"""{STYLE}

生成一个游戏角色的全身立绘（面朝镜头正面站立，俯视3/4角度）：

角色：铁匠刘，五十岁老铁匠，身材敦实矮壮，面膛通红布满皱纹，花白短发，上身着灰白色粗布短褂敞开前襟，露出壮硕胸膛，下穿黑色宽裤，腰系厚皮革围裙，右手握铁锤搭在肩上，左手叉腰，神态憨厚朴实。旁边有一个铁砧。

要求：
- 单个角色全身，从头到脚完整
- 纯白背景 #FFFFFF
- 角色居中，占画面80%高度
- 无文字，无装饰边框
- 适合作为2D RPG游戏中的NPC精灵图
""",
        'output': 'game/art/characters/npc_blacksmith_liu_new.png',
        'final': 'game/art/characters/npc_blacksmith_liu.png',
    },
    'shenbanzhan': {
        'prompt': f"""{STYLE}

生成一个游戏角色的全身立绘（面朝镜头正面站立，俯视3/4角度）：

角色：沈半盏，四十多岁中年文士，头戴青灰方巾，身穿蓝灰色宽袖长衫配白色内衬，墨绿色腰带，右手持折扇轻摇，面容儒雅温和微笑，身材中等偏瘦，气质从容淡然。

要求：
- 单个角色全身，从头到脚完整
- 纯白背景 #FFFFFF
- 角色居中，占画面80%高度
- 无文字，无装饰边框
- 适合作为2D RPG游戏中的NPC精灵图
""",
        'output': 'game/art/characters/npc_shenbanzhan_new.png',
        'final': 'game/art/characters/npc_shenbanzhan_idle_8f.png',
    },
}


def generate_npc(npc_id: str):
    npc = NPCS[npc_id]
    headers = {'Content-Type': 'application/json', 'token': API_KEY}
    payload = {
        'model': 'gpt-image-2',
        'prompt': npc['prompt'],
        'n': 1,
        'size': '1024x1024',
        'quality': 'medium',
    }

    print(f'[{npc_id}] Generating...')
    resp = httpx.post(f'{BASE_URL}/images/generations', json=payload, headers=headers, timeout=120)
    data = resp.json()

    if resp.status_code != 200:
        print(f'[{npc_id}] Error {resp.status_code}: {json.dumps(data, ensure_ascii=False)[:300]}')
        return False

    # ALAPI returns {data: {data: [{url:...}]}} or {data: [{url:...}]}
    raw_data = data.get('data', data)
    if isinstance(raw_data, dict) and 'data' in raw_data:
        items = raw_data['data']
    elif isinstance(raw_data, list):
        items = raw_data
    elif isinstance(raw_data, dict):
        items = [raw_data]
    else:
        items = []

    if not items:
        print(f'[{npc_id}] No data returned: {str(data)[:200]}')
        return False

    item = items[0]
    out_path = PROJECT_ROOT / npc['output']

    if 'b64_json' in item:
        img_data = base64.b64decode(item['b64_json'])
        out_path.write_bytes(img_data)
    elif 'url' in item:
        print(f'[{npc_id}] Downloading from URL...')
        img_resp = httpx.get(item['url'], timeout=60)
        out_path.write_bytes(img_resp.content)
    else:
        print(f'[{npc_id}] Unexpected format: {str(item)[:200]}')
        return False

    print(f'[{npc_id}] Raw saved: {out_path}')

    # Remove background and crop
    process_to_final(npc_id, out_path, PROJECT_ROOT / npc['final'])
    return True


def process_to_final(npc_id: str, raw_path: Path, final_path: Path):
    """用 rembg AI 抠图、裁切、resize 到约 512x512"""
    from rembg import remove as rembg_remove

    img = Image.open(raw_path).convert('RGBA')

    # 使用 rembg AI 模型抠图（比简单白色阈值准确得多）
    print(f'[{npc_id}] Running AI background removal...')
    img = rembg_remove(img)

    # Crop to content
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)

    # Resize to 512 height (maintain aspect ratio)
    w, h = img.size
    target_h = 512
    scale = target_h / h
    new_w = int(w * scale)
    img = img.resize((new_w, target_h), Image.LANCZOS)

    # Place on 512x512 canvas (centered)
    canvas = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    x_off = (512 - new_w) // 2
    canvas.paste(img, (x_off, 0), img)
    canvas.save(final_path)
    print(f'[{npc_id}] Final: {final_path} ({canvas.size})')


if __name__ == '__main__':
    targets = sys.argv[1:] if len(sys.argv) > 1 else list(NPCS.keys())
    for npc_id in targets:
        if npc_id not in NPCS:
            print(f'Unknown NPC: {npc_id}')
            continue
        generate_npc(npc_id)
