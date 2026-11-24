# 2026-11-01b 场景质量纠偏与同类检查（有限收口交试玩）

状态：**本批已正式接入并有限收口交试玩。坐客快速转向局部已修；怡红院挂饰/红毯氛围及三片区地面材质/边接口获Root有限接受，整体设计与用户接受未授。** 首轮91364及后继95060的地面ART拒保留；最终04/44444只验地面89检查0错/0输入、19106ms，console11912自然0，三正常图Root亲看。最终有限保护87056F24通过，不声称全部场景已改好；下文首拒/文档阶段为历史。

## 用户反馈与当前范围

1. 怡红院接待/雅座：通用客栈木厅、普通桌/酒架不能只靠改名表达场所身份；两坐客来回转向太快。
2. 洛阳宅园**室外**：大面积青石粒度过大、石/粗泥硬矩形切边、门外细碎石另成接片，材质与院落空间不协调。不是29p会客厅墙shader/露底的同一问题。
3. 用户要求掌握项目本地质量规律，主动按同类原因检查，不能等逐个截图后再零散补丁。

本次制作前置：[S01–S07质量标准](../scene-art-quality-standard.md)；当前与历史范围：[缺陷登记册](../scene-art-defect-register.md)。YIH-02（坐客方向循环）仅本轮局部关闭；YIH-03（空间身份）、EST-04（宅园具体地面材质/边接口）为局部改善/待用户接受，不整体关闭所有硬边或整个场所。旧29n/29p局部信用与本次早期新否决都保留。

## 两张用户原图的持久证据

归档路径在 `docs/assets/scene-quality/20261101b/`，通过原文件复制，不经图像工具重采样或编辑；源附件保持不动。复制后独立核对各自源/目标SHA256和字节数一致。

| 图 | 原附件来源 | 持久证据 | bytes / SHA256 |
| --- | --- | --- | --- |
| 怡红院 | `C:/Users/rajqiu/AppData/Local/Temp/codex-clipboard-765763b4-50ea-4ab6-aed9-12a08c67f6c0.png` | [原始截图](../assets/scene-quality/20261101b/user-yihongyuan-hall-rejected.png) | 5560548 / `92a9b968b024a929274302904334ea7eb2c621a5de108e7673d0a2d64ac00197` |
| 宅园室外 | `C:/Users/rajqiu/AppData/Local/Temp/codex-clipboard-49858f6a-fdd1-4b7d-b764-f2280c7cb219.png` | [原始截图](../assets/scene-quality/20261101b/user-estate-ground-rejected.png) | 10778389 / `315b3897f386271881cc0ce9cbb3c33d9ecaf408f9a1941b03a1070f8b74b66a` |

图能证明构图、地面、家具与当前静态姿态，不能独自证明动画周期、功能进返或修改结果。坐客转向速度来自用户动态反馈，并有以下只读代码原因支持。

## 已核事实与待验证假设分开

- 已看两张用户原图：坐客确有坐姿，不能误诊为只有站姿；怡红院与宅园的问题分别定位到场所身份/动画语义及室外地面。
- 修前只读核对 [NPC播放路径](../../game/scripts/field/npc_node.gd)：默认`IDLE_FRAME_SECONDS=0.28`，横条按宽高确定hframes，通用`_process`推进帧时未因`movement_mode=seated`自动停播。[怡红院作者](../../game/build/luoyang_yihongyuan_20261029n_system01/room_factory.gd)对末两客人设置seated。四帧默认一轮1.12s是静态推导，不冒修前实机计时。当前独立显示后继的稳定性见91364实际检查，不改写旧问题。
- 方向strip不应当呼吸动画循环；实施方案须分开“朝向选择”和“同方向动作相位”。仅把.28s改慢仍不能消除错误语义；也不能未看源帧就为全部NPC改共享播放器。
- 地面同类检查须沿真实现役作者/helper和实际消费者列有限名单，核纹理粒度、UV相位、软硬过渡与门外接驳；一次宅园截图不能推出其他所有地图都同样失败或均已修复。
- 素材准备/候选代码、文档通过或历史技术PASS本身不计正式接入/视觉完成；本轮只给下方实际现役证据覆盖的有限范围信用。

