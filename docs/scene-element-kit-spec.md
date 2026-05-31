# 场景元素模块库 · 规范 v1

> 目标：用模块化 2.5D 元素拼装林西村新手关卡三场景（主街 / 官道 / 密林），
> 不再给每个场景生成不可复用的整张背景大图。
> 本规范定义 4 类 atlas 的元素清单、命名体系、Godot 接入标准。

---

## 1. 总则

| 项 | 规范 |
|---|---|
| **视角** | 正交略俯视（~30°），适合 Sprite2D 平铺摆放 |
| **光源** | 统一右上方暖光，阴影朝左下落 |
| **透明度** | **所有元素必须是透明底**（RGBA，零像素 alpha=0） |
| **禁止** | 人物、NPC、中文字、英文、编号、水印、签名 |
| **风格** | 港漫厚涂，墨线清晰，色彩明亮鲜艳（暗调场景允许但保持高饱和） |
| **画幅** | 1536×1024 横版 atlas |
| **元素数** | 每张 atlas 12–20 个独立元素，整齐分布，元素间留白 ≥ 40px |

---

## 2. 命名体系

```
<category>_<subdomain>_<material/feature>_<variant>.png
```

### 2.1 Category 前缀

| 前缀 | 类别 |
|---|---|
| `road_` | 地面 / 道路 |
| `build_` | 建筑 |
| `veg_` | 植物 |
| `prop_` | 可交互道具 |

### 2.2 子域（地点标识）

| 子域 | 说明 |
|---|---|
| `linxi_` | 林西村通用（第一章村庄风格） |
| `zhuwei_` | 竹尾村通用 |
| `ruin_` | 城西废宅特化 |

### 2.3 变体后缀

| 后缀 | 说明 |
|---|---|
| `_a` `_b` `_c` | 同类型不同造型变体 |
| `_L` `_M` `_R` | 左 / 中 / 右接缝模块（建筑墙体 / 屋顶） |
| `_edge` | 过渡边缘（道路→草地等） |
| `_cluster` | 簇 / 丛（植物组） |

### 2.4 命名示例

```
road_dirt_linxi_straight_a.png       # 黄土路直段 A
road_dirt_linxi_cross.png            # 黄土路三岔口
road_stone_zhuwei_straight_a.png     # 青石板直段
build_linxi_house_wall_L.png         # 民居木墙左块
build_linxi_inn_door.png             # 酒馆木门
build_linxi_roof_gray_a.png          # 灰瓦屋顶块
veg_bamboo_single_a.png              # 竹子单株
veg_bamboo_cluster_a.png             # 竹丛 A
veg_bush_green_a.png                 # 灌木丛
prop_linxi_lantern_red_a.png         # 红灯笼
prop_linxi_barrel_wood_a.png         # 木桶
prop_linxi_signboard_blank.png       # 招牌底板（无字）
prop_ruin_wall_crack_L.png           # 破墙左块
prop_zhuwei_stone_altar.png          # 石坛
```

---

## 3. 四类 Atlas 元素清单

### 3.1 Atlas 1：地面 / 道路（`scene_kit_ground_road_linxi_v1`）

> 用于拼装村道、官道、小镇街道的地面底层。大部分元素可无缝拼接。

| 元素 ID | 文件名 | 说明 |
|---|---|---|
| 01 | `road_dirt_linxi_straight_a` | 黄土路直段，约 256×128 |
| 02 | `road_dirt_linxi_curve_L` | 黄土路左弯道 |
| 03 | `road_dirt_linxi_curve_R` | 黄土路右弯道 |
| 04 | `road_dirt_linxi_cross` | 黄土路三岔 / 十字口 |
| 05 | `road_stone_zhuwei_straight_a` | 青石板直段 |
| 06 | `road_stone_zhuwei_straight_b` | 青石板直段（破损） |
| 07 | `road_stone_zhuwei_corner_L` | 青石板转角 |
| 08 | `road_dirt_grass_edge` | 土路→草地过渡边 |
| 09 | `road_stone_grass_edge` | 石板→草地过渡边 |
| 10 | `road_gravel_scatter_a` | 碎石散落 |
| 11 | `road_gravel_scatter_b` | 碎石大块 |
| 12 | `road_dirt_footprint_trail` | 土路脚印 / 车辙痕 |
| 13 | `road_grass_patch_a` | 草地斑块（可做装饰底层） |
| 14 | `road_grass_patch_b` | 草地斑块 B |
| 15 | `road_dirt_slope_up` | 上坡土路（替换视野深度的直段） |

### 3.2 Atlas 2：建筑（`scene_kit_building_linxi_v1`）

> 林西 / 竹尾村用武侠民居 + 酒馆建筑模块。可分左中右拼出任意宽度的房屋。

