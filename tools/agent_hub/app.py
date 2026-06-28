from __future__ import annotations

import html
import re
import shutil
from pathlib import Path
from urllib.parse import urlencode
from uuid import uuid4


from fastapi import FastAPI, Form, HTTPException, Request
from fastapi.responses import FileResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from .db import ROOT, connect, init_db, row, rows
from .scanner import ROLE_NAMES, scan_all
from .story_data import CHAPTERS, CHARACTERS, ENDINGS, FACTIONS, STORY_OVERVIEW

try:
    import markdown
except ImportError:  # pragma: no cover - optional dependency fallback
    markdown = None


APP_DIR = Path(__file__).resolve().parent

app = FastAPI(title="RPG_GAME Agent Hub")
app.mount("/static", StaticFiles(directory=APP_DIR / "static"), name="static")
templates = Jinja2Templates(directory=APP_DIR / "templates")
templates.env.auto_reload = True


STATUS_LABELS = {
    "planned": "待规划",
    "in_progress": "进行中",
    "qa": "测试中",
    "review": "审查中",
    "blocked": "阻塞",
    "done": "完成",
    "cancelled": "取消",
    "draft": "草稿",
    "design": "功能设计",
    "art": "美术 UI",
    "implement": "程序实现",

    "PASS": "通过",
    "FAIL": "失败",
}

KIND_LABELS = {
    "doc": "文档",
    "godot": "Godot 数据/脚本",
    "image": "图片/GIF",
    "json": "JSON",
    "meta": "元数据",
    "yaml": "YAML",
}

CATEGORY_LABELS = {
    "ui_button": "按钮",
    "ui_dialog": "对话框",
    "ui_icon": "图标",
    "ui_frame": "框架",
    "scene_background": "场景背景",
    "character_portrait": "角色立绘",
    "sprite_sheet": "精灵图",
    "audio": "音频",
    "unknown": "未分类",
}

ADOPTED_STATUS_LABELS = {
    "adopted": "已采用",
    "candidate": "候选",
    "rejected": "已淘汰",
}


def status_label(value: str | None) -> str:
    return STATUS_LABELS.get(value or "", value or "未设置")


def agent_label(value: str | None) -> str:
    if not value:
        return "未分配"
    role_name = ROLE_NAMES.get(value, value)
    return f"{role_name}（{value}）"


def kind_label(value: str | None) -> str:
    return KIND_LABELS.get(value or "", value or "文件")


def yes_no(value: object) -> str:
    return "是" if value else "否"


templates.env.filters["status_label"] = status_label
templates.env.filters["agent_label"] = agent_label
templates.env.filters["kind_label"] = kind_label
templates.env.filters["category_label"] = lambda v: CATEGORY_LABELS.get(v or "", v or "未分类")
templates.env.filters["adopted_status_label"] = lambda v: ADOPTED_STATUS_LABELS.get(v or "", v or "")
templates.env.filters["yes_no"] = yes_no


def _db():
    conn = connect()
    init_db(conn)
    return conn


def _refresh_index(conn) -> None:
    scan_all(conn)


@app.on_event("startup")
def startup() -> None:
    with _db() as conn:
        _refresh_index(conn)


def _redirect(path: str) -> RedirectResponse:
    return RedirectResponse(path, status_code=303)


def _slug(value: str) -> str:
    slug = re.sub(r"[^0-9A-Za-z\u4e00-\u9fff]+", "-", value.strip()).strip("-")
    return slug or "module"


def _proof_complete(summary: str, links: str) -> bool:
    return bool(summary.strip()) and bool(links.strip())


def _redirect_with_feedback(path: str, *, error: str = "", success: str = "") -> RedirectResponse:
    params = {}
    if error:
        params["error"] = error
    if success:
        params["success"] = success
    if params:
        return _redirect(path + "?" + urlencode(params))
    return _redirect(path)


def _render_markdown(text: str) -> str:


    if markdown is not None:
        return markdown.markdown(
            text,
            extensions=["extra", "sane_lists", "toc"],
            output_format="html5",
        )

    escaped = html.escape(text)
    escaped = re.sub(r"^### (.+)$", r"<h3>\1</h3>", escaped, flags=re.MULTILINE)
    escaped = re.sub(r"^## (.+)$", r"<h2>\1</h2>", escaped, flags=re.MULTILINE)
    escaped = re.sub(r"^# (.+)$", r"<h1>\1</h1>", escaped, flags=re.MULTILINE)
    return "<pre>" + escaped + "</pre>"


