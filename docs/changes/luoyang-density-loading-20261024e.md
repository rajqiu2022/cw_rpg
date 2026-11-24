# 洛阳街坊密度、剩余附楼与加载整改（2026-10-24e）

状态（2026-10-25本轮收口）：24e南市43实体街坊、干净底层及五用途地面已写入正式消费者；功能有限验收已过。8路世界后台首检预热已实测：真实Space首入城门8.812578秒、同活场景重复1.675133秒；不是进程启动/SSD冷启动或全城区达标。码头两铺比例与北仓退界也已正式接入并完成局部实机验收。整城艺术仍未完成。承接用户新示例；暂停24d世界河桥工作，不把其样例当洛阳正式进展。以下“仍24c/未部署”段为原时间点历史，原失败不回写。

## 目标

参考图采用连续街坊、主次街、院落围合和不同用途地面形成城市密度；不直接复制其建筑、标牌或完整底图。保持当前人物视角和成人比例，不靠缩小房屋/放大主角或透明化穿插来制造密度。

1. System：南市一个完整商业街坊的后体/屋面、院界、巷肩增量；并另核码头绳铺/供给铺最终消费者与局部地块比例。Root审批具体坐标后才实施，不能只撒十件道具交差。
2. Performance：读取现有真实分段计时与当前代码，找最多一到两处可证的加载热点；不再重跑旧四城/十室内基线，不修改Loading显示冒性能通过。
3. Source：以24c最新正式30目标及当前保存为起点做fresh保护，保持严格来源/权限分类/历史深度及worker事实；实现成熟后一次最小来源接线。
4. Root/QA：新几何差量、关键局部真实图与必要路线、实际加载计时；保失败，不重复已过书生肖像/旧室内全链。

## 不重复的已完成项

24c已经正式合入府衙两附楼比例/退界，以及与抱书精灵匹配的专属书生肖像EBD60B64；已有真实35项对话检查通过。若当前源仍精确匹配，则本轮不重生图或重跑该对白。尚余的附楼是码头`harbour_rope_shop`与`harbour_quay_supply_shop`，不能拿府衙已换的素材或旧native占位尺寸代它们。

## 本轮可见验收

- 至少形成一个可读的连续街坊，包含真实屋面/建筑后体，不是孤立楼加薄墙或杂物。
- 主街、次街、必要侧巷分别按256/144/96px目标核footprint与檐口。原旧门脚/巷位优先保护，但不能把“所有东西原位不动”当借口继续薄墙填缝；本轮已明确允许有限南市街坊重排、精确同步受影响门和室内返脚。任务身份、触发/奖励、角色身体/速度和原室内几何保持。
- 新附属门使用145～150px成人标尺，按最终素材测量；不盲放大或捏造可进入的门。
- 新/退solid与mask及真实Physics一致，不把图片alpha包络当真实基座。
- 第一入场目标约10秒、同进程重复小于10秒，以Loading隐藏且首绘可动定义；现有功能测试总耗时不当加载成绩。未实测不宣称达标。

## 保护

不关编辑器、不私停游戏；所有旧失败、原图、备份、保存保留。不关严格校验、不扩历史上限、不从现盘hash自填authority。只对本次改动做必要检查；正式由Root统一部署，子角色不得自行启动引擎或写正式源。

## 方案收敛与已排除的伪优化

原位可用槽只有约150～220px投影深度，塞成人完整楼会撞檐或缩成玩具；Root拒绝“两个浅屋面＋薄墙”交差。改为两列、三层真正街坊：客栈/药铺/当铺为西街立面，裁缝/成人闭门后勤体/书铺为东街立面，另一列后勤屋和店铺组成东后院。允许移动必要既有楼、生活物件及同职业NPC，六门左右返回标量精迁；原十房几何不得为此重编。主街须由两侧真实街面限定300～400级宽度，而不是在1000px空广场中名义画300px路。最终坐标仍以实际净距/门返脚候选与检查为准，未提前授通过。

