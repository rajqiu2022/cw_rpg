"""
gen_walk_frames_16f.py — 逐帧生成 16 帧行走动画
每次 API 调用 n=4（同 prompt 生成 4 个自然变体），共 4 次调用 = 16 帧

用法：
    python scripts/gen_walk_frames_16f.py              # 正式出图
    python scripts/gen_walk_frames_16f.py --dry-run    # 只渲染 prompt
"""
from __future__ import annotations

import argparse
import asyncio
import base64
import io
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import httpx
from PIL import Image
from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent.parent

CHARACTER_NAME = "冷孤云"
CHARACTER_APPEARANCE = (
    "二十岁青年男子，黑发束于脑后系一条简素深色发带，几缕刘海略显不羁，"
    "面庞轮廓分明棱角硬朗，浓眉入鬓、眼神冷峻坚毅含杀气，"
    "下颌方正有力，嘴角微沉带一股狠劲，绝非阴柔小白脸，"
    "身着深灰色布袍内衬白色中衣，腰间束带悬一柄长剑，腰侧挂一只青瓷酒葫芦，"
    "体格修长矫健，宽肩窄腰，武者身板结实有力，"
    "整体气质冷峻硬朗、行侠仗义"
)

STYLE_ANCHOR = (
    "90 年代中国港式武侠漫画美术风格，2.5D 漫画质感，"
    "墨线分明清晰，厚涂上色、色彩饱和鲜艳明亮，"
    "人物五官立体，衣袂飘动有动势，"
    "整体明亮通透、光影对比鲜明、阳光感强、色彩活力充沛，"
    "保持暖色调与冷色调的鲜明对比，避免整体灰暗压抑。"
)

NEGATIVE = (
    "现代服装，3D CG 渲染感，照片级写实，"
    "网络红人脸，二次元萌系，迪士尼风，"
    "水印，签名，文字乱码，"
    "繁体中文，繁体字，traditional chinese characters，"
    "错字，简化字写错，"
    "整体灰暗，雾蒙蒙，低饱和，沉郁压抑，黯淡无光，灰蒙蒙的色调"
)

REF_IMAGE = PROJECT_ROOT / "assets" / "_style_bible" / "00_protagonist_portrait_ref.png"

# 4 批 prompt，每批 n=4 生成 4 个自然变体 → 共 16 帧
# 每批描述不同的行走关键阶段，模型自行生成该阶段内的自然姿态变化
BATCH_PROMPTS = [
    # 批次 1：右脚前迈阶段（产生 4 个不同瞬间）
    (
        "右脚前迈阶段",
        "右脚向前迈出，右膝微屈，脚跟即将或刚触地，"
        "左腿在后蹬直脚尖点地，身体重心在两脚之间前移，"
        "双臂自然交替摆动（左臂前摆、右臂后摆），"
        "左手扶剑鞘，上身微微前倾，衣摆向后轻扬。"
        "注意：请生成 4 张该阶段内不同瞬间的连续姿态，"
        "每张的脚部位置和手臂角度要有明显差异，形成自然过渡。",
    ),
    # 批次 2：右脚承重后蹬阶段
    (
        "右脚承重后蹬阶段",
        "右脚全掌着地承重，右腿蹬直发力，"
        "左腿向前摆动、左膝弯曲抬起、左脚离地，"
        "身体重心已完全移至右脚，上身微前倾，"
        "双臂大幅度交替摆动（右臂前摆、左臂后摆），"
        "左手仍扶剑鞘，袍摆随蹬地动作展开飘动。"
        "注意：请生成 4 张该阶段内不同瞬间的连续姿态，"
        "每张的左腿抬起高度和手臂摆动幅度要有明显差异。",
    ),
    # 批次 3：左脚前迈阶段
    (
        "左脚前迈阶段",
        "左脚向前迈出，左膝微屈，脚跟即将或刚触地，"
        "右腿在后蹬直脚尖点地，身体重心在两脚之间前移，"
        "双臂自然交替摆动（右臂前摆、左臂后摆），"
        "左手扶剑鞘，上身微微前倾，衣摆向后轻扬。"
        "注意：请生成 4 张该阶段内不同瞬间的连续姿态，"
        "每张的脚部位置和手臂角度要有明显差异，形成自然过渡。",
    ),
    # 批次 4：左脚承重后蹬阶段
    (
        "左脚承重后蹬阶段",
        "左脚全掌着地承重，左腿蹬直发力，"
        "右腿向前摆动、右膝弯曲抬起、右脚离地，"
        "身体重心已完全移至左脚，上身微前倾，"
        "双臂大幅度交替摆动（左臂前摆、右臂后摆），"
        "左手仍扶剑鞘，袍摆随蹬地动作展开飘动。"
        "注意：请生成 4 张该阶段内不同瞬间的连续姿态，"
        "每张的右腿抬起高度和手臂摆动幅度要有明显差异。",
    ),
]


