"""DMXAPI gpt-image-2 渠道存活探测（单次最小调用）

用途：跑批前确认 DMXAPI 上游渠道是否可用，避免 503 浪费时间和重试预算。
退出码：0 = 渠道可用；非 0 = 不可用（503 / 渠道熔断 / 连接失败）。
"""

from __future__ import annotations

import os
import sys

from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY"),
    base_url=os.getenv("OPENAI_BASE_URL"),
    timeout=30.0,
)

try:
    rsp = client.images.generate(
        model="gpt-image-2",
        prompt="a single white circle on plain background",
        size="1024x1024",
        n=1,
    )
    if rsp.data and rsp.data[0].b64_json:
        print(f"OK len={len(rsp.data[0].b64_json)}")
        sys.exit(0)
    print(f"FAIL empty data: {rsp}")
    sys.exit(2)
except Exception as e:
    print(f"FAIL {type(e).__name__}: {e}")
    sys.exit(1)