加载只读F7EEFE36确认旧Yamen/Docks的完整source首检和末检为主要耗时，当前已8路Hash，旧Yamen贴图预载仅237.68ms。P1 packet解析缓存首次miss无益、P2旧单侧wire最多348.896ms上界，均不作为本轮实现。改授E8146E29方案的独立候选：世界真正hidden可动post_draw后，只预热合法Gate完整source-first SHA；精Scene/完整expected-map/sourceEpoch匹配才接管完成或pending纯Hash任务，fresh末检始终照原完整执行。新finite/token/NAV不复用，不用秒mtime豁免，也不修改Loading隐藏点。后台收集路径的主线程同步块仍有帧停顿风险，实际未测不得承诺10秒。

Source fresh63C08EB5读取原2120＋UI额外1：24c30正式目标和UI仍精SHA；相对24c只有两份pre前外部保存变化，当前值保为本次新保护起点，不回滚。书生EBD在正式Field精Market/paper_scholar分支已确认，继承24c35项真实对话事实，不重画/重测。

## 已执行的有限组件检查

Root唯一运行 `candidate01/test_plain_hash_NOTRUN.gd`，自然退出0，13项真实小文件SHA/map-key/缺路径/等长异内容/未join/取消检查全部通过，stderr为空。保留日志和receipt `plain01_actual_process_receipt.json`（C62643C6）。仅授纯Hash组件；没有World事件、入城、导航或实际提速结论。C/Field仍为原24c正式字节，两个原末次完整fresh函数在候选中全文保持。

南市当前作者04（697397F2）将六栋街面楼重新排布，书铺落主街东侧、与当铺实际alpha街面候选间隔351.61px；两栋完整闭门后勤楼使用150px门高、当铺145px。四旧院墙迁移加四纵墙形成两后院，六房门/返回和必要跨区落脚同步候选；原室内几何和PNG像素未改。发布器冻结原runtime＋DG投影37整结构再作43实体子投影，整结构/像素正逆、变更域路线、最终真实Field与画面仍须通过，不将静态坐标当正式验收。

独立prior03实际70376自然0、1146检查0失败、2312ms、stderr空；两PNG/0packet，旧native25→DG37→43全部f32逐位源模型、27域1000516像素、parent差0，子mask变化590860像素、RGBA B6D6D0AF，整逆通过。精提五字段DCC92D0A交发布器，未修改正式mask。prior01 Rect2i两参数API解析FAIL、prior02 JSON数字Array类型误比FAIL原样留存；03只修精整数schema比较，未放宽实际坐标/域或容差。05作者另迁货行商避免站在新书铺屋面后，精退新增NPC迁移和说明字段整逆04，可继承此几何先验。

Gate父map配方检查recipe01自然0、15检查0失败、stderr空，949路径/完整SHA值与独立24c固定map一致；不是子map验收。分段实际raw载入3196us、主线程路径收集827880us、expected配方106701us。故拒绝直接部署原start：NEW候选将只在世界后台启动推测配方的纯Hash，实际claim仍完整收集/核key与值，最终fresh全保持。106ms同步配方残余仍须如实观测，不授后台流畅。

## 2026-10-25凌晨续行：组件已落，正式仍24c

- 新recipe-only残余实际10/0，自然0；主线程配方275768us（不是早先106701us），无collector/worker，1ObjectDB warning非clean，继续保留真实帧风险。实际World冷/暖Benchmark尚待。
- publisher03全parent37/child43整逆和独立像素先验已过，但药铺route擦灯FAIL；06只三条路线改走，publisher05继承像素值，18路/native/crowd前缀走过，实际任务纸匠8801340与灯角不足1px而整体FAIL。组件先落9720（CAFEE），未把失败称整体通过。
- Root前缀事实26394575明确不造样本数，并指出失败后尚有六room_return。suffix02仅旧880负控、新888实际任务脚和这六返回点，85/0/1131ms自然0，小header BA50D6EC；0旧route重播/0raster/0native包解码，1ObjectDB warning非clean。07作者仅新增该任务NPC脚位，原身份/触发/奖励不变。
- 单新mask隔离导入和原生检查自然0，80/0/139ms，完整raw/import/direct RGBA B6D6同、23参数/mip0/detect0，1Image警告非clean。Root批准并只晋升原ABSENT sidecar EA3C3D1E（1012B）/ctex 2DA462CA（1038B），receipt 2CA9B4C7；PNG未改、无主项目import、md5未晋升，保存精ticks保持。
- 保留所有原失败：prior01 Rect2i API解析、prior02 JSON整数类型、publisher02 helper重复变量（实际挂起后仅Root验证的自身child113968被停，退出-1非自然；有纠正JSON）、publisher03/05路径失败、suffix01混缩进解析。新后继不擦原证据。
- 待最终runtime/ENV/Router最小包、一次候选parse、街坊overview与真实Field/门返脚、冷暖入城计时。Router原混合CRLF保持，禁止借运输暗全文件LF归一；DT原尾LF保持。上述组件检查不是全城正式合入或10秒目标通过。