def compress_ref_base64(path: Path, max_side: int = 1280, quality: int = 88) -> str:
    image = Image.open(path).convert("RGB")
    image.thumbnail((max_side, max_side), Image.LANCZOS)
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=quality, optimize=True)
    return base64.b64encode(buffer.getvalue()).decode("ascii")


def build_prompt(batch_label: str, phase_desc: str) -> str:
    return f"""{STYLE_ANCHOR}

游戏角色行走精灵单帧，用于 2D RPG 的 Sprite2D 动画序列。

角色：{CHARACTER_NAME}，{CHARACTER_APPEARANCE}，
与参考图保持完全一致的脸型、五官、发型、深灰色布袍、长剑、青瓷酒葫芦。

动作阶段：{batch_label}
- {phase_desc}
- 武侠轻快步伐，动作连贯自然
- 衣摆和袍服随步伐飘动

构图（极其重要）：
- 1024×1024 画布，纯白背景 #FFFFFF
- 角色从头顶到脚底高度占画布高度的 50%~55%
- 角色水平居中，双脚始终在画布底部 10%~15% 范围内
- 4 张图必须保持完全一致的角色外观、体型比例和光照风格

反向：{NEGATIVE}
- 禁止角色过高超过画布 60%
- 禁止脚底位置上下浮动
- 禁止改变脸型、五官、发型、服装颜色和款式"""


async def call_alapi(
    api_key: str,
    base_url: str,
    prompt: str,
    n: int,
    model: str,
    ref_b64: str | None,
) -> list[bytes]:
    """调用 ALAPI，n 张图，返回 n 个图片 bytes"""
    root = (base_url or "https://v3.alapi.cn/api/ai").rstrip("/")
    if root.endswith("/images/generations"):
        url = root
    else:
        url = f"{root}/images/generations"

    payload: dict = {
        "model": model,
        "prompt": prompt,
        "n": n,
        "size": "1024x1024",
        "quality": "high",
    }
    if ref_b64:
        payload["image"] = [{"type": "base64", "data": ref_b64}]

    async with httpx.AsyncClient(timeout=httpx.Timeout(300.0, connect=30.0)) as hc:
        response = await hc.post(
            url,
            headers={"token": api_key, "Content-Type": "application/json"},
            json=payload,
        )
        response.raise_for_status()
        data = response.json()

    if data.get("code") not in (None, 200):
        raise RuntimeError(f"ALAPI error code={data.get('code')} message={data.get('message')}")

    items = []
    data_field = data.get("data")
    if isinstance(data_field, dict) and isinstance(data_field.get("data"), list):
        items = data_field["data"]
    elif isinstance(data_field, list):
        items = data_field
    elif isinstance(data_field, dict):
        items = [data_field]

    if len(items) < n:
        raise RuntimeError(f"ALAPI 返回 {len(items)} 张图，期望 {n} 张")

    results: list[bytes] = []
    for item in items[:n]:
        if isinstance(item, dict):
            b64_val = item.get("b64_json")
            url_val = item.get("url")
        else:
            b64_val = getattr(item, "b64_json", None)
            url_val = getattr(item, "url", None)

        if b64_val:
            results.append(base64.b64decode(b64_val))
        elif url_val:
            async with httpx.AsyncClient(timeout=httpx.Timeout(120.0, connect=20.0)) as hc2:
                r = await hc2.get(str(url_val))
                r.raise_for_status()
                results.append(r.content)
        else:
            raise RuntimeError("返回项中既无 b64_json 也无 url")

    return results


