"""Audit runtime art references before a production export.

The report distinguishes a loadable texture from a release-ready texture.  A
resource must both exist and have provenance metadata; backups, previews and
full-screen showcase art are explicitly rejected from the release set.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
ART = GAME / "art"
SOURCE_SUFFIXES = {".gd", ".tscn", ".tres"}
ART_REF = re.compile(r"res://art/[A-Za-z0-9_./-]+\.(?:png|webp|jpg|jpeg)")
REJECTED_PARTS = ("_backup", "/preview", "preview_", "_raw", "display_")
SHOWCASE_ART = re.compile(r"res://art/ui/cold_wuxia/|ui_display_art", re.I)


def is_release_candidate(ref: str, source: Path) -> tuple[bool, str]:
    lower = ref.lower()
    if any(part in lower for part in REJECTED_PARTS):
        return False, "backup_or_preview"
    if SHOWCASE_ART.search(ref) or source.name == "ui_display_art.gd":
        return False, "showcase_only"
    return True, ""


def audit() -> dict:
    references: dict[str, set[str]] = {}
    for path in GAME.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in SOURCE_SUFFIXES:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for ref in ART_REF.findall(text):
            references.setdefault(ref, set()).add(path.relative_to(ROOT).as_posix())

    entries: list[dict] = []
    for ref, sources in sorted(references.items()):
        relative = ref.removeprefix("res://")
        file_path = GAME / relative
        metadata_path = file_path.with_suffix(".meta.json")
        source_paths = [ROOT / source for source in sources]
        allowed, reason = is_release_candidate(ref, source_paths[0])
        status = "adopted"
        if not file_path.exists():
            status, reason = "missing", "file_not_found"
        elif not allowed:
            status = "rejected"
        elif not metadata_path.exists():
            status, reason = "candidate", "missing_provenance_metadata"
        else:
            try:
                meta = json.loads(metadata_path.read_text(encoding="utf-8"))
                if meta.get("adopted_status") not in (None, "adopted"):
                    status, reason = "candidate", "metadata_not_adopted"
            except json.JSONDecodeError:
                status, reason = "candidate", "invalid_provenance_metadata"
        entries.append(
            {
                "path": ref,
                "status": status,
                "reason": reason,
                "sources": sorted(sources),
                "bytes": file_path.stat().st_size if file_path.exists() else 0,
            }
        )

    counts = Counter(entry["status"] for entry in entries)
    return {
        "summary": {
            "references": len(entries),
            "adopted": counts["adopted"],
            "candidate": counts["candidate"],
            "missing": counts["missing"],
            "rejected": counts["rejected"],
        },
        "entries": entries,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--out",
        type=Path,
        default=ROOT / "logs" / "release_asset_audit.json",
    )
    args = parser.parse_args()
    report = audit()
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(report["summary"], ensure_ascii=False))
    return 1 if report["summary"]["missing"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