| 元素 ID | 文件名 | 说明 |
|---|---|---|
| 01 | `build_linxi_house_wall_L` | 民居木墙左块（含左檐） |
| 02 | `build_linxi_house_wall_M` | 民居木墙中块（可重复拉伸） |
| 03 | `build_linxi_house_wall_R` | 民居木墙右块（含右檐） |
| 04 | `build_linxi_roof_gray_L` | 灰瓦屋顶左块 |
| 05 | `build_linxi_roof_gray_M` | 灰瓦屋顶中块 |
| 06 | `build_linxi_roof_gray_R` | 灰瓦屋顶右块 |
| 07 | `build_linxi_door_wood_a` | 木门（合闭） |
| 08 | `build_linxi_door_wood_open` | 木门（半开） |
| 09 | `build_linxi_window_paper_a` | 纸窗 |
| 10 | `build_linxi_column_wood` | 木柱（立） |
| 11 | `build_linxi_eaves_straight` | 屋檐直段 |
| 12 | `build_linxi_wall_courtyard_a` | 院墙 / 篱笆段 |
| 13 | `build_linxi_inn_storefront` | 酒馆门面（含酒幡挂架，无文字） |
| 14 | `build_linxi_smithy_front` | 铁匠铺门面（炉口可见，无人） |
| 15 | `build_linxi_signboard_blank_a` | 横匾招牌底板（无字） |
| 16 | `build_linxi_signboard_blank_b` | 竖匾招牌底板（无字） |

### 3.3 Atlas 3：植物（`scene_kit_veg_linxi_v1`）

> 竹子为主（第一章竹尾村场景基调），辅以灌木杂草。前景遮挡用。

| 元素 ID | 文件名 | 说明 |
|---|---|---|
| 01 | `veg_bamboo_single_a` | 竹子单株（完整，高约 300px） |
| 02 | `veg_bamboo_single_b` | 竹子单株 B（形态微变） |
| 03 | `veg_bamboo_cluster_a` | 竹丛（3–5 株一组） |
| 04 | `veg_bamboo_cluster_b` | 竹丛 B（密集） |
| 05 | `veg_bamboo_edge_L` | 竹林左边缘（可作场景边框） |
| 06 | `veg_bamboo_edge_R` | 竹林右边缘 |
| 07 | `veg_bamboo_top_canopy` | 竹冠蓬（前景遮挡用，水平走向） |
| 08 | `veg_bush_green_a` | 灌木丛（低矮，约 80px 高） |
| 09 | `veg_bush_green_b` | 灌木丛 B |
| 10 | `veg_grass_tuft_a` | 草簇（地面点缀） |
| 11 | `veg_grass_tuft_b` | 草簇 B |
| 12 | `veg_flower_wild_a` | 路边野花（小撮） |
| 13 | `veg_leaves_scatter` | 竹叶散落（地面装饰） |
| 14 | `veg_tree_pine_a` | 远景松树（远山背景用） |
| 15 | `veg_foliage_fg_L` | 前景竹叶遮挡左（失焦感） |
| 16 | `veg_foliage_fg_R` | 前景竹叶遮挡右 |

### 3.4 Atlas 4：可交互道具（`scene_kit_prop_linxi_v1`）

> 覆盖村内、官道、废宅三场景所有可交互物 + 装饰物。

| 元素 ID | 文件名 | 说明 |
|---|---|---|
| 01 | `prop_linxi_barrel_wood_a` | 木桶（竖放） |
| 02 | `prop_linxi_barrel_wood_b` | 木桶（横放） |
| 03 | `prop_linxi_box_wood_a` | 旧木箱（闭合） |
| 04 | `prop_linxi_box_wood_open` | 旧木箱（开盖） |
| 05 | `prop_linxi_wine_jar_a` | 酒坛 |
| 06 | `prop_linxi_wine_jar_stack` | 酒坛叠放（2 坛） |
| 07 | `prop_linxi_lantern_red_a` | 红灯笼（挂式） |
| 08 | `prop_linxi_lantern_red_b` | 红灯笼（立杆式） |
| 09 | `prop_linxi_wine_banner` | 酒幡（红布条，无字） |
| 10 | `prop_zhuwei_stone_tablet` | 石碑（路边指路，青苔斑驳） |
| 11 | `prop_zhuwei_road_sign` | 木路牌（立杆，无字） |
| 12 | `prop_linxi_weapon_scatter` | 散落兵器（断剑 / 枪杆，官道战斗迹） |
| 13 | `prop_linxi_fire_pot` | 铁匠铺炉火盆（含火光） |
| 14 | `prop_zhuwei_stone_altar` | 古旧石坛（密林 BOSS 战场） |
| 15 | `prop_ruin_wall_crack_L` | 破墙左块 |
| 16 | `prop_ruin_wall_crack_R` | 破墙右块 |
| 17 | `prop_ruin_door_broken` | 破旧木门（半坍） |
| 18 | `prop_ruin_beam_broken` | 断木梁 |
| 19 | `prop_ruin_rubble_pile` | 瓦砾堆 |
| 20 | `prop_linxi_cart_wood` | 木推车（街边障碍） |

