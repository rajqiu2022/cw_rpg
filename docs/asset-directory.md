# 工程资源目录

盘点日期 2026-11-09。Godot 的 `res://` 对应工程的 `game/`。本目录按用途和平台整理入口，新增内容优先引用对应平台的运行资源。

## 按平台查找

| 清单 | 可查内容 |
| --- | --- |
| [桌面工程](../assets/catalog/resource_directory/pc.csv) | 桌面源工程里有静态路径或目录入口的资源，且本地微信快照无同路径副本。 |
| [微信试玩](../assets/catalog/resource_directory/mobile.csv) | 本地微信快照特有的文件、同逻辑路径但与桌面字节不同的版本，以及微信原生外壳素材。可定位到实际分包。 |
| [桌面与微信共用](../assets/catalog/resource_directory/shared.csv) | 桌面源和本地微信快照的逻辑路径及 SHA-256 一致。 |
| [桌面地图包](../assets/catalog/resource_directory/map-packs.csv) | 大图、分块、遮挡、地形数据和历史地图包按目录归组，附引用入口和数量。 |
| [待核资源](../assets/catalog/resource_directory/review.csv) | 未匹配到静态资源路径或目录入口的文件。地图目录里同类资源的数量见地图包清单。 |
| [已归档](../assets/catalog/resource_directory/archive.csv) | 确认归档的文件，带原路径、归档路径和校验值。 |

“静态路径”是代码、配置或场景的可定位引用。“有目录入口”表示存在按目录或名称加载的可能。剧情可达性、分支执行和发布包实际内容需分别核验。微信清单使用本地 `game/build/wechat_pack_projects` 的分包工程，缺项再查 `game/build/wechat_stage`。它记录已有快照，不代表桌面新资源已同步到微信。微信试玩的范围以 [打包计划](../config/wechat-content-pack-plan-v1.json) 和 [运行清单](../game/config/wechat_content_packs.json) 为准。工程当前只有 Web-WeChat 导出预设，Android、iOS 原生包未独立盘点。[导出预设](../game/export_presets.cfg)

本次对照查到 1,541 个同路径且同字节的文件。V8 世界图导航蒙版在桌面源工程和微信公共包内同名、字节不同，两份文件在微信清单中分别列出。大批地图分块按包归组，各清单提供最多六个引用入口示例。

## 按用途查找

| 类别 | 桌面运行资源 | 复用时查看 |
| --- | --- | --- |
| 战斗特效 | [战斗贴图与动画](../game/art/battle_vfx/) · [神兵外显](../game/scripts/appearance/) | [战斗特效表](../game/scripts/battle/battle_vfx_player.gd) 按动画 ID 绑定图集。神兵光晕走材质、挂点和粒子脚本。 |
| UI | [UI 素材](../game/art/ui/) · [界面场景](../game/scenes/ui/) | [系统按钮四态](../game/art/ui/menu_buttons_20261109/) · [UI 规范](ui-style-guide.md)。微信共用 UI 以本地公共包实际文件为准。 |
| 地图和场景 | [场景配置](../game/data/scenes/) · [布局数据](../game/data/maps/) · [建筑、地面、物件](../game/art/modules/) · [背景](../game/art/backgrounds/) | 原地形、碰撞、遮挡、入口与返脚需一起引用。大地图分块和布局见下表。 |
| 音乐 | [BGM](../game/art/audio/bgm/) · [武侠音乐库](../game/art/audio/bgm/wuxia_20261011/) | [曲目表](../game/scripts/audio/music_catalog.gd) 和场景 `bgm_path`。 |
| 音效和环境音 | [常用音效](../game/art/audio/free/) · [环境音](../game/art/audio/ambience/) · [生活技能音效](../game/art/audio/life_skills_20261030l/) | [音频管理器](../game/scripts/autoload/audio_manager.gd) 统一播放。微信的公共包、章节包路径见平台清单。 |
| 配音 | [对白配音](../game/art/audio/voices/) | 按对白和章节找，音效与配音分列。 |
| 角色 | [地图精灵及立绘](../game/art/characters/) · [战斗精灵](../game/art/sprites/battle/) | 地图 NPC 与战斗帧分别取用。 |

| 大地图 | 当前入口 | 可引用的分块或布局 |
| --- | --- | --- |
| 桌面工程 V16 | [World 场景](../game/data/scenes/world_map_jianghu.tres) | [V16 分块配置](../game/build/world_coast_20261031h_system01/world_v16_stream02.tres) · [V16 布局](../game/build/world_coast_20261031h_system01/world_v16_layout02.tres)。分块与布局会引用早期目录下继续在用的素材。 |
| 本地微信试玩快照 V8 | [快照中的 World 场景](../game/build/wechat_pack_projects/common/data/scenes/world_map_jianghu.tres) | [V8 分块配置](../game/build/wechat_stage/data/background_sets/world_map_jianghu_v8_streamed.tres) · [V8 移动分块](../game/build/wechat_stage/art/background_chunks/world_map_jianghu_v8/mobile/)。保留包内原路径。 |

## 归档与后续使用

[本轮留存库](../assets/retained/20261109/README.md) 集中保存五组旧备份、概念图和未采用候选。原图和 Godot 导入描述一并移动，恢复时按清单还原路径。旧批次历史档案继续在 [原有归档库](../assets/_archive/)。[制作原图](../assets/raw/) 和 [制作素材库](../assets/library/) 可作为重新出图或授权核对的来源。

正式运行、候选试用和历史预览分开登记。仍被出图模板引用的旧 UI 展示图、仍由脚本生成的战斗 UI 候选，以及只有动态加载线索的资源保留原路径。打包过滤规则和运行路径沿用现有配置。

[带缩略图的资源图鉴](equipment-skill-catalog.html) · [地图、音频和 NPC 历史复用索引](resource-reuse-index.md)

重新生成分类清单可在工程根目录执行 `python scripts/build_asset_directory.py`，输出到 `assets/catalog/resource_directory/`。这一步只更新索引。

