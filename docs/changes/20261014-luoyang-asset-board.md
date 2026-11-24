# 洛阳素材板与统一索引 · 试点

## 目标与边界

change-id：luoyang-asset-board-pilot。先让现有洛阳城楼、城墙、河岸、街坊与人物素材能在同一制作工具中浏览、比较和导出参考资料，避免制作时丢失来源或混淆正式采用状态。

这是本地制作工具，不是游戏内界面，不安装 OhMyGame，不调用图片／3D／音乐服务，不改变正式地图、加载队列或存档。现有生成脚本继续使用；参考包导出不等于自动生成或正式采用。

## 分工与写入范围

1. ART 盘点现有真实素材与当前 sprite 消费规范，写新 `assets/catalog/` 试点 JSON 和一份精灵规范说明。
2. SYSTEM 按冻结合同独立实现 `tools/asset_board/`，生成 `docs/luoyang-asset-board.html` 与检查报告。
3. QA 独立检查 ID、缺文件、路径逃逸、来源、导出与界面关键交互；producer 集成并查看真实预览。

探索可并行，实现按数据→工具→检查顺序；禁止改 `game/scripts`、`game/data`、`game/scenes`、`game/project.godot`、现有 PNG 和 `prompts/tasks.yaml`。不提交、不删除或重置用户工作区。

## 验收

- 项目相对路径、稳定 ID、真实来源证据；未知许可明确写未知，原创素材不冒称 CC0。
- 候选／参考／已采用分开；已采用须有现役场景及布局引用依据。浏览器工作草稿不会改变正式采用状态。
- 图片保持比例，能搜索、筛选、选择、同屏对比；缺文件保留 ID 和错误提示。
- 参考包包含原始路径与 SHA、来源、制作说明；导入检查未知 ID、过期 SHA、非法路径并保留有效草稿。
- 无外部依赖的 Node 本地检查／构建命令；真实浏览器关键交互和视觉检查。
- 精灵规范明确方向、帧数、尺寸、透明背景、脚点与循环验收；未知参数不得补成已验收值。

## 参考与许可处理

设计参考：[上游画布合同](https://github.com/WhiteTowerAI/ohmygame/blob/main/docs/canvas-agent.md)、[素材目录检查](https://github.com/WhiteTowerAI/ohmygame/blob/main/src/daemon/canvas-assets.ts)、[sprite 流程](https://github.com/WhiteTowerAI/ohmygame/blob/main/plugins/web-game-studio/skills/sprite-pipeline/SKILL.md)。本试点独立实现，不复制上游代码／整段规范，不把上游许可套给本项目图片；若后续实际引入代码，另做许可证与 notice 归档。

当前状态：本地管理工具试点完成。最终30项Node检查通过，ROOT实测搜索筛选、对照显示、草稿恢复、错误导入保留及参考包导出；真实六图参考包经CLI回核通过，20图已加载。正式地图与15保存未改，未调用生成服务。详 `game/build/asset_board_20261014_root01/outcome_root.json`；只授该有限工具验收，不授新场景、美术生成、自动试玩或加载提速信用。
