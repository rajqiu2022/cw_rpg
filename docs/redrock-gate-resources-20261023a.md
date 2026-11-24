# 赤岩关镇01 · 峡口关门首批制作

后续状态：用户已允许原批当前12图的精确本地处理，[透明留白派生及门洞定点清理](redrock-local-processing-20261023b.md)已执行、105核验过。下文13原始PNG的失败与原始收据保持历史，不回写为原图已通过；新派生仍未接入游戏。

2026-10-23，用户指定[赤岩关镇总览](../assets/raw/sect_western_map_designs_20261022d/redrock_masterplan_overview_v1.png)开始制作。本次以它为制作方向，先做入口分区；西域地名仍为设计暂名，未创建正式场景或命名NPC。其余三套设计不继承本次选择。

**已生成13张原生PNG：12当前候选＋1门洞不足首稿。** 当前候选为4件建筑/墙体、2件场景实体、关卒1待机＋4下行帧＋1同人立绘。候选不等于正式可用，透明留白、门洞与行走限制见下文；未装配成可玩镇图。

![当前六件地图组件](../assets/previews/redrock_gate_resources_20261023a/current-modules-alpha-contact.jpg)

## 分区设计先行

依据洛阳总规流程，先做尺寸平面和用途关系，再生组件。工作平面2560×1920、成人可视约112px、身体35×25像素检查；主路与门洞目标320，侧步道128，货物支路180。数值由本分区拟定，未从概念像素裁量，也未改变已有游戏角色碰撞。

南来驿道→关门→关内北侧分流点→东北阶街接口，另留东侧服务回路。关卒站在门前左侧，货包和饮水槽在路肩。关门去掉中原瓦檐，用厚石两墩、平顶雉堞与木过梁；岗楼也是平顶，保红砂岩峡镇识别。正面墙与纵深侧墙分别生成，不能旋转图片冒深度。

[当前revision2尺寸平面](../assets/staging/redrock_gate_20261023a/revision2/district-footprint-plan.png) · [坐标合同](../assets/staging/redrock_gate_20261023a/revision2/district-plan.json) · [几何检查](../assets/staging/redrock_gate_20261023a/revision2/geometry-check.json)。4拟定路径1596个完整身体点、10条完整宽带、320门洞目标空带通过；非门户通道避开拟定建筑可视包络。只是作者矩形几何，**没有生成图门洞、导航、引擎Physics或正式通行信用**。

首预检货包侵入支路被拒，旧脚本保留；目录已存在导致第二次预备未执行亦保留事实，无生图重复。初版虽地脚通过但北侧分流处在关门可视包络内，已保历史，revision2把分流移到北侧可视包络外，岗楼及其步道同步向西调整。所有旧文件不覆成“已通过当前图”。

## 分类路径与当前使用

统一原图目录：[assets/raw/redrock_gate_resources_20261023a/](../assets/raw/redrock_gate_resources_20261023a/)。[README逐图表](../assets/raw/redrock_gate_resources_20261023a/README.md)和[完整机器清单](../assets/raw/redrock_gate_resources_20261023a/resource-pack.json)列每张PNG、提示词、来源图、SHA、尺寸和状态。

| 类别 | 目录 / 当前文件 | 用途与状态 |
|---|---|---|
| 建筑/墙体 | `building/`：`redrock_20261023a_gate_opening_v1.png`、`redrock_20261023a_tower_v1.png`、`redrock_20261023a_front_wall_v1.png`、`redrock_20261023a_side_wall_v1.png` | 加宽关门、平顶岗楼、正面墙、纵深侧墙；4当前候选，待图像尺度/地脚/门洞/接缝适配 |
| 保留首稿 | `building/redrock_20261023a_gate_v1.png` | 原关门门洞不足，不作为当前选择；保留生成与失败记录 |
| 场景/大世界实体 | `scene_prop/redrock_20261023a_cargo_v1.png`、`redrock_20261023a_trough_v1.png` | 驿道货包组、石制饮水槽；是场景摆件，非背包图标；未配置任务、拾取、奖励或碰撞 |
| 地图待机 | `npc_sprite/redrock_20261023a_guard_idle_v1.png` | 匿名关卒造型源；地图俯视全身图，不是对话立绘，未创建正式NPC_ID |
| 地图行走 | `npc_walk/redrock_20261023a_walk_f01_v1.png`至`redrock_20261023a_walk_f04_v1.png` | 4张1254²独立原生下行帧，待机同人参考；未做合格运行atlas或四方向 |
| 同人立绘 | `portrait/redrock_20261023a_guard_portrait_v1.png` | 引用新待机身份的1024×1536全身立绘，独立于地图精灵计数 |

![关卒身份与原始帧对照](../assets/previews/redrock_gate_resources_20261023a/guard-identity-raw-frames.jpg)

