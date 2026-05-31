"""
qr.py — Quick Review wrapper. 拖文件路径进来，自动调 Gemini 审图。

用法：
    python tools/qr.py tools/企业微信截图_xxx.png
    python tools/qr.py game/art/backgrounds/bg_linxi_main_street_full.png
    python tools/qr.py tools/截图.png "检查这张图有没有建筑和道路"

等价于 review_image.py 的便捷入口。
"""

import subprocess
import sys
from pathlib import Path

REVIEW_SCRIPT = Path(__file__).resolve().parent.parent / "scripts" / "qa" / "review_image.py"

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python tools/qr.py <图片路径> [自定义检查项...]")
        sys.exit(1)

    img = Path(sys.argv[1])
    if not img.exists():
        print(f"[ERROR] 文件不存在: {img}")
        sys.exit(1)

    cmd = [sys.executable, str(REVIEW_SCRIPT), str(img)]
    if len(sys.argv) > 2:
        cmd += ["--checks"] + sys.argv[2:]

    subprocess.run(cmd)
