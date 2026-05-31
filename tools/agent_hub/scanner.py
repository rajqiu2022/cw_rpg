from __future__ import annotations

import json
import re
import sqlite3
from datetime import datetime
from pathlib import Path
from typing import Any

import yaml

# Compatible with both `from .db import` (as package) and `import db` (direct)
try:
    from .db import ROOT, rel
except ImportError:
    from db import ROOT, rel


ROLE_NAMES = {
    "producer": "主控 / 制作人",
    "lore": "剧情 / 世界观",
    "system": "Godot 系统",
    "battle": "战斗 / 数值",
    "art": "美术管线",
    "qa": "测试 / QA",
    "review": "代码审查",
}


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def _mtime(path: Path) -> str:
    return datetime.fromtimestamp(path.stat().st_mtime).isoformat(timespec="seconds")


def _extract_scope(text: str) -> str:
    for line in text.splitlines():
        if line.startswith("> Scope:"):
            return line.replace("> Scope:", "", 1).strip()
    return ""


def _extract_section(text: str, heading: str, max_chars: int = 500) -> str:
    pattern = re.compile(rf"^## {re.escape(heading)}\s*$", re.MULTILINE)
    match = pattern.search(text)
    if not match:
        return ""
    start = match.end()
    next_heading = re.search(r"^## ", text[start:], re.MULTILINE)
    end = start + next_heading.start() if next_heading else len(text)
    return text[start:end].strip()[:max_chars]


def scan_agents(conn: sqlite3.Connection) -> None:
    agents_dir = ROOT / "docs" / "agents"
    for path in sorted(agents_dir.glob("*-memory.md")):
        role = path.stem.replace("-memory", "")
        text = _read_text(path)
        conn.execute(
            """
            INSERT INTO agents (id, name, memory_path, scope, owner_summary, updated_at)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
              name=excluded.name,
              memory_path=excluded.memory_path,
              scope=excluded.scope,
              owner_summary=excluded.owner_summary,
              updated_at=excluded.updated_at
            """,
            (
                role,
                ROLE_NAMES.get(role, role),
                rel(path),
                _extract_scope(text),
                _extract_section(text, "Current Project State")
                or _extract_section(text, "Current Sprite Direction")
                or _extract_section(text, "Architecture Snapshot")
                or _extract_section(text, "Responsibilities"),
                _mtime(path),
            ),
        )
    conn.commit()


def _owner_for_path(path: str) -> str:
    normalized = path.replace("\\", "/")
    if normalized.startswith("docs/agents/"):
        filename = Path(normalized).name
        return filename.replace("-memory.md", "") if filename.endswith("-memory.md") else "producer"
    if normalized.startswith("game/scripts/battle") or normalized.startswith("game/data/skills") or normalized.startswith("game/data/enemies"):
        return "battle"
    if normalized.startswith("game/"):
        if normalized.startswith("game/data/dialogs") or normalized.startswith("game/data/quests"):
            return "lore"
        return "system"
    if normalized.startswith("docs/system-"):
        return "system"
    if normalized.startswith(("prompts/", "assets/", "docs/sprite", "docs/style", "docs/art", "tools/")):
        return "art"
    if normalized.startswith(("logs/qa", "game/tests", "docs/mvp-")):
        return "qa"
    if normalized.startswith("docs/"):
        return "producer"
    return "producer"


def _kind_for_path(path: Path) -> str:
    suffix = path.suffix.lower()
    normalized = rel(path)
    if normalized.endswith(".meta.json"):
        return "meta"
    if suffix in {".png", ".gif", ".webp", ".jpg", ".jpeg"}:
        return "image"
    if suffix == ".json":
        return "json"
    if suffix == ".yaml":
        return "yaml"
    if suffix == ".md":
        return "doc"
    if suffix in {".gd", ".tscn", ".tres"}:
        return "godot"
    return suffix.lstrip(".") or "file"


