# 赤岩关防：授权留白完成，已接入主工程结构场景

用户明确回复“允许，仅增加透明留白”后，本批3图按冻结方案执行。原PNG及全部原RGBA保持，新增区域均为RGBA0，未裁/缩/旋转/清alpha。新结构场景已写入现有Godot工程，旧c版及洛阳公共运行链保持。

## 直接查看与编辑

在当前Godot工程打开 [redrock_joint.tscn](../game/scenes/drafts/redrock_joint_editor_20261023f/redrock_joint.tscn)，按F6运行。WASD/方向键移动，Tab全景/跟随，1左接缝，2右接缝，3门洞，R回起点，F2临时地面。

`Structure/LeftWing`、`Core`、`RightWing`是独立原生Sprite2D，贴图及其摆放已保存在Scene；`Collision`下7个多边形、角色35×25足底体和摄像机均可直接编辑。控制脚本不访问绝对外部路径、全局单例、存档、任务或世界路由。可在Scene根节点设置`show_ground`查看临时地面，默认关闭。

本次仅将新文件落入同一工程，没有向用户编辑器发送打开/切换标签命令，没有启动第二个生产编辑器。F5仍为既有游戏入口；F6是本独立结构草案。

![新场景原生渲染](../assets/staging/redrock_joint_editor_20261023f/validation_project/artifacts/overview.png)

## 本次精确处理

| 图 | 原尺寸 | 新尺寸 | 原图在新画布中的偏移 | 原画布内改动 |
|---|---|---|---|---|
| 核心 | 1774×887 | 2282×1141 | 254,127 | 0 RGBA字节 |
| 左墙翼 | 1536×1024 | 1976×1318 | 220,147 | 0 RGBA字节 |
| 右墙翼 | 1536×1024 | 1976×1318 | 220,147 | 0 RGBA字节 |

独立16项检查通过：旧RGBA逐字节一致、源PNG SHA保持、新区域全RGBA0、准确尺寸与完整A>0边距≥10%；最小边距11.130587%。弱alpha与隐藏RGB也保留，没有清理任何原像素。

[许可与方案SHA](../assets/staging/redrock_joint_trial_20261023e/padding-authorization.json) · [冻结原计划](../assets/staging/redrock_joint_trial_20261023e/padding-proposal.json) · [处理报告](../assets/processed/redrock_joint_trial_20261023e/processing-report.json) · [独立16项核对](../assets/staging/redrock_joint_editor_20261023f/independent-padding-verification.json)。旧计划的PREPARED字段保历史，由此次明确许可/执行记录覆盖当前状态，**本批同范围无需再问许可**。

保持核心1.2、左.771119、右1.181910的原uniform pixel scale；绘制origin减去padding_offset×scale。原画布左上角及其全部内容在世界坐标上保持，未将扩大后的整图重新fit到旧宽度。原始碰撞世界多边形不因留白改变。

## 路径和使用状态

| 内容 | 路径 | 状态 |
|---|---|---|
| Scene | `res://scenes/drafts/redrock_joint_editor_20261023f/redrock_joint.tscn` | 已写主工程；原生可编辑/F6 |
| 控制 | `res://scripts/drafts/redrock_joint_editor_20261023f/joint_preview.gd` | 仅本草案输入/摄像机/遮挡 |
| 工程5图/消费者 | [resource-pack.json](../game/art/modules/redrock_joint_editor_20261023f/resource-pack.json) | 3结构派生＋既有guard/earth副本 |
| 新3派生/原图来源 | [processed清单](../assets/processed/redrock_joint_trial_20261023e/resource-pack.json) | 仅透明padding，供本Scene |
| 原生生成提示词 | [e版队列](../assets/staging/redrock_joint_trial_20261023e/production/prompts/) | 本轮无新生图调用 |
| 试拼与接缝历史 | [e版实际试拼](redrock-joint-trial-20261023e.md) | 原图/首图/技术记录保持 |

图鉴同步新3派生、5工程副本及来源状态；图片仍可缩略/原图放大，工程复制件标“结构编辑草案·已接入工程”，不误标正式世界采用。原始3图的A1失败记录保持，合格的是新增派生。

## 实际核验与接入范围

相同res路径的独立验证工程先导入5图，只关闭本批`fix_alpha_border`/detect3D，保lossless/mipmap关闭；5图导入后全RGBA精确。没有生产全工程import、UID重建或复制文件系统数据库。

Godot4.6.2实际GPU **67项/0失败、1558次原生运动采样，自然退出0**：5图RGBA与导入参数、3原画布origin补偿、6冻结世界碰撞脚印/7原生多边形、穿门进返/5lane/4阻挡、112px待机检查员/35×25足底体、W移动及Tab/1/2/3/R/F2均通过。临时地面z=-10，确保F2显示时人物走到门后仍高于地面。

[67项结果](../assets/staging/redrock_joint_editor_20261023f/validation_project/artifacts/verification.json) · [右接缝](../assets/staging/redrock_joint_editor_20261023f/validation_project/artifacts/right-seam.png) · [门下有人](../assets/staging/redrock_joint_editor_20261023f/validation_project/artifacts/door-with-actor.png) · [native日志](../assets/staging/redrock_joint_editor_20261023f/native-verification.log)。

只发布23个新文件：5PNG、1GD/1UID、1Scene、15个新import/ctex/md5叶；另新增1份说明性资源清单。所有目标事前不存在，与验证副本逐项SHA一致。[发布清单](../assets/staging/redrock_joint_editor_20261023f/publication.json)保留完整文件路径。234项保护范围初核SHA/bytes/mtime_ns零差，包括旧c版41文件、既有配置/公共源、原图和存档。

## 保留限制

这是接入工程的**结构编辑草案**。e版两处正墙中段窄带连通，完整五锚点、墙道/垛口节奏与接缝光影仍待收尾；不授整个设计图已拼成成品。临时地面重复明显，默认隐藏，不能代表峡壁高差/内侧折返坡道；作业凹位、生活陈设与合格行走动画尚待。本Scene未加入正式世界地图或剧情旅行。
