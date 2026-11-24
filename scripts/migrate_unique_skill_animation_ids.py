#!/usr/bin/env python3
"""Assign every Skill resource its own dedicated battle VFX id."""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL_DIR = ROOT / "game" / "data" / "skills"


def migrate() -> int:
    changed = 0
    skill_ids: set[str] = set()
    for path in sorted(SKILL_DIR.glob("*.tres")):
        source = path.read_text(encoding="utf-8")
        match = re.search(r'(?m)^skill_id\s*=\s*&"([^"]+)"', source)
        if not match:
            raise ValueError(f"missing skill_id: {path}")
        skill_id = match.group(1)
        if skill_id in skill_ids:
            raise ValueError(f"duplicate skill_id: {skill_id}")
        skill_ids.add(skill_id)
        replacement = f'animation_id = &"{skill_id}"'
        updated, count = re.subn(r'(?m)^animation_id\s*=\s*&"[^"]*"', replacement, source, count=1)
        if count != 1:
            raise ValueError(f"missing animation_id field: {path}")
        if updated != source:
            path.write_text(updated, encoding="utf-8", newline="\n")
            changed += 1
    if len(skill_ids) != 42:
        raise ValueError(f"expected 42 skills, got {len(skill_ids)}")
    return changed


if __name__ == "__main__":
    print(f"Updated {migrate()} skill resources with dedicated animation ids")
