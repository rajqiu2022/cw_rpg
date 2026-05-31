"""
精灵表工具（Sprite Tool）— 集生成 + 切割于一体

子命令：
  generate  - 用 AI（gpt-image-2）生成精灵表或逐帧精灵动画
  split     - 将精灵表切割为单帧图片
  preview   - 将单帧图片拼成预览动画 GIF

用法：
  python sprite_tool.py generate --help
  python sprite_tool.py split --help
  python sprite_tool.py preview --help

示例：
  # 生成4方向行走精灵表
  python sprite_tool.py generate --character "蓝袍剑客" --action walk --directions right,left,up,down --frames 9

  # 生成精灵表并自动切割
  python sprite_tool.py generate --character "蓝袍剑客" --action walk --directions right,left,up,down --auto-split

  # 切割已有精灵表
  python sprite_tool.py split images/hero.png -r right,left,up,down --walk 9 --idle 4

  # 从单帧生成预览 GIF
  python sprite_tool.py preview images/hero_frames/ --fps 12
"""
from __future__ import annotations

import argparse
import asyncio
import base64
import io
import json
import os
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

import httpx
import numpy as np
from PIL import Image
from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent.parent

# ============================================================
# 通用配置
# ============================================================

def load_env():
    load_dotenv(PROJECT_ROOT / '.env')
    load_dotenv(PROJECT_ROOT / '.env.local', override=True)


def get_api_config():
    """获取 AI 图片生成 API 配置"""
    api_key = os.getenv('OPENAI_API_KEY')
    base_url = (os.getenv('OPENAI_BASE_URL') or 'https://v3.alapi.cn/api/ai').rstrip('/')
    model = os.getenv('OPENAI_IMAGE_MODEL', 'gpt-image-2')
    return api_key, base_url, model


# ============================================================
# AI 生成模块
# ============================================================

# 预置角色模板
CHARACTER_PRESETS = {
    'lengguyun': {
        'name': '冷孤云',
        'appearance': (
            "二十岁青年男子，黑发束于脑后系一条简素深色发带，几缕刘海略显不羁，"
            "面庞轮廓分明棱角硬朗，浓眉入鬓、眼神冷峻坚毅，"
            "身着深灰色布袍内衬白色中衣，腰间束带悬一柄长剑，腰侧挂一只青瓷酒葫芦，"
            "体格修长矫健，宽肩窄腰"
        ),
        'ref_image': 'assets/_style_bible/00_protagonist_portrait_ref.png',
    },
    'shenbanzhan': {
        'name': '沈半盏',
        'appearance': (
            "四十岁中年文士，面容清癯儒雅，留有一缕短须，双目含笑暗藏精光，"
            "头戴青灰色方巾，身穿暗青色长衫外罩浅灰色薄氅，腰系墨绿色布带，"
            "手持一把折扇，身形消瘦清高，气度从容不迫，举止间有几分落拓书生气"
        ),
        'ref_image': 'assets/art_validation_v2/character_v2/portrait_shenbanzhan_friendly.png',
    },
    'duqingshan': {
        'name': '杜青衫',
        'appearance': (
            "二十五六岁青年女子，面容秀丽冷艳，柳眉杏目带几分英气，"
            "黑发高束马尾以碧绿玉簪固定，几缕碎发垂于额前，"
            "身穿深蓝色紧身劲装外罩月白色短披风，腰束皮带别着匕首与药囊，"
            "脚蹬黑色短靴，身姿挺拔利落，气质干练飒爽"
        ),
        'ref_image': 'assets/art_validation_v2/character_v2/portrait_duqingshan_steady.png',
    },
    'xingfantian': {
        'name': '刑樊天',
        'appearance': (
            "三十岁壮年男子，络腮胡须浓密，面色黝黑粗犷，虎目圆睁气势逼人，"
            "头绑赤红色额带，乱发披肩，身穿暗褐色皮甲露出健壮臂膀，"
            "左肩搭一条狼皮披风，腰悬宽刃朴刀，双臂肌肉虬结，"
            "体格魁梧壮硕如铁塔，浑身散发粗豪战意"
        ),
        'ref_image': 'assets/art_validation_v2/character_v2/portrait_xingfantian_serious.png',
    },
    'blacksmith_liu': {
        'name': '铁匠刘',
        'appearance': (
            "五十岁老铁匠，身材敦实矮壮，面膛通红布满皱纹，花白短发扎于脑后，"
            "上身仅着一件灰白色粗布短褂敞开前襟，露出满是灼伤疤痕的胸膛，"
            "下穿黑色宽裤束腿，腰系厚皮革围裙已被铁水灼出无数小洞，"
            "双臂粗壮有力，右手常握铁锤，神态憨厚朴实中透出匠人执着"
        ),
        'ref_image': '',
    },
}

