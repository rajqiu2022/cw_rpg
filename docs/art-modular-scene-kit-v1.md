# 模块化场景美术 Kit v1

> 目标：停止把每个场景当作一张 loading / 概念图来画，改为“模块化美术 kit + Godot 数据化摆放”。
> 适用范围：林西村外官道、竹尾村/临溪镇主街、城西废宅等第一章前期场景。

## 1. 方向结论

短期不切纯 TileMap 像素流，也不继续整张大背景流。

推荐方案：

```text
可复用 PNG/atlas 模块
  -> Godot SceneScript / scene_objects 数据摆放
  -> 碰撞、遮挡、NPC 锚点、触发区随对象配置
```

原因：

- 保留漫画 2.5D / 港漫厚涂质感。
- 避免每个场景单独生成一张不可复用大图。
- 建筑、道路、树、摊位等可以换色 / 缩放 / 镜像 / 加装饰后复用。
- 更适合可行走玩法：障碍、出口、NPC 位置与视觉模块一一对应。

## 2. Kit 分层

### 2.1 Ground / Road

- 土路直段、弯道、交叉口
- 青石路直段、破损边缘、台阶
- 草地边缘、泥地过渡、石块边缘

### 2.2 Building

- 民居墙体模块：左 / 中 / 右
- 屋顶模块：灰瓦、褐瓦、青瓦
- 门窗、柱子、屋檐、院墙
- 招牌底板（不含文字，文字由 UI 或单独贴图叠加）

### 2.3 Vegetation

- 竹子单株、竹丛、竹林边缘
- 灌木、草丛、树根、枯枝
- 前景遮挡树枝

### 2.4 Props / Decoration

- 木箱、酒坛、摊位、木桶
- 灯笼、旗幡、石碑、路牌
- 破墙、断梁、旧门板、杂草

### 2.5 Gameplay Anchors

每个可交互模块建议同时记录：

```text
asset_id
pos_norm
scale
z_index
collision_rect
interaction_anchor
trigger_action
hide_flag / require_flag
```

## 3. Godot 数据建议

下一步 system 可考虑在 `SceneScript` 上增加：

```gdscript
@export var scene_objects: Array[Dictionary] = []
```

示例：

```gdscript
{
  "asset_id": "building_linxi_house_a",
  "path": "res://art/modules/buildings/linxi_house_a.png",
  "pos": Vector2(0.32, 0.42),
  "scale": 0.9,
  "z_index": 10,
  "collision_rect": {"pos": Vector2(0.32, 0.50), "size": Vector2(0.18, 0.10)}
}
```

## 4. 第一批建议生成

### Atlas A：林西 / 竹尾村建筑模块

- 8~12 个模块：墙、屋顶、门窗、院墙、招牌底板。
- 同一透视、同一光源、透明背景。
- 不要人物、不要中文字。

### Atlas B：道路 / 地面模块

- 土路、青石路、草地边缘、台阶、碎石。
- 可无缝拼接或至少边缘过渡自然。

### Atlas C：植物 / 装饰模块

- 竹子、树、灌木、石碑、木箱、酒坛、灯笼、摊位。
- 透明背景，适合直接作为 Sprite2D 叠加。

## 5. 验收标准

- 每个模块必须透明背景。
- 单个模块边缘干净，不带白底。
- 无人物、无文字、无水印。
- 光源方向一致，默认右上光。
- 适合在 1920×1080 场景中缩放摆放。
- 能明确区分可通行区域和障碍物。

## 6. 暂不做

- 不做完整 TileMap 编辑器管线。
- 不做每个场景一张完整成图。
- 不做自动生成碰撞；碰撞先手工矩形配置。
