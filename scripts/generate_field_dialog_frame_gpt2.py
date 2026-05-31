from __future__ import annotations

import argparse
import asyncio
import json
import os
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
from dotenv import load_dotenv
from PIL import Image

from gen_assets import _call_alapi_generation, call_image_model, detect_backend


ROOT = Path(__file__).resolve().parent.parent
REFERENCE = ROOT / "assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_field_hud_screen_gpt_v1.png"
RAW_OUT = ROOT / "assets/raw/ui/field_hud/dialog_frame_gpt2_v1.png"
RAW_META = ROOT / "assets/raw/ui/field_hud/dialog_frame_gpt2_v1.meta.json"
GAME_OUT = ROOT / "game/art/ui/field_hud/v2/hud_dialog_frame.png"
PREVIEW_OUT = ROOT / "tools/field_dialog_frame_gpt2_preview.png"


PROMPT = """
Generate one standalone bottom dialog box frame for a Chinese wuxia RPG field HUD.

Use the attached reference screenshot only for style direction: cold blue-black metal, ink-blue translucent glass,
hand-painted Hong Kong wuxia comic UI, worn steel edges, misty cold highlights, subtle ornamental corner caps.

Output requirements:
- one single long horizontal dialog frame only, centered on a plain white background
- no game scene background, no character, no icons, no text, no numbers, no logos
- target shape: very wide bottom conversation box, aspect ratio about 5.7:1
- the frame should have a complete border on all four sides, visible decorated corners, dark semi-transparent interior
- leave a large clean inner area for runtime Chinese text
- left side should have enough blank area for an optional portrait, but no portrait drawn
- color palette: cold black, deep ink blue, cold steel blue, dim cyan edge highlights
- avoid gold, parchment, modern flat UI, sci-fi neon, web dashboard style
- plain white canvas background so the frame can be cut out after generation
""".strip()


def _clean_alpha(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    arr = np.array(rgba)
    rgb = arr[:, :, :3].astype(np.int16)
    white_distance = np.abs(rgb - 255).sum(axis=2)
    max_rgb = rgb.max(axis=2)
    min_rgb = rgb.min(axis=2)
    saturation = max_rgb - min_rgb
    alpha = arr[:, :, 3]
    remove = (white_distance < 110) | ((min_rgb > 176) & (saturation < 72))
    alpha[remove] = 0
    soft = ((white_distance >= 110) & (white_distance < 260)) | ((min_rgb > 130) & (saturation < 92))
    alpha[soft] = np.minimum(alpha[soft], np.clip((white_distance[soft] - 110) * 255 / 150, 0, 255).astype(np.uint8))
    arr[:, :, 3] = alpha
    arr[arr[:, :, 3] <= 2, 0:4] = 0
    return Image.fromarray(arr, "RGBA")


def _fit_to_dialog_canvas(image: Image.Image) -> Image.Image:
    cleaned = _clean_alpha(image)
    bbox = cleaned.getbbox()
    if bbox is None:
        raise RuntimeError("generated dialog frame has empty alpha")
    cropped = cleaned.crop(bbox)
    canvas = Image.new("RGBA", (1600, 280), (0, 0, 0, 0))
    size = (1520, 248)
    resized = cropped.resize(size, Image.Resampling.LANCZOS)
    canvas.alpha_composite(resized, ((1600 - size[0]) // 2, (280 - size[1]) // 2))
    return canvas


def _postprocess_existing() -> None:
    image = Image.open(RAW_OUT).convert("RGBA")
    dialog = _fit_to_dialog_canvas(image)
    GAME_OUT.parent.mkdir(parents=True, exist_ok=True)
    dialog.save(GAME_OUT)
    preview = Image.new("RGBA", (1920, 1080), (18, 27, 34, 255))
    preview.alpha_composite(dialog, (160, 760))
    PREVIEW_OUT.parent.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEW_OUT)
    print(GAME_OUT)
    print(PREVIEW_OUT)


async def _generate(force: bool, postprocess_only: bool) -> None:
    if postprocess_only:
        _postprocess_existing()
        return
    if GAME_OUT.exists() and RAW_OUT.exists() and not force:
        print(f"exists: {GAME_OUT}")
        return

    load_dotenv(ROOT / ".env")
    load_dotenv(ROOT / ".env.local", override=True)
    api_key = os.getenv("OPENAI_API_KEY") or os.getenv("ALAPI_TOKEN")
    base_url = os.getenv("OPENAI_BASE_URL")
    model = os.getenv("OPENAI_IMAGE_MODEL", "gpt-image-2")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY / ALAPI_TOKEN is not configured")

    spec = {
        "prompt": PROMPT,
        "size": "1536x1024",
        "quality": "high",
        "background": "opaque",
        "reference_images": [REFERENCE],
    }

    backend = detect_backend(base_url)
    if backend == "alapi":
        img_bytes, meta = await _call_alapi_generation(api_key, base_url, spec, model)
    else:
        from openai import AsyncOpenAI

        client = AsyncOpenAI(api_key=api_key, base_url=base_url, max_retries=0)
        img_bytes, meta = await call_image_model(client, spec, model, backend)

    RAW_OUT.parent.mkdir(parents=True, exist_ok=True)
    RAW_OUT.write_bytes(img_bytes)
    meta = {
        **meta,
        "prompt": PROMPT,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "raw_output": str(RAW_OUT),
        "game_output": str(GAME_OUT),
    }
    RAW_META.write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8")

    image = Image.open(RAW_OUT).convert("RGBA")
    dialog = _fit_to_dialog_canvas(image)
    GAME_OUT.parent.mkdir(parents=True, exist_ok=True)
    dialog.save(GAME_OUT)

    preview = Image.new("RGBA", (1920, 1080), (18, 27, 34, 255))
    preview.alpha_composite(dialog, (160, 760))
    PREVIEW_OUT.parent.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEW_OUT)
    print(RAW_OUT)
    print(GAME_OUT)
    print(PREVIEW_OUT)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--postprocess-only", action="store_true")
    args = parser.parse_args()
    asyncio.run(_generate(args.force, args.postprocess_only))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
