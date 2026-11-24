# 赤岩关镇 · 峡口首段编辑草案

**当前结论：用户已否定本版墙体拼装。** 岗楼与关墙没有形成完整建筑，侧墙插接、尺度和地形围合不合格。Scene与技术检查保留追溯，不继续作为设计基线；下面“已完成”仅指当时技术装配。新方案见[峡口连体关防重设计](redrock-gate-redesign-20261023d.md)。

2026-10-23，按用户“继续改造，如果可以就直接改到编辑器”，新增主工程内可编辑的原生节点场景。采用已选赤岩总规的红砂岩厚墙、平顶岗楼、关防/商队饮水/候检用途。此版仅峡口首段；不是整镇完成，也未加入正式大世界入口。

![首段原生画面](../assets/staging/redrock_editor_gate_20261023c/validation_project/artifacts_verified/overview.png)

## 在现有Godot工程查看

打开 [redrock_gate.tscn](../game/scenes/drafts/redrock_gate_20261023c/redrock_gate.tscn)，按F6运行当前场景。WASD/方向键移动，Tab切换全景/跟随，R回起点，F1切换制作标记。未切换主场景，F5仍沿原工程入口。

本次没有向现有编辑器发送打开/切换场景命令，没有关闭/重启编辑器。新场景已经写进同一工程，在文件系统面板可打开；没有额外启动第二个生产编辑器。

地面、建筑、两堵门墩、角色和碰撞均为独立节点，可在2D视图编辑。SceneTree中的`Depth`按脚点排序；各建筑`Art`与`Solid/Footprint`分离。地面材质在`Ground`，摄像机在`Camera`。本场景脚本不引用全局单例、存档、任务或路由。

## 路径与当前使用

| 内容 | 路径 | 当前状态 |
|---|---|---|
| 原生编辑场景 | `res://scenes/drafts/redrock_gate_20261023c/redrock_gate.tscn` | 已写主工程；可编辑/F6草案 |
| 草案控制 | `res://scripts/drafts/redrock_gate_20261023c/gate_preview.gd` | 原生CharacterBody2D移动、摄像机、门梁淡出 |
| 贴图与来源清单 | [resource-pack.json](../game/art/modules/redrock_gate_20261023c/resource-pack.json) | 9图逐项列工程路径/来源/消费者 |
| 地表混合 | `res://art/modules/redrock_gate_20261023c/ground_blend.gdshader` | 原生夯土/裸岩材质柔和过渡；不画建筑或峡壁 |
| 原像素保留的派生来源 | [12图处理说明](redrock-local-processing-20261023b.md) | 本次取7张；未追加PNG处理 |
| 原生地表来源 | [地面批次说明](redrock-ground-parallel-20261023b.md) | 本次取2张RGB原图 |
| 图鉴 | [资源查看](equipment-skill-catalog.html#resources) | 搜索“赤岩编辑草案”，9张可缩略/放大 |
| 实际摆放参数 | [placements.json](../assets/staging/redrock_editor_gate_20261023c/placements.json) | 原图origin、留白偏移、uniform scale、碰撞脚印 |

9张工程PNG与来源文件字节一致。7张透明图来自已授权派生，2张地表来自原生RGB；没有修改源图、裁图、删alpha或新生图。关门使用原像素scale=0.86，减去padding×scale补偿绘制起点；没有把扩画布后的全图fit回旧宽度。旧尺寸平面只是前期规划，本版按真实组件重新摆放，不宣称旧平面等于实际碰撞。

## 已完成与核验范围

场地2560×1760，成人视觉高112，角色足底碰撞35×25。关门两墩、连墙、岗楼、纵深墙、饮水槽、候检货位、匿名关卒均有独立节点；门中保持真实碰撞缺口。检查员复用同一待机精灵，标明仅用于尺度检查，不新增正式角色。

Godot4.6.2隔离工程完成场景载入、GPU绘图和77项检查，最终自然退出0：9图导入后全RGBA字节一致且无mipmap，2461次原生运动采样，进门/返程、岗楼门前、饮水和货位通行，9条横向门道采样，以及墙、两墩、货包、槽、楼与边界7组阻挡负例通过；注入W确实驱动CharacterBody2D移动。门梁下临时淡出整关门Art，碰撞不移除。该有限淡出效果仍可继续细分为门梁遮挡层。

[77项检查](../assets/staging/redrock_editor_gate_20261023c/validation_project/artifacts_verified/verification.json) · [门下实图](../assets/staging/redrock_editor_gate_20261023c/validation_project/artifacts_verified/door-passage.png) · [近景](../assets/staging/redrock_editor_gate_20261023c/validation_project/artifacts_verified/forecourt.png) · [精确导入日志](../assets/staging/redrock_editor_gate_20261023c/native-exact.log)。

首次GPU检查自然退出1：7张透明图被Godot默认`fix_alpha_border=true`改写透明区RGB。原FAIL、77检查/7失败、首图均保留在`validation_project/artifacts/`及`native-first.log`。只在本批隔离导入设置关闭fix_alpha_border、detect3D，源PNG不变，再核9图全RGBA精确。未通过修改比较条件掩盖失败。

首个`--quit-after 3`编辑器核验有Scan thread aborted警告，保留`editor-scene-load.log`；后续明确指定此Scene的隔离`--editor --import`自然0，记录在`editor-scene-import.log`。不宣称已操作用户编辑器UI。

主工程只新增本场景专用文件。9个`.import`和18个ctex/md5新叶由相同res路径的隔离工程精确复制；拒绝覆盖任何既有目标，没有整工程重新导入、UID重建或替换缓存数据库。[发布清单](../assets/staging/redrock_editor_gate_20261023c/publication.json)逐项列41个文件SHA，另新增1份说明性resource-pack。

## 仍待制作

- 峡壁立面、挡墙转角与后接层台、阶街建筑。当前是平面场地，裸岩材质不能当作真实高差、悬崖或防坠边界；地图外沿仍可见地面矩形范围。
- 岗楼与关墙的建筑连接、地脚/材质尺度统一、生活陈设和光影收边。现状有明显空地，画面属于装配草案，不授整区艺术通过。
- 合格统一脚锚行走序列与其余方向。目前两个可见人形共享待机图；移动检查员会平移，不能算已完成走路动画。
- 后续层台出口、正式导航/地图schema、NPC对白和剧情接线。现有通行检查不等于正式Field、任务旅行、整镇NAV或完整门洞320px全透明证明。

本轮保持生产`project.godot`、autoload、Field、原始/已处理PNG、根任务清单和保护域内存档不变；最终220文件的SHA/bytes/mtime_ns零差，见[保护结果](../assets/staging/redrock_editor_gate_20261023c/protected-after.json)。洛阳在另一对话的索引修改与本场景独立，未回滚其保存。

图鉴58项离线核查通过：9新副本＋9来源状态行，非resources以及其它旧行同，现4796文件/2489图/2307音。没有浏览器点击实测信用。复用索引首次读取遇洛阳6源并行保存，原生成器严格拒写；后继1772文本来源稳定，141场景/0显式路径缺口，已单列本场景与9条源/副本/使用情况。