# 预置动作模板
ACTION_PRESETS = {
    'walk': {
        'phases_4dir': {
            'right': '向右行走，面朝右方',
            'left': '向左行走，面朝左方',
            'up': '向上行走，背对镜头',
            'down': '向下行走，面朝镜头',
        },
        'frame_desc': '行走动画帧，双脚交替迈步，手臂自然摆动，衣摆微飘',
    },
    'idle': {
        'phases_4dir': {
            'right': '面朝右方站立',
            'left': '面朝左方站立',
            'up': '背对镜头站立',
            'down': '面朝镜头站立',
        },
        'frame_desc': '站立待机动画帧，微微呼吸起伏，衣摆轻微飘动',
    },
    'attack': {
        'phases_4dir': {
            'right': '面朝右方攻击',
            'left': '面朝左方攻击',
            'up': '背对镜头攻击',
            'down': '面朝镜头攻击',
        },
        'frame_desc': '攻击动画帧，拔剑挥斩，动作刚猛有力',
    },
    'run': {
        'phases_4dir': {
            'right': '向右奔跑',
            'left': '向左奔跑',
            'up': '向上奔跑，背对镜头',
            'down': '向下奔跑，面朝镜头',
        },
        'frame_desc': '奔跑动画帧，步幅大速度快，衣摆大幅飘动',
    },
}

STYLE_DEFAULT = (
    "90年代中国港式武侠漫画美术风格，2.5D漫画质感，"
    "墨线分明清晰，厚涂上色、色彩饱和鲜艳明亮，"
    "人物五官立体，衣袂飘动有动势。"
)

NEGATIVE_DEFAULT = (
    "现代服装，3D CG 渲染感，照片级写实，"
    "网络红人脸，二次元萌系，迪士尼风，"
    "水印，签名，文字乱码，繁体中文"
)


def compress_ref_image(path: Path, max_side: int = 1280, quality: int = 88) -> str:
    """将参考图压缩为 base64"""
    image = Image.open(path).convert('RGB')
    image.thumbnail((max_side, max_side), Image.LANCZOS)
    buf = io.BytesIO()
    image.save(buf, format='JPEG', quality=quality, optimize=True)
    return base64.b64encode(buf.getvalue()).decode('ascii')


def build_spritesheet_prompt(
    character_name: str,
    character_appearance: str,
    action: str,
    direction: str,
    frame_count: int,
    style: str = STYLE_DEFAULT,
    negative: str = NEGATIVE_DEFAULT,
    custom_desc: str = '',
) -> str:
    """构建精灵表生成 prompt"""
    action_preset = ACTION_PRESETS.get(action, {})
    dir_desc = action_preset.get('phases_4dir', {}).get(direction, f'{direction}方向')
    frame_desc = action_preset.get('frame_desc', f'{action}动画帧')

    if custom_desc:
        frame_desc = custom_desc

    prompt = f"""{style}

生成一张游戏角色精灵表(Sprite Sheet)，包含 {frame_count} 帧 {action} 动画。

角色：{character_name}，{character_appearance}

方向：{dir_desc}
动作：{frame_desc}

精灵表格式要求：
- 所有帧排成一横行，从左到右按时间顺序排列
- 每帧之间间距均匀
- 每帧角色大小、位置一致
- 纯白背景 #FFFFFF
- 画布宽高比约 {frame_count}:1（例如 {frame_count * 128}x128 或 {frame_count * 256}x256）

动画要求：
- {frame_count} 帧构成完整循环
- 帧与帧之间动作过渡自然流畅
- 角色体型、比例、服装在所有帧中完全一致
- 角色双脚底部对齐在同一水平线上

反向要求：{negative}"""
    return prompt


