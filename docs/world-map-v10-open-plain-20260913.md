# 江湖大地图 v10 · 开阔原野版（2026-09-13）

## 目标

旧版大地图地标密集、道路细碎，角色行走更像在图标之间穿梭，缺少传统 RPG 大地图的远行感。本版重做空间构图：中央留出大面积原野，城镇、门派、雪关、渡口与茶山分布在外围，以宽阔官道连接。

## 已实施

- 使用 OpenAI 内置 ImageGen 生成全新 3:2 斜俯视江湖母图；v9 仅作画风参考，没有直接修改旧图。
- 中央两块开阔区域并入正式导航，不再把玩家限制在细线道路上；当前可走面积为整图的 33.93%。
- 15 条主路与支路由同一份结构化数据生成道路强化、导航蒙版和 QA 覆盖图；最窄道路在 2304×1536 运行尺寸下约 87 像素。
- 13 个目的地处于同一安全连通域。华山、武当、古峰、凌月山的触发点位于山脚官道口，山上阶梯只表达距离，不允许角色沿隐形通道穿越山体。
- 世界镜头放大到 1.25，主角旅行比例收至 0.58，使横纵移动都需要跨屏，增强大地图的路程感。
- 每个可进入区域的箭头旁常驻金色地名；靠近后仍沿用原有交互与转场逻辑。右侧地标使用向左排版，减少文字越界。
- 运行场景、M 键地图、林西/竹尾/烈云/茗雾返回点、桌面/移动分块和微信资源规则全部切换到 v10；v9 资源保留，可回退。

## 资源与数据

- ImageGen 原图：`assets/raw/scene_background/world_map_v10_open_plain/bg_world_map_jianghu_v10_source.png`
- 运行底图：`game/art/backgrounds/region_masters_v2/bg_world_map_jianghu_v10_2304.png`
- 4608 桌面母图：`assets/raw/scene_background/world_map_v10_open_plain/bg_world_map_jianghu_v10_pc_4608.png`
- 导航蒙版：`game/art/navigation_masks/world_map_jianghu_walk_v10.png`
- 布局：`game/data/maps/world_map_jianghu_layout_v10.tres`
- 路网单一来源：`scripts/world_map_v10_road_source.py`
- 生成与验证报告：`assets/processed/scene/world_map_v10/navigation_validation.json`

## 验收

- 13/13 门户连通。
- 4063 个带 5 像素脚底余量的路网中心样本通过。
- 开阔区、官道、门户与山体/水域负例通过。
- 15 个移动分块和 15 个桌面分块均可逐像素精确还原母图。
- 世界专项 66 项、旅行专项 59 项、地区综合专项 117 项，合计 242 项零失败。
- Godot 4.6.1 严格导入 exit 0；仅保留已有的嵌套微信 staging 工程提示。
- 真实 OpenGL 截图检查了中央、北部、西部和东部视野，地名与箭头均可见，北部门派入口没有再落到山体隐形路上。

本批没有重新导出 Web 或微信包。