## 本次文档与证据改动

- 新增 [场景质量标准](../scene-art-quality-standard.md)：用途设计先于摆件，成人/净门、完整原生形体、地面、围合门路、姿态方向、遮挡及正常镜头七类门禁；一轮基线、按原因成组、比例适当的有限QA及记录模板。
- 新增 [缺陷登记册](../scene-art-defect-register.md)：当前已拒、历史局部已修、已知残余、缺证据待核分开，不把旧问题或旧接受历史重写。
- 在根 `AGENTS.md`、[进展快照](../current-progress.md)、[经验日志](../experience-log.md)头部增本阶段入口，既有历史条目保持。
- 新增上述两张原字节截图。文档阶段未启动引擎、未改生产游戏源/PNG、未读写真实存档、未操作编辑器或用户游戏进程；文本编辑使用apply_patch，原图仅精确文件复制。

## 两张新原生素材及授权处理

Root通过内置imagegen生成墙饰、地毯各一次，共2次；没有本次CLI/API fallback或额外重生。模型/provider/cost未由工具公开，保持unknown/null，不把请求文字当模型证明。请求均为1536×1024，实际两张均1774×887 RGBA，如实按实际尺寸落位，不重采样为请求尺寸。

| 素材 | 完整prompt / SHA256 | RAW（原文件字节保留） | 工程图（完整主体+64px留白） |
| --- | --- | --- | --- |
| 牡丹鸟画/帷幔灯饰 | [salon_wall_v1](../../prompts/luoyang_quality_20261101b/salon_wall_v1.txt) / `440e42a9c2e018744f738c58a5f1df11142586c49591d0ba143562b89bb1ade5` | [salon_wall_v1.png](../../assets/raw/luoyang_quality_20261101b/salon_wall_v1.png)，1774×887，`ccaa3a4dfc0bbdc6ea32fcecf215702e23f94356c266fd028cbcab67b971e779` | [salon_wall_v1.png](../../game/art/modules/luoyang_quality_20261101b/salon_wall_v1.png)，1902×1015，`18a7c29ba999bb6df67b4110155518b53ac28b8ef17bf542a5e5aa9b92f8f038` |
| 完整牡丹红毯 | [salon_peony_rug_v1](../../prompts/luoyang_quality_20261101b/salon_peony_rug_v1.txt) / `3b9140ecd6492d0de6e993d463e0b9e53705ef5bb6146f6210d5cc10eaf29705` | [salon_rug_v1.png](../../assets/raw/luoyang_quality_20261101b/salon_rug_v1.png)，1774×887，`5c11e1d0bbe7b4731d72fe682cad71328898ceb5847fc0fd62f2d196d49211ff` | [salon_rug_v1.png](../../game/art/modules/luoyang_quality_20261101b/salon_rug_v1.png)，1902×1015，`79d0725d3859016941db26fbfc29f76ab3cfec8fb3b6b2f3431701fbfa22ef96` |

用户2026-10-28后续同类长期许可下，确定性[prepare_media.py](../../game/build/luoyang_quality_20261101b_art01/prepare_media.py)只把各保护框外A=1改0、四边增64px RGBA0：

| 素材 | 源保护框（半开） / 清理数 | 工程A>0框 / A>1框 | 实际证明 |
| --- | --- | --- | --- |
| 墙饰 | `(40,54,1734,824)` / 2317 | `(113,118,1798,888)` / `(115,129,1787,877)` | [wall_ACTUAL](../../game/build/luoyang_quality_20261101b_art01/salon_wall_ACTUAL.json) |
| 红毯 | `(32,118,1744,772)` / 5057 | `(108,190,1795,836)` / `(109,194,1795,823)` | [rug_ACTUAL](../../game/build/luoyang_quality_20261101b_art01/salon_rug_ACTUAL.json) |

