# 2026-10-31h 东海离岸岛与汴州城前空间施工

状态（2026-11-01）：新版海岛与汴州城前布局已正式合入；双向渡船、两岸World返回、M/mini同源、汴州真实进返及洛阳真实入城已通过有限实机检查。最终累计39目标（原37加文化Coordinator/CT两项），原布局和业务保持；最终保护核见文末。仅本轮接入交试玩，不授整张World全部美术终验或真实存档读盘恢复。

## Change

- 目标：白鹿渡位于大陆，东海埠位于连续海水围合的离岸岛，只能乘船跨海；汴州桥后有独立引道与城前广场，不再桥头顶着城门。
- 背景：31g只读确认两港旧东商路同陆域；用户另指出汴州桥端几乎贴着大城门。设计说明见31g专题，不能把设计PNG当正式地形。
- 读文件：31g总规/只读诊断、现役World15 contract、layout、stream、源JSON/RF、有效farmland视觉、30m桥绑定、Router/SaveManager/Field/Loading/M/mini、town_registry与三冒险WorldLinks、两港对白。
- 写文件：先新增`game/build/world_coast_20261031h_system01`（地理作者/增量publisher）、`system02`（新坐标合同与接线）、`system03`（精来源后继）、`qa01`（有限验证/保护）及`game/art/maps/world_coast_20261031h/candidate02`。候选具备且fresh保护后，Root按`system03/sealed_candidate03/receipt_REVIEW_ONLY.json`精确37目标合入，并安装`luoyang_world_coast_20261031h_snapshot03`两份新快照；未放宽旧来源guard。
- 高风险点：新地理坐标版本16，涉及旧脚/返回锚点迁移和共享脚本严格来源。旧15原件保留；新layout格式可沿用15，但导航版本必须持久识别16，不静默偷换15含义。未知版本与16降级拒绝。
- 分工：system01负责同源海岸、RF/mesh、真实NAV、有效地形块和overview；system02负责精V15/V16分派/迁移及接线候选；QA01负责只读metadata保护与新域有限验收；Root唯一引擎和正式集成。
- 验收标准：大陆与东海岛NAV不连通且无桥/浅滩/画布边缘绕行；两港原船双向真进返；22既有入口身份/任务锁保持；旧合法受新水域影响脚有声明地域的安全迁移；汴州入口与桥之间有真实可走引道、广场；M/mini与正式地形同源。
- 验证方式：只测新增海岸连通域、迁移、两船与汴州局部动线及最小旧城门来源准入，不重跑全城/五桥/战斗/制作成功矩阵。编辑器保留，真实存档不反序列化或写回。

## 已形成的真实地理与正式接线

- 新坐标空间16，资源格式仍为15，不能将格式号误当旧坐标语义。新海岸、RF高程、mesh、实际NAV、14块有效地形及总览来自同一份平滑海岸几何；不靠覆盖海水图隐藏旧陆路。
- 东海埠为离岸岛，海湾与岛岸分别64/72点闭合曲线，岛东缘距世界边界仍有178px海水；原白鹿大陆干道、5桥与93条桥视觉源数据保持。22处既有入口身份/目的地保留，除汴州外21处有效门脚保持；原16条地标门户typed数据中也仅汴州批准位置字段改变。
- 汴州整组城廓/实体/门从`7600,2196.8779296875`整体北移640至`7600,1556.8779296875`；桥后引道折向东侧再进入独立前坪，不再桥端顶门。原生地面作者验证384个全足路径/前坪样本及368个基础轮廓样本，没有删除未声明障碍。
- 主入口`res://data/scenes/world_map_jianghu.tres`现在是1170B的薄Scene，只改私有Scene03的`scene_id`，明确外引layout02/stream02；不是17MB内联资源。大地图M面板和行走小地图读取同源新总览及相同门户坐标。
- 两港保原城镇、NPC、任务和双向渡船动作/选项，不新增船费或锁；仅说明文字改为离岸岛/返航大陆。三处31f冒险入口继续保留；其返回origin带坐标版本，并兼容历史三字段记录。

## 存档位置兼容边界

