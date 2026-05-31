"""
review_module_atlas.py — 场景元素模块 atlas 专用审核

基于 docs/scene-element-kit-spec.md 对 4 类 atlas 做逐项 QA。
内部调用 review_image.py 的 atlas preset，增加元素数量校验和命名对齐。

用法：
    python scripts/qa/review_module_atlas.py assets/raw/scene_background/scene_kit_building_linxi_v1.png
    python scripts/qa/review_module_atlas.py <path> --category building --expected-count 15
    python scripts/qa/review_module_atlas.py <path> --json > report.json
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
REVIEW_IMAGE = SCRIPT_DIR / "review_image.py"

CATEGORY_NAMES = {
    "ground_road": "ground / road",
    "building": "building",
    "veg": "plant / vegetation",
    "prop": "interactable prop / decoration",
}


def main():
    parser = argparse.ArgumentParser(description="QA a scene element atlas image via Gemini Vision")
    parser.add_argument("image", type=Path, help="Path to atlas PNG")
    parser.add_argument("--category", choices=list(CATEGORY_NAMES), help="Expected element category")
    parser.add_argument("--expected-count", type=int, default=12, help="Minimum expected element count (default: 12)")
    parser.add_argument("--json", action="store_true", help="Output raw JSON")
    args = parser.parse_args()

    if not args.image.exists():
        print(f"[ERROR] Image not found: {args.image}", file=sys.stderr)
        sys.exit(1)

    # Run the core vision review
    cmd = [sys.executable, str(REVIEW_IMAGE), str(args.image), "--preset", "atlas", "--json"]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)

    if result.returncode != 0:
        print(f"[ERROR] review_image.py failed:\n{result.stderr}", file=sys.stderr)
        sys.exit(result.returncode)

    try:
        report = json.loads(result.stdout)
    except json.JSONDecodeError:
        print(f"[ERROR] Failed to parse review_image.py output:\n{result.stdout[:500]}", file=sys.stderr)
        sys.exit(1)

    # Post-process: add category-specific checks
    if args.category:
        cat_name = CATEGORY_NAMES.get(args.category, args.category)
        report["_meta"]["expected_category"] = cat_name
        report["_meta"]["expected_min_elements"] = args.expected_count

    # Element count check
    estimated = report.get("element_count_estimate", 0)
    if estimated > 0 and estimated < args.expected_count:
        report["findings"].append({
            "check": "element_count",
            "result": "WARN",
            "detail": f"Estimated {estimated} elements, expected >= {args.expected_count}",
        })
    elif estimated > 0:
        report["findings"].append({
            "check": "element_count",
            "result": "PASS",
            "detail": f"Estimated {estimated} elements (expected >= {args.expected_count})",
        })

    # Category relevance check
    if args.category:
        cat_keywords = {
            "ground_road": ["road", "path", "ground", "dirt", "stone", "gravel", "grass edge"],
            "building": ["building", "house", "wall", "roof", "door", "window", "column", "eave"],
            "veg": ["plant", "bamboo", "tree", "bush", "grass", "leaf", "flower", "foliage"],
            "prop": ["prop", "barrel", "box", "lantern", "sign", "stone", "tablet", "weapon", "wall crack", "rubble", "cart"],
        }
        keywords = cat_keywords.get(args.category, [])
        summary_lower = report.get("summary", "").lower()
        matched = [kw for kw in keywords if kw in summary_lower]
        if not matched:
            report["findings"].append({
                "check": "category_match",
                "result": "WARN",
                "detail": f"Summary doesn't mention expected category '{cat_name}'. Make sure elements match.",
            })

    # Recalculate verdict
    all_results = [f["result"] for f in report.get("findings", [])]
    if "FAIL" in all_results:
        report["verdict"] = "FAIL"
    elif "WARN" in all_results:
        report["verdict"] = "WARN"
    elif not all_results:
        pass  # keep original
    else:
        report["verdict"] = "PASS"

    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        _print_atlas_report(report, args)


def _print_atlas_report(report: dict, args: argparse.Namespace) -> None:
    verdict = report.get("verdict", "?")
    print(f"\n{'='*60}")
    print(f"  Atlas QA: {Path(report['_meta']['image']).name}")
    print(f"  Verdict: {verdict}")
    if args.category:
        print(f"  Category: {CATEGORY_NAMES.get(args.category, args.category)}")
    print(f"  Elements (est): {report.get('element_count_estimate', '?')} / min {args.expected_count}")
    print(f"{'='*60}")

    for f in report.get("findings", []):
        icon = {"PASS": "[OK]", "FAIL": "[FAIL]", "WARN": "[WARN]"}.get(f.get("result", ""), "[?]")
        print(f"  {icon} {f['check']}: {f['detail']}")

    violations = report.get("violations", [])
    if violations:
        print(f"\n  VIOLATIONS:")
        for v in violations:
            print(f"    - {v}")

    usage = report.get("_meta", {}).get("usage", {})
    if usage:
        print(f"\n  Tokens: {usage.get('total_tokens', '?')}")


if __name__ == "__main__":
    main()
