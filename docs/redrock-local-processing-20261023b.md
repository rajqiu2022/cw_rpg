# 赤岩关镇 · 12张候选的授权本地处理

2026-10-23，用户明确回复 **“允许按这个精确范围处理”**。现已执行原批12张候选的透明留白，以及关门指定区域352个弱alpha像素的定点清理。不是新生图，原PNG不覆盖，新增12张派生PNG，均未接入游戏。

![处理后组件查看](../assets/previews/redrock_local_processing_20261023b/authorized-modules-contact.jpg)

## 执行范围

源文件逐一锁SHA，范围仅为[精确方案](../assets/staging/redrock_gate_20261023b/local-processing-proposal.json)列出的旧批当前12图：岗楼、正/侧墙、货包、饮水槽、关卒待机、旧4张下行帧、同人立绘、加宽关门。关门首稿和b批5张新图全部排除。

每图只在四周增加全RGBA为0的透明区域，将完整旧画布原样放到指定offset，未缩放、裁切、旋转、调色或清除外缘旧弱alpha。关门在旧坐标`[570,450,1008,700]`内，仅把352个非零alpha设为0：alpha1共338、alpha2共13、alpha3共1；这些像素RGB仍保留。区域内外所有其他RGBA以及石墙/木门alpha≥4像素均逐字节不变。

[人类许可记录](../assets/staging/redrock_gate_20261023b/local-processing-authorization.json)绑定方案与处理脚本SHA，原方案及原dry-run保历史。[实际处理报告](../assets/processed/redrock_gate_20261023b/processing-report.json)列12张输出、尺寸、偏移和差量。

## 独立核验结果

[105项独立检查](../assets/processed/redrock_gate_20261023b/independent-verification.json)全部通过：

- 12张输出均真实RGBA，原画布RGB完全相同；全批只有指定352个alpha字节变化，其余全部RGBA不变。
- 新画布的旧画布以外区域全部RGBA为0；按完整A>0包围盒计算四边留白全部≥10%，最小约11.1178%。没有换alpha阈值洗通过。
- 原18张PNG（a批13+b批5）及工程根任务表的SHA/字节/mtime_ns均与执行前相同；无新生图、任务追加或用户进程操作。
- 关门声明438×250原像素矩形现**全部alpha为0**；按旧全画布1160世界宽的同一比例，相当于约320.56×182.97世界像素的透明图像区域。
- 保同一个原像素缩放量、补偿新增画布offset后，原内容点的世界坐标等价；这个检查仅是摆放数学，不是引擎Physics验收。

## 路径与当前使用

派生图统一存于 [assets/processed/redrock_gate_20261023b/](../assets/processed/redrock_gate_20261023b/)。[README逐图表](../assets/processed/redrock_gate_20261023b/README.md)列原图/派生图完整路径和状态，[机器清单](../assets/processed/redrock_gate_20261023b/resource-pack.json)列全部SHA、尺寸、source_offset及许可来源。[资源图鉴](equipment-skill-catalog.html#resources)新增12条“透明留白派生”，保留原图记录；可按赤岩建筑、场景实体、待机、行走、立绘5类查看缩略图与放大。

[图鉴42项核对](../assets/processed/redrock_gate_20261023b/gallery-verification.json)与[离线筛选/放大入口函数](../assets/processed/redrock_gate_20261023b/gallery-functions.json)通过；12派生路径、缩略图和5分组齐，状态均为未接入。旧资源行、装备124/招式67/任务126/故事8及全部非resources数据保持，图鉴现4787文件/2480图像/2307音频；复用索引1769文本扫描期间稳定、0显式路径缺口。未进行浏览器实点验收。

| 类别 | 数量 | 当前状态 |
|---|---:|---|
| 建筑与墙体 | 4 | 留白通过；成人门尺度、脚印与接缝待适配 |
| 场景/大世界物件 | 2 | 留白通过；摆放尺度/交互与碰撞待接 |
| 关卒地图待机 | 1 | 原身份像素保持；未正式绑定 |
| 旧下行原始帧 | 4 | 只增加留白，原相位/脚底漂移没有修复 |
| 同人立绘 | 1 | 原全身像素保持，未加入正式对白 |

## 摆放时保主体大小

新增画布后若仍把“整张PNG”fit到旧宽，会把石墙和人物缩小。必须保原uniform scale，并令`new_draw_origin = old_draw_origin - padding_offset × old_scale`。旧画布在派生图中的区域是`source_canvas_rect`，详[摆放合同](../assets/processed/redrock_gate_20261023b/placement-contract.json)。

例如关门原画布1585×992，派生2039×1276、offset227×142。若原全画布显示宽1160，仍保`scale=1160/1585`，新画布显示宽约1492.26；增加的空间是透明留白，旧内容世界大小不变。这个1492不是授权把实际关门变宽，也不扩大可见建筑预留或物理门洞。

## 尚未解决的边界

门洞这次只清空明确批准的矩形，未动更低处形制与门叶：原y740截面约313.97px仍保持，不能据区域通过冒整个连续门户320通过。该矩形与玩家脚位/前后遮挡关系还需分区映射。岗楼成人门尺度、正侧墙接口也未因此合格。

透明留白不修复衣摆、身高、步态或脚锚；旧4帧仍保26/27px诊断差，新b批第4帧修版仍独立保留且未处理。b批坡道/护栏的完整alpha边距及两地表无缝问题，也不在这次许可中自动解决。

本次不写`game/`、`.godot`、存档或根任务表，不导入、不运行引擎、不改变洛阳正式来源或控制用户进程。接下来按已授权的改造范围，做派生组件的尺度/落脚/接口适配，再进入峡口首区装配；不得把12张派生数量当整镇已完成。