async def main():
    parser = argparse.ArgumentParser(description="逐帧生成 16 帧行走动画")
    parser.add_argument("--dry-run", action="store_true", help="只渲染 prompt 不调 API")
    parser.add_argument(
        "--out-dir", type=str, default="assets/raw/sprite/walk_16f", help="输出目录"
    )
    args = parser.parse_args()

    load_dotenv(PROJECT_ROOT / ".env")
    load_dotenv(PROJECT_ROOT / ".env.local", override=True)

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key or api_key.startswith("sk-..."):
        print("[ERROR] 未配置 OPENAI_API_KEY，请先复制 .env.example 为 .env 并填入")
        return 2

    base_url = os.getenv("OPENAI_BASE_URL") or "https://v3.alapi.cn/api/ai"
    model = os.getenv("OPENAI_IMAGE_MODEL", "gpt-image-2")

    out_dir = PROJECT_ROOT / args.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    ref_b64 = None
    if REF_IMAGE.exists():
        ref_b64 = compress_ref_base64(REF_IMAGE)
        print(f"[OK] 参考图已加载: {REF_IMAGE}")
    else:
        print(f"[WARN] 参考图缺失: {REF_IMAGE}")

    if args.dry_run:
        print(f"\n=== DRY RUN: {len(BATCH_PROMPTS)} 批，每批 n=4，共 16 帧 ===\n")
        for i, (label, desc) in enumerate(BATCH_PROMPTS):
            prompt = build_prompt(label, desc)
            f_start = i * 4 + 1
            f_end = i * 4 + 4
            print(f"--- 批次 {i + 1}: 帧 {f_start:02d}~{f_end:02d} ({label}) ---")
            print(prompt)
            print()
        dry_dir = PROJECT_ROOT / "logs" / "dry_run"
        dry_dir.mkdir(parents=True, exist_ok=True)
        dry_meta = {
            "task": "walk_16f",
            "dry_run": True,
            "batches": [
                {
                    "batch": i + 1,
                    "frames": f"{i*4+1:02d}~{i*4+4:02d}",
                    "label": label,
                    "prompt": build_prompt(label, desc),
                }
                for i, (label, desc) in enumerate(BATCH_PROMPTS)
            ],
        }
        (dry_dir / "walk_16f.meta.json").write_text(
            json.dumps(dry_meta, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        print("Dry-run meta -> logs/dry_run/walk_16f.meta.json")
        return 0

    n_per_batch = 4
    total_batches = len(BATCH_PROMPTS)
    total_frames = total_batches * n_per_batch

    print(f"\n=== 生成 {total_frames} 帧: {total_batches} 批 × n={n_per_batch} ===\n")

    frame_idx = 1
    for batch_num, (label, desc) in enumerate(BATCH_PROMPTS, 1):
        f_start = frame_idx
        f_end = frame_idx + n_per_batch - 1
        prompt = build_prompt(label, desc)

        print(f"[批次 {batch_num}/{total_batches}] {label} → 帧 {f_start:02d}~{f_end:02d}")
        print(f"  prompt 长度: {len(prompt)} chars")

        try:
            imgs = await call_alapi(api_key, base_url, prompt, n_per_batch, model, ref_b64)
        except Exception as e:
            print(f"  [ERROR] {type(e).__name__}: {e}")
            frame_idx += n_per_batch
            continue

        for j, img_bytes in enumerate(imgs):
            fidx = frame_idx + j
            out_png = out_dir / f"raw_F{fidx:02d}.png"
            out_meta = out_dir / f"raw_F{fidx:02d}.meta.json"
            out_png.write_bytes(img_bytes)
            out_meta.write_text(
                json.dumps(
                    {
                        "frame_index": fidx,
                        "total_frames": total_frames,
                        "batch": batch_num,
                        "batch_label": label,
                        "batch_variant": j + 1,
                        "model": model,
                        "generated_at": datetime.now(timezone.utc).isoformat(),
                    },
                    ensure_ascii=False,
                    indent=2,
                ),
                encoding="utf-8",
            )
            print(f"  [OK] raw_F{fidx:02d}.png ({len(img_bytes):,} bytes)")

        frame_idx += n_per_batch

        if batch_num < total_batches:
            wait_s = 2
            print(f"  (冷却 {wait_s}s...)")
            await asyncio.sleep(wait_s)

    print(f"\n=== 完成! 输出: {out_dir} ===")
    print(f"共 {total_frames} 帧，可拖入 Godot SpriteFrames 使用")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
