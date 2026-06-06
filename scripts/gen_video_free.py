"""
gen_video_free.py — 免费视频 API 批量生成（豆包 / 千问）

调用豆包（火山方舟）或千问的免费视频生成额度，产出短动画帧，
用于 sprite 动画、场景动态元素等。

当前支持的免费额度（截至 2025 年中）：
    豆包（火山方舟·即梦）: 每日 5 次，每次 10 秒
    千问（"快乐马"）:       每日 10 次，每次 5 秒

用法：
    python scripts/gen_video_free.py --prompt "黑底猫咪待机动画，脚不动" --provider doubao
    python scripts/gen_video_free.py --task-file prompts/tasks_video.yaml
    python scripts/gen_video_free.py --provider qianwen --count 3

输出：
    assets/raw/video/<task_id>/
    ├── 0001.mp4           # 原始视频
    ├── frames/             # 抽帧 PNG（可选）
    │   ├── f01.png
    │   └── ...
    └── meta.json           # 生成元数据
"""

from __future__ import annotations

import argparse
import asyncio
import base64
import hashlib
import io
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import httpx
import yaml
from dotenv import load_dotenv
from PIL import Image
from rich.console import Console
from rich.table import Table

load_dotenv()

console = Console()

# ── 配置 ──
OUTPUT_ROOT = Path("assets/raw/video")
OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)

# 每日额度
DAILY_LIMITS = {
    "doubao": 5,
    "qianwen": 10,
}


# ═══════════════════════════════════════════════════════════════════
# 豆包（火山方舟·即梦）API
# ═══════════════════════════════════════════════════════════════════

DOUBAO_API_BASE = "https://ark.cn-beijing.volces.com/api/v3"
DOUBAO_VIDEO_MODEL = "doubao-seedance-1-0-pro-250528"


async def _doubao_video(
    client: httpx.AsyncClient,
    api_key: str,
    prompt: str,
    negative_prompt: str = "",
    duration_sec: int = 10,
    width: int = 1024,
    height: int = 1024,
) -> dict[str, Any]:
    """调用豆包视频生成 API，返回任务 metadata。"""
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    payload: dict[str, Any] = {
        "model": DOUBAO_VIDEO_MODEL,
        "prompt": prompt,
        "duration": duration_sec,
        "size": f"{width}x{height}",
    }
    if negative_prompt:
        payload["negative_prompt"] = negative_prompt

    # 提交任务
    resp = await client.post(
        f"{DOUBAO_API_BASE}/video/generations",
        headers=headers,
        json=payload,
        timeout=30,
    )
    if resp.status_code != 200:
        return {"error": f"HTTP {resp.status_code}: {resp.text[:200]}"}

    data = resp.json()
    task_id = data.get("task_id", "")

    # 轮询等待
    for attempt in range(60):
        await asyncio.sleep(10)
        poll = await client.get(
            f"{DOUBAO_API_BASE}/video/generations/{task_id}",
            headers=headers,
            timeout=30,
        )
        if poll.status_code != 200:
            continue
        poll_data = poll.json()
        status = poll_data.get("status", "")
        if status == "completed":
            return poll_data
        if status == "failed":
            return {"error": f"任务失败: {poll_data.get('error', 'unknown')}"}

    return {"error": "超时（10 分钟未完成）"}


# ═══════════════════════════════════════════════════════════════════
# 千问（"快乐马"）API
# ═══════════════════════════════════════════════════════════════════

QIANWEN_API_BASE = "https://dashscope.aliyuncs.com/api/v1"
QIANWEN_VIDEO_MODEL = "cogvideox-v1"


