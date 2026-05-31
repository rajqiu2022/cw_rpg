"""cleanup_artifacts.py — 清理失效链接和废弃产出物"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools" / "agent_hub"))
import db

# ── 废弃路径模式 ──
DEPRECATED_PATTERNS = [
    # v0.1 旧 IP（步惊云/聂风/排云掌/绝世好剑/天下会）
    "bujingyun",
    "niefeng",
    "paiyunzhang",
    "juesihaojian",
    "tianxiahui",
    # 一致性测试（已完成，不再需要）
    "consistency_test/",
    "consist_v",
    "scale_v",
    # sprite v2 旧版（已被 v3 替代，且文件不存在）
    "sprite/v2/",
    # UI v1 旧按钮（已被 v2 替代）
    "ui/field_hud/v1/",
    # 旧 UI 候选（已确认/拒绝的）
    "ui/field_hud/candidates/",
    "ui/field_hud/layers/",
    # 旧版主菜单 keyart v2
    "ui_cold_wuxia_main_menu_keyart_v2",
    "ui_cold_wuxia_main_menu_screen_gpt_v4",
    # dry_run 下的旧 JSON
    "logs/dry_run/",
    # raw 下不存在的旧引用
    "assets/raw/ui/cold_wuxia/v1/",
    # processed 下不存在的旧 sprite
    "assets/processed/sprite/",
    # _archive
    "assets/_archive/",
]


def main():
    conn = db.connect()
    ROOT = db.ROOT

    all_rows = db.rows(conn, "SELECT id, path FROM artifacts")
    to_delete: list[int] = []
    reasons: dict[int, str] = {}

    for r in all_rows:
        rid = int(r["id"])
        path = r["path"]

        # 1. 文件不存在 → 删除
        if not (ROOT / path).exists():
            to_delete.append(rid)
            reasons[rid] = f"file missing: {path}"
            continue

        # 2. 匹配废弃模式
        for pattern in DEPRECATED_PATTERNS:
            if pattern in path:
                to_delete.append(rid)
                reasons[rid] = f"deprecated ({pattern}): {path}"
                break

    print(f"Total artifacts: {len(all_rows)}")
    print(f"To delete: {len(to_delete)}")
    print(f"  - Broken links (file missing): {sum(1 for rid in to_delete if 'file missing' in reasons.get(rid, ''))}")
    print(f"  - Deprecated: {sum(1 for rid in to_delete if 'deprecated' in reasons.get(rid, ''))}")
    print()

    if not to_delete:
        print("Nothing to clean up.")
        conn.close()
        return

    # Show samples
    for rid in to_delete[:20]:
        print(f"  DELETE #{rid}: {reasons[rid]}")
    if len(to_delete) > 20:
        print(f"  ... and {len(to_delete) - 20} more")

    # Execute
    placeholders = ",".join("?" for _ in to_delete)
    conn.execute(f"DELETE FROM artifacts WHERE id IN ({placeholders})", tuple(to_delete))
    conn.commit()

    remaining = db.rows(conn, "SELECT COUNT(1) AS c FROM artifacts")[0]["c"]
    print(f"\nDone. Remaining artifacts: {remaining}")
    conn.close()


if __name__ == "__main__":
    main()
