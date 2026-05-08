from __future__ import annotations

import sqlite3
from pathlib import Path
from typing import Any


APP_DIR = Path(__file__).resolve().parent
DB_PATH = APP_DIR / "agent_hub.sqlite3"
ROOT = APP_DIR.parents[1]


def connect() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db(conn: sqlite3.Connection) -> None:
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS agents (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            memory_path TEXT,
            scope TEXT,
            owner_summary TEXT,
            updated_at TEXT
        );

        CREATE TABLE IF NOT EXISTS tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            goal TEXT NOT NULL DEFAULT '',
            owner_agent TEXT NOT NULL DEFAULT 'producer',
            status TEXT NOT NULL DEFAULT 'planned',
            priority INTEGER NOT NULL DEFAULT 2,
            milestone TEXT NOT NULL DEFAULT '',
            context_files TEXT NOT NULL DEFAULT '',
            acceptance TEXT NOT NULL DEFAULT '',
            constraints TEXT NOT NULL DEFAULT '',
            proof_summary TEXT NOT NULL DEFAULT '',
            proof_links TEXT NOT NULL DEFAULT '',
            proof_updated_at TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        );


        CREATE TABLE IF NOT EXISTS handoffs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_id INTEGER,
            from_agent TEXT NOT NULL DEFAULT 'producer',
            to_agent TEXT NOT NULL,
            goal TEXT NOT NULL,
            memory_files TEXT NOT NULL DEFAULT '',
            context_files TEXT NOT NULL DEFAULT '',
            expected_output TEXT NOT NULL DEFAULT '',
            acceptance TEXT NOT NULL DEFAULT '',
            constraints TEXT NOT NULL DEFAULT '',
            status TEXT NOT NULL DEFAULT 'draft',
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE SET NULL
        );

        CREATE TABLE IF NOT EXISTS requirements (
            id TEXT PRIMARY KEY,
            module_id TEXT NOT NULL DEFAULT '',
            module_title TEXT NOT NULL DEFAULT '',
            submodule_id TEXT NOT NULL DEFAULT '',
            submodule_title TEXT NOT NULL DEFAULT '',
            title TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            status TEXT NOT NULL DEFAULT 'planned',
            phase TEXT NOT NULL DEFAULT '功能设计',
            priority INTEGER NOT NULL DEFAULT 2,
            owner_agent TEXT NOT NULL DEFAULT 'producer',
            acceptance TEXT NOT NULL DEFAULT '',
            links TEXT NOT NULL DEFAULT '',
            source_path TEXT NOT NULL DEFAULT '',
            linked_task_id INTEGER,
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(linked_task_id) REFERENCES tasks(id) ON DELETE SET NULL
        );

        CREATE TABLE IF NOT EXISTS artifacts (

            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT NOT NULL UNIQUE,
            kind TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT '',
            adopted_status TEXT NOT NULL DEFAULT 'candidate',
            owner_agent TEXT NOT NULL DEFAULT 'producer',
            summary TEXT NOT NULL DEFAULT '',
            status TEXT NOT NULL DEFAULT '',
            mtime TEXT NOT NULL DEFAULT ''
        );

        CREATE TABLE IF NOT EXISTS qa_runs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            report_path TEXT NOT NULL UNIQUE,
            source_path TEXT NOT NULL DEFAULT '',
            status TEXT NOT NULL DEFAULT '',
            detected_cells INTEGER,
            expected_cells INTEGER,
            baseline_spread INTEGER,
            height_spread INTEGER,
            mtime TEXT NOT NULL DEFAULT ''
        );

        CREATE TABLE IF NOT EXISTS cost_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            meta_path TEXT NOT NULL UNIQUE,
            task_id TEXT NOT NULL DEFAULT '',
            model TEXT NOT NULL DEFAULT '',
            cost REAL NOT NULL DEFAULT 0,
            currency TEXT NOT NULL DEFAULT '',
            dry_run INTEGER NOT NULL DEFAULT 0,
            size TEXT NOT NULL DEFAULT '',
            quality TEXT NOT NULL DEFAULT '',
            mtime TEXT NOT NULL DEFAULT ''
        );

        CREATE TABLE IF NOT EXISTS reviews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_id INTEGER,
            scope TEXT NOT NULL DEFAULT '',
            severity TEXT NOT NULL DEFAULT '',
            finding TEXT NOT NULL DEFAULT '',
            file_path TEXT NOT NULL DEFAULT '',
            blocking INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE SET NULL
        );
        """
    )
    _ensure_column(conn, "requirements", "proof_summary", "TEXT NOT NULL DEFAULT ''")
    _ensure_column(conn, "requirements", "proof_links", "TEXT NOT NULL DEFAULT ''")
    _ensure_column(conn, "requirements", "proof_updated_at", "TEXT NOT NULL DEFAULT ''")
    _ensure_column(conn, "tasks", "proof_summary", "TEXT NOT NULL DEFAULT ''")
    _ensure_column(conn, "tasks", "proof_links", "TEXT NOT NULL DEFAULT ''")
    _ensure_column(conn, "tasks", "proof_updated_at", "TEXT NOT NULL DEFAULT ''")
    _ensure_column(conn, "artifacts", "category", "TEXT NOT NULL DEFAULT ''")
    _ensure_column(conn, "artifacts", "adopted_status", "TEXT NOT NULL DEFAULT 'candidate'")
    conn.commit()


def _ensure_column(conn: sqlite3.Connection, table: str, column: str, ddl: str) -> None:
    existing = {item["name"] for item in conn.execute(f"PRAGMA table_info({table})")}
    if column in existing:
        return
    conn.execute(f"ALTER TABLE {table} ADD COLUMN {column} {ddl}")


def rows(conn: sqlite3.Connection, query: str, params: tuple[Any, ...] = ()) -> list[sqlite3.Row]:

    return list(conn.execute(query, params))


def row(conn: sqlite3.Connection, query: str, params: tuple[Any, ...] = ()) -> sqlite3.Row | None:
    return conn.execute(query, params).fetchone()


def rel(path: Path) -> str:
    return path.resolve().relative_to(ROOT).as_posix()
