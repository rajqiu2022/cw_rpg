"""Smoke test: 在没有 OPENAI_API_KEY 的情况下验证整条流水线骨架可跑通。

会依次：
  1. gen_assets.py --dry-run  (验证 prompt 渲染 + 任务加载)
  2. verify.py                (验证 verifier 能跑且不崩)
  3. postprocess.py --help    (验证 postprocess 能加载)

整个过程不调用任何外部 API，不烧钱，不需要网络。
通过 = 你的 Python 环境与项目结构是健康的。

用法：
    python scripts/smoke_test.py
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "scripts"
RAW = ROOT / "assets" / "raw"

# Force UTF-8 console on Windows
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass


def run(cmd: list[str], step: str) -> int:
    print(f"\n=== [{step}] {' '.join(cmd)} ===")
    env = os.environ.copy()
    env.setdefault("OPENAI_API_KEY", "sk-smoke-test-placeholder")
    env["PYTHONIOENCODING"] = "utf-8"
    res = subprocess.run(cmd, cwd=ROOT, env=env)
    if res.returncode != 0:
        print(f"!!! [{step}] FAILED with exit {res.returncode}")
    else:
        print(f"--- [{step}] OK")
    return res.returncode


def main() -> int:
    if RAW.exists() and any(RAW.iterdir()):
        print(f"清理旧的 dry-run 产物: {RAW}")
        for child in RAW.iterdir():
            if child.is_dir():
                shutil.rmtree(child)
            else:
                child.unlink()

    py = sys.executable
    failures = 0

    failures += run(
        [py, str(SCRIPTS / "gen_assets.py"), "--dry-run", "--priority", "1"],
        "gen_assets dry-run",
    )

    failures += run(
        [py, str(SCRIPTS / "verify.py")],
        "verify (empty)",
    )

    failures += run(
        [py, str(SCRIPTS / "postprocess.py"), "--help"],
        "postprocess --help",
    )

    print()
    if failures:
        print(f"[FAIL] {failures} step(s) failed")
        return 1

    if RAW.exists():
        meta_files = list(RAW.rglob("*.meta.json"))
        print(f"[OK] dry-run produced {len(meta_files)} meta file(s) under assets/raw/")
        for child in RAW.iterdir():
            if child.is_dir():
                shutil.rmtree(child)
            else:
                child.unlink()
        print(f"[OK] cleaned up dry-run artifacts")

    print("[PASS] smoke test all green - environment is healthy")
    return 0


if __name__ == "__main__":
    sys.exit(main())
