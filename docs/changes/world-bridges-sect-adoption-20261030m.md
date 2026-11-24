# 2026-10-30m 大地图五桥重做与门派采用诊断

状态：桌面大地图五桥已正式替换并交用户验证。Root实际125256自然0、184检查0错误、454条真实输入、5正常桥图亲看，原88桥体精同；停止本批复测。武当、华山本轮只读诊断，采用待用户确认；凌月内庭不是现成新版漏接。

## 范围

- 当前桌面World15确有5桥、93原视觉组件、88原实体组件，不拿旧17桥记录当本次清点。
- 新外观：00/02/04石桥、01/03木桥；00—03采用V1，04采用V4。只等比缩放与轻微旋转，无像素拉伸。保留原道路、NAV、实体、World入口、业务与存档。
- 仅改两旧GD：`game/scripts/world/world_v15_visible_stream_20261018r.gd`、`world_v15_stream_overlap_20261018r.gd`；独立helper、GPU分区与五图binding在新专域。Web仍原fallback，不冒已改Web。

## 美术来源和文件

本轮全部使用内置imagegen；无CLI/API回退，工具未披露的model/provider/cost均为null。

- 原图：[assets/raw/world_bridges_20261030m](../../assets/raw/world_bridges_20261030m)
- 正式候选五图：[game/art/modules/world_bridges_20261030m](../../game/art/modules/world_bridges_20261030m)
- 完整prompt/tasks：[production/prompts/tasks.yaml](../../assets/staging/world_bridges_20261030m/production/prompts/tasks.yaml)，模板同production/templates。
- 每任务仅一次内置调用。00—03各1次；04先V1、V2、V3比例被拒，V4最终；V5是灰雾误判引起的多余背景编辑，未采用，弃用记录保留。总9次调用，不伪报仅5次。
- 仅框外alpha1→0和256px全透明补白：00—03为160/238/116/1005像素，04V4为170。原RGB含隐藏RGB、主体RGBA、所有alpha≥2像素完整保留，RAW不改。
- V4查看器灰雾经大区和逐点检查是alpha0隐藏RGB，不能因此去背景或改原RGB。maxAlpha254保留，未归一为255。
- 精来源：[selected_five_V4_SOURCE_READY.json](../../game/build/world_bridges_20261030m_art01/selected_five_V4_SOURCE_READY.json)，手量仅参考、不冒碰撞或Physics PASS。
- 5PNG隔离导入自然0，仅15新叶；`process/fix_alpha_border=false`，mipmap0/lossless，不能仅据存在即宣称decodedRGBA相同。

## 门派诊断

武当`openworld_wudang_gate`、华山`openworld_huashan_forecourt`仍走普通Field和sect_maps_v5旧整图；现成可运行室外草案分别是`sect_maps_20261029k/wudang.tscn`、`huashan_map_20261029m/huashan.tscn`，未进正式registry。用户记得已制作属实，但不等于业务接线已完成。

截图二明确是“凌月派 · 内庭”：外门30a已native采用，原`openworld_lingyue_inner_court`仍旧背景，未发现可一行接入的现成新版内庭。两草案控制器没有现有SectField调用的`examine()`，不得只塞路径冒完成；须原NPC/出入/返脚/旧UV适配。

详[只读诊断](../../game/build/sect_adoption_20261030m_audit01/DIAGNOSIS.md)。本轮未改门派入口、NPC、任务或原内区。

## 保护和未完成

171真实存档只核SHA/bytes/UTCticks，从不反序列化/写入/恢复。首capture误将seed中9个exists=false的合法缺省路径当missing，wholeFAIL保；独立残余证162present+9absent共171同首、0错误。两历史差异继承用户前批合法save0/bak更新，不回滚。

首次import_decode实际61/1、自然1，停于尺寸比较，原报告保留；02实际100424自然0、32/0，逐值尺寸与全RGBA8一致，确认JSON浮点Array与整型Array整体比较误判。5Texture实解码逐RGBA字节与源PNG完全相同，mip0；两个候选与helper解析过。原7退出ERROR与ObjectDB历史警告不洗。用户编辑器51856保留，仅Root自有导入/有限验证进程。

## 正式收口

正式stream `2A7BC5BA`、overlap `5803CDAF`、helper `9462EC32`、binding `DCCAEA88`；原layout/Field/Router/native/registry/project无写。93视觉退绘为5图共20同源分层，旧实体88完整保留。索引区分稀疏新array index与原depth ordinal；同源纹理驻留仅计一次且最后引用退出扣账，压力驱逐后再重算，256MB/1024对象上限不改。

首World 128880在加载阶段75秒41/1、0INPUT保。诊断134624自然1、6/1精定位`INPUT_BRIDGE_ROW:bridge_01_bridge_post3`：原素材JSON与正式TRES的8个depth浮点序列化不完全同（例如0.193575918674469与0.19357592）。固定原layout SHA，从TRES精提取1302字段为新`bridge_source_rows_LAYOUT_TYPED_03_READY.json`；向量/实体零差，严格匹配函数原封，无epsilon、无关guard。原素材证JSON不改。必要helper路径/SHA、binding和stream头精后继后，125256才通过；旧FAIL不改PASS。

- [五桥实机结果](../../game/build/world_bridges_20261030m_qa01/world5_startup03_actual/125256/result.json)：公开真World进入一次，其余为同一自有MainField五个局部setup，不冒连续大地图旅行。每桥真实WASD过两端、旧rail圆5负控压力、3个新图source像素的GPU/CPU前景分区与共享纹理、旧88实体和所有其他row索引原样；末重访只证release/revisit，不冒自然1024滞回压力全验。
- 五张原生正常图均Root亲看：[00](../../game/build/world_bridges_20261030m_qa01/world5_startup03_actual/125256/bridge_00_normal_center_rail.png)、[01](../../game/build/world_bridges_20261030m_qa01/world5_startup03_actual/125256/bridge_01_normal_center_rail.png)、[02](../../game/build/world_bridges_20261030m_qa01/world5_startup03_actual/125256/bridge_02_normal_center_rail.png)、[03](../../game/build/world_bridges_20261030m_qa01/world5_startup03_actual/125256/bridge_03_normal_center_rail.png)、[04](../../game/build/world_bridges_20261030m_qa01/world5_startup03_actual/125256/bridge_04_normal_center_rail.png)。桥头/地板方向与人物比例交用户细看，不授水体/河岸或整World艺术完成。
- [末保护](../../game/build/world_bridges_20261030m_qa01/final_guard03_ACTUAL.json)：600原源只两授权差、171save精SHA/bytes/UTCticks同首、26新资源pin、0并行差/0外差，仅editor51856；原9缺省与两历史save差独立保留。
- 图鉴5234→5253：9RAW+5processed+5game、19新缩略；4弃用版本零消费者。最终15所选来源`currentBindingSHA256`精同步DCCA，旧5234和非resources/cache原封，见[图鉴精证](../../game/build/world_bridges_20261030m_art01/catalog19_binding03_FINAL_PROOF.json)。

待办仅门派：若用户确认采用武当/华山室外草案，新增独立适配器保原NPC、任务、下山/内区与返脚；凌月新版内庭属另一个明确实施范围。本轮不把它们列已接入，不重复五桥成功检查。
