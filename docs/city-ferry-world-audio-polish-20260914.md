# 城市可行走区、白鹿渡、大地图与音频安全基线（2026-09-14）

## 结论

- 汴州、襄州、金陵与白鹿渡不再用宽松矩形代表可行走区，运行时切到独立黑白导航蒙版；白色只保留道路、广场与必要交互前站位，围墙、围栏、建筑、摊位、树池、码头水面和河道均为黑区，并额外做7像素脚底安全收缩。
- 襄州校场树冠新增独立透明遮挡蒙版。角色脚底进入树下时，由树冠像素覆盖角色并显示半透明剪影，不再把旁边地面或灯柱一起当成遮挡。
- 临时通缉榜改成正式冷黑铁木、旧纸与朱红揭榜牌界面。底图只提供材质和框架，标题、声望、犯人、等级、线报、奖励及按钮仍由Godot实时排版，避免AI文字和低分辨率文字。
- 白鹿渡重画为3072×2048固定比例2.5D多屏地图，保留宽广场、陆路、客栈、渡口公署与码头群；NPC、通缉犯候选点及返回入口全部回收到导航蒙版内。
- 三座城市运行图不再使用动漫模型超分。原先“源图写实、游戏内像油画/卡通”的直接原因是`RealESRGAN_x4plus_anime_6B`，现改为源图直接Lanczos确定性重建，避免动漫模型重塑瓦片、石板和树叶笔触。
- 江湖大地图升级到v11写实版，新增汴州、襄州、金陵实体城池，凌月山与东海埠分别放到洛阳东北山地与最东海岸；16个入口、20条路线同域连通，入口文字继续由程序清晰渲染。
- 所有本轮被否决的铜管/大号感音乐停止使用。武当、三城、渡口、世界地图及其他近期新增场景暂时统一回退到用户认可的林西村主题；胜利音乐改为从认可主题派生的8秒非循环庆祝句。当前是安全基线，不宣称已经完成城市和门派的差异化配乐。

## ImageGen资产

本批使用Codex内置ImageGen的编辑/参考图模式，未调用ALAPI。

- 通缉榜源图：`assets/raw/ui_frame/bounty_board_v2/bounty_board_frame_v2_source.png`
- 通缉榜运行图：`game/art/ui/bounty_board/bounty_board_frame_v2.png`
- 白鹿渡源图：`assets/raw/scene_background/bailu_ferry_v2/bg_bailu_ferry_gameplay_v2_source.png`
- 白鹿渡运行图：`game/art/backgrounds/openworld_ferry_v2/bg_bailu_ferry_gameplay_v2_3072.png`
- 大地图源图：`assets/raw/scene_background/world_map_v11_realistic/bg_world_map_jianghu_v11_source.png`
- 大地图运行图：`game/art/backgrounds/region_masters_v2/bg_world_map_jianghu_v11_2304.png`

提示词重点：通缉榜要求16:9、冷黑铁木、旧纸、朱红印牌、无任何生成文字；白鹿渡要求固定平行2.5D、无地平线和远景缩放、道路至少三人宽、建筑/摊位/水面与步道边界明确；大地图编辑要求保留海岸、河流、桥和开阔路网，新增五处互不重叠的实体地标并去除动漫描边、油画团块和文字。

## 导航、遮挡与世界地图

- 构建器：`scripts/build_openworld_city_navigation_v3.py`
- 城市/渡口蒙版：`game/art/navigation_masks/openworld_city_v3/`
- 审查叠图：`assets/processed/scene/openworld_city_v3/`
- 襄州树冠蒙版：`game/art/navigation_masks/openworld_city_v3/xiangzhou_lower_tree_canopy_mask_v1.png`
- 大地图道路源：`scripts/world_map_v11_road_source.py`
- 大地图构建器：`scripts/build_world_map_v11_assets.py`
- 大地图布局：`game/data/maps/world_map_jianghu_layout_v11.tres`
- 流式分块：`game/art/background_chunks/world_map_jianghu_v11/`
- 导航报告：`assets/processed/scene/world_map_v11/navigation_validation.json`

v11导航统计：20条路线、16个门户、4223个脚底中心样本、可走面积32.85%，全部入口处于同一连通域。

## 音频决策

参考了[GameFactory-3A](https://github.com/OpenDCAI/GameFactory-3A)的资产生产与审核工作流：生成资产必须经过可追溯、试听和质量门禁，不能因为文件可播放就自动投产。该工程不是可直接复制的武侠BGM曲库，因此本批没有从其中复制音乐。

- 场景安全基线：`game/art/audio/bgm/bgm_linxi_village_v6.wav`
- 胜利短句：`game/art/audio/bgm/bgm_victory_v4_approved.wav`
- 重建脚本：`scripts/build_audio_safe_fallback_v8.py`

曾考察第三方传统乐器曲目，但没有把未完成授权核验或带Content ID风险的网络音乐装入游戏。后续差异化配乐必须逐首人工试听后再替换，不再批量生成后直接挂载。

## 验证

- `test_city_ferry_world_v11_polish_20260914.gd`：109项，0失败。
- `test_reputation_bounty_city_expansion_20260913.gd`：194项，0失败。
- `test_region_scene_polish_20260913.gd`：117项，0失败。
- `test_openworld_city_runtime_20260913.gd`：24项，0失败。
- `test_world_map_v9_shared_source.gd`：79项，0失败。
- `validate_world_map_travel_20260820.gd`：59项，0失败。
- `test_sect_map_v3_runtime_navigation_20260913.gd`：108项，0失败。
- `test_wuxia_audio_v7_20260913.gd`：11项，0失败。
- `validate_polish_batch_20260822.gd`：147项，0失败。
- `test_sect_map_v3_20260913.gd`：145项，0失败。

合计993项，0失败；Godot 4.6.2严格导入exit 0。退出时个别测试仍报告既有资源清理警告，不影响断言结果。本批未重建Web/微信包。

## 实机证据

- `game/screenshots/bounty_board_v2.png`
- `game/screenshots/city_gate_v2_bianzhou.png`
- `game/screenshots/city_gate_v2_xiangzhou.png`
- `game/screenshots/city_gate_v2_jinling.png`
- `game/screenshots/city_gate_v2_bailu_ferry.png`
- `game/screenshots/world_map_v11_realistic_center.png`