[原始四帧播放](../assets/previews/redrock_gate_resources_20261023a/guard_walk_down_original.gif)只统一缩小整画布供查看，未做逐帧bbox适配或脚底平移，原始漂移可见。头像、立绘和动作不互计完成数量。

## 图像复核与限制

- **全部13张完整A>0四边10%透明留白未通过**。均有真实RGBA/0–255 alpha，但完整弱alpha范围延到边缘；没有以alpha128替换准入阈值，没有本地清边、裁图、扩画布、改色或修改原图。
- 模块经真实alpha合成查看，查看器显示的红/棕晕色可能包含隐藏RGB，不能仅凭黑底查看器判断有不透明背景；完整alpha失败仍保留，二者分别记录。
- 关门首稿在1160全画布显示宽度下，六条真alpha0中心截面约136–306px，不符合320目标。一次另登记定点编辑生成加宽版，首稿不覆。
- 加宽版六截面约314–353px，前五条大于320，门底最后一条仍约314；声明矩形`[570,450,1008,700]`内有352个非零alpha像素。**不能把几个宽截面当整个连续门洞通过**，也不能为过检直接放大关门挤占预留步道。
- 平顶岗楼形制符合方向，但成人门和拟定240脚印的实际适配未认证；正/侧墙砌块密度、斜向基脚、转角接缝也未做图像映射，不提前给可进入/无缝拼接结论。
- 关卒帽、短袄、胡须、腰包整体同人可辨；腰包侧沿实际图一致，不把文本指定方位冒成已精确命中。没有沿用概念里的包头造型。
- 四张下行帧可辨两侧脚接触与相反摆臂，经过相位仍偏弱；显著轮廓诊断（alpha128，仅观察）高度差26px、底边差27px，衣摆与身体也有变化。未授稳定循环、8相动作、四向、待机动画或正式SpriteFrames通过。

[首次技术观察](../assets/raw/redrock_gate_resources_20261023a/technical-review.json) · [加宽关门观察](../assets/raw/redrock_gate_resources_20261023a/gate-opening-review.json)。原A1、几何与相位问题不通过命名、缩略图或文件数消除。

## 图鉴与复用

[equipment-skill-catalog.html](equipment-skill-catalog.html#resources)按“赤岩关镇 / 建筑与墙体、场景与大世界物件、地图待机、地图行走原生帧、同人立绘”5组登记。13张均有缩略图和原图放大入口；原关门首稿标保留，第一张行走卡附原始播放。完整路径与使用状态同步[复用索引](resource-reuse-index.md)。既有浏览器file策略拒绝保持，本批仅离线解码/路径/函数核对，不冒浏览器点击验收。

全部13调用走内置imagegen，每ID1次，无CLI或自动重试；加宽版是记录失败后单独登记的一次定点编辑。工具未披露model/provider/cost，元数据留null，不虚称具体模型。原图复制入项目，与内置源逐SHA相同；[提示词目录](../prompts/redrock_gate_resources_20261023a/)和逐图meta保完整血缘。

[文件核验91项通过](../assets/raw/redrock_gate_resources_20261023a/verification.json)，范围为13原图/内置源/meta/prompt/reference、真实RGBA解码、缩略图/路径、唯一skip任务与旧队列前缀、原始GIF四帧、图鉴状态和脚本语法。旧四类及全部非resources数据相同；除新增13条外，旧行仅赤岩总览的statusLabel/note按用户选择更新。图鉴现4770文件/2463图/2307音频，资源本批5组；[离线筛选/卡片入口](../assets/raw/redrock_gate_resources_20261023a/gallery-functions.json)通过。文件核验不覆盖上文失败的美术准入，不能报告整区可用。

离线卡片检查首断言误认为全部卡片都把缩略图作为`img.src`，在行走卡失败；既有实现实际采用`animationPreview || thumbnail`，原FAIL另存`gallery-functions-first-fail.json`。后继只纠正检查的取源预期，应用代码不改；PNG原图入口及独立缩略图解码仍由原91项核验覆盖。

## 待办

先解决关门完整净口、组件边缘及固定尺度/脚锚，再按地脚与可视包络装配峡口分区，补红岩地形、贴地道路与崖边护栏；合格后才增加关卒交互和正式导航。当前没有运行引擎，也没有写`game/`、`.godot`、存档或控制洛阳编辑器/其他对话进程。

后续阶街民巷→驿舍马院→石作修坊→蓄水小院→高台望关逐区推进，民居/驿舍等尚未制作，不把本批墙和岗楼冒整个镇建筑齐套。敌人普通/野外高品质精英/剧情Boss按已有身份分开；本入口首批未新增敌人、任务和数值，不私造剧情Boss。