def build_single_frame_prompt(
    character_name: str,
    character_appearance: str,
    action: str,
    direction: str,
    frame_idx: int,
    total_frames: int,
    style: str = STYLE_DEFAULT,
    negative: str = NEGATIVE_DEFAULT,
    custom_desc: str = '',
) -> str:
    """构建单帧生成 prompt"""
    action_preset = ACTION_PRESETS.get(action, {})
    dir_desc = action_preset.get('phases_4dir', {}).get(direction, f'{direction}方向')
    frame_desc = action_preset.get('frame_desc', f'{action}动画帧')

    if custom_desc:
        frame_desc = custom_desc

    # 计算动画周期中的相位
    phase = frame_idx / total_frames
    if action in ('walk', 'run'):
        if phase < 0.25:
            phase_desc = '右脚前迈，左脚后蹬'
        elif phase < 0.5:
            phase_desc = '右脚着地承重，左脚抬起'
        elif phase < 0.75:
            phase_desc = '左脚前迈，右脚后蹬'
        else:
            phase_desc = '左脚着地承重，右脚抬起'
    elif action == 'idle':
        phase_desc = '微微呼吸起伏'
    elif action == 'attack':
        if phase < 0.3:
            phase_desc = '蓄力准备'
        elif phase < 0.6:
            phase_desc = '挥剑攻击'
        else:
            phase_desc = '收招回正'
    else:
        phase_desc = ''

    prompt = f"""{style}

游戏角色单帧精灵图，用于 2D RPG 的 Sprite2D 动画序列。

角色：{character_name}，{character_appearance}

方向：{dir_desc}
动作：第 {frame_idx}/{total_frames} 帧，{frame_desc}
当前姿态：{phase_desc}

构图要求：
- 1024x1024 画布，纯白背景 #FFFFFF
- 角色从头顶到脚底高度占画布高度的 50%~55%
- 角色水平居中，双脚始终在画布底部 10%~15% 范围内

反向要求：{negative}"""
    return prompt


async def call_image_api(
    api_key: str,
    base_url: str,
    model: str,
    prompt: str,
    n: int = 1,
    size: str = '1024x1024',
    ref_b64: str | None = None,
) -> list[bytes]:
    """调用图片生成 API"""
    url = base_url if base_url.endswith('/images/generations') else f'{base_url}/images/generations'

    payload = {
        'model': model,
        'prompt': prompt,
        'n': n,
        'size': size,
        'quality': 'high',
    }
    if ref_b64:
        payload['image'] = [{'type': 'base64', 'data': ref_b64}]

    headers = {'Content-Type': 'application/json'}
    # ALAPI uses 'token' header; standard OpenAI uses 'Authorization: Bearer'
    if 'alapi' in base_url.lower():
        headers['token'] = api_key
    else:
        headers['Authorization'] = f'Bearer {api_key}'

    async with httpx.AsyncClient(timeout=httpx.Timeout(300.0, connect=30.0)) as client:
        response = await client.post(url, headers=headers, json=payload)
        response.raise_for_status()
        data = response.json()

    if data.get('code') not in (None, 200):
        raise RuntimeError(f"API error: code={data.get('code')} message={data.get('message')}")

    # Parse response (compatible with ALAPI and OpenAI formats)
    items = []
    data_field = data.get('data')
    if isinstance(data_field, dict) and isinstance(data_field.get('data'), list):
        items = data_field['data']
    elif isinstance(data_field, list):
        items = data_field
    elif isinstance(data_field, dict):
        items = [data_field]

    results = []
    for item in items[:n]:
        if isinstance(item, dict):
            b64_val = item.get('b64_json')
            url_val = item.get('url')
        else:
            b64_val = getattr(item, 'b64_json', None)
            url_val = getattr(item, 'url', None)

        if b64_val:
            results.append(base64.b64decode(b64_val))
        elif url_val:
            async with httpx.AsyncClient(timeout=httpx.Timeout(120.0, connect=20.0)) as dl:
                r = await dl.get(str(url_val))
                r.raise_for_status()
                results.append(r.content)
        else:
            raise RuntimeError("Response item has no b64_json or url")

    return results


