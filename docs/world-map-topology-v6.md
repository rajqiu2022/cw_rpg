# 江湖大地图 v6：像素对齐道路合同

## 目标

- 玩家只能沿最终美术图中实际可见的浅色官道行走。
- 世界入口箭头位于城门、山门或村口外侧，不压在建筑内部。
- 运行大地图、`M` 行旅图、城市返回出生点共用一份 `WalkableMapLayout`。

## 单一数据源

- 场景：`game/data/scenes/world_map_jianghu.tres`
- 布局：`game/data/maps/world_map_jianghu_layout_v6.tres`
- 生成器：`scripts/build_world_map_v6_navigation.py`
- 审查叠图：`assets/processed/scene/world_map_v6/world_map_v6_navigation_overlay.png`
- 二值通行图：`assets/processed/scene/world_map_v6/world_map_v6_walkable_mask.png`

`SceneRouter` 只保留“场景属于哪个世界门户”的 ID 映射，不再保存坐标。坐标从 v6 门户读取；`WorldMapPanel` 同样读取运行场景及其门户。

## 道路生成流程

1. 人工定义道路图的连接关系和宽走廊，避免图像识别跨越到无关道路。
2. 在最终 3072×2048 底图中识别浅色官道像素。
3. 在人工走廊内保留道路像素，进行开闭运算与小区域清理。
4. 用分段寻路补齐桥面、阴影和路色变化造成的断点。
5. 排除城池、门派建筑和大型地标内部区域。
6. 将通行掩码压缩成 16px 栅格矩形，写入 Godot 正向行走多边形。
7. 生成叠加图目检，并以门户/可走/阻挡探针做运行验证。

## 门户规则

- 聚落和门派箭头放在道路与地标接触的门槛位置。
- 世界门户进入城市后，城市的世界出口必须返回同一门户坐标。
- 内部密林、洞穴、废宅不出现在大地图，由所属聚落进入。
- 门户中心必须落在任一 `walkable_regions` 内。
