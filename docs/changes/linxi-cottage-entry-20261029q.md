# 林西村村民家入口与旧落点修复 · 2026-10-29q

已修改正式场景。进屋落在屋内南门箭头旁，出屋返回村中心同一民房箭头；旧的右墙落点会迁到屋内门前。需要重新运行当前游戏进程才能加载新 Router 和场景资源。

## 问题与范围

用户截图所示人物在右墙。正常首次进入本室的原默认坐标 `(0.5, 0.76)` 本来正确；错误的旧坐标 `(0.835, 0.60)` 会被全局最近安全点搜索移至 `(0.837883, 0.646675)`。旧可走多边形包含右墙，这个“安全点”在视觉上仍是墙。另一个可复现问题是村外沈青禾距离民房箭头太近，在箭头按空格先触发 NPC 对话。

本次只修 `linxi_farmer_cottage` 及其与 `linxi_village_center` 的门户配对。没有把未验证的异步移动竞态当作根因，也不宣称所有场景入口已全面修复。

## 正式修改

- `game/scripts/field/linxi_entry_contract_20261029q.gd`：本室旧落点先核地板、家具与足部边缘；合法室内保存位置保留，无效位置回到明确门前，避免最近搜索落墙。村中心入本室始终使用本室门前落点；本室返回村中心读取对应门户箭头，旧路线缓存不覆盖这组门户。
- `game/scripts/autoload/scene_router.gd`：仅在本室恢复和相关门户解析处接上述 helper，两处窄改。最终 SHA `C0EDAB77`。
- `game/data/maps/linxi_farmer_cottage_layout_v1.tres`：地板范围排除右墙；补右墙筐篓碰撞；返回 fallback 从 `(0.775, 0.5)` 对齐到实际村外箭头 `(0.835, 0.470)`。最终 SHA `ADC0AFC3`。
- `game/data/scenes/linxi_village_center.tres`：沈青禾从 `(0.820, 0.520)` 移至 `(0.735, 0.550)`，避开门口优先对话范围，身份和对话保持。最终 SHA `68B2CAD1`。
- Router 与原洛阳来源合同采用必要九文件后继，保留旧 17 边与全部旧 source keys，新增完整逆变更第 18 边。EX `E959A8F9`。全局 Field、project、原室内默认出生点、村中心地图与全部 PNG 未修改。

## 实际验证及图片

独立自有 Godot 进程，公开 `go_field_smart` 设置初始场景，实际 InputEvent 的 Space/WASD 操作；用户编辑器 PID 51856 未操作，测试进程全部自然退出。

1. 原 `probe01` PID 133864 自然退出 1：外箭头 Space 被沈青禾对话截获，原失败保留。
2. 原 `probe02` PID 61900 自然退出 0：绕开 NPC 后正常进门；合成旧坐标复现右墙站位。未读取用户存档内容来制造该样本。
3. `verify03` PID 41340，22 检查通过，自然退出 0：新来源头/新完整逆边、历史允许及未知拒绝、Culture readiness、presentation 来源、合法室内恢复保留、两种旧墙位置回门；实际外箭头 Space 入屋、S 走向门再 Space 返回、旧路线缓存重入、错误旧位置实际恢复均通过。右侧行走虽被新墙界阻挡，但原图显示筐篓仍可站人，因此只接受入口结果，不以该数值通过冒充筐篓视觉验收。
4. 仅新增筐篓阻挡后 `wall04` PID 117784，6 检查通过，自然退出 0：旧筐篓落点回门、门前仍合法、实际 D 停止在 `(0.720833, 0.72)`，A 可离开。原图确认脚在地板上。已通过的进返与来源检查继承，不重跑整组。

实图已逐张查看：

- [入屋门前](../../game/build/linxi_entry_repair_20261029q/entry_after03.png)
- [返回村外同一箭头](../../game/build/linxi_entry_repair_20261029q/return_after03.png)
- [旧错误位置恢复到门前](../../game/build/linxi_entry_repair_20261029q/legacy_after03.png)
- [筐篓旁实际阻挡](../../game/build/linxi_entry_repair_20261029q/basket_boundary_after04.png)

所有原始报告和日志位于 `game/build/linxi_entry_repair_20261029q/` 与 `assets/staging/linxi_entry_repair_20261029q/`。旧七条退出 Texture/RenderingServer ERROR 仍在，不称空 stderr 或 clean。数据补丁首次因把沈青禾写成“沈清禾”的匹配断言中断，修正精确姓名后完成；原文件备份保持。

## 保护与交付边界

末核 177 个原基线对象：173 个 SHA/bytes/mtime_ns 精同；两项是本批授权 Map/Router；另两项 `save_0.json`/`.bak` 在 23:35/23:36 外部更新，时间位于自有 probe02 退出与 verify03 启动之间。原整体 guard 失败事实保留，更新后的两存档现值保持稳定，未还原或覆写；其余 169 个登记存档与最初基线精同。全部测试启动即暂停 checkpoint 保存。不能声称最初 171 存档全程零差。

正式九来源与封存候选 SHA 一致；最终 `final-guard.json` 保留 `initial_global_guard_passed: false` 及外部存档差异。无新 PNG、像素处理、资源导入或图鉴条目变更。当前仅本民房入口/恢复/右墙范围交付，停止成功组件复测。