全原RGB、保护框RGBA、源文件/RAW字节精同；原画布完整平移保留，新增留白逐RGBA0、PNG编码往返像素精同；无裁主体、重画、改色、拉伸或重采样。原A>0触边/杂点事实保留，不把清理后结果倒写原图合格。Art处理阶段0engine/import；随后Root独立完成实际导入/绑定，前述处理报告状态是当时点，不改写历史文件。三挂饰是**一张素材的三次完整等比使用**，不是三次生成或三张新图；地毯为另一张完整等比图。原shell未替换，mini包含新视觉。

两图统一[asset_registration.json](../../game/build/luoyang_quality_20261101b_art01/asset_registration.json)已登记原builtin路径、每图1次/合2次、未知模型口径、prompt/RAW/runtime/实际import与CTEX完整SHA、长期处理许可和当前局部接受边界。

### 有限图库增量

沿既有31d精确追加范式和现有`gallery.thumbnail`，仅新增本批2RAW+2runtime共4路径与4个新webp；[图库](../equipment-skill-catalog.html)5266→5270。旧5266条record语义与序列化前缀、HTML非resources区域及旧cache条目保持；只更新resources的records/categories/summary并追加4个cache键，原HTML/cache精备。本次没有全图库build、inventory/source扫描或逐5000资源重验，没有改共享scanner或资源PNG。[执行证明](../../game/build/luoyang_quality_20261101b_art01/catalog4_append_ACTUAL.json)记录完整首末SHA、4缩略路径和有限11条素材/登记/prompt/import保护；[新增records](../../game/build/luoyang_quality_20261101b_art01/catalog4_records_ACTUAL.json)明确氛围待用户接受，不将图库登记当全ART通过。

## 首次失败、现役检查与视觉拒绝

- 首headless probe为**11项PASS、2项FAIL**，不是11总检查。Estate/Temple无类型空Array赋给`Array[Dictionary]`实际失败，Civic成功前缀继承；只修typed空数组分支。原probe/首helper、失败和旧source_pins保留，见[失败与残余说明](../../game/build/luoyang_quality_20261101b_ground01/failure01_and_residual02.md)。后继probe02仅Estate/Temple残余16PASS/0FAIL，[stdout](../../game/build/luoyang_quality_20261101b_runtime01/probe02_stdout.log)与空stderr只属于该次纯probe，不能借给实机。
- Root现役首实机为91364，[quality_result.json](../../game/build/luoyang_quality_20261101b_runtime01/actual/91364/quality_result.json) SHA `b931a20aebf9ca2e89c061b6e84d7aed691f124df5c37844a1a517101be057d0`：112检查、0错误、22真实输入ticks、39274ms，`actor_camera_writes=0`、`save_file_reads=0`、`save_writes=0`。三室外/室内接近均为公开versioned near setup，**非World至城连续旅行**；后续W12/Space进怡红院、S8/Space返原街脚是真输入，坐客稳定观察真实执行。
- 两实际坐客单帧显示连续至少2.1秒、至少15样本保持，原body/owner/compiled/业务不变。YIH-02快速转向关闭为本轮局部已修；没有新呼吸/喝茶动画，不授其他所有坐客已修。原四人对白成功矩阵不重跑。
- 四张正常1920×1080图Root均亲看：[怡红院](../../game/build/luoyang_quality_20261101b_runtime01/actual/91364/yihong_seated_wall_normal.png)、[宅园](../../game/build/luoyang_quality_20261101b_runtime01/actual/91364/estate_servants_edge_normal.png)、[Civic布坊](../../game/build/luoyang_quality_20261101b_runtime01/actual/91364/civic_cloth_court_normal.png)、[Temple西院](../../game/build/luoyang_quality_20261101b_runtime01/actual/91364/temple_court_edge_normal.png)。Art文档角色只亲看其中怡红院/宅园，不冒独立复跑。怡红院接待雅座氛围改善，仍旧shell/未开放楼上/无新乐师，YIH-03待用户接受，不能报整体设计全通过。
- **Root首轮明确拒绝三地面ART**：10px收边在正常图不显、原mud粗石/硬矩形仍突兀。首地面技术通过不能关闭EST-04，不复制该拒绝方案扩铺；首拒源码档案 `ground_visual_ART_REJECT_91364.gd.source` 保留。下方03再次拒绝、04有限接受另记，不能倒洗首拒。
- [finite01_stderr.log](../../game/build/luoyang_quality_20261101b_runtime01/finite01_stderr.log)实际保留7条纹理/RID/RenderingServer退出ERROR及ObjectDB泄漏warning；**不是empty stderr或clean日志**。112/0只说明该QA断言范围；OS退出/最终guard仍由Root实际进程与保护收据记录，本文不补造。

