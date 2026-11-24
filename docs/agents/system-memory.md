# System Memory

## 2026-11-18 · 中后期招募、装备与出战名单

段长风、何平、罗望复用原招募入口，悦无姮在第八章集结地开场后可邀请。新招募按当时主角等级初始化七项属性。载入时保已存等级、经验与伤势，旧队友只补模板武功和未穿戴部位；发放记录防止重复赠礼。随身装备由独立实例直接穿戴，满包也可随人入队。三本秘籍复用阅读与任务奖励延期入包流程。

角色页切换出战／待命，实际战斗与敌方编队使用同一五人上限，结算按实际参战者发经验。隔离验证 29/0，含满包读档和三本实际研习；集结地及角色页桌面 8/0。

## 2026-11-06 独立分层2D四向与动作生命周期

lab Actor新增direction/play_action；up/down真实独立clip，left侧向镜像；不存在的正背hit/defeat返回false，预览UI明确侧向。attack/hit/defeat不循环、finished停末帧，重播清状态；idle/walk循环。原hand_center不随web迁，原7图保持。背面socket切0而非-1：-1会落在祖先背景后，结构QA不够，后续GPU开关武器差2066像素通过。仅隔离lab，Player/Battle/Router/autoload与存档未读写；仍不能宣称正式接线。详docs/changes/layered-actor-prototype-20261106.md。

## 2026-11-06 独立分层2D试验台，正式接线未做

`game/build/layered_actor_20261106_lab`独立project/.gdignore，无主autoload/save。actor按item_id两武器、3×4f同身体，逐帧脚/握/尖点、缓存Atlas手部前景及局部资产FX；矩形遮挡仅人物武器.42ghost，原遮挡物不透明。159功能检查0失败/空stderr，自有自然退/原editor51856保；首相对路径退多层与首输入未ready导致FAIL均保。未改Player/Inventory/Battle/Router/project/来源链；不能正式采用只有右+左镜像的样板。手部矩形mask、正背/全动作/刀剑差异握法与真实遮挡合同仍待。详[范围](../changes/layered-actor-prototype-20261106.md)。

## 2026-11-02c 切图先显 Loading／真实就绪退屏，冷加载总耗时仍 OPEN

本域正式 CityNavigationRuntime `E0DE2AD6`、新 Screen 子类 `4889191F`、102-pin manifest `B5A685AD`；旧 LoadingManager／Router／Region 与其严格来源闭包未改。现役11pair的 `_travel` 先纯 UI 实际 postdraw，再做原深校验和原 public dispatch；每次完整媒体 SHA 以纯 FileAccess Thread 新算，不以永久缓存、mtime或松 guard 代替。原 LoadingManager 自然 reset 后，保留屏幕及独立输入锁，完成原 lease、Art／Mouth、真实小地图 capture_ready、图标准备及 postdraw 才退屏。普通房门直进的前段同步校验不因此变为全异步；不得宣称所有地图零卡顿。

Root136480原配对实际首 Loading6186.053ms，退屏后5861.448ms长帧。73400／133776虽各自然0、6/0，但仍退屏后4832／4952ms，均保为功能部分成功，不能冒性能已修。typed vs dynamic 原 PackedScene小测各 override1，静态调用绕派生假说已否。122040有限64事件实证：旧 smart-field 非 field_scene_id 路径在 `current_scene=null` 时调用 hide（20261822us），子类因无 Field 落 base fade；至22910778us目标 Artisan才安装 complete，随后 `_process` 才补重 attach。外部 flags／重复hide猜测不是这次实际根因。

修复只在已接受 pair 的精7字段／固定端点／Router目标／token／visibility generation一致时保留空窗，等待实际支持目标完整 ready，原子移交既有 prepare；无伪 Field、无 manager flags/token 写，无 actual目标 complete 前 actor 写。Screen拥有pending job时host不抢先清pair或二次attach。102叶仅 runtime／Screen精两叶后继，其余100值保持；C709父全文及两脚本在 `game/build/transition_latency_20261102c_candidate01/before_install/` 保，候选 manifest全文逆同，回执 `install_successor_receipt.json`。

Root137624自然0、6/0：首屏95.022ms；hidden25574.465／operable25574.689ms同帧，退屏后最大31.162ms，**本域先显屏与真实就绪退屏已过**。但总冷切图25.6s、屏下最大10537.847ms，性能总耗时仍 OPEN，不得把卡顿移进 Loading 就宣称加载加速完成。Root另报17392 Docks／Garden两真腿8/0；99776／34956原35秒超时失败保留；共享cache功能65项本轮无超35秒但明确 perfpassed=false。停止本域引擎、代码和sourcepin追加；Root最终文档及全局guard尚在收尾。系统本人0引擎、0存档内容读写；详自有 `PLAN.md`。

## 2026-11-02b 入口显示独立最高世界深度（正式有限修复）

用户林西采药房门前名称被坛罐遮住，真实原因是共享ExitZone三个显示子节点仅relative30/31，PortalLayer500/1100仍会被原生足点排序/4095人物影像越过。新独立`build/entrance_overlay_20261102b_runtime01/entrance_overlay_runtime.gd`只改MarkerVisual/Prompt/Indicator为`z_as_relative=false,z_index=4096`，不抬Area2D/人物、不重挂节点/动transform、alpha、visible、shader、碰撞、路由及存档；HUD40/System80/Dialog120独立CanvasLayer仍在其上。不能只抬Prompt或只改局部z。

同因消费者是MainField普通/World15/洛阳V3/野外派生、四聚落Field、ThreeTown World新增/WorldReturn和CityNavigation pair。用node_added deferred+一次既有group接入；World31c `raise_names`可能在稍后挂城地标时把已驻留文字重设4095，因此priority1000只校正已登记显示WeakRef（不每帧扫全树），晚建Zone/显示子节点也接入。旧Field/ExitZone/Router/严格source manifest与媒体全不改；Root已合project一autoload行。

Root实际23860结构17/0、132008正常12/0：真实packed ExitZone/负z祖先/4095遮挡及晚写/lateZone与显示子节点/原变换alpha、shape、业务和范围信号/HUD40层已有限通过。林西采药房原camera.9、18登记显示，原坛罐有效深536而入口箭头/文字4096，Root正常图亲看完整在罐子之上；仅此视角ART接受，非全部地图逐处验收。QA脱树readd旧owner的WARNING保，不复成功；系统本人未启动引擎/读存档，停止实现与重复验证。详[正式有限交付](../changes/entrance-overlay-20261102b.md)与[最小范围及消费者](../../game/build/entrance_overlay_20261102b_runtime01/PLAN.md)。

## 2026-11-02a 三叶路口后继/11pair双向正式有限交付

仅2同pathvisualhelper+1Pair+manifest：7605/96→9EBD样板99→CFD6推广99→C237 Pair99，媒体GROUND3原值保；不触134旧源/Router/Region/compiled/NAV或21/33闭包。Pair单行仅yamen_artisan/a mouth720840/arrival824840，retired720970/其它21端保，fresh1 8A450全文精等原d815/208事实，不能用after重置before。原677A hunk中文label传输损坏预检拒/0生产写，独立UTF8 AE22整正逆后apply3B408保CD338。

24624补14方向；Civic原墙实体始1024而瓦檐投影始918.4，原口脚安全仍朝墙，须北移实际口而非只挪marker/删真墙。97124只重证该pair2真向/返824840，功能unique22=旧8+14−旧2+新2，20不复。97124自然0/109检查0/8INPUT/1新图，Docks原Scenezoom1.05尾oracle实核，不重拍/不把原73468整FAIL洗PASS。22分类14短轴+1South原样+7保真路；53220南口、97124北移Civic口及原821E Docks土肩仅本域有限接受，非逐22ART或强美化全完。

唯一guard02 C476EBDC PASS、sourcepreflight E1E959D3：208有限源/204精同含134、99现役C237/93原叶同，171metadata精同9absent、只after1pass/0档内容读写恢复。旧guard01未执行/原阶段证据保，46516/73468Civic拒/UTF8预检/旧退出ERROR保。全engine已退、仅editor51856前次保，不再检测；[最终记录](../changes/scene-quality-20261102a.md)，交重新运行试玩。

## 2026-11-02（11-01d）配对路口/Docks精21闭包正式有限收口

独立CityNavigationRuntime用精端点同源触发/方向/固定安全落脚/返回/路口/mini，原建筑剧情门及World-origin岸驿事务保，Region/旧Router业务不改。百工原marker被边缘钳离trigger82px，不能只扩near。Root131104百工双向、25304 Market↔Temple双向真Space已过并继承；25304随后Docks public accepted却未到/144检查8Input/0图整FAIL保，不能把accepted当ready。Quarter1282源旧3Regionpin先精2后继，原1279值保；刀客compiled28004240，QA正南4360缺floor，固定东29204240全脚/NPC巡路安全，仅改QA。

Root只读diag02/113404自然0证AC入口manifest387CEBDE精同，但B.header先AA.author拒：普通C最外仍硬F1C8，当前正式7EC013FE，故author空/collector0，早于AC legacy2494中Linxi ADC0与3Region旧pin。Root批准currentC→固定F1整逆层续AA，AA新bytes再由AC→固定FE1整逆，全部旧proof/author JSON保；AC既有EX owner仅1新逆边，OWNED集合/其它row含完整Router链精同。最终既有33域实际21目标+3新runtime叶，精source-map/index机械闭合，原EX luoyang_ snapshot前缀不松。Root fresh9201D551/21全文备后明确授权本人apply_patch2GD+nativeCopy19；实际回执3CB1B016全21after字节SHA及整正逆过，C/Router/Region3/10bin实核精同、与原113/冻结96交0，0engine/0save内容或metadata读取。静态virtual AC2562/Gate1722/Quarter1285全预期无差不冒真实C/B通过；Root109688真实consumer C2583/剩余2pair四真向及修后堂图已过；总4pair8真腿非11pair22全实机，382检查0/16INPUT/自然0。原25304/诊断01QA-only toast ERROR及旧退出ERROR保，不冒11pair全实机/全城ART；详[本轮](../changes/scene-quality-20261101d.md)。

Root115984实际C2583/B2574只多9既有批准Router snapshots，selectedACmanifest/index精2第三阶段追加9/原2497值及其它JSON保，apply307CBE80；两目标是21子集，distinct源134=113+21不重复计数。QuarterD834初段/9201全文与3CB实际21after逐段双逆；03因Root已审正式before并授权apply，不补新capture，取固定21全文snapshot作前驱，不重置baseline。Art同pathE261→8B4D只relative标志，96旧64B全文存→760534仅1leaf变/95同，Root109688前方有效楼265/人273/僧268正常图接受、旧91216遮人拒保，后方.42合同保但ghost_pixels0非背后新实测。auth30868A后唯一final03/158D1D01 PASS，直接原113final FDDBE8D3一次/96+3runtime/171metadata精同9absent，0档内容读写恢复，onlyeditor51856；停止engine/重复验证，非整城ART。

## 2026-11-01c 独立步态/墙闭包已收口，精2补充不重写183baseline

Gate新seven26c两前墙退役，29m旧两墙仍退；runtime同path/newbinding触6direct SHA+material，31target仅SHA/BIND/source-map后继，EX原3owner各1逆边不扩Router/OWNED，AA/AC保。NPCGait只project一行，NPCNode/Region/10bin/11b60与World16保，16叶9101DB不塞旧FIRST。102424/66检查1错保、World+C/B1727过，x600 query命中gallery55柱后仅QA650残余；57604自然0/7770检查0/14Input、双墙真W/原daily自然收尾及3图有限接受。native228另MainField旧pin需2literal，A924补充fresh2全文备份必须同原183 before；不改baseline/strict、不用after补before。Root批auth106361DF后新guard26DF2620 PASS：183源/33授权恰33变化/project一行精逆/171save9absent精metadata/16叶/36备保持，原guard不改。旧7ERROR/ObjectDB/Imagewarnings/失败保，onlyeditor51856，无真实save恢复回写；停止复验非完美footlock/全城ART。详[本轮](../changes/scene-quality-20261101c.md)。

## 2026-10-31b 岚溪梯田左通路

四田原图跨L1东坎造成石岸穿田假象，四田整体内移并等比缩小，Art/visual_rect/Body同源同步，原cliff/四阶/三桥/31a板街全保；新继承31a helper仅旧合法新田体覆盖脚迁声明田埂，不nearest。正式Scene80D0/nativeC38B/registry9DA1/helperB1D0。Root84652自然0/37检查0/6输入/20960ms，P4物理Y2700/L1/H120同实例A6890→6103.5再D6890，Cliff7真实接触未越界，6300,2790→6500,2880旧脚迁移过；EAA37原图已看石岸田分离。末guard38429886核986源恰3授权/171save精ticks同/9absent/202依赖0外差，onlyeditor51856。旧7退出ERROR+ObjectDB保，停止源码与引擎验证；详docs/changes/lanxi-terrace-passage-20261031b.md。

## 2026-10-31a RaisedMarket3/4侧边

两木街物理L0，原北栏短/南侧无体，不能把画上支架当高度层。延原北栏+新南体layer16/mask0，桥面X−574.2..575.94，不封端，不碰原水。新继承30l helper只旧合法新边覆盖全脚35×25同X归中心Y，并核原碰撞/原短北栏与目标净空；实际actor34×24/mask24，接触断言不能拿保守迁移脚额外.5px误拒。SceneCD88/native0F39/registry83CF/helper21CA；83612局部42/0，旧控制器/三桥四阶/PNG保持。旧166无UID节点不能触发全Scene重存，四新节点不做额外规范化。详31a专题。

## 2026-10-30n 武当华山采用

新独立Field继承30a宿主复用原两draft，补缺失Space fallback而不set_script/改原controller；原NPC1/0与四门户ID/action/内区保，3005隔离旧UV/同版合法脚全足精保。control与return写入同时检查current owner/id/loading/dialog，避免离场native仍移动/污染返脚。原World generic gateway会覆盖记忆脚，新精ID复用原REG.leave_town并记真实入门前脚，原Router/MainField不改。registry229D/native44E仅两旧源，旧14/166保→16/200；Field720F/contract33F/entryCF33/data21DB。Root109820自然0/54检查0/20输入，两World/首内区/原对白与真主阶、两图过；末B7F99A06保护970/171精ticks0外差，停止测试。仅两室外非ch3主线/凌月内庭/全内景重做；旧7退出ERROR保，详30n专题。

2026-10-30m：World实际5桥/93视觉改5张native同源整桥+15前栏GPU切片，原88实体/WorldNAV/门/路不改；仅World专stream/overlap，无Router/Field/native闭包。分区alpha需CPU同源核，samePNG按引用只计一次且pressure eviction后重算费用。原TRES与JSON仅8个depth float64序列化差，固定LAYOUT_SHA精提93row/1302字段作NEW严格期望，禁止epsilon。Root125256自然0/184检查0/454INPUT/5原图已看，正式stream2A7/overlap5803/helper9462/bindingDCCA；末guardACB8核600源171save26newpins0外差。原75s41/1、预选6/1及7退出ERROR保；停止本批复测改图，web仍旧fallback。详docs/changes/world-bridges-sect-adoption-20261030m.md。

2026-10-30l 岚溪寨：岚溪寨旧set_fade在派生类关fade_enabled，独立ghost同时检测Sprite与Polygon原UV alpha，不改建筑像素。沿原深度显示同主角0.42影像。移动物件旧脚兼容必须同时满足旧合法/新覆盖，固定本物件门前且同层/净空；凹碰撞需Geometry2D凸分解再Shape.collide。仅专用新控制器，不改共享Player/Router/宿主。详 docs/changes/lanxi-occlusion-and-banks-20261030l.md。

2026-10-30l：LifeSkills5687BBB7只把普通try_gather变pending→新helper5812B078完成终检→原GATHER.collect，原recipe/transaction/Player不改。Field modal bool关闭会无条件放移动/隐藏原panel，劳动动作不得借它；自有actor+sprite token/WeakRef仅藏显示与can_move，foreign panel/dialog/transition/owner换即取消，不能释放他人的锁。独立4hframe Sprite按逐帧源脚定位和负X镜像，原body/移动约束/方向无改，SFX帧2按实际volume播放。Root384/0/30输入真实4帧/Audio.playing+position、满包/重复/Esc/小D取消恢复；矿点视觉仅X1040→925单图6/0继承384，不用抬z穿墙。03saveaudit169精同/2用户11:02新进度保、非save无外差，旧7退出ERROR留。详30l专题，停止测试。

2026-10-30k：独立AdventureRuntime接三newID普通MainField，source connector校验真实ID/region/脚/射线与移动约束后公开go_field_from_portal，回古寺用真实绑定ExitZone认证，不造compiled owner。project加一autoload/gather仅catalog追加8点，原新12行与制作算法/Router21CAF/native/任务全保；自有viewed/wins flags直写不广播。新mini必须SubViewport.world_2d=World2D.new()（无own_world_2d），TextureRect先expand IGNORE再texture/size，否则256被旧1024最小尺寸卡住；Line2D TILE还需texture_repeat ENABLED，再GPU软边，不改PNG。typed Array不要接三元式无类型数组，用append；tree_exiting lambda抓WeakRef避免freed capture。现场24/0、战斗残余9/0自然0，旧七退出ERROR保/04一次资源重复另留。末185事实171save精ticks/两源逆同，详30k专题；不复已过制作/旧城。

2026-10-30j：首批采药/采矿→制药/铁匠制造已正式，5新GD+1点表、project仅一LifeSkills autoload；原Inventory/GameState/SaveManager/Router/ShopUI不写。事务先副本扣料腾格、完整装包及规划原格式实例编号，全部提交slots/gold/serial后才发事件，信号期持锁防重入，失败零消费；进阶三件需5级及真实铁匠stock，锁子甲当前两店未开放。12普通点每点2份，累计3场非逃跑胜利全局刷新；资源状态走原flags保存但不广播剧情flag_set，避免采草重建地形。Root97176自然0/754检查0、131200自然0/146检查0；115660自然0/25检查0/22INPUT仅山道真F草矿、制药和铁盔制造；UI残余73596自然0/9检查0。原QA首编译FAIL及旧七退出ERROR保，不冒clean或全部野外完成；原I键禁用须用左下“药方·制药”。末guard通过，171save精SHA/bytes/ticks同、editor51856保；本人仅实现两新事务GD、0引擎，停止代码/测试。详docs/changes/life-skills-loop-20261030j.md。

2026-10-30e：四地独立宿主复用原Scene业务，运行时仅重映NPC/门/互动脚；旧map.portals生效时不追加legacy热点。版本3001隔离旧归一化坐标，原室内返回按currentID选新门脚；World原landmark脚精读，ferry互返甲板。小地图clone专用accepted IDs且缓存实际纹理。source_valid绑定125源，0共享Router/Field写。详四地30e专题。


2026-10-30c：实景小地图已正式交付，30b色块只作旧基线，不再当可辨美术。canonical CityMinimap C125B513继承冻结841布局/marker，visual_cache E700D251用独立World2D、最长1024随场景比例SubViewport；只new无脚本Sprite/Polygon，Region按全compiled.render源脚/scale/centered/尺寸/深度取全景，常驻Polygon保真实地面UV，非当前chunk。StaticBody仅遍历视觉，不复制Body；NPCNode/CharacterBody/Area/已知Keeper与GateSentinel根排除。UPDATE_ONCE后DISABLED，ready前不露抽象图。Root15988自然0/346检查0/D4真32px，一图真实灰顶树池/远楼接受；首viewport_set_canvas_transform错误保。唯一移位入树赋值后125868自然0/94检查0/0INPUT一图，新错误消，346成功继承不复。RouterDFBD8DCD/manifest09E6E032/23逆边；末DC93EABA核80源35备171save精ticks同，仅editor51856。旧七退出ERROR/ObjectDB保非clean，0新PNG/素材/三FieldCT花园NAV门户改变。现存helper canonical SHA真实pin才做必要后继，新专用模块只绑Region runtime_modules；Router snapshot必须res://build/luoyang_前缀，不能因新目录名放宽Authority。本人0引擎/正式写；后续只按用户新请求窄改，不重成功缓存矩阵。详docs/changes/city-visual-minimap-20261030c.md。

2026-10-30a：三城离场Field在LoadingManager过场或currentID不同时禁止写return_spawn，避免旧脚污染新payload。门派专用host复用原业务，三级地面物理坐标与视觉高程分开；ExitZone必须configure_marker持久偏移，不能只改Sprite.position被bob覆盖。3原入口/内院/条件锁已通过；Router/全局Field未写。详30a专题。


2026-10-29q宅园后园已Root实际局部收口：Router72863831/manifest1954DD35/Field2674DD68/Entry772A42FD、Estate26918BA3。基于并发林西合法C0EDAB77/E959A8F9新九头，保林西全部代码/18旧边/source keys，仅Region常量新第19条完整逆边；原29p39C4旧头在写前guard安全拒，未覆盖新任务。外后门estate27q_hall_rear_door脚15361450→原正厅960240，原厅北160→1450/南出15362060、29o门阈及29p室内保持；rear_cross y1184..1328两端30px正floor缝400..430/2642..2672接service，屋下1620..1740不铺穿。保泥土底，精Estate GardenVisual追加两不规则64px内羽化草岛与world UV384×256圆角144px园路；8现货树群/高低牡丹/石蕨+唯一新荷塘，旧tree_nw620570→580340图与solid2同步。池塘1792×1280/PNG96C1E188/RGBA5A3312CA/ctex76D3C5A6，source锚8961066/foot950860/scale.46，整水+石岸18点源坐标+128后映世界真阻挡，无桥口；Root仅框外A1清理/128补白/一次导入，0再生图。GardenRestore仅精Estate/rev1、本批新solid碰脚且旧A3A1真safe→1450，新body/NPC再核，不nearest/不改save schema；正950700迁回、保留旧树2407681仍拒。128248出版自然0空stderr76/0，单Estate bin/其余9精保；12target首次apply因func片段截断原子拒，补完整行后与候选新SHA全同。最终35156自然0/178检查0/1046真INPUT，Root看两园原图池塘透明无halo，真北门返厅再原南门出2060过，旧成功全城/29o不复。B540E17B通过：55源/21备/171新现值save精ticks同，仅editor51856；原29p并发外差wholeFAIL保留不倒改。本人0engine/0正式部署/0存档写。停止本批代码、封包、导入与复验，候选保留；不冒整城ART或新剧情完成。

2026-10-29q林西民房：旧坐标被最近安全搜索移到仍在旧宽多边形内的右墙，不能只验证候选被拒；本室 helper 校验地板/家具与足缘，无效旧脚回明确门前，合法室内脚保，门户配对覆盖旧缓存并从对应外门读返脚。Router两窄hunk+9必要来源后继17→18完整边，现C0EDAB77/EXE959A8F9；全局Field保持。沈青禾距箭头原小于118px会截Space，移位而不改互动优先级；筐篓补真实阻挡。仅此室，详docs/changes/linxi-cottage-entry-20261029q.md。


2026-10-29p仅会客正厅estate27d_living_hall视觉边界已Root局部接受，原wholeFAIL不得改PASS：实际98124自然1/79检查1/340INPUT，唯一SOURCE_FIRST_FINAL为其他聊天同时改动4个外部三城registry/native_sources及赤岩/沙漠scene（guard8375D57A），不属于本室修复；外差保、不还原、不为此重跑本室成功旅程。真实进/出、南北两正常原图均成功，Root亲看无黑灰露底，仅授此室边界修复、不授全城ART。现役本批Router39C4C81D/EX73479C37/RegionManifest25D82B40/RegionField41415912，11必要来源后继16→17边、旧keys保，Entry B1C6/29o门槛与旧脚兼容/29n内外/全部10bin精保。根因是floor只96..1824/1344且沿用庭院砖、竖墙错误复用南端32px横边、旧shader fragment COLOR已含默认整shell采样再*=导致整PNG alpha/横梁二乘，且归一化UV错当px。专用hall_boundary/helper+room_patch shader精ID截本室floor/wall，vertex颜色单独传入、UV*1536×1024后真实局部repeat，室内floor600780/280120及wall/cap现货全alpha255样本，0图片像素/导入/业务改；北/侧224高连续立面、南前128 cutaway，南北真实门洞保。仅本室正常Camera limit_top−128容纳北墙，zoom1/主角1.12保持；opaque visual backing覆盖真实可视(0,−128)..(1920,1440)及512装饰bleed，不扩walkable或改NPC/家具/原门户。Root93572元数据publisher自然0/7检查0空stderr，首次Field+helper真实parse通过；本人0engine/0正式部署/0存档写。QA仅静核自有闭包与171现值save，不能以本条冒最终全保护无差；本轮停止实现、封包、解析、图片处理及功能复验。

2026-10-29o豪宅会客厅门洞已Root实际封为交互入：截图精owner是Estate的estate_ak_main_hall（main_hall.png），不是怡红院、Civic豪宅或真正outer_gate。原左右实体idx6/7夹x1472.2962646484375..1599.25830078125，y1881.688720703125..1920，中央为空；只新增同x/y1881.688720703125..1971闭口quad及solid_cells，既有144×32门estate27d_hall_door脚1536,1984/去estate27d_living_hall 9601260/返15362060全部保持，outer_gate15363760仍通。118016出版22/0自然0空stderr，其余九bin/图/原solids/NPC/门户不变；正式Estate新binA3A1AF2A、manifestF7BCD35C、RouterC5A9295A/EXEADC879A/EntryB1C6DDD0，11target最窄闭包15→16完整Router边/旧keys保，Field/Authority/Culture/29n内外bin保持。为防截图中旧门洞脚若已保存导致“又进不去”，Entry仅接原REGION_SAVED_FOOT_BLOCKED，委托threshold_restore：精Estate/revision1/此次源quad相交且immutable旧07D64 bin原完整足体safe，才迁明确旧门户return15362060并再核新body/NPC净空；旧本已墙内、其他障碍/未知范围仍拒，不nearest、不读写用户save内容/不变schema。唯一103828自然0/66检查0/60INPUT：真实W停1536,1988（8px离散，不硬等1983）、Space入原厅/精返/返后离开、旧gap脚迁回与旧墙脚仍拒两逻辑case通过；Root亲看AACC3C6C门前主角全身。guard8390D104通过，旧七条纹理ERROR和ObjectDB警告保，不称clean；0新PNG/导入。本人0engine/0正式部署/0存档写。只授本门局部，停止本轮代码、封包、解析与功能复验；不得误封连续前院outer_gate或扩到其他门楼。

2026-10-29n怡红院专项已Root实际收口交试玩：最终RouterE8ABC085/EXD03C4E3D/RegionManifest6BA977AE，Civic C0A84079/Room4871B3E4；RegionField2AD83F42/Entry5D6DD291、全局Field CAE9/Authority F120/文化29l分支及三城保持。首两原图拒门前齐切头和屏风遮掌事/主角，visual03只把源门洞580749..748923并入原低层踏面、其余墙柱与物理精同；室内撤唯一quiet_screen render及源donor实际平移后的typed solid，雅座不再冒“屏风雅座”，6NPC/对白/原生厅/其余家具/门与8旧bin精同。60160残余publisher自然0/23检查0，10target纯Router头与必要来源后继（14→15边、旧keys全保）已Root精合；未知SHA拒/历史pin/当前Culture三准入仍过，ObjectDB warning保。最终20208自然0/75检查0/102真INPUT，柜前原正式精坐标setup后只余真实退出/两原图：Room Space精返Civic5206.18,4280，主角门前完整头脚、室内无遮挡原图Root接受；前缀入楼/主角先开口/掌事同人肖像/静态身份成功继承，不再重测。首trip旧can_enter oracle失败与126584固定tick返路误差75/1、133240柜前FAIL及各原日志保，不洗成整轮clean。finalguardB41FF062通过：57源/12备/171save当前事实保留（包括用户新save），仅editor51856存活；本人0engine/0正式部署/0存档写。只授本楼局部与进返，不冒整个洛阳ART/加载目标完成。停止实现、打包、解析、导入及功能复验；后续不要重跑旧publisher把已退屏风带回。

2026-10-29n前置12target历史（已由上段visual03收口）：Root精合Router29F597D1/EX6811E162，RegionField2AD83F42/Entry5D6DD291/manifest8D4FC4C0；独立Civic bin42B3A77E+新Room9D818170，其余8bin字节保持。新外图Root生成/局部清边补白/3叶导入，1441×1206、门槛664922、前阶锚6641010，contact5206.18,4174.42及uniform1.152123，不能复用旧1540×1277 UV。源UV把中央踏面和高身分层、source foundation减前channel，正式门enter_yihongyuan27n脚5206.18,4185/返街5206.18,4280；新yihongyuan27n_interior连续1536×1024原生木厅，明确大厅/雅座/备茶后台，不冒小院或可上二楼。6普通成人/4同人家常主角先开口/2坐客无同人肖像仅环境；柜后掌事1150520、柜前1150584可达64px，新增对白零奖励/flags且强Ref owner pin终止解锁。首publisher133240 COUNTER_FRONT FAIL保，精因折屏1040620 footprint碰柜前，唯一搬1170640后Root58540 33/0自然0（6图load及退出警告保）；12source闭包只Router单常量新14th完整逆边，Authority/Culture/全局Field/三城不变，旧13边/旧source keys全保。Root最小admission117440自然0、历史pin获准/未知SHA拒/current Culture.readiness三断言过，ObjectDB warning保。本人0engine/0正式部署。

2026-10-29m城门两孤立膝高横墙已Root实际退役：精ID finish_i_gate_queue_low_edge_west/east（500/900,1450），同时撤visual_additions4/5、effective_navigation41/42、effective_solids49/50及2530专属NAV像素；无独立base，原PNG自带基座随本体撤，整院铺地/真围院front/竖墙/NPC/门户保。Publisher132376 16/0、NAV隔离自然0及3新叶；沿既有31域仅const/source SHA后继精合，Field CAE9A1A5/C F1C8/Coordinator B685/EX A148/Runtime A92B。25116自然0/158检查0/80INPUT，仅两墙cross+1正常原图Root已看；82548原141/1保，是QA显式城内spawn却local_version=-1导致默认1被PUBLIC_CITY_REQUIRES_CURRENT_COORDINATES拒，最后参数改本城3即过，生产不再改。World版本15不能代替最后本城版本3，不为QA坐标版本误用修改生产导航。finalguard9CCCFFC4C130ABDECA68945DFF006627D196C7EC6D24FF5A215E7B1B266A8668 PASS：136源/99备/171save SHAbytes精ticks，31授权差/0外差，仅editor51856留；原7退出ERROR保，不称clean。无原美术PNG改变，停止本轮实现/解析/出版/导入/功能复验。

2026-10-29l洛阳入口回归已Root实际修复：9target精合Coordinator50500E8D/EX56D19060；Router5D6AAA78/Field E22564EC/Authority F120/文化CT/三城模块原封。根因为文化Coordinator readiness原26项直等中Router仍pin D25DA6FE，另Authority.edge_valid要求new_snapshot为canonical或res://build/luoyang_前缀，金陵/三城两旧快照命名不合；机械全文逆不能代替真实准入。新luoyang_entry_regression_20261029l_system01仅Coordinator精Router分支复用AP_NPC._source_matches完整approved，其余25项直等；两快照按原字节合法前缀重发/旧原件key保，EX302→305、Coordinator39→40、Router13边保。Root33236 headless21/0自然0（保ObjectDB warning），127460真World Space入洛阳86/0/5INPUT自然0、32px及正常原图已看；入城至图11.091秒，非10秒加载达标。最终guard4446C44B…核75source/60备/171save SHAbytes精ticks，9授权差且0外差，仅editor51856留；原7退出ERROR保，不称clean。停止本轮代码/解析/功能复验。今后所有新EX snapshot必须遵守原luoyang_闭集；任何公共Router接线后至少实际运行Culture.readiness与Authority.approved关键旧pin准入，不能仅以机械inverse或新城trip代替；admission_probe_READY.gd含未知SHA负例可复用。本人本轮0engine/0正式部署。