async def cmd_generate(args):
    """生成精灵图/精灵表"""
    load_env()
    api_key, base_url, model = get_api_config()

    if not api_key:
        print("[ERROR] 未配置 OPENAI_API_KEY，请在 .env 中设置")
        return 1

    # 解析角色
    character_name = args.character
    character_appearance = args.appearance or ''
    ref_b64 = None

    # 检查是否使用预置角色
    if args.preset and args.preset in CHARACTER_PRESETS:
        preset = CHARACTER_PRESETS[args.preset]
        character_name = character_name or preset['name']
        character_appearance = character_appearance or preset['appearance']
        ref_path = PROJECT_ROOT / preset['ref_image']
        if ref_path.exists():
            ref_b64 = compress_ref_image(ref_path)
            print(f"[OK] 参考图: {ref_path}")
    elif args.ref_image:
        ref_path = Path(args.ref_image)
        if not ref_path.is_absolute():
            ref_path = PROJECT_ROOT / ref_path
        if ref_path.exists():
            ref_b64 = compress_ref_image(ref_path)
            print(f"[OK] 参考图: {ref_path}")
        else:
            print(f"[WARN] 参考图不存在: {ref_path}")

    if not character_name:
        print("[ERROR] 必须指定角色名称 (--character) 或预置 (--preset)")
        return 1

    # 解析参数
    action = args.action
    directions = [d.strip() for d in args.directions.split(',')]
    frame_count = args.frames
    style = args.style or STYLE_DEFAULT
    mode = args.mode  # 'sheet' or 'single'

    out_dir = Path(args.output) if args.output else PROJECT_ROOT / 'assets' / 'raw' / 'sprite' / f'{action}_{len(directions)}dir'
    if not out_dir.is_absolute():
        out_dir = PROJECT_ROOT / out_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"\n=== 精灵生成 ===")
    print(f"  角色: {character_name}")
    print(f"  动作: {action}")
    print(f"  方向: {directions}")
    print(f"  帧数: {frame_count}/方向")
    print(f"  模式: {'精灵表' if mode == 'sheet' else '逐帧'}")
    print(f"  输出: {out_dir}")
    print(f"  API: {base_url}")
    print(f"  模型: {model}")
    print()

    if args.dry_run:
        print("=== DRY RUN ===\n")
        for direction in directions:
            if mode == 'sheet':
                prompt = build_spritesheet_prompt(
                    character_name, character_appearance, action, direction, frame_count, style
                )
                print(f"--- {direction} (精灵表, {frame_count}帧) ---")
                print(prompt)
                print()
            else:
                for f_idx in range(1, frame_count + 1):
                    prompt = build_single_frame_prompt(
                        character_name, character_appearance, action, direction,
                        f_idx, frame_count, style
                    )
                    if f_idx == 1:
                        print(f"--- {direction} F{f_idx:02d} ---")
                        print(prompt)
                        print(f"  ... (后续 {frame_count - 1} 帧 prompt 结构相同)")
                        print()
                    break
        return 0

    total_calls = len(directions) * (1 if mode == 'sheet' else (frame_count + 3) // 4)
    print(f"预计 API 调用: {total_calls} 次\n")

    meta = {
        'task': f'sprite_{action}',
        'character': character_name,
        'action': action,
        'directions': directions,
        'frames_per_dir': frame_count,
        'mode': mode,
        'model': model,
        'generated_at': datetime.now(timezone.utc).isoformat(),
        'results': [],
    }

    for dir_idx, direction in enumerate(directions):
        print(f"\n[{dir_idx + 1}/{len(directions)}] 方向: {direction}")

        if mode == 'sheet':
            # 一次生成整个精灵表
            prompt = build_spritesheet_prompt(
                character_name, character_appearance, action, direction, frame_count, style
            )
            # 精灵表用较宽的尺寸
            size = '1536x1024' if frame_count <= 8 else '1024x1024'

            try:
                images = await call_image_api(api_key, base_url, model, prompt, n=1, size=size, ref_b64=ref_b64)
                out_path = out_dir / f'{action}_{direction}_sheet.png'
                out_path.write_bytes(images[0])
                print(f"  [OK] {out_path.name} ({len(images[0]):,} bytes)")
                meta['results'].append({'direction': direction, 'file': out_path.name, 'type': 'sheet'})
            except Exception as e:
                print(f"  [ERROR] {type(e).__name__}: {e}")

        else:
            # 逐帧生成（每次 n=4）
            batch_size = min(4, frame_count)
            for batch_start in range(0, frame_count, batch_size):
                batch_end = min(batch_start + batch_size, frame_count)
                n_this_batch = batch_end - batch_start
                f_start = batch_start + 1
                f_end = batch_end

                # 用批次第一帧的 prompt
                prompt = build_single_frame_prompt(
                    character_name, character_appearance, action, direction,
                    f_start, frame_count, style
                )

                print(f"  批次 F{f_start:02d}~F{f_end:02d} (n={n_this_batch})...", end='')

                try:
                    images = await call_image_api(
                        api_key, base_url, model, prompt, n=n_this_batch, size='1024x1024', ref_b64=ref_b64
                    )
                    for j, img_bytes in enumerate(images):
                        fidx = batch_start + j + 1
                        fname = f'{action}_{direction}_F{fidx:02d}.png'
                        (out_dir / fname).write_bytes(img_bytes)
                        meta['results'].append({'direction': direction, 'frame': fidx, 'file': fname})
                    print(f" OK ({len(images)} imgs)")
                except Exception as e:
                    print(f" ERROR: {e}")

                # 冷却
                if batch_end < frame_count:
                    await asyncio.sleep(2)

        # 方向间冷却
        if dir_idx < len(directions) - 1:
            await asyncio.sleep(3)

    # 保存 meta
    meta_path = out_dir / 'generate_meta.json'
    meta_path.write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"\n=== 完成! 输出: {out_dir} ===")
    print(f"Meta: {meta_path}")

    # 自动切割
    if args.auto_split and mode == 'sheet':
        print("\n--- 自动切割精灵表 ---")
        for direction in directions:
            sheet_path = out_dir / f'{action}_{direction}_sheet.png'
            if sheet_path.exists():
                split_dir = out_dir / 'frames'
                split_dir.mkdir(exist_ok=True)
                split_single_row_sheet(
                    str(sheet_path), str(split_dir),
                    direction=direction, action=action,
                    expected_frames=frame_count
                )

    return 0


