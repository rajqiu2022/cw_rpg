from __future__ import annotations

from fastapi.testclient import TestClient

from tools.agent_hub.app import app
from tools.agent_hub.db import connect, init_db, row, rows
from tools.agent_hub.scanner import scan_all


def main() -> int:
    with connect() as conn:
        init_db(conn)
        scan_all(conn)
        checks = {
            "agents": "SELECT COUNT(*) AS count FROM agents",
            "artifacts": "SELECT COUNT(*) AS count FROM artifacts",
            "qa_runs": "SELECT COUNT(*) AS count FROM qa_runs",
            "cost_records": "SELECT COUNT(*) AS count FROM cost_records",
            "tasks": "SELECT COUNT(*) AS count FROM tasks",
            "requirements": "SELECT COUNT(*) AS count FROM requirements",
        }

        results = {name: rows(conn, query)[0]["count"] for name, query in checks.items()}

    print("Agent Hub verification")
    for name, count in results.items():
        print(f"- {name}: {count}")

    required = ("agents", "artifacts", "tasks", "requirements", "qa_runs", "cost_records")

    missing = [name for name in required if results[name] <= 0]
    if missing:
        print(f"Missing required data: {', '.join(missing)}")
        return 1
    with connect() as conn:
        qa_ok = rows(conn, "SELECT COUNT(*) AS count FROM qa_runs WHERE status IN ('PASS', 'FAIL')")[0]["count"]
        cost_ok = rows(conn, "SELECT COUNT(*) AS count FROM cost_records WHERE task_id != ''")[0]["count"]
    if qa_ok <= 0 or cost_ok <= 0:
        print("Parsed QA or cost records are missing required fields")
        return 1

    client = TestClient(app)
    preview = client.get("/repo/docs/system-technical-design-v0.1.md")
    handoff_preview = client.get("/repo/docs/system-handoff-2026-05-04.md")
    raw = client.get("/repo/docs/system-technical-design-v0.1.md?raw=1")
    agent_page = client.get("/agents/system")
    requirements_page = client.get("/requirements")
    if preview.status_code != 200 or "markdown-preview" not in preview.text:

        print("Markdown preview route did not render the preview page")
        return 1
    if handoff_preview.status_code != 200 or "System Handoff - 2026-05-04" not in handoff_preview.text:
        print("System handoff document did not render through markdown preview")
        return 1
    if raw.status_code != 200 or "markdown-preview" in raw.text:
        print("Markdown raw route did not return source content")
        return 1
    if agent_page.status_code != 200 or "角色记忆预览" not in agent_page.text or "markdown-preview" not in agent_page.text:
        print("Agent detail page did not embed markdown memory preview")
        return 1
    if "重要文档" not in agent_page.text or "docs/system-technical-design-v0.1.md" not in agent_page.text:
        print("Agent detail page did not surface important system design docs")
        return 1
    if "重要文档预览" not in agent_page.text or "Godot 系统技术设计稿 v0.1" not in agent_page.text:
        print("Agent detail page did not embed important document content")
        return 1
    if "docs/system-handoff-2026-05-04.md" not in agent_page.text:
        print("Agent detail page did not surface the latest system handoff doc")
        return 1
    if requirements_page.status_code != 200 or "需求列表" not in requirements_page.text or "角色成长系统" not in requirements_page.text:
        print("Requirements page did not render seeded module requirements")
        return 1
    if "confirmOk.addEventListener" not in client.get("/artifacts").text:
        print("Artifacts page did not render adoption controls script")
        return 1
    with connect() as conn:
        candidate = row(
            conn,
            "SELECT id FROM artifacts WHERE adopted_status = 'candidate' AND category = 'unknown' LIMIT 1",
        )
    if candidate:
        artifact_id = int(candidate["id"])
        adopted = client.post(f"/api/artifacts/{artifact_id}/adopt")
        if adopted.status_code != 200:
            print("Artifact adopt API failed")
            return 1
        with connect() as conn:
            scan_all(conn)
            status = row(conn, "SELECT adopted_status FROM artifacts WHERE id = ?", (artifact_id,))
        if not status or status["adopted_status"] != "adopted":
            print("Artifact adopted status did not persist across scan")
            return 1
        reset = client.post(f"/api/artifacts/{artifact_id}/reset")
        if reset.status_code != 200:
            print("Artifact reset API failed")
            return 1
    return 0



if __name__ == "__main__":
    raise SystemExit(main())