2026-10-29k两派新namespace复用i高程引擎，新terrain从各layout.terrain读；同边多个阶口按已有pieces逐段切除，修旧“后一个口覆盖前一个口”的算法漏洞，不改旧i。只画朝南可见坎面但保全部物理边；物件按层抬Art/物理基座原XY。W0/180/360、M0/60/120各4阶，桥先落平岸再走阶。61新文件可F6，烘存重载与实际键盘通过；Router外部改动不在依赖，不覆盖。详docs/changes/sect-maps-20261029k.md。

2026-10-29i：苗风真高差独立场景AD58BA14，terrain.json单源0/120/240多边形/4阶口；逻辑XY足底、显示y−Z，进入正确上下端才开启ramp，连续插值并按投影校速。共用8+楼层16/32/64，坎边两侧同挡/仅阶切口，阶侧轨防逃。建筑Art投影/物理基座不搬错，居民父类帧后减高程；缓存厅mask1/同actor原脚返。原生Terrain138节点已pack并标baked，重载跳过生成/二次抬高，保坎双层mask，7/0。真实旅程3795INPUT出生点经两阶到民巷5/0；7新文件/0共享写/0PNG导入。旧f/g/h平面阶检不作高差依据，详docs/changes/miao-terrain-20261029i.md。

2026-10-29h当前49A6建筑差异版，12替换体量及地面院材同步；转角作坊按轮廓作凹形占地，低宅正常门105px/厅楼119—120，200高粮棚为储藏舱。只复制控制器改状态文案，旧HouseHall/三Bridge/四Stairs8子树原文同、正式Player/NPC/Router0改；一株厅前树有独立ShaderMaterial局部主角窗口，旧树图/实体不变。新26工程文件/10叶，317保护精同；62/0＋6/0局部GPU，不复桥阶/室内矩阵，未主工程autoload复测。详docs/changes/miao-building-variety-20261029h.md。

2026-10-29g重排版独立2CEC8926/30新文件12叶：斜溪中心线与水域碰撞同源，三桥换中心保原UV窄走廊；高架市场原UV分成Deck/Supports负z与Shops前景，铺前foreground_depth_y=-40（纯栈道-25），让NPC在前栈街正常显示，不能只给Hero开窗而使居民只剩腿。门移1750,1845仍同Player/同缓存厅精返；原shared0写。两房挡路按原碰撞器定位窄移，不削阶侧墙。65/6保，14/0残余通过；旧29f117文件和其他城镇精保，见docs/changes/miao-recompose-20261029g.md。

2026-10-29f苗风山城独立编辑场景91CF987B已发布：本地controller复用正式Player+previewadapter，默认view1/35×25脚/冷孤云v7剑四向动画，同Player两次进返同缓存Hall精返；8居民仅水平四相巡行，左向runtime镜像。房屋、居民与主角统一world-y/4绝对z；桥/阶Base必须z_as_relative=false且保全局负z，否则父脚深度会把踏面提到人物前。复制房材质须每实例独立；曲水画面与静态水域使用同源polygon，保三桥窄开口。117全新文件、52新import叶，0共享project/Router/Player/根tasks变更、0正式世界接线。仅独立同源GPU验证，未重主工程autoload；停止本轮复测，详docs/changes/miao-town-20261029f.md。

2026-10-29d独立沙漠城首版已创建：用户确认29c总规，`game/scenes/drafts/desert_town_20261029d/desert_town.tscn` C37F2B1C可F6；黄沙/浅土坯六区、15民居/双铺/客栈驼棚工坊井台、3民院+驼院井院/2枣椰，63对象87blocker。正式Player跟随/四向walk、6复用居民巡行和一缓存前厅同人原脚进返。14内置原图含1城廓首稿弃用，12透明当前图只增RGBA0留白/原RGBA精同，13工程图RGBA精确；原A1 FAIL保。49/2首FAIL、13/0后继、222/5院轴FAIL和8/0残余保，原图已看，仅首版结构、不授参考密度/全ART；前墙局部人物窗口/全景不透明。59全新工程文件/26新import叶，0旧game写，168保护含162save精ticks同/editor51856保。图库4980/2673图2307音/40新路径缩略核/非resources同，正式世界/剧情经济战斗未接。详docs/changes/desert-town-20261029d.md。

## 2026-10-29 · 金陵连续水巷桥市室外结构收口

- 正式唯一实现位于`game/build/jinling_city_20261029_system01/`：Author`14B56E48`、Field`E22A1A90`、Entry`13E2EE7D`、river binding`D9319AD8`；Router`671B99FC`及9目标来源闭包冻结。5632×4096/layout31连续双岸八用途区、28完整楼、40NPC、两原生石桥与漕运船、民巷井庭/绸业/榜亭/市集已接。原水巡/商人ID、guide/Shop/榜、世界与芦荡出口目的地保持，旧1/5显式迁移、World固定南陆路到达；不改存档、任务奖励或原Scene，不扩绸业商店库存。
- 首actual114832的桥挡北街与24 typed错误原样保。02仅两桥全源等比主`.46`/副`.44`、双脚Y2624及绑定同步，前景Polygon2D改入自有Node2D数组，未扩共享类型；真实北街失败腿1536,1976→4504,1976已过，净远口130.18/124.52，不冒全160街宽无视觉柱帽。86396原76检查/2FAIL保：Hero实际neutral肖像正确、QA旧oracle错；商店返回则真被Author假NPC域拒。03仅NPC占地改为真实Texture2D单格与row.scale对应的居中20.16×25.92体、normalized patrol双向sweep；ground anchoring已抵消shape偏移，Field后置`.8`仅显示不重建碰撞，不得再用假34×32下伸框或关闭NPC检查绕过。
- Root实际77724自然0/74检查0/550真INPUT/22.139秒，原失败脚2584,1944与NPC脚负控、原Shop关闭精返及剩余旅程通过，1正常桥图＋1整城总览已亲看。最后仅04 JSON三段south_quay_cap的6个Y从2560→2580接同STONE街面，X/桥口/UV周期/solid/NAV/代码零变；83404自然0/57检查0、单正常图/0INPUT，Root确认20px土缝消。旧两FAIL、7旧退出ERROR及原日志全部保，不称clean，不重成功World入城、桥、对白/商店或几何矩阵。
- 最终Root guard`FD85528A`通过：35源、15save SHA/bytes/UTC精ticks、9备及原12媒体＋水3叶无外变；用户编辑器保留，自有进程全退。本人只候选与本角色记忆，0引擎/0正式部署/0媒体或存档写。**八区室外结构交用户细节验收，停止本城代码、打包、解析和功能复测；不是全部ART/新内景完成，襄州尚未改造。** system02/03/04为各窄后继历史，不能拿旧绑定或假NPC域回退正式。

## 2026-10-29a 赤岩同Scene新增生活街坊

28dScene现B92D7F02，专用29a controller继承D只加生活人物肖像查看/状态；原Player/B/D控制/两室内不写。新增28根：2房22物4原atlas巡行，2旧北房重排；地面shader独有29a，新增原生paving RGB/512周期，不动旧PNG。原35001020→37001150斜路跨E侧阶墙，现经37001020上口正交；东支路43001010→43001100→49001100。三阶21节点主体全同，仅末块分隔LF后继。准确旧源基约束新桌凳，不撤墙；clone必须精确匹配parent尾引号或斜杠，Dwelling1前缀会误带Dwelling10并留6孤儿。首FAIL/警告保，最后4/0空stderr，0共享/save写。详docs/changes/redrock-city-life-20261029a.md。

## 2026-10-28f · 汴州八区室外结构收口，交用户细节验收

- 当前正式专用`system01/city_author.gd`为`35FBBDE296923BFCCA949457D716E2D201E85E6D087D3ACA4495218B64E20A5D`，`bianzhou_field.gd`为`473B58B6CE2B190E5853EADA48A18D5A03FB96BCD1B94917752CB7F5B3308A8E`；Entry仍`71AE33CA`。Author引用独立04 Gate绑定`E562EEE3`及05 completion绑定`3868DB0E`，04旧completion`A09E1F72`保留历史，不覆盖旧system01 GateBinding。04/05/06候选及FINAL补丁、精授权与静态逆证分别留在各自build目录，不能拿草稿或旧PENDING头回退正式。
- 6144²连续八用途区现有28完整普通楼、44匿名/原功能NPC，双住宅院含真实成人厨房/井/晾晒，东驿两厢与完整三开间马车棚、西货院、百工作业、榜亭院及南北门相连。新横墙和东西纵墙使用完整原生横截面region等比接段，端帽保持；不旋转正面墙、不用A3工程灰代理或缩门充整楼。原两业务NPC/原Shop与guide/榜/两门目的地保持；layout30对29/28/v1按登记新增或移位实体域lane显式迁移，未知仍拒，无nearest搜索、存档写或guard松绑。
- 04 Root actual`120780`自然0/176检查0/406真INPUT、三native加一4k真实World2D总览，结构/业务组件过，但Root原图拒巨大灰坪、矩形土岛、假田和裁脚菜贩；原ART拒绝不得洗成全通过。05最窄视觉后继将内城底改连续SOIL512²、主街PAVING128²/次石路和前坪STONE256×170.6666667，world UV同相位；退14冗余土岛/十字草及假田，保4小根部草窝/墙角绿带和64px官道、32px草边、80px田边内向透明羽化。两南外真田仅使用已导入复合图的完整4点sourceUV等比1.5、不repeat、不带原图门路、0PNG编辑/新import。独立05 completion仅ground19→11，原assets与60实体objects精typed同，geometry/NAV/44脚与30迁移未动。
- 9个女性岗位统一换已有完整`npc_zhuwei_vegetable_vendor_idle_down_25d_4f_v2_runtime.png`（640×160/4帧、有鞋、A8最下151），专用Field精映已有`generic/portrait_generic_older_woman_v1.png`。这是经Root/Art实看的普通年长妇女展示pair，不新增命名身份。旧street_expansion女体每160帧原像素下缘即裁裙，不能补白冒恢复缺脚；原裁底PNG与银发portrait均未编辑。原9ID/role/对白/脚/20.16×25.92身体及17.28偏移保持。
- 05 Root唯一actual`85680`自然0/109检查0，一住宅native加一4k总览确认灰坪/土岛/假田/女裁脚解除；仍发现同z后画土横巷切断石环路。06仅Field道路draw一行统一PAVING z=-998、STONE=-999、SOIL=-1000，全文精逆回原`FB4D3D24`；不动Author/JSON/材质周期/sourceUV/羽化shader/人物/实体。Root正式apply后唯一局部actual`84380`自然0/18检查0、单图/0INPUT，Root亲看石环路连续，停止重复旧109/176功能与1122几何、4k总览或新的艺术刷图。
- 最终Root guard`C8F9257C` PASS：15source仅两授权差、3module/3全文备、15save SHA/bytes/UTC精ticks、69旧媒体及24现货叶保持；用户editor51856与独立赤岩67108保留。04首数学1122/8FAIL及其38/0残余、早期误oracle失败、7旧退出ERROR均原样保，不称clean。本人本批0引擎/0正式部署/0媒体或存档写，Root独占引擎、导入和正式合入。
- **已确认八区室外结构可交用户细节验收；不是完美密度/全部细部ART/新内景或全城冷性能终验。** 本批不扩新店任务/住宿/奖励，金陵襄州仍未改造；无新授权不再写代码、生包或运行引擎。下文旧“布局29待实机”“东西墙缺素材”“八区未结构收口”均为历史阶段，不回退现役30。

## 2026-10-28e 赤岩阶面必须与护墙分层

三阶原整Sprite按底脚排序盖住上阶主角，28d中央走通测试漏掉显示。现同Scene C8B0：踏面z=-2、同原纹理UV/scale的两护墙Polygon2D保前景，六body按源轮廓映射；0PNG/Player/Router改。113424自然0/41检查0/357真实W/S ticks：原中段可见0重现、新九点1、三阶上下及左右墙过；关键三图已看。五保护SHA/bytes/mtime同，只发布Scene，不复旧矩阵，不冒整个沙漠正式流程完成。详docs/changes/redrock-stair-surface-20261028e.md。

## 2026-10-28d 赤岩六区+关外同场景地图

新D控制器继承当前B本地控制器，保原Player/35×25脚体及缓存重父；增加单一HomeDoor→HomeRoom，原InnHall不共享门脸身份。ambient_actor只驱动原生region，36帧按每帧脚锚/统一比例播放，居民真实physics巡行，接近主角/查看面板时停；worker原图左右行朝向重复，左向runtime flip，不改PNG。首66/2FAIL定位NPC占路及WestStair压横巷，实际移动带2660/阶1250后24/0；退休离散岩旧negative不能继承。六新壁与路线带22px余量分离，五接缝/阶高400后10/0，最后ground折叠UV仅3图不复route。79新文件/51叶精发布，不改共享Player/Router/Field/project/旧B。205保护含162save同。新D数据在ART/atlases.json，不能只把stage res://atlases.json搬正式。详docs/redrock-desert-complete-20261028d.md；非正式World/剧情经济战斗/A1验收。

## 2026-10-28b · 汴州街坊增量布局29已合，新增运行验收待

- Root已把唯一`system02/city_author.gd`候选E73AFC79正式精合到`system01/city_author.gd`。普通楼21→23，另原两门楼/两岗棚保持；西后街增加两栋真相反斜向完整楼，脚`1850,2940`及`1850,4130`、主体宽540，不拿小门皮/工程墙补围合。西后街与西货街两处增加14组粮袋/布架/手车/小木箱，使用既有四PNG，0新媒体/导入。原22NPC/8路/两门/榜与服务身份保持；旧Field2C79F8ED、Entry、Router及9来源闭包未写。
- 四低物使用Art核过的sourcefoot/native_scale，并从原接地source bounds精确变换Rect2；手车包括左车把，不再用居中±95猜基。crate从旧AC现役原polygon逆回source bounds。新body同时用于真实Field碰撞与safe_foot；后街手车最终`2240,4310`退开南粮与横街，未改任何旧NPC脚。候选Field244C935A只为预览改preload，**不部署到正式**，正式原Field继续预载唯一正式Author，避免两份作者分流。
- 布局升VERSION29，支持原28：不碰新增16实体足体保护域的脚原UV保持；仅落新body与34×24足体相交时，按该行`migration_lane_foot`明确移到已登记原巷脚并最终safe校验，无nearest搜索/全局fallback。v1先继承旧明确街段投影，再同增量迁移；29不再迁，未知版本仍拒。Entry既有World外门脚使用Author.VERSION，故无需新Entry/Router修改或Save schema/文件写。
- Root末只读guard`4B089EF0` PASS：12源仅Author授权差、2全文备、15save SHA/bytes/UTC精ticks与60媒体同、0外变，0引擎；用户editor51856及赤岩draft96824均保留。**本批仅正式数据已合，尚待唯一窄parse/新增域probe/两街段真INPUT与1原生街景；不能称新增布局已通过实机或全城艺术完成。** 用户游戏未退，Root已异步请仅退游戏，不私停进程；旧北返/World39/商店对白等已过组件不复测。金陵襄州、完整城廓和整城ART仍不在本批完成口径。

## 2026-10-28c 赤岩受控角色使用正式主角

28b原默认全景/匿名Inspector引发用户误解，现同Scene实例化原Player为Town/Player，专用preview_player继承原Player，关闭自主physics并提供动画接口。controller保原移动/重父，ready应用ground_anchored并关闭原interact；原35×25body、0.945视觉保，复用v7剑八条方向动画，默认view_mode1。共享Player/媒体不改。唯一23756 GPU窄验证自然0/空stderr，四向帧推进/脚体/Tab/同人返厅过，截图已看；非真实键盘输入、旧79矩阵或世界业务。详docs/changes/redrock-player-camera-20261028c.md。

## 2026-10-28b 赤岩独立前厅：保持对象，不靠静态重建返场

专用`redrock_luoyang_standard_20261028b/town_controller.gd`只持Node强引用，前厅原生PackedScene常驻缓存；进入时同CharacterBody重父到Hall/Sort，出门重父回Town并还原真实return_foot。室外静态节点只隐藏，物理域与前厅相隔，未`_setup_scene`/重建。79实际证同角色、地面/院体/前厅IID保持，3真Space+Esc；实际不调用公共Router/Quest/Save/金钱服务。此为本地编辑草案，正式世界接线待统一，不作为绕过旧权威校验的先例。119新文件/28原图RGBA导入，旧28a和汴州无写。详docs/redrock-luoyang-standard-20261028b.md。

## 2026-10-28 · 汴州八区连续首轮已接入（仅本轮功能/材质收口）

- 用户转向其他大城市后，依已确认`bianzhou-city-masterplan-20261022b`实施汴州，不复活被否定的32模块试拼，也不在三城旧baked整图上叠楼。新独立实现位于`game/build/bianzhou_city_20261028_system01/`：`city_author.gd`＋`bianzhou_field.gd`＋继承原Field场景＋`router_entry.gd`。6144×6144连续物理城，八用途区/主轴/两横街/东西环；21完整楼体、真相反斜向楼、22NPC、59可见物件/56实体由Root实际读取，不把三开间街楼当豪宅或多独立业务入口。原Scene canonical、2旧NPC ID/驿丞对白/行商Shop、唯一缉捕榜和南北目标保持。
- 新Field继承原业务，普通深度带扩大到1024、入口层2048，不盖HUD；角色遮挡只取缓存源图真实alpha的5个身体采样，建筑本身不淡。匿名生活岗位使用8种已入库职业体，新增人物外观112px归一；同人portrait明确配对、未匹配伙计不强挂generic帅脸。Root提供8职业日常文案：Hero先开口、NPC续句/轮换家常，无选项强塞、任务或奖励副作用。此城静态无flag依赖，更新任务/HUD不重建地面或实体。
- 南门采用Root本批准的3派生PNG（原图留存/仅局部清边留白）：真门楼uniform`.98245614`、连体U形瓮城`1.09375`、两岗棚`.35`；padded sourcefoot按原整数补白偏移，不fit新画布。主楼两翼抵实际280px洞边，L侧脚保真polygon；北门复用同职能完整门楼，南北12段A3正面城墙有限等比连主体。**A3仍偏工程灰块，东西全长纵深墙无合格现货，本轮不授完整城廓最终美术**，不得旋转正面墙或用灰tile补齐。
- 坐标使用既有`navigation.local_layout_versions`：旧缺省1→新28按明确街段affine迁移，未知版本拒绝，不nearest-safe猜点、不改Save schema或写玩家存档。新鲜到达精确`[3072,5910]`在瓮城外，南出口`[3072,6020]`保110px净距；旧v1南段`.75→.9`映射`4456→5910`、`.9→1`映射`5910→6020`。北门原anchor是`[3102.72,245.76]`，原BaseField普通出口有意记authored anchor而非最后INPUT脚；不可为1.302px的QA误期待改掉原返程语义。
- Root唯一正式路由改动位于`_go_field_smart_prepared`首部的exact汴州分支，统一public、prepared portal、商店返程和读档，不在public另造漏private的旁路。实际旧Gate/Docks仍执行B.describe完整source map；正式采用唯一`source_closure04_READY`的9目标，Router`6C154897`保原13CRLF/单末LF，EX`CB5E5E33`保旧10Router边＋1真实全逆边，新不可变snapshot位于`res://build/luoyang_bianzhou_router_20261028_source01/Router_READY.gd`。Gate/Docks各Router+EX两key与snapshot源key同步；Quarters仅EX+EXindex两key＋同snapshot，四索引精确后继。独审9全文逆/EX11边逐全文逆过，未扩死旧Civic B/新Region9bin，未松guard。01格式稿、02/03不完整准备全部留存不采用。
- Root actual首`117388/46236`自然1、103检查仅1旧北返误期待FAIL；默认入场2.789s（不是全城冷性能指标）、22NPC/59物件/56实体、Hero正确头像→军士无菜单家常、对白后静态不重建、原Guide、原Shop原脚返、北旧驿到达组件已过，停止复测这些。唯一残余`33948/13056`自然0、48检查0/21.443s：北往返精等原source anchor、741真INPUT ticks完整北→南、南出口真Space→`world_map_jianghu`约1.946s；保首FAIL而不洗整段PASS，没有生产返脚改动。
- 两原图曾被Root判巨泥底/灰噪声条ART FAIL。唯一纹理/period后继现Author`395E5DD6`、Field`2C79F8ED`（Entry`4952E153`保持）：base为已存courtyard_floor `768×512`；主轴/服务巷为已导入cobblestone_floor_08 `384²`；横街/前庭原石板`512×341.3333333`保源3:2比例。灰岩worn_bluestone不是带砖缝道路，停用；brown_mud不再铺全城，不拿森林/赤岩地冒中原庭土。几何/NPC/门/业务/9来源闭包不变。残余唯一原图`E2FE1B8D`Root亲看，巨泥/噪声直条已消，仅局部材质准。
- 交付前Root追加静审发现World旧authored UV与本城version28可混用：World→BZ prepared对非Family/非Luoyang保`local_version=-1`，Entry原supplied分支会套`versions[BZ]=28`，再次从World来且无记忆UV时会误落瓮城。仅Entry增加准确`router.is_world_map_scene(current)`分支，固定外门脚`[3072,5910]`及Author.VERSION；新Entry`71AE33CA`。OldPost/Shop与非World读档迁移代码不动，Router/9来源闭包不变。此新增World分支只做静读链确认，未冒实机通过，也未复已过组件。
- **停止本批引擎、代码、导入和功能复测，交用户试玩。** 街坊密度、院落细部、A3墙体、完整东西城廓仍不是终版ART；客舍/驿馆当前外观用途，不新增未授权内景/住宿定价/剧情。金陵、襄州本轮仍保持原baked城图，不能称其已改造。本角色0引擎/0正式整合/0存档写，Root独占引擎与9正式合入，保用户editor51856。

## 2026-10-28 · 27d 新Region与视觉残余已正式收口（当前C1C49F44）

- 当前正式为Root部署`C1C49F44`，唯一视觉Stage`1CB6`、4085来源首末同，27必要目标（12GD＋15JSON）、849全文备份；`final_guard7CECCD0B`全部零差，15save的SHA/bytes/精确ticks保持，当前仅用户editor51856。下文“仅BUILD/未采用”均为历史检查点，不可据其回退当前版本。
- 新权威为`game/build/luoyang_regions_20261027d_source01/`的RegionField/manifest/session：府衙与南市同一连续物理Field，逻辑旧ID独立用于任务/商店/存档别名；宅园、古寺及六独立Room沿明确导航ID与原业务source逻辑ID分离。真实Region FIRST/FINAL冻结compiled/layout及完整实际消费源，不伪造旧C/Family owner；碰撞/NPC常驻，仅视觉分块。旧BaseField业务采用完整不可变快照，新Region不调用其旧owner setup。
- 来源键修复：原compiled/terminal `.sources`不可指向会被后继更新的canonical Estate/Quarter manifest，否则即使业务值没变也会严格拒入。当前仅将这两个key绑定到原全文SHA不变的不可变0857/58CD快照，九bin/两terminal除`.sources`外全typed及原字节段逆保；没有放宽hash门、用observed值补期待或重编几何。旧86968整FAIL保，Gate已通过前缀不复。
- Phase生命周期修复：Entry局部`RefCounted Phase.new()`只交Callable不能保证对象存活，曾在actual102304产生`null::project`。RegionField现在强持`_region_phase_owner`，adopt时精核Callable真实object、固定phase脚本与`project`方法；业务投影不变。不能把Callable当强引用或再次移除此字段。
- 功能信用继承Root唯一`121140`：自然0、87检查0、86真INPUT、两原图；Civic769/Temple679自然LIVE，跨府南逻辑界同Field/Player/Camera/LoadingManager，守钟Hero开口→原KEY2“暂且不接”→静态地面/碰撞及人物实例保持、输入解锁通过。和尚使用原业务，不冒已接受任务或文化菜单；旧失败全部保留。
- 视觉纯增量Root`67124`：只从三个冻结outdoor bin退Estate32＋Temple22灰tile代理及Temple2孤矮墙的56组render/专属body，精保其余polygon顺序并重索引solid_cells，原positive ground/NPC/调查点全typed同、整逆通过；不造新mask/import、不重九组件或旧路线矩阵。已有土纹全域underlay为纯视觉z=-1100，不扩大floor_rects/可走域；不能只隐藏代理留下无形墙，也不能用窄屋脊条旋转拉长冒完整侧墙。
- 真正出口`ch4_s1_luoyang_yamen/to_city_gate`原主轴(3072,2160)移至既有西横街(720,2090)，返脚(1000,2110)；原Gate target/door身份/legacy source绑定与Zone尺寸保留，不删真正城门或另设码头世界出口。中文HUD通过logical entry更新PrimaryHUD/scene_title，不改Owner锁定的Scene.storage。视觉Field候选53736563与manifest749E8D4E已随本次正式采用。
- 最终仅视觉`100264`自然0、49检查0、两PNG、0INPUT；Root/ART有限确认灰空/灰代理及孤墙已消、右上中文地名正确。功能沿121140继承，不以两图重授旅行/任务/全城ART。**停止本批实现、解析、编译、导入、Stage和功能复测，交用户试玩。** 硬矩形地块/密度与宅园六Room实玩仍交用户评审；Spring House只是可到达外观地标、没有新增内景，World/旧预热32批继续暂停，不称七项或整城全部完成。经验已由Root另写`docs/experience-log.md`，本条仅角色记忆更新。

## 2026-10-28 · 27d 七项整改进行中（仅 BUILD，未采用）

- 三RAW已由Root按本批明确许可08处理（2DF1FE28），System仅备隔离工具；Root NEW02唯一prepare/import/wholeRGBA verify/9叶晋升已完成`15920208FCBD2C7B09FA6808623A2F146A6A531623A35404730E130B85AFBBE8`。正式媒体目录`art/maps/luoyang_city_rebuild_20261027d/`的east/west/spring三`*_padded.png`及6导入叶，停止复导。prepare首候选PNG prefix误双转义在Root执行前静发现，NEW02只改为真实8字节，原稿保/0失败isolate，不冒像素或Field信用。
- 新Region纯展示业务接线已BUILD冻结，待Root唯一必要集中load：`presentation_definition.gd`7435E9CB/contractED4FF178，完整继承D51F7视觉/12日常与7475的8人/4family及原无effects菜单，73普通固定叶；原FieldF4BE/NPCNode旧值仅历史提取证据，不调EX/旧source_paths。NEW Projector05`944DFAFF`/Bridge04`0D979C22`改纯compose/topics/menu入口，同份ready贯穿一次projection/open，原Region真实owner/guard/reducer/play均保。Temple三纯提取`temple_source_business_snapshot01.gd`277DA185、`temple_paper_task_business_snapshot01.gd`760B3C06、`temple_task_business_snapshot01.gd`D13F2BB9，保原child身份/纸任务phase/全部typed脚/原receipt及双僧规则，不含旧prepare或source_paths；63真正资源叶从固定BIND/Task普通声明推导，不借旧196控制表。整逆AB0FDCEB含两业务完整父子字节，73+63物理逐同与函数重名/局部参数冲突/EOF1LF静核过；0System引擎/正式写，不授实际业务通过。已交Source一次final接线，旧04/Bridge03不覆。

- 新Region文化业务已拆出独立定义（Root待审）：`culture_definition.gd`D6F0AF1C /固定业务data3F538A6B，从Stage956F不可变CT候选EA35抽取全业务字段；原26中Field/Router/C/Loading/NPCNode5只历史证据，新权威47固定叶=21真正业务+W24+CT/33D快照，静态逐SHA同，原零奖励/无auto complete门保。NEW bridge `logical_context_bridge_culture03.gd`232ED6C5仅3 readiness→Definition及依赖/指针；NEW Projector04 `logical_terminal_projector04_culture_definition.gd`6A1BDD91仅CULTURE preload一literal（phase原来也会调用canonical CT readiness）。原9EA4/Source6770/33D快照/W都不改，旧_owned未宽松，新Region真实会话仍独立。全业务值提取+两代码全文逆proof752BD25B。新API dependency_paths/source_declarations供Source精冻结，不current填SHA，0engine/canonical/业务实例。
- 两Family纯门户NEW `pure_family_portal_projection.gd`85628278 /depsF91D9A9B已交Source adapter04。Temple真child原2 legacy6/7@240850/1296850→finish整typed170926/1380926，除pos原字段不动；Estate真实native2（return_market/enter_mansion_hall）＋AP唯一estate_to_garden＝3，另精核garden_to_estate反向脚合同，不误添第二outbound。固定AP58CD/Garden7ECB/targetscene4B52，无旧owner prepare/matches/safe/几何人物改动。Source单次两源冷编译待Root，不复已过府南。
- NEW Region子层由System独写 `region_render_auxiliary.gd`9F9564F5 /三profile `region_auxiliary_fixed_door_specs_BUILD.json`223DE359；Source只换现RegionChildren preload+install(self,_region_owner,row,sprite)。真实REGION_27D signedIID/Weak FieldSceneLayout/FIRST或LIVE、冻结compiled/Field同key整row/parent实际映射/Atlasregion与尺寸/源pins守，不借C/Family。子层仅parent内ONE scale/局部offset/relative-1/tint/material继承，随chunk父卸载；Estate wing[-208,168]、Temple非centered wing[893,812.5]、mainhall[-1.5,118.5]固定模板。原Estate `estate_al_door_main_hall`独立row已存在，hall模板禁止重复叠加。未单独engine/GPU，留最终Field实际。Root已报Gate唯一mask两叶晋升C2AC，停止该导入/几何。
- Market冷编译124012/118920原FAIL保：D98 crowd→T guest迁移→Space全crowd→DG/PRESENT→DE191；Task新纸匠1320,1290还须原Field1137的Space task migration到880,1340，随后DE191纸匠到888。NEW02 projector904E、NEW03 `logical_terminal_projector03_market_task_space.gd`819ECAB3（整逆FF94B337）严格补原层，不松oldfoot；56564所有坐标越过后仅缺原media来源。一次离线全19potential actors/21媒体静核 `market_final_actor_media_READONLY.json`D2A8312E：仅examiner sprite、linxi martial master sprite、封砚秋portrait三组9叶缺Stage956F；独立历史424库存29E9F1B1已有全部9值，当前逐同，已交Source继承普通来源，非current hash回填/新换图。Catalog无Market匹配，原Field后端仅书生和examiner portrait已投影，0引擎。
- Gate供应房已不止spec：Root唯一82020/19148自然0、106检查0、空stderr；N27d/GATE_REAR_ROOT_READY01/output/82020/result.json15E84A37，payload07266C6D/180644B、mask9A02EF87/30959B/RGBA8B716B20、34432所属新黑像素/62solid，原NPC/portal全同/整typed与RGBA逆。helperC84ABDF2及Field hook30991330交Source（Field由Source独写）；单mask隔离prepare2EDC317E/inputF2A337ED/template7E0D38AE/promoteE9C59905/整逆1C9EF5E4在N27d/gate_mask_import01_ROOT_ONLY，均未由System执行。Root唯一后续prepare/import/verify/2NEW importer叶晋升；不复本几何。
- 新Region业务桥候选已冻结：N27d `logical_context_bridge.gd` 9EA4FD4E / `logical_terminal_projector.gd` CE4BB7F2，Root唯一19508集中syntax-only 37/0通过，仅解析不授Field/业务实例。新Region真实session持Weak身份，原Culture仅纯graph/W reducer；旧_owned不改。完整Task/Catalog/Harbour/DG/Market末端与finish迁移、两BUYER互斥槽、Temple未来两调查Area已声明；Source独占RegionField的play/observe/finish/busy/动态刷新接线。新增纯门户`pure_portal_projection.gd` A7F7A767仅Yamen/Market，固定G authors/Space/Estate/AP/DE191→finish typed投影，无旧owner prepare，尚未解析。8份BountyDef无府南/Temple/Estate潜在位置，Gate两潜在槽仍属未接旧域，不能冒当前active列表覆盖所有未来位置。
- 当前正式01656F8C/FieldB674/Router2687，园林退孤墙及Garden→Estate双Family冷生命周期已由Root唯一100436/128检查/1真Space验收；不复此项。用户game10836与editor51856不得自停，本角色0引擎/0canonical。
- 和尚闪地静因：`baima_offer/longmen_offer`真实accept_quest+set_flags→Field pending→dialog_ended deferred→`_refresh_scene_preserving_player`；Temple不属C resident，旧分支必`_setup_scene`清world_container并重prepare/地面/ENV/静态体。不是对白脚本显式改地形。
- NEW27d独立helper `game/build/luoyang_city_rectification_20261027d_system01/temple_dynamic_refresh_NOTREADY.gd`（0F09F40A）保原T完整source/storage FINAL/finish Weakowner/Task投影；两和尚原实例、身体、贴图、尺度、脚和门户不换，只换原phase对白及动态调查Area。Field调用hunk717EBD75仅建议；本轮Field/Router全文由Source独写，Region物理Scene不得冒原Temple owner。READY false，尚未解析/实际/正式。
- 用户图1透门房已核并非码头：`wing.png`+“货担主人”对应Gate `finish_i_gate_east_supply`@2380,1300/.41；Docks有效rows无wing。仅左右前基y1254.9..1300，PNG门洞透明，无后房体积。图2为`estate_ak_main_hall`@1536,520、原仅两前基y481.689..520。后体/门暗面提案D5643D06是新设计，不冒旧测量；不取整屋顶alpha bbox当solid。Source Region编译器统一消费，原PNG不编辑。
- 新候选统一EOF单LF，未提前封32/运行引擎。旧prewarm/elder/World保持暂停，不混本轮。

