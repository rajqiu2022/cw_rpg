# 2026-08-09 角色、图标与特效扩展批次

## 范围

- 主角：刀、棍、空手三套 Field 4 向母图，以及三套 Battle 4×5 五状态母图。
- 敌人：凌月守卫、武当弟子、蒙面杀手精英三套 Battle 4×5 母图。
- NPC：4 张基础立绘、沈半盏身份修正版立绘；第二阶段生成 6 套 Field 4×4 母图。
- UI：16 枚无文字技能图标、16 枚无文字物品图标。边框和文字继续由 Godot 运行时负责。
- VFX：毒针、眩晕、寒霜万针三套 2×2 四阶段图集。不重复已有的剑/刀/棍/掌三阶通用特效。

任务清单：

- `prompts/tasks_asset_expansion_20260809_phase1.yaml`：19 项，可独立生成。
- `prompts/tasks_asset_expansion_20260809_phase2.yaml`：6 项，依赖第一阶段立绘身份锚点。

## 本轮结果

第一阶段 dry-run 为 19/19 通过。正式生成在硬预算 ¥20 下完成 3 项，任务成本合计 ¥3.60：

- `portrait_linxi_herbalist_subo_v1`
- `portrait_linxi_village_guard_v1`
- `portrait_linxi_teacher_v1`

三张均已目检为候选：身份、手部、随身物件和画风无明显缺陷。原图和 `.meta.json` 位于 `assets/raw/character_portrait/expansion_20260809/`，元数据均为 `gpt-image-2 / alapi / fallback_used=false / CNY 1.20`。

随后 16 项均收到 `ALAPI error code=400 message=`。又分别用一项无参考图 VFX 和一项安全题材立绘执行 `--skip-ping` 单任务诊断，仍连续返回空 400，费用均为 ¥0。本轮因此停止付费调用，未采用任何未完成资源，也未覆盖 `game/art/`。

### 继续尝试记录

按 ALAPI API 107 当前官方文档更新了客户端协议：生成请求只发送当前公开字段，参考图改用 `image_urls` data URL，并新增官方推荐的 `/images/generations_sync` 异步提交与 `/images/generations/task` 轮询。同步请求仍返回公共 400，request ID：

- `945023069886779392`
- `945023102140977152`
- `945023150882983936`

异步接口可以成功创建任务，证明 token、接口权限和本地 JSON 请求可到达服务端；但安全人物、无人物 VFX、`1024x1024` 和 `1:1` 两种尺寸均在模型执行阶段返回 `task failed, please try again later`。可供 ALAPI 支持定位的 task ID：

- `01KZK0YHBQ21W62Y48DGB7S1K6`
- `01KZK0Z0GF2008Y6HZ7TJEMQ87`
- `01KZK104Q8Q32WM4Q23EZFH4W4`
- `01KZK10GBFNNVEJZK9Z9W73DSW`
- `01KZK10ZNNZGS7XV0NGQQSDCM6`
- `01KZK12FA0XJX5F1M7CANDYWB5`
- `01KZK12SVMGFC6HYWDY5BT0GPG`
- `01KZK1390ZM9ZFFJZXDTHP7108`

上述失败任务的管线记账均为 ¥0。当前阻塞点已确认是 ALAPI 上游图像任务执行，而不是 prompt、参考图、尺寸格式、同步超时或本地解析。

## Codex 内置 ImageGen 续产

用户明确允许停止使用 ALAPI、改用 Codex 内置生图后，完成以下候选资产：

- 主角 Field：刀、棍、空手 3 套 4×4 母图，派生 24 条 idle/walk 运行条。
- 主角 Battle：刀、棍、空手 3 套 4×5 母图，派生 60 张 512×384 战斗帧。
- 敌人 Battle：凌月守卫、武当弟子、蒙面杀手精英 3 套 4×5 母图，派生 60 张 512×384 战斗帧。
- UI 图标：技能 16 枚、物品 16 枚，均派生 256px 与 64px RGBA，共 64 张运行候选。
- VFX：毒针、寒霜万针、眩晕冲击 3 套 1024² RGBA 四阶段图集，并生成 3 个 GIF。
- NPC：沈半盏正式身份立绘、沈半盏四向 Field、悦无姮专属四向 Field。

技术 QA 结果：`field_strips=40`、`battle_frames=120`、`icons_256=32`、`icons_64=32`、`vfx=3`、`gifs=3`，所有 Field 帧脚底透明区至少 8px，Battle 站立帧底边至少 12px。资产仍处于 `candidate`，尚未复制到 `game/art/` 或修改运行时绑定。

Codex 内置工具不暴露项目可核算单价，因此旁车元数据使用 `backend=codex_builtin`、`model=codex-imagegen-built-in`、`cost=null`、`currency=null`，不得伪装为 ALAPI 成本记录。

## 通道恢复后的续跑方式

先挑一项执行单图验证，预算必须略高于当前单图估值 ¥1.20：

```powershell
python scripts/gen_assets.py --tasks-file prompts/tasks_asset_expansion_20260809_phase1.yaml --task portrait_linxi_granny_v1 --skip-ping --fallback-model gpt-image-2 --budget 1.30 --concurrency 1
```

验证成功后仍按“单项生成 → 目检 → 后处理 → 下一项”的节奏续跑，不对已有成功项使用 `--force`，也不反复启动未计费到任务元数据的 startup ping。

`scripts/gen_assets.py` 现在默认使用 ALAPI 异步模式；仅在诊断旧同步接口时设置环境变量 `ALAPI_IMAGE_MODE=sync`。

## 后处理契约

- Field 4×4：`scripts/process_25d_npc_master_atlas.py`，默认输出 160px 帧、人物高 140px、脚底透明区 8px。
- Battle 4×5：`scripts/process_battle_sprite_atlas.py`，输出五状态各 4 帧、512×384、底边 12px。
- VFX/图标：先用 `scripts/remove_chroma_key.py --input <raw> --out <rgba> --auto-key border --soft-matte --despill --edge-contract 1` 转透明；图标再用 `scripts/slice_fixed_grid_atlas.py` 切 4×4，并派生 256px 与 64px 版本。
- 所有候选均需检查：身份一致、完整双脚、网格不串格、无文字水印、无洋红残边、移动端缩小后剪影可读。
