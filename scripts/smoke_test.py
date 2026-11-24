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
import subprocess
import sys
import tempfile
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


def run(cmd: list[str], step: str, env_overrides: dict[str, str] | None = None) -> int:
    print(f"\n=== [{step}] {' '.join(cmd)} ===")
    env = os.environ.copy()
    env.setdefault("OPENAI_API_KEY", "sk-smoke-test-placeholder")
    env["PYTHONIOENCODING"] = "utf-8"
    if env_overrides:
        env.update(env_overrides)
    res = subprocess.run(cmd, cwd=ROOT, env=env)
    if res.returncode != 0:
        print(f"!!! [{step}] FAILED with exit {res.returncode}")
    else:
        print(f"--- [{step}] OK")
    return res.returncode


def main() -> int:
    py = sys.executable
    failures = 0

    failures += run(
        [
            py,
            str(SCRIPTS / "gen_assets.py"),
            "--dry-run",
            "--task",
            "ui_quest_panel_bg_v3",
        ],
        "gen_assets dry-run",
    )

    with tempfile.TemporaryDirectory(prefix="rpg-art-smoke-") as temp_dir:
        empty_raw = Path(temp_dir) / "raw"
        empty_processed = Path(temp_dir) / "processed"
        empty_raw.mkdir()
        empty_processed.mkdir()
        failures += run(
            [py, str(SCRIPTS / "verify.py")],
            "verify (isolated empty dirs)",
            {
                "RAW_DIR": str(empty_raw),
                "PROCESSED_DIR": str(empty_processed),
            },
        )

    failures += run(
        [py, str(SCRIPTS / "postprocess.py"), "--help"],
        "postprocess --help",
    )

    print()
    if failures:
        print(f"[FAIL] {failures} step(s) failed")
        return 1

    print("[PASS] smoke test all green - environment is healthy")
    return 0


if __name__ == "__main__":
    sys.exit(main())