2026-10-24a正堂柱后修复正式G1078/helperA5B0：原floor图为RGB8，clip先接受RGB8/RGBA8再只内存convert，不改PNG；两个同源柱overlay必须挂既有ActorLayer，sharedparent/identity/opacity严格检查，沿用完整native depth/人物alpha ghost，不能拿invalid snapshot的0hit当通过。固定单屏房间本来无Camera2D，QA按实际中心WorldContainer源式验证，不强造camera。旧91184/124716FAIL保，最终新suffix98132 51/0、3092ghost→0/真INPUT正逆/柱alpha1/自然0但旧退出7ERR；初27+两个子集22来源后继，native/registry/4家具/身体不改。入口新专用shader仅base=COLOR，三态两尺度70/0/锁门不放开。final2639全2120/save15/运行0同，editor留；停止两项复验，详20261024a专题。

2026-10-23f赤岩3授权padding后已新增`scenes/drafts/redrock_joint_editor_20261023f/redrock_joint.tscn`入主工程。原生3Sprite extTexture/7CollisionPolygon/body35×25/控制相机，无@tool绝对PNG动态读、无autoload；6旧worldfoot和原canvasorigin补偿实际过，默认actor26501550。5图相同res隔离lossless/fixAlpha=false/mip0/detect0，actual67/0自然0/1558motion，W/Tab/123/R/F2过；Ground z=-10避免门后actor被调试地面压。23新文件精SHA（含15import/ctex/md5叶）＋1清单，不复导生产/UID/公共入口/旧c；234保护初同/editor留。已明确许可3仅padding执行16核，旧RGBA全保/A1≥10，不能再问同一范围。世界入口、完整5锚/艺术/真实峡壁层台仍待。详同名专题。

2026-10-23e赤岩3原生模块已在`assets/staging/redrock_joint_trial_20261023e/trial_project/trial.tscn`真实试拼。只读外部raw经ImageTexture，PNG不import/不改game；@tool可独立工程查看。核心1.2/左.771119/右1.181910无旋/非等比，2前锚与12/16px接合，右翼draw最后盖共有端截面，首两种图保；A1不合格仍不正式。Native34/0自然0/1558motion，112idle/35×25body、门进返5lane4负控W过。首PackedVector2Array const非常量PARSE停驻只中断自有，后继var实际自然0，用户editor留。默认结构台隐藏临时镜像土纹走域，不冒峡壁层台/正式NAV。新3padding方案需独立许可待答，不能套旧12；正式game接入未做。详同名专题。

2026-10-23赤岩峡口首段新增`scenes/drafts/redrock_gate_20261023c/redrock_gate.tscn`及同名独立脚本/Art命名空间，不触Field/Router/project。原生9Sprite、脚点sort、13碰撞polygon＋35×25角色、成人112、门梁淡出与Tab跟随；9PNG源字节同，27新导入叶从相同res路径隔离工程精确晋升，禁止整工程import。Godot4.6.2实际77/0自然0、2461原生motion、9RGBA精确/mip0；首默认fix_alpha_border导致7RGB FAIL保，关本批该参数/detect3D后过。编辑器earlyquit扫描警告保，明确Scene隔离import后继自然0。只编辑草案，非正式World/Field；源地表非峡壁，稳定walk和层台街坊未做，两个可见人形复用idle。source-preserving padding绘制origin需减pad×scale，Gate本次pixel scale .86；不可fit padded全宽缩主体。详redrock-editor-gate-20261023c专题。

2026-10-22汴州隔离试点：全部工程在assets/staging/bianzhou_city_20261022a/revision2，未改game/Field/Router/project及生产cache；独立原生图自然0退出，不停editor51856。32模块33足迹＋4边界、mask与整35×25像素净空同源，8route2572点和522原生motion/37中心负控通过；预览注入键通过但仅Sprite移动＋mask约束，不冒正式CharacterBody输入。279地面Sprite/32模块/61Atlas待集成布局由真实WalkableMapLayout副本载入，32对象坐标尺度与33矩形polygon逐值读回过；Scene仅新layout路径＋两NPCpos三处全文逆，其它字段/两出口整行原样。first readback passed类型推断PARSE失败留，显式bool后继自然0。独立查看人物统一112px与正式Scene原scale .96/.90分开，未授Field尺度/遮挡/路由信用。原生整体画面仍NOT_ART_READY，详同名专题和README；生产不能整体copy integration_candidate/game里的核验配置/domain副本。

2026-10-22ap继续：Root Artisan4实际53624自然0／5148ms／114源首末同，106visual／33solid／4portal、五楼成人门f32[124.129,124.129,123.557,171.210,125.074]全≥120；woodwork780／notice1190,1490有限后继，17859mask全逆，2429旧route域外继承／0受影响重采，报告09301B55。新三native在唯一quarters/revision4/，Family候选CC97只ROOT字面量；53624与所有旧实际冻结。122264_3201原生图402／0、79源15save同，Root有限认可尺度／间距／4人可见，ART38B755有限候选准，非正式Field。三PNG112496唯一隔离153／0／239ms且9叶精晋，原A0隐藏RGB非灰雾，不二次处理。Root已明确景桥安全fallback：700等比只景观／无水上support，≥192连续岸路与亭庭连接；Garden31pin离线0差／2299新route875＋17离线0错只规划核，NEW garden_revision4唯一publisherD757待Root actual，不冒几何／Field或全城完成。水polygon与Physics／mask同域，真实DocksDC4B材质资源＋NEW nativehelper5644同构绘制；未跑引擎／未改canonical。Sign仅Market真pawn子Sprite装饰ENV候选9038／作者5A999，无body／mask／nativecount变化，旧19共享来源保；十owned sourceproofRoot B6A2／9BF787已成，不再改该闭集。handoff6 81B269／72FAB5固定114源与最终ROOT，Garden实际／两mask导入／统一来源和八场／有限门返仍待。

2026-10-22ap恢复：用户已确认三新图本地处理，Root按冻结脚本实际生成，未擅扩大范围；sign／bridge一度被隐藏RGB显示误判灰雾，Root／ART正用真实alpha复核，不重处理／不直接绑定。百工revision3仅NEW作者4571／publisher83BC／compiler18AD，五块连院court铺装、中式木作楼6201290、树移1180600、撤炉砧保完整手车／固定NPC，禁A16木梯。Root121476自然0／4380ms／112源同／106visual33solid4portal／36654mask整逆；2429旧路线在实际变化域外继承、0受影响875重采，4NPC南48与门户body直接查过，报告BA421F7D。新三native在quarters/revision3/，旧60720／97020／17536及所有失败原字节保留；walk仍build候选未import。尚待106native整图艺术、Garden真实source-ground／几何与全批正式来源／8Field，不授整城合入。handoff5固定实际112源／3artifact／FamilyDDE664与ENV763009，Root执行所有引擎；System未改canonical／存档或跑引擎。

2026-10-22ap收束至必要许可，未整城部署：Root实际Market17536自然0／4524ms，24native／DG36、437新改4px full875＋17／1085NPC、5058继承与110300mask像素整逆，五return-only及其他7row逆过，报告0058E2DA；B最终候选8D3仅指向实际retry6helper。百工60720自然0／5695ms、82visual／32solid／4portal、1786新改875＋17／643旧主路继承／4NPC南48／113546mask逆／101源同，报告08D19866；原55268错误65hex与49284穿cloth基座失败保留。97020 native图技术402／0但Root＋ART明确NOTREADY（棕草主导、硬条石路／巨土块、西式绿顶锻楼），不能部署或冒Field完成。NEW artisan_revision3仅PENDING：五块连院石铺、换中式木作楼6201290、撤炉砧保固定木作NPC及完整手车、树11901110→1180600；ART8B5E按A16裁木梯被Root拒，不纳作者／不绕背景许可。唯一未来ROOT为quarters/revision3/，不覆盖60720／48408。新publisher仍PENDINGpin／无author.json，未引擎／native／图／导入；Family DDE664仅ROOT字面量后继，原canonical78c inactive与B06保。最终ENV763009仅Market39C898前院＋Artisan轻车辙19源同／代码E1F不改，亦非艺术授信。Root要求在新sign／bridge／pavilion本地处理许可未答处停止，不擅清理／导入／部署；现役仍AO／AN，完整十区尚未完成。CHECKPOINT_PENDING_ART_PERMISSION.json和handoff4为当前索引，新增v3 geometry／正式闭包／8Field与有限门返／最终保护仍待；System本轮未跑引擎、未改canonical／存档／进程。

2026-10-21am进行中转PENDING许可交接、未正式：NEW am_system01已写AL83／AK20父的围合实体增量helper／publisher草稿、4旧代码候选、单mansion return-only出版与runtime native路径／媒体别名typed逆工具；计划6短墙＋4实体草石肩、条件2花床。Root准唯一forecourt_to_garden横路改南下1420→东2540，原398点不继承，旧其余路仅受影响段复875＋17；尚无AUTHOR_READY、geometry／新native／图／import／真实Field或旅行。v3花床形体合适但A1杂点FAIL，必要本地背景处理许可未答，按Root指令停止写／执行，不擅处理或拿无床10体冒花坛完成。Root唯一9direct proper中8自然0，Router单脚本GameState域失败保留；残余16184在autoload后只load／can_instantiateD996，126ms内部／自然OS0，1ObjectDB非clean，不实例或旅行。当前helperAB237为随后支持6墙4肩／受控接缝与可选床的后继，非旧proper信用；formal native工具6E108亦未编译实际。Root仅加2NEW family530B／indexC305（false／PENDING），4旧G7EEE／RI6470／B92DA／Router15665全保持，正式现役仍AE；候选G7364先精确重演旧G追加mansion唯一门再移除1，避免把native0错作宽容0／1。family按transition serial＋INDEX／manifest key只source-first／final两完整SHA遍、共享packet／mask缓存，不重复5次大文件校验；仍需实际验收。已发现正式必要传递闭包：x契约DA49直接pin Router15665、coordinatorFC933固定契约SHA，Temple ad2F38／v14 parent亦ownedRouter／coordinator／contract；将来必须NEW精确后继，不删校验、不复文化全链。Root66A984EA阶段2094仅tasks授权1差、其余2093含15save exactticks同，2NEW另列；CHECKPOINT_PENDING_PERMISSION.json为最短实际／缺项索引，早期94497逆及B158patch不是最终可部署证明，须最终实际LF／CRLF字节逆后再统一来源与关键门返。编辑器／API保留，本角色无引擎／用户进程／存档操作。

2026-10-21al视觉衔接候选收束、仍未正式：只NEW al_system01派生AK，撤46旧粗石行、保原16草／树／门／5建筑全值，补庭心与两厢支路／南主路及3真实室内材质门深度；20rect／完整mask／portal1536544／route／2710＋661全继承，不跑geometry／旧2226。首actual console113320自然0／render111448，2273ms／23Sprite／typed全逆读回过（4F66E4CB／图4C84F1ED），但Root艺术拒native1:1青石巨板，原源／作者／3native／图全保留。唯一NEW revision2仅4section uniform_scale=.25、cols／rows=4，12标量全文逆，四footprint原值同；六Atlas／3door／原16行及所有物理不变，author1D6167／script6ADA8A冻结。Root唯一rev2 console120940自然0／render16096，2676ms／83真Sprite／73源首末同，C4A66219报告／图9224A3EA；typed父native／packet全逆与readback、20rectmaskrouteportal不变／geometryfalse。三门按AK真门rect扩3sourcepx、同建筑等比和facade前一层，贴现成shell墙脚地板并固定暖暗化，不改PNG、不用黑Rect；Root／ART有限认可砖尺度与门洞透草已修，但收边／短墙／花坛／回廊围合缺，整体NOTREADY，不授整院、正式Texture导入、Field人物遮挡Physics、门返／Router／来源接线、NPC语音或加载改善。Root finalguard6221BEF6自然0：2094全SHA／bytes／exactticks同含15save与tasks，own引擎自然退／editor与API保留；日志不冒clean。AL CHECKPOINT_NOTREADY.json为最短实际索引；冻结全部源／产物，停止本批预览；下次视觉可继承，新增墙／花坛如实体须独立有限几何delta，不能无body摆障碍或重整套旧路。

2026-10-21ak实际建筑候选完成、艺术仍NOTREADY未正式：用户准3新组件本地背景处理，Root派生3PNG／meta／ART D607／processFBA3原样copy进NEW ak_system01；新5建筑只ImageTexture候选预览，不授正式import。原QA43／2 annotation预期遗漏FAIL留存，41pixel／保护组件继承，残余20／0自然0的98D86A只补两标量、不重decode不洗整体。AUTHOR_READY C210／helperF618／publisher475D冻结；首check-only E081因A.resource_path静态类访问PARSE自然1保全文，唯一字面HELPER_PATH窄修后proper自然0。Root唯一geometry110824自然OS0／1319ms／44源／62visual／20rect（新14），收据248273FC；原3路线661样本全继承，旧dry环显式替换，新4路线152＋297＋260＋2001＝2710逐875＋17过，不重旧2226／旧mask全栅格。NW／NE树同ID脚、24×18rect、局部旧黑恢复新黑同步迁3901510／27401780，SW／SE与其余旧4体保持；mainhall真门脚1536,544候选取代原院门假门1144，室内ID保持但实际返脚／Router未接。Root唯一preview console8984自然0／render115536，1847ms／62真Sprite／native统一.5，报告622BE942／图3BD94C08；Root＋ART看到主厅／两厢／两短廊无叠，仍缺铺装、短墙和门内深度，整体NOTREADY，不部署。5Image WARN／旧7Texture退出ERROR非clean，无真实Field／人物／任务／门返／加载信用。Root finalguard41CA8E9A：2094全SHA／bytes／exactticks同含15save与tasks，44实际源当前零差，own两引擎自然退／editor和API保留。AK CHECKPOINT_NOTREADY.json为最短实际索引；全部actual源／产物冻结，下一地面视觉层继承本几何、不复2710或旧2226，新增实体才单独有限delta，正式来源和连接仍待。

2026-10-21aj候选收束、无新architecture实际：NEW aj_system01已写architecture纯候选／有界增量geometry出版器／独立预览PENDING和树后继静态范围，源码0A9C3D6A／944842DF／812D88F5；author空assets/components、无AUTHOR_READY、pin仍PENDING，未语法引擎／geometry／新native／import／preview／Router或canonical部署。预备5组件、未来62Sprite仅脚本目标，不是实际看到建筑的信用。Root准只移NW／NE两树至外园，明确visual＋24×18rect＋旧黑局部恢复／新黑＋受影响路线同步；当前仅静态范围9C4E，adapter尚未实现，SW／SE保留。已按QA补完整A1／source-size整数域、门锚画布内、两厢440–520／短廊500–560完整A1宽下界、4新路线真实门前端点及原5prop精确A1重算，不重AI2226。三新raw未ART准入（halo／A1触边、主厅760宽门高不足），Root唯一厅v2 edit已产，最后像素量测与背景授权仍待；不扩生图，不拿旧halo整楼或商楼冒宅院。CHECKPOINT_NOTREADY.json为本turn最短索引；91C9／40E3及原产物全冻，原AI可视原型艺术仍NOTREADY，Market25／37、三返脚／正式来源与连接全部待后继。本人无引擎／用户进程／存档操作，等待Root最终事实。

2026-10-21ai候选检查点、未部署：十功能区映射已落NEW ai_system01，不再把百工／民坊／宅园强塞现南市；旧AF及早期AI三门脸草稿仅历史，当前拟Market24→25／District36→37两商铺，豪宅原roomID移新Estate外场的门／三房返回／Router／来源接线均PENDING。Root唯一Estate几何114084自然OS0／728ms／2226 full875+17／4路线／6矩形／5完整alpha过，收据91C95216，原源与三native冻结，5ImageWARN＋1ObjectDB非clean。原13Sprite预览121092技术过但Root＋ART艺术FAIL（空场／1024石带／镜像树），原证保留。NEW revision3仅地面视觉后继，Root console119296自然0、实际child116964／1714ms／57Sprite／收据40E3387D、图B938F838：384px原生square纹理路径与704×256前庭，Scene／layout／packet全文逆，原草／门树／mask／6solid／2226几何继承同、不重raster或import；Root实看仍空旷、硬边T铺砖、四镜像树和无主体建筑，仍NOTREADY艺术，不继续本轮预览。小手册CHECKPOINT_NOTREADY.json列下一主厅／两厢／廊墙／花坛与真正接线检查；不授完整宅园、全城／人物剧情、真实Field门返、来源准入或加载提速信用。本人未跑引擎／改canonical或保存，等待Root最终保护事实。

2026-10-21ag只读收束：首药铺窗口6E2D与缺口9EAD保留，复核原灯完整A>0并补实际DG药摊／2080,1580伙计／2420,1770前巷灯及两树；A280×205仍不能容纳120px净门，不扩大边界，B220×284仅名义尺寸fit且与原eastrow相交，不能additive叠挂或补透明画布后冒NAV／solid／门返脚通过。Root唯一0-reference生图B329窄单间形体可用、raw透明边距FAIL，待用户选择背景处理方式；未追加生成／代码实现／引擎／导入／canonical部署，不复AF八语法。Root最终守卫AAA42C63：current2094仅tasks一授权差，其余2093含15save exactticks同；原AE正式与AF PENDING保持。

2026-10-20af候选收束、未部署：南市eastrow一楼三门拆药铺／书斋／宅门的NEW候选保留于`game/build/luoyang_market_frontage_20261020af_system01/`，纯transform／单Market出版器／三房return-only克隆及B、G、RoomIndex、AEground四副本均PENDING，原native24→26／DG36→38尚未执行。四代码全文逆静态核14／7／3／1 hunk全同；Root唯一check-only八入口全部自然OS0／stderr空／候选SHA首末同，收据439062AE，只授语法、不授runtime或source准入，不复跑。三图v2最终ART判定全部FAIL（B3B8FDE4：门高／比例、A>0触边、宅门halo与书斋桌挡），按Root指令停止生成／出版／部署，不降低透明边距或门高门禁；READY和formal均false、没有author_READY／最终source stager／新原生产物。原AE正式、District C4FB与AC 34B8→d744严格后继、C／Field／Router／GS／fade／Temple／所有存档不动。下一必须先获合格门脸与实测alpha／solid／门锚，再冻结作者、三图导入、单Market及三返脚出版、独立新walk隔离导入与有限source后继；当前仅可见方案候选，不声称玩家已见南市建筑改好。

2026-10-20ae正式收束：4张新贴图为码头系缆／车辙／纯贴地湿膜及南市首簇地面磨损；湿膜仅固定`shore_ae_wet_` RGB(.38,.48,.52)，系缆固定effective z=-1，其余-998，不加碰撞／支撑／ghost，不改AC29原生几何、NAV、六巡游、门或任务。遗漏的传递来源约束导致首CPU118004自然OS1／96检查1失败：不可变AC.author85DFF仍pin District旧0137，不能只迁城市manifest。已以NEW predecessor helper34B8＋approvalB016精确核0137→C4FB四hunk全文逆及navigation原文，再由AC d744接纳该唯一执行依赖后继；原author／packet／CPUproof不改，Docks来源1515→1518，另三城市仅BI权威叶继承，原失败完整保留。Root残余CPU102496自然OS0／2892检查0失败／26772ms、1842源与15save/state首末同；随后两index sole-bool true，Docks65540自然OS0／1668检查0失败／28341ms／8Physics／2图（第二仅inspection），Market114244自然OS0／1396检查0失败／27216ms／68Physics／1图，finalized1518／1250及15save首末同，0SCRIPT但退出8／7ERROR，明确非clean。Root final_admission D1D7B59E授实际PASS：20canonical／19backup／1845两实际来源当前SHA＋bytes零差；1782守卫仅9授权差，其余1773含15save exactticks同。编辑器保留，不再源改／引擎复测；仅首簇地面氛围完成，不冒全南市建筑规划或全城完成。

2026-10-19x最终收束：Market-only78244自然OS0／1336检查0失败／25886ms，1249来源与15保存首末同、11Physics、本人60px真实Space独立report一次且QM2；未重跑Docks，Root＋QA实看202FCA图并限域批准，0SCRIPT／7旧退出ERROR／1ObjectDB非clean；923最终仅三授权差、其余920含15save exactticks同，53来源及6部署targets零差，用户editor51856保持、Root自身引擎全自然退；三支线已正式可重运行试玩，v媒体仍候选、数值奖励0待确认，下方“真实亲领待验”等仅本段之前的阶段记录，不扩大本次实测范围。

## 2026-10-19x · 三文化任务已接正式来源；受控对话／保存通过，真实码头亲领待验

- 用户授权开始接入后，NEW `luoyang_cultural_sidequests_coordinator_20261019x.gd` 与 Field 最小接线消费原 w reducer／资源；原七任务、NPC 原 primary、几何／碰撞／加载门禁不减。6 个既有身份增加独立文化话题，不往 catalog 塞 ground-anchored profile，不冒新增6套人物素材或多数36生活人已补全。三 canonical flat QuestDef 为0数值奖励、空自动触发；未擅加金钱／经验。w 原型、24资源与历史证据保持冻结。
- 最终 coordinator `FC9339579A0091936CF1BB747E84667E017D0EB57FFD025918023601AFC51DA9`，own runtime contract `DA49FE454E9AB975485E75E96772834F2A8C312463CF96BFF8ACEB6C0D050C1F`，Field `F4BE15C219C7873AE37D918C3B989BBBFABF4B782B4EE5711BBF9D6B2C0900EE`；Root 唯一 culture index bool true 后为 `CA40357AC1B478DBDD71CA6D3CDCB698D7BCCD776BFBD22EF36975D7D6FE575B`。Root 6项来源元数据已精确后继，当前 bundle index F834、Temple helper EF44／NEW binding 4E4272，53 true closure EF37；不重制原 artifact／几何 proof，不任意接受当前磁盘 SHA。本人未启动引擎、控制用户 editor51856 或写玩家保存。
- 活状态是六键 reducer 状态的 JSON **字符串**，存现有 `GameState.flags[luoyang_culture_x_<key>]`；另 `GameState.set_flag(luoyang_culture_x_progress_changed,true)` 作独立布尔通知。全局 GS/QM/DP/Router/SaveManager 不改，listener 不接 Dictionary/String。只有真正 absent 且 QM0 才新态，显式 null／非String拒绝，字符串必须解码为原严格六键合法态；JSON整值float只在既定小整数域规范，绝不把 bool／小数放行。QM接取／完成仍走原接口，原存档格式兼容，旧 solved 单旗标不授新任务进度。
- 对话事务绑定真实 Field／Router当前ID／完成且未失败的加载 owner、Scene／Player／NPC 实例、当前原生身体、118px距离、同一 DP script/node/session 和正常结束。接取者／解题者／三条证人／回报者各自严格角色授权；原 primary 经独立菜单派发。adapter 向 w 只构造精确公开 String-key payload，不透传内部 qid/meta。归信 solved 才迁移同一 buyer 身份到 Docks；原记货伙计与收信人均须真人可见实体、距离／原C／实际Physics通过，现有封信 PNG 成为可见无碰撞 Sprite，0.45s 从伙计转到本人后才允许 collected；成功句晚于真实转交与提交。Tween 使用带 serial／weakref 的非 await finished 回调，取消清自身旧物件，旧回调不得清新会话。**以上亲领实现尚无本段实机场景验收信用。**
- Root 受控最终109256 console自然OS0、1090检查0失败／9536ms、62来源及15保存首末一致，0 SCRIPT；17个坏JSON负例产生预期 Parse JSON ERROR，明确非clean。前两链实际 DP/QM 接取、三证、可重试解题、独立回报一次、进程内 JSON saveparts往返通过；归信三证正确后只到 solved，未领取／未回报。这是 `CONTROLLED_OWNER_NOT_REAL_MAP`，不冒 C setup、城内实走、实际信件交接或配音图像完成。
- 默认无参数 source audit115872自然OS1、9102检查1失败／91679ms，四完整 collector 709／1034／1447／1240和逆映射已执行、2473去重来源及15保存首末一致；唯一60秒预算失败原样留存，不改预算、不重跑四 collector，不授整体 PASS／场景加载性能。Root/QA 正透明限域复用其 source-only 事实准备实际 Docks→Market 代表检查。生产源码当前全部冻结，只响应确定实际错误，不重全城／十房／w逻辑。
- 失败链全部保留：116172类型推断 SCRIPT、118216合法accept未推进、115768明确 `CULTURE_EVENT_FIELDS`、119368虽736/0和OS0但全局 bool(Dictionary) SCRIPTFAIL、72620解码float与规范int直接字典等式误拒。每版源码／closure前像在 `game/build/luoyang_culture_integration_20261019x_source01/`；Root追加事实在 `game/build/luoyang_culture_integration_20261019x_root01/validation-observations.md`。109256不冲销旧失败，115872不洗成成功。

### 本轮接线经验

- `--check-only` 的入口 proper0 不证明被动态 load 的 API 可执行；先实际 `Script.can_instantiate()`，再读常量／调用API。带 Dictionary 字段的组合表达式用显式 bool 等确定类型，不能把衍生 Identifier/FLAG 错误当业务根因。
- 会话私有事件与严格 reducer 公共事件必须在适配边界分开构造；点写 Dictionary 键可能是 StringName，JSON日志会抹平键域，不能仅看打印出的字段名就判合法。保 w String-key／精确字段规则，不为适配错误放宽它。
- 既有 flag(value:Variant) 不等于全局 listener 能接任意 Variant：真实 GS99无条件 `bool(value)` 先于业务前缀检查。结构化持久数据与 boolean 通知分离；不盲从 Dictionary 换String后仍原样 emit，也不因此改全局 GS。
- reported failures=0／自然OS0仍须查 SCRIPT与ERROR；合法“拒接”必须正常返回而非任意错误都当作拒接成功。先加只读 receipts 取得 terminal／selected／finish 精确证据，再作最小修复。JSON数值域用既定规范态比对，不以 String JSON 或 raw Dictionary直接等式冒语义保存正确。
- 有限 source-only 审计超预算仍是整体失败；其已完成的严格来源事实可明确限域交给下一独立代表检查，不能为变绿重跑全城、扩大预算或声称实际可玩。取消时不得 await 一个可能被 kill 而永不 finished 的 Tween，更不能让旧 serial 失败路径 abort 新会话。

## 2026-10-19w · 三文化支线纯候选，洛水归信强制本人亲领阶段

- NEW `luoyang_cultural_sidequests_candidate_20261019w.gd` 与 `data/luoyang_culture_candidates_20261019w/manifest.json` 是独立候选，`FORMAL_ENABLED=false`、无 Field/C/Router/DialogPlayer/QM hook，不读写玩家保存或真实任务状态；本角色未启动引擎。三候选 ID 为 `q_ch4_side_08_qiangxiang_receipt`、`q_ch4_side_09_luoshu_numbers`、`q_ch4_side_10_luoshui_letter`，3 QuestDef +21 Dialog／31节点由 Lore 提供，全部奖励候选0/TBD、触发与对白副作用为空。Root/QA 后续只作 NEW 薄键，不复 u 四区或 v744。
- `new_state`／`transition` 仅深拷贝六键 JSON 状态；schema/count 接有限整值 int/float、拒 bool/小数；接取无奖，3条 exact clue 均需正确场景/NPC且涵盖2地2人，错误解答可重试，回报一次；旧 solved flags 完全无入口。source_paths 成功时固定26叶（SELF+manifest+24资源），资源缺失或变源显拒。
- Root 复审发现“推理完成”不等于“已亲领”：仅洛水归信新增 `pickup` 事件与 `collected` 状态，必须 `solved` 且3线索／正确答案仍完整，在 `ch4_s2_canal_docks` 的 `harbour_life_docks_booking_attendant`，指定收件人 `district_life_market_buyer`，`personal_pickup_confirmed` 必须为 bool true；此前 Market report 必拒。其它两题不接受 pickup 或 collected，仍 solved→report；提前／重复／错人错地／伪造少线索 collected 全拒。此事件只是候选逻辑声明，返回 `actual_world_presence_verified=false`；未来正式 Coordinator 必须验证本人实体到场、原条/封缝与真实交接授权，不能把玩家选择按钮当本人出现证据。
- 最终源码 SHA `F1AB01D8D8CA1B31FFBA178B1B1FA8FCA661E598741CE5C84F37B029CC9614AC`，manifest `7FA69F44D8E176832BA5A2C177565905A335753654761DDA575459A0C64BDF35`；24资源静态逐SHA零差。前版 module506D／manifest4D6C 精确全文保存在 `game/build/luoyang_cultural_sidequests_20261019w_system01/before_personal_pickup/`，Lore三资源修前另保留，不篡改历史失败／证据。此条仅 SOURCE_READY，不授 proper／actual／实走／配音／正式完成。

## 2026-10-18q · 最终交用户试玩

ROOT/QA末轮two96036自然OS0、1893项0失败/79.544秒（result C152EC0C6A5000CB66561A38EC9C7590842C6084146542C21C6D0AE443B7E25C），豪宅1.908964秒/仓栈1.912528秒均含Loading隐藏可动、同Field/Player/Scene及精确返脚，353来源与15保存首末及QA当前同，Root/QA实看两图。
豪宅一ULP返脚域已由g9468/Router1566严格scalar-first修正、无epsilon或门/碰撞放宽，Temple3B59/v12 D9C8最终保持；spacing P1C94普通105980的1291项0失败已正式，原失败/历史证明保全，不授全城间距或首次加载完成。
815最终guard仅五授权SHA差、余810含15保存精确ticks保持，NEW spacing/binding/import另闭包核且引擎全退；末93Image/9ERROR（WASAPI两项＋旧退出七项）/0SCRIPT/ObjectDB非clean，本轮停止实现与引擎，交用户重启试玩，详[p/q专题](../luoyang-building-spacing-and-interiors-20261017p.md)。

## 2026-10-18q · 十新组装房已实测，三新门补齐原生多边形；撤仓仍候选