def _category_for_asset(path: Path) -> str:
    """根据路径判断资产类别，用于 artifacts 表的 category 字段。"""
    normalized = rel(path).lower()
    # adopted/ 下的资产 = 已采用
    if "/adopted/" in normalized:
        for key in ["ui_button", "ui_dialog", "ui_icon", "ui_frame",
                    "scene_background", "character_portrait", "sprite_sheet", "audio"]:
            if key in normalized:
                return key
        return "unknown"
    # library/ 或 raw/ 下的资产
    for key in ["ui_button", "ui_dialog", "ui_icon", "ui_frame",
                "scene_background", "character_portrait", "sprite_sheet", "audio"]:
        if key in normalized:
            return key
    # assets/processed/ 子目录映射
    if "assets/processed" in normalized:
        if "scene" in normalized or "background" in normalized:
            return "scene_background"
        if "character" in normalized or "portrait" in normalized or "avatar" in normalized:
            return "character_portrait"
        if "sprite" in normalized:
            return "sprite_sheet"
        if "icon" in normalized:
            return "ui_icon"
        if "ui" in normalized or "field_hud" in normalized or "hud" in normalized:
            return "ui_frame"
        if "audio" in normalized:
            return "audio"
        if "button" in normalized or "btn" in normalized:
            return "ui_button"
        if "dialog" in normalized:
            return "ui_dialog"
        return "unknown"
    # game/art/ 子目录映射
    if "game/art" in normalized:
        if "background" in normalized:
            return "scene_background"
        if "character" in normalized:
            return "character_portrait"
        if "sprite" in normalized:
            return "sprite_sheet"
        if "icon" in normalized:
            return "ui_icon"
        if "ui" in normalized:
            return "ui_frame"
        if "audio" in normalized:
            return "audio"
    return "unknown"


def _adopted_status_for_path(path: Path) -> str:
    """根据路径判断资产的采用状态。"""
    normalized = rel(path).lower()
    if "/adopted/" in normalized:
        return "adopted"
    if "/processed/" in normalized:
        return "adopted"
    if "/library/" in normalized:
        return "candidate"
    # raw/ 或 game/art/ 中的文件默认是候选
    return "candidate"


def scan_artifacts(conn: sqlite3.Connection) -> None:
    patterns = [
        "docs/**/*.md",
        "docs/**/*.yaml",
        "prompts/**/*.yaml",

        "assets/raw/**/*",
        "assets/processed/**/*",
        "assets/library/**/*",
        "assets/adopted/**/*",
        "assets/previews/**/*",
        "assets/_style_bible/**/*",
        "assets/_archive/**/*",
        "game/art/**/*",
        "tools/**/*",
        "logs/qa/*.json",
        "logs/dry_run/*.json",
        "game/tests/**/*.gd",
    ]
    seen: set[str] = set()
    for pattern in patterns:
        for path in ROOT.glob(pattern):
            if not path.is_file():
                continue
            relative = rel(path)
            if relative in seen:
                continue
            
            # 排除 agent_hub 自身运行时文件
            if "tools/agent_hub/" in relative:
                continue
            # 排除 Python 脚本、数据库、pycache、Godot import 元数据
            if relative.endswith((".py", ".sqlite3", ".pyc", ".db", ".import")):
                continue
            
            seen.add(relative)
            category = _category_for_asset(path)
            adopted = _adopted_status_for_path(path)
            conn.execute(
                """
                INSERT INTO artifacts (path, kind, category, adopted_status, owner_agent, summary, status, mtime)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(path) DO UPDATE SET
                  kind=excluded.kind,
                  category=excluded.category,
                  adopted_status=artifacts.adopted_status,
                  owner_agent=excluded.owner_agent,
                  mtime=excluded.mtime
                """,
                (
                    relative,
                    _kind_for_path(path),
                    category,
                    adopted,
                    _owner_for_path(relative),
                    "",
                    "" if adopted != "adopted" else "adopted",
                    _mtime(path),
                ),
            )
    conn.commit()


def scan_qa_runs(conn: sqlite3.Connection) -> None:
    for path in sorted((ROOT / "logs" / "qa").glob("*.json")):
        try:
            data = json.loads(_read_text(path))
        except Exception:
            continue
        summary = data.get("summary", {}) or {}
        baseline = data.get("baseline", {}) or {}
        height = data.get("height", {}) or {}
        conn.execute(
            """
            INSERT INTO qa_runs (
              report_path, source_path, status, detected_cells, expected_cells,
              baseline_spread, height_spread, mtime
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(report_path) DO UPDATE SET
              source_path=excluded.source_path,
              status=excluded.status,
              detected_cells=excluded.detected_cells,
              expected_cells=excluded.expected_cells,
              baseline_spread=excluded.baseline_spread,
              height_spread=excluded.height_spread,
              mtime=excluded.mtime
            """,
            (
                rel(path),
                str(data.get("source", "")),
                summary.get("status", ""),
                data.get("detected_cells"),
                data.get("expected"),
                baseline.get("spread"),
                height.get("spread"),
                _mtime(path),
            ),
        )
    conn.commit()


def _meta_value(data: dict[str, Any], key: str, default: Any = "") -> Any:
    if key in data:
        return data.get(key, default)
    payload = data.get("payload", {}) or {}
    if key in payload:
        return payload.get(key, default)
    spec = data.get("spec", {}) or {}
    return spec.get(key, default)