@app.get("/")
def dashboard(request: Request):
    with _db() as conn:
        _refresh_index(conn)
        agent_rows = rows(conn, "SELECT * FROM agents ORDER BY id")
        requirement_counts = rows(conn, "SELECT status, COUNT(*) AS count FROM requirements GROUP BY status ORDER BY status")
        active_requirements = rows(
            conn,
            """
            SELECT * FROM requirements
            WHERE status NOT IN ('done', 'cancelled')
            ORDER BY priority ASC, updated_at DESC
            LIMIT 12
            """,
        )

        qa_recent = rows(conn, "SELECT * FROM qa_runs ORDER BY mtime DESC LIMIT 6")
        cost_summary = rows(
            conn,
            """
            SELECT COALESCE(NULLIF(currency, ''), 'UNKNOWN') AS currency,
                   COUNT(*) AS records,
                   SUM(CASE WHEN dry_run = 0 THEN cost ELSE 0 END) AS paid_cost
            FROM cost_records
            GROUP BY COALESCE(NULLIF(currency, ''), 'UNKNOWN')
            ORDER BY currency
            """,
        )
        artifact_counts = rows(conn, "SELECT owner_agent, COUNT(*) AS count FROM artifacts GROUP BY owner_agent ORDER BY owner_agent")
    return templates.TemplateResponse(
        request,
        "dashboard.html",
        {
            "request": request,
            "agents": agent_rows,
            "requirement_counts": requirement_counts,
            "active_requirements": active_requirements,

            "qa_recent": qa_recent,
            "cost_summary": cost_summary,
            "artifact_counts": artifact_counts,
        },
    )


@app.post("/scan")
def rescan():
    with _db() as conn:
        _refresh_index(conn)
    return _redirect("/")


@app.get("/story")
def story(request: Request):
    return templates.TemplateResponse(
        request,
        "story.html",
        {
            "request": request,
            "overview": STORY_OVERVIEW,
            "characters": CHARACTERS,
            "factions": FACTIONS,
            "chapters": CHAPTERS,
            "endings": ENDINGS,
        },
    )


@app.get("/agents")
def agents(request: Request):
    with _db() as conn:
        agent_rows = rows(conn, "SELECT * FROM agents ORDER BY id")
    return templates.TemplateResponse(request, "agents.html", {"agents": agent_rows})


@app.get("/agents/{agent_id}")
def agent_detail(request: Request, agent_id: str):
    with _db() as conn:
        agent = row(conn, "SELECT * FROM agents WHERE id = ?", (agent_id,))
        if not agent:
            raise HTTPException(status_code=404, detail="agent not found")
        tasks = rows(conn, "SELECT * FROM tasks WHERE owner_agent = ? ORDER BY updated_at DESC LIMIT 20", (agent_id,))
        artifacts = rows(conn, "SELECT * FROM artifacts WHERE owner_agent = ? ORDER BY mtime DESC LIMIT 80", (agent_id,))
        doc_artifacts = rows(
            conn,
            """
            SELECT * FROM artifacts
            WHERE owner_agent = ? AND kind = 'doc'
            ORDER BY
              CASE
                WHEN path LIKE 'docs/system-%' THEN 0
                WHEN path LIKE 'docs/agents/%' THEN 1
                ELSE 2
              END,
              mtime DESC
            LIMIT 12
            """,
            (agent_id,),
        )
        handoffs = rows(conn, "SELECT * FROM handoffs WHERE to_agent = ? ORDER BY created_at DESC LIMIT 20", (agent_id,))
    memory_html = ""
    if agent["memory_path"]:
        memory_path = (ROOT / agent["memory_path"]).resolve()
        if ROOT in memory_path.parents and memory_path.exists() and memory_path.suffix.lower() == ".md":
            memory_html = _render_markdown(memory_path.read_text(encoding="utf-8", errors="replace"))
    doc_previews = []
    for artifact in doc_artifacts[:4]:
        doc_path = (ROOT / artifact["path"]).resolve()
        if ROOT in doc_path.parents and doc_path.exists() and doc_path.suffix.lower() == ".md":
            doc_previews.append(
                {
                    "path": artifact["path"],
                    "html": _render_markdown(doc_path.read_text(encoding="utf-8", errors="replace")),
                }
            )
    return templates.TemplateResponse(
        request,
        "agent_detail.html",
        {
            "request": request,
            "agent": agent,
            "tasks": tasks,
            "artifacts": artifacts,
            "doc_artifacts": doc_artifacts,
            "doc_previews": doc_previews,
            "handoffs": handoffs,
            "memory_html": memory_html,
        },
    )