- ROOT 实际十新房74976自然OS0，564项0失败/39.708秒，结果 `game/build/luoyang_ten_rooms_actual_20261017p/74976_2581/result.json`（87C595DD…）：十类真实Field/独立家具与代表遮挡、原feet/34×24通过；旧Smith作为第十一类复用，不冒十一张新图。该scope明确不是外部门往返。原28图strict透明边失败保持，未擦源或缩身。
- 三新外门旧g遗漏 `interaction_polygon_px`，41700实际拒绝保留。NEW g D2F726仅三append补已批40×32原生world矩形poly，中心沿原UV→world操作，C安全足/Field缺poly拒绝不放宽，原七门/Smith/59家具不动。Router1082原仅数immutable parent portals，三投影门count0使park拒；NEW Router `9CFBF3D17CB263B63D50558B5D95A574286BFE921DA45DCCDA04A84272CAA869` 唯一park hunk改数严格成功的g同源投影，原safefoot/receipt/return/stage/detach/取消/内存门禁不减。
- 三门retry3实际33216自然OS1保留：当铺真Space进出、同Field驻留返城1.777007秒通过；内宅真入且PARKED，但返城原2000ms超时，第三仓门未执行，不能称三门全通过。超时未保存当帧return/Loading状态，不能定罪某callee或声称冷fallback；当铺metadata524.106ms/resume19.583ms/Router总1154.107ms不含hide，外部隐藏可动1777.007ms，仅有限分项。未实施性能改动、不延2秒/180/60。
- ROOT 已原子部署spacing接线依赖：Harbour `1A269BC65DF4AA70EDD59A67EE5415768BEE039EA52188939905746A99EF61AD`、District `6921FA796C419202FC9707559ADDABDB013EA0B37EC51E6303E9F4923A79FC17`、g `D82232B96035F365652831238BAD490E79DC973B75D3550C79D6AB6B2070B979` / NEW registry `959BC6F5408261586A6165BF731347959E6287BEA9AFA8BFB40F6E4035302AD5`。g保留D2F三门poly及既有正式状态；仅11处District pin 2CBE→6921，先对不可变prior7255作完整逆映射等式，再原89历史proof核prior；room_path/末检逐SHA原样，原registry/CPU firstfinal不改。轻admission83828自然OS0/33项0失败，1ObjectDB非clean。
- Temple实际helper `CDE7675F20904610C3FBA203E2A4FA9BB947D049E23F2E154A2D9C0FF1B56F90` 选择NEW v11 binding `33DCF6D9E1EB55841951C5610F71D021DEB5BA3F0ED72BC3D617131E07C1D3BE`：从Router-aware v10 E50D衍生，仅currentHC26E2→1A269及priorv10/显式revision；Router9CFB与历史firstfinal/原字段保留。旧C6B6 spacing候选仍pinRouter1082，**不得部署**。完整精备/diff/交接见 `game/build/luoyang_projected_room_resident_20261018q_source01/`、`game/build/luoyang_spacing_fusion_20261018q_source01/`、`game/build/luoyang_g_district_dependency_20261018q_source01/`。
- 新walk54F106已ROOT隔离parse72692/import39316/verify101424自然OS0、1行fullRGBA/23params/noMip；报告7422F8F6…，仅原absent新import0B839159/ctex8CFD81FB精确复制。spacing helper `AD8F3EDE08596A56892FB482C64994CC58480A038BD0B9480806528CAC2EDEB9` / binding A52E4B51…保持，**FORMALfalse**。CPU67340的103首末历史留原事实，只声明current旧→候选依赖，不补造新first/final。
- 候选Docks实际103592自然OS1/1108项2失败/37.609秒（476E860C…），仅QA错误要求新游戏受任务条件控制的 `warehouse_mud_trace` Sprite永久存在及衍生scope失败；C27record/source已过，QA正按真实任务投影窄修测试。**尚未授候选Docks通过或撤仓正式启用**；不把接线部署当实机完成，不称其它Docks/Market/Yamen间距已修。本轮本人只准备/源审与角色记忆，不启动引擎、控制用户进程或写玩家保存。详情：[p/q专题](../luoyang-building-spacing-and-interiors-20261017p.md)。

## 2026-10-17p · 码头撤重复大仓候选CPU通过，未导入/未实机/未正式

- 用户叠房截图确认为Docks原北仓 `north_canal_warehouse` `[870,580]`、新增 `harbour_main_warehouse` `[1450,650]` 与右供货铺 `[1930,530]` 互穿。候选只撤无门新增大仓的唯一render entry、六顶点solid与record object；原北仓/右铺全部值、北仓门 `[754,610]`、NPC/任务/原路线/roomreturn/BGM不动。保留两楼含全部A>0尾迹仍有117.50px水平缝，未调alpha/缩建筑或人物。其它Docks/Market/Yamen间距问题只盘点，**不称全城间距已修**。
- NEW helper `luoyang_building_spacing_20261017p.gd` retry1 `E74A2595588286378587ABFCBC13F22C9605B86B53E45FDB8645AC1B9B54ADA5`；author `A6ECCD68C78947AF74DE4FED5E1D844F464D316E21D9524688CF5439F92571AD`；publisher `33E25E0E9C5A580ABB2272FED3164864FE30A31E8B6095E1CFF093933ED3C3C9`。仅候选Harbour `1A269BC6…` / District `6921FA79…` 及Templev10依赖草稿放在 `game/build/luoyang_spacing_20261017p_source01/`，现役Harbour26E2/District2CBE/TempleA85A/C/Field/Router/LM/resident与旧发布/图片/import未部署或改写。原完整父证明先过，再唯一撤仓与同raw减剩余solids，Scene全storage可逆检查及District完整父record显式逆映射，不宽松略字段。
- 首proper108260自然OS0/空stderr；首CPU11088自然OS1约3秒，helper错误把4参传给C三参 `_safe_body_cpu`，SCRIPT失败保留。已将失败helper8E311和publisher全文精备至 `game/build/luoyang_spacing_20261017p_retry1_source01/`；retry1仅四行/五调用移除多余cancel实参，原上层独立cancel检查保留，C原full875/continuous算法不动，author/publisher无改。原 `source01/HANDOFF.md` 留作8E311历史，不覆写冒新源。
- ROOT唯一retry1实际67340自然OS0/3442ms，结果 `game/build/luoyang_spacing_publication_20261017p/67340_1837/result.json`（38844700…）：103来源首末、原raw-minus父fullRGBA、28→27、恢复33040像素且无旧clear变blocked、旧2739路线/人群样本＋46恢复路＋2812当前District combined样本/10delta/6moving lanes通过。恢复脚 `[1500,630]` 已有此有限CPU证据，但尚无实际nativePhysics/画面。fresh815末0差含15保存；用户102696/102312仍活，未停止，ROOT自身进程自然退出。室内NOTREADY34392仅proper0，不授11房实机。
- **binding仍PENDING、FORMALfalse，未新walk导入、未GPU、未正式。** 下一等用户关闭后，仅新mask隔离import/fullRGBA＋23params→不可变binding/精确source冻结→候选Docks关键GPU/旧仓门与撤仓区实际Physics及同视角；不借CPU开启正式、不回全城或继续本轮实现。本人本次仅更新此角色记忆，未引擎/保存写。详情：[p专题](../luoyang-building-spacing-and-interiors-20261017p.md)、[间距盘点](../luoyang-building-spacing-audit-20261017p.md)。

## 2026-10-17o · 转场尾段五组 scalar 诊断完成，未实施提速

- ROOT 精备部署 C `06244B1DC286149CE8299CD83F766D2D9F5FD9B61BCB59180261DFF40D8E9D3D`、Harbour runtime `26E2E263426719878CD6E7853878D25277E25483CBB495BB3DF44116EFC6B5B8`；Temple helper `A85A521825C9AF4CD5FAF44A6E2952EEFCADCCDE4A06E2409213BE7EF177C08C` / NEW v9 binding `62D91B80EF217BD3192CBAB9D1CF9C846ED04E85E1664887B14BA04BB3941A55` 仅明确当前来源依赖，历史不改。五个固定 scalar row 绑定实际 token/id：Harbour import readback、materialize/serialized、C nav commit、proof storage/copies/maskSHA、成功 packet validation；原字典发布表达式/return/await/owner/取消/完整625叶首末与全部算法保持，诊断缺row不新增生产失败。
- 唯一普通 GUI110208 自然OS0/526项0失败/whole44.116秒，真实首次可移动21.837秒；这是诊断结果，**未实施或授予提速**。五组均token2：import51671µs(frame1336)，materialize6942µs、commit7677µs、proof63553µs(frame1337)；packet9次跨frame1337..1501，总817389µs/max91634µs，不能将跨帧累计相加解释一次卡顿。
- 最长gap1.664372秒，区间37248663..38913035µs/frame1336→1337，起点在import结束后50µs；gap内其余三组仅78172µs，没有被测单次秒级callee。未覆盖候选收窄到 resolve返回后的Router门户准备/新到达核验、重复prepared检查与LM handoff；其中 `_fresh_source_portal_matches` 的world Scene/layout SHA及CACHE_MODE_IGNORE重读只是**待测候选，非已证因果**。后续Field首setup更晚，不混入此gap归因；不据此删门禁或追加优化。
- 最终509保护事实仅三授权旧脚本差，余506的SHA/长度/精确ticks保持，15保存不变；v9新依赖另核。本轮本人仅源审/记忆维护，不运行引擎、不新增测试或改其它生产文件。详情：[o专题](../luoyang-tail-profile-20261017o.md)，候选备份/diff在 `game/build/luoyang_tail_profile_20261017o_source01/`，实际结果 `game/build/luoyang_tail_profile_gate_20261017o/110208_2574/result.json`。

## 2026-10-17n · live 树首次 Mesh pair 复用已接，整体提速未达成

- ROOT 精备后部署：Original `FB11C1DD600587666A00FEC57C67AEA4AE597FB1F8A3302FDD6746117C2FCFF5`、Note `3B07679017AF1B8FC02FCF4A5940C41AF0707572ADA8964CB287A64D3FE6EC53`、BASE `EE8FBD88436817C7EAEDAC159A3563034B806340F4C777F3650B5D6C60768B0B`、Temple helper `0538A489D38700C5E795E4EBE3984DF64462B0F6A17D0FB55338A8F68B1AE30E` / NEW v8 binding `F8FE846676BF6E05BA4788BE205142BC4CD5B05397C584DF372EF5173922C119`。仅 live tree 在原完整 class/全slot/faces/storage 校验通过后保留首次两份 Mesh，本attempt local 供原逐surface材质/fullRGBA+mip核验复用，所有owner/yield与clear出口保留；同步/其它mesh原第二load不改，无worker资源访问或全局cache。C/m四源/workspace/Field/Router/LM/resident/素材/几何/保存均不动，历史证据不改，源码审无具体回退风险。
- 首24564自然OS1/65检查2失败保留：测试误限import remap.path，实际branch_arm合法path.s3tc，非生产pair错误。NEW retry1 57656自然OS0/184项0失败，真实Mesh全数组/材质RGBA/mip、同实例交接、伪path/ID及vertex差异/错误空pair/取消与测试持有者释放有限通过；不冒内部local可直接观测或零泄漏。唯一普通108616自然OS0/425项0失败：world96真Space→Gate原出生/Loading隐藏可动→32px/full87517 Physics及实图通过。625完整来源仅Original/Note/BASE三SHA变化，295自身源与15保存首末同。
- tree.load19µs证实局部第二次加载已免，但首次可移动38.017秒反慢于m22.952秒，**整体提速未达成**；其它未改phase也变慢，没有因果证据，不归环境或直接归pair。新增有界maxgap事件3.204269秒跨frame1667→1668，C.active false→true、worker/BASE两端均false、sources_finalizedfalse，仅限定到转场尾部proof发布里程碑，不授唯一callee，也不补造m旧事件；观察器已变，不冒同仪器对照。
- 下一只可有限区分四尾组：Harbour join后实际导入Texture/fullRGBA、materialize的apply_scene/published load/全storage、C revision_commit与job.release、transition snapshot/deepcopy/maskSHA及紧接的同token重复比较。当前没有这些独立计时，不先删/异步化门禁或新建框架。最终508事实仅四授权旧脚本差，余504精确保持，15保存不变，部署后0漂移/ROOT自身引擎全退；52Image/7退出ERROR/1ObjectDB/0SCRIPT非clean。本轮停止任何代码/引擎或扩测。详情：[n专题](../luoyang-tree-pair-reuse-20261017n.md)，备份/diff在 `game/build/luoyang_tree_pair_reuse_20261017n_source01/`。

## 2026-10-17m · Gate module 来源收据正式接入（有限CPU/GPU通过）

- ROOT 已精备并部署六源，逐全文SHA同候选：C `3DEB7395E2441F94068377C905E5A9E85222416C672834BBFAD1754B22AC50CA`、MODULE `95F1C05C217868857F91DA21BAE460CC27E7813A47E907DC47DEC3BBAA3560E0`、GATE `23719D1BE5633DDF681C08AE220FB1196853BFC54894B08C484A48A2DF0121B3`、STABLE `29001631C265538B8D89A7AA13896017BDD49B74D1396BD488C7A810153CD784`；NEW Temple v7 binding `ACAF16F21E0C6E7DBFCF3C71E471A5B26CAF1EC6A6DFE36818EC323B99675952` / helper `9584E0046565C4FCB8EBFB0576B02B8F321B472E20DA49564269CEE3DF782974`。完整备份/diff/HANDOFF及各仅一preload差的QA适配版保留于 `game/build/luoyang_module_source_receipt_20261017m_source01/`；本人未运行引擎，正式采用与实测由ROOT执行。
- 仅 Gate module 消费同次真实 Script、同 token/id、已 join workspace 的当前完整来源收据；审批15叶、四组八路径与 raw/import/ctex 三联仍逐项精确核，无 file fallback，完整625叶首末/像素/Lanczos/几何/碰撞/取消join不减，Market和同步/null/Web原路径保持。C live入口额外 `_owns_base_live_attempt` 门禁是本轮源审新增保护：真实 Gate live 缺receipt必须拒；旧API允许null供同步兼容，**不等于live可容错回退同步**。625来源集合不变，仅四个实现SHA变化；Temple v7仅显式依赖衍生，历史first/final不改。
- CPU wrapper25200自然OS0，实际子进程93528完整结果8401F4DF/303项0失败/11.217秒；未捕获child退出码，不补称93528自然0。真实joined workspace一次，旧Gate packet4.147619秒→新Module1.481秒，完整packet/两份RGBA/walk字节精确同，101用源与15保存首末同；既定失效及审批反例通过，承认执行顺序/cache影响。固定来源重复读量经QA纠正为至少1,138,955,450B（24次审批而非初估12），不是时间百分比证明。
- 唯一普通GUI29348直捕自然OS0/417项0失败/41.202秒：真实world96 INPUT/Space→Gate原出生、Loading隐藏可动、32px/Physics及一图F5BA通过，Root/QA实看。首次可移动22.952秒（l24.705秒），module1675ms（l4258ms），但最大观测gap仍1.689830秒，仍有卡顿，不授秒进/完全顺畅或将整场差值全归本slice。625完整来源仅四实现SHA变化；291自身源/15保存首末同。52Image/7退出ERROR/0SCRIPT/0ObjectDB，非clean。
- 最终506保护事实仅C/Gate/Module/Temple四授权变化，余502的SHA/长度/精确ticks保持，15保存不变；STABLE不在原506，另由CPU101及部署前精确旧F43F全文备份/新2900 SHA保护，不能虚补首ticks或把它冒成原506第五差。NEW v7另核，部署后0漂移、ROOT自身引擎全退。可重启普通工程测试；本轮停止任何引擎/新增实现或扩测，不触warm/十一室内/素材/保存。详情：[m专题](../luoyang-module-source-receipt-20261017m.md)。

## 2026-10-17l · 物件映射复用本次已 join 来源收据

- 最终源：Original checker `17297869279C43E068E442E7269C57CC4D986B5B26C9A2374883D6FF97CB5481`；Note `7E3DD58D49A628E7B9AE3AF428F050526BC5C7B473873C93B10DDE5908FF3825`；BASE `2C2F2CBAF84AFA92A585CD4EAC2670C59BE35C8FB33C0E4164D7469D228B48A3`；Temple helper `CF7E336BA9478C5650403C8653E4D1414655A0DEA236167A1A703BDCAFE05415` / NEW v6 binding `489FE1501CF3CA5F6BABADC34794B8C35A76DC415F8C7890E012CE65D4F9DAE0`。仅 Original 对象映射的 PNG/mesh SHA 在 live 路径消费同 token、完整输入已绑定且已 join 的 workspace source receipt，无 fallback；同步/Web 原 FileAccess、逐物件数学/几何/碰撞与完整625叶首末校验保留。Note/BASE仅固定pin更新，Temple历史first/final不改；旧未选V5完整保留，Market自身映射算法未优化。C9CA2/helper8026/workspace/residentF173/Field/Router/LM/室内/素材均不动。
- ROOT CPU9972自然OS0/155项0失败，旧新版17物件结果/state精确同，错误owner/未join/取消/缺path/错SHA及真实变换负例拒绝。唯一普通GPU83180自然OS0/417项0失败，真实world INPUT/Space进入Gate、Loading隐藏可移动、原34×24/full87517 Physics、32px步行及625完整来源通过；首次到可移动24.705秒，对照上轮43.975秒，但其它未改阶段也变快，**不能把全部下降归于本slice**。映射17次合计438854µs，仍有1.669933秒观测gap，不授秒进或完整流畅。
- 最终505保护事实仅四授权旧脚本变化，其余501的SHA/长度/精确ticks保持，15保存不变，NEW v6另行绑定；52Image/7退出Texture ERROR/1ObjectDB/0SCRIPT，非clean。本轮停止重复测试/生产修改，不借此授其它城区运行、暖返回或十一新室内完成。详情：[l专题](../luoyang-mapping-receipt-20261017l.md)，完整备份/diff在 `game/build/luoyang_object_mapping_receipt_20261017l_source01/`。

## 2026-10-17k · 冷来源完整SHA四线程接入，整体冷加载未达标

- 最终实际源：helper `80261E1BF9B34400C6AA99959D98502B648589FCCF2138231F3907D9826D8B0B`；C `9CA2F4615E576E45B20B2A8CD2B59B07B097095A7199009BA2C7D42877709374`；Temple helper `DE5E929F17E23A4FEB82346A1B6851ACF2F7B2E1BC3C18ED1DAF74FD672AC3A2`；NEW Temple v5 binding `17A3800494524C543FFE9810A4102E36E19DB7C54A37654B7E4D9EA6CF5C63CC`。原C82DF/Temple9D0A/B900与helper80B9完整保留，历史first/final不改。只改变完整文件SHA的有限并发；1MiB合作取消、全部Thread join后才发布完整map、原首末/像素/几何门禁保持；residentF173/Field/Router/LM/室内/素材不动。
- Root薄CPU夹具33324自然0/72/0、全624来源103704自然0/1265/0；2.92GB完整map与独立FileAccess SHA相同，helper1/2/4实测14.154/6.924/3.640秒，Root选择4，承认执行顺序与OS缓存影响。旧52648收尾SCRIPT/外guard停OS−1且无result保留；65112只读诊断未复现，NEW异步夹具修复不改原80B9。
- 普通39608自然OS0/407项0失败/73.626秒：真实world INPUT/Space到Gate、625完整来源首末、原出生/34×24/87517 Physics和15保存保持。来源首检native3.960秒、帧观察首/末3.741/3.883秒变快，但完整冷入场43.975秒反慢于j的35.260秒，**不授整体冷加载提速**。BASE main9.888秒、module CPU7.739秒也变慢，原因未证，不猜环境归因。502旧路径只有C与Temple两项授权变化，其余500含15保存/project及暖链源SHA/长度/字符串ticks保持；52Image/7退出Texture ERROR/1ObjectDB/0SCRIPT，非clean。
- 本轮收束不再跑GPU/benchmark/暖路径或全城，不再改实现；下一独立任务只读查BASE材质实例化与module重复工作。详情：[k专题](../luoyang-cold-load-acceleration-20261017k.md)，备份/差异在 `game/build/luoyang_cold_source_sha_20261017k_source01/`，实际保护在 `game/build/luoyang_cold_load_20261017k_root01/final_guard.json`。

## 2026-10-16 · 码头/南城门外生活化候选源码冻结（未授GPU/正式）

- ROOT授权仅C/Field旧源窄hook，精确旧字节备份在 `game/build/luoyang_harbour_life_20261016_system01/`，C原3B8C→CC0D50787A79007F943E771E8D777ABBB50918E3F5943EB5749ADB9AE69144E4，Field原7765→3B7824E99EA4CD423ADF62324A134AA88AADAEA39DAC70B6692ACFC9FB3FF0E8。完整diff与source pins见同目录HANDOFF.md。Router/LM/resident/NPCNode/Player/旧任务/前轮Market-Yamen-铁匠/world/farm/旧imports不改。用户editor108140/game101700不停止，保存不写不恢复；ROOT唯一运行引擎。
- NEW `luoyang_harbour_life_{author_retry3,crowd_retry3,geometry_retry3,runtime,fade}_20261016.gd`；runtime FEFC623B1FA5D4B4BCD78B9C3F79D0CA3C2D6AA7D0DAD85E5D7359A001E17A8C，`FORMAL_ENABLED=false`，唯一候选flag `--luoyang-harbour-life-20261016`。binding `data/maps/luoyang_harbour_life_20261016/runtime_bindings.json` 4A2E9A4985C0548672F00E8FEE46C33588DA5F27D0C803A345D32A2F86704BCA固定58叶，含全部6NPC PNG/import/ctex、3新美术/2新NAV三叶、原字节ART920A、两实际无损导入报告/许可与CPU出版。
- Docks原21物删除确切oldboat一项，新增6仓储/商铺/棚体量＋两种写实船=28物；主新仓.62门约147px，复用旧仓ratio1.0门约154px，不能缩至mini门。Gate原28物保持，不在城墙前堆普通房。两域各新10ambient=6现役真walk横巡＋4驻留，角色称谓无新故事/奖励/门户；TASK原投影成功后追加，原4港任务NPC来源/交互/返脚不改。merchant right文件实际朝左故inverttrue，guardfalse；原巡游是sin水平位移而非寻路/动态避人AI，不能扩大信用。
- 新NPC仅实例化时使用现役140视觉校准/脚点锚，原160cell的原生StaticBody22.4×28.8保持，CPU同时审连续34×30 Rect/poly与原34×24/full875+17、4px步完整包络/互lane/受保护脚。空ambient关闭Area monitoring/pickable/highlight而非删身体。Field `get_harbour_life_state`给值副本，原actor列表/group/销毁，不建新全局循环或跨转场缓存。新CPU仍同C exclusive revision job/canceljoin/完整来源首末，导航只完整成功commit。
- actual111568 Gate首次fresh storage拒、48108 Docks拒完整保留；83416诊断Gate9项、24824诊断Docks8项仅unused world_origin Float64短写且native f32同，但Gate还漏原apply_entry图集/sort协议，不能仅加approx。retry3 Gate完全深克隆父28entries；Docks保父20entries（旧船已删），仅新8渲染entry省去Field无consumer的冗余world_origin，完整author/native record仍保来源与几何，所有Scene storage/record writer-domain严格比较不删门禁。
- ROOT actual93032_1727 CPU result B1BF4131AA7458919FF243C6770B0A2BCFAF071A2E7890294AED6FECD77BB018两行通过/Gate1842+Docks2739完整采样，69.576s；wrappergone但OS码未捕，不冒自然0。ROOT三图100260、两NAV25016分别自然0全RGBA+23params；10个新import/ctex目标均原不存在，File.Copy(false)后实际SHA精核，没有旧import覆盖。proper与normalheadless动态C/Field编译自然0，1ObjectDBwarning/0ERROR，ROOT327仅两授权源变/余325含15保存exactticks零差；独立源码审有限SOURCE_APPROVE。
- 当前仍**候选**，冻结供ROOT一次120s/60arrival短GPU：两域各4s人流/真walk帧、两代表87517/Physics、原chief/门吏及原world门可进入、reset释放。没有运行验收/正式艺术/音频clean信用；通过后只ROOT最窄formal开关与普通出生，不复全六/旧两区/任务链。

## 2026-10-15 夜 · public 洛阳先显示 Loading、同 token 异步核验与取消恢复（有限实测通过）

- 仅 Router 从 `EEA08CA0111FB06E7A7E4C2C22C26FC770ED0810456A676910C0132E894A14FE` 改为 `DA99D43F6ECEE2CED0CEAEBFB0468BFC21B35A5A6235D2F3C0B965B02DD007A0`；原完整字节备份 `game/build/luoyang_public_live_before_20261015_system01/scene_router.gd.EEA08CA0.source`。C `79F77EBC…`、R正式true `2A90DCA1…`、Field `B5D2B513…`、LM `7CF318D9…`、bindings `AA2CC1E7…` 及 geometry/assets/room author/保存 schema 均不改。SOURCE独审确认 private 原 body 与 EEA0 旧 public body 精确相同；本人未运行引擎，ROOT唯一编译/实机。
- Desktop public 城市 `go_field_smart` 先轻门禁、立即 begin opaque Loading，再 deferred/两自然帧后消费现有完整 live source→CPU/RGBA→geometry→导航链；同 token 首末来源、ready与取消/join不减，无跨转场缓存。返回 true 只表示 `ACCEPTED_ENQUEUED_NOT_READY`，不表示校验完成/已出生；忙/非法版本或finite坐标/缺ID立即false，晚期失败记录值状态并收尾。Web与非城市保留原 private 路径；已准备 portal 直接 private，public pending时任何 smart/portal 请求均最早拒绝，避免写 remembered return 后才忙拒。
- 新 `get_public_city_preparation_state()` 仅给 deep value copy，QUEUED/VALIDATING/PREPARED/HANDED_OFF/FAILED/CANCELLED与token/时间；两帧 draw_checkpoint 不是单独GPU凭据。`cancel_public_city_preparation(token)` 仅准备期完整LM owner接受，同步合作cancel+join后恢复目标C `_records/_masks/_solids/_using_patch` 原has-key/值/原Image身份；保旧Field。request identity 与 C/LM ownership分离，handoff立即失败也可清自己的busy并raw恢复Router四字段，不调用有重校验副作用的 restore_navigation_state；旧协程/旧cancel不能清后继。非本请求transition/newgame/exit取消本owner，LM finish只允许完整token/external owner，不隐藏后继Loading。
- ROOT最终 retry2 actual87192 自然OS0，2193检查/0失败/97133ms；`game/build/luoyang_public_async_loading_key_20261015/87192_2513340/result.json` SHA `FF4D43B1F50551C4277DA9431C2C263D6FBC51EAA8A4AF9368F17529C174FD70` 已只读实核。公开call137.102ms、首真实opaque930.03ms、ready25186.59ms；新token重入call13.615ms/首opaque28.835ms/ready19890.885ms。late BASE CPU取消100811us，四nav原has/Image/fullRGBA、Router/旧Field恢复及实际16px INPUT通过，旧cancel不动继任；客栈真Space进入1232ms/返回20006ms，原门精返/full875+17/Physics/来源final通过。只授本次南市公开入口、一次客栈往返与晚取消/重入，不借此授全六/世界提速/全门玩法。
- retry2 924 inner来源、ROOT195保护源及15玩家exactticks零差；115 Image warnings，ERROR/SCRIPT/ObjectDB均0，不冒全局/导出clean。旧 actual108812 自然OS1/1673/7 保留：QA917闭包漏6室内import/ctex叶，已有call168.186ms/首opaque981.351ms/ready24839.53ms与final通过不能冲销整轮失败；NEW retry2只补6显式pins，不改240秒预算/1500ms显示标准或生产判据。
- 剩余边界：go_chapter提前 `_load_field_scene_def` 同步旁路本轮未改；旧LM failure Retry复用过期proof/token的问题仅登记、不扩大重构。当前 ready仍约20–25秒、实际返城约20秒，不称所有入口零同步或完整加载流畅，下一按用户反馈再限域处理。所有生产源继续冻结，本次仅更新SYSTEM记忆。

## 2026-10-15 晚 · 南市/码头第四层、八门室内正式默认接入（有限关键实测通过）

- ROOT 已将唯一 `luoyang_city_revision_runtime_20261015.gd` 的 `FORMAL_ENABLED` false→true；当前 SHA `2A90DCA1E3CB9A2A662B8E7822DAE161298ACB7F7E21BEC3A0C316EF118EBEF6`，原 false `DA8FAF3D…` 完整备份于 `game/build/luoyang_city_runtime_hook_20261015_root01/runtime_before_formal.gd.source`。本 SYSTEM 未改正式 bool、未运行引擎；实际采用和测试由 ROOT 执行。当前 C `79F77EBC…` / Router `EEA08CA0…` / Field `B5D2B513…` / LM `7CF318D9…` / bindings `AA2CC1E7…` 已逐 SHA 只读核实。原 canonical Scene/TRES/world/农田没有复制替换；运行仍先完整原 C/enclosure/第三层证明，再 source-bound 第四层纯 compose、原 raw 重 raster、全 RGBA/full875+17/≤4px 路线和完整派生 Scene storage 核对，独占 live worker 同 token 取消/join/末来源核验不减，没有跨转场缓存或 take_over_path。
- 正式内容：Market 26 物件、12 门户/8 处已审真实门轴房门；9 个唯一 flat RoomID 显式映射各自 nested scene，原门当前版3精确返回，室内3模板/BGM直用已认可 `city_bianzhou.wav`。旧 published13 门户先完整比对，随后只移除西南双门间立柱的唯一假门，同时移除 gameplay slot 并记录 disabled receipt；因此不把9室内定义或CPU通行证明当作9门开放/视觉全验。北街口 `[2090,160]`、前院墙/树移后侧、门前 solid 延到原 worldfoot、屋后55%/前方1、码头 ferry `[2140,1840]` 与南市口分离、`canal_work_chief` 可见漕工承接原箱 offer action/hide_flag 均已接入。新船仍未采用，无真正豪宅或全城美术完成信用。
- ROOT A3 actual47000 自然 OS0，603检查/0失败/186.440s，result `69632580…`：客栈和西北后排真实小宅两种室内、4次正常 Space（1320/21367/1271/21348ms）、原门 `[735,854]` 和 `[620,524]` 精确返场/full875+17/Physics、同 sprite 屋后.55→门前1及7张图有限通过。B3 actual111276 自然 OS0，659/0/106.611s，result `66B9D58D…`：码头真实渡口箭头、真人 NPC 唯一正常 offer 信号/对白及3图有限通过。ROOT/QA 实图仅授关键视角，两间之外其余已接门仍交用户验收，不扩大为全城/全门/剧情完整通过。
- 无 candidate flags 的正式105620自然 OS0，1204/0/121.768s，`res://build/luoyang_revision_formal_boot_20261015/105620_2641942/result.json`（`12869CC2…`）：默认第四层12门户/8门、普通30px INPUT/full875+17/Physics、门前alpha1和1张实图通过。A3/B3/formal 内部473/612/917源首末 exact，三次 ROOT195保护路径及15玩家 exactticks 保持，implementation前至末15保存也零差；用户 editor108140未停。stderr分别251/194/179 Image warnings，三轮 ERROR/SCRIPT/ObjectDB 均0，不冒 export/全局 clean。来源和结果主凭据见 `game/build/luoyang_city_runtime_hook_20261015_root01/`。
- 加载仍明确待办：public setup 原来4次完整 R resolve，包含8次 BASE.prepare；本轮仅 Router 两行去掉 get_field_scene_path/default spawn 的后两次重复 load，显式player_spawn→同场_current→已验证city default优先级及非城市分支不变。旧0517字节备份 `game/build/luoyang_router_public_dedup_before_20261015_system01/`；初始 resolve/migrate 完整双检查仍在，不能称流畅/冷提速完成。正式实测 setup98.431s，其中同步67.237s；A3 setup102.234s/同步69.470s，两次真实返回南市约21.35s。下一优先拆 public 剩余同步及可见 Loading，不再重复已过双室内、Gate、世界农田或全六。
- 旧失败全部保留：83292西北门路线擦原 street_tree_0，retry2仅显式绕y590不删树/缩鞋；107684 A2自然1/548/3，室内是QA1536设计域与实际1920×1280 cover域混用（同帧真实Physics=true），另12来源仅mtime变/SHA同仍原 guard FAIL。A3只修独立oracle投影/出口坐标并保 native34×24/+42与875家具判据，不改生产房间碰撞；QA读取已有严格record深副本避免 getter再次prepare。直接 preload autoload 的 check入口虽OS0但SCRIPT errors，原拒例不冲销；后续实际项目启动三轮无SCRIPT。两新版 walk 只经 ROOT 隔离10516 import/110884 verify自然0/29/0、source/import/native fullRGBA及23参数证明后，精确复制原先不存在的4个import/ctex；approval/proof与四新叶进69项bindings闭包，旧imports不借此重置。当前所有生产源冻结，本次仅更新 SYSTEM 角色记忆。

2026-10-14 最终增量：104580无flags formal boot5 result090006E5保存124/stdout125/0，真实canonical2DF/newlayout26/出生[1536,1860]满875/17/Physics及1GPU通过；普通public→出生85.885s、arrival18.612s，不授提速。wrapper150未捕OS，后有完整result/gone不补称自然OS0；0ERROR/SCRIPT、431Image＋1ObjectDB warning非clean。192＋76来源/15保存精确首末零改，ROOT准备交用户GM南市试玩；此前失败保留，不追加测试或扩大信用。

