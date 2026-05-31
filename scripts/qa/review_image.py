"""
review_image.py — 通用图片分析器

通过 OkRouter Gemini Vision 分析任意游戏资产图片，返回结构化 QA 报告。

用法：
    # 自由描述模式
    python scripts/qa/review_image.py assets/raw/scene_background/scene_kit_building_linxi_v1.png

    # 指定检查项
    python scripts/qa/review_image.py <path> --checks transparency,style,perspective

    # 传自定义 prompt 文件
    python scripts/qa/review_image.py <path> --prompt prompts/qa/atlas_check.txt

    # JSON 输出（给下游脚本消费）
    python scripts/qa/review_image.py <path> --json

输出：终端打印结构化报告 + 可选 JSON 到 stdout。
"""

import argparse
import base64
import io
import json
import os
import sys
from pathlib import Path

import requests
from PIL import Image
from dotenv import load_dotenv

# Load .env from project root
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
load_dotenv(PROJECT_ROOT / ".env")

DEFAULT_API_KEY = os.getenv("OKROUTER_API_KEY", "")
DEFAULT_BASE_URL = os.getenv("OKROUTER_BASE_URL", "https://api.okrouter.com/v1")
DEFAULT_MODEL = os.getenv("OKROUTER_VISION_MODEL", "gemini-3.1-pro-preview-customtools")

MAX_IMAGE_SIDE = 1568
JPEG_QUALITY = 75
API_TIMEOUT = 180


def compress_image(img_path: Path) -> str:
    img = Image.open(img_path).convert("RGB")
    img.thumbnail((MAX_IMAGE_SIDE, MAX_IMAGE_SIDE), Image.LANCZOS)
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=JPEG_QUALITY, optimize=True, progressive=True)
    return base64.b64encode(buf.getvalue()).decode("ascii")


def build_payload(image_b64: str, prompt: str) -> dict:
    return {
        "model": DEFAULT_MODEL,
        "messages": [{
            "role": "user",
            "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{image_b64}"}}
            ]
        }],
        "temperature": 0.2,
        "max_tokens": 2048,
    }


def call_vision(payload: dict) -> dict:
    r = requests.post(
        f"{DEFAULT_BASE_URL}/chat/completions",
        headers={
            "Authorization": f"Bearer {DEFAULT_API_KEY}",
            "Content-Type": "application/json",
        },
        json=payload,
        timeout=API_TIMEOUT,
    )
    r.raise_for_status()
    data = r.json()
    if "error" in data:
        raise RuntimeError(f"API error: {data['error']}")
    return data


def build_prompt_template(image_path: Path, checks: list[str] | None) -> str:
    filename = image_path.name
    header = f"""You are a game art QA reviewer. Analyze the image "{filename}".

Reply in VALID JSON only, with this structure:
{{
  "verdict": "PASS" | "FAIL" | "WARN",
  "summary": "<one sentence overview>",
  "findings": [
    {{"check": "<check name>", "result": "PASS" | "FAIL" | "WARN", "detail": "<brief explanation>"}}
  ]
}}
"""
    if checks:
        items = "\n".join(f"  - {c}" for c in checks)
        header += f"\nCheck these specific aspects:\n{items}\n"
    else:
        header += """
Do a general visual quality check. Consider:
  - Is anything obviously wrong (blurry, garbled, wrong content)?
  - Does the style look coherent?
  - Are there any unwanted artifacts, watermarks, or text?
  - Is the composition reasonable for game art?
"""
    return header


# ----- presets -----

PRESET_ATLAS = """You are a game art QA reviewer analyzing a modular scene element atlas.

This atlas should contain 12-20 independent game sprite elements on a transparent or clean background.
Key requirements:
1. All elements are SEPARATE, non-overlapping, with clear spacing between them
2. NO human characters, NPCs, or animals
3. NO Chinese/English text, labels, numbers, or watermarks
4. Consistent perspective (orthographic slight top-down, ~30 degree)
5. Consistent lighting (upper-right warm light, shadows cast to lower-left)
6. Hong Kong manhua thick-paint style, bold ink lines, vibrant colors
7. Background should be transparent (alpha) or at least clean white for cutting
8. Elements should be recognizable as the intended category (buildings / plants / roads / props)

Forbidden items that would make this FAIL:
- Human figures, faces, animals, creatures
- Any text, letters, numbers, signatures
- Spider webs, spider imagery
- Full scene backgrounds (this should be individual elements, not a complete scene)
- Overlapping or merged-together elements
- Heavy blur, low resolution, pixel art style
- 3D CGI rendering look, photo-realistic textures
- Warm gold/orange dominant colors (should be cool-toned: blue-green-ink)
- Muddy gray desaturated look (should be vibrant)

Reply in VALID JSON only:
{
  "verdict": "PASS" | "FAIL" | "WARN",
  "summary": "<one sentence>",
  "element_count_estimate": <number of separate elements you can count>,
  "violations": ["<list any rule violations found>"],
  "findings": [
    {"check": "element_separation", "result": "PASS"|"FAIL", "detail": "<are elements non-overlapping?>"},
    {"check": "no_characters", "result": "PASS"|"FAIL", "detail": "<any human/creature present?>"},
    {"check": "no_text", "result": "PASS"|"FAIL", "detail": "<any text/numbers/watermarks?>"},
    {"check": "perspective_consistent", "result": "PASS"|"FAIL", "detail": "<consistent angle?>"},
    {"check": "lighting_consistent", "result": "PASS"|"FAIL", "detail": "<same light direction?>"},
    {"check": "style_match", "result": "PASS"|"FAIL", "detail": "<HK manhua thick-paint style?>"},
    {"check": "clean_background", "result": "PASS"|"FAIL", "detail": "<transparent/clean for cutting?>"},
    {"check": "vibrant_colors", "result": "PASS"|"FAIL", "detail": "<bright and saturated, not muddy?>"}
  ]
}
"""