@app.get("/ui-layout")
def ui_layout(request: Request):
    return templates.TemplateResponse(request, "ui_layout.html", {})


@app.get("/requirements")
def requirements(request: Request):
    with _db() as conn:
        _refresh_index(conn)
        requirement_rows = rows(
            conn,
            """
            SELECT * FROM requirements
            ORDER BY priority ASC, module_title, submodule_title, updated_at DESC
            """,
        )
        agents = rows(conn, "SELECT id, name FROM agents ORDER BY id")
    modules: dict[str, dict] = {}
    for req in requirement_rows:
        key = req["module_id"] or req["module_title"]
        module = modules.setdefault(
            key,
            {
                "id": req["module_id"],
                "title": req["module_title"] or "未分组模块",
                "submodules": {},
                "total": 0,
                "done": 0,
            },
        )
        sub_key = req["submodule_id"] or req["submodule_title"]
        submodule = module["submodules"].setdefault(
            sub_key,
            {"id": req["submodule_id"], "title": req["submodule_title"] or "未分组子模块", "requirements": []},
        )
        submodule["requirements"].append(req)
        module["total"] += 1
        if req["status"] == "done":
            module["done"] += 1
    grouped_modules = [
        {**module, "submodules": list(module["submodules"].values())}
        for module in modules.values()
    ]
    return templates.TemplateResponse(
        request,
        "requirements.html",
        {
            "request": request,
            "modules": grouped_modules,
            "requirements": requirement_rows,
            "agents": agents,
            "error": request.query_params.get("error", ""),
            "success": request.query_params.get("success", ""),
        },
    )



@app.post("/requirements")
def create_requirement(
    module_title: str = Form(...),
    submodule_title: str = Form(...),
    title: str = Form(...),
    description: str = Form(""),
    status: str = Form("planned"),
    phase: str = Form("功能设计"),
    priority: int = Form(2),
    owner_agent: str = Form("producer"),
    acceptance: str = Form(""),
    links: str = Form(""),
):
    req_id = "req-manual-" + uuid4().hex[:10]
    with _db() as conn:
        conn.execute(
            """
            INSERT INTO requirements (
              id, module_id, module_title, submodule_id, submodule_title,
              title, description, status, phase, priority, owner_agent,
              acceptance, links, source_path
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'web')
            """,
            (
                req_id,
                _slug(module_title),
                module_title,
                _slug(submodule_title),
                submodule_title,
                title,
                description,
                status,
                phase,
                priority,
                owner_agent,
                acceptance,
                links,
            ),
        )
        conn.commit()
    return _redirect("/requirements")


@app.post("/requirements/{requirement_id}/proof")
def update_requirement_proof(
    requirement_id: str,
    proof_summary: str = Form(""),
    proof_links: str = Form(""),
):
    with _db() as conn:
        exists = row(conn, "SELECT id FROM requirements WHERE id = ?", (requirement_id,))
        if not exists:
            raise HTTPException(status_code=404, detail="requirement not found")
        conn.execute(
            """
            UPDATE requirements
            SET proof_summary = ?, proof_links = ?, proof_updated_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
            """,
            (proof_summary.strip(), proof_links.strip(), requirement_id),
        )
        conn.commit()
    return _redirect_with_feedback("/requirements", success="工作证明已保存")


@app.post("/requirements/{requirement_id}/status")
def update_requirement_status(requirement_id: str, status: str = Form(...)):
    with _db() as conn:
        req = row(conn, "SELECT id FROM requirements WHERE id = ?", (requirement_id,))
        if not req:
            raise HTTPException(status_code=404, detail="requirement not found")
        conn.execute("UPDATE requirements SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?", (status, requirement_id))
        conn.commit()
    return _redirect_with_feedback("/requirements", success="需求状态已更新")


