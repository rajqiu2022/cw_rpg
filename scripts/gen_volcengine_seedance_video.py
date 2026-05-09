"""Submit a Volcengine Ark Seedance 2.0 video trial and download the MP4.

The script intentionally keeps credentials out of source control. Set one of:

    VOLCENGINE_API_KEY
    ARK_API_KEY

before running it.
"""

from __future__ import annotations

import argparse
import base64
import io
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[1]
TASKS_ENDPOINT = "https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks"
VIDEOS_ENDPOINT = "https://ark.cn-beijing.volces.com/api/v3/videos"


def _api_key() -> str:
    return (
        os.getenv("VOLCENGINE_API_KEY", "").strip()
        or os.getenv("ARK_API_KEY", "").strip()
    )


def _headers(api_key: str) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }


def _post_json(url: str, payload: dict[str, Any], api_key: str, *, timeout: int) -> dict[str, Any]:
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=body,
        headers=_headers(api_key),
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {detail}") from exc


def _get_json(url: str, api_key: str, *, timeout: int) -> dict[str, Any]:
    request = urllib.request.Request(url, headers=_headers(api_key), method="GET")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {detail}") from exc


def _reference_frame_png(path: Path, *, frame_count: int, frame_index: int) -> bytes:
    image = Image.open(path).convert("RGBA")
    if frame_count > 1:
        cell_width = image.width // frame_count
        left = cell_width * frame_index
        image = image.crop((left, 0, left + cell_width, image.height))
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


def _data_url(png_bytes: bytes) -> str:
    encoded = base64.b64encode(png_bytes).decode("ascii")
    return f"data:image/png;base64,{encoded}"


def _plain_base64(png_bytes: bytes) -> str:
    return base64.b64encode(png_bytes).decode("ascii")


def _extract_task_id(result: dict[str, Any]) -> str | None:
    for key in ("id", "task_id"):
        value = result.get(key)
        if value:
            return str(value)
    data = result.get("data")
    if isinstance(data, dict):
        for key in ("id", "task_id"):
            value = data.get(key)
            if value:
                return str(value)
    return None


def _extract_video_url(result: dict[str, Any]) -> str | None:
    for key in ("video_url", "url"):
        value = result.get(key)
        if value:
            return str(value)

    data = result.get("data")
    if isinstance(data, dict):
        response = data.get("response")
        if isinstance(response, list) and response:
            return str(response[0])
        if isinstance(response, str):
            return response
        for key in ("video_url", "url"):
            value = data.get(key)
            if value:
                return str(value)

    content = result.get("content")
    if isinstance(content, dict):
        value = content.get("video_url")
        if value:
            return str(value)

    return None


def _extract_status(result: dict[str, Any]) -> str:
    for source in (result, result.get("data")):
        if isinstance(source, dict):
            status = source.get("status")
            if status:
                return str(status)
    return "unknown"


def _download(url: str, output: Path, timeout: int) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url, timeout=timeout) as response:
        output.write_bytes(response.read())


