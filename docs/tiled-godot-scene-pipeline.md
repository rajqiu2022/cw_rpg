# Tiled + Godot 场景拼装管线 v1

> 目标：把 Tiled 作为 2.5D 场景拼装的可视化编辑器，用 66 个透明 PNG 元素库搭建可行走新手关卡，再导入 Godot 的 `SceneScript`。

## 1. 方向结论

Tiled 是场景布局的 source of truth。Python 只负责导入、校验和格式转换，不再用 PIL 盲排场景。

本项目暂不把 Tiled 当传统 TileMap 使用，而是当 **Sprite2D 模块摆放编辑器**：

```text
game/art/modules/**/*.png
  -> Tiled image collection tileset
  -> maps/tiled/*.tmj
  -> scripts/import_tiled_scene.py
  -> game/data/scenes/*.tres
  -> field_walkable_controller.gd 渲染 scene_objects / 碰撞 / 触发
```

## 2. 目录约定

```text
game/art/modules/
├── ground/
├── building/
├── veg/
├── prop/
└── atlases/

maps/tiled/
├── tilesets/
└── linxi_tutorial.tmj
```

Tiled 里引用的图片应尽量指向 `game/art/modules/`，导入器会转换为 `res://art/modules/...`。若引用 `assets/` 下文件，导入结果不是 Godot 可直接加载路径。

## 3. 生成 Tiled Tileset

66 个元素 PNG 放入 `game/art/modules/{ground,building,veg,prop}/` 后，先生成 image collection tileset：

```powershell
python scripts/create_tiled_tileset.py --out maps/tiled/tilesets/scene_elements.tsx
```

也可以只收某些目录：

```powershell
python scripts/create_tiled_tileset.py game/art/modules/ground game/art/modules/prop `
  --out maps/tiled/tilesets/linxi_ground_props.tsx `
  --name linxi_ground_props
```

生成的 `.tsx` 会为每张 PNG 写入：

- `id`：文件名 stem
- `category`：从目录或文件名前缀推断
- `z_index`：按类别给默认层级

Tiled 中把 `maps/tiled/tilesets/scene_elements.tsx` 加为 external tileset，再拖拽素材到场景层。

## 4. 自动生成首版 Tiled 地图

正式拼关卡时不要求人工从零拖拽。先让脚本按固定构图模板生成可审核初版：

```powershell
python scripts/generate_linxi_tutorial_tiled.py `
  --tileset maps/tiled/tilesets/scene_elements.tsx `
  --out maps/tiled/linxi_tutorial.tmj `
  --preview tools/linxi_tutorial_tiled_preview.png
```

该脚本会：

- 按类别 / 文件名提示选择道路、建筑、竹林、灌木、道具、前景遮挡。
- 生成 `ground`、`buildings`、`vegetation`、`props`、`foreground` 五个可视层。
- 生成 `spawn`、`collisions`、`triggers`、`exits`、`npcs` 对象层。
- 同时渲染一张 PNG 预览，供快速审核。

这一步是确定性模板布局，不是让大模型自由拖图块。Tiled 的作用是让用户和 AI 后续可以可视化微调。

## 5. Tiled 地图设置

建议新建地图：

- Orientation: Orthogonal
- Tile layer format: JSON / `.tmj`
- Map size: `60 x 34`
- Tile size: `32 x 32`
- 实际画布：`1920 x 1088`，接近 Godot 运行视口 `1920 x 1080`
- Tileset 类型：Image Collection，每个 PNG 是一个 tile

## 6. 层命名规范

### 4.1 场景元素层

以下层会导入为 `SceneScript.scene_objects`：

| Tiled 层名 | 默认 z_index | 用途 |
|---|---:|---|
| `ground` / `road` / `terrain` | 0 | 道路、草地、石板 |
| `buildings` | 10 | 房屋、院墙、牌坊 |
| `props` | 12 | 木箱、酒坛、石碑、摊位 |
| `vegetation` / `veg` | 18 | 竹子、灌木、树 |
| `foreground` / `fg` | 30 | 前景遮挡树枝、竹叶 |

每层可设置自定义属性：

| 属性 | 类型 | 说明 |
|---|---|---|
| `z_index` | int | 覆盖该层默认深度 |

单个 tile object 可设置：

| 属性 | 类型 | 说明 |
|---|---|---|
| `id` | string | 场景对象 ID |
| `z_index` | int | 覆盖层默认深度 |
| `scale_x` / `scale_y` | float | 覆盖导入器按对象尺寸推导的缩放 |
| `require_flag` / `hide_flag` | string | 条件显示 |

## 7. 对象层规范

### `spawn`

玩家出生点。放一个矩形对象即可，导入对象中心为 `player_spawn`。

### `collisions`

矩形对象导入为 `collision_rects`：

| 属性 | 类型 | 说明 |
|---|---|---|
| `id` | string | 碰撞 ID |
| `require_flag` / `hide_flag` | string | 条件生效 |

### `triggers`

矩形对象导入为 `trigger_zones`：

| 属性 | 类型 | 说明 |
|---|---|---|
| `id` | string | 触发区 ID |
| `action` | string | `SceneRouter.resolve_action()` 动作，如 `dialog:ch1_road_intro` |
| `require_flag` / `hide_flag` | string | 条件生效 |

### `exits`

矩形对象导入为 `exits`：

| 属性 | 类型 | 说明 |
|---|---|---|
| `label` | string | 出口提示 |
| `target_scene` | string | 目标 `scene_id` |
| `target_pos` | string | 目标出生点，格式 `Vector2(0.1, 0.5)` |
| `require_flag` | string | 条件生效 |

### `npcs`

矩形对象导入为 `npcs`：

| 属性 | 类型 | 说明 |
|---|---|---|
| `npc_id` | string | NPC ID |
| `npc_name` | string | 显示名 |
| `dialog_id` | string | 对话资源 ID |
| `portrait_path` | string | 立绘路径 |
| `sprite_path` | string | 行走场景 sprite 路径 |
| `scale` | float | NPC sprite 缩放 |
| `require_flag` / `hide_flag` | string | 条件显示 |

## 8. 导入命令

```powershell
python scripts/import_tiled_scene.py maps/tiled/linxi_tutorial.tmj `
  --out game/data/scenes/linxi_tutorial.tres `
  --scene-id linxi_tutorial `
  --display-name "林西村 · 新手关" `
  --background-path ""
```

导入器输出：

- `scene_objects`
- `player_spawn`
- `npcs`
- `exits`
- `collision_rects`
- `trigger_zones`

## 9. 当前限制

- 只支持 Tiled JSON / `.tmj`，不解析 `.tmx` XML。
- 只支持普通有限地图，暂不支持 infinite chunks。
- 只支持矩形碰撞 / 触发区，暂不支持多边形。
- 旋转会写入 `scene_objects.rotation`，但碰撞区不随图片旋转。
- Tiled 引用的图片最好在 `game/art/modules/`，否则 Godot 路径不可直接加载。

## 10. 验收标准

- Tiled 中可视化摆放的模块能在 Godot 可行走场景中显示。
- 玩家能在 `collisions` 周围正确受阻。
- 进入 `triggers` 能执行 action。
- `exits` 能返回 `SceneRouter.go_field_smart()`。
- `npcs` 能触发现有对话系统。
- 不再使用 PIL 脚本作为正式场景布局工具。
