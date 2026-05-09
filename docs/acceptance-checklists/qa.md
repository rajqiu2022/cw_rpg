# 测试 / QA 验收清单（qa）

> 适用对象：每次 sprint / milestone 完成、或 bug 复现。

## 自动化

- [ ] `game/tests/test_inventory_m5.gd`（M5 起）通过。
- [ ] `python scripts/smoke_test.py` 通过（不烧钱的接口冒烟）。
- [ ] `python scripts/verify.py` 通过（如适用）。
- [ ] 涉及新模块时新增对应 `game/tests/test_*.gd`。

## 手测（按当前 milestone 取对应清单）

- [ ] `docs/mvp-m1-checklist.md` ~ `docs/mvp-m5-checklist.md` 的相关条目逐项勾选。
- [ ] 主菜单「新游戏」「继续游戏」「设置」「退出」全部可点，无 Parser Error。
- [ ] Field 场景在缺 PNG 时仍显示 FallbackBg + HintBar。
- [ ] 存档 → 退出 → 继续游戏后，关键状态（金币 / 背包 / 装备 / 任务进度 / 当前场景）一致。

## bug 复现

- [ ] 提供：步骤 / 期望 / 实际 / 截图（如有）/ 控制台日志关键行。
- [ ] 标注是否阻塞当前 milestone 验收。
- [ ] 在 `docs/experience-log.md` 留索引。

## 提交时附带

- 跑过的命令清单
- 通过 / 失败统计
- 是否要求 review agent 介入