- 未读取、反序列化或回写真实用户存档；以下为新合同的有限纯输入测试，不冒真实读盘恢复已经通过。
- 旧15合法、在新16仍合法的位置原值保留。旧15合法但被本轮海水覆盖的位置，只能依据声明的历史地域迁至对应白鹿渡或东海埠门前，不采用任意最近安全点搜索。
- 汴州旧门户附近的合法脚及被新城廓覆盖的原合法草地脚，迁到同一汴州入口；其他原本非法墙内位置仍拒绝。
- 12/13/14先经过原15迁移，再执行16兼容；未知版本、16降级、当前16非法脚不借旧迁移名义传送。现代版本声明存在但来源未就绪时保留16身份并拒载，不能退成旧通用Field。
- Router/SaveManager先预检当前世界脚与所有World返回锚点，预检成功后才进入状态提交路径。原存档schema未新增主线、奖励或物品数据。

## 实际证据与保留失败

1. 候选01：Root看总览后拒绝硬折八边形海岸；原图、原运行日志和未获保留的退出状态留存，不称自然0。没有采用此版。
2. 候选02出版：console PID34220，保留进程`WaitForExit`得到自然0，30649ms；`root01/publisher02_ACTUAL_process_receipt.json`。Root只接受总览中圆顺海岸/岛屿分离及城桥间距，不以此授予正常Field或全大地图ART。
3. NAV04首次失败在JSON双精度→Float32半界序列化比较，发生在连通域扫描前；原失败保留。NAV05以原新typed门户逐字段精同并比较原始JSON往返标量，无epsilon：实际引擎139064、console112612，自然0、9233ms，`qa01/nav_component05_actual/139064/result.json`共271检查/0错/0输入。完整8邻接岛域885979像素不触ROI边界，证明NAV本身不存在大陆或世界边缘绕行；未重跑旧五桥/全城玩法。
4. Scene02包装暴露内联layout/stream的resource_path身份问题，原17,728,395B Scene与旧sealed包保留但不采用。Scene03只更换manifest的`scene_path`与`scene_sha256`两字段，精逆恢复原manifest，地理/RF/mesh/NAV/PNG均未重建。
5. 29张运行PNG在无autoload的独立小工程导入；实际引擎40852解码145检查/0错；正式游戏实际引擎69804再次解码145/0。编辑器已自行生成的同名导入叶保持、不覆盖，不做整个工程批量导入。原29PNG字节不改；直接原图读取仅在QA比较中，相关export提醒保留。
6. 私有Scene03真实ResourceLoader绑定/迁移：实际引擎22520、console119236，保留进程自然0、7498ms、空stderr；`qa01/bind_migration03_actual/22520/result.json`102检查/0错/0输入/0公开Router调用，验证外引资源路径及有限迁移/拒绝样本，不等同正式Field旅行。
7. Root严格37目标+2新快照合入：`system03/apply03_ACTUAL_receipt.json`（SHA前缀25B98347）；独立前后检查逐字节同候选。原native226→228、Region567→569仅增两新合同代码键并更新必要现役头；EX原全部key/历史边保留，新增Router/Field各一条完整逆边（29→30、33→34），C新增精16路由证明，未改Authority闭集。
8. 实际精16C collector→B.describe：`system03/probe_actual03/98740_13717220/result.json`，实际引擎98740/console125368自然0、14021ms、空stderr；7项World证明成立，C实际集合1714与Gate prewarm期待1714相同，changed/add/missing全空，B.describe为ready。0Field实例/0输入/0存档API，不将静态来源准入冒称实际入城已走通；本域不再复测。
9. 首次Field32实际尝试保留失败：`root01/field32_ACTUAL_stderr.log`记录`WorldMapPanel`全局类重载冲突，以及`REAL_SHORE_RETURN_DOOR_OVERLAP:openworld_east_sea_port`断言失败；原船夫左向对白镜像fallback提醒、纹理退出ERROR/ObjectDB警告均保留。后续只处理残余域，不以Gate成功洗白本次Field失败。

本轮首次保护曾因TRES正则误追历史路径超过2048而停止，原失败保留；后改为显式有效视觉/NAV/sidecar输入。fresh基线3221来源/171存档metadata/9缺席目标；37目标另有补充精备份，其中14项为补充时首次记录，不伪称初始基线全已覆盖。用户在fresh前已改变的save0/bak保留，编辑器51856保持。