async def _qianwen_video(
    client: httpx.AsyncClient,
    api_key: str,
    prompt: str,
    duration_sec: int = 5,
) -> dict[str, Any]:
    """调用千问视频生成 API。"""
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "X-DashScope-Async": "enable",
    }
    payload = {
        "model": QIANWEN_VIDEO_MODEL,
        "input": {"prompt": prompt},
        "parameters": {"duration": duration_sec},
    }

    resp = await client.post(
        f"{QIANWEN_API_BASE}/services/aigc/video-generation/video-synthesis",
        headers=headers,
        json=payload,
        timeout=30,
    )
    if resp.status_code != 200:
        return {"error": f"HTTP {resp.status_code}: {resp.text[:200]}"}

    data = resp.json()
    task_id = data.get("output", {}).get("task_id", "")

    for attempt in range(60):
        await asyncio.sleep(10)
        poll = await client.get(
            f"{QIANWEN_API_BASE}/tasks/{task_id}",
            headers=headers,
            timeout=30,
        )
        if poll.status_code != 200:
            continue
        poll_data = poll.json()
        status = poll_data.get("output", {}).get("task_status", "")
        if status == "SUCCEEDED":
            return poll_data
        if status == "FAILED":
            return {"error": f"任务失败: {poll_data}"}

    return {"error": "超时（10 分钟未完成）"}


# ═══════════════════════════════════════════════════════════════════
# 视频下载 & 抽帧
# ═══════════════════════════════════════════════════════════════════

async def _download_video(client: httpx.AsyncClient, url: str, output_path: Path) -> bool:
    """下载视频到本地。"""
    try:
        resp = await client.get(url, timeout=120)
        if resp.status_code == 200:
            output_path.write_bytes(resp.content)
            return True
    except Exception as e:
        console.print(f"  [red]下载失败: {e}[/red]")
    return False