## 2026-10-14 · 南市连片街坊 v2 接入（候选关键通过，正式出生仍进行中）

- 原16物件追加4连片街面、2摊、4树，共26；原8NPC定义、4门户、4交互、7路线、地板/BGM和其它三城区/world/Loading保持。复用原PNG，没有收费生成、小宅/豪宅/新室内或NPC身份。原875足底/4px路线与fade算法不改，仅C/Field南市窄分派；最终contract `7782EFD9…`、manifest `D617289E…`、C `4A7F23C2…`、Field `7C4EC636…`。
- 初版树矩形遗漏与原PNG import透明边RGB差保全；v2三个runtime alias机械复制后与原source完全同SHA，单独lossless/fix_alpha_border=false/mipmaps=false导入，原PNG/import和v1全部保留。完整RGBA判据不放宽，几何/构图不改；源码精确备份见 `game/build/luoyang_market_enrichment_before_20261014_system01/` 与 `luoyang_market_enrichment_before_alias_v2_20261014_system01/`。
- 候选关键结果138保存/139stdout零失败；wrapper210未捕实际OS、进程后来gone不能补称OS0。原98036/7804/95800/6368失败均保留。canonical已由3D4D→精确候选2DF可恢复切换，旧字节备份保留；正式无flags boot104580仍进行中，不授正式ready/出生通过或全城完成。测试端拟复用已过完整候选来源/几何并fresh闭核，实际875/17/Physics出生仍须通过，不改90/60预算或生产验证。

## 2026-10-14 · 洛阳本地素材板与统一索引试点（有限关键验收通过）

- 独立无依赖 Node18 工具 `tools/asset_board/build.mjs` / `board.template.html` / `README.md`；默认只读取 ART 三份 JSON（20真实条目、16引用登记/1候选/3参考、4精灵规范），只构建 `docs/luoyang-asset-board.html` 与 `assets/catalog/catalog-report.json`。18 PNG＋2 JPEG 实读头尺寸和完整SHA；缺文件保留ID，安全拒绝越界/符号链接、未知ID/prototype字段和超大JSON。没有复制上游实现、接付费API、改变游戏或自动采用素材。
- 浏览器选图最多20项、参考包最多14张；localStorage与导入/导出仅工作草稿，不改变 declared_status。包绑定素材/预览、来源证据、现役引用和关联精灵规范证据的实际SHA，`refs`重新核当前事实；未选素材缺失只列诊断，不阻塞合法选中包，也不授整目录clean。初版CE489/FF5的精灵证据只查存在缺口保留，精确备份于 `game/build/asset_board_before_contract_evidence_20261014_ce489_ff5e/*.source`；NEW最终 build `9F9A6B55616FC4233FFDEBA0970ADC78A05002869B475CC6DD5800081E51781B` / template `82950B0B7649371A2481CBC824468F413971EAF776852C81F5E37CA4C8FF05DA`，REVIEW SOURCE_APPROVE。
- SYSTEM实际 Node语法/check/build成功、20条0文件问题；ROOT最终Chrome2560×1215实看20图片全部loaded/0errors、默认5参考，搜索/分类3/候选1加入6、明暗底/150%保持contain、reload恢复6、非法草稿保旧、合法15草稿禁参考包、默认恢复通过。真实导出6图包 `game/build/asset_board_20261014_root01/browser_reference_package.json`，CLI refs实际0/valid6；QA最终30/30并由ROOT重跑。192有限源与15保存exactticks零差，用户84080/editor36036保持；本人未运行引擎/浏览器/网络，实际UI信用来自ROOT独立验收。
- 已采用仅登记现役引用，不自动证明完整引用语义、最终美术、商业许可、sprite朝向/透明像素/脚底或Godot运行；PNG/JPEG是header-only非像素解码验收。本轮不修改 Loading/地图/生成任务，不授新增城区或动物已正式可玩。工具试点可用，后续人工选参考→核验→原管线dry-run/生成/独立验收；无自动任务恢复或3D服务接入。

## 2026-10-14 · Loading desktop最多8并发预读（SOURCE_READY，实际耗时待测）

- 本轮仅改 `autoload/loading_manager.gd`：桌面同一完整paths集合最多8个在途请求，已有取消请求的drain也占槽；仅LOADED取回，成功全收后才能返回。缓存完成立即补槽，连续主线程收取以8ms批次让出已有process_frame；Web仍原串行资源路径与进度数学。默认world2692=2687独立物件+4视野块+1出生导航，不裁物件/图像/来源/碰撞。
- captured owner绑定external token、controller path、kind与完整context bytes；finisher deferred以及所有await恢复均核owner。取消/失败将当前私有请求数组转drain并清原数组，旧resume不得写新UI/资源或fail/reset新转场。已提交后台请求不能物理取消，只有完成后取回丢弃；退出只一次非阻塞poll并清引用，无shutdown等待。
- `get_field_preload_metrics()`只给值副本：scene_id/limit/count/completed/request_peak/poll_frames/collect_ms/scene_read_ms/elapsed_ms/complete以及active/draining数量，elapsed仅预读阶段，不冒整体Field或实际提速。完整枚举文本逐字与原5995一致；门禁/百分比/去计数中文、Field/Router/地图/LoadingScreen均不改。
- 原5995B345BB019F95C93F40BA9A47F365F0763F315E08562A84247209B26566CC全文16954B/ticks639275400951685490精确备份于 `game/build/loading_parallel8_before_20261014_59d4cf95d4a24614b10606a12fe087ba/loading_manager.gd.source`。本system未运行引擎/import/网络，未停止用户game84080/editor36036或写玩家；SOURCE_READY不授parse、实际速度、完整玩法或退出clean信用，root独占后续短测。

## 2026-10-11 · 用户批准音乐替换后的 catalog 接入（SOURCE_READY）

- 用户明确“可以替换现有的音乐了”，root授权新增23已批准 loop（20地域/村庄/郊外/剧情/战斗＋3早期认可母带循环）；art独立安装到 `game/art/audio/bgm/wuxia_20261011/`，asset manifest `10AC83AC…`。本system未制作/复制音频或启动Godot。QA actual beforeguard `wuxia_audio_install_qa_20261011/before.json`先固定实际dirty源码、99SceneTRES、170旧音频及15玩家。
- NEW `scripts/audio/music_catalog.gd` 显式scene/dialog/node ID选择；SceneScript authored bgm_path及所有SceneTRES/几何保持原bytes，AudioManager ensure先解析实际消费path再播放/emit。99顶层静态映射85新曲/13林西原日曲/1无BGM试验场景沿DEFAULTfallback；六城镇/竹尾/三真实郊外独立，旧山间/行旅通用family用早期认可两loop，旧洞穴danger/树林forest/门派mountain回退明示。未知、新增不在旧fallback键内的合法path保留。DEFAULT_FIELD原village_day_v4、DEFAULT_BATTLE新battle_default。
- 四story明确ID：ch4_case_clue紧张、linxi_center_granny温暖、ch4_peony_poetry与ch1_side_caravan_done欢乐、ch4_temple_ambush与ch1_road_corpse危险；不是文本关键词猜测。night只在现有ch8_master_ultimate_breakthrough n6/n7“灯火初上”节点，DialogPlayer仅_show_node一行转交，无昼夜feature/文字效果修改。正常end只还原owned path/context；场景/显式play/stop/validsting取消ownership，battle/sting禁止新cue；local end同步重开对话由DialogPlayer.is_playing挡旧EventBusend。相同night曲n6→n7继续不重启。
- 新23首首播0，WAV沿原全文件loop_begin0/endlength；同曲继续/跨曲淡入与旧legacy quarterentry保持。Battle角色顺序只改五family/BOSS常量，spar/boss判定与结算不改，旧victory sting/SFX不动。当前固定Catalog `CAFBABDD…` / AudioManager `2DF54104…` / Dialog `B2738778…` / Battle `BAD948D8…`，独立limited SOURCE_REVIEW_PASS；无runtime/耳审信用。
- 对照actualbefore报告 `assets/processed/audio/wuxia_music_adoption_source_20261011/source.patch`（`9868649E…`）及source_mapping.json明确旧资源身份和实际选曲。root串行import与真实WASAPI fixture待执行；用户editor36036/存档/正式城市几何保持，公共docs由root写。
- 初稿保护后root批准最窄Web队列stop修：stop_bgm清空pending path/context，防未解锁story在explicitstop之后复播。当前AudioManager最终 `2A089D4B…`；NEW source_final.patch/source_final_mapping.json对应最终source，初稿报告保留不冒旧SHA。桌面gate模拟不授浏览器执行信用。root首import OS0但历史466/source_copies造成global class cache污染，原失败证据保留；QA/root独立修扫描metadata，本system未碰该目录/.godot。actual音频fixture仍待，不授runtime PASS。

## 2026-10-10 · ROOT466 建筑轻淡化实际候选 Field 专项（有限通过，未正式切换）

- root 串行 NEW623B/3F5D GPU 专项自然 OS0，stdout36080/0、保存 result36079/0、complete=true；实际目录 `game/build/joint_world_luoyang_20261003_qa/building_fade_actual_field_retry1_1791596538_3074164_6028/`，result SHA `B97FCF9EF62599F6678573DFC9B79D09A7FAA589968F077919F3D2A87C598107`。root 独立有限实审通过，不是 standalone 平面夹具或旧阶段借用。
- 六张实际 GPU PNG、当前原图/导入身份、native 脚点/Z/source-alpha 与 exact union 合格；原 gate/inn 真实后方输入建筑 .55，前方/离开恢复1。四个实际 rebuild/exit 的38个唯一建筑均恢复原 Color，缓存清空，本轮无资源退出错误。原465 FAIL保留、不覆盖；也不据本轮清退出冲销原456失败或猜其归因。
- 本轮17196来源和15玩家存在性/字节/SHA/精确UTC ticks零差，runtime `B0C4DBED…`/Field `6073DA10…`/旧正式四保持。本人本次仅 NOENGINE 更新记忆，系统源不改。
- 信用仅为候选 Field 的建筑淡化、有限真实输入/视觉及上述生命周期专项：未新增有效 Player 热换实际case、未新增 native 等脚tie实际case；不是完整 geometry/gameplay/audio/六阶段或正式批准。Dummy 有限专项不授 WASAPI/音乐连续信用，正式四尚未切换。

## 2026-10-10 · 洛阳 enclosure 建筑轻淡化候选 Field 接线（SOURCE_READY）

- 用户批准“建筑淡化一点，能看清人物即可”；root 授权只改必要 Field 接线与 NEW `city/luoyang_enclosure_building_fade_runtime_20261010.gd`，继承冻结 preview `BB5D1215…`，不重写当前帧/source-alpha/native Float32 脚点排序或旧局部 ghost。默认建筑显示 alpha 乘 .55，进入/空间离开 .18s，前方/同脚立即恢复；原人物本体 alpha 不写。四区实际79物件中仅38明确建筑墙体（15/13/3/7），树灯/摊/船箱/栏杆/地表/札记/石碑均排除。
- Field 仅现有 `C.is_v3` 且准确 enclosure manifest 元数据分支创建 runtime 并 `configure_scene`；非四ID/配置失败明确 ERROR、释放未配置实例，不降级为淡化 helper。普通旧city3、world14/15、郊外及普通场景选择保持；旧 native F926 preload 常量保留。原自然晚刷新与强制刷新都沿原接口，只有 NEW helper 的无效 Player 分支进入清理。
- `_setup_scene` rebuilding=true 后、Player 清空/世界变换/移除子节点前 release；Field `_exit_tree` 同样 release。有效 Player 更换先清 previous/current ghost、原 Color/签名与计时起点，不丢物件注册。release 恢复原 self_modulate RGB/alpha、清本实例 props/depth/mask/image/弱引用；有限 last_release 只保存 ID/实例整数/前后 Color 值，不持节点/纹理/callable，无新 Tween。
- 改前 Field `1EB104FA…` 实际 ROOT456 已保存的166395字节 `.source` 独立核 SHA 后 Copy-Item 至 `game/build/city_building_fade_runtime_source_before_20261010/field_walkable_controller.gd.1EB104FA.source`。如实为既有 actual guard 副本，不冒称本次编辑前重新取样。冻结 BB5D/F926/C558A/Player9F283、正式四资源/美术/15玩家不写。
- 本轮仅源码/窄 diff 与独立审查准备；本人 NOENGINE，未运行 parse/Field/音频/六阶段或正式激活。QA 使用原候选双 flags 的 NEW actual Field 专项，真正人物输入、恢复和退出收据待 root 串行运行；Dummy 只授有限几何/视觉，不能冲销原456资源退出失败或替代严格 WASAPI 验收。

## 2026-10-10 · NEW 地域/剧情/战斗 BGM 候选映射（未接入）

- 只读真实 SceneScript / world-bible / BattleController，确认六城镇为洛阳、汴州、金陵、襄州、清河镇、雁门关；东海实际是“东海埠 · 内河接驳栈”，不冒称海港。两村林西/竹尾，三郊外林西竹溪林/襄州密林/金陵南泽；四剧情紧张调查/轻松相伴/欢乐相聚/危险潜伏，五 battle family spar/river/mountain/village/boss 保留独立语义。
- NEW 仅候选应用说明 `assets/processed/audio/wuxia_regional_story_mapping_20261010/README.md`：已重核最终 plan（SHA `711bf22a…`）20个唯一 track ID。两村庄方向为竹尾晨市/故园夜色；三郊外 ID 为 `outskirts_zhuxi_linxi`、`outskirts_forest_xiangzhou`、`outskirts_wetland_jinling`，分别对应实际三地区；五战斗 ID 对应现有 spar/river/village/mountain/boss，不新增 sect family。林西已认可实际 village_day_v4 白日曲保留。紧张调查与生命威胁、轻松与庆祝分别区分；不自动按地名覆盖剧情。
- 用户最新用途为个人使用、暂不商用，不扩大未来商用许可或登记事实。并行 city source guard 保持，本轮无 game/Godot/玩家写入；上轮接入补丁/恢复包任务停止、不恢复。本表不授听感、真乐器、循环或 runtime PASS，主控统一后续集成。

## 2026-10-09 · 四区 GPU 与独立 native 地面进入 Field 候选（正式未切）

- ROOT393 府衙真实 patch `2E1F562C…`、ROOT395 native 码头记录 `967ACAA0…`、ROOT398 三计划与 ROOT399 gate/docks/market 三真实 patch `20CB77DE…/B4B06110…/BA46BFA0…` 均由 root 串行执行并保全。ROOT396 显式 ground_overlay/water_decoration 37项正反例零失败；非阻挡装饰不新增导航支持，墙仍实测脚底阻挡/ghosttrue/真实Y排序。native 板船材质为项目原创简模，不冒称授权扫描或成熟写实。
- ROOT397 错65位 exporter SHA、ROOT400 首 ground 的 JSON float尺寸Array→原intArray拒绝两份失败保留。仅NEW caller逐维验证有限exact3072/2048再复制为int尺寸，whole相机经原writer JSON域严比较；不改冻结Zone/BASE/阈值。ROOT402 四区 native ground 实际 OS0/source-player0：仅移除指定旧native caster，其余原mesh/basis/origin与支持/铺地材质保持，395新deck/boat真实saved mesh投影；不造PNG代理或CPU抹影，原14px顶点土迹保留。
- ROOT403 四整图与八近景实际GPU/source-player0，root/art允许进入可试玩Field美术候选；旧悬空墙影已去除，原重复空灰地/城防简模/低墙平切/暗灰船篷仍待办。这不是NPC遮挡、碰撞、剧情、音乐或正式批准。
- 经 root 403授权，C `D112F9E7…` 精确绑定四patch/四ground sidecar；GROUND `39F844CD…` 独立核原/新caster mesh/basis/origin及whole catalog、相机、PNG导入。effective record额外ground_path/capture_path/capture_sha/catalog；materialize background/meta明确绑定，runtime严对照。stable仅extends一行 `A9787378…` 到NEW C，无候选flag原formal继续BASE委托；原037C bytes已备份到NEW cutover/source_backup。
- NEW city-only activator `CCAEED8F…` 只准备源码，APPROVAL_SHA仍PENDING闭锁，不执行。四city原SHA及world14 `838380FD…`/outskirts `203C9F08…` 只读复核未变。下一候选publisher→两端fresh几何/玩法/当前保存→root审批city-only备份切换→正式无flag复验；不做用户取消的旧存档兼容、不扩世界QA，editor36036保持。

## 2026-10-09 · V11 实际 author plan 与 NEW 码头 native 捕获源

- 根 ROOT391 source-load 实际 OS0／24项零失败、完整 stderr 空、来源/玩家零变化；ROOT392 plan 准备实际 OS0，原13移除/9保留/11新Y组13UV与真实南1680、视觉1689.5/通道940..1200保持。实际计划 `CAB3991FE92315E61876374AA492177F9AC8441703EC27D757D16DF97F724E6E` 经根批准仅填新 consumer 的 EXPORT_PLAN_SHAS，consumer `979C039445EF0B8DCA68EBA1BD273362BE28F7992952824FCC2FBC888EC54B31`、exporter `7493ECC658D5548C687E3F0D0DA041D71E9F8C318215BEE7F9F3491F0BA60EA9` 冻结待 ROOT393 GPU；patch 仍 PENDING，非 Field/美术/正式信用。预览新源码 `preview_luoyang_enclosure_v11_export.gd` 用实际 patch SHA，只读五个完整院落/连接/门楼窗口。
- 原 v11b raw/gate 与 generation record 已逐字节复制新 source 根，原图未改。短纵 run 失败保留，实际 source 不是完整480/320生图；11组通过真实等比模块/内域重复补长，不能冒称图片原生完整围合。
- NEW `export_luoyang_docks_native_v12.gd` 源就绪未 engine：只继承冻结旧 capture 的 camera/environment/alpha/read/sync 工具，不调旧发布器。实际 deck/boat helper 原 mesh/material/identity transform、明确 local ground anchor0→camera投影，canvas crop同时含alpha与语义anchor；实际 raw/repeat、独立PNG/native.res与重新加载draw数组/来源SHA待根串行 GPU。码头 native 材质明确项目原创程序化木纹/帆布/铁，非 CC0 扫描。原详细货箱与剧情 chest ID/图像来源保持。尚未接 patch，船仍需全合法角色域/当帧alpha阴性验收，府衙与码头不能自授四区完成。

## 2026-10-09 · NEW 洛阳 V11 围合消费/独立导出（SOURCE_READY，未运行）

- 新 `city/luoyang_enclosure_v11_candidate_contract.gd` 是小型 composite：严格委托冻结 V5 note BASE 校验/物化原始四区，仅对明确 patch 地区按 `remove_object_ids` 移除旧墙/中央门旧U形载图并追加独立 PNG。未 patch 三城仍旧批准来源，不授新美术信用。`effective_author_record` 提供 BASE+patch 原始 author 记录；QA可独立读双 manifest SHA+plan SHA合并，而非 production materialize 自证。
- 新 exporter 仅 dev GPU UV载片→每个真实Y片独立RGBA，生产仍既有 Sprite2D / 34×24足体 / 实测WORLD solids / 原8px深度带与局部alpha；人工地面foot与alpha bbox/末行视觉brickfoot严格分离。新 walk 必须从冻结 `raw_walk.png` 逐保留/新物件实体重建（原integer polygon、half-open box、24px guard），不能从旧final walk开始而留下移除墙的隐形阻挡；原 routes/gameplay stand/portal passage全部净空保持。
- 来源plan/patch pins目前字面PENDING而闭锁，未 engine、未 GPU/候选发布/Field/正式接入；root串行执行，用户 editor36036与玩家档不动。新 publisher 只写 `luoyang_enclosure_v11_candidates` 独立 scene/layout路径，拒覆盖不同既有资源，不能激活正式；stable city wrapper尚未写。
- `PlatformBridge.set_checkpoint_saves_suspended(true)` 必须在首次await前获真实ack并持至quit，不是 SaveManager 的不存在方法。GPU导出观察consumer源码first/last，记录其pre-final-pin SHA但不放current-byte catalog：consumer稍后填patch SHA会变，否则构成 consumer→manifest→consumer SHA循环；最终consumer由root独立冻结，不伪造执行源身份。
- 本轮新增consumer/exporter/publisher已静态接口/搜索核对，未安装gdtoolkit、未声称Godot parse/实际通过。等待art V11b真实足/UV/solid接口与root解析后，才生成并冻结计划/实际GPU；码头板船箱、街区围合及完整四区玩法另待，不把府衙局部升级当四区完成。

## 2026-10-04 · 060来源SHA缺省窄修（SOURCE_READY，未运行）

- 根实际060候选publisher OS1因 notice_pavilion 缺original_source_sha256拒绝，实际原图/common/runtime均523CA108…883CCB，并非bytes不同。CPU逐四当前合同和原文件核对：16个v2复用实例、13个缺原SHA/3建筑已具备，sourceSHA/catalog/current及三bytes全部一致（0失败）；另5碑箱直接来源属于旧registry。此CPU检查不算publisher或Field通过。
- 仅 `_reuse_error` 按根批准收窄authoring分类为generated nature且original exact v2/source前缀，避免碑箱相同nature被误分；只有authoring缺省key可选择source_sha256，显式null/empty/wrong仍拒。两个schema sourceSHA必须严格等于当前catalog/source，原/copy/runtime相同及冻结entry语义/尺寸/身份检查保持。新City冻结SHA `56386DE74D5A9E57088C38A542ED4CC8EB43298D3B52539A9C233A3C7824B7D7`，world gate E717E46B未动；060失败与旧00FC来源留存，未开引擎/改ART/写正式，等待根重跑。

## 2026-10-04 · 055来源合同分支修正与真实viewport（SOURCE_READY，未运行）

- 根确认生成建筑/物件与碑箱复用是两套来源记录。仅City合同新增 generated_independent_architecture/city_prop 的精确 `source/reused_architecture_authoring.json` 分支：status FROZEN_AUTHORING_GEOMETRY_ONLY，冻结原v2合同948702C2…887B及当前实际bytes必须相同；记录texture/source严格等于original_source，catalog/current SHA、原图/common副本/runtime三字节、真实尺寸及source_semantics逐值一致。碑箱保留原 `reused_city_prop_provenance.json` 的身份/status/source_bytes_modified检查；缺省只选对应固定路径，显式错路径或错类型仍拒。未修改041艺术合同或registry，不将项目原创来源标为CC0。
- World发布门禁仅按根/ART真实协议修正 actual_native_canvas 为含96px overscan的原生viewport（3456×2432），cropped_native_canvas独立为3072×2048；raw_viewport/camera/crop/repeat/112边等其余严格校验不变。WORLD source/manifest pins仍PENDING，057道路穿实体forecast由ART窄修，不能发布完整64。
- 两执行源冻结SHA：City `00FC9A8B53CB97CF6E853CB612D960857B09DA11F8DD41C51FC87B323574EEDE`；world gate `E717E46B8F13641E9854714F1F150DBB1A5994D730A395E5D82CF3BED6DBD82C`。055实际publisher FAIL与7F5A/499597旧源码证据保留；本次只SOURCE_READY，未启动引擎/发布candidate/正式激活，等待根新进程重跑，不继承旧通过数。

## 2026-10-04 · 055候选发布来源字段拒绝（窄修SOURCE_READY，仍有登记缺口）

- 根实际055 publisher拒绝south_gate且未写candidate。仅City合同 `_reuse_error` 在provenance_document缺省时选择唯一固定 `ROOT/source/reused_city_prop_provenance.json`，显式null/empty/wrong仍拒；catalog/currentSHA/status/source_bytes_modified/source-copy-runtime三字节相等及registry精确身份完全保留。合同新SHA `499597CD9295A37EAFADC4F1C95A3031A844B06F7C315636414C5D5D6F573A31`，7F5A旧执行快照不可覆盖。
- 只读实际发现当前registry BFC97842…9F1F7与041catalog相等，但仅tablet/chest两条，缺south_gate/inn/shop原v2→common复制记录；缺省字段修复并不能让缺记录的建筑通过。已交根/ART核对，不改冻结ART或放宽身份门禁；未执行引擎或publisher。WORLD actual_native_canvas协议另由根/ART明确应指真实overscan原生viewport、cropped_native_canvas独立，当前旧gate仍冻结未越权改写。

## 2026-10-04 · 041四城候选来源绑定（未发布、未实机验收）

- 根逐图041原始review后只授权四City来源可进入实际Field候选验收，不是最终视觉批准。四manifest当前实际SHA与授权值逐一相等：gate F191FF7D…104C5／yamen630C98DB…13A24／market87ADB287…43D37／docksBD6D7B5C…31EDB，已仅替换 `luoyang_layered_v3_contract.gd` pin及候选性质注释；新系统合同SHA `7F5A7AF34806A0F0B234F433D7B52D37366113A82E35B79DD8FF1CE825B8044B`。
- Joint mandatory加入QA新 `joint_v15_world_artifact_semantics_probe.gd`，joint gate新SHA `17ACAC8BFC031225FD07AB8AA2D5B4EAB467E679EBF5E56E52086AB6CDF2A192`。郊外builder实际 literal preload及source graph登记新REEDS，同既有snapshot/catalog→builder→literal递归绑定；旧未重捕获的marsh graph不得假借新builder信用，实际SHA不一致仍闭锁。
- WORLD源/manifest pin继续PENDING（root retry4尚未GPU）；world gate FF95365C／publisherBD23AB57均未变。六正式目标/ADOPTION逐SHA仍原值，系统未启动引擎、未调用publisher/activation、不写用户档；本次仅SOURCE_READY待根串行compile/publish/QA，不继承之前通过数字。

## 2026-10-04 · 完整64发布协议闭合（SOURCE_READY，仍未执行）

- 根仅释放 world publication gate/publisher 与 joint acceptance 三文件；其余七运行源码冻结SHA未变，六正式目标（含ADOPTION）逐SHA仍原值。锁定真实执行 builder `build_world_map_v15_complete_v5_full_draft.gd`，不冒称旧局部builder；实际Shader另保存 `art/maps/world_map_v15_complete_v5/capture/terrain_shader.gdshader` 并绑定当前bytes，不用surface脚本SHA代替。
- 每chunk/reference精确区别逻辑裁切、裁切SSAA2、原始overscan viewport：overscan96px、crop[96,96,w,h]；同source PPM102.4／45度相机位置/基底和global RF1537×1025、局部window RES及独立global RES分别绑定。每四类裁切PNG及其真实repeat、visual原始SSAA2与binary原始MSAA0 PNG尺寸/SHA严格；新112门禁重新枚举全部邻接，source/capture分类与实际脚点见证一致，独立32px条带四RGBA与两块原图拼接逐字节一致，不将blocked边界涂白。
- Publisher需显式 `--publish-candidate`，不存在自动正式写。Joint mandatory另绑定新city migration/interaction-negative、world object-input/saved-context QA根；尚缺文件时snapshot直接拒绝。三新SHA：gate `FF95365C27C093874EBF0611540C8954C9332379E6B19426D77984EA7FC1BA70`／publisher `BD23AB57F6188D392E8D2D99A633882429759BFC269F6ED5B4206A7F56AA94E4`／joint `FD2EC71EB60F72A2C33EF96F0648DD0B09FF1AADDCDCD33339F7E84B4107DCD3`。根未报告本次新解析/合成结果，系统未开引擎。
- 当前world source_contract/manifest/landmark_semantics及三retry1郊外合同尚缺，四City final SHA仍PENDING；真实full64 draft只到未获运行批准的matrix/assembly源码阶段。QA main/world仍source_complete=false、WIP schema，不能只改布尔取FULL信用；需各真实子phase闭合并聚合精确 JOINT_FULL_ACTUAL_FIELD_INPUT、两实际headless/GPU外部OS及日志SHA，再root图审+技术审批，固定六字节journal激活后仍须fresh正式FULL。全部尚NOT_RUN／NOT_APPROVED，不继承旧通过数字。

## 2026-10-04 · City3水船最小遮挡与版本门禁（源码冻结，未运行）

- 根授权新增 `city/luoyang_v3_modular_overlap.gd`：仅 validated 码头 `moored_canal_boat` 的 `water_decoration` 注册精确 ordinary 同8px band脚底排序，不入 ghost alpha 的 `_props`。其余高物不得声明 ghost=false；地层仍负z非排序。船无实体阻挡、无walking support、无interaction；这不证明岸侧不相交，正式联合gate另要求 actual 连续全drawrect域分离证据、全40 Player武器/方向/state图及原3 gated NPC全部来源/尺度/域/四岸侧真实输入负例。空粗扫、complete单布尔或gap<=0都不可批准。
- City现核 existing-original 原PNG/common副本/region运行图三个实际SHA相同、真实来源尺寸、精确 `reused_city_prop_provenance.json` registry绑定；不得将项目原资源冒称CC0，原图未改。Router世界版本先按确切数值12/13/14/15校验，JSON14.0合法，fraction/string/bool/unknown/nonfinite拒绝；纯preparse/prepare/restore负例新增，不改SaveManager/schema。QA实际NPC只axis/sin巡逻；当前art无patrol_path_px，合同可选路径键没有Field消费者，不能声称沿新路径已运行。
- 新郊外双旗固定ROOT已改 `art/maps/world_map_v15_outskirts_complete_v5_retry1/`，旧020完整目录仍失败证据，不继承采用；默认旧ROOT/v4原行为不变。四City manifest SHA仍PENDING，正式world 838380FD、ADOPTION203C9F08未动。本角色未启动任何Godot/GPU/正式发布或用户存档。
- 8源SOURCE_READY等待root解析/synthetic：Router F3EAD745 / City E76569DA / overlap70072F29 / Field0319FCD5 / Outskirts0A6EBB10 / jointgateDE072835 / sourcecheckerD380AFD4 / purechecker897E6915。实际Field、完整域证明和联合正式激活均NOT_RUN，不能继承旧011/012或v2数字为本修补信用。

## 2026-10-04 · 联合完整v15／洛阳v3正式能力源码（美术仍PENDING，未激活）

- 新完整世界维持坐标VERSION15、12288×8192／64chunks／16原门户／9核心地标，独立 `art/maps/world_map_v15_complete_v5/`；四洛阳 canonical IDs 维持原15NPC、11布局交互、12门户及所有原action／flag／剧情／BGM／商店，只换独立3072×2048 native空间。三郊外仅双显式flags `--outskirts-candidate-preview --outskirts-complete-v5` 选择固定新ROOT，默认旧ROOT／v4双旗不变；正式采用以后只能由独立ADOPTION绑定新ROOT和三实际合同SHA。当前正式六文件和玩家档均未写。
- `luoyang_layered_v3_contract.gd` 四manifest SHA仍PENDING，四区首轮捕获即使OS0也未获总视觉批准（摊位压屋顶、越canvas、同质铺地、码头水/护岸缺细节），不能填失败图SHA或继承v2机制信用。合同保留实际capture/source/catalog SHA、6144×4096视觉与3072×2048权威相机、385×257 RF、raw repeat、导入walk实际字节一致；普通34×24完整875样本和WORLD实心polygon同源。独立外部layout/typed数组先别名检查再就地clear，不用set[]残留旧碰撞。地层overlay固定负z、非solid、无Y-sort/ghost，其余高物ordinary脚底Y/current alpha。
- 原四区旧scene+layout八份字节副本保留于 `data/maps/luoyang_v3_legacy/`。legacy_scene显式SHA读备份layout并赋独立scene clone，不依赖切后canonical旧外部路径。四旧区均feet=true，不套南坊47.628偏移。existing navigation payload新增local_layout_versions（1旧/3新），schema14不改；未知/非整数/降级拒绝。旧自由点先同区语义插值、196px内实际路段投影，再显式同旧门户安全锚fallback；已3坐标不重复映射、不全图找白点。
- Router新city/v15门户为pure prepare→pack/安全落点通过→commit：失败不记pairedreturn／localversion／active/current；public resolve在新范围只查询，旧91契约保留。world_map action与返回同走新transaction；go_field_smart返回dispatch成功bool、缺v15候选/忙Loading/缺控制器拒绝；restore仅在私有copy补callerfallback后预解析。SaveManager／schema／原Dialog奖励代码不改。
- 新 `publish_luoyang_layered_v3.gd` 只写四独立candidate/layout，全部准备通过才写；新 `joint_world_city_v15_acceptance.gd` 精确绑定actual8art图谱、候选、原gameplay叶（含equipment）、Audio/Battle/result/Shop/Bounty/M/Inventory/GameState/Quest代码及真实新QA/reused helper依赖。仅独立root视觉批准+两实际headless/GPU完整normal-gameplay报告（JOINT_FULL_ACTUAL_FIELD_INPUT）能激活，FAST/unit/limited/source WIP不算。`activate_joint_world_city_v15.gd`需双显式确认参数，写前再次复核全SHA，保留固定六目标原字节/journal；任一失败整组恢复，显式rollback拒覆盖后来用户改字节。不自动批准/不运行/不切正式。
- 主控实际011 source/publication checker：24 checks/0失败、OS0/stderr空；012 pure city candidate：34 checks/0失败、OS0，Unknown/PENDING预期拒绝及ObjectDB退出warning保留。源码与15玩家save路径SHA/size/ticks零变化，证据 `game/build/joint_world_luoyang_20261003_qa/root_publication_source_20261004_011/`、`root_city_pure_atomic_20261004_012/`。这仅解析／合成／失败路径，真实成功Field/physics/交互/战斗/旧档/正式切换仍NOT_RUN。运行SHA：Router `8C073558691BF49E68E2144B41573CF26E2443773010B7F0547ABD772A162BF3`，City `137B8D903B420E02BBED7D135519F38AD9977FABDA5773AF6FD9D2C29642963C`，joint gate `F1B937225BD3F5A7A3BA6F57679D7D6D437501C016497803C925E849BE8BBDD0`。所有引擎均root串行，系统未自启。

