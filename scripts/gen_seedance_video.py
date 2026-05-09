"""Submit a minimal Seedance video job through DMXAPI and download the MP4.

This is intentionally separate from gen_assets.py because Seedance uses an
async video endpoint instead of the OpenAI images endpoint.
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
DEFAULT_ENDPOINT = "https://www.dmxapi.com/v1/responses"


def _endpoint_from_env() -> str:
    base_url = os.getenv("OPENAI_BASE_URL", "").strip().rstrip("/")
    if base_url:
        return f"{base_url}/responses"
    return DEFAULT_ENDPOINT


def _auth_headers(api_key: str, *, bearer: bool = True) -> dict[str, str]:
    auth_value = f"Bearer {api_key}" if bearer else api_key
    return {
        "Authorization": auth_value,
        "Content-Type": "application/json",
    }


def _post_json(
    url: str,
    payload: dict[str, Any],
    api_key: str,
    *,
    timeout: int,
    bearer: bool = True,
) -> dict[str, Any]:
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=body,
        headers=_auth_headers(api_key, bearer=bearer),
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {detail}") from exc


def _get_json(url: str, api_key: str, *, timeout: int, bearer: bool = True) -> dict[str, Any]:
    req = urllib.request.Request(
        url,
        headers=_auth_headers(api_key, bearer=bearer),
        method="GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {detail}") from exc


def _image_data_url(path: Path, *, frame_count: int, frame_index: int) -> str:
    suffix = path.suffix.lower()
    mime = {
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".webp": "image/webp",
    }.get(suffix)
    if not mime:
        raise ValueError(f"Unsupported reference image type: {path}")

    if frame_count > 1:
        image = Image.open(path).convert("RGBA")
        cell_width = image.width // frame_count
        left = cell_width * frame_index
        image = image.crop((left, 0, left + cell_width, image.height))
        buffer = io.BytesIO()
        image.save(buffer, format="PNG")
        raw = buffer.getvalue()
        mime = "image/png"
    else:
        raw = path.read_bytes()

    encoded = base64.b64encode(raw).decode("ascii")
    return f"data:{mime};base64,{encoded}"


def _extract_video_url(result: dict[str, Any]) -> str | None:
    """Handle DMXAPI's nested JSON-in-text response format."""
    direct_url = result.get("video_url") or result.get("meta_data", {}).get("url")
    if direct_url:
        return str(direct_url)

    output = result.get("output")
    if not isinstance(output, list):
        return None
    for item in output:
        for content in item.get("content", []) if isinstance(item, dict) else []:
            text = content.get("text") if isinstance(content, dict) else None
            if not text:
                continue
            try:
                inner = json.loads(text)
            except json.JSONDecodeError:
                continue
            video_url = inner.get("content", {}).get("video_url") or inner.get("video_url")
            if video_url:
                return video_url
    return None


def _extract_status(result: dict[str, Any]) -> str:
    output = result.get("output")
    if isinstance(output, list):
        for item in output:
            for content in item.get("content", []) if isinstance(item, dict) else []:
                text = content.get("text") if isinstance(content, dict) else None
                if not text:
                    continue
                try:
                    inner = json.loads(text)
                except json.JSONDecodeError:
                    continue
                status = inner.get("status")
                if status:
                    return str(status)
    return str(result.get("status") or result.get("id") or "unknown")


def _download(url: str, output: Path, timeout: int) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url, timeout=timeout) as response:
        output.write_bytes(response.read())