def extract_frames(video_path: Path, output_dir: Path, fps: int = 4) -> list[Path]:
    """
    从视频中抽帧。
    依赖 ffmpeg；如果不可用则跳过。
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    try:
        import subprocess
        result = subprocess.run(
            [
                "ffmpeg", "-i", str(video_path),
                "-vf", f"fps={fps}",
                "-q:v", "2",
                str(output_dir / "f%02d.png"),
            ],
            capture_output=True,
            timeout=60,
        )
        if result.returncode == 0:
            return sorted(output_dir.glob("f*.png"))
    except (FileNotFoundError, subprocess.TimeoutExpired):
        console.print("  [yellow]ffmpeg 不可用，跳过抽帧[/yellow]")
    return []


# ═══════════════════════════════════════════════════════════════════
# 主流程
# ═══════════════════════════════════════════════════════════════════

async def generate_one(
    client: httpx.AsyncClient,
    provider: str,
    api_key: str,
    task: dict[str, Any],
    output_root: Path,
    extract: bool = True,
) -> dict[str, Any]:
    """生成单个视频并下载。"""
    prompt = task.get("prompt", "")
    task_id = task.get("id", hashlib.md5(prompt.encode()).hexdigest()[:12])
    negative = task.get("negative_prompt", "")
    duration = task.get("duration_sec", 10 if provider == "doubao" else 5)

    console.print(f"\n[bold]▶ {task_id}[/bold]: {prompt[:60]}…")

    if provider == "doubao":
        result = await _doubao_video(client, api_key, prompt, negative, duration)
    elif provider == "qianwen":
        result = await _qianwen_video(client, api_key, prompt, duration)
    else:
        return {"error": f"未知 provider: {provider}"}

    if "error" in result:
        console.print(f"  [red]✗ {result['error']}[/red]")
        return result

    # 提取视频 URL
    video_url = ""
    if provider == "doubao":
        video_url = result.get("video_url", "")
    else:
        media = result.get("output", {}).get("video_url", "")
        video_url = media if isinstance(media, str) else ""

    if not video_url:
        return {"error": "未能获取视频 URL", "raw": result}

    # 下载
    task_dir = output_root / task_id
    task_dir.mkdir(parents=True, exist_ok=True)
    video_path = task_dir / f"{task_id}.mp4"

    console.print(f"  [dim]下载视频…[/dim]")
    if await _download_video(client, video_url, video_path):
        file_size_mb = video_path.stat().st_size / (1024 * 1024)
        console.print(f"  [green]✓ {video_path.name} ({file_size_mb:.1f} MB)[/green]")
    else:
        return {"error": "下载失败"}

    # 抽帧
    frames_dir = task_dir / "frames"
    frames: list[str] = []
    if extract:
        frame_paths = extract_frames(video_path, frames_dir, fps=task.get("extract_fps", 4))
        frames = [str(p.relative_to(task_dir)) for p in frame_paths]
        if frames:
            console.print(f"  [dim]抽帧 {len(frames)} 张[/dim]")

    # 写 meta.json
    meta = {
        "task_id": task_id,
        "provider": provider,
        "model": DOUBAO_VIDEO_MODEL if provider == "doubao" else QIANWEN_VIDEO_MODEL,
        "prompt": prompt,
        "negative_prompt": negative,
        "duration_sec": duration,
        "video": str(video_path.relative_to(output_root)),
        "frames": frames,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }
    (task_dir / "meta.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2))

    return meta


async def amain(args: argparse.Namespace) -> None:
    provider = args.provider
    api_key = os.environ.get(
        "DOUBAO_API_KEY" if provider == "doubao" else "DASHSCOPE_API_KEY", ""
    )
    if not api_key:
        console.print(f"[red]请设置环境变量 {'DOUBAO_API_KEY' if provider == 'doubao' else 'DASHSCOPE_API_KEY'}[/red]")
        sys.exit(1)

    # 额度检查
    daily_used_file = OUTPUT_ROOT / f".{provider}_used_today"
    today = datetime.now().strftime("%Y-%m-%d")
    if daily_used_file.exists():
        record = daily_used_file.read_text().strip()
        if record == today:
            console.print(f"[yellow]今日已用完 {provider} 额度[/yellow]")
            return
    limit = DAILY_LIMITS.get(provider, 5)

    tasks: list[dict[str, Any]] = []

    if args.task_file:
        data = yaml.safe_load(Path(args.task_file).read_text(encoding="utf-8"))
        tasks = data if isinstance(data, list) else data.get("tasks", [])
    elif args.prompt:
        tasks = [{"prompt": args.prompt, "id": args.task_name or "video_001"}]
    else:
        console.print("[red]请指定 --prompt 或 --task-file[/red]")
        sys.exit(1)

    tasks = tasks[: min(args.count, limit)]
    console.print(f"[bold]{provider}[/bold] 每日额度 {limit} 次，本次生成 {len(tasks)} 个")

    async with httpx.AsyncClient() as client:
        for task in tasks:
            result = await generate_one(
                client, provider, api_key, task, OUTPUT_ROOT, extract=not args.no_extract
            )
            if "error" not in result:
                console.print(f"  [green]✓ 视频: {result.get('video', '?')}[/green]")
            await asyncio.sleep(2)  # 避免触发频率限制

    daily_used_file.write_text(today)

    # 汇总
    table = Table(title="生成结果")
    table.add_column("Task", style="cyan")
    table.add_column("视频", style="green")
    table.add_column("帧数", style="dim")
    for task in tasks:
        tid = task.get("id", "?")
        meta_path = OUTPUT_ROOT / tid / "meta.json"
        if meta_path.exists():
            meta = json.loads(meta_path.read_text())
            table.add_row(tid, meta.get("video", "?"), str(len(meta.get("frames", []))))
    console.print(table)


def main() -> None:
    parser = argparse.ArgumentParser(description="免费视频 API 批量生成")
    parser.add_argument("--prompt", type=str, help="单个 prompt")
    parser.add_argument("--task-file", type=str, help="任务 YAML 文件路径")
    parser.add_argument("--task-name", type=str, default="", help="任务 ID / 名称")
    parser.add_argument("--provider", choices=["doubao", "qianwen"], default="doubao")
    parser.add_argument("--count", type=int, default=1, help="生成数量（受额度限制）")
    parser.add_argument("--no-extract", action="store_true", help="跳过抽帧")
    args = parser.parse_args()
    asyncio.run(amain(args))


if __name__ == "__main__":
    main()
