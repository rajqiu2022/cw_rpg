# 赤岩三块关防：实际试拼

**当前进展：本批3图仅透明扩画布已获用户明确许可并执行，16项原RGBA核对通过；f版独立原生结构Scene已写主工程。** 详[透明留白与工程场景](redrock-joint-editor-20261023f.md)。下方“许可待答/未导入game”是e版只读试拼当时状态，同范围不再重复询问；原PNG失败记录保持，新增派生通过留白。

用户已确认d版设计“可以”，并要求尝试拼接。本轮按该方向新做3张原生模块，在独立Godot场景完成了实际拼接和穿门试走。**这是结构试验，不是完整城市场景，也没有恢复用户否定的c版。**

![三块结构实际渲染](../assets/staging/redrock_joint_trial_20261023e/trial_project/verified_artifacts/overview.png)

## 现在接成了什么

左岩肩与墙翼 → 连体岗楼/门关 → 带转折的右墙翼与岩肩。岗楼、门墩和门梁在核心原图中已是连续建筑，不再靠另一张独立岗楼靠拢。两翼各包含完整的墙接岩体关系，主要现场接口缩减为左右两处。

| 模块 | 原PNG路径 | 尺寸 | 实际消费者 |
|---|---|---|---|
| 连体关楼核心 | [core](../assets/raw/redrock_joint_trial_20261023e/building/redrock_joint_20261023e_core_v1.png) | 1774×887 RGBA | 隔离Scene的`Structure/Core` |
| 左墙翼接岩肩 | [left](../assets/raw/redrock_joint_trial_20261023e/landform/redrock_joint_20261023e_left_v1.png) | 1536×1024 RGBA | `Structure/LeftWing` |
| 右转墙翼接岩肩 | [right](../assets/raw/redrock_joint_trial_20261023e/landform/redrock_joint_20261023e_right_v1.png) | 1536×1024 RGBA | `Structure/RightWing` |

3张各一次内置imagegen调用，原PNG保持完整，未裁切、清alpha、镜像或改像素。左右墙翼生成时同时参考已确认设计和核心实图；独立队列登记/dry-render通过，根任务清单未写。模型/供应方/费用不可见，元数据保持null。

## 接口怎么适配

核心统一像素scale=1.2。左翼以核心左侧约178源像素高的墙面配277源像素，等比scale=0.771119；右翼以196配199，scale=1.181910。只用等比缩放与平移，无旋转/非等比拉伸。前沿地脚保留12/16世界像素接合余量，原图完整端段在共有截面内交叠。

这次先测量前地脚与墙道前沿两个锚点，不能宣称完整五锚点接口已认证。右侧首试露出较突出的核心端面；对比两种原生绘制顺序后，采用右翼前置，保留两种实图，不修改PNG以掩盖问题。

[左接缝实图](../assets/staging/redrock_joint_trial_20261023e/trial_project/verified_artifacts/left-seam.png) · [右接缝实图](../assets/staging/redrock_joint_trial_20261023e/trial_project/verified_artifacts/right-seam.png) · [接口坐标/尺度](../assets/staging/redrock_joint_trial_20261023e/interfaces.json)。两接缝正墙中段12px宽、中央半高条带按0.5px采样：左5136点/右5664点，强alpha≥128的结构合成无透空。**该小条带不检验墙道全宽、垛口节奏、光影、整图或正式导航。**

## 原生检查与查看

隔离工程：[project.godot](../assets/staging/redrock_joint_trial_20261023e/trial_project/project.godot)；场景：[trial.tscn](../assets/staging/redrock_joint_trial_20261023e/trial_project/trial.tscn)。可打开这个独立工程查看/F6运行；不会替换主工程入口。场景脚本为`@tool`，读取项目中固定原PNG，建立ImageTexture供原生Sprite2D显示，不走生产PNG导入。

WASD/方向键移动，Tab全景/跟随，1左接缝，2右接缝，3门洞，R回起点，F2临时地面。默认隐藏临时地面，便于只看建筑结构。临时走域与土纹重复镜像明显，不作为正式地形；没有伪造峡壁高差或完成内侧坡道。

实际Godot4.6.2原生GPU检查**34项/0失败，自然退出0**：3模块原始像素到ImageTexture字节一致、无旋转/拉伸、完整35×25角色体、穿门/返程、5条门道、4组墙/门墩阻挡、门下淡出、W注入移动。运动采样1558次。角色视觉112px，复用既有匿名关卒待机，仅为尺度检查，平移不算行走动画。

[原生检查JSON](../assets/staging/redrock_joint_trial_20261023e/trial_project/verified_artifacts/verification.json) · [门下有人实图](../assets/staging/redrock_joint_trial_20261023e/trial_project/verified_artifacts/door-with-actor.png) · [源保护/墙面条带核对](../assets/raw/redrock_joint_trial_20261023e/assembly-review.json)。191保护文件SHA/bytes/mtime_ns初核零差，包含工程配置、autoload/Field、存档、根tasks和设计图。未操作现有editor51856。

首运行`const PackedVector2Array`不符合该GDScript常量表达式要求，原脚本/日志保留；只中断本轮错误停驻的自有进程，未碰用户编辑器。改为实例var后捕获/层次对比/原生核验均自然0。首土纹地面版本和右端面突出版本保留在`first_artifacts`、`structure_artifacts`，不当最终场景推荐。

## 留白与主工程接入

3图完整A>0边距仍FAIL，不能因结构试拼连通就降低10%门槛。左/右查看器中部分棕色背景实际alpha0；原生合成正确消隐，不能凭隐藏RGB误判为实底再擦图。

已准备本批独立的**仅增加透明画布**方案：核心1774×887→2282×1141（offset254,127），两翼各1536×1024→1976×1318（offset220,147）；全部旧RGBA连同弱alpha/隐藏RGB保持，不裁/缩/清理。[具体计划](../assets/staging/redrock_joint_trial_20261023e/padding-proposal.json)已冻结脚本与来源SHA。旧12图许可不覆盖本批，已另问用户，未获本批同意前不执行。处理后保原pixel scale并减pad×scale补偿绘制origin，不能重新fit整张大画布而缩小建筑。

当前未正式导入game、未覆盖生产Scene或旧PNG，也没启动第二个生产编辑器。后续还要：完整五锚点、墙道/垛口和接缝光影收尾；主工程新场景接入；与设计相符的峡壁、折返层台、作业凹位；合格行走序列。本轮结构连通不等于这些全部通过。

[三图收据](../assets/raw/redrock_joint_trial_20261023e/manifest.json) · [完整提示词目录](../assets/staging/redrock_joint_trial_20261023e/production/prompts/) · [设计确认记录](../assets/raw/redrock_joint_trial_20261023e/selected-design-authorization.json)。

图鉴已新增3原图并按核心建筑/墙翼岩肩分类，可查看缩略图/原图；设计图状态同步为已确认试拼中。11项离线核查通过，非resources保持，现4800文件/2493图/2307音；无浏览器点击实测信用。复用索引1774文本来源扫描期间稳定，141场景/0显式缺口。