def build_prompt(direction: str) -> str:
    if direction != "down":
        raise ValueError("Only down direction is configured for the first trial")
    return (
        "Use the provided reference sprite sheet as the exact character identity. "
        "Generate a short seamless white-background video of this wuxia RPG field "
        "sprite walking in place toward the camera. Fixed camera, orthographic "
        "front view, no zoom, no pan, no rotation, no scene, no shadow, no text. "
        "The head, chest, belt center, sword, and green wine gourd stay stable. "
        "Only the legs, feet, sleeves, and lower robe move subtly. The left and "
        "right feet alternate naturally: left foot contact, right foot passing, "
        "right foot contact, left foot passing, loop back smoothly. Keep the "
        "body center locked; avoid side-to-side sway and avoid big cloak swings. "
        "Plain pure white background suitable for extracting sprite frames."
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate a Seedance video trial")
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
        default=PROJECT_ROOT / "assets/raw/video/seedance_down_walk_trial.mp4",
    )
    parser.add_argument(
        "--meta",
        type=Path,
        default=PROJECT_ROOT / "assets/raw/video/seedance_down_walk_trial.meta.json",
    )
    parser.add_argument("--endpoint", default=None)
    parser.add_argument("--api-mode", choices=["responses", "videos"], default="responses")
    parser.add_argument("--model", default="doubao-seedance-1-5-pro-responses")
    parser.add_argument("--poll-model", default="seedance-get")
    parser.add_argument("--image-role", default="first_frame")
    parser.add_argument("--reference-frame-count", type=int, default=4)
    parser.add_argument("--reference-frame-index", type=int, default=0)
    parser.add_argument("--ratio", default="1:1")
    parser.add_argument("--resolution", default="480p")
    parser.add_argument("--duration", type=int, default=4)
    parser.add_argument("--poll-seconds", type=int, default=10)
    parser.add_argument("--timeout-seconds", type=int, default=420)
    parser.add_argument("--seed", type=int, default=-1)
    return parser.parse_args()


def main() -> int:
    load_dotenv(PROJECT_ROOT / ".env")
    args = parse_args()
    api_key = os.getenv("OPENAI_API_KEY", "").strip()
    if not api_key:
        print("OPENAI_API_KEY is not configured", file=sys.stderr)
        return 2

    reference = args.reference.resolve()
    if not reference.exists():
        print(f"Reference image not found: {reference}", file=sys.stderr)
        return 2

    endpoint = args.endpoint or _endpoint_from_env()
    prompt = build_prompt(args.direction)
    image_url = _image_data_url(
        reference,
        frame_count=args.reference_frame_count,
        frame_index=args.reference_frame_index,
    )
    input_content = [
        {"type": "text", "text": prompt},
        {
            "type": "image_url",
            "image_url": {"url": image_url},
            "role": args.image_role,
        },
    ]
    payload = {
        "model": args.model,
        "ratio": args.ratio,
        "resolution": args.resolution,
        "duration": args.duration,
        "seed": args.seed,
        "watermark": False,
    }
    if args.api_mode == "responses":
        payload.update(
            {
                "input": input_content,
                "callback_url": "",
                "generate_audio": False,
                "camera_fixed": True,
                "return_last_frame": False,
            }
        )
    else:
        payload.update(
            {
                "content": input_content,
                "callback_url": "",
                "camera_fixed": True,
            }
        )

    print(f"Submitting Seedance job to {endpoint}")
    try:
        submit_result = _post_json(endpoint, payload, api_key, timeout=60, bearer=True)
    except RuntimeError as exc:
        # Some DMXAPI docs show raw sk-* auth for submit and Bearer for polling.
        if "HTTP 401" not in str(exc):
            raise
        submit_result = _post_json(endpoint, payload, api_key, timeout=60, bearer=False)

    task_id = submit_result.get("id")
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
        if args.api_mode == "responses":
            poll_payload = {"model": args.poll_model, "input": task_id}
            last_result = _post_json(endpoint, poll_payload, api_key, timeout=60, bearer=True)
        else:
            poll_url = f"{endpoint.rstrip('/')}/{task_id}"
            last_result = _get_json(poll_url, api_key, timeout=60, bearer=True)
        status = _extract_status(last_result)
        print(f"Status: {status}")
        video_url = _extract_video_url(last_result)
        if video_url:
            break
        if status in {"failed", "expired", "cancelled"}:
            break

    meta = {
        "task_id": task_id,
        "endpoint": endpoint,
        "model": args.model,
        "poll_model": args.poll_model,
        "reference": str(reference),
        "reference_frame_count": args.reference_frame_count,
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
    _download(video_url, args.output, timeout=120)
    print(args.output)
    print(args.meta)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