def build_prompt(direction: str) -> str:
    if direction != "down":
        raise ValueError("Only down direction is configured for this trial")
    return (
        "Use the uploaded first frame as the exact character identity. Generate a "
        "short seamless white-background RPG sprite animation of this wuxia "
        "character walking in place toward the camera. Orthographic front view, "
        "fixed camera, no zoom, no pan, no rotation, no scene, no shadow, no text. "
        "Keep the white hair, dark robe, belt, back sword, and green wine gourd "
        "consistent. The head, chest, belt center, sword, and gourd stay stable. "
        "Only the legs, feet, sleeves, and lower robe move subtly. The feet must "
        "alternate naturally: left foot contact, right foot passing, right foot "
        "contact, left foot passing, then loop smoothly. Avoid side-to-side body "
        "sway, avoid running, jumping, big arm swings, and large cloak swings. "
        "Plain pure white background, suitable for extracting eight sprite frames."
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate a Volcengine Seedance 2.0 trial")
    parser.add_argument("--direction", default="down", choices=["down"])
    parser.add_argument(
        "--reference",
        type=Path,
        default=PROJECT_ROOT
        / "assets/processed/sprite/sprite_lengguyun_walk_down_4f_balanced_slow.png",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=PROJECT_ROOT / "assets/raw/video/volc_seedance2_down_walk_trial.mp4",
    )
    parser.add_argument(
        "--meta",
        type=Path,
        default=PROJECT_ROOT / "assets/raw/video/volc_seedance2_down_walk_trial.meta.json",
    )
    parser.add_argument("--api-mode", choices=["tasks", "videos"], default="tasks")
    parser.add_argument("--model", default="doubao-seedance-2-0-260128")
    parser.add_argument("--ratio", default="1:1")
    parser.add_argument("--resolution", default="480p")
    parser.add_argument("--duration", type=int, default=4)
    parser.add_argument("--seed", type=int, default=-1)
    parser.add_argument("--reference-frame-count", type=int, default=4)
    parser.add_argument("--reference-frame-index", type=int, default=0)
    parser.add_argument("--poll-seconds", type=int, default=10)
    parser.add_argument("--timeout-seconds", type=int, default=600)
    return parser.parse_args()


def main() -> int:
    load_dotenv(PROJECT_ROOT / ".env")
    load_dotenv(PROJECT_ROOT / ".env.local", override=True)
    args = parse_args()
    api_key = _api_key()
    if not api_key:
        print("Set VOLCENGINE_API_KEY or ARK_API_KEY before running.", file=sys.stderr)
        return 2

    reference = args.reference.resolve()
    if not reference.exists():
        print(f"Reference image not found: {reference}", file=sys.stderr)
        return 2

    png_bytes = _reference_frame_png(
        reference,
        frame_count=args.reference_frame_count,
        frame_index=args.reference_frame_index,
    )
    prompt = build_prompt(args.direction)

    if args.api_mode == "tasks":
        endpoint = TASKS_ENDPOINT
        payload = {
            "model": args.model,
            "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": _data_url(png_bytes)}},
            ],
            "ratio": args.ratio,
            "resolution": args.resolution,
            "duration": args.duration,
            "seed": args.seed,
            "watermark": False,
            "return_last_frame": False,
            "generate_audio": False,
        }
    else:
        endpoint = VIDEOS_ENDPOINT
        payload = {
            "model": "Doubao-Seedance-2.0",
            "prompt": prompt,
            "binary_data_base64": _plain_base64(png_bytes),
            "ratio": args.ratio,
            "resolution": args.resolution,
            "seconds": args.duration,
            "seed": args.seed,
            "watermark": False,
            "return_last_frame": False,
            "generate_audio": False,
        }

    print(f"Submitting Volcengine Seedance job to {endpoint}")
    submit_result = _post_json(endpoint, payload, api_key, timeout=60)
    task_id = _extract_task_id(submit_result)
    if not task_id:
        print(json.dumps(submit_result, indent=2, ensure_ascii=False))
        print("No task id returned; stopping.", file=sys.stderr)
        return 1
    print(f"Task id: {task_id}")

    deadline = time.time() + args.timeout_seconds
    last_result: dict[str, Any] = submit_result
    video_url: str | None = None
    while time.time() < deadline:
        time.sleep(args.poll_seconds)
        if args.api_mode == "tasks":
            poll_url = f"{TASKS_ENDPOINT}/{task_id}"
        else:
            poll_url = f"{VIDEOS_ENDPOINT}/{task_id}"
        last_result = _get_json(poll_url, api_key, timeout=60)
        status = _extract_status(last_result)
        print(f"Status: {status}")
        video_url = _extract_video_url(last_result)
        if video_url:
            break
        if status.lower() in {"failed", "expired", "cancelled", "canceled"}:
            break

    meta = {
        "task_id": task_id,
        "api_mode": args.api_mode,
        "model": args.model,
        "reference": str(reference),
        "reference_frame_index": args.reference_frame_index,
        "output": str(args.output),
        "submit_result": submit_result,
        "last_result": last_result,
        "video_url": video_url,
    }
    args.meta.parent.mkdir(parents=True, exist_ok=True)
    args.meta.write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8")

    if not video_url:
        print(f"No video URL before timeout. Meta written: {args.meta}", file=sys.stderr)
        return 1

    print(f"Downloading video: {video_url}")
    _download(video_url, args.output, timeout=180)
    print(args.output)
    print(args.meta)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
