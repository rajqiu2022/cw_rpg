# 2026-11-06 冷加载与高清 NPC：只读 QA 审查及交付草稿

本记录由 audit06 作只读代码审查；不运行引擎、不改被测代码、不接触真实存档。实际安装由 loading06/npc06、有限引擎与最终准入由 Root 负责。以下是审查时快照，不是“全部改造完成”。此前反馈覆盖清单和 GM 正常截图见 [反馈与 GM 专题](feedback-audit-and-world-gm-20261106.md)。

## 最新有限状态（后继更新，历史快照保留）

- batch03启动中，尚未计入正式交付：仅行商1族的down idle 4帧和四向walk各8帧，计划5atlas/36帧；QA新域见[增量审查](../../game/build/npc_hd_20261106_batch03_qa/REVIEW.md)。只准备新增消费者fixture，未启动引擎或重跑旧18图。ghost复核更正：当前确认的低清副本均是Player消费者（主角本体、岚溪、武华），NPCNode没有该副本；主角高清未接，因此这是未来主角高清准入的缺口，不是本轮新HD NPC已复现退化。城市actor_frame mask不能只换高清纹理而忽略局部坐标变换；本批保留正式adapter，不借此扩大实现。
- batch02后继已有限正式接入：Root formal3 actual117864自然退出0，3个新增正式NPCNode消费者/0失败，无候选注入、非Field旅行。累计**14族、18张atlas/manifest映射，另保原农人，共19个runtime映射**；正式source变化0、15个真实存档路径metadata变化0。退出3条RID/null RenderingServer旧类警告保留，非clean；仅编辑器51856留。下列12族/15图与formal16是首批历史证据，不是最新总量。system02纹理并发候选因新增ObjectDB警告未采用，正式旅行实测仍以8.488秒为最近有限证据。
- 本轮共 **12 类、15 张贴图：8 类新生、4 类原生复用**。坐客男女虽在 `reuse_preparation_receipt.json` 的整理流程中，RAW 是本轮新生成，不能算旧素材复用。8 类新生为小二、菜贩、男女坐客、竹尾门卫、武馆师傅、哭泣妇人、竹尾护送者；4 类复用为搬运工、老僧、老军士、年轻军士。原农人另行保留，不计本轮12类。
- visual02 已被 Root **ART 拒收**；sampling_ab02 的错误 oracle 导致 QA FAIL，原失败保留。后继 ab03 首层 RGBA 字节精同，不能把改过滤本身算作高清重制。
- visual03 实际 PID **130952 自然退出0，15检查/0失败**；Root 对实际尺度下15张贴图的首帧身份、比例和缩小采样效果作有限 ART 接受。这不是全部方向、动画连续性、全部现役 NPC 或全部正式场景通过；`128` 为世界身高目标，非截图中128屏幕像素。
- npc06 已执行精确 **45项安装**，47对象 after SHA 全同：旧2张PNG冻结不写，新13张PNG、15个导入配置、15个ctex以及adapter与manifest。旧2映射保持，原农人保留。Root 后续 formal16_04 actual27964 自然退出0，16个正式NPCNode消费者/0失败、15 manifest映射+原农人，无候选注入；source/player/executable变化均空。只证明正式采用，不是实际Field逐图旅行。PS5预引擎、02类型推断、03误验AtlasTexture裁片路径的失败保留，04仅修oracle验证底层atlas及region；未据QA失败改正式资源。
- QA在安装前只读核验47对象/45拟写、8旧对象全文备份和39 absent目标；逐帧核新13图来源的RGB与保护区RGBA精同，仅授权框外alpha=1清理、补白及整数平移。搬运工idle1/walk4与母条对应完整格切片精同。adapter差异仅HD显示子节点 `LINEAR` → `LINEAR_WITH_MIPMAPS` 及注释，原材质租约、动画方向、碰撞与农人固定映射逻辑未改。此为有限静态接入审查，不是新一轮运行验证。

计划及留痕：[formal_mipmap_install_plan](../../game/build/npc_hd_20261106_candidate01/formal_mipmap_install_plan.json)、[formal15_before_receipt](../../game/build/npc_hd_20261106_candidate01/formal15_before_receipt.json)。下列顶表与早期adapter段落保留为历史快照，最新状态以上述更新为准。