## 地面03有效深度反例与最终04

- 03实际95060：[结果](../../game/build/luoyang_quality_20261101b_runtime01/actual_ground03/95060/quality_result.json)88检查0错/0输入、19032ms，Root记录自然0，但三正常图显示铺石全部被新砂土盖住、仅边条露出，明确ART拒。新底层使用absolute z=-1050，铺石仍relative z；QA只断言local属性，未计算父层−100后的最终深度。该反例不能称“88/0地面通过”，原三图、报告和拒绝版本保留。
- 04只修同一原因：新地面统一进入原父层relative深度族，QA记录真实祖先深度：旧底−1200、细砂土−1150、铺石−1100，宅园garden−1099/−1098；实际前后关系成立。不得只用`z_index`局部值或`visible`代替最终画面。
- 最终04实际44444、console11912自然0：[结果](../../game/build/luoyang_quality_20261101b_runtime01/actual_ground04/44444/quality_result.json)89检查0错、0输入、19106ms；只三个公开near setup、无连续旅行，0actor/camera写、0save内容读写。Root亲看[宅园](../../game/build/luoyang_quality_20261101b_runtime01/actual_ground04/44444/estate_servants_edge_normal.png)、[Civic布坊](../../game/build/luoyang_quality_20261101b_runtime01/actual_ground04/44444/civic_cloth_court_normal.png)、[Temple西院](../../game/build/luoyang_quality_20261101b_runtime01/actual_ground04/44444/temple_court_edge_normal.png)：真实铺石恢复、三片区尺度/worldUV与入口异材接片改善；旧粗mud换细砂土，连续18px石边+6pxdust形成可辨接口，获本批有限接受。原compiled/receipt/物理不变，91364坐客稳定/真实门功效继承，不重跑。
- 仍保留：平直院落边、宽空地、纹理重复、临时院墙不够自然。EST-04只具体材质尺度/边接口局部改善待用户，不关闭全部硬边；不是整城设计/全ART。04仍有旧7条退出ERROR+ObjectDBwarning，不能把自然0写成empty stderr/clean。

## 最终保护与交付停止点

[final_guard_ACTUAL.json](../../game/build/luoyang_quality_20261101b_runtime01/final_guard_ACTUAL.json) SHA `87056f24620fcc3d7c8df540265bebc2551895ee044393e440576e21ec7f0d2d`，`passed=true`、errors空：仅`project.godot`新增一行autoload、exact-one-line字节逆回原project；97原冻结源全同、171存档路径SHA/bytes/精UTCticks保持（9缺席）、60独立pins无差。只保编辑器51856，自有实机已自然结束；capture前两用户save/bak变化与此前历史变化保现值，不恢复、不反序列化/写用户存档。旧3236范围仅历史信用，本轮未重哈全库。

已交付：可重新运行查看固定坐向的两客人、三挂/红毯/mini与三个片区地面接口，停止本批成功域复验。氛围/地面局部改善待用户；旧shell、楼上未开、无新剧情/乐师/服务边界保持。其他城市、野外、门派、World和全部室内不因本批有限接受变成已审/已修；未来仍按[ai-rules场景前置条目](../ai-rules.md)先列原因组、真实消费者与成人/净门/纹理/用途样板，并同时检查有效祖先深度和实际正常图。