## 2026-10-03 · 洛阳南门—南市分层机制试样（源码候选，未正式接入）

- 新独立 `luoyang_layered_interior_v1_contract.gd` / `_field.gd` / `run_luoyang_layered_interior_v1.gd` 仅消费冻结 `art/maps/luoyang_modular_v1/art_contract.json`（SHA `2A1BE0F8…9F784FD`）；3072×2048 native floor/nav、10独立实体与实际 source/capture/RF/mesh 资产全 SHA 绑定，导入 walk 解码与当前 PNG 字节相等门禁。root已读建筑方向，但灰砖空场及 toy 榜亭/灯柱仍视觉 FAIL，不是正式美术采用。
- 普通角色 `.91`、34×24 RectangleShape2D 与 ground-anchor=0，不调用世界旅行5px碰撞。dev subclass自行将建筑 WORLD `solid_polygons_px` 建成真实 CollisionPolygon2D，两翼门柱围出拱洞、不叠整栋大矩形；native props 矩形同源。移动/出生按 `round_world_pixel`、零 margin、整个34×24 body逐像素导航与实体 polygon 相交拒绝，而非用世界17点鞋胶囊替代普通 body。ordinary helper 255/8px/current-frame alpha 局部 ghost；父 NPC spawn 已注册 helper，不重复登记。
- 原4洛阳资源仅只读逐 STORAGE 快照；候选显式复制外部 layout 和所有数组，清旧烘焙 fade/occluders，仅候选替换背景/navigation。保留3原NPC身份/scale：门吏1700,1780、巡捕1070,1170、掌柜2370,1080；移离必测路线，实际 PNG 全35×25含边样本各0阻挡只是 CPU 预测，不能称真实移动通过。
- 全部 NPC/dialog/shop/bounty/原portal身份仅 DRY_RUN 日志（executed=false），榜亭保留原旗标门禁；客栈没有原正式动作，只 `lab:inspect_inn` 明确候选检查 token。门前1536,1660→门内1536,1440→精确源站位只是同画布 checkpoint 往返，不调用原府衙/世界 Router、不发剧情事件或奖励。HUD/原 BaseButton 全部隐藏禁用，GM仅独立进程临时禁用并恢复；C/K/J/M/F5/F12等屏蔽。
- 父 setup 实际 transient 写 Router `_current_field_spawn`/`_field_payload` 后，dev仅精确恢复这两项独立副本；不能用 public restore_navigation_state 回滚，因为正式v14分支会把默认12升级14。移动不写 Router，其他状态不恢复掩盖故障。runner全量比较 raw Router payload/版本/返回、旗标/角色/队伍/金币/历练/声望/Inventory/Quest/Bounty及5槽和备份 SHA/mtime，不写玩家存档。
- 启动必须 `--script res://scripts/dev/run_luoyang_layered_interior_v1.gd -- --luoyang-layered-preview`；另加 `--luoyang-layered-source-check` 只审资产/materialization，不起 Field。公开 runner `start_preview`/`field`/`get_probe_state`，Field `get_lab_contract`/`get_lab_scene`/`get_preview_return_state`/`observed_actions` 给独立 QA。runner在10帧后必须核真实 production-script Player/普通34×24shape与anchor0/.91/3准确NPC及纹理/10准确prop及纹理，缺任项false拒绝，不能只凭ready打印。初期冻结 `49C5AD26`/`6F4FEE3D`/`94365E94` 失败来源保留；当前修复候选 contract `77E2FF23…6841ED5`、Field `90B5AD1C…D1FF434`、runner `0CE8D2BC…59E20557`，不继承初期失败前后的检查为新版本通过。
- root首 source-check 实际 OS0 但 stderr 有旧归档 Player global-class 重名，**不记通过**。按root批准只给 `build/outskirts_links_actual_retry2_20261003/` 加 `.gdignore`（SHA `01BA4719…ACA546B`），保留全部旧证据，不删缓存/改生产 Player。strict重扫、最终 sourcecheck、真实 Field 输入/Physics/返回/局部 ghost/GPU均待主控与QA串行；旧场景/正式v14/adoption/存档未切换，不能继承既有地图或郊外测试为本试样通过。
- root后续6236/71624两次stderr仍有归档 `Player hides` ERROR，71624缺真实Player却曾打印ready，明确不算运行通过。按新授权仅给 `build/outskirts_links_actual_retry1_20261003/` 和 `build/outskirts_field_first_20261003/` 各加同SHA `.gdignore`，原证据全部保留。只读确认 `world_map_v14_third_capture_second_qa_failed/.gdignore` 已存在；`wechat_pack_projects` 本层无ignore，但common及chapter1_start/chapter1_late/chapter2/chapter3均有独立project.godot边界，本轮未广域修改。新runtime实体guard尚待主控实际重跑。
- root真实只读 Physics 因果诊断 OS0（`physics_cause_1791030317_1538/physics_cause.json`，JSON引擎PID1928）4个snapshot发现残留原南门左右guard_post：旧norm .190/.515及size .180/.210乘新3072×2048，精确得583.68/1054.72、552.96/430.08；右同样精确2503.68/1054.72、506.88/430.08。它们堵新版loop/inn/shop/NPC站位，而原生LabPhysical_shop在上方阻挡应保留。父Field没有blocker fallback；原dev清理动态`layout.set(name, [])`无类型数组，未校验typed export实际清空，sourcecheck仅查隔离/原资源未改而漏候选残留，不能把这次路线失败归咎鞋尺度/美术。
- 按root窄批，只有dev改成显式9个Scene/13个Layout Array先验证copy非原source alias，再就地`.clear()`保留typed element type并复查getter count0；保存before/typed_builtin/after/source_alias诊断。materialization在make_scene、sourcecheck、Field ready及runtime guard四层拒遗留blockers/fades/occluders/regions/interactions/tiles等；实际CollisionLayer仅允许MapBounds（4Rectangle子shape）及10LabPhysical_id，ActorLayer3正常NPC自身foot StaticBody/Rectangle另核，不改任何碰撞尺度/坐标/导航PNG。原失败证据、正式Gate B967C347/layout1D5CCA7D、艺术合同2A1BE0F8均保留；新候选源码已冻结交root串行retry，本角色未运行引擎，新结果尚待。

## 2026-10-03 · v15 扩大地图系统候选（未发布、未切正式）

- 真实headless `diagnose_world_v15_visible_portal.gd`复现v14洛阳门口Space：安全门前(2586,1433)实际Player.interacted=1/exit=0，旧portal(2586,1515.639)interacted=1/exit=1；实际87.55×55.30热区不包含门口。retry2实际OS0但Dummy texture null ERROR保留，不能作为无错误运行通过；首解析错误与physics-only等待失败也保留。诊断只截获出口、不调用Router旅行、不触发剧情/奖励/存档。
- 新`world_map_v15_contract.gd`定义12288×8192/64×1536×1024，完整10×6px椭圆17点。导航global rounded pixel后拆tile，12tile LRU保RGB+alpha，Field在v15不另load全部nav；物件安全grow沿用v14的18.432×12.288实际像素，不因归一化扩大至49×32。当前15坐标只在196px内修复；旧12/13/14插值无法局部修复时，明确回退最近旧门户ID对应的新safe门口，记录迁移原因，不任取白像素；未知source version拒绝。
- v15独立`world_v15_exit_zone.gd`读取精确`interaction_polygon_px`物理Area，同时要求实际脚中心位于polygon且full17安全；`_activate()`同样守卫，避免旧native Area鼠标绕过`try_interact()`。旧ExitZone不变。root批准仅v15对象`solid_polygons_px:Array[PackedVector2Array]`为世界投影逻辑像素，contract17点contains与Field CollisionPolygon2D（world point-object pos转local）同源，声明poly时不再叠大rect；无hole填充，门洞由多个实心poly围出。
- 新publisher仅发布候选；独立read-only `world_map_v15_publication_gate.gd`绑定当前asset_sha256目录、executed source_graph及literal依赖、capture_graph各role、64exactrect/256PNG与RF/mesh/shader/actualcamera、16actual-source测量及未裁alpha复制、8actualcore两两3072px、route和root独立逐图review SHA。`passage_path_px`中心线≤4px采样走完整17点，不以只验证箭头点冒充门口通过。owner不能自动APPROVED、publisher拒绝无独立root图审；source/art仍WIP，因此未执行发布、未切正式。最终source/manifest字段集需与art产物联合验证。
- `v15_modular_overlap.gd`继承冻结v14 alpha算法，只重写Actor登记/深度分桶上限1024，8px粒度、实际同bandY序和局部ghost保留；v15 PortalLayer1100，普通255/v14 512保留。共享Field/Router仅按v15身份分派，新M预览仍读active stream，无需改UI源码。
- Router v15 pure prepare/commit与SaveManager preflight在任何GameState/Inventory/Quest/slot应用前解析navigation；unknown/missingcandidate/unsafe当前15拒绝、不部分load。15存档对14/13/12正式回退中文提示拒降级；SaveManager schema仍14。v15候选尚未生成，真实旧档/门户往返/Field/GPU均待QA。
- v6只读compile10脚本实际OS0且没有错误/退出warning。后续root串行窗口v7日志`game/build/world_v15_system_compile_v7.log`检查11脚本（含strictgate及polygon）实际OS0；真实15→14只读preflight rejected=true/Router不变、无存档文件读写。v7 stderr预期中文拒降级warning及ObjectDB退出warning保留，不能称clean stderr；该checkSHA AF10E295…F51B225。v7后继续补gate对象transform与source-alpha绑定字段，待下一串行compiler及实际art整合；从未以源码编译冒充地图/输入/视觉验收。旧v14contract/helper/publisher/builders/art/catalog未编辑。

## 2026-10-02 · v14 九区正式接入准备（尚未激活）

- 用户授权九区新版大地图正式接入；本角色由 review 切到 system，实现生产 `world_map_v14_contract.gd` / `publish_world_map_v14.gd`，不继承 lab Field、不停剧情/BGM/遭遇/奖励。候选 ID `world_map_jianghu_v14`，正式仍 `world_map_jianghu`；布局 `data/maps/world_map_jianghu_layout_v14.tres` 与 stream `data/background_sets/world_map_jianghu_v14_streamed.tres` 由 art `art/maps/world_map_v14/source_contract.json` 转换，4608×3072 与九个1536×1024 visual chunk，运行不读取build。
- publisher 完成资产状态才发布候选，先原字节保留 `data/maps/world_map_jianghu_legacy_v12_scene.tres`，SHA必须 `09fa89449b1792063e66ad488aa2f60671aa00da2193e5c68acb861df14d71d5`（scene_id不改）。最终 `--activate` 需要独立 technical+visual 认可以及 source/manifest/生产art目录递归png/json/rf/res/gdshader（去重、不含import/log）、候选tres/legacy、12系统脚本及art builder的精确SHA清单；本阶段未写批准文件、未激活正式resource。
- `navigation.world_map_version` 独立于 SaveManager schema14。旧缺字段默认12，v13 staging默认13，显式v14候选默认14避免重迁移；室内存档也记录world-side return版本。world侧坐标近旧门户64px内按同ID映射；自由点由最近4地理锚点IDW位移后完整脚底安全修复，不无条件传最近门户。室内侧返回值不改，只重写key。正式切换后普通菜单load自动迁移，candidate QA显式第三参 `WORLD_MAP_V14_SCENE`。
- 所有正式战斗入口统一记录 `return_world_map_version`，胜/败/切磋结果保留，实际撤离和结果UI经 `return_from_battle_payload` 调普通Field回程，不改奖励/旗标。`go_field_smart` 第四参spawn_version可明确坐标版本，已有三参不变。16portal ID/target_scene/target_pos与正式v12逐项比较，不删除入场对白门禁。
- Field新v14完整脚底安全检查与原Field同round/alpha/maxRGB规则；nav优先读取导入Texture2D.get_image，原PNG仅publisher未导入兜底；blocker矩形按layout缓存。新v14深度上限512，只在本Field给Player/NPC meta `depth_band_max`，其余场景默认255，8px band规则保留。M地图按active world读独立带地标overview；BackgroundChunkStreamer只绘chunks，不读取preview，所以Field不双绘地标。
- 新v14独立物件用 `v14_modular_overlap.gd`，当前主角帧有效alpha像素中心经真实transform对独立prop当前帧alpha采样，多物件按 `1-product(1-alpha)` 合并；只有实体真实foot在角色后且effectiveZ覆盖时才触发。透明矩形/人物在前/同8px band角色实际在前不触发，不改角色本体透明度。Field只注册sort_by_feet实体，不注册底图/地影/甲板。Texture Image与演员逐帧alpha点缓存，当前变换或帧变化才重算；无前景候选跳过actor像素循环。
- Player内嵌新actor_frame局部mask shader，只显出被实体遮挡的角色部分；ghost绝对Z至少450且高于实际命中物件，HUD/SystemUI仍独立CanvasLayer在上。旧同画布门楼mask shader保留原分支；ordinary切图helper清空、旧ghost默认450。Field QA接口 `get_v14_modular_overlap_debug()` 暴露space/frame_rect/actor_rect/flip/mask_image/mask_texture/actualZ/prop_hits，供独立重建current-frame alpha检查。保留8px深度离散限制；未声称真实shader或旧门楼回归已通过。
- 源码编译checker `check_world_map_v14_system.gd` 动态load 12 个实际脚本，真实headless exit0；独立直接checkautoload因未注册GameState产生预期不适用错误，不能当源码运行失败或运行通过。本阶段尚无新art完成产物、候选发布、16入口/旧档/UI/GPU验证；必须等producer串行导入/发布后QA。
- 2026-10-02 art第三技术capture/root strictimport exit0后，首publisher因Godot JSON数字数组float与字面int数组严格不等而exit1。真实`--diagnose-source`证明schema type3/14.0，world_size type28/[4608.0,3072.0]，old_array_equality=false，其余完成状态正确。边界改为仅INT/FLOAT、finite、逐标量精确数值校验（不容许字符串、截断或删尺寸门禁）。真实重跑publisher exit0 `WORLD_V14_CANDIDATE_PUBLISHED_NOT_ACTIVATED`，输出生产candidate/layout/stream；默认出生和16门户full-foot全部门禁通过。canonical及legacy字节SHA仍原09fa…；未activate、未写批准文件，正式Field/UI/旧档/战斗/GPU仍待独立QA。publisher是编辑器资产发布工具，raw Image读图有export警告，runtime contract已优先读导入Texture。
- 首candidate实际QA发现StreamedBackgroundSet被SceneScript内嵌，因为publisher仅给layout而未给stream最终resource_path。只补 `stream.take_over_path(STREAM_PATH)` 保独立流资源真正被引用，不在QA活跃时重发布tres，等producer准许。两低草depth测试double scalar与实际Vector2 float32在8px边界不同（2487.999999999999→2488、2415.999999999999→2416），已交QA精确按世界global Vector2变换及真实entity脚底核定，不放宽±1或改素材；当前首轮失败需保留。
- 首QA退出、producer明确批准后，publisher真实headless再发布exit0。新增发布后CACHE_MODE_IGNORE重新读取SceneScript并failclosed验证layout/stream两者外部路径，实际打印layout=`res://data/maps/world_map_jianghu_layout_v14.tres`、stream=`res://data/background_sets/world_map_jianghu_v14_streamed.tres`；成功日志 `game/build/world_map_v14_publish_external_stream.log`。formal/legacy SHA仍09fa…，未activation，旧当前美术仅供继续结构验证，不称路线/视觉全PASS。
- 二轮完整QA 21592/71失败归档后，producer批准系统小修：v14 Field移动global→worldlocal/_world_size不clamp，完整17点safe_foot与出生/旧档修复同源；旧91图center行为不变。contract预缓存ellipse偏移，17nav后对76cached blocker矩形做实际样本min/max包络inclusive宽筛（equal不可跳过），仅候选做17has_point。独立headless优化对比旧完整合同59285点/0差，包括网格/边界/ellipse切触；源码12compile exit0，不等于Field实机通过。只读诊断`diagnose_world_map_v14_safe_foot.gd`/日志`build/world_map_v14_safe_foot_equivalence.log`。
- 同批activation额外要求manifest versionworld_v14/statusPRODUCTION_APPROVED及typedBOOL visual_approved&&production_approved为true；外部approval+exactassetSHA仍必需，不编辑manifest/不activate。pointer interaction_only Area缺highlight_node元数据改has_meta条件读，避免Godot null默认仍报missing；原hit优先语义保持。鼠标所有入口/退出超时原因尚待QA独立真实event诊断，不把这一missingmeta修复当全部鼠标问题解决。本批未重publish候选/art、不render/GPU。
- 后续QA真实pointer诊断发现首测试parse_input_event传逻辑坐标，但headless64×64窗口相对1920×1080有root stretch，导致真实_input倍放大；QA用logical→physical真实事件重查，无需改Field指针优先级。原timeout记录保留，不以Router直接切图冒充输入成功。
- v14独立native物件近邻噪声运行原因：project默认texture_filter0=Nearest，SceneObject未设置而背景显式Linear，Camera1.25和非整数render_size放大产生棋盘/阶梯。仅v14SceneObject明确TEXTURE_FILTER_LINEAR；Player只让ghost复制actor.texture_filter，不改actor/global/91旧图。12compile0，无GPU图质结论。已报LINEAR边缘alpha与helper目前nearest source alpha的1texel插值差异，待producer确认精确bilinear同步；不放宽QA。triangle-projected source portal/object/route/spawn均直接消费art runtime字段，SIZE4608×3072是画布约束，不重新套旧flat脚点或生成高度。
- producer批准后仅v14 helper对明确LINEAR prop采样精确双线性alpha：当前帧与flip映射source坐标 `frame_origin+uv*frame_size-.5`，四texel interpolation，外texture边界clamp；保留Sprite默认atlas frame边邻texel语义，不额外裁帧，之后乘modulate/self_modulate。actor当前帧nearest不改，signature包含texture_filter避免变更陈旧。轻CPU源诊断`diagnose_world_map_v14_linear_alpha.gd`真实19/0，含texel中心/半像素/outer clamp/atlas frame边/旋转缩放/flip/modulate/invalidregion/nearest对照；日志`build/world_map_v14_linear_alpha_source.log`，12compile0。QA已获明确采样语义独立重构；未GPU/import/repub，不声明滤波画质或GPU阴影剪影验收通过。
- 密集成熟树性能观测经producer批准，只给v14helper debug新增 `candidate_count=candidates.size()`（初始化/坏actor帧0），算法不改，直接headless helper check-only exit0。QA240帧开销测试直接读这个字段，不每帧独立遍历120物件以免把测试开销算运行层；实际站位须另独立核对候选数/alpha，技术观测字段不是自证性能已合格。无GPU/import/repub。


## 2026-10-01 · 分层路线 v7 隔离接驳合同

- `world_native_pair_landmark_contract_v7.gd` 是桥面白区、道路停点、河流中心与城池／渡口脚点的单源；renderer 读取同一合同。独立城池禁走整个围墙占地，渡亭和船体单独阻挡；桥整图放角色下方，前栏同画布 alpha 独立按脚底 Y 排序，不把整座桥盖到人物前面。
- 新曲线绕渡亭南侧，v6 挡路灌木只在 v7 合同内将视觉、阻挡和深度脚点一起移动到 `(2280,810)`；新河流上的 `grove_middle_b` 同样成对移到陆侧 `(1860,810)`。13个继承物件完整collision底面每4px加边界采样陆地蒙版，不允许任何足迹浮河或海。不可改 v6 已验收源数据或删除道路脚底失败断言。甲板白区为 `Rect2(1418,348,484,35)`，截图站位前376／后355保持完整脚底净空，不宣称384可走或前栏遮腿已视觉验收。
- 开发 CLI 用延迟加载 Field 子类，避免 SceneTree 预加载共享控制器先于 autoload；源图与目的地 SceneScript 仅内存副本切换，屏蔽剧情／奖励、保存菜单与 GM，不调用正式旅行。退出恢复 Router 导航；PlatformBridge 对未登记正式场景拒绝 checkpoint。五个玩家存档与备份 SHA 和剧情 flags 前后不变。
- 专项 headless1055／0、OpenGL1062／0，含900个每4px连续主路全脚底探针、13物件底面陆地正例、海河／桥栏／两处陡坡负例、真实双向过桥、真实 Space／pointer入口与同源锚点返回。原生输入测试需固定独立窗口1920×1080并填写global_position，避免headless64px物理窗口拉伸事件；Space要等待实际Player.interacted后断言。
- 七张实机图在 `game/build/world_native_pair_landmark_v7_*.png`；退出仍有GLES纹理RID／ObjectDB告警。技术通过不等于地形视觉通过，正式v12／v13 staging不切，不宣称所有场景层级已修复。

## 2026-10-01 · 成人 NPC 素材身高与同曲续播

- 只有已审查的 `npc_zhuwei_gate_guard_*`、`npc_zhuwei_inn_waiter_*`、`npc_escort_guard_*` 成人家族按第一帧可见 alpha 高度统一到140px素材基准，再乘原场景比例；不对所有PNG、儿童或坐姿泛化。所有idle/walk/conversation/Field override从原比例重算。透明纹理bounds按Texture实例缓存；脚点和原物理碰撞保持，名字按有效头顶。
- `AudioManager.play_bgm`判同曲只用规范路径／有效AudioStream身份，不比较scene context；同曲不stop/play/seek、不发bgm_changed。context只在真正换曲时选择首次入句；同曲可取消未完成的显式stop淡出。平台paused时playing可为false，必须识别stream_paused并原位恢复。
- 专项205/0，审查28条共享家族NPC；真实SceneRouter林西中心→南坊同曲playhead17.099→18.213秒、播放器不换、曲目事件0。五个真实用户槽与备份前后SHA完全相同，无存档写入；strict import exit0。实机南坊／金陵截图和命令详见`docs/npc-scale-bgm-continuity-20261001.md`。
- 本机WASAPI打不开设备，自动回退Dummy；续播验证是播放位置／实例身份证据，不能宣称音乐听感或武侠风格通过。未换曲目、未导出Web／微信；OpenGL既有RID／ObjectDB退出告警仍在。

_Last updated: 2026-10-01_

## 2026-09-27 · 通缉榜的正式入口是实体榜牌

- 四个城市ID`luoyang/bianzhou/xiangzhou/jinling`各自必须且只能有一个正式`bounty_board:<city>`布局交互；交互记录`visual_baked`、`baked_feature`、`activation=interact`和`clickable=true`。
- `clickable`仅让玩家处于Area2D交互范围时可点击实体榜牌，执行层仍复核角色重叠，不允许远距离隔空打开。
- 汴州、襄州、金陵向导对白只提供地点提示，不再携带`bounty_board:`动作；榜单状态和揭榜结算继续由`BountyManager`单一管理。


## 2026-09-27 · 门户锚点、脚底净空与天气作用域

- `FieldWalkableController`绑定出口信号时同时绑定`source_portal_spawn`；`SceneRouter.go_field_from_portal`的返回锚点禁止再使用角色触发瞬间位置。
- `_resolve_player_spawn`对声明点和覆盖点都执行完整脚底椭圆净空检查，失败后只在有限局部环内寻找最近安全点。它同时保护新入口和带错误落点的旧存档。
- `WeatherManager`保存`scope_scene_ids`；非clear天气默认只作用于启用它的当前场景。雨shader通过负Y UV偏移形成向下屏幕运动。
- 烘焙物件用blocker与`depth_mode=y_sort`成对登记；可穿门楼用同画布alpha蒙版与狭窄脚底fade region，禁止宽泛`actor_fade_zones`覆盖空地。

_Last updated: 2026-09-27_

## 2026-09-14 · 城门使用同画布蒙版裁剪，而非整人淡化

- `DynamicOccluder2D.alpha_mask_texture_path`是门楼实体像素的唯一遮挡真值；前景shader和玩家半透明剪影必须读取同一张全画布alpha蒙版，禁止分别维护两个估算区域。
- 渲染顺序为“原角色 → 不透明前景 → 蒙版裁剪后的半透明角色剪影”。门洞alpha为0，因此角色通过空洞时保持正常；只有角色像素与横梁/屋檐等实体alpha重叠时才显出淡影。导航仍由脚底通道和门柱blocker独立负责。
- 旧`actor_fade_zones`只保留给无前景资源的兼容场景，不能作为新门楼方案。世界地图目的地标签采用逆镜头缩放，并配合MSDF和描边，确保最终屏幕像素1:1。

_Last updated: 2026-09-14_

## 2026-09-13 · 声望、通缉状态与门派申请合同

- `BountyManager`是榜文可接/追捕中/已归案、随机藏身点、战败迁移与归案结算的单一状态源；Field只按当前状态动态生成目标NPC。
- `GameState.reputation`默认0，通过`EventBus.reputation_changed`刷新HUD/角色界面；十档称号不参与战斗公式。五派`select_faction`先校验声望10和建设材料，只标记申请并进入原有考校，`joined_faction=true`后才授门派根基。
- SaveManager v14保存`reputation`与`bounties`；旧档缺字段回退0/空。`SceneRouter`新增`bounty_board:`和`bounty_battle:`动作，胜败分别结算或迁移。

## 2026-09-13 · 门派分区、门框淡化与原生尺寸合同

- 华山/武当六张场景使用3072×2048原生布局和0.70角色比例，通过门户组成双向三段路线；大地图只负责进入山门，不直达门派深处。
- `actor_fade_zones`按角色脚底归一化位置驱动`Player.set_baked_map_overlap`，适用于背景中已烘焙的城门/牌楼；门柱必须另设blocker，避免“淡化”被误当成无碰撞。
- 新门框测试同时验证门洞点落在淡化区、透明度不高于0.45、门户脚底可达和门柱负例阻挡。

## 2026-09-13 · 世界入口支持常驻目的地标签

- `ExitZone`新增`always_show_destination`与`destination_label_side`；世界地图portal通过`show_destination_label`开启，右侧地标可把文字排到箭头左边。
- 世界地图v10继续使用归一化门户坐标与2304×1536逻辑尺寸，桌面4608分块只提高纹理精度，不改变导航坐标。
- 世界镜头改为1.25，旅行角色比例为0.58；双向返回仍由`SceneRouter`按门户ID解析，旧存档落点继续走安全点修复。

## 2026-09-13 · 多屏场景移动与开放入口规则

- Web/微信不应在玩家移动期间同步加载背景分块；进入场景时一次预载，桌面保留线程预取。角色自身已有插值时，相机不再叠加平滑，否则会产生拖滞和卡顿感。
- 大地图公开地标默认允许进入。剧情门槛应放在对白、事件与奖励层；危险地图用敌人强度和明确“高危”提示限制，不用无解释的入口锁。
- 城门前景使用`actor_fade_zones`按脚底位置淡化主角，碰撞布局同时保留贯通甬道；视觉遮挡与导航必须由同一入口合同验收。
- I键仍按2026-09-12最新产品决策在两套Field中被消费但不打开背包；下方2026-09-11“仅隐藏按钮、保留I键”记录已被后续决策取代。

## 2026-09-11 · 背包快捷入口暂时隐藏

- 临时产品规则：仅隐藏 Field 主HUD/旧HUD 的背包按钮及提示文案中的“I 背包”；I键仍启用，可以正常打开、关闭背包。不要把隐藏入口误实现为禁用快捷键或删除背包功能。
- `field_primary_hud.tscn/BtnInventory`、`field.tscn/HUD/InventoryBtn`、`field_walkable.tscn/HUD/InventoryBtn` 使用 `visible=false`。节点与信号仍保留；右侧菜单滑动仅修改按钮位置，展开、收起、系统面板恢复均不会显示该按钮。
- 两Field的 `KEY_I -> _toggle_inventory_panel()`、对话模态守卫、背包移动锁保持不变；其他按键保持现状，角色快捷键为C，不新增E绑定。

## 2026-09-10 · 本批系统增量

- `DialogScript`新增required_story_flag/required_completed_quest、blocked_story_flag与required_free_inventory_slots。执行入口play/play_at统一检查；受阻仍正常播放并结束安全对白，避免Field输入挂起。
- Field两套入口在写once flag前检查对白条件，经典Field补齐on_enter_require_flag。竹尾新增master_training_done且q_ch1_main_training已完成门槛；一般传闻不跟主线硬锁。
- 新地图actor_positions_are_feet显式选择Player/NPC脚底坐标；world模式用5px脚底圆，局部新图保留34×24矩形，旧图坐标默认不变。
- 世界地图旧存档非法点吸附最近足印安全路面；成对传送目标为world时强制读取来源区域的最新门户，覆盖旧target_pos和旧返回记忆，室内成对返回不变。
- 同伴注册新增duan_changfeng，加入flag统一解析注册表并幂等；存档仍v12，资源/flag扩展不需要升级schema。
- 开放世界一件装备的木箱要求1个空位，满包不消费领取flag。后续多件/堆叠奖励需按实际容量扩展，不能将这个单槽字段当通用原子发奖事务。

> Role: `system` / Godot 系统 agent.
> Scope: Godot architecture, autoloads, field routing, save schema, inventory/equipment/shop/UI systems.
> Canonical docs: `docs/design-mvp-chapter1.md`, `docs/module-owners.md`, `docs/acceptance-checklists/system.md`.

## Architecture Snapshot

- Engine: Godot 4 + GDScript.
- Core runtime chain: main menu → `SceneRouter` → Field scene → dialog / battle / shop / inventory / quest UI.
- Current system design doc: `docs/system-technical-design-v0.1.md` (2026-05-04).
- Latest handoff doc: `docs/system-handoff-2026-05-04.md`.
- Autoloads currently include:
  - `EventBus`
  - `GameState`
  - `Inventory`
  - `SceneRouter`
  - `SaveManager`
  - `DialogPlayer`
  - `QuestManager`
- Save schema is currently v3 and includes `inventory`.
- `SceneScript` now supports walkable `collision_rects` and `trigger_zones`; `field_walkable_controller.gd` generates static obstacles and trigger areas from those arrays.

## Critical Invariants

- `EventBus` is the signal hub. New cross-system events should go through it.
- `SceneRouter.resolve_action()` is the action string gateway. Keep action syntax centralized.
- `SceneRouter.go_field_smart(scene_id, spawn?)` is now the standard entry for field transitions. It reads `SceneScript.is_walkable` and chooses classic `field.tscn` vs `field_walkable.tscn`; use it for saves, battle victory/flee returns, shop returns, dialog `scene:` actions, and exits.
- UI-opening action strings must go through `EventBus.ui_requested(panel_id)`; `SceneRouter` must not hold Field UI node references.
- `QuestManager.accept()` and `QuestManager.complete()` are the only external quest state APIs.
- Do not emit quest signals directly from random systems.
- `SaveManager` schema upgrades must include migration notes and `experience-log.md` entries.
- Missing `game/art/**/*.png` must not break scenes; preserve `FallbackBg` and HintBar behavior.