formal16_04最新事实已只读核对[stdout](../../game/build/joint_world_luoyang_20261003_qa/npc_hd06_formal16_04/stdout.log)、[进程所有权](../../game/build/joint_world_luoyang_20261003_qa/npc_hd06_formal16_04/owned_process.json)和[after](../../game/build/joint_world_luoyang_20261003_qa/npc_hd06_formal16_04/after.json)：实际27964、OS exit0、16 consumers/0 failures；`candidate_injection=false`、`real_field=false`、`real_save_content_access=false`。全部实际裁片检查底层atlas身份、正式路径、mipmap和region，source/player/executable变化为空；因此旧“formal16待Root”已由有限正式采用证据替代，未扩成全NPC或实景全动作完成。

### 存档审计更正与后续保护边界

上述`real_save_content_access=false`是游戏fixture的自报字段，不能覆盖外层启动脚本的行为。2026-11-06后续审查确认旧 `scripts/qa/run_luoyang_city_only_current_protected_20261010.ps1` 第49–55行：`Player-Records`把15个真实slot/bak/tmp路径交给`File-Record`，其中`Get-FileHash`会读取存在文件的实际字节。此前笼统“0真实档读取”说法过宽，现更正为：这些旧保护运行确有存档字节哈希读取；未据此发现反序列化、写入或恢复。原日志和结果不抹除，metadata/SHA不变也不能反证“没有读”。本QA此次只读代码定位该问题，未执行旧runner。

后续禁用旧runner，改独立 [metadata-only runner](../../game/build/loading_20261106_system02/run_metadata_protected_ROOT_ONLY.ps1)。只读复核其`Player-Metadata`仅15命名路径的Test-Path/Get-Item存在性、长度与ticks，无hash/copy/readtext；项目source/executable才做SHA与源备份。system02的17个source和batch02 visual的24个source均为项目源码/候选资源，无真实存档路径；这些有限路径及祖先无reparse跳出。入口须在精清单，APPDATA/LOCALAPPDATA隔离且finally恢复，超时仅处置本次直接启动的GUI Process对象。此更正阶段仅空项目mipmap导入已运行，不把待跑fixture宣称已经通过或无存档访问。

### batch02安装前最小审查边界（历史；后继有限准入见下节）

- 正式adapter仍要求atlas等格、源图格数与映射帧数完全相等。非整格8帧RAW必须保原像素整数分区、补透明留白后等格重拼，不放宽adapter或对人物重采样。原帧序与左右镜像语义须对应真实运行源。
- 源脚点和HD脚点必须逐帧同一解剖落点；不可只将每格最低alpha当站立脚点。最小残余覆盖新增动作首/末帧、左右flip、idle→walk→idle换源及已知交互材质租约；不复旧15贴图或成功入口矩阵。
- `ghost_stays_original_resolution=true`仍是正式明确边界：遮挡影像沿旧低清source，未因本轮高清view采用自动升级。因此“全部画面NPC高清”仍未完成。本轮不扩写ghost实现；后续必须明确真实遮挡消费者与共享材质边界，不能借主体高清掩盖影像降级。

## batch02 / system02 后继状态（2026-11-06）

batch02：Root候选visual02 actual110248自然0、53检查/0失败，13帧及双flip有限通过，三首帧身份/比例/清晰度获有限ART接受；不扩为全部动作或全NPC。npc06随后安装10精目标，QA只读逐一重新计算正式文件SHA，10/10与批准计划after精同，adapter仍为冻结`7dc7b154…`。manifest为`34f2830f…`；原15映射保持，新3映射对应2族。后继Root formal3 actual117864自然0，新增3个正式NPCNode消费者/0失败，无候选注入；manifest18、连原农人adapter19，非实际Field旅行。source变化0、15个真实存档metadata变化0；退出3条RID/null RenderingServer旧类警告保留，仅编辑器51856。见[formal_after_receipt](../../game/build/npc_hd_20261106_batch02/formal_after_receipt.json)。visual01缺NameLabel超时、visual02旧RID/null RenderingServer错误、首次patch末尾多CRLF造成after不符均保留；格式纠正后精字节同候选，不称clean。