# ============================================================
# 切割模块
# ============================================================

def remove_checker_background(img, threshold=240, soften=1):
    """去除背景（边缘连通域 flood-fill 方法，不会误删角色内部白色衣物）

    算法：从图像四条边缘出发，BFS 扩展所有 R/G/B 均 >= threshold 的像素，
    只有与边缘连通的白色区域才被设为透明。角色身体内部的浅色区域不受影响。

    Args:
        img: PIL Image
        threshold: 像素 RGB 各通道 >= 此值才被视为背景（默认240，纯白/近白）
        soften: 边缘柔化半径，消除锯齿（默认1）
    """
    from collections import deque

    rgba = img.convert('RGBA')
    w, h = rgba.size
    arr = np.array(rgba)

    # BFS 从边缘出发找连通的白色/浅灰背景区域
    visited = np.zeros((h, w), dtype=bool)
    queue = deque()

    # 初始化：扫描四条边
    for x in range(w):
        for y in (0, h - 1):
            r, g, b, a = arr[y, x]
            if r >= threshold and g >= threshold and b >= threshold and a > 0:
                if not visited[y, x]:
                    visited[y, x] = True
                    queue.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            r, g, b, a = arr[y, x]
            if r >= threshold and g >= threshold and b >= threshold and a > 0:
                if not visited[y, x]:
                    visited[y, x] = True
                    queue.append((x, y))

    # BFS 扩展
    while queue:
        cx, cy = queue.popleft()
        for nx, ny in ((cx-1, cy), (cx+1, cy), (cx, cy-1), (cx, cy+1)):
            if nx < 0 or ny < 0 or nx >= w or ny >= h:
                continue
            if visited[ny, nx]:
                continue
            r, g, b, a = arr[ny, nx]
            if r >= threshold and g >= threshold and b >= threshold and a > 0:
                visited[ny, nx] = True
                queue.append((nx, ny))

    # 将连通背景区设为透明
    bg_mask = visited

    # 柔化边缘：将背景边界附近的近白像素也设为透明（消除白边）
    if soften > 0:
        # 找到背景区域的边界像素
        from scipy import ndimage
        dilated = ndimage.binary_dilation(bg_mask, iterations=soften)
        # 扩展区域中，近白色的也设为透明（threshold - 15）
        edge_zone = dilated & ~bg_mask
        soften_thresh = threshold - 15
        edge_is_bg = (
            (arr[:, :, 0] >= soften_thresh) &
            (arr[:, :, 1] >= soften_thresh) &
            (arr[:, :, 2] >= soften_thresh)
        )
        bg_mask = bg_mask | (edge_zone & edge_is_bg)

    # 应用 mask
    result = arr.copy()
    result[bg_mask, 3] = 0

    return Image.fromarray(result, 'RGBA')


def detect_row_boundaries(alpha, min_gap=10):
    """通过alpha通道检测行边界"""
    row_density = np.sum(alpha > 20, axis=1).astype(float) / alpha.shape[1]
    threshold = 0.005

    in_content = False
    rows = []
    start = 0
    gap_count = 0

    for y in range(len(row_density)):
        if row_density[y] > threshold:
            if not in_content:
                start = y
                in_content = True
            gap_count = 0
        else:
            if in_content:
                gap_count += 1
                if gap_count > min_gap:
                    rows.append((start, y - gap_count))
                    in_content = False
                    gap_count = 0
    if in_content:
        rows.append((start, len(row_density)))
    return rows


