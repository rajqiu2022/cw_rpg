# 可行走地图 V2 规范

## 目标

固定视角 2.5D 场景不再依靠大量障碍矩形“猜”哪里不能走。地图使用正向可行走区域限定玩家动线，再用少量脚底碰撞补充建筑、树木、箱子等实体。

## 数据边界

- `SceneScript`：剧情场景身份、背景、BGM、NPC、进场对话。
- `WalkableMapLayout`：纯地图空间数据，位于 `game/data/maps/*_layout_v2.tres`。
- 所有位置、尺寸和多边形点使用相对背景可视区域的 `0~1` 归一化坐标。

## 五层结构

| 层 | 数据 | 规则 |
|---|---|---|
| VisualLayer | `visual_objects` | 背景上的独立建筑、树木、箱子；默认无物理 |
| CollisionLayer | `walkable_regions` + `blockers` | 正向道路边界 + 物件脚底局部阻挡 |
| InteractionLayer | `interactions` | `interact` 或 `enter_once`，禁止隐式自动触发 |
| PortalLayer | `portals` | 出口、目标场景/动作、显示条件 |
| ActorLayer | SceneScript `npcs` + Player | NPC 只走自身按键交互，不重复配置对话触发区 |

## 关键规则

1. 每张自由行走地图至少一个 `walkable_regions` 多边形。
2. 建筑碰撞覆盖墙脚、台基和不可穿越实体，不覆盖整张屋顶投影。
3. 可调查物使用 `activation = "interact"`；一次性调查必须带 `hide_flag`。
4. 自动剧情使用 `activation = "enter_once"`，必须带 `hide_flag`，并避免放在出生点。
5. 出口和交互点必须位于可行走多边形内，且从出生点可达。
6. 独立美术物件按语义逐个放置，禁止把未经审核的 atlas 碎片批量铺到正式底图上。
7. 玩家或 QA 标出的穿帮点写入 `walkable_probes` / `blocked_probes`，成为永久回归验收点。

## 验收

```powershell
godot --headless --path game --script res://test/validate_walkable_map_v2.gd
godot --headless --path game --script res://test/validate_first_two_walkability.gd
godot --headless --path game --script res://test/validate_chapters_1_4_resources.gd
```

随后对每张地图执行实际截图，并人工检查道路、出口箭头、NPC、独立物件和背景是否对齐。