## 接入前残余（25日凌晨，正式仍24c）

Root整区overview02自然0/350项/2511ms，实际43 Sprite与5用途但无NPC/Player/Field。Root看出旧底图仍有孤树影/矩形旧地块，故仅加入一层既有干净court_stone重复铺地，不改原PNG、43实体/geometry/mask/五用途。overview03自然0/350项/2207ms，Root已看84060_2655实图：旧影与烙地块去除，三层街面/两后院可读；街/院仍近同灰度，不能授整城密度或氛围完成。两图均有WASAPI回退及旧退出Texture错误，0SCRIPT，非clean。

Root精33旧目标完整备份D09FC，preparation0AFC只授权33=18GD15JSON的来源准备及Root Stage。旧10 OWNED成员不扩，原139证据叶全保仅新增9至148，深度16不扩；Estate仅因Field退出无条件消费而精加普通Perf03一叶，保registry三等与完整逆。Stage01实际自然0，33目标/4独立map/全源首末同，receipt C9810B93；只SOURCE_ONLY，未部署。

14GD parse实际106948自然1/29项/2060ms：C/DT/Field/G组件通过，Router新增脚本常量直接call触GDScript静态调用错误。System仅显式Variant接收器1hunk修正908F2254，13CR保持。残余10 parse11904自然1/29项/261ms，Router/ENV/AA/AC/Coord/Temple通过，session203动态表达式局部delta无法推断类型；后四helper未到，不能计通过。旧FAIL/代码及日志保留，下一只补显式类型并收齐未执行脚本解析，再最小来源后继，不复已过几何/旧14整体。

码头三同ID独立候选C894C34C：北仓西移116px，两铺门高145px，供给铺两侧完整檐净距98.756/97.333；原仓返脚754610→638610，室内几何保持。尚无实际局部mask/路线或正式接入，不以静态数字冒通过。

## 33目标已部署试验与当前运行阻断（未交付完成）

余4解析122028自然0/17项/小范围通过，只有ObjectDB退出警告；Source03仅显式类型与SELF路径精迁，Stage03 EA657A57实际自然0/33目标/4map，原OWNED10/139+9/深度16与整逆保持。Root依据限定试验批准，18GD apply_patch、15JSON逐字节机械复制，Router先同LF语义再恢复原13CR；部署D5AA84D4逐33候选SHA同，编辑器51856一直保留。guard75F4A750实际通过：原2120+UI1，33授权变化、其它2088与15save精ticks无差（相对本轮fresh起点）。这不是运行功能或城市艺术通过。

Market02实际117104自然1，30项/3910ms，尚未进入Field：B报告完整bundle/legacy来源域不等。只读静态发现C会展开新复用府衙墙PNG的既有import/ctex两叶，Stage未声明。Root精3备份并部署3550AA2E：APMarket及finiteMarket仅legacy+原Yamen固定2叶、APCityIndex仅2摘要，完整逆8FE17858；原1851→1853，其它三城仅共享index一个旧值更新。没有新媒体/导入或功能代码。Market03实际22396仍同处拒，证明这2叶缺口并非唯一原因；原两次FAIL全部保留。暂停猜测后继，正在准备一次必要的Market专用B.manifest/C路径域诊断，禁止关闭校验或旧四collector复跑。

WorldGate05实际73212自然1仅QA初始World身体域误用，未进入Gate。继承城市Rectangle34×24的_clear拒绝真实World Circle5；原Luoyang portal UV数学本就是4000/2594.4912，不是网格snap。NEW06只World实际enabled Circle5/position0+原World17点合同及Physics，城市super不动、.3px/60s20s/0PNG保。