## Known Past Pitfalls

- `SceneRouter` once missed `go_shop()` while data referenced `shop:` actions; always verify router API and data actions together.
- Classic Field and walkable Field still have low-level entry helpers, but feature code should not call them directly. If battle/shop/save/exit paths bypass `go_field_smart()`, a scene can reopen in the wrong container and lose its interaction model.
- PNG `.import` files are not enough. If real PNGs are missing, runtime textures are empty.
- UI fallback exists because early runs looked blank when art was not actually in repo.
- Inventory / equipment changes must update save serialization and UI together.

## Data / File Ownership

- Owns scripts under `game/scripts/autoload/`, `game/scripts/field/`, `game/scripts/ui/`, `game/scripts/domain/`.
- Owns scene wiring under `game/scenes/`.
- Shares data ownership with:
  - `lore` for text in `.tres`
  - `battle` for combat numbers
  - `art` for actual image files and paths

## Preferred Verification

- Open Godot project without parser errors.
- Run relevant `game/tests/*.gd` when `GODOT_BIN` is configured.
- For save changes: new game → save → quit → continue → verify current field, inventory, quest state.
- For router changes: test every changed action string once.

## Lessons

- 任务目录不能只遍历 `game/data/quests` 并宣称全部可玩；必须反查对话 `accept_quest` / `complete_quest`、场景引用、完成 trigger 与奖励资源，并将只有定义的任务标成待接入。

- Treat `.tres` data as part of the system contract. Script changes and data changes must be validated together.
- Do not fix failing tests by weakening tests unless QA agrees the original acceptance was wrong.
- If a system task needs new art assets, block on an `art` handoff instead of inventing placeholder final paths.
- For 45° turn-based battle, keep battle logic data-driven and put 45° layout/animation in a `BattleView` layer; do not mix visual stance with damage formulas or quest events.
- Router changes should include a search for direct `SceneRouter.go_field(` / `go_field_walkable(` calls; exits are easy to miss because they live in `field_walkable_controller.gd`.
- Trigger zones that emit `set_flag` can cause Field rebuilds; preserve the player's current normalized position when rebuilding walkable scenes.
- Walkable world coordinates must use the actual `TextureRect` viewport rectangle. `KEEP_ASPECT_COVERED` may crop the source image; using a separately calculated source-aspect size shifts every collision, exit, NPC, and prop away from the visible artwork.
- Modular scene objects may own `collision_size` and `interaction_action`; keep decorative objects collision-free and author obstacle collision around the object's foot, not its full transparent sprite bounds.
- Never rebuild a walkable Field synchronously from `flag_set` while a dialog is active. Defer the refresh until `dialog_ended`, and make inspectable one-shot triggers `interaction_only` with a matching `hide_flag`.
- Walkable maps use `WalkableMapLayout` V2 under `game/data/maps/`. Treat positive `walkable_regions` as the primary movement contract; blockers are only for physical footprints. Keep NPC interaction out of `interactions` because `NPCNode` already owns it.
- `walkable_regions` are enforced twice: boundary collision for physics plus Player's movement constraint before each move. Do not remove the runtime constraint, or diagonal movement can leak across a `CollisionPolygon2D.BUILD_SEGMENTS` outline.
- Keep portal indicators out of HUD bounds and away from baked-in house roofs. The Linxi tutorial exit is at the bottom main-road edge and uses an always-visible locked gold arrow before `got_sword`, then becomes the regular enabled portal after the sword is acquired.
- For persistent NPCs with one-time rewards, replace the reward-bearing dialogue actor with a same-position idle-dialogue actor after the stage flag. Never leave the original actor visible, or rewards can be granted repeatedly.
- Pure RPG direction (2026-07-25): split battle presentation from combat logic. Future BattleActor/BattleView work must not move damage, AI, status or rewards out of BattleController; it only owns actor animation, stage layout and hit feedback.
- Repeatable random encounters are SceneScript data (`encounter_enemy_ids`, `encounter_step_distance`, `encounter_chance`, `encounter_require_flag`) and are evaluated by FieldWalkableController from Player movement. Keep them gated by a progression flag and never trigger while a dialog or modal movement lock is active.

## 2026-07-29 Main-Street Panorama Handoff

- `ch1_s0_linxi_main_walkable` now uses the native `3072x1024` panorama `res://art/backgrounds/bg_linxi_main_street_panorama_v1.png`.
- The matching V2 layout uses one positive walkable region plus small foot blockers for the seam bamboo, smithy, residence, and cliff edge. Do not restore legacy repeated `scene_objects` over this baked background; `map_layout.visual_objects` intentionally remains empty until individually reviewed props are sliced and placed.
- The village-road portal moved to the lower-right road end at `Vector2(0.935, 0.835)` and the player spawn moved to the lower-left public lane.

_Last updated: 2026-07-29_

## 2026-07-29 Native Tutorial Map Fix

- `linxi_tutorial` uses the reviewed single-image `1536x1024` background at native scale via `WalkableMapLayout.display_at_native_size`; do not restore its former `3072x2048` declaration.
- `FieldWalkableController._is_inside_walkable_screen()` must convert Player global movement targets through `world_container.to_local()` before applying normalized positive-region checks. This keeps native centering and camera scroll from rejecting valid movement.
- Use `render_layer = "foreground"` for transparent fence/eave/foliage occluders. `ForegroundLayer` is above `ActorLayer`; collision remains a separate foot-level blocker. Portal markers use a higher layer so they stay legible over foreground props.
- The generated standalone Linxi gate does not match the baked gate perspective and must remain unreferenced. Do not overlay it on the current complete tutorial background.

## 2026-07-29 Panorama Decision

- `docs/panorama-map-production-v2.md` governs future map production: world travel maps and local exploration maps are separate; independent AI panels may not be directly stitched; use pixel-preserving outpaint with overlap only when supported, otherwise build expandable local maps from a no-building terrain base plus reviewed modular props.

## 2026-07-30 World Map Native Layout

- `world_map_jianghu` now references `world_map_jianghu_layout_v2.tres`. Its reviewed background is actually `1536x1024`, so its V2 layout must keep `design_size = Vector2i(1536, 1024)` and `display_at_native_size = true`.
- ALAPI rejected the final `3072x1024` test with `422: 选定的 size 无效` on all three retries; stop treating unsupported request dimensions as a future runtime plan. `validate_walkable_map_v2.gd` asserts native display for the world map to prevent regression.

## 2026-07-30 Mountain-Road Transitional State

- `ch1_s1_road_layout_v2.tres` previously declared `3840x1080` for a `1536x1024` baked source. It is now native-size with `display_at_native_size = true`; do not restore the fake wide declaration.
- The current road art contains a baked stone tablet and distant village buildings. It cannot accept duplicate tablet, gate, fence, or building modules. The approved replacement plan is `docs/ch1-mountain-road-modular-map-v1.md`.
- The terrain-only generation task dry-run passed, but two real ALAPI calls returned no asset, no metadata and no recorded API error. Do not auto-deploy a substitute. Retry only this one task after the provider responds normally, then visually review before scene integration.

## 2026-07-30 Mountain-Road V3 Adopted Base

- The third retry eventually produced `assets/raw/scene_background/ch1-road/terrain/v1/scene_ch1_road_terrain_base_v1.png` (`1536x1024`, ¥1.20). It is adopted at `res://art/backgrounds/bg_ch1_s1_road_terrain_base_v1.png`.
- `ch1_s1_road` now uses V3 layout with a positive road corridor, independently placed stone tablet and chest, and road-end portals. The actual capture is `game/screenshots/field_ch1_s1_road_1785373174.png`; review shows no stretched terrain and the upper-right marker is on the road.
- ALAPI may write a result after returning a header-only console response. Always inspect expected output and metadata before retrying a paid task.

## 2026-07-30 Explicit inspect interactions

- `WalkableMapLayout.interactions` supports background-detail investigation without introducing a new visible prop. Author `activation = "interact"`, `label`, `action`, `pos` and `size`; use a reachable edge of a blocked baked object rather than its visual center.
- `FieldWalkableController` shows the context prompt on overlap but invokes interaction-only actions exclusively from `_on_player_interacted`. Do not restore the old movement-time auto-trigger loop, or papers/chests/bed clues will interrupt traversal and can reintroduce dialogue refresh loops.

## 2026-07-31 Zhuwei release-map wiring

- `ch1_s2_qingfeng` now uses a native 4096x1024 terrain base with modular transparent buildings. Its character movement pre-check must combine `WalkableMapLayout.blockers` with any `visual_objects` carrying `collision_size`; runtime physics alone is too late to prevent visible building overlap.
- The inn door is owned by the inn visual object, not a duplicate interaction entry. Keep the interaction area immediately outside the foot collision, and validate its route using `test/validate_ch1_zhuwei_navigation.gd`.
- Chapter flow validation must ingest map-layout portals, interactions and visual-object interaction actions. It caught the stale Chapter 1 quest trigger pointing at `ch1_s2_qingfeng_walkable`; production route uses `ch1_s2_qingfeng`.

## 2026-08-06 Investigation Runtime Contract

- `InvestigationState` is the sole runtime owner for evidence, testimonies, faction trust, companion trust, bond events, city outcomes and method flags. Do not duplicate these values in UI scripts or individual quests.
- Content definitions live under `res://data/investigation/evidence/` and `res://data/investigation/testimonies/`; dialogue nodes and action strings reference stable IDs.
- Save schema is version 5. Older saves without `investigation` load an empty dictionary and remain valid.
- New action or trigger commands must be added to runtime and `test/validate_chapters_1_4_flow.gd` in the same change.

## 2026-08-09 Village and result-screen regression fixes

- `NPCCatalog.find()` overrides scene-level NPC sprite paths and scales. When a Field screenshot disagrees with the scene `.tres`, inspect the resolved profile before regenerating art.
- Zhuwei merchant and vegetable vendor now resolve to the `v2_runtime` foot-safe strips; the gate guard uses scene scale `1.08`.
- Linxi center's south-district portal is locked to the lower-left road at `(0.260, 0.840)` and returns to `(0.330, 0.760)`.
- Victory result buttons must use textless `btn_menu_frame_*` textures. The only visible action is the runtime text `返回游戏`.

## 2026-08-09 Chapter-end and Chapter 2 market runtime contract

- A walkable-map interaction that represents a person must be authored as `SceneScript.npcs`, not only as `WalkableMapLayout.interactions`; the latter deliberately renders a context `!` but has no actor identity.
- `NPCNode.dialog_variants` resolves the first entry whose `require_flags` are all true and `hide_flags` are all false. Use it for follow-up/turn-in dialogue while keeping one visible NPC and one stable `npc_id`.
- A gated destination needs `locked_label`; otherwise `_spawn_exits()` omits it completely and the player cannot learn that a route exists. Every chapter entry map also needs at least one unconditional return portal.
- Single-screen 1536×1024 outdoor art should use equal-ratio viewport cover (`display_at_native_size = false`) on wide windows. Native centering leaves a visible gray side strip when the window is wider than the source.
- Formal chapter-end capture/tests set SceneTree metadata `skip_chapter_end_autosave` so visual QA never overwrites the player's real slot 0.

## 2026-08-13 悟性与阅历运行时合同

- 悟性是学习型属性：只用于 `Skill.required_insight` 门槛和招式研读阅历折扣，不得再参与最大内力、速度、暴击率或伤害公式。
- 战斗和任务获得的经验会等量累积为总阅历/可用阅历；研读只扣可用阅历，总阅历保留用于长期进度展示。
- 一次性剧情授艺若悟性不足，必须写入 `GameState.pending_skill_unlocks`，并在升级、装备变化或读档恢复后自动重试，不能让玩家永久错过。
- 存档 schema v8 持久化总阅历、可用阅历和待领悟武学；旧档缺字段时以 0 阅历兼容加载。

## 2026-08-13 Skill catalogue VFX contract

- `build_arsenal_catalog.py` calls `build_skill_vfx_previews.py` before reading skill rows, so the local catalogue cannot report stale preview availability.
- Catalogue generation now covers all 42 skills and fails when any skill lacks a generated VFX preview. Runtime registration, source-sheet existence, animation-ID ownership/uniqueness and displacement styles are covered by `validate_skill_vfx_motion.gd`.
- `scripts/build_unique_skill_vfx.py` is the reproducible source-to-runtime step for `game/art/battle_vfx/skill_unique_v1/`; `scripts/build_skill_vfx_previews.py` scans that directory so the webpage always derives from the adopted game sheets.
- Unique names are insufficient evidence: catalogue QA also compares preview hashes, preventing two differently labelled skills from silently pointing at the same visual file.

## 2026-08-14 Sparring and readable-item runtime contract

- Sparring enters battle through a payload with `battle_mode = sparring` and a stable `sparring_id`. Both team and legacy settlement paths must branch before normal loot, experience, flags and `enemy_defeated` emission.
- `GameState.sparring_records` is the sole reward ledger. Save schema v9 persists it through `get_sparring_records_save_data()` / `restore_sparring_records()`; a missing or invalid old-save value restores `{}`.
- A readable item remains a non-consumable KEY_ITEM. `readable`, `read_title`, `read_content` and `read_source` are presentation data; opening `ReadingPanel` must not call `Inventory.use_item()` or mutate quest/investigation state.
- Direct NPC spar actions require a formal confirmation that explains the current reward state. Cancellation must not emit `npc_talked_to` or modify progression.

_Last updated: 2026-08-14_

## 2026-08-17 Character portrait crop contract

- CharacterPanel party cards and the main character-detail portrait must both use `_character_avatar()`. Do not load a companion's full-body `portrait_path` directly into either portrait box.
- Companion sources may be square or vertical full-body canvases. Derive a centered square head-and-shoulders region from 38% of the shorter side, with a small top offset; the main portrait uses `KEEP_ASPECT_COVERED` and clips to its box.
- The protagonist already owns a formal headshot source and therefore bypasses the companion crop. This keeps identity art intact while presenting all party members at a consistent facial scale.

_Last updated: 2026-08-17_

## 2026-08-19 Weapon category and equipment-copy contract

- Call `Equipment.normalize_weapon_type()` at every equipment/skill matching boundary. Resource migration alone is insufficient because old saves or modded content may still contain `dagger`, `short_blade` or `axe`.
- The martial screen owns six filter buttons: all, sword, blade, staff, palm and hidden. Its generated secondary-tab kit has only five interchangeable images, so the sixth button reuses an existing frame instead of loading a nonexistent texture.
- Equipment detail views append `special_effect_description` as a separate purple `◆` line after ordinary green/blue stat lines. Empty special effects render nothing.

## 2026-08-19 Patrol spawn order and baked actor-fade zones

- `NPCNode` snapshots `_patrol_origin` in `_ready()`. Field controllers must assign the authored `position` before `add_child()`; adding first silently sends every patrol NPC back toward world origin on its first process frame.
- `WalkableMapLayout.actor_fade_zones` is for buildings already painted into the base map. It contains only a normalized `region` and `actor_faded_alpha`; it adds no texture, foreground node or collision.
- `Player.set_baked_map_overlap()` fades the base player and restores alpha on exit. Do not call `set_building_overlap()` for this case, because that contract creates a foreground ghost for truly separated building layers.

## 2026-08-17 Global GM console contract

- `GMConsole` is a debug-build-only autoload on CanvasLayer 220. It owns a draggable launcher, F12 toggle and a scene-persistent panel for gold, experience, training points, item/equipment grants and martial-art learning.
- `GameState.debug_force_learn_skill()` is the only insight-bypass path. It remains guarded by `OS.is_debug_build()` and must preserve passive bonuses, pending-unlock cleanup, derived-stat refresh and the normal `skill_learned` event.
- UI capture commands hide GM by default; pass `show_gm=true` only for the dedicated GM screenshot. Release builds must not instantiate the launcher or panel.

## 2026-08-19 Martial UI and formation-status contract

- `basic_attack` belongs only to the all-skills view. Pure heal/buff/non-damage support techniques are heart arts and remain independent of the equipped weapon; `defend` stays a system action rather than a learnable heart art.
- Skill descriptions use regular-weight text at a readable size. Avoid `[b]` in dense runtime detail labels because the current CJK font becomes visibly blurred at small sizes.
- The active-unit arrow is anchored to the center above the HP/inner-power widget, not to the animated sprite bounds. Actor frame motion must never move the turn indicator.
- Patrol-facing correction is per NPC entry (`invert_patrol_facing`) because some source strips face opposite their semantic travel direction; do not globally invert every NPC.
- Formation status icons are buttons with semantic artwork, remaining-turn text, and a transient tooltip. They are HUD/UI children and must stay above actors and battlefield art.

## 2026-08-20 Equipment special-effect presentation contract

- Special-effect text inherits the equipment quality color in every surface: InventoryPanel details, CharacterPanel details, rectangular equipment tooltip, battle log and the generated web catalogue.
- Never hard-code purple for the `◆` special-effect line. Use the owning equipment's quality mapping so rare is blue, epic is purple and legendary is orange.

## 2026-08-17 Character-panel item feedback contract

- CharacterPanel direct consumable use and precious-item confirmed use both call `_use_consumable_for()`. It snapshots current/max life and inner power before `Inventory.use_item_for()`, then renders the actual deltas in one transient toast.
- Permanent growth distinguishes current values from maxima. Status-cure items need semantic feedback even when no numeric delta exists. The legacy InventoryPanel already has its own equivalent feedback path.

## 2026-08-15 Layered dynamic occluder contract

- `WalkableMapLayout.occluders` is visual-only data. Each entry owns a tight foreground `cover_polygon`, a separate reachable `fade_region`, and an explicit foreground source; none may create or replace collision.
- A flattened opaque background cannot produce true building-only transparency by sampling itself. The active base must be a clean plate without that building, while the foreground source retains the original building pixels at the same coordinates.
- Use the player's normalized foot point to drive fade state. Rectangular cover regions over open ground are rejected even if the trigger works; cover polygons must follow the visible roof, canopy or stall silhouette.
- Building blockers, actor foot-depth sorting, foreground occluders and modal UI remain four independent layers. Validate authored geometry mechanically and still capture the player actually standing behind each occluder.

_Last updated: 2026-08-15_

## 2026-08-14 Character equipment interaction contract

- In CharacterPanel, an unequipped inventory instance uses the action label `装备`; the exact instance worn by the selected character uses `卸下`. Equipment worn by another party member is not misreported as worn by the current character.
- Equipped-slot left click is selection/details only. Right click is the direct unequip gesture. Do not bind the slot button's normal `pressed` signal to unequip.
- Equipment detail must include real resource bonuses, crit chance, weapon scaling and school scaling; occupied state and selected state use separate visual styling.

_Last updated: 2026-08-14_

## 2026-08-20 · Offline story catalogue contract

- `scripts/build_arsenal_catalog.py` embeds story chapters in the same offline JSON/static HTML as equipment, skills and quests.
- `docs/storyline-data.json` supplies curated chapter semantics; implemented quest, scene and dialog references are resolved at build time. Core choice option drift is a build error.
- The page must work from `file:///` without fetch, XHR, CDN or external scripts, and it keeps static story cards for no-JavaScript viewing.
- `scripts/validate_story_catalog.py` checks 8 ordered chapters, 4 implemented + 4 planned status, legacy isolation, 2/5/2 core choices, embedded JSON freshness and non-empty legacy catalogue sections.

## 2026-08-20 · 世界地图与自修上限合同

- 世界地图运行布局使用 `world_map_jianghu_layout_v3.tres`，逻辑尺寸 2304×1536；城市出口应调用 `SceneRouter.go_world_map()`，由当前城市到 `WORLD_MAP_CITY_SPAWNS` 的映射决定世界地图出生点。
- 城镇随机遭遇不能靠逐场景删数据实现。`SceneScript.is_settlement=true` 后，行走控制器必须在遭遇抽取前短路；显式 `battle:` 行为不走该短路。
- `Skill.max_level` 表示绝对最高境界，`self_practice_level_cap` 表示武学界面自行修炼封顶。两者必须分离，普通武学默认相等，师门终境武学可设为 10/9。
- 林西终境突破必须是幂等迁移：`q_ch8_main_03_final_boss` 完成后写入 `chapter8_complete`，再校验三门基础武学九重；移除基础条目后授予十重进阶条目，并用最终突破旗标防止重复结算。旧档提前获得进阶武学要在门槛不满足时清理。

_Last updated: 2026-08-20_

## 2026-08-21 · 心法装备门槛与武学面板布局合同

- `GameState.equip_internal_art()` 必须校验当前有效悟性，武学面板的按钮禁用只负责表现，不能作为唯一门禁。存档恢复或装备变化导致悟性下降时，要清理不再满足条件的非固定心法。
- 已装备心法即使后来条件不足也必须保留“卸下”出口；未装备且悟性不足时，装备按钮禁用并以橙色粗体显示精确需求与当前值。
- 武学正式底图的上方详情框止于约 `y=755`。运行时 RichTextLabel 必须开启裁剪和滚动，正文矩形不得跨入下方提升框。
- 程序按钮即使 disabled 也必须拥有正式 `StyleBoxTexture`。技能升级类按钮使用 `upgrade_disabled.png`，禁止禁用态退化成裸灰字。

_Last updated: 2026-08-21_

## 2026-09-09 · faction path 数据合同

- `GameState.faction_id`允许`wanderer`，其显示名为“无门派”；无门派仍写入路线旗标，但不得自动授予任何五派武学。
- 门派初始武学只保留根基；中后期用`QuestDef.reward_skills_by_faction`发放镇派传承。武当剑、掌可兼修，旧`wudang_route_*`只作存档兼容，禁止再用`reward_skills_by_flag`互斥发奖；双修成本由各武学独立历练消耗承担。
- 旧资源ID可为存档兼容保留，但`Skill.category/required_weapon`、装备武器类型、敌人招式和VFX注册必须同步到新门派定位。

## 2026-09-09 · 结算跳转、v8地图与相机性能合同

- `SceneRouter.go_victory/go_defeat/settle_sparring`必须直接切换结算场景；结算界面关闭后再通过`go_field_smart`进入Loading。不得恢复“战斗结束先Loading再领奖励”。
- 世界场景与M键地图当前唯一布局为`world_map_jianghu_layout_v8.tres`；v8像素蒙版必须归微信common包，否则主包场景会在章节包挂载前缺依赖。
- 相机平滑只对桌面且地图/视口溢出比≥1.35启用，速度20.0；Web/微信及接近单屏地图即时跟随，避免每步缓慢追焦。
- 后期区域母图不能单独替换SceneScript背景；必须将布局、碰撞、NPC、热点、portal和验证探针作为一次原子迁移。

_Last updated: 2026-09-09_

## 2026-09-08 · 开放世界任务的章节独立合同

- `QuestDef.chapter_independent`只声明内容语义，QuestManager仍完全按事件旗标推进，不新增存档字段或章节判断。
- 多入口长链把所有线索列入`auto_accept_triggers`，确保玩家从任意入口开始都能接取；全部线索由GameState汇总为最终入口旗标。
- 旧任务旗标迁移在`reconcile_progression_rewards()`中幂等补齐新旗标，并在QuestManager恢复状态前完成。

_Last updated: 2026-09-08_

## 2026-08-25 · World-map v7 runtime contract

- `world_map_jianghu_layout_v7.tres` binds `world_map_jianghu_walk_v7.png`; runtime movement is O(1) pixel sampling. The 93 fallback segment polygons are editor/topology backup, never the primary movement path.
- Large maps keep `WorldContainer` fixed and use a real smoothed `Camera2D` attached to Player. Do not restore `_process()` world translation, 1.15 zoom or final render rounding while the camera is active.
- Player caches weapon/state/direction textures, calls `move_and_slide()` before emitting `moved`, and only syncs the overlap ghost while visible.
- World backgrounds use linear filtering; pixel actors retain nearest. The world map remains native 3072x2048 at camera zoom 1.0.
- `travel_mode=ferry` is presentation/planning data on White Deer Ferry and East Sea Port. Sea destinations must use scene transitions after dock interaction; water must never be inserted into the walking mask.

_Last updated: 2026-08-25_

## 2026-08-29 · 第七章世界地图双入口合同

- `world_map_jianghu`在`chapter6_complete`后用一次性进场对话选择调查顺序；两门户共享`ch7_dual_route_chosen`门槛，差异由独立first-route旗标和NPC variant读取。
- 新Field返回世界地图时必须同时更新`FIELD_TO_WORLD_PORTAL`与场景布局的`target_pos`；v7新增门户还要同步构建器和`world_map_v7_topology.json`，避免重建静默删除。
- 第二个入口的on-enter门槛必须使用共同解锁旗标，不能要求“自己是第一路线”，否则后到入口永远不写入任务进度。

_Last updated: 2026-08-29_

## 2026-08-30 · 双线内门与战斗场地合同

- 双线内门使用共同`ch7_outer_routes_opened`旗标，由完成入口求证后的NPC对话接任务并设置；不得分别解锁造成顺序路线永久分裂。
- 场景ID含`outpost/outer_ward/outer_court`时映射到`courtyard_wedge`战场，避免固定庭院冲突落回竹林平台背景。
- 外院任务使用两个`evidence_acquired`加一个战斗旗标的全触发器；Field NPC在药册旗标后出现、战斗胜利后隐藏，场景刷新由现有任务/旗标事件驱动。

_Last updated: 2026-08-30_

## 2026-08-30 · 第八章主厅数据合同

- 会盟祭台新增`require_quest_completed:q_ch8_main_07_su_first_confrontation`主厅入口，主厅提供无门槛返回祭台的反向门。
- 授权链完成后接取撤离任务；三条撤离对白统一写入`ch8_final_evacuation_complete`与`ch8_rear_sanctum_unlocked`，下一批后殿入口只依赖后者。
- `MAIN_QUEST_PROGRESS_ORDER`已加入第八章q8/q9，故事与任务离线目录同步到122项。

## 2026-08-30 · 薛影处置分支合同

- q9三条撤离结算统一接取`q_ch8_main_10_xueying_resolution`；主厅后殿门只依赖`ch8_rear_sanctum_unlocked`，后殿有无门槛反向门。
- NPC变体要求授权链、亲令证词、撤离完成三旗齐备后才加载三选一对话；默认对白是强制死战，防止旧档或调试跳关无证据感化。
- `SceneRouter`为`rear_sanctum`选择`mingwu_sanctum`专属战场；`BattleController`已登记背景/BGM。

## 2026-08-30 · 苏雾笙终战状态合同

- 薛影三种结算节点统一接取q11；后殿苏雾笙NPC按`joined_mingwu`优先，再读取作证/伏法，默认反馈死战结果。
- `battle_group_then:ch8_su_wusheng_final:ch8_su_final_victory`负责Boss胜利回场；胜利对白完成q11并接取q12。
- q12“旧案见光”已加入主线顺序，等待会盟祭台公示交互设置`ch8_truth_disclosure_settled`。

## 2026-08-31 · 公示策略运行合同

- 会盟祭台公示NPC只在q12进行中出现，按`ch7_disclosure_full`、`ch7_disclosure_staged`、`ch7_disclosure_joint_review`选择三种对白；默认联合会审用于旧档兜底。
- 三路统一写`ch8_evidence_multi_copy`和`ch8_truth_disclosure_settled`，分别写入独立危险武学归档旗标，然后完成q12并接取q13。
- q13已加入主线顺序，唯一完成门为`ch8_aftermath_returns_done`；本批不触发`chapter_end:8`。

## 2026-08-31 · 余波与关系结算合同

- q13改为五个`require_all_completion_triggers`：洛阳、烈云、竹尾、关系、林西；QuestManager完成q13时统一写`chapter8_complete`。
- 三地对白结束调用`resolve_ch8_relationship_if_ready`，只有三地旗标齐全才解析关系；解析器按信任+共同事件评分，并为戚云笙旧档补读三项正式剧情旗标。
- 林西新增`xingfantian_epilogue`状态；旧师父状态在`ch8_linxi_final_return_open`时隐藏，q13结算后由既有终境未就绪/已就绪NPC接管。

## 2026-08-31 · 环境动画运行合同

- `SceneScript.animated_props`正式支持`banner/texture_sway/hammer/flame/smoke/glow`；新`flame`使用程序Polygon2D与径向纹理，不增加物理或交互节点。
- 动画物件使用归一化`pos/size`和视觉`z_index`；剧情状态只通过`require_flag/hide_flag`控制显示，不触碰WalkableMapLayout。
- 所有循环Tween必须由对应视觉根节点或子精灵`create_tween()`，禁止绑定长期存活的Field控制器，否则场景重建会留下无目标的无限循环Tween。

## 2026-08-31 · 漂移迷雾运行合同

- `mist_drift`使用一个128px程序径向纹理和1～6个横向漂移Sprite；数据支持`size/speed/opacity/count/color/direction`，opacity强制限制0.02～0.30，正式场景当前≤0.15。
- 雾层坐标表示漂移区域中心，size表示横向行程和纵向散布；z_index只控制视觉层，不进入WalkableMapLayout。
- 每个Sprite自己的Tween负责重置、淡入、横移和淡出，随Sprite释放；禁止将雾改成`_process`逐帧更新。

## 2026-08-31 · 水面与风雪运行合同

- `water_shimmer`在归一化水域矩形内生成1～8条短Line2D反光，使用节点Tween淡入/漂移/淡出；它不是水体模拟，不允许覆盖陆地或扭曲完整背景。
- `snow_drift`使用一个32px共享径向纹理与4～18个Sprite，支持`size/speed/opacity/count/wind_x/color`；正式场景每场只配置一层风雪。
- 两类动画均属于SceneScript视觉层，不创建碰撞、交互、Portal或每帧更新；所有Tween绑定Line2D/Sprite节点。

## 2026-08-31 · 环境动画平台密度合同

- `PlatformBridge.ambient_animation_density()`：`wechat_trial=0.55`、普通`web=0.70`、桌面`1.0`。
- Field对smoke puff、mist puff、water streak、snow flake数量乘平台密度并保留安全下限；火焰、旗帜、帐篷、竹冠等顶层语义物件不因平台直接消失。
- 密度只改变装饰子节点数量，不改变SceneScript数据、任务旗标、碰撞、交互、portal或视觉根的位置/尺寸。

## 2026-08-30 · NPC基础门槛不能阻断完成后变体

- NPC若用`require_quest_active`限制基础生成，任务完成后整个NPC会先被隐藏，内部`dialog_variants.require_quest_completed`没有机会执行。
- 需要承担“进行中对白→完成后开启下一任务”的常驻NPC，应由场景门槛保证首次可达，并移除基础active门槛；再用变体顺序控制完成后入口。
- “死名活权”使用共同`ch7_dead_code_routes_opened`开放两处档案，任务以一个evidence和一个testimony全触发器结算。

_Last updated: 2026-08-30_

## 2026-08-30 · 内证双线与角色身份资产

- 完成外院任务后由NPC对话统一设置`ch7_inner_routes_opened`并接受第四主线，两处内门共享同一旗标；子场景分别回到原外区。
- 戚云笙Scene NPC同时绑定专属portrait与640×160四帧idle，首次会面后读取`ch7_qi_reform_testimony_heard`切换短复访对白。
- 内证任务用两个`testimony_heard`全触发器；先后顺序均可完成，调查状态负责历史回查和幂等。

_Last updated: 2026-08-30_

## 2026-08-21 · idle/walk计时与主线进场门禁

- `NPCNode` 现在分别使用 `idle_frame_seconds` 和 `walk_frame_seconds`；场景NPC字典可单独配置。巡逻纹理只有真实walk资源才能启用，驻守NPC不配置walk。
- 主角Field根为 `v7_idle_stable`，所有idle条带脚部区域跨4帧一致；walk仍是8个唯一帧。
- `SceneScript.on_enter_require_flag` 只门禁自动进场对白。城市portal和场景加载不再承担章节锁，提前游历不会写入 `on_enter_once_flag`。
- 竹尾晨市/大会执事在前章未完成时使用 `hide_flags` 驱动的early-visit对白；这些对白禁止接取、完成任务或写章节开始旗标。