def detect_frame_columns(alpha_row, min_frame_width=40, min_gap=5):
    """检测一行中各帧的x范围"""
    col_density = np.sum(alpha_row > 20, axis=0)
    height = alpha_row.shape[0]
    threshold = height * 0.01

    in_content = False
    frames = []
    start = 0
    gap_count = 0

    for x in range(len(col_density)):
        if col_density[x] > threshold:
            if not in_content:
                start = x
                in_content = True
            gap_count = 0
        else:
            if in_content:
                gap_count += 1
                if gap_count > min_gap:
                    end = x - gap_count
                    if end - start >= min_frame_width:
                        frames.append((start, end))
                    in_content = False
                    gap_count = 0
    if in_content:
        end = len(col_density)
        if end - start >= min_frame_width:
            frames.append((start, end))
    return frames


def uniform_frame_size(frame_images, target_size=None):
    """统一帧尺寸（底部对齐）"""
    if not frame_images:
        return frame_images
    if target_size is None:
        max_w = max(f.width for f in frame_images)
        max_h = max(f.height for f in frame_images)
    else:
        max_w, max_h = target_size

    result = []
    for frame in frame_images:
        if frame.width == max_w and frame.height == max_h:
            result.append(frame)
        else:
            new_frame = Image.new('RGBA', (max_w, max_h), (0, 0, 0, 0))
            offset_x = (max_w - frame.width) // 2
            offset_y = max_h - frame.height
            new_frame.paste(frame, (offset_x, offset_y))
            result.append(new_frame)
    return result


def split_single_row_sheet(sheet_path: str, output_dir: str, direction: str, action: str,
                            expected_frames: int, padding: int = 2, min_frame_gap: int = 5,
                            min_frame_w: int = 40):
    """切割单行精灵表"""
    img = Image.open(sheet_path).convert('RGBA')
    img = remove_checker_background(img)
    arr = np.array(img)
    alpha = arr[:, :, 3]

    frame_cols = detect_frame_columns(alpha, min_frame_width=min_frame_w, min_gap=min_frame_gap)
    print(f"  {direction}: 检测到 {len(frame_cols)} 帧 (期望 {expected_frames})")

    os.makedirs(output_dir, exist_ok=True)
    frames = []
    for i, (left, right) in enumerate(frame_cols):
        frame = img.crop((left, 0, right, img.height))
        bbox = frame.getbbox()
        if bbox:
            x0 = max(0, bbox[0] - padding)
            y0 = max(0, bbox[1] - padding)
            x1 = min(frame.width, bbox[2] + padding)
            y1 = min(frame.height, bbox[3] + padding)
            frame = frame.crop((x0, y0, x1, y1))
            frames.append(frame)

    frames = uniform_frame_size(frames)
    for i, frame in enumerate(frames):
        fname = f'{direction}_{action}_{i + 1:02d}.png'
        frame.save(os.path.join(output_dir, fname))
    print(f"  -> 保存 {len(frames)} 帧到 {output_dir}")


