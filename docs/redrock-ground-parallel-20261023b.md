# 赤岩关镇 · 地面补充与洛阳并行推进

最新：用户已明确允许旧12图的精确本地处理，现已执行并通过105项独立核验；详[授权处理记录](redrock-local-processing-20261023b.md)。本轮新增5图没有扩大到该许可中。下文待答/预演内容是执行前历史，原报告保留。

2026-10-23，用户要求继续改造，并询问能否和洛阳一起进行。**可以在同一项目中分场景推进**：本线继续赤岩独立资源/平面/预览；洛阳沿原对话处理，公共Field/Router、原生运行包和引擎验收分批串行接入。不在本对话重复洛阳性能测试，也不宣称洛阳已经完成。

## 本轮已制作

![地面与组件联系表](../assets/previews/redrock_ground_resources_20261023b/ground-components-contact.jpg)

| 资源 | 原图路径（仓库根目录起） | 当前使用情况 |
|---|---|---|
| 细夯土地表 | `assets/raw/redrock_ground_resources_20261023b/ground/redrock_20261023b_earth_v1.png` | 1254² RGB，不透明候选；重复铺贴可辨，未认证无缝 |
| 裸岩地表 | `assets/raw/redrock_ground_resources_20261023b/ground/redrock_20261023b_rock_v1.png` | 1254² RGB，不透明候选；层理较强，需结合尺度与过渡验收 |
| 缓坡接道 | `assets/raw/redrock_ground_resources_20261023b/building/redrock_20261023b_ramp_v1.png` | 1586×992 RGBA；形制候选，尚未匹配关口高差/朝向/通行面 |
| 低石护栏 | `assets/raw/redrock_ground_resources_20261023b/building/redrock_20261023b_rail_v1.png` | 1774×887 RGBA；独立直段，转角/连续防坠/净高未接 |
| 第4下行帧脚锚修版 | `assets/raw/redrock_ground_resources_20261023b/npc_walk/redrock_20261023b_guard_footfix_v1.png` | 1254² RGBA，原第4帧的定点编辑；旧帧保留，未接运行atlas |

5图均内置imagegen，每ID1次，无CLI或自动重试；原PNG与内置源逐SHA相同，未本地修改。具体model/provider/cost未披露留null。[完整清单](../assets/raw/redrock_ground_resources_20261023b/resource-pack.json)及逐图meta保留来源和提示词。

关卒新第4帧与旧1–3帧合用时，显著轮廓诊断（alpha128，仅观察）高度差从26降至10原像素，脚底差从27降至12。新帧最低显著像素1107仍未达到提示词1115–1119的目标；只授改善，不冒目标精确命中/动作稳定。[原始四帧查看GIF](../assets/previews/redrock_ground_resources_20261023b/guard_walk_down_footfix_raw.gif)统一缩小整画布，未逐帧fit/平移；经过相位仍待复核。

地表做了[夯土3×3查看](../assets/previews/redrock_ground_resources_20261023b/earth-3x3-check.jpg)和[裸岩3×3查看](../assets/previews/redrock_ground_resources_20261023b/rock-3x3-check.jpg)。左右/上下边RGB平均差分别约17.32/16.89和15.18/14.36，高于部分内部邻差；重复纹理块仍可辨，不能因为prompt写seamless就授无缝。坡道/护栏/修版人物的完整A>0四边10%留白仍待，不将不透明地表套用透明留白指标。

## 并行隔离

本批出图队列放在独立工作区：`assets/staging/redrock_gate_20261023b/production/prompts/tasks.yaml`，模板与完整提示词也在同目录。调用项目renderer时仅在本进程内指定该工作区模板目录，原`gen_assets.py`和工程根`prompts/tasks.yaml`未改，避免洛阳运行时的来源守卫受共享任务表变化影响。

本批不写`game/`、`.godot`、原生包、存档或操作用户进程，不要求关闭编辑器。图鉴/复用文档由本线同步自身资源；后续正式接入须明确当前生产来源与单写范围，不能用“同时做两城”扩大到任意公共源。并行规则依据`docs/agent-workflow.md`第7节，不另建聊天、不擅自向其他聊天发消息。

## 门洞与透明留白：原精确方案与执行前预演

原加宽门的声明开口矩形内352个非零alpha像素，实际直方图为alpha1×338、alpha2×13、alpha3×1。拟仅把这些alpha置零，保全部RGB、石墙/木门与其余RGBA字节。另给**原批当前12张候选**增加纯透明边距，完整原画布放到新画布指定offset，不裁切、缩放、调色或擦背景；本轮新增5图不擅自扩入该授权范围。

[精确来源与处理范围](../assets/staging/redrock_gate_20261023b/local-processing-proposal.json) · [预演报告](../assets/staging/redrock_gate_20261023b/local-processing-dry-run.json)。预演已核12原图SHA、保护区域、352精确差量及派生完整A1留白；**仅在内存模拟，0派生PNG落盘**。处理脚本`process_redrock_local_proposal_20261023b.py`默认dry-run，执行参数不会自行启用。

原先通过异步问题请用户选择本地处理或继续只用生图工具。用户现已明确选择允许精确范围，执行和保护证明单列在最新记录；无需再询问同一范围。此前确认原因是image_gen工具默认编辑方式限制，不是洛阳并行的技术障碍。

## 当前边界与下一步

新增5候选可在[资源图鉴](equipment-skill-catalog.html#resources)按“赤岩关镇”查看，来源与实际使用状态同步复用索引。原批13图、当前12候选和本轮5张分别记账，不覆盖旧失败或冒整镇完成。

本轮[43项文件与隔离核验](../assets/raw/redrock_ground_resources_20261023b/verification.json)通过：5张原图/内置源/meta/prompt/ref同、图鉴5条与原图/缩略图链接齐、原旧记录及非resources JSON不变、独立队列5条唯一skip、工程根tasks首末SHA相同、0本地派生图落盘。[离线筛选/预览入口](../assets/raw/redrock_ground_resources_20261023b/gallery-functions.json)通过，非浏览器实点。图鉴现4775文件/2468图像/2307音频，复用索引1768份文本扫描期间稳定、0显式路径缺口。文件核验不等美术或运行准入。

先落实门洞处理方式与稳定脚锚，再统一地表尺度、坡道接口和护栏高度，形成峡口第一分区的可审核装配；正式导航/碰撞/NPC交互另验。当前未做原生引擎、全城加载或洛阳实机复验。