@app.post("/requirements/{requirement_id}/create-handoff")
def create_handoff_from_requirement(requirement_id: str):
    with _db() as conn:
        req = row(conn, "SELECT * FROM requirements WHERE id = ?", (requirement_id,))
        if not req:
            raise HTTPException(status_code=404, detail="requirement not found")
        agent = row(conn, "SELECT memory_path FROM agents WHERE id = ?", (req["owner_agent"],))
        phase = req["phase"] or "功能设计"
        conn.execute(
            """
            INSERT INTO handoffs (
              task_id, from_agent, to_agent, goal, memory_files, context_files,
              expected_output, acceptance, constraints, status
            )
            VALUES (NULL, 'producer', ?, ?, ?, ?, ?, ?, ?, 'draft')
            """,
            (
                req["owner_agent"],
                req["description"] or req["title"],
                agent["memory_path"] if agent else "",
                req["links"],
                "改动摘要\n验证结果\n需要写回的经验",
                req["acceptance"],
                f"当前阶段：{phase}；保持与 requirements.yaml 对齐，完成后补齐工作证明。",
            ),
        )
        conn.commit()
    return _redirect_with_feedback("/handoffs", success="已从需求生成交接")


@app.post("/requirements/{requirement_id}/create-task")
def create_task_from_requirement(requirement_id: str):

    with _db() as conn:
        req = row(conn, "SELECT * FROM requirements WHERE id = ?", (requirement_id,))
        if not req:
            raise HTTPException(status_code=404, detail="requirement not found")
        if req["linked_task_id"]:
            return _redirect("/tasks")
        cursor = conn.execute(
            """
            INSERT INTO tasks (title, goal, owner_agent, status, priority, milestone, context_files, acceptance, constraints)
            VALUES (?, ?, ?, 'planned', ?, ?, ?, ?, ?)
            """,
            (
                f"需求实现：{req['title']}",
                req["description"],
                req["owner_agent"],
                req["priority"],
                f"{req['module_title']} / {req['submodule_title']}",
                req["links"],
                req["acceptance"],
                "按 功能设计 → 美术UI → 程序实现 → QA 顺序推进；不要跳过验收。",
            ),
        )
        conn.execute(
            "UPDATE requirements SET linked_task_id = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
            (cursor.lastrowid, requirement_id),
        )
        conn.commit()
    return _redirect("/tasks")


@app.get("/tasks")
def tasks(request: Request):
    with _db() as conn:
        task_rows = rows(conn, "SELECT * FROM tasks ORDER BY status, priority, updated_at DESC")
        agents = rows(conn, "SELECT id, name FROM agents ORDER BY id")
    return templates.TemplateResponse(
        request,
        "tasks.html",
        {
            "request": request,
            "tasks": task_rows,
            "agents": agents,
            "error": request.query_params.get("error", ""),
            "success": request.query_params.get("success", ""),
        },
    )



@app.post("/tasks")