WorldGate06实际38032自然0，81检查0失败/19.969s，42Physics/31INPUT/3真实Space，保存/source首末相同。真实世界96px行走不等待预热，首入Gate hidden可动post_draw **11.193274s，未达到10秒**；返World1.925522s、重复同活Gate1.575388s。后者保同Field/Scene/Player/layout与旧token2，warm FINAL不冒新fresh SHA。预热PENDING在Space前只自然运行247119us，纯SHA首任务2lane总4.089282s，claim后剩余等待3.200114s，postjoin98.896ms，fresh末检2.294406s。背景启动同步166.473ms；记录32.695ms帧间隔不覆盖这段，不授全World不卡。WASAPI回退、旧纹理退出错误/3Image警告非clean，0SCRIPT。下一唯一高收益候选为纯预热2→原H默认8lane，仍完整SHA/claim/末检/取消join，不改Loading、不人为等预热；未实测不得授10秒。

## 南市实际有限验收与8路加载结果（2026-10-25）

- 唯一来源诊断确认tuple两叶以外还有finite header的`legacy_source_sha256[APMarket]`旧值，Root仅精迁该边及index摘要（D596EF3C），未关闭B来源校验。Market04自然1/40项的功能前缀已进入1170,1860，完整1853源自然FINAL通过；失败为书门QA直接用JSON双精度比Node的f32往返产生1ULP，不是放宽坐标容差。
- Remaining05自然1/871项，书门按源f32链、六新增真实实体/碰撞、八NPC迁移、主街真INPUT及第一图通过；横穿服务街撞到原刀客1260,1480而失败。后继Remaining06只走合法NPC间隙折线，未暂停/搬走NPC或关身体：91668自然0/550项0失败/27224ms，485Physics、470INPUT、两次Space，实际服务院图及药铺进入/同Field、Scene、Player、layout原脚580,1212.2347精返通过。停止旧路线/门/六体八NPC复测。
- 新五用途profile04只调四组tone/contrast/core；原几何、矩形/材质路径/.25纹理尺度/边缘/第五树土组不改。Overview04自然0/350项/2214ms；Root看图仅准地面有限可读性，灰空地仍明显，不授参考图级整城密度。
- Root精29备份A235B1D4，原38份加本次29共67份。9脚本仅解析自然0。Stage29首input因ENV不可变scalar过时在输出前FAIL；第二只修该scalar和新输出目录，3A67564E自然0，29=15GD+14JSON、4独立来源map，原OWNED10/旧148证据叶保留加6至154、历史深度16不扩。FE154945部署逐SHA同；Router/DT/G/native/mask/registry此次不变。before guard2553C174通过2121项、33授权目标、15save exactticks、67备份，外差0（相对本轮fresh起点）。
- **WorldGate07：7048自然0/82项0失败/17915ms**。纯Hash从2路回原H默认8路；无预热等待、无Loading口径变更。世界96px真实INPUT及Space首入Gate至Loading隐藏、post_draw且可动 **8.812578s**；返World1.944981s，再Space同活Gate **1.675133s**，仍同Field/Scene/Player/layout/token2。完整966源自然fresh FINAL末检2.379263s保留；剩余claim等待602810us、postjoin102021us。最大World首绘后帧隙169108us包含预热同步启动，因此不授全程无卡顿。只授本路径本次首入/重复达到约10秒目标，不外推默认世界启动、进程总启动、SSD冷或其它城区。receipt0CCD60C6，结果`game/build/luoyang_loading_20261024e_perf01/world_gate_benchmark_output/7048_2858/result.json`。
- **Market profile07：94260自然0/44项0失败/12998ms**。普通default单图、完整1862源自然FINAL及五真实material新值通过，0INPUT/Space/旧功能重播；Root已看`market_profile07_output/94260_2826/01_profile04_actual_default_original_camera_no_route.png`。只授当前南市地面/街坊显示，不将整个脚本耗时冒加载成绩。旧退出Texture错误仍在，非clean。

## 码头剩余附楼（当前未部署）

三同ID：北仓870,580→754,580，返脚754,610→638,610；绳铺600,1510、供给铺1860,640均按源门高145px。仓↔供给完整alpha净距98.756px、供给↔岸栏97.333px、绳铺↔现有粮袋96.112px，旧native29及DG10身份保持，不增假入口。