---

## 4. AI 生成参数

| 参数 | 值 |
|---|---|
| model | `gpt-image-2` |
| size | `1536x1024` |
| quality | `high` |
| background | `transparent` |
| n_reference_images | 0（纯文本锚定，依赖 identity_anchor 保持风格） |

### identity_anchor（所有 4 张 atlas 共用）

```
港漫厚涂武侠 2D RPG 场景元素 atlas，
正交略俯视视角（~30°），统一右上方暖光、阴影左下落，
色彩明亮鲜艳、墨线清晰，
透明背景，每个元素完整独立、无遮挡，
不要人物、NPC、中文字、英文、编号、水印。
```

---

## 5. Godot 接入标准

### 5.1 目录结构

```
game/art/modules/
├── ground/          ← 道路/地面元素 PNG
├── building/        ← 建筑模块 PNG
├── veg/             ← 植物元素 PNG
├── prop/            ← 道具/装饰物 PNG
└── atlases/         ← 原始 atlas 大图（切分前的备份）
```

### 5.2 Sprite2D 摆放规范

每个场景元素在 Godot 中作为 `Sprite2D` 节点摆放，关键属性：

```gdscript
{
  "texture": "res://art/modules/building/linxi_house_wall_L.png",
  "position": Vector2(320, 480),        # 世界坐标 px
  "scale": Vector2(1.0, 1.0),           # 默认 1.0，可微调
  "z_index": 5,                         # 地面0 建筑10-20 植物15-25 前景30+
  "centered": true,                     # 轴心居中
}
```

### 5.3 Z-Index 分层约定

| 层 | z_index 范围 | 元素 |
|---|---|---|
| 地面 | 0 | road_* 道路元素 |
| 地面装饰 | 1–4 | 碎石、草簇、竹叶散落 |
| 建筑底层 | 5–9 | 院墙、柱子 |
| 建筑主体 | 10–14 | 墙体、门、窗、招牌 |
| 建筑顶层 | 15–19 | 屋顶 |
| 植物中层 | 15–24 | 灌木、竹子单株 |
| 植物上层 | 25–29 | 竹丛、竹冠 |
| 道具 | 8–18 | 按位置在建筑前或后 |
| 前景遮挡 | 30+ | veg_foliage_fg_* |

### 5.4 碰撞框配置

```gdscript
# SceneScript collision_rects 示例
{
  "id": "inn_block",
  "pos": Vector2(0.22, 0.50),     # 归一化坐标
  "size": Vector2(0.16, 0.10),
  "asset_id": "build_linxi_inn_storefront"   # 关联元素
}
```

### 5.5 切分脚本

atlas 生成后使用 `scripts/slice_module_atlas.py` 切分（待实现；当前可先手工或复用 `sprite_slicer.py` 逻辑）：

```bash
python scripts/slice_module_atlas.py --atlas assets/raw/scene_background/scene_kit_building_linxi_v1.png --manifest docs/scene-element-kit-spec.md
```

---

## 6. 三场景拼装矩阵

下表标明每个场景需要哪些元素，即 **"这 4 张 atlas 应该覆盖以下全部需求"**。

### 6.1 林西村主街（ch1_s1_road）

| 层 | 所需元素 |
|---|---|
| 地面 | 黄土直段×3、弯道×1、土草过渡边 |
| 建筑 | 民居左中右×1 组、酒馆门面、铁匠铺门面、招牌底板、院墙 |
| 植物 | 竹丛×2、灌木×2、草簇 |
| 道具 | 红灯笼×4、酒坛×2、木推车、散落兵器、酒幡 |

### 6.2 村外官道（ch1_s2_qingfeng）

| 层 | 所需元素 |
|---|---|
| 地面 | 黄土直段×4、弯道×2、碎石散落、脚印车辙 |
| 建筑 | 无（野外场景） |
| 植物 | 竹丛×6、竹子单株×4、竹冠蓬×2、灌木、野花、草簇 |
| 道具 | 石碑、路牌、散落兵器（战后痕迹） |

### 6.3 竹尾密林（ch1_s3_west_ruin）

| 层 | 所需元素 |
|---|---|
| 地面 | 黄土弯道、草地斑块、碎石 |
| 建筑 | 民居墙（废宅）、破墙、断梁 |
| 植物 | 竹丛×8、竹冠×3、灌木×4、前景竹叶遮挡×2、松树远景 |
| 道具 | 石坛、旧木箱×2、酒坛、破门、瓦砾堆 |

---

## 7. 暂不做

- 不做完整 TileMap 编辑器管线（短期人力不够）
- 不替换 `bg_*.png` 单张背景方案（模块化方案是并行新增，不是替代）
- 不生成 45° 等距 tile（保持正交略俯视）
- atlas 内元素不做动态光照 / 法线贴图

---

_最后更新：2026-05-09 · v1_
