# 城门像素遮挡、等比例城区与大地图地名清晰度（2026-09-14）

## 本轮问题

1. 洛阳等正门虽然已有角色淡化，但淡化区域仍靠截图后人工估算，角色会出现在屋瓦/门框上，楼梯处也可能错误透明。
2. 汴州、襄州、金陵首版城市图采用从城门望向全城的远透视构图，远处道路和建筑缩小，只适合作为loading或概念图，不适合等比例角色自由行走。
3. 世界地图入口地名属于世界空间节点，跟随1.25倍镜头放大，低有效分辨率字形被二次采样后发糊。

## 城门根治方案

每个可穿越门楼现在必须同时交付四类数据：

- 与场景逻辑画布同尺寸的前景alpha蒙版；
- 门洞中心的脚底可走通道；
- 门柱、墙体等不可走blocker；
- 门洞透明点、横梁/屋檐不透明点及真实Field截图。

运行时层级固定为：原角色 → 不透明门楼前景 → 仅在门楼蒙版内显示的半透明角色剪影。这样角色穿过门洞空白时保持正常；与横梁或屋檐实体像素重叠时，只有重叠部分显示淡影。前景和剪影读取同一蒙版，不再各自维护人工估算矩形。

本轮接入：

- `game/art/masks/gate_occlusion_v1/luoyang_south_gate_foreground_mask_v1.svg`
- `game/art/masks/gate_occlusion_v1/wudang_gate_foreground_mask_v1.svg`
- `game/art/masks/gate_occlusion_v1/huashan_gate_foreground_mask_v1.svg`

蒙版没有交给生成式接口重绘。原因是它必须与现有底图逐像素对齐，生成式编辑容易改变门框轮廓；本轮使用确定性同画布矢量蒙版，自动验证尺寸和关键透明/不透明采样点。之前的旧方案确实主要来自实机截图后人工判断矩形，本轮已将其从新门楼合同中淘汰。

## 三座城市可玩地图v2

旧`openworld_cities_v1`城市远景图保留，但合同明确为`loading_or_concept_only`。运行时三城切换为独立局部城区：

| 城市 | 可玩底图 | 局部空间职责 |
|---|---|---|
| 汴州 | `bg_bianzhou_market_gameplay_v2_3072.png` | 中原坊市与通缉榜广场 |
| 襄州 | `bg_xiangzhou_garrison_gameplay_v2_3072.png` | 关城军市与告示墙 |
| 金陵 | `bg_jinling_bridge_market_gameplay_v2_3072.png` | 江南桥市与水巷广场 |

三图使用内置ImageGen生成1536×1024源图，再由Real-ESRGAN 2×重建为3072×2048。提示词共同约束为：写实手绘武侠2.5D局部城区、固定平行/近正交斜俯视、无地平线与消失点、道路宽度不随纵深缩小、跨画布建筑和人物参照尺度一致、宽连续铺地、空场景、无人物/文字/UI。三城再以独立导航、通缉榜交互站位和双向出口接入。

后续中大型城市扩展必须以多个局部等比例分区构成；全城鸟瞰图只承担loading、地图概览或概念展示，不得直接接入Field运行场景。

## 世界地图地名清晰度

- `ExitZone`地名改为24px、3px深色描边；
- 字体导入开启多通道SDF；
- 标签按世界镜头zoom设置逆缩放，1.25倍镜头下最终仍为屏幕1:1采样；
- 箭头、标签和实际转场继续使用同一个出口节点，不额外维护一套屏幕坐标。

## 主要实现

- `game/scripts/field/dynamic_occluder_2d.gd`
- `game/scripts/field/player.gd`
- `game/scripts/field/field_walkable_controller.gd`
- `game/scripts/field/exit_zone.gd`
- `game/scenes/exit_zone.tscn`
- `game/data/maps/openworld_*_city_layout_v2.tres`
- `game/data/maps/openworld_city_gameplay_contract_v2.json`
- `assets/raw/scene_background/openworld_cities_v2/gameplay_projection_contract.json`

## 验收

- 新合同`test_city_projection_gate_mask_labels_20260914.gd`：54项0失败；
- 城市/通缉扩展：187项0失败；
- 三城真实Field装载：24项0失败；
- 门派地图：145项0失败；
- 地区场景：120项0失败；
- 动态遮挡：28项0失败；
- 合计558项0失败；严格资源导入exit0。

实机截图：

- `game/screenshots/world_map_v10_open_plain_center.png`
- `game/screenshots/city_gate_v2_bianzhou.png`
- `game/screenshots/city_gate_v2_xiangzhou.png`
- `game/screenshots/city_gate_v2_jinling.png`
- `game/screenshots/city_gate_v2_luoyang_gate.png`
- `game/screenshots/city_gate_v2_wudang_gate.png`
- `game/screenshots/city_gate_v2_huashan_gate.png`

快速截图进程退出时仍可能出现Godot既有Texture RID清理告警，不影响截图内容或上述合同结果。本轮仅更新Godot工程与源资产，未重建Web/微信包。