def create_task(
    title: str = Form(...),
    goal: str = Form(""),
    owner_agent: str = Form("producer"),
    status: str = Form("planned"),
    priority: int = Form(2),
    milestone: str = Form(""),
    context_files: str = Form(""),
    acceptance: str = Form(""),
    constraints: str = Form(""),
):
    with _db() as conn:
        conn.execute(
            """
            INSERT INTO tasks (title, goal, owner_agent, status, priority, milestone, context_files, acceptance, constraints)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (title, goal, owner_agent, status, priority, milestone, context_files, acceptance, constraints),
        )
        conn.commit()
    return _redirect("/tasks")


@app.post("/tasks/{task_id}/proof")
def update_task_proof(
    task_id: int,
    proof_summary: str = Form(""),
    proof_links: str = Form(""),
):
    with _db() as conn:
        exists = row(conn, "SELECT id FROM tasks WHERE id = ?", (task_id,))
        if not exists:
            raise HTTPException(status_code=404, detail="task not found")
        conn.execute(
            """
            UPDATE tasks
            SET proof_summary = ?, proof_links = ?, proof_updated_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
            """,
            (proof_summary.strip(), proof_links.strip(), task_id),
        )
        conn.commit()
    return _redirect_with_feedback("/tasks", success="任务工作证明已保存")


@app.post("/tasks/{task_id}/status")
def update_task_status(task_id: int, status: str = Form(...)):
    with _db() as conn:
        task = row(conn, "SELECT id, proof_summary, proof_links FROM tasks WHERE id = ?", (task_id,))
        if not task:
            raise HTTPException(status_code=404, detail="task not found")
        if status == "done" and not _proof_complete(task["proof_summary"], task["proof_links"]):
            return _redirect_with_feedback("/tasks", error="任务置为完成前请先补齐工作证明（摘要+关联证据）")
        conn.execute("UPDATE tasks SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?", (status, task_id))
        conn.commit()
    return _redirect_with_feedback("/tasks", success="任务状态已更新")



@app.get("/handoffs")
def handoffs(request: Request):
    with _db() as conn:
        handoff_rows = rows(conn, "SELECT * FROM handoffs ORDER BY created_at DESC")
    return templates.TemplateResponse(
        request,
        "handoffs.html",
        {"request": request, "handoffs": handoff_rows},
    )



@app.post("/handoffs/from-task/{task_id}")
def create_handoff_from_task(task_id: int, expected_output: str = Form("")):
    with _db() as conn:
        task = row(conn, "SELECT * FROM tasks WHERE id = ?", (task_id,))
        if not task:
            raise HTTPException(status_code=404, detail="task not found")
        agent = row(conn, "SELECT memory_path FROM agents WHERE id = ?", (task["owner_agent"],))
        conn.execute(
            """
            INSERT INTO handoffs (
              task_id, from_agent, to_agent, goal, memory_files, context_files,
              expected_output, acceptance, constraints, status
            )
            VALUES (?, 'producer', ?, ?, ?, ?, ?, ?, ?, 'draft')
            """,
            (
                task_id,
                task["owner_agent"],
                task["goal"] or task["title"],
                agent["memory_path"] if agent else "",
                task["context_files"],
                expected_output,
                task["acceptance"],
                task["constraints"],
            ),
        )
        conn.commit()
    return _redirect("/handoffs")


def render_handoff(handoff) -> str:
    return "\n".join(
        [
            "[handoff]",
            f"from: {handoff['from_agent']}",
            f"to: {handoff['to_agent']}",
            f"goal: {handoff['goal']}",
            "memory_files:",
            *_prefixed_lines(handoff["memory_files"]),
            "context_files:",
            *_prefixed_lines(handoff["context_files"]),
            "expected_output:",
            *_prefixed_lines(handoff["expected_output"]),
            "acceptance:",
            *_prefixed_lines(handoff["acceptance"]),
            "constraints:",
            *_prefixed_lines(handoff["constraints"]),
        ]
    )


def _prefixed_lines(value: str) -> list[str]:
    lines = [line.strip() for line in value.splitlines() if line.strip()]
    if not lines:
        return ["  - <fill in>"]
    return [f"  - {line}" for line in lines]


@app.get("/handoffs/{handoff_id}")
def handoff_detail(request: Request, handoff_id: int):
    with _db() as conn:
        handoff = row(conn, "SELECT * FROM handoffs WHERE id = ?", (handoff_id,))
        if not handoff:
            raise HTTPException(status_code=404, detail="handoff not found")
    return templates.TemplateResponse(
        request,
        "handoff_detail.html",
        {"request": request, "handoff": handoff, "handoff_text": render_handoff(handoff)},
    )


@app.get("/artifacts")
def artifacts(
    request: Request,
    owner_agent: str = "",
    kind: str = "",
    category: str = "",
    adopted_status: str = "",
    page: int = 1,
    per_page: str = "20",
):
    allowed_page_sizes = {"20", "50", "100", "all"}
    if per_page not in allowed_page_sizes:
        per_page = "20"
    page = max(1, page)

    where = " FROM artifacts WHERE 1=1"
    params: list[str] = []
    if owner_agent:
        where += " AND owner_agent = ?"
        params.append(owner_agent)
    if kind:
        where += " AND kind = ?"
        params.append(kind)
    if category:
        where += " AND category = ?"
        params.append(category)
    if adopted_status:
        where += " AND adopted_status = ?"
        params.append(adopted_status)

    with _db() as conn:
        _refresh_index(conn)
        total_count = row(conn, f"SELECT COUNT(*) AS count {where}", tuple(params))["count"]
        query = f"SELECT * {where} ORDER BY mtime DESC"
        if per_page != "all":
            limit = int(per_page)
            total_pages = max(1, (total_count + limit - 1) // limit)
            page = min(page, total_pages)
            offset = (page - 1) * limit
            query += " LIMIT ? OFFSET ?"
            artifact_rows = rows(conn, query, (*params, limit, offset))
            showing_from = offset + 1 if total_count else 0
            showing_to = min(offset + limit, total_count)
        else:
            limit = None
            total_pages = 1
            page = 1
            artifact_rows = rows(conn, query, tuple(params))
            showing_from = 1 if total_count else 0
            showing_to = total_count
        agents = rows(conn, "SELECT id, name FROM agents ORDER BY id")
        kinds = rows(conn, "SELECT DISTINCT kind FROM artifacts ORDER BY kind")
        categories = rows(conn, "SELECT DISTINCT category FROM artifacts ORDER BY category")
        adopted_statuses = rows(conn, "SELECT DISTINCT adopted_status FROM artifacts ORDER BY adopted_status")

    def artifact_url(target_page: int) -> str:
        query_params = {
            "owner_agent": owner_agent,
            "kind": kind,
            "category": category,
            "adopted_status": adopted_status,
            "per_page": per_page,
            "page": str(target_page),
        }
        return "/artifacts?" + urlencode({k: v for k, v in query_params.items() if v})

    page_links = []
    if per_page != "all":
        start = max(1, page - 2)
        end = min(total_pages, page + 2)
        page_links = [(item, artifact_url(item)) for item in range(start, end + 1)]

    return templates.TemplateResponse(
        request,
        "artifacts.html",
        {
            "request": request,
            "artifacts": artifact_rows,
            "agents": agents,
            "kinds": kinds,
            "categories": categories,
            "adopted_statuses": adopted_statuses,
            "owner_agent": owner_agent,
            "kind": kind,
            "category": category,
            "adopted_status": adopted_status,
            "page": page,
            "per_page": per_page,
            "per_page_options": ["20", "50", "100", "all"],
            "total_count": total_count,
            "total_pages": total_pages,
            "showing_from": showing_from,
            "showing_to": showing_to,
            "prev_url": artifact_url(page - 1) if per_page != "all" and page > 1 else "",
            "next_url": artifact_url(page + 1) if per_page != "all" and page < total_pages else "",
            "page_links": page_links,
        },
    )


# ---------------------------------------------------------------------------
# Adopt API helpers
# ---------------------------------------------------------------------------
CATEGORY_TO_GAME_ART_DIR = {
    "ui_button": "ui/button",
    "ui_dialog": "ui/dialog",
    "ui_icon": "ui/icon",
    "ui_frame": "ui/frame",
    "ui_cursor": "ui/cursor",
    "scene_background": "backgrounds",
    "character_portrait": "characters",
    "sprite_sheet": "sprites",
    "audio": "audio",
}


def _copy_to_game_art(artifact_path: str, category: str) -> str | None:
    """Copy an adopted artifact into game/art/<subdir>/ and return dst relative path.
    
    Returns:
        str: destination relative path on success
        None: skip (no matching game art dir)
        Raises on copy error.
    """
    src = ROOT / artifact_path
    if not src.exists() or not src.is_file():
        return None
    # Already a game art file — skip copy
    rel_src = src.resolve().relative_to(ROOT.resolve())
    if rel_src.as_posix().startswith("game/art/"):
        return str(rel_src.as_posix())
    subdir = CATEGORY_TO_GAME_ART_DIR.get(category)
    if not subdir:
        return None
    dst_dir = ROOT / "game" / "art" / subdir
    dst_dir.mkdir(parents=True, exist_ok=True)
    dst = dst_dir / src.name
    
    # Skip if identical content already exists
    if dst.exists() and dst.stat().st_size == src.stat().st_size:
        return str(dst.relative_to(ROOT).as_posix())
    
    shutil.copy2(src, dst)
    return str(dst.relative_to(ROOT).as_posix())


@app.post("/api/artifacts/{artifact_id:int}/adopt")
def adopt_artifact(artifact_id: int):
    try:
        with _db() as conn:
            artifact = row(conn, "SELECT path, category, adopted_status FROM artifacts WHERE id = ?", (artifact_id,))
            if not artifact:
                raise HTTPException(status_code=404, detail="产出不存在")
            if artifact["adopted_status"] == "adopted":
                return {"status": "already_adopted", "path": artifact["path"]}
            # Copy file to game/art/ if applicable
            copied_path = None
            if artifact["category"] and artifact["category"] != "unknown":
                try:
                    copied_path = _copy_to_game_art(artifact["path"], artifact["category"])
                except Exception as copy_err:
                    raise HTTPException(status_code=500, detail=f"文件复制失败: {copy_err}")
            conn.execute(
                "UPDATE artifacts SET adopted_status = 'adopted' WHERE id = ?",
                (artifact_id,),
            )
            conn.commit()
        return {
            "status": "adopted",
            "path": artifact["path"],
            "copied_to": copied_path,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/artifacts/{artifact_id:int}/reject")
def reject_artifact(artifact_id: int):
    try:
        with _db() as conn:
            r = row(conn, "SELECT adopted_status FROM artifacts WHERE id = ?", (artifact_id,))
            if not r:
                raise HTTPException(status_code=404, detail="产出不存在")
            conn.execute(
                "UPDATE artifacts SET adopted_status = 'rejected' WHERE id = ?",
                (artifact_id,),
            )
            conn.commit()
        return {"status": "rejected"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/artifacts/{artifact_id:int}/reset")
def reset_artifact_status(artifact_id: int):
    try:
        with _db() as conn:
            r = row(conn, "SELECT adopted_status FROM artifacts WHERE id = ?", (artifact_id,))
            if not r:
                raise HTTPException(status_code=404, detail="产出不存在")
            conn.execute(
                "UPDATE artifacts SET adopted_status = 'candidate' WHERE id = ?",
                (artifact_id,),
            )
            conn.commit()
        return {"status": "reset"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ---------------------------------------------------------------------------
# QA & Costs & Repo (original routes continue below)
# ---------------------------------------------------------------------------

@app.get("/qa")
def qa(request: Request):
    with _db() as conn:
        _refresh_index(conn)
        qa_rows = rows(conn, "SELECT * FROM qa_runs ORDER BY mtime DESC")
    return templates.TemplateResponse(request, "qa.html", {"qa_runs": qa_rows})


@app.get("/costs")
def costs(request: Request):
    with _db() as conn:
        _refresh_index(conn)
        cost_rows = rows(conn, "SELECT * FROM cost_records ORDER BY mtime DESC LIMIT 200")
    return templates.TemplateResponse(request, "costs.html", {"costs": cost_rows})


@app.get("/repo/{path:path}")
def repo_file(request: Request, path: str, raw: str = ""):
    target = (ROOT / path).resolve()
    if ROOT not in target.parents and target != ROOT:
        raise HTTPException(status_code=403, detail="outside repo")
    sensitive = {".env", ".env.local", "agent_hub.sqlite3"}
    if target.name in sensitive or target.suffix == ".key":
        raise HTTPException(status_code=403, detail="sensitive file")
    relative = target.relative_to(ROOT).as_posix()
    with _db() as conn:
        allowed = row(conn, "SELECT 1 FROM artifacts WHERE path = ?", (relative,))
    if not allowed:
        raise HTTPException(status_code=404, detail="file is not indexed artifact")
    if not target.exists() or not target.is_file():
        raise HTTPException(status_code=404, detail="file not found")
    if target.suffix.lower() == ".md" and raw != "1":
        markdown_text = target.read_text(encoding="utf-8", errors="replace")
        return templates.TemplateResponse(
            request,
            "markdown_preview.html",
            {
                "request": request,
                "path": relative,
                "html": _render_markdown(markdown_text),
            },
        )
    return FileResponse(target)


@app.get("/health")
def health():
    return {"ok": True, "repo": str(ROOT), "roles": list(ROLE_NAMES)}
