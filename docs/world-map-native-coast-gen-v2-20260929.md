# 大地图海岸分层候选 v2 · 2026-09-29

## 本轮结果与边界

在不改正式 v12、也不替换 v13 九宫 staging 的前提下，做了一张 1536×1024 的可运行海岸局部候选：自生成的**无建筑地形底座**、从底座像素单独生成的**水陆导航蒙版**，以及从 CC0 Boulder 01 派生的**透明石块物件**。石块、接地阴影、脚底碰撞、Y 深度分开登记。实机截图：`game/screenshots/world_map_native_coast_gen_v2_candidate_20260929.png`。

与 v1 原生 3D 同源试验不同，本候选的视觉底座是内置生图编辑输出；导航蒙版由图像分类和人工约束推导，**不是生图模型提供的精确碰撞层**。可用性只能由定点探针与逐区实机审查确认，不能把这张小图扩印成全地图。

## 素材与复现链

- 原生地形试验：`game/scripts/dev/render_world_map_native_coast_slice_v1.gd`；v2 在同一高度、道路和水陆几何上尝试混合地面纹理、海面及授权 Coastal Cliff 01 / Shrub 03：`game/scripts/dev/render_world_map_native_coast_slice_v2.gd`。v2 输出只在本地 `game/build/`；重复纹理与物件比例未通过视觉验收。
- 内置生图编辑模式：以 v2 渲染作地貌/海岸构图，以已采用的洛阳写实场景作风格参考，要求固定平行 2.5D、自然草坡、斜向可走土路和右侧石岸海面，**不生成文字、建筑、道具或角色**。第一轮俯拍图因视角不合未采用；第二轮原图见本机 `C:/Users/rajqiu/.codex/generated_images/019ff02b-0e55-70f3-82bb-5e5410641bf8/exec-41c13719-89df-42f4-980f-2d8388e89807.png`，工作副本为 `game/art/backgrounds/world_map_v13_proto/bg_world_map_native_coast_cleanplate_gen_v2_candidate.png`。该文件仍是**候选**，不能标记已采用正式地图。
- 同轮又以授权巨石和地形作参考，尝试内置生图重做透明石块；新图出现明显红黄边缘残影，**未采用**，不进入游戏资源目录。当前可玩候选仍显示 CC0 巨石正交渲染图。
- `game/scripts/dev/build_world_native_coast_gen_v2_mask.gd` 从每行右侧连续海水像素提取岸线、平滑并向陆侧保留约 130 像素安全距离，输出 `game/art/navigation_masks/world_map_v13_proto/native_coast_gen_v2_walk_candidate.png`；`game/build/native_coast_gen_v2_mask_overlay.png` 仅用于 QA。
- 隔离运行资源：`game/data/scenes/world_map_native_coast_gen_v2_candidate_20260929.tres` 与对应 `_layout.tres`；无门户、不会从正式大地图进入。石块脚底阻挡、Y 深度和视觉物件使用同一条布局记录；接地阴影是单独、不阻挡行走的简单 SVG。

## 验收

- 生成底座、导航蒙版与场景图设计尺寸一致；道路/内陆四个脚底探针可走，海面、崖边和巨石脚底三个探针禁走；正式 v12、v13 staging 均未指向候选底座；候选合同 17 项、0 失败。
- Godot 4.6.2 严格导入 exit 0；OpenGL 实机截图 exit 0。截图进程退出仍有已知 GLES 纹理 RID 清理告警，不等于运行时画面/逻辑失败。
- **视觉未获批准**：底座比原生纹理试样自然，但仍缺相邻区接缝、道路连续性和足够多的可辨地标；授权石块即使加接地阴影，和底座的光照/接触关系仍显拼贴。当前只能证明分层接入方法可跑，不能宣布海岸区或全世界地图完工。

## 下一步门槛

按世界地图统一投影先做中心—海岸两块相邻底座，手工定岸线与道路接缝，并从同一规划导出导航；再把通过视觉验收的 CC0/自制城池、桥、石、植被逐件摆放，逐件验证脚底碰撞、前后排序和阴影。九区、16 入口和存档迁移需要在整图画面及通行审查通过后才切换正式运行图。