def cmd_split(args):
    """切割精灵表"""
    input_path = os.path.abspath(args.input)
    if not os.path.exists(input_path):
        print(f"错误: 文件不存在: {input_path}")
        return 1

    output_dir = os.path.abspath(args.output) if args.output else \
        os.path.join(os.path.dirname(input_path), 'hero_frames')

    row_names = [n.strip() for n in args.rows.split(',')]
    walk_count = args.walk
    idle_count = args.idle
    do_uniform = not args.no_uniform
    padding = args.padding

    print(f"输入: {input_path}")
    print(f"输出: {output_dir}")
    print(f"方向: {row_names}")
    print(f"帧分配: walk={walk_count}, idle={idle_count}, 每行共{walk_count + idle_count}帧")
    print(f"统一尺寸: {'是' if do_uniform else '否'}")
    print()

    img = Image.open(input_path)
    print(f"精灵表尺寸: {img.width} x {img.height}")
    print("去除棋盘格背景...")
    img = remove_checker_background(img)

    arr = np.array(img)
    alpha = arr[:, :, 3]

    # 检测行
    rows = detect_row_boundaries(alpha, min_gap=args.min_gap)
    print(f"\n检测到 {len(rows)} 行:")
    for i, (top, bot) in enumerate(rows):
        name = row_names[i] if i < len(row_names) else f"row{i}"
        print(f"  行{i} ({name}): y={top}~{bot} (高度{bot - top}px)")

    expected_rows = len(row_names)
    if len(rows) != expected_rows:
        print(f"\n警告: 期望{expected_rows}行但检测到{len(rows)}行，尝试调整...")
        for gap in [8, 5, 3, 2]:
            rows = detect_row_boundaries(alpha, min_gap=gap)
            if len(rows) == expected_rows:
                print(f"  min_gap={gap} 时检测到 {len(rows)} 行")
                break
        if len(rows) != expected_rows:
            h = img.height // expected_rows
            rows = [(i * h, (i + 1) * h) for i in range(expected_rows)]
            print(f"  fallback: 等分 ({h}px/行)")

    # 清空输出
    os.makedirs(output_dir, exist_ok=True)
    for f in os.listdir(output_dir):
        fp = os.path.join(output_dir, f)
        if os.path.isfile(fp):
            os.remove(fp)

    # 切割
    all_frames = []
    total_expected = walk_count + idle_count

    for row_idx, (row_top, row_bottom) in enumerate(rows):
        if row_idx >= len(row_names):
            break
        direction = row_names[row_idx]
        row_alpha = alpha[row_top:row_bottom, :]
        frame_cols = detect_frame_columns(row_alpha, min_frame_width=args.min_frame_w, min_gap=args.min_frame_gap)

        print(f"\n行 {row_idx} ({direction}): 检测到 {len(frame_cols)} 帧", end='')
        if len(frame_cols) != total_expected:
            print(f" (期望{total_expected})", end='')
        print()

        if len(frame_cols) == 0:
            print(f"  [!] 帧检测失败，跳过")
            continue

        widths = [f[1] - f[0] for f in frame_cols]
        print(f"  帧宽: min={min(widths)} max={max(widths)} avg={sum(widths) // len(widths)}")

        for frame_idx, (col_left, col_right) in enumerate(frame_cols):
            frame = img.crop((col_left, row_top, col_right, row_bottom))
            bbox = frame.getbbox()
            if bbox:
                x0 = max(0, bbox[0] - padding)
                y0 = max(0, bbox[1] - padding)
                x1 = min(frame.width, bbox[2] + padding)
                y1 = min(frame.height, bbox[3] + padding)
                frame = frame.crop((x0, y0, x1, y1))
            else:
                continue

            if frame_idx < walk_count:
                filename = f"{direction}_walk_{frame_idx + 1:02d}.png"
            elif frame_idx < walk_count + idle_count:
                idle_idx = frame_idx - walk_count + 1
                filename = f"{direction}_idle_{idle_idx:02d}.png"
            else:
                extra_idx = frame_idx - walk_count - idle_count + 1
                filename = f"{direction}_extra_{extra_idx:02d}.png"

            all_frames.append((filename, frame))

    # 统一尺寸
    if do_uniform and all_frames:
        print(f"\n统一帧尺寸...")
        images = [f[1] for f in all_frames]
        max_w = max(f.width for f in images)
        max_h = max(f.height for f in images)
        print(f"  目标尺寸: {max_w} x {max_h}")
        images = uniform_frame_size(images, (max_w, max_h))
        all_frames = [(all_frames[i][0], images[i]) for i in range(len(all_frames))]

    for filename, frame in all_frames:
        frame.save(os.path.join(output_dir, filename))

    print(f"\n完成! 共输出 {len(all_frames)} 帧 -> {output_dir}")

    directions_summary = {}
    for filename, _ in all_frames:
        parts = filename.split('_')
        key = f"{parts[0]}_{parts[1]}"
        directions_summary[key] = directions_summary.get(key, 0) + 1
    print(f"\n帧分布:")
    for key, count in sorted(directions_summary.items()):
        print(f"  {key}: {count} 帧")

    return 0


# ============================================================
# 预览模块
# ============================================================

def cmd_preview(args):
    """从单帧图片生成预览 GIF"""
    input_dir = Path(args.input)
    if not input_dir.is_absolute():
        input_dir = PROJECT_ROOT / input_dir
    if not input_dir.exists():
        print(f"错误: 目录不存在: {input_dir}")
        return 1

    fps = args.fps
    direction = args.direction
    action_filter = args.action

    # 收集帧
    patterns = []
    if direction and action_filter:
        patterns.append(f'{direction}_{action_filter}_')
    elif direction:
        patterns.append(f'{direction}_')
    elif action_filter:
        patterns.append(f'_{action_filter}_')

    frame_files = sorted(input_dir.glob('*.png'))
    if patterns:
        frame_files = [f for f in frame_files if any(p in f.name for p in patterns)]

    if not frame_files:
        print(f"未找到匹配的帧文件")
        return 1

    print(f"找到 {len(frame_files)} 帧")
    print(f"FPS: {fps}")

    frames = [Image.open(f).convert('RGBA') for f in frame_files]

    # 统一尺寸
    max_w = max(f.width for f in frames)
    max_h = max(f.height for f in frames)
    uniform_frames = []
    for frame in frames:
        bg = Image.new('RGBA', (max_w, max_h), (200, 200, 200, 255))  # 灰色背景方便预览
        offset_x = (max_w - frame.width) // 2
        offset_y = max_h - frame.height
        bg.paste(frame, (offset_x, offset_y), frame)
        uniform_frames.append(bg.convert('RGB'))

    # 输出 GIF
    out_name = f"preview_{direction or 'all'}_{action_filter or 'all'}.gif"
    out_path = input_dir / out_name
    if args.output:
        out_path = Path(args.output)
        if not out_path.is_absolute():
            out_path = PROJECT_ROOT / out_path

    duration = int(1000 / fps)
    uniform_frames[0].save(
        out_path,
        save_all=True,
        append_images=uniform_frames[1:],
        duration=duration,
        loop=0,
    )
    print(f"\n完成! GIF: {out_path}")
    print(f"  尺寸: {max_w}x{max_h}, 帧数: {len(uniform_frames)}, 时长: {len(uniform_frames) * duration}ms")
    return 0


