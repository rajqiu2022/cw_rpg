# 双区独立物件 Field 验证与角色 30% 比例试调（2026-09-30）

## 本轮结论

- **比例试调已进入运行工程**：正式 v12 世界地图与 v13 staging 的主角视觉比例从 `0.58` 调为 `0.754`（×1.30），不改变地图、镜头、脚底坐标或物理半径。战斗编队的玩家、队友和敌人共用 ×1.30 渲染基准；旧单人回退路径也同步调整。其他城镇／室内 Field 比例不变，避免把已有 1.18～1.32 的近景角色误放大。
- **分层物件仍只在隔离双区试样运行**：四件独立物件共用一份脚底数据，真实 Field 控制器以这份数据生成纹理、脚底碰撞和按 Y 排序的遮挡。四物件各自脚底阻挡、左右侧绕行和前后排序检查均通过；没有把视觉 FAIL 的地表替换到正式 v12 或 v13 staging。
- 视觉审查：30% 角色试调在 1920×1080 单人战斗、五人编队、正式世界地图、v13 staging 截图中未见角色被 UI 裁切。山门战斗首拍发现最上排敌人血条文字贴顶，已把编队状态栏顶边留白改为 28px 后复拍。隔离试样灌木能正确盖住后方角色，前方角色能盖住灌木。但地形仍平、石块缺接地明暗过渡，**新版地图视觉仍 FAIL**，不能因此宣布全部场景完成。

## 可复核资源

- 场景物件合同：`game/scripts/dev/world_native_pair_prop_contract_v1.gd`；预览脚本与真实 Field 测试共用，不再手抄两份坐标。
- 真实 Field 专项：`game/tests/test_world_native_pair_field_props_v1.gd`。隔离运行资源为本机 `game/build/world_native_pair_shared_v2_visual.png` 与 `_walk.png`，需先运行 v2 构建并导入；这些不是正式打包素材。
- 前后遮挡截图：`game/build/world_native_pair_field_props_v1_behind.png`、`_front.png`。
- 比例截图：`game/screenshots/field_world_map_jianghu_1790725302.png`、`field_world_map_jianghu_v13_staging_1790725337.png`、`battle_thug_lone_1790725183.png`、`battle_thug_lone_thug_lone_thug_lone_1790725215.png`。
- 山门五友军／三敌人复拍：`game/screenshots/battle_thug_lone_thug_lone_thug_lone_1790726231.png`。

## 验证

- Godot 严格编辑器导入 exit 0；双区同源裁切／道路／水陆测试 exit 0；真实 Field 物件测试 0 失败（headless 与 OpenGL 截图各一次）；战斗场景布局专项 0 失败；四张角色比例实机截图生成 exit 0。
- 旧 `game/test/validate_party_battle_feedback_20260814.gd` 仍因引用已移除的 `BattleFormationView.ALLY_SLOTS/ENEMY_SLOTS` 在解析阶段失败。这是旧测试未维护，不是本次比例试调通过的证明；本轮未改那份过期测试。
- OpenGL 截图命令退出时有项目现存的纹理 RID 清理告警；截图和断言已完成，仍不能把 exit 0 解释为视觉通过。

## 待办

1. 双区地形要在固定正交镜头下重做有体积的地貌、路肩与接地阴影，再审草地重复、海水和授权石块的材质统一。
2. 视觉通过后，才扩展到桥、城池入口与九宫；逐区做脚底通行、物件阻挡、前后层级和真实返程落点测试。
3. 30% 是首轮比例试调，需由玩家确认世界／战斗的观看感受，尤其检查多人高密度战斗与不同分辨率。不要用这次单屏截图宣称全部战斗地图完成。