_Last updated: 2026-08-21_

## 2026-08-21 · 任务NPC与环境调查门禁

- `_spawn_npcs()` 必须和 trigger、interaction、visual object 一样执行 `_quest_gate_passes(d)`；`require_quest_active/require_quest_completed` 现在对任务阶段NPC真实生效。
- 环境调查使用现有 `WalkableMapLayout.interactions`，一次性对白 flag 与 `hide_flag` 同键；不创建额外视觉节点，也不影响主线门槛。
- 交互点验收同时检查正向区域、blocker与玩家半径扩张后的网格可达性，不能只用点是否在原矩形外判断。

_Last updated: 2026-08-21_

## 2026-08-21 · battle_group_then 与任务场景门禁

- `SceneRouter.start_encounter/start_encounter_csv` 支持可选 `victory_action`；`battle_group_then:<csv>:<dialog>` 是正式队伍战后续对白行为。
- 任务NPC和地图交互继续使用 `require_quest_active/require_quest_completed/require_flags/hide_flag` 数据门禁；接受或完成任务时Field延迟到对话结束后重建并保持玩家位置。
- 护商任务只由专属胜利对白写 `caravan_escort_done`，不使用通用山匪击杀触发，避免随机战提前结算。

_Last updated: 2026-08-21_

## 2026-08-21 · 第一章内容计划与旧线隔离合同

- `chapter_1_content_plan.tres` 是第一章机器可读运行内容总表；只登记现行9段主线和6条已接入支线，不把兼容任务当成待制作或可玩内容。
- `ch1_s3_zhuwei_forest.tres` 的 NPC/热点不再引用 `ch1_forest_yuewuxing*`。旧对白可保留在磁盘，但不能重新接入第一章 SceneScript。
- 任务目录生成器以 `retired` 标记三项第一章兼容任务，并跳过退役对白作为接取/完成源；江湖全录的可用数量必须读取同一字段。

_Last updated: 2026-08-21_

## 2026-08-21 · 支线生产决策与采集生命周期

- `ChapterContentPlan.side_quest_decisions` 记录 implemented / merge / migrate，字段包含目标章节、替代任务和原因；目录构建器读取该数据，不再靠硬编码把已处理草案留在“待接入”。
- 采集任务使用两个旗标：`*_collected` 只控制场景物件消失和回交对白，`*_delivered` 才作为 QuestDef 完成条件。任务物件用 `require_quest_active` 出现，避免玩家未接任务时预先采集。
- 林西悬崖药草复用 `visual_objects` 自带交互；不要在 `interactions` 再放同坐标副本，否则会生成重叠提示与重复触发区。

_Last updated: 2026-08-21_

## 2026-08-21 · 主角棍系运行根升级

- `Player.FIELD_VARIANT_ROOT` 当前为 `v6_stowed`，`BattleController.PLAYER_BATTLE_VARIANT_ROOT` 当前为 `weapon_variants_v3/lengguyun`。两处必须成对更新，避免野外已换棍而战斗仍加载旧单手帧。
- v6/v3完整保留五种视觉键；只替换staff也必须复制其他四类到新根，否则换装会因资源缺失回退标准剑版。
- 五武器切换继续从标准scale重算，不得因长棍alpha外框重新缩小角色。

_Last updated: 2026-08-21_

## 2026-09-10 · 林西酒永久上限账本与存档 v13

- `CharacterStats.permanent_resource_bonuses` 保存每角色永久上限来源，`item:linxi_jiu` 累计 `max_hp/max_mp/applications`。核心派生重算只叠加一次账本，不再直接改上限后被升级或心法刷新覆盖。
- `Inventory.use_item_for` 先成功消费一份林西酒，再记永久生命 +100 / 内力 +50 并恢复相同当前值；奖励量不变，支持队友及多份合法使用。没有物品不写账，副作用发出人物与队伍更新。
- SaveManager schema 为 13；主角与所有队友保存账本，恢复时清空旧来源并覆盖读取。主角同时出现在 player/party 两份数据时也不重复发奖；Resource 深复制有独立账本。GameState 无需另加叠加逻辑。
- v12及以前仅在七项核心属性齐全且缺账本时，保留已保存最大生命/内力相对旧核心公式的正差额为 `legacy_saved_capacity`，applications=0，不把差额猜成喝酒次数；无核心字段走既有旧档推断。已经被旧重算抹掉的增量无可靠证据，不补偿。v13缺账本不做旧差额推断。
- 迁移依据：装备只存在 Inventory 的附加层、不写 CharacterStats.max_hp/max_mp；心法常驻奖励已写入核心属性。生命装备穿戴存档再卸下专项确认不会入永久账。未来改生命公式时，v12差额必须继续以历史 `80+vitality*8+strength*3` / `20+inner_pool*6+inner_power*2` 为基准，不能使用新版公式猜差额。
- 专项 `game/tests/test_permanent_resource_bonuses_20260910.gd`：46 checks / 0 failures，覆盖实际两次使用、无物品拒绝、升级、心法学习及装备/卸下、队友、深复制、真实存读3轮、v12重复迁移、装备隔离、缺字段与无证据边界、畸形来源忽略。辅助 `isolated_permanent_resource_save_20260910.gd` 延迟加载继承正式 SaveManager，只重定向唯一测试目录；测试退出清理自己创建的文件，不碰玩家槽位。
- Godot 4.6.2 `--headless --path game --editor --import --quit` exit 0，无脚本解析错误；现有 `build/wechat_stage` 嵌套项目警告与本改动无关。

_Last updated: 2026-09-10_

## 2026-09-12 · 世界地图 v9 同源产物

- 运行唯一布局为`world_map_jianghu_layout_v9.tres`，唯一导航蒙版为`world_map_jianghu_walk_v9.png`；M键地图和世界场景使用同一v9背景。
- `world_map_v9_road_source.py`是道路、门户和见证点的唯一源；`build_world_map_v9_assets.py`同时输出移动端/桌面背景与导航遮罩。禁止手工单独涂改其中任一产物。
- `validate_world_map_v9_shared_source.py`逐像素重建并核对哈希，同时限制背景变化只发生在道路带周边；微信common包必须包含v9移动分块、底图和导航蒙版。
- 林西与竹尾的城市出口`target_pos`必须等于v9对应门户坐标，避免依赖最近道路搜索掩盖配置漂移。

_Last updated: 2026-09-12_

## 2026-10-14 · A3/B3 城门候选接线 SOURCE（未出版/未正式）

- 精确旧 Gate 合同897FE9B8与旧publisherEB20C198全文备份：`game/build/gate_fortification_v3_binding_before_20261014_6ed1c5bb2d99419caab5ed3f43850359/*.source`。旧V1 author/manifest/native captures/Scene/layout保持；C48ED42A3、Field94D87559、水runtimeC8FFF519和fade26FC78AF未改。
- 新产物根为`res://art/maps/luoyang_gate_fortification_v3_refined/`，Scene/layout各在`luoyang_gate_fortification_v3_candidates/`。合同分别绑定A3 report087A0A76的wall与B3 report9886E63F的tower，来源同path异SHA拒绝；B3 333px高/foot324.958984375按actual安放，slot140/2932不抄展示图100/2972。
- SOURCE冻结：Gate合同ADAE5DCC、NEW publisher73086031（`publish_luoyang_gate_fortification_v3_candidate_20261014.gd`）、NEW author0C51EBC7。数学/875/4px/PNG读回/semantic/公共checkpoint收尾与旧publisher机械逆换精确相同，只增加双capture绑定及导航SHA必须D9A14F7A。manifest pin仍PENDING，未运行Godot/import/API、未写canonical/保存/音频；下一由root唯一出版并绑定实际manifest后短Field验收，不授旧六或资产图即正式。

## 2026-10-02 · 白鹿渡邻接回程最小客栈阻挡校准

- 在v14九区正式接驳测试中，QA独立mask-only／逐blocker对照证明旧白鹿渡仅加入`ferry_inn`即可使北路完整脚底路径断开，spawn与世界出口本身合法；另两blockers仍可通。实际v2原图客栈在左侧，旧框center(.345,.155)/size(.180,.145)误占公共北路，不是新版大地图导航应白化的问题。
- 主控明确批准仅该邻接目标一处布局字典改动，按实际左侧墙面／台基重锚为center(.085,.225)/size(.170,.170)，保留原ID、默认grow.014和全部正负probe。PNG／nav／门户位置／target_pos／NPC／故事／生产manifest未改；没有删除客栈阻挡、没有放宽测试或改变共享Field旧场语义。
- 旧布局逐字节副本`game/data/maps/openworld_bailu_ferry_layout_before_v14_return_fix_20261002.tres`保留SHA `1bbad7067a3cebd017c4acd71763387f5c9ebf5e6133bfee11efad359e9f4c6c`；文本比较唯一变化是inn字典。此布局不在原403.files列表中，403冻结规则不变（cutover前403／后402），Bailu另以原SHA及唯一hunk保护，不宣称改成401或静默扩allowlist。
- 后续主控批准publisher `_asset_hashes()`显式增加现役Bailu layout及上述原始副本两条路径，验收fingerprint exact keyset与SHA同时绑定此邻接修复；碰撞或证据文件再变必须使旧activation批准失效。批准后Godot4.6.2真实轻量headless check-only publisher exit0，无错误输出；未改变其他发布行为、没有重新publish或activation。
- 历史CityFerry专项仅取mask中心probe，Region专项遇mask即直接返回、不读取blockers，因此旧绿未证明实际北路连通。真正运行层同时生成实体StaticBody矩形并缓存grown blocker用于移动／出生修复；需QA重验mask负例、17完整足连通及真实Player往返。本人仅完成受限patch，没有执行引擎或批准系统／视觉／formal cutover通过。

_Last updated: 2026-10-02_

## 2026-09-28 · v13 九宫 staging 地图与安全切换边界

- 正式 `world_map_jianghu` 继续为 v12。独立 `world_map_jianghu_v13_staging.tres` 使用 4608×3072 逻辑世界、九个 1536×1024 唯一地形流式 chunk 和九张各自绘制的 SVG 导航；`WalkableMapLayout.tiles` 保存每块图/导航/rect，缺资源不得用旧图复制或开放空白。16 个旧 `portal.id/target_scene/target_pos` 保持，地标图、脚底 blocker、近距入口与回程按同一 ID 配对。
- 12 条地貌接缝透明覆层及 17 条通往 16 个入口的 `travel_routes` 已进入 staging 候选，全部为 `PENDING_*`。`FieldWalkableController` 只在每条路线的所有中心采样已在导航白区且不压建筑 blocker 时绘路，绝不因贴图自动开放导航；路层 z=-1，在桥、山体、建筑和角色下面。道路数据有有限宽度，QA 还必须检查边缘 10×6px 完整脚底。当前路线专项 172/0/1 仅是导航合同，并非视觉验收；金陵两桥至南门仍有过长、过规整的 U 形路径，过渡图有贯穿山墙/硬切，当前九块独立生图边界天然不对应。统一母图到位前勿逐像素硬拗旧图、勿批准 seam 或道路。
- 桥导航只允许明确的 80px deck 中心带，两岸其余水黑区。桥当前 6+5 个跨界样本在桥板中心而非侧水；因桥图/岸路未获视觉准入，QA 标 PENDING，不得自行改 `APPROVED_VISUAL_QA`，也不得为凑绿色把桥面封死。`blocked_probes` 记录桥两侧上下游及水岸负例，候选桥坐标若改变必须同步移动桥图、deck mask、岸路与 probes。
- v12 旧档升级是显式 opt-in：`SceneRouter.restore_navigation_state(data, fallback_field, WORLD_MAP_STAGING_SCENE)` 按旧门户 ID 对应新安全门前锚点重写世界回程；未给第三参仍回 v12。`SaveManager.load_from_slot(slot, WORLD_MAP_STAGING_SCENE)` 与 `get_save_field_id(slot, WORLD_MAP_STAGING_SCENE)` 仅供独立测试/将来正式切换，默认无参 UI 不变。真实槽位测试必须隔离 `user://`，不可覆盖玩家存档。新母图若挪襄州/金陵等门户，仅换视觉、portal.pos 与导航安全脚点，16 IDs 和旧档映射语义不变。
- 2026-09-28 本轮资源严格导入 exit0；staging 行为合同 481 checks / 0 FAIL / 10 PENDING；路面专项 172 / 0 / 1。正式切换门槛仍包括统一母图九区视觉、12 接缝、16 入口主路与双向返程、桥面/旁水、旧档真实加载和 1.25× 实机截图全部通过。
- 2026-09-29 native 母图止损：`scripts/build_world_map_v13_native_candidate.py` 与 `game/data/maps/world_map_v13_native_compose_v0.json` 可复现输出 4608×3072 候选 master、24px 重叠的九张同源 chunk、SHA/源矩形 manifest，九块重拼逐像素一致；rough biome mask 脚本与中心—东岸局部 spec 只作实验，输出隔离在 `game/build/world_map_v13_native_*candidate/`，未改正式 v12/现有 v13 staging。Godot 1.25× A/B：强微材质 1.25 增益成为俯拍纹理地毯，淹没山脊；20% 增益虽保留 2.5D 地貌，但锐度几乎与低分母图同镜头一致，仍明显糊。producer/art 一致判视觉 FAIL，manifest 保持 `PLACEHOLDER_CONTRACT_ONLY` 并记录拒绝；不可扩九宫或切正式。正确下一工艺需原生 4608 可编辑的等比例 2.5D 地形结构母版（如正交 3D terrain 或手绘分层地形）＋同源水域/道路/导航 mask，山岩/建筑等高物件保持独立 `visual_object`＋脚底 blocker/Y 遮挡，再由同一 native master 确定性九切。不得把 1536 Lanczos 放大或五种微纹理平铺当高清完成。
- 2026-09-29 固定正交几何探针止损：隔离脚本 `game/scripts/dev/capture_world_map_v13_ortho_terrain_probe.gd` 在 Godot 4.6.1 OpenGL 桌面渲染生成中心河＋东岸双湾原生 3072×1024 与真实正交 1.25× 两张截图，路径 `game/build/world_map_v13_ortho_terrain_probe/`。纯蓝初帧并非美术判定，原因是地形材质背面剔除；显式启用 SubViewport 3D、关闭材质 cull 后相机/网格/纹理均能显示，exit 0。渲染的河湾边缘沿 24px 网格阶梯化，山坡几乎无体积，五种材质呈亮色重复的俯拍地毯；producer/art 对真正可见的 1.25× 帧一致判视觉 NO-GO。该脚本只保留技术证据，不接 v13 staging 或正式 v12、不扩九宫。要达到写实 2.5D，仍缺人工/外部 3D 原生山岸地貌造型、两湾连续坡岸与正交同尺度美术，以及由同一岸线输出的水域禁走和门前干地/栈桥连接；单靠现有五张材质+简单高度场不可交付。

_Last updated: 2026-09-29_

## 2026-09-14 · 导航蒙版与世界地图v11合同

- 汴州、襄州、金陵、白鹿渡使用768×512黑白导航蒙版并做7像素MinFilter收缩；运行时不能再回退到宽松矩形区域。
- 襄州树冠遮挡与导航分离：树冠alpha只负责绘制层级，黑白mask只负责脚底碰撞，两者不能互相代替。
- 世界地图现行为schema 11、20路线、16门户和独立流式分块；微信/Web打包规则必须指向v11，不得静默回退v10。
- 音频默认Field和近期场景统一指向认可的林西主题，胜利默认指向`bgm_victory_v4_approved.wav`。

_Last updated: 2026-09-14_

## 2026-09-11 · v8 林西主路复描与 Field 点击出口优先

- 正式 v8 底图不改（SHA256 `6057ea346226519807b148be4f0cf3784def7ca38d0517117879791410849272`）。旧林西东行线在参考 x480～560 处偏北约20px，旧返接线穿过村屋顶；`world_map_v8_road_survey.py` 重描实际弯路、村北支路，补4处真实路口面，不放开整片草地/山地。
- `build_world_map_v8_navigation.py` 增加只读式坐标图 `--inspect-only`，RGB独立横断面33段逐像素验证；470个路面样本由328（69.79%）提升到470（100%）。38段路线5995个中心密采点通过5px半径净空，13门户同连通域，12个岩壁/水域/屋顶反例保持阻挡。此百分比仅指登记样本，不声称所有美术像素自动识别正确。
- 输出证据在 `assets/processed/scene/world_map_v8/`：`linxi_road_before.png`、`linxi_road_after.png`、`world_map_v8_navigation_overlay.png`、`navigation_validation.json`；重复构建保留首次修前对比，不修改门户坐标/门禁/目的地。旧测试见证(490,726)偏离真实路心，正式survey已改(490,741)，需QA同步旧期望。
- Walkable Field统一从`_unhandled_input`接收左键/触屏，在HUD未消费且无对话/系统面板/切场/战斗锁时，根据viewport坐标逆变换至各视觉节点拾取。优先级：可见出口箭头（9屏幕px容错，最近中心优先，同距按资源顺序）→NPC（最大脚底Y，平手资源顺序）→可交互物件→出口地面区。点箭头不再被NPC Area抢走，远距只提示靠近、不透传给后层。
- Field生成的NPC、出口和交互物件关闭独立physics pick，由单一派发器调用既有try_interact/trigger；范围、锁定、对白与奖励仍走原接口。不改变Space键NPC优先，也不改变I/J/C/K/M/F12等键。
- 南坊归田村民由(.630,.340)移至(.600,.350)，巡村老兵由(.930,.470)移至(.885,.460)，避开药铺箭头与内缩世界出口箭头；保留ID、对白与动画配置。
- 验证：Godot4.6.2 editor import exit0，Field实际加载无解析错误；既有出口marker回归PASS；既有v8道路49项为48通过/1旧见证失效（上述(490,726)），不为了旧断言重新放开草边。新增真实点击/触屏专项由QA接续。

_Last updated: 2026-09-11_

## 2026-09-11 · 当前装备图标、持久详情与有符号属性色

- CharacterPanel右侧六槽保持82px行高/12px间距，每槽新增64×64图标、独立槽位名、装备品质色名称；长名省略。缺图与空槽复用现有六类语义fallback，空槽保留“未装备”。所有子视觉mouse_filter=IGNORE，父Button仍接键盘选择、左键查看和右键卸下。
- 左键仍调用`_select_equipment_slot`→`_set_selected_inventory_entry`→`_refresh_inventory_detail`，与背包共用唯一InventoryDetail；触屏选择后按可见“卸下”操作，不引入长按或竞争详情面板。原同部位候选对比与队友选择保留。
- `equipment_stat_presentation.gd`从Equipment数值生成text/kind/value结构化条目：正值#72d2a6、负值#ff8770、零隐藏、无额外属性中性。角色详情、当前装备对比属性、hoverTooltip及旧I背包共享该来源，暴击/命中/流派百分比也支持负值；不从字符串减号推断。特殊词条按自身品质色，比较净差仍按candidate-current正绿负红。
- Tooltip的EquipmentTooltipStats改为RichTextLabel，逐条按数值着色；仅compose_text但没传set_stat_rows的兼容调用保留中性，不再把未知文本全部涂绿。
- 验证：Godot4.6.2严格导入exit0；CharacterInventoryActionButtons9项、EquipmentCompareStoryPortal8项通过；PartyCharacterSystem中所有装备/队伍UI交互通过，唯一失败为早已变化的沈青禾首次招募对白旧断言。旧EquipmentTooltip7项中6通过、1旧“统一绿色Label”断言待QA改为有符号RichTextLabel。
- 已实机查看1920×1080 `game/screenshots/character_party_1789129444.png`：六槽图标及名称未裁切。占用槽品质色、重剑速度-2、负基准比较及触屏专项由QA续验。运行数据、地图和战斗未改。

_Last updated: 2026-09-11_
## 2026-10-03 · 三处独立原生郊外系统候选（未采用）

- v4 视觉候选新增固定目录 `res://build/world_v15_outskirts_visual_v4/`，必须同时显式 `--outskirts-candidate-preview` 与 `--outskirts-visual-v4`；单 visual-v4 拒绝，默认 ROOT/ADOPTION/正式场景壳不变。contract cache 改完整 art_contract 路径，materialize 同步绑定 ground/native walk/props/source 路牌及 RF/mesh/camera 图谱，不把新物件叠到旧底图或导航。缺候选只记 NOT_READY，不称 Field 或视觉通过。
- 主控首四模式轻检 default/single/dual 实际 OS0，但 original preview 实际 OS1、123 项出现三原壳不可变失败，原日志保留。原因已由主控 retry1 的实际普通 `scene.duplicate(true)` 诊断证明：三图 `same_layout=true/same_objects_array=true`，外部 ExtResource layout 未隔离。仅 helper 增显式独立 layout 复制并对其 STORAGE Array/Dictionary 独立 duplicate；native 与 source overlay 共用。checker 保持不可变断言，逐字段比较和布局/数组身份验证，不放宽失败。
- 主控实际串行四模式 retry1 均 OS0：default90/0（WARN1）、single visual90/0（WARN1）、dual v4 90/0且refused3（WARN0）、original preview282/0且bound3（WARN91）。新壳与三个源 overlay 的全部 STORAGE 不可变/独立引用通过；日志 `game/build/outskirts_v4_binding_checks_20261003/*_retry1.{stdout,stderr}.log`。helper SHA `6DC16FE0804C1B47D1BC1EEB21C1F902068AE682D2308F55C54D42F4DC2042D4`、checker SHA `395487DE98EEC8E58A4BEB9D5D3105F353C9AF5D982202D5DCD21BD55D7B3B5A`。仅轻编译/绑定证据，不能继承旧2499完整 Field，也不新增运行批准；系统未自启引擎、未改正式/adoption/存档。
- 新场景固定为 `openworld_v15_bamboo_outskirts`（林西竹溪林，2–4级）、`openworld_v15_forest_outskirts`（襄州密林，7–8级；现役TreeSmall02为阔叶树，不称松林）、`openworld_v15_marsh_outskirts`（金陵南泽，10–11级）。独立1536×1024原生底座、四份画面/导航、RGBA物件与RF/mesh证据由art提供；系统只写新SceneScript/layout/dialog与限定胶水，不改既有敌人、战斗数据、正式世界资源或用户存档。
- `outskirts_native_contract.gd` 只接受三个准确ID、`round_world_pixel`及显式0px物理/导航margin；当前asset SHA、capture graph/source graph、实际源图尺寸、RF/mesh/camera均逐字节绑定，缺失或篡改拒绝。导航在真实投影像素取中心+16个10×6px脚底点，独立物件按实际脚底阻挡；不继承旧普通场景的`.004`扩框，也不把三个地方场景伪装成世界schema15。
- 源入口分别挂林西南坊(.55,.53)、襄州矿谷(.80,.62)、江南芦荡(.72,.58)的实体路标。实际路牌鼠标、箭头与Space共用同一ExitZone权威，要求当前源场景、真实脚位置、完整足净空及目标可用；`source_foot_pos` 与 `source_spawn_pos` 分离。南坊旧actor origin按现役剑idle_down实际高度/缩放/脚偏移换算，feet=true场景保持无偏移，不能把47.628px硬套其他场景。回程采用源actor origin，目标入场采用art真实return foot，不使用资源壳占位(.5,.9)。
- 新三场仅调用Player既有5px脚锚、普通255上限/8px带稳定脚排序和局部alpha ghost；其他91地方场、v14世界及其sealed helper语义不变。短材料探索复用现有DialogScript的`blocked_story_flag`+`required_free_inventory_slots=1`，一次给已有材料并置旗；重复战斗走现有Encounter/奖励，未加无限永久属性或公共DialogPlayer动作。既有背包满保守拒绝（即使已有同类堆叠）本轮不改。
- 默认 `outskirts_native_adoption.json` 为 `NOT_ADOPTED`，正常入口隐藏/目标拒绝；仅显式 `--outskirts-candidate-preview` 可技术验收，不能称正式可玩。正式采用必须root真实逐图/Field/进入返回/正常随机战/存档验证后绑定全部三份当前合同SHA。`.gd`源字节门禁在只有`.gdc`的导出包会拒绝，本轮范围仅Godot工作区，不冒称Web/微信已支持。
- 主控严格import实际OS0；首系统checker实际OS1（动态helper结果`missing_scene`推断失败）保留原日志，仅改为显式Variant后，主控 `system_retry1.log` 实际OS0，7脚本动态加载、三个BGM存在、未采用拒绝及导航状态不变通过。最终checker SHA `0FB4E8868BBD04B97A958DAB889F9CCD4479F3B457B7B0AD4FAB38276230CA46`；contract SHA `502C3CF348E40F1AA2EA2B3B674BBA13886701A6C38A48D2EF481570ABDA087A`。QA预检334/0不是Field通过，真实Field窗口由QA独占，系统源冻结。本条不自批系统/视觉/采用；art三场技术重试OS0但画面仍FAIL，正式世界SHA `838380FDB05D08B4B521D92EFB12A13369358090740DC5C7D4CB7C9EC6F4C015`保持。

- QA首轮真实headless Field实际OS1、2198/1保留；一次自然Encounter胜利返回、六玩家存档不变，仅behind-alpha复合断言仍独立拆证据，退出resource告警另记，不能称全过。该进程退出后主控仅批准三处执行文字「襄州松林」/「松林小径」改为实际阔叶对应的「襄州密林」/「密林小径」；ID/等级/路线/导航/ghost/奖励不变。改名后contract SHA `C0F7FE64B9E81241AD13A1203B64F8374E90DC9867B8DE23B6D1F7105DA9766B`，此前502C及0FB4检查证据仅属于改名前源；未自行发动引擎或改失败算法，等待root/QA后续验收。

- QA新local-links实际2347/24、OS1保留：源入口三模式因独立oracle错误要求旧polygon源提供PNG而未执行；三源现役仅`walkable_regions`+blockers，须QA按旧真实语义独立验证，不能改生产源伪造白mask。材料首满袋实体点击已真实开capacity fallback，原地腾空后第二点击被Field的`_trigger_events_in_flight[discovery_cache]`残留锁拒绝，首次public play反而才发奖导致每场4个级联失败。主控批准仅exact3 native discovery_cache interaction_only、本场准确authored action捕获真实dialog_started live ID，matching dialog_ended仅erase该1项锁；不动公共DialogPlayer、一次旗/背包门槛/奖励/旧91场/source路牌/alpha/audio/nav。Field新SHA `6A4AF836B4D098B317446DD33CE4B2B67E4500BFB20C8FA8980E5BBE1522B646`；系统未自行运行引擎，此修待主控编译及QA原地正常点击重验，仍未采用。

## 2026-09-12 · 雨景移动性能合同

- 全屏雨幕禁止在fragment阶段为每个像素重复计算随机哈希；使用Field首次进雨景时生成并缓存的128×128稀疏纹理，Shader只做两层滚动采样、斜风和透明度合成。
- 剧情天气状态、室内抑制、独立雨声与存档合同不变；性能优化只能调整渲染实现和装饰数量，不能把天气重新绑回SceneScript。
- 小雨/大雨水花顶层预算为5/8组；桌面真实渲染探针`probe_rain_runtime_20260912.gd`只提供证据，不作为跨设备CI阈值。

## 2026-10-02 · v14 同8px深度带独立物件排序与第七版发布证据

- 仅v14启用的`v14_modular_overlap.gd`注册真实ActorLayer物件、Player与正常生成的NPC根节点；每次refresh先用实际global物件脚底／actor `get_depth_sort_y()`更新8px band，再只排序发生变化的band。真实脚底相等以原注册ordinal稳定排序，ghost不进入排序；不启用以图片中心排序的全树Y-sort，不改旧91场景。
- 同band ghost覆盖必须同时满足物件脚底严格位于角色后方、有效Z不低于角色、同band实际sibling index在角色之后，再作当期角色alpha与物件LINEAR alpha交集。debug新增`get_v14_depth_order_debug()`的foot_y/band/sibling_index/stable_ordinal/actor与ghost order_revision。正常`_spawn_npcs`经`_update_actor_depth(npc)`赋本场上限（v14=512，普通=255），不依赖测试手塞meta。
- 两运行源READY SHA：Field `F3B73F30FE90BD1B4A6E6E6EC792593D5CC4207EA3E9D429B2002623B080BC78`；helper `C17C7E1CD8435A1D1C7EC3637659501B7C82BFCDD1AE5E63EA67E8861291A6BC`。helper真实check-only exit0；直接Field check-only因该入口没有autoload名称编译环境而exit1，系统checker check-only只解析checker并不动态load Field，不能称Field运行通过。完整／GPU验收仍由主控与QA另跑；本人不自批系统PASS。
- 六次失败运行的这两系统源未在编辑前保存原始字节，主控已在失败归档README记录证据缺口；不得逆构成所谓原件。第七版必须冻结新的系统源重新验收，不能继承第六版批准或绿数。
- 主控授权publisher固定增加第七draft及第七native_surface两路径，保留第六路径；递归扩展`.rgf`绑定真正Float32RG `road_profile.rgf`。publisher真实check-only exit0，SHA `6967B6C3E60794AD5CB6C1C402E4CE450A2FB3639D2F68DC898582E3F3C25234`，未publish／activate。第七两源全文只读审查，无新增静态capture阻断，但实际视觉／Field仍待验。
- 第七相同source/variant/yaw/scale的body复用明确`fresh_capture=false`；原型repeat不是每株新GPU重复证据。QA需独立核当前camera、translation、prototype SHA与足锚定；各实例caster和物理/Y合同仍独立。不能仅凭真实height/PBR源码或CPUforecast宣称正式整图视觉通过。
- 第七限定真实运行随后13793/5及SCRIPT ERROR保留：正常NPC释放后helper先`as Node2D`再valid检查会每帧报freed-object。仅helper将注册、prune、bucket move、debug、signature和candidate全部改为先检查存储Variant是否有效再转换，SHA更新为`92F80ED076D90BE292C848CB9743130B465B71E06250E8867D24E01F02090DAB`；没有改排序、alpha或导航门槛。
- 静态追踪发现父Field idle refresh先于NPC子节点patrol idle移动，可能同band次序滞后一帧。主控批准v14-only内部子Node `V14LateDepthRefresh` priority100，在默认idle0的NPC／Field之后、渲染之前刷新；Player动画仍physics，传送／动态强制刷新仍即时。弱Field引用、唯一节点与当前身份／rebuilding gate保护退出；旧world remove_child立即停止处理且queue_free，不给普通91场创建节点或修改全局Field priority。此后Field SOURCE SHA为`EF00B668356416A12307859236A0EE3006AB469ABE0ED8A0905CADB5B660B8E0`，尚未引擎解析／实际回调验收，不能称运行PASS；真实patrol crossing、相同foot稳定tie、当前帧alpha及释放／退出回归待QA窗口。
- 主控后续真实causal1496/1无SCRIPT ERROR，晚回调／释放／普通255清理及原timing树前方通过，唯一NPC alpha站位横32px未交需QA另校准；不能因此掩盖原bounded retry2真实4609/3：两树front早边界断言及一个陡坡脚样本仍失败。`await process_frame`恢复在节点idle之前，不能自动视为priority100已处理／实际帧渲染后的证据；QA需保原timing，按before-force-ghost等历史调用作受控自然physics/idle后诊断，不能force刷新抹时序。
- 主控另授权publisher绑定8/9固定draft/helper、6实际模型glTF及本地buffer/image依赖、6套PBR SOURCE与18通道JPG、pine/tree/RockFace SOURCE，以及固定`repo://`三fetch脚本、许可doc、raw登记README和RockFace raw5来源字节。repo keys只从明确project父目录及固定相对路径解析，不使用manifest外部URI；拒绝越目录／网络模型依赖。所有current SHA必须非空64位，缺九源码／缺依赖或坏sourcegraph激活拒绝，不conditionalomit。publisher SOURCE SHA为`441CE10567166C21DBB38E580F02B33FB6D5E8B03D49EB5895870BE9365A01F8`，此增量未发动引擎／check-only／publish／activate，等待主控独立读与执行。后续登记doc或来源字节再变必须重算exact keyset并重新批准；绑定来源字节不等于许可真实性、技术或视觉批准。

_Last updated: 2026-09-12_