def scan_cost_records(conn: sqlite3.Connection) -> None:
    for base in (ROOT / "assets" / "raw", ROOT / "logs" / "dry_run"):
        if not base.exists():
            continue
        for path in sorted(base.glob("**/*.meta.json")):
            try:
                data = json.loads(_read_text(path))
            except Exception:
                continue
            conn.execute(
                """
                INSERT INTO cost_records (meta_path, task_id, model, cost, currency, dry_run, size, quality, mtime)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(meta_path) DO UPDATE SET
                  task_id=excluded.task_id,
                  model=excluded.model,
                  cost=excluded.cost,
                  currency=excluded.currency,
                  dry_run=excluded.dry_run,
                  size=excluded.size,
                  quality=excluded.quality,
                  mtime=excluded.mtime
                """,
                (
                    rel(path),
                    str(data.get("id") or data.get("task_id") or ""),
                    str(_meta_value(data, "model", "")),
                    float(data.get("cost") or data.get("cost_estimate") or 0),
                    str(data.get("currency") or ""),
                    1 if data.get("dry_run") else 0,
                    str(_meta_value(data, "size", "")),
                    str(_meta_value(data, "quality", "")),
                    _mtime(path),
                ),
            )
    conn.commit()


def import_requirements(conn: sqlite3.Connection) -> None:
    req_path = ROOT / "docs" / "requirements.yaml"
    if not req_path.exists():
        return
    data = yaml.safe_load(_read_text(req_path)) or {}
    modules = data.get("modules", []) if isinstance(data, dict) else []
    for module in modules:
        if not isinstance(module, dict):
            continue
        module_id = str(module.get("id", ""))
        module_title = str(module.get("title", module_id))
        for submodule in module.get("submodules", []) or []:
            if not isinstance(submodule, dict):
                continue
            submodule_id = str(submodule.get("id", ""))
            submodule_title = str(submodule.get("title", submodule_id))
            for item in submodule.get("requirements", []) or []:
                if not isinstance(item, dict) or not item.get("id"):
                    continue
                conn.execute(
                    """
                    INSERT INTO requirements (
                      id, module_id, module_title, submodule_id, submodule_title,
                      title, description, status, phase, priority, owner_agent,
                      acceptance, links, source_path
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(id) DO UPDATE SET
                      module_id=excluded.module_id,
                      module_title=excluded.module_title,
                      submodule_id=excluded.submodule_id,
                      submodule_title=excluded.submodule_title,
                      title=excluded.title,
                      description=excluded.description,
                      phase=excluded.phase,
                      priority=excluded.priority,
                      owner_agent=excluded.owner_agent,
                      acceptance=excluded.acceptance,
                      links=excluded.links,
                      source_path=excluded.source_path,
                      updated_at=CURRENT_TIMESTAMP
                    """,
                    (
                        str(item["id"]),
                        module_id,
                        module_title,
                        submodule_id,
                        submodule_title,
                        str(item.get("title", item["id"])),
                        str(item.get("description", "")),
                        str(item.get("status", "planned")),
                        str(item.get("phase", "功能设计")),
                        int(item.get("priority") or 2),
                        str(item.get("owner_agent", "producer")),
                        str(item.get("acceptance", "")),
                        str(item.get("links", "")),
                        "docs/requirements.yaml",
                    ),
                )
    conn.commit()


def import_prompt_tasks(conn: sqlite3.Connection) -> None:

    tasks_path = ROOT / "prompts" / "tasks.yaml"
    if not tasks_path.exists():
        return
    data = yaml.safe_load(_read_text(tasks_path)) or {}
    prompt_tasks = data.get("tasks", []) if isinstance(data, dict) else []
    for item in prompt_tasks:
        if not isinstance(item, dict) or not item.get("id"):
            continue
        task_id = f"asset:{item['id']}"
        exists = conn.execute("SELECT 1 FROM tasks WHERE title = ?", (task_id,)).fetchone()
        if exists:
            continue
        conn.execute(
            """
            INSERT INTO tasks (title, goal, owner_agent, status, priority, milestone, context_files, acceptance, constraints)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                task_id,
                f"Asset generation task using template `{item.get('template', '')}`.",
                "art",
                "planned" if not item.get("skip") else "blocked",
                int(item.get("priority") or 2),
                str(item.get("category", "")),
                f"prompts/tasks.yaml\nprompts/templates/{item.get('template', '')}.yaml",
                "Dry-run passes\nGenerated asset has matching meta\nQA/checklist passes before system handoff",
                "Do not batch paid generation before dry-run",
            ),
        )
    conn.commit()


def scan_all(conn: sqlite3.Connection) -> None:
    scan_agents(conn)
    scan_artifacts(conn)
    scan_qa_runs(conn)
    scan_cost_records(conn)
    import_requirements(conn)
    import_prompt_tasks(conn)