# ============================================================
# 主入口
# ============================================================

def main():
    parser = argparse.ArgumentParser(
        description='精灵表工具 - 生成 / 切割 / 预览',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    subparsers = parser.add_subparsers(dest='command', help='子命令')

    # --- generate ---
    gen_parser = subparsers.add_parser('generate', aliases=['gen'], help='AI 生成精灵图')
    gen_parser.add_argument('--character', '-c', help='角色名称')
    gen_parser.add_argument('--appearance', '-a', help='角色外貌描述')
    gen_parser.add_argument('--preset', '-p',
                           choices=list(CHARACTER_PRESETS.keys()),
                           help='预置角色: ' + ', '.join(CHARACTER_PRESETS.keys()))
    gen_parser.add_argument('--ref-image', help='参考图路径')
    gen_parser.add_argument('--action', default='walk', help='动作类型 (walk/idle/attack/run，默认: walk)')
    gen_parser.add_argument('--directions', '-d', default='right,left,up,down',
                           help='方向，逗号分隔 (默认: right,left,up,down)')
    gen_parser.add_argument('--frames', '-f', type=int, default=9, help='每方向帧数 (默认: 9)')
    gen_parser.add_argument('--mode', '-m', choices=['sheet', 'single'], default='single',
                           help='生成模式: sheet=一张精灵表 / single=逐帧 (默认: single)')
    gen_parser.add_argument('--style', help='风格描述 (默认: 港式武侠漫画)')
    gen_parser.add_argument('--output', '-o', help='输出目录')
    gen_parser.add_argument('--auto-split', action='store_true', help='sheet模式下自动切割')
    gen_parser.add_argument('--dry-run', action='store_true', help='只输出 prompt 不调 API')

    # --- split ---
    spl_parser = subparsers.add_parser('split', help='切割精灵表')
    spl_parser.add_argument('input', help='输入精灵表图片路径')
    spl_parser.add_argument('--output', '-o', help='输出目录')
    spl_parser.add_argument('--rows', '-r', default='right,left,up,down',
                           help='从上到下各行方向名 (默认: right,left,up,down)')
    spl_parser.add_argument('--walk', type=int, default=9, help='走动帧数 (默认: 9)')
    spl_parser.add_argument('--idle', type=int, default=4, help='站立帧数 (默认: 4)')
    spl_parser.add_argument('--no-uniform', action='store_true', help='不统一帧尺寸')
    spl_parser.add_argument('--padding', type=int, default=2, help='trim边距 (默认: 2px)')
    spl_parser.add_argument('--min-gap', type=int, default=10, help='行间最小空白 (默认: 10px)')
    spl_parser.add_argument('--min-frame-gap', type=int, default=5, help='帧间最小空白 (默认: 5px)')
    spl_parser.add_argument('--min-frame-w', type=int, default=40, help='最小帧宽 (默认: 40px)')

    # --- preview ---
    prev_parser = subparsers.add_parser('preview', help='生成预览 GIF')
    prev_parser.add_argument('input', help='帧图片目录')
    prev_parser.add_argument('--fps', type=int, default=12, help='帧率 (默认: 12)')
    prev_parser.add_argument('--direction', help='筛选方向 (right/left/up/down)')
    prev_parser.add_argument('--action', help='筛选动作 (walk/idle)')
    prev_parser.add_argument('--output', '-o', help='输出 GIF 路径')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 0

    if args.command in ('generate', 'gen'):
        return asyncio.run(cmd_generate(args))
    elif args.command == 'split':
        return cmd_split(args)
    elif args.command == 'preview':
        return cmd_preview(args)
    else:
        parser.print_help()
        return 0


if __name__ == '__main__':
    sys.exit(main() or 0)