独立prior84604自然0/551项0失败/1801ms，1packet/1rawPNG，311432访问像素、206555变化，child RGBA0D0A5871及整逆通过。发布78128自然0/43项0失败/2173ms，独立child/域/全原记录逆相符，48点仅三个新短门前，旧routes/NPC sweep与变化域全不交而继承，不重旧全域。两次有Image/ObjectDB警告，非clean。运行helper及C/DT/Field/G消费者准备中：完整actual39导航整值核；视觉只三目标同ID完整行迁移，原任务阶段隐藏的非阻挡物仍由原CITY_TASKS producer决定。单新mask隔离、正式来源后继和实际仓门往返尚待，不能按CPU通过冒正式已显示。

后续单mask隔离：import108332自然0/3512ms/空stderr，保护7源和15save同；verifier124876自然0/82项0失败/132ms，原PNG/import/direct整RGBA0D0A同、23params/mip0/detect0，1Image warning非clean。Root只晋升两ABSENT叶（sidecar31EF0459 1037B、ctexC57D127E 1294B），receipt A2E8D90E；不晋PNG/md5/不导主工程。有限trial BF23CEBD仅准同源素材与作者布局实际检查，不提前准ART。System冻结helper3340EB04/bindingDFFDED2E，原五GD完整字节正逆6ED8FF6E；Root唯一parse69388自然0/54项/1947ms/空stderr，逐五load/can_instantiate、0实例/方法/几何。下一31=16GD15JSON旧父精备745E2338（合计98份）；准备准2E8E23A9，不等于正式部署。

## 最后31接线与码头实机收口

首Stage31自然1保：原AO独立map里Coordinator29E953到新C819最短16边，原`range(16)`仅测试深0～15而拒；非生产源缺失。残余03只从已固定FE154现役parent map增量、仍原approved核现役1边，并以原AO声明操作另数学重建整表精比；原4AO literal/五gates、所有旧边/OWNED10/154+8=162/16限制不动，不加历史捷径。02是未运行草稿、03另修map selector，均保。唯一03自然0，Stage8EA2ED3E/31目标4图/首末源同，Root授权45E45E3B后16GD apply_patch与15JSON精copy实际EE47AD85逐SHA同；Router/ENV/native/PNG/原室内geometry不变。四独立图974/1352/1844/1874。

实际05自然1/7项2FAIL/19ms保留：还未入Field，唯一QA嵌套JSON float Array与int Array直接比较误拒，尾whole-scope为complete=false级联。NEW06只二元numeric schema→原Vector2精等，不加epsilon/不改fixture/生产。

**Docks06：21392自然OS0/114项0失败/23213ms**，结果88CD7BD5。普通default首次设置后自然完整1844源FINAL；三真实Sprite/新变换及enabled底座、全39导航/35solid、Field/DT/Player motion guard同一effective mask与token过。三次明确QA inspection定位（非连续旅行/非性能）后32真实INPUT、47Physics、612局部mask点；原仓门精638,610的真实Space进入→原室内短行→Space返回，同Field/Player/Scene/layout/token1/mask及原脚保持。0旧路线/NPC重播、0QA collector/packet/全mask重构、1原相机北视窗图379B877F，Root已看，仅准北仓/北铺局部比例和间隔；绳铺不在该图，三Sprite比例仅实际技术过。WASAPI回退与7旧退出Texture错误保留，0SCRIPT，非clean。独立source角色只读承接事实一致。

最终guard D1D20983通过2121=2120+UI、33授权目标、15save SHA/bytes/exactticks、98份全文备份及两mask共6条路径，和pre1EFC16B9零差/0external/source稳定；pre前两外部save变化保留。只剩用户editor51856，Root引擎全部自然退出，未停用户进程/模型。停止本轮组件复测，可普通重运行查看新南市/码头；本轮加载成绩8.812578/1.675133是29预热包的真实World→Gate路径，最终31仅加条件码头接线/普通来源后继，未重新授最终所有区域加载。南市更连贯但大灰空地、院墙与其余片区城市密度仍需后续，不把有限通过写成全城达到示例。

资源复用索引已同步人工采用状态后重建：1779份文本扫描期间SHA同、5699行，无显式路径缺口；不把生成器静态扫描冒新游戏验收。当前南市/码头helper和原图路径保留，不移动或重写素材。