system02纹理批次：新候选3hunk经QA独立SHA与全文字节逆回正式`05ef868…`，仍在source/payload/mask校验之后预取，全部path归属先验，最多4请求，每个成功request均get收尾，随后原序校验Texture2D及resource_path；null或request失败回原load。没有发现确定性新增未回收控制分支，但预取会在原首个坏纹理拒绝前加载后续已授权资源，失败日志/加载副作用顺序不再等同串行，不能称完全等序。

Root诊断71528自然0、diagnostic失败0、source及metadata差异0；同headless目标纹理段576.765→446.783ms（批次445.790+原序0.993）、ensure855.202→722.011ms。新进程OS缓存不受控，不据此宣称正式8.488秒再次降低。候选新增ObjectDB leak warning，原baseline46612空stderr；原因未确认，Root决定**不正式接入纹理批次候选**，保留结果而不追加引擎复测。

### batch02 / system02 安装前只读结果（历史候选阶段）

独立读取 [preparation_receipt](../../game/build/npc_hd_20261106_batch02/preparation_receipt.json) 对每帧实际母图与候选像素作比较，而非只相信 receipt 布尔值。3张候选共13帧：书生1帧整字节复制；护卫idle4帧仅保护框外4713个alpha=1清零，全部RGB/主体RGBA不变；护卫walk8帧按历史 `round(i*1983/8)` 边界完整分区，全部RGBA保留、整数平移，补白全部RGBA0。三张候选SHA与receipt一致，18映射候选的原15映射逐字段精同；本审查未写正式adapter、manifest或图片。

- walk候选3584×928、8等格448×928，兼容原adapter，不需放宽非整格校验。RAW实际净身高411–416，以411为基准映射到原source目标140，显示范围140–141.70；idle616映射回原126，保留原idle/walk既有高度差，不声称统一131或全族各帧完全等高。脚锚均为对应原帧脚底支撑带，母图锚加整数平移精等atlas锚。
- 两张护卫候选原图已看：普通中年黑衣、腰刀、包腿身份无明显换人；walk旧RAW细紫边仍继承，像素保真不替代正常倍率ART。最小运行残余应限新增13帧、左右flip、idle↔walk切换和一次交互outline；不复原15纹理或全城矩阵。
- ghost边界进一步精确：`player.gd::_sync_overlap_ghost`复制原sprite纹理；town/sect的ghost helper读取`town.actor`主角并未复制源self_modulate/material，所以主体discard不会令影像消失，但影像仍是旧分辨率。尚无证据这3个NPC直接使用上述主角ghost，不将其误写为已复现的NPC新bug。NPC原outline逐实例创建、HD clone独立，未发现新增共享材质污染；不改ghost。
- system02 [instrumentation_receipt](../../game/build/loading_20261106_system02/instrumentation_receipt.json)已独立逐hunk逆回：wrapper及计时注入移除后，UTF8整字节精等正式`05ef868…`，原来源校验/OWNED/执行顺序保留。无新线程、无正式磁盘写，不构成已优化耗时证据。
- 原probe曾未断言计时调用确命中目标，已反馈并由loading06补`TARGET_COLD_ENSURE_ACTUALLY_MEASURED`：目标scene、成功ensure并含`object_textures_all`才可标诊断完整。逐hash/texture详情包含在阶段时间内，不再加总；旧4352ms最大帧与865ms FIRST/FINAL并非已证明同区间，不可直接相减归因。剩余以Root本次有限探针结果为准，本QA不启动引擎。

## 早期实际状态快照（非当前完成表）

| 范围 | 本轮事实 | 验收边界 |
| --- | --- | --- |
| 道路距离场 AABB 热路径 | 正式 geometry `0C9F5466…`；继承1707/0等价检查、同一路线6/0 | 不是所有冷加载完成 |
| World GM 避让 | 正式两文件；fixture12/0、World7/0；Root亲看正常原图接受 | 仅 GM 与小地图不重叠、拖动不抢位；不重测全入口 |
| 并行来源 SHA | exact8目标已安装；Root 实际94624共8检查、1失败；后继41264真实Market来源2696/2696有限PASS | Docks原通过继承，Market精闭包残余已通过；原94624 FAIL保留，不扩大为全部入口通过 |
| 新高清小二、菜贩 | 正式 adapter `28DB6F07…`；manifest `56CF5CC1…` 仅2个新映射 approved；首visual01有1项映射失败（未import） | Root空项目仅2PNG import01 PID75836自然0，未全游戏导入；visual02待验，尚不能声称runtime已看见高清；各4帧下向idle，非四向/全动作/全部NPC |
| 六类整理候选（原称“六类复用”，此处更正） | 坐客男女为2类本轮新生；僧、老军士、年轻军士、搬运工为4类复用，共9纹理映射候选 | 此行为早期候选状态；不能因整理脚本名将新生坐客计成复用，实际后继采用见最新有限状态 |

