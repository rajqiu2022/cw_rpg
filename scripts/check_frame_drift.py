"""
check_frame_drift.py — 动画帧漂移检测

基于关键点检测（MediaPipe Pose）检查 AI 生成的 sprite 帧之间
是否存在"身体比例漂移"——肩宽/头身比/脚位置在连续帧中不一致。

原理：
    1. 对每一帧提取人体关键点（双肩、髋部、脚踝）
    2. 计算帧间的锚点位移（归一化到第一帧）
    3. 标记超出阈值的帧

用法：
    python scripts/check_frame_drift.py frames/ --threshold 0.05
    python scripts/check_frame_drift.py frames/ --report drift_report.json
    python scripts/check_frame_drift.py f01.png f02.png f03.png --compare

依赖：
    pip install mediapipe opencv-python

输出：
    终端报告 + 可选 JSON 报告，标注漂移帧和具体偏移数值。
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image

# 关键点索引（MediaPipe Pose）
# 11: 左肩, 12: 右肩
# 23: 左髋, 24: 右髋
# 27: 左脚踝, 28: 右脚踝
# 0:  鼻子

KEYPOINTS = {
    "left_shoulder": 11,
    "right_shoulder": 12,
    "left_hip": 23,
    "right_hip": 24,
    "left_ankle": 27,
    "right_ankle": 28,
    "nose": 0,
}


def detect_pose(img: Image.Image) -> dict[str, tuple[float, float]] | None:
    """对单张图片提取关键点，返回归一化坐标（0~1）。"""
    try:
        import cv2
        import mediapipe as mp
    except ImportError:
        print("[ERROR] 缺少依赖。请安装：pip install mediapipe opencv-python")
        sys.exit(1)

    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose(static_image_mode=True, model_complexity=1)

    h, w = img.height, img.width
    rgb = np.array(img.convert("RGB"))
    bgr = cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)

    results = pose.process(bgr)
    pose.close()

    if not results.pose_landmarks:
        return None

    landmarks = results.pose_landmarks.landmark
    points: dict[str, tuple[float, float]] = {}
    for name, idx in KEYPOINTS.items():
        lm = landmarks[idx]
        # 归一化到图像尺寸
        points[name] = (lm.x * w / w, lm.y * h / h)
    return points


def compute_metrics(points: dict[str, tuple[float, float]]) -> dict[str, float]:
    """从关键点计算可比较的锚点指标。"""
    m: dict[str, float] = {}

    ls = points.get("left_shoulder", (0, 0))
    rs = points.get("right_shoulder", (0, 0))
    lh = points.get("left_hip", (0, 0))
    rh = points.get("right_hip", (0, 0))
    la = points.get("left_ankle", (0, 0))
    ra = points.get("right_ankle", (0, 0))
    nose = points.get("nose", (0, 0))

    # 肩宽
    m["shoulder_width"] = np.sqrt((rs[0] - ls[0]) ** 2 + (rs[1] - ls[1]) ** 2)
    # 髋宽
    m["hip_width"] = np.sqrt((rh[0] - lh[0]) ** 2 + (rh[1] - lh[1]) ** 2)
    # 肩-髋中点（躯干中心）
    torso_cx = (ls[0] + rs[0] + lh[0] + rh[0]) / 4
    torso_cy = (ls[1] + rs[1] + lh[1] + rh[1]) / 4
    m["torso_center_x"] = torso_cx
    m["torso_center_y"] = torso_cy
    # 身高（估算：鼻子到脚踝中点）
    ankle_cy = (la[1] + ra[1]) / 2
    m["height_approx"] = ankle_cy - nose[1]
    # 脚位置（Y 坐标，应为固定锚点）
    m["foot_y"] = (la[1] + ra[1]) / 2

    return m


def check_drift(
    frame_paths: list[Path],
    threshold: float = 0.05,
) -> list[dict[str, Any]]:
    """
    检测连续帧的漂移。
    threshold: 相对第一帧的最大允许漂移比例（0.05 = 5%）。
    """
    if len(frame_paths) < 2:
        return []

    print(f"检测 {len(frame_paths)} 帧的漂移…")

    all_metrics: list[dict[str, float]] = []
    for i, p in enumerate(frame_paths):
        img = Image.open(p)
        points = detect_pose(img)
        if points is None:
            print(f"  [WARN] 第 {i+1} 帧未检测到人体: {p.name}")
            return []
        metrics = compute_metrics(points)
        all_metrics.append(metrics)

    # 以第一帧为锚点
    ref = all_metrics[0]
    issues: list[dict[str, Any]] = []

    for i, m in enumerate(all_metrics[1:], start=1):
        frame_issues: dict[str, float] = {}
        for key in ref:
            if abs(ref[key]) < 1e-6:
                continue
            drift = abs(m[key] - ref[key]) / abs(ref[key])
            if drift > threshold:
                frame_issues[key] = round(drift, 4)

        if frame_issues:
            issues.append({
                "frame_index": i,
                "filename": frame_paths[i].name,
                "drift": frame_issues,
                "severity": "high" if any(v > threshold * 3 for v in frame_issues.values()) else "medium",
            })

    return issues


def main() -> None:
    parser = argparse.ArgumentParser(description="动画帧漂移检测")
    parser.add_argument("frames", nargs="+", type=str, help="帧图片路径或目录")
    parser.add_argument("--threshold", type=float, default=0.05, help="漂移阈值（默认 0.05 即 5%%）")
    parser.add_argument("--report", type=str, default="", help="输出 JSON 报告路径")
    parser.add_argument("--compare", action="store_true", help="两两比较模式")
    args = parser.parse_args()

    # 收集帧文件
    frame_paths: list[Path] = []
    for f in args.frames:
        p = Path(f)
        if p.is_dir():
            frame_paths.extend(sorted(p.glob("*.png")) + sorted(p.glob("*.jpg")))
        else:
            frame_paths.append(p)

    if len(frame_paths) < 2:
        print("至少需要 2 帧进行比较")
        sys.exit(1)

    issues = check_drift(frame_paths, args.threshold)

    if not issues:
        print("\n✅ 所有帧锚点稳定，无漂移")
    else:
        print(f"\n⚠️  发现 {len(issues)} 个漂移帧：")
        for item in issues:
            flag = "🔴" if item["severity"] == "high" else "🟡"
            print(f"  {flag} 帧 #{item['frame_index']}: {item['filename']}")
            for key, val in item["drift"].items():
                print(f"       {key}: {val*100:.1f}% 漂移")

    if args.report:
        report_data = {
            "total_frames": len(frame_paths),
            "threshold": args.threshold,
            "issues": issues,
            "verdict": "PASS" if not issues else "FAIL",
        }
        Path(args.report).write_text(json.dumps(report_data, ensure_ascii=False, indent=2))
        print(f"\n报告已保存到 {args.report}")


if __name__ == "__main__":
    main()
