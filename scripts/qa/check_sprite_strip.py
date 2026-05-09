"""QA: 校验主角行走 sprite strip 的对齐与一致性。

读取一张水平 sprite strip，按白边自动分割角色块，逐格输出：
- 检出格数
- 每格非白边界 (left, top, right, bottom)
- 每格角色高度
- 脚底基线 (即 bottom) 在原图坐标
- 与首格脚底基线的偏差 (px)

输出 PASS / FAIL：
- 检出数 == --expected
- 脚底基线最大偏差 <= --baseline-tolerance
- 角色高度极差 <= --height-tolerance

供 qa agent 在多 Agent 协作流程中执行；不修改源文件。
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))

from build_sprite_preview import _non_white_bbox, _segment_cells_by_columns  # noqa: E402

from PIL import Image  # noqa: E402


def analyze(source: Path, expected: int) -> dict:
    sheet = Image.open(source).convert("RGBA")
    cells = _segment_cells_by_columns(sheet, expected=expected)

    sheet_bg_diff_bbox = _non_white_bbox(sheet)
    cell_reports: list[dict] = []
    baselines: list[int] = []
    heights: list[int] = []

    for index, cell in enumerate(cells):
        bbox = _non_white_bbox(cell)
        if bbox is None:
            cell_reports.append({"index": index, "empty": True})
            continue
        left, top, right, bottom = bbox
        height = bottom - top
        baselines.append(bottom)
        heights.append(height)
        cell_reports.append(
            {
                "index": index,
                "cell_size": cell.size,
                "bbox": [left, top, right, bottom],
                "char_height": height,
                "baseline_y_in_cell": bottom,
            }
        )

    if not baselines:
        return {
            "source": str(source),
            "detected_cells": len(cells),
            "expected": expected,
            "cells": cell_reports,
            "summary": {"status": "FAIL", "reason": "no characters detected"},
            "sheet_bbox": sheet_bg_diff_bbox,
        }

    baseline_min = min(baselines)
    baseline_max = max(baselines)
    height_min = min(heights)
    height_max = max(heights)

    return {
        "source": str(source),
        "detected_cells": len(cells),
        "expected": expected,
        "cells": cell_reports,
        "baseline": {
            "min": baseline_min,
            "max": baseline_max,
            "spread": baseline_max - baseline_min,
        },
        "height": {
            "min": height_min,
            "max": height_max,
            "spread": height_max - height_min,
        },
        "sheet_bbox": sheet_bg_diff_bbox,
    }


def verdict(report: dict, baseline_tol: int, height_tol: int) -> dict:
    detected_ok = report["detected_cells"] == report["expected"]
    baseline_ok = (
        "baseline" in report and report["baseline"]["spread"] <= baseline_tol
    )
    height_ok = "height" in report and report["height"]["spread"] <= height_tol

    status = "PASS" if (detected_ok and baseline_ok and height_ok) else "FAIL"
    return {
        "status": status,
        "detected_ok": detected_ok,
        "baseline_within_tol": baseline_ok,
        "height_within_tol": height_ok,
        "baseline_tol": baseline_tol,
        "height_tol": height_tol,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--expected", type=int, default=8, help="期望分出的角色格数")
    parser.add_argument(
        "--baseline-tolerance",
        type=int,
        default=12,
        help="脚底基线允许的极差 (px)，建议 <= 12",
    )
    parser.add_argument(
        "--height-tolerance",
        type=int,
        default=24,
        help="角色高度允许的极差 (px)，建议 <= 24",
    )
    parser.add_argument(
        "--report",
        type=Path,
        default=None,
        help="可选：把完整报告写到 JSON 文件",
    )
    args = parser.parse_args()

    report = analyze(args.source, args.expected)
    summary = verdict(report, args.baseline_tolerance, args.height_tolerance)
    report["summary"] = summary

    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    print("=== sprite strip QA ===")
    print(f"source           : {report['source']}")
    print(f"detected / expect: {report['detected_cells']} / {report['expected']}")
    if "baseline" in report:
        print(
            "baseline (px)    : min={min} max={max} spread={spread} (tol {tol})".format(
                tol=args.baseline_tolerance, **report["baseline"]
            )
        )
    if "height" in report:
        print(
            "char height (px) : min={min} max={max} spread={spread} (tol {tol})".format(
                tol=args.height_tolerance, **report["height"]
            )
        )
    print(f"status           : {summary['status']}")
    return 0 if summary["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