小二/菜贩安装回执：[formal_install_receipt](../../game/build/npc_hd_20261106_candidate01/formal_install_receipt.json)。继承 Root 实际130476自然0、34通过/0失败的有限 fixture，既有退出 warning 保留。该fixture不替代真实资源导入与显示：其后的visual01映射失败保留，2PNG限定导入完成也不等于visual02通过。原农人映射不计本轮新增。RAW身高最低678/664，原生重制而不是旧160格放大；正式源业务纹理、碰撞、任务不替换。

## 冷加载已测数值（并行 SHA 安装前）

来源：[loading HANDOFF](../../game/build/loading_20261106_system01/HANDOFF.json) 和其 `actual/129412/result.json`。

- 旧同类冷进程到可操作25574.689ms；本轮 AABB 后实际10561.205ms。
- 本轮首draw69.823ms、Field完成9866.099ms、Loading隐藏10560.206ms。
- Loading内最大帧6384.430ms，退屏后最大帧16.714ms；因此屏内卡顿仍真实存在，不以退屏后平滑声称全程流畅。
- 独立双道路函数9120.724→279.527ms，可明确证明该函数约8.841秒减少；总约15秒差额不能全归因AABB，来源IO条件不同。
- 并行纯hash两次串行2354.551/2415.713ms、四worker686.589/685.247ms；1311路径值/顺序相同、跨阶段改动仍被发现。这里只是纯hash，不是安装后真实旅行总耗时。

旧 WASAPI fallback、texture/RID/ObjectDB 退出告警和此前失败日志均保留，不称 clean log。

### 并行 SHA 安装后：Root 实际94624（早期快照，Market待修已过时）

- 首draw46.542ms、Field7811.376ms、Loading隐藏8487.870ms、可操作8488.116ms。
- Loading内最大帧4352.838ms，屏内长帧仍OPEN；旧25.575秒→AABB后10.561秒→本次8.488秒分别记录，不将各阶段测试环境差额全归因单项优化。
- 本次8检查、1FAIL：Docks实际消费者通过，Market真实C→B准入失败。loading06正在修复精确闭包，原FAIL保留，修后最小残余结果尚待。
- 因存在实际准入失败，不能用耗时降低宣称加载任务完成，也不能用只读8hunk结构正确覆盖实际consumer失败。

## 只读审查结论

**静态审查在所读8hunk/线程边界与adapter差异内未发现确定性实现缺陷；这不是运行准入结论。其后Root真实Market C→B的94624 FAIL保留；最新Root报告41264实际来源2696/2696有限PASS，故该精确闭包阻断已获残余证据。** 不等于所有场景、所有角色动作通过。

### SHA 并行与严格来源

审查 `hash_batch.gd`、`hash_closure_READY01/all_hunks.json` 全部8目标及 family 调用上下文。

1. 每次 `fresh` 新开文件，FIRST/FINAL各自重读；没有跨阶段结果、mtime或size缓存。失败仍通过原期望SHA逐项比较，未放松校验。
2. 各线程只有私有路径桶/私有返回字典；无SceneTree、Resource或共享Dictionary写。启动失败走同桶同步回退；所有已启动线程join后才读结果。
3. 按原输入路径顺序合并，缺失文件保空hash并由原校验拒绝。正式调用来自已检查Dictionary，键唯一，轮转桶和结果索引一致。
4. 可执行helper先核固定SHA再load；4处manifest source集合追加相同helper，family SELF SHA后继及各index SHA同步；未新增OWNED键/逆边。
5. 独立只读核查：8候选SHA逐一匹配receipt；逐new_offset精核hunk，逆变换后UTF8全字节SHA逐一回到receipt旧SHA；当前8正式文件逐一精同候选。初次对“旧formal”比较不相等是并发已安装状态，未将它冒充缺陷或回滚。
6. worker仍会同步join，因此减少耗时不等于异步无卡顿；后续以真实帧时定位剩余热路径，不能追加等待掩盖。

