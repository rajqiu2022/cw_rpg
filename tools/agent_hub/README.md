# RPG_GAME Agent Hub

本地 Web 调度台，用来管理多 agent 的工作状态、handoff、产出、QA 和成本记录。

第一版边界：

- 不部署独立 agent。
- 不配置任何大模型 API key。
- 不自动调用 Cursor / Claude / OpenAI。
- Web 只负责管理需求、生成 handoff、扫描仓库产出。

- 实际执行仍由用户把 handoff 复制给 Cursor 中的 agent。

## 启动

```powershell
Set-Location F:\Code\RPG_GAME
python -m pip install -r scripts/requirements.txt
python -m uvicorn tools.agent_hub.app:app --reload --host 127.0.0.1 --port 8765
```

打开：

```text
http://127.0.0.1:8765
```

## 功能

- Dashboard：项目总览、活跃任务、最近 QA、成本记录。
- Agents：读取 `docs/agents/*-memory.md`，展示各角色职责与 memory 摘要。
- Requirements：按大模块 / 子模块跟踪需求，可新增需求、更新状态、直接生成交接；保存“工作证明”并在置为完成前校验。
- Handoffs：输出标准 `[handoff]` 文本，复制给 Cursor 执行。

- Artifacts：扫描文档、prompt、资源、GIF、QA JSON。
- QA：展示 `logs/qa/*.json` 的 PASS/FAIL。
- Costs：解析 `assets/raw/**/*.meta.json` 与 `logs/dry_run/*.meta.json`。

## 数据

SQLite 数据库：

```text
tools/agent_hub/agent_hub.sqlite3
```

删除该文件后重启应用，会重新从仓库扫描基础索引；手动创建的 tasks / handoffs 会随数据库删除而丢失。

_Last updated: 2026-05-01_