关键包装：私有Scene03 `C47C462E`、layout02 `231E6221`、stream02 `B702D063`、manifest03 `022E2414`、合同03 `F25EDF94`、分派03 `A1761EC8`、正式薄Scene `E03CCCF3`；完整SHA由Root批准的`system03/SourceExpected03_ROOT_APPROVED.json`与sealed03收据记录。旧01/02失败产物、旧期待和旧sealed包不覆盖。

## 正式旅行收尾与新增发现

- Field32（实际125824/console34888）首次白鹿渡→东海埠真实数字选项抵达成功；随后QA误用target匹配城镇动作式出口且调用不存在的`_can_enter`，全次FAIL保留，不重复已成功的船程。
- 新候选副本被保留编辑器扫成全局`WorldMapPanel`类，缓存指向旧sealed副本，引发同名类冲突。5个候选档案根加入`.gdignore`，Root仅将生成缓存这一项路径归回正式UI；后续04/05档案亦隔离。正式UI字节不变，不做全工程导入或关闭编辑器。
- Field35（实际128136/console139676，自然1，26检查/1错/18输入）：东海埠→白鹿渡真实船程、两岸动作式门Space返回精16、M与mini绑定新总览、汴州前坪真D32px及3张正常图均成功；最后QA误按未赋值的`portal_id`元数据查汴州门，全次FAIL保留。
- Field36（实际138276/console132372，自然1，11检查/1错/8输入）：按真实target匹配后，汴州真Space进城、步行到原出口、真Space返回北移后的7600/1556.878入口成功；洛阳实际加载暴露Culture迟校验：旧CT仅允许Router后继，拒绝已获EX证明的Field。Field37（实际133864/console123448）补Field准入后又拒CT的旧C直SHA，全次FAIL和1715来源成功前缀均保留。
- system04只让Coordinator原有FIELD常量与Router一样使用既有AP_NPC闭集EX逆链，不加任意路径、不扩Authority OWNED；system05只更新CT的C来源键f1c8→55ef及Coordinator CONTRACT_SHA。Coordinator本来就是EX OWNED，分别追加snapshot04/05两条精确逆边；C/Router/Field/Region/native未再改变。CT原26来源与W的24任务资源事先有限静态核对；任务、对白、奖励、布局不变。
- 最终Field38（实际46988/console127428，保留进程自然0，35995ms，12检查/0错/4输入）：纯Culture.readiness通过，实际C collector与B期待1716项全键全SHA相同、changed/add/missing全空、B.describe_ready；随后原World洛阳门真Space进入1536/1860并真D32至1568/1860，一张正常图Root亲看。原纹理退出ERROR及ObjectDB警告保留，不称全日志clean。停止本轮成功组件复验。
- Root已亲看海岛岸、白鹿大陆渡口、汴州前坪和洛阳城门4张正常图，仅接受本轮地理/间距/接入范围；水岸细节、旧World厚mini框等不借此宣称全ART完成。

## 最终保护与交付范围

- 初始3221来源、37项补充中新增14来源、CT新增1条fresh事实，口径3236来源；CT确实不在原3221里，不能伪称继承。CT改前双读/原字节备份`protectedCT39_supplement_ACTUAL.json`（FCCA9EB7），真实171存档与9个缺席路径均只核metadata，不读盘反序列化、不恢复或回写。
- Root批准的`qa01/cumulative39_ROOT_APPROVED.json`保留原始before（不是04/05中间态）与最终39目标SHA；3个运行合同/Scene证明及4份新执行快照由实际字节固定。`evidence39_ROOT_APPROVED.json`记录29原PNG和58真实导入叶及前后实际结果、失败报告与正常图；编辑器生成的导入叶不覆盖。
- 最终`qa01/final_guard39_ACTUAL.json`为PASS，SHA `1f7b00756e4d2b50dea1ba342cea0d623a8503ed77e2ae4c66104d13900e3988`：3236来源/171存档精metadata/9缺席，39精授权变化，123新证据、41份备份，0外差。仅编辑器51856保留，Root自有游戏检查进程自然退出。用户fresh前save0/bak历史变更保留，停止复验交试玩。
- 可试玩内容：白鹿渡到东海岛及返航、海水阻断陆路、汴州桥后引道/前坪与新门位、M/mini同步、旧合法位置有限迁移和原洛阳入口。未完成/未授予：整张World美术重制、逐城全玩法矩阵、真实用户存档读盘恢复、新剧情或新收费。