### 正式 NPC display adapter（首2映射时的历史审查，非当前数量）

审查候选与当前正式SHA一致，涉及 source prepare、双向flip脚点、material lease、source切换与退出清理；对照原 `npc_node.gd` 的进入/退出交互range实现及真实outline shader参数。

- 只对精SHA、指定source/layout/frame有效时显示高清；未声明动作回原生，不伪装方向覆盖。
- 显示子节点承接原sprite变换；锚点经flip后同公式补偿，原纹理/frame/collider/游戏状态不写。
- 原生outline可复制已核shader，补偿宽度比例；原图用discard避免透明底上仍冒outline。外来材质退回原生，已离开range不恢复过时高亮；重复赋同材质复用clone。
- self_modulate租约只还原自己仍持有的值；子view不继承父self_modulate，原modulate/显隐仍沿树继承。
- 现正式仅小二/菜贩2新映射，加原农人。原生ghost仍旧分辨率，代码明确记录；不能声称“所有画面方向均高清”。
- 当前新增atlas在autoload初始化时验证与载入；扩至全员时需纳入启动时间/驻留内存测量。这是扩容注意项，当前两映射尚无证据构成阻断缺陷，不据此盲目改加载架构。

## 本轮尚不能关掉的总项

全NPC真实高清四向/全部现役动作；主角完整动作；三大城市整体地域风格/密度与部分地面重复边缘；未改造门派内景及剩余野外组；总冷加载与屏内长帧。visual02拒收与后继visual03首帧有限接受分别保留；45项安装、47对象SHA一致及formal16正式采用PASS不等于上述总项完成。Market41264精闭包PASS只关闭上述单点残余，不重复其它成功路线。历史反馈按 [AUDIT](../../game/build/feedback_audit_20261106_qa01/AUDIT.md) 的逐项范围继承，后续用户否决优先，不用局部功能成功覆盖美术未完成项。

### 后继有限证据更新（Root报告）

- Market41264：实际来源2696/2696有限PASS；94624原8检查1FAIL仍留存，静态补丁结构正确与真实consumer准入分别计证。
- NPC sampling ab02：QA失败历史保留；后继ab03基底字节精同。该结果仅说明采样基底一致，不能外推全部NPC或所有动作已正式接入、视觉全接受。
- 下一批未处理4族见 [只读候选清单](npc-next-four-readonly-20261106.md)，不计入本轮已接线/候选12族。

## 补充：finish8 动态新增 NPC 的有限来源补表

只读实际 `luoyang_quarters_family_20261022ap.gd` → `luoyang_gate_short_walls_20261029m_system01/closure_READY01/finish8_runtime_READY.gd` → `scene_cleanup_20261102c_system01/closure_READY01/finish8_binding_READY.json`。BIND 固定 SHA `08a52adce7ab3b032baf7b33904304808352c77231009b09efd18b6bd45b0e31`，其声明的 8 个 payload 字节 SHA 全同。只读取这些项目资源，不读取用户存档，不调用引擎。

runtime 第 303 行消费字段确为 `new_NPCs`。按原字节定位此键及紧随的 Godot Array 头（type=28），7 包 count=0；宅园包 count=2。键字节偏移按 gate/yamen/docks/market/temple/estate/artisan/garden 次序为 `173016,260448,269176,228108,31624,127744,170196,62936`。宅园仅新增：

| NPC ID | 正式 sprite source | 动作 |
| --- | --- | --- |
| `luoyang_estate_court_keeper_20261025i` | `res://art/characters/npc_linxi_farmer_idle_down_25d_4f_v1_runtime.png` | idle；walk_sprite_path 空 |
| `luoyang_estate_kitchen_hand_20261025i` | `res://art/characters/npc_zhuwei_inn_waiter_idle_down_25d_4f_v2_runtime.png` | idle；walk_sprite_path 空 |

两族都已在静态 source inventory，故本次补表不增加 unique family；农人是原有高清行，小二属于本轮正式 2 映射之一。此结果只覆盖 finish8 的新增行，不将它扩大为全部原 parent NPC、后续动态生成 NPC 或所有活跃 spawn 的完整人口统计。