def main():
    parser = argparse.ArgumentParser(
        description="Review game art images via Gemini Vision",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
presets:
  --preset atlas     Use atlas-specific QA checklist (for scene_element atlases)

examples:
  python scripts/qa/review_image.py art.png
  python scripts/qa/review_image.py art.png --preset atlas --json > report.json
  python scripts/qa/review_image.py art.png --checks "Is the style HK manhua?" "Are there any text?"
        """,
    )
    parser.add_argument("image", type=Path, help="Path to image file")
    parser.add_argument("--preset", choices=["atlas"], help="Use a built-in QA preset")
    parser.add_argument("--checks", nargs="*", help="Custom check items")
    parser.add_argument("--prompt", type=Path, help="Custom prompt file")
    parser.add_argument("--json", action="store_true", help="Output raw JSON only")
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"Model ID (default: {DEFAULT_MODEL})")
    args = parser.parse_args()

    if not DEFAULT_API_KEY:
        print("[ERROR] OKROUTER_API_KEY not set in .env", file=sys.stderr)
        sys.exit(1)

    if not args.image.exists():
        print(f"[ERROR] Image not found: {args.image}", file=sys.stderr)
        sys.exit(1)

    model = args.model

    # Build prompt
    if args.prompt:
        prompt_text = Path(args.prompt).read_text(encoding="utf-8")
    elif args.preset == "atlas":
        prompt_text = PRESET_ATLAS
    else:
        prompt_text = build_prompt_template(args.image, args.checks)

    if not args.json:
        print(f"Analyzing: {args.image.name}  ({args.image.stat().st_size / 1024:.0f} KB)")
        print(f"Model: {DEFAULT_MODEL}")
        print("-" * 60)

    try:
        b64 = compress_image(args.image)
        payload = build_payload(b64, prompt_text)
        payload["model"] = model
        response = call_vision(payload)
        content = response["choices"][0]["message"]["content"]
    except Exception as e:
        err = {"verdict": "ERROR", "summary": str(e), "findings": []}
        if args.json:
            print(json.dumps(err, indent=2, ensure_ascii=False))
        else:
            print(f"[FAIL] Vision API error: {e}")
        sys.exit(2)

    # Try to parse JSON from response
    try:
        # Handle markdown-wrapped JSON
        text = content.strip()
        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        report = json.loads(text.strip())
    except json.JSONDecodeError:
        report = {"verdict": "WARN", "summary": content.strip(), "findings": [], "raw_response": True}

    report["_meta"] = {
        "image": str(args.image),
        "model": DEFAULT_MODEL,
        "usage": response.get("usage", {}),
    }

    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        _print_report(report)


def _print_report(report: dict) -> None:
    verdict = report.get("verdict", "?")
    color = {"PASS": "green", "FAIL": "red", "WARN": "yellow", "ERROR": "red"}.get(verdict, "white")
    print(f"Verdict: [{color}] {verdict}")
    print(f"Summary: {report.get('summary', 'N/A')}")

    if "element_count_estimate" in report:
        print(f"Element count (estimated): {report['element_count_estimate']}")

    if report.get("violations"):
        print("\nViolations:")
        for v in report["violations"]:
            print(f"  [red]✗ {v}")

    if report.get("findings"):
        print("\nFindings:")
        for f in report["findings"]:
            icon = {"PASS": "[green]✓", "FAIL": "[red]✗", "WARN": "[yellow]⚠"}.get(f.get("result", ""), "?")
            print(f"  {icon} {f['check']}: {f['detail']}")

    if not report.get("findings") and not report.get("violations") and report.get("raw_response"):
        print(f"\n[Raw response]:\n{report['summary']}")

    usage = report.get("_meta", {}).get("usage", {})
    if usage:
        print(f"\nTokens: {usage.get('total_tokens', '?')} (prompt: {usage.get('prompt_tokens', '?')}, completion: {usage.get('completion_tokens', '?')})")


if __name__ == "__main__":
    main()
