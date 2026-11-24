# 江湖大地图 v9：道路视觉与导航同源

## 结论

大地图正式升级到 v9。运行底图、桌面高清分块和像素导航遮罩不再由两套互不约束的人工结果维护，而是由同一份道路几何源生成。以后调整一段道路时，视觉强化层、碰撞遮罩、门户连通验证会一起重建；任一产物被单独改动，校验脚本都会失败。

## 采用方案

- 保留已经审定的 v8 地形、河流、城市和 13 个入口坐标，避免重绘造成剧情地理漂移。
- `scripts/world_map_v9_road_source.py` 是唯一道路源，现含 39 段路线、门户、路面横断面、可走与禁行见证点。
- `scripts/build_world_map_v9_assets.py` 同时生成 2304×1536 运行底图、4608×3072 桌面母图、导航遮罩、审阅覆盖图和哈希报告。
- 道路视觉只在导航带及其 12 像素边缘内做轻微暖色、中央提亮和边缘压暗，不重画山川，不制造新的假路。
- 世界场景、M 键地图和流式背景集已统一切到 v9；林西、竹尾离开城镇时直接落在各自 v9 门户，不再依赖运行时搜寻附近道路兜底。

## 为什么没有采用整图 AI 重绘

曾用 Codex 内置生图按道路覆盖图生成一张候选。候选的武侠质感合格，但道路曲线、河岸和地标发生了局部位移，无法保证现有门户、任务入口与旧存档坐标精确对应，因此标记为 rejected，未接入游戏。图像生成适合风格探索，不适合作为已有拓扑的像素级导航真值。

## 验证结果

- 39 段道路；13 个门户处于同一安全连通域。
- 角色脚底按 5px 半径校验，6245 个中心线密采样全部具备净空。
- 37 个登记路面横断面共 584 个像素样本全部可走。
- 10 个可走见证与 12 个水面、悬崖、屋顶禁行见证全部符合预期。
- 移动端与桌面背景逐像素重建一致；15+15 张流式分块无缝还原源图。
- Godot 运行时专项 52 项通过；世界地图旅行 59 项、场景标准 58 项、地图音频/NPC 148 项、开放世界入口 98 项通过。

## 重建与验证

```powershell
python scripts/build_world_map_v9_assets.py
python scripts/validate_world_map_v9_shared_source.py
python scripts/build_streamed_background_variants.py --mobile game/art/backgrounds/region_masters_v2/bg_world_map_jianghu_v9_2304.png --desktop assets/raw/scene_background/world_map_v9_shared_road_source/bg_world_map_jianghu_v9_pc_4608.png --output game/art/background_chunks/world_map_jianghu_v9 --logical-width 2304 --logical-height 1536 --chunk-size 512 --overlap 12
python scripts/validate_streamed_background_variants.py --manifest game/art/background_chunks/world_map_jianghu_v9/manifest.json --mobile-source game/art/backgrounds/region_masters_v2/bg_world_map_jianghu_v9_2304.png --desktop-source assets/raw/scene_background/world_map_v9_shared_road_source/bg_world_map_jianghu_v9_pc_4608.png
```

运行证据见 `assets/processed/scene/world_map_v9/navigation_validation.json` 和 `world_map_v9_navigation_overlay.png`。
