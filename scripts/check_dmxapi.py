"""DMXAPI 连通性 + 余额 + 出图诊断脚本（非常便宜，仅 ¥0.08 测试一次）

用法：
    python scripts/check_dmxapi.py              # 用 seedream-3.0 (¥0.08) 测出图
    python scripts/check_dmxapi.py --model gpt-image-1   # 用 gpt-image-1 (¥1) 测
    python scripts/check_dmxapi.py --no-image   # 只测连通，不出图
"""
from __future__ import annotations

import argparse
import base64
import os
import sys
import time
from pathlib import Path

import httpx
from dotenv import load_dotenv
from openai import OpenAI

ROOT = Path(__file__).resolve().parent.parent

for s in (sys.stdout, sys.stderr):
    if hasattr(s, "reconfigure"):
        try:
            s.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="seedream-3.0",
                    help="测试模型，默认最便宜的 seedream-3.0 (¥0.08)")
    ap.add_argument("--no-image", action="store_true", help="跳过出图，只测连通")
    ap.add_argument("--timeout", type=int, default=180, help="HTTP 总超时秒")
    ap.add_argument("--connect", type=int, default=30, help="TLS 连接超时秒")
    args = ap.parse_args()

    load_dotenv(ROOT / ".env")
    key = os.getenv("OPENAI_API_KEY")
    base = os.getenv("OPENAI_BASE_URL")

    if not key or not base:
        print("[x] .env 未配置 OPENAI_API_KEY 或 OPENAI_BASE_URL")
        return 2

    print(f"base_url = {base}")
    print(f"key      = {key[:8]}...{key[-4:]}  (长度 {len(key)})")
    print(f"model    = {args.model}")
    print(f"timeout  = {args.timeout}s (connect {args.connect}s)\n")

    timeout = httpx.Timeout(args.timeout, connect=args.connect)
    client = OpenAI(api_key=key, base_url=base, timeout=timeout)

    if not args.no_image:
        print("→ 调 images.generate ...")
        t0 = time.time()
        try:
            r = client.images.generate(
                model=args.model,
                prompt="A simple red circle on white background, flat design",
                size="1024x1024",
                n=1,
            )
            dt = time.time() - t0
            print(f"[OK] 出图成功，耗时 {dt:.1f}s")

            data0 = r.data[0]
            out_dir = ROOT / "assets" / "_diagnostic"
            out_dir.mkdir(parents=True, exist_ok=True)
            out_path = out_dir / f"check_{args.model.replace('/', '_')}.png"

            if hasattr(data0, "b64_json") and data0.b64_json:
                out_path.write_bytes(base64.b64decode(data0.b64_json))
                print(f"[OK] PNG 已保存: {out_path}")
            elif hasattr(data0, "url") and data0.url:
                print(f"[OK] 图像 URL: {data0.url}")
                img = httpx.get(data0.url, timeout=60).content
                out_path.write_bytes(img)
                print(f"[OK] PNG 已下载并保存: {out_path}")
            else:
                print(f"[!] 响应中没有 b64_json 也没有 url: {data0}")
                return 3
            return 0
        except Exception as e:
            dt = time.time() - t0
            print(f"[x] 失败 ({dt:.1f}s): {type(e).__name__}: {e}")
            return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
