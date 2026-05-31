"""调用 Gemini API 分析图片内容"""
from __future__ import annotations

import base64
import json
import sys
from pathlib import Path

import requests

API_URL = "https://cn.okrouter.com/v1/chat/completions"
API_KEY = "sk-pWBhxCCVHIsto9ytse0fMrYiw26Qnnn9z58b1hWuyRTM3Mhb"
MODEL = "gemini-3.1-pro-preview"


def encode_image(path: Path) -> str:
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def analyze(image_path: str, prompt: str) -> str:
    b64 = encode_image(Path(image_path))
    ext = Path(image_path).suffix.lstrip(".").lower()
    mime = f"image/{ext}" if ext in ("png", "jpg", "jpeg", "webp", "gif") else "image/png"

    payload = {
        "model": MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": {"url": f"data:{mime};base64,{b64}"}},
                ],
            }
        ],
        "max_tokens": 4000,
    }

    resp = requests.post(API_URL, headers={
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
    }, json=payload, timeout=120)
    resp.raise_for_status()
    data = resp.json()
    return data["choices"][0]["message"]["content"]


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python analyze_image.py <image_path> [prompt] [--output out.txt]")
        sys.exit(1)

    image_path = sys.argv[1]
    prompt = sys.argv[2] if len(sys.argv) > 2 else "请详细描述这张图片的内容，包括布局、颜色、文字等所有细节。"
    out_path = None
    if "--output" in sys.argv:
        idx = sys.argv.index("--output")
        out_path = sys.argv[idx + 1] if idx + 1 < len(sys.argv) else None

    result = analyze(image_path, prompt)
    if out_path:
        Path(out_path).write_text(result, encoding="utf-8")
        print(f"Written to {out_path}")
    print(result)
