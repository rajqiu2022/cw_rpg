# 洛阳全区补齐 · 2026-10-21ai

状态：实施中。用户要求“继续下一步，补齐完整洛阳城所有区域”。沿用已认可的z总规，不另造城市方向，不把十功能区误做十张独立加载图。

## 目标与顺序

1. 南市：以已通过留白的AH药铺为起点，补书斋与独立宅门；拆解一楼三种用途，门、返脚、实体足迹和导航同步。最初三栋同东街方案经实际空间核验不成立，已改为两商铺＋独立宅园外场，见下文。
2. 全区盘点：将南门、主街、府衙、南市、百工、居民坊、宅园、码头、园林、古寺逐项对应到现役场景、资产、NPC与可进入房屋。只计已接入内容，不把候选和计划算完成。
3. 逐区落地：按资产与路由依赖安排，建筑/地面/物件/NPC/氛围同区配套；关键通行、入口与代表室内往返通过后才交付正式。

## 写权与保护

- System：现状精确映射和新候选接线；ART：两门脸提示词、素材与来源；QA：独立守卫与有限验证；Root统一调用生成、执行验证和集成。
- 新候选分别在`game/build/luoyang_city_completion_20261021ai_{system01,art01,qa01,root01}`。旧AF失败、AG原raw和AH派生不改。
- 用户编辑器、Ollama服务与存档保留；普通修改不要求退出编辑器。实际测试只运行自己的进程。
- 新图用内置imagegen，每图单独调用，透明背景由生成器直接产出。上次本地padding授权不泛化到新图背景处理。
- 不改存档schema、任务奖励、原NPC身份；不绕过来源与几何校验。正式部署的目标白名单须在候选验收后冻结。

## 验收

- 门脸：单主门、成年人尺度、入口不烘家具，完整alpha检查，材质/镜头一致，非给同一楼换标签。
- 布局：建筑与檐口不穿插，街巷分级、门前净空、原灯树/巡游/任务点保护；不靠淡化掩盖重叠。
- 接入：新geometry/solid/NAV与门户一致、至少代表门真实入出，原存档未变。
- 进度：分开列素材完成、候选完成与正式可玩；不因全区清单完成而宣称整城已改完，不捏造加载改善。

## 实际结果

### 十区现状与范围修正

System现源映射`game/build/luoyang_city_completion_20261021ai_system01/district_mapping_readonly.json`：01南门→Gate，02主街跨Gate/Market/Yamen，03官署→Yamen，04南市→Market，08码头→Docks，10古寺→Temple；05百工、06民坊、07宅园、09园林尚没有对应完整街区，不能用已存在的同名室内充数。五个现役外场不包含剧情地道。

旧东街北窗上限：shop完整alpha底761，加80px退界后到横街保留带顶1012仅剩171px；南窗又与两棵追加树完整alpha相交。主门120px的正常完整建筑约220–240px高，不能压扁去凑171px。因此放弃继续缩楼与三栋同线，候选改为Market24→25（旧楼换药/书两栋），豪宅归属独立`luoyang_estate_riverside_20261021ai`小外场，旧豪宅室内ID保持、只精确迁返回场景/脚位。05+06另安排一个紧凑街坊，不继续堆南市。

范围后继`scope_successor_two_shops_estate.json` SHA `45D7DC9B6A21C2D4BABBE063F3013A090FB0C451BB22985F5BD082DAE9A511C0`。早先8脚本仍是未完成的三栋草稿，不部署、不跑其旧语法检查来冒新范围通过。新外场沿现有通用SceneScript/WalkableMapLayout，显式矩形实体和mask；不假称C四城多边形字段在普通新ID自动生效。正式四城C校验不绕过。

### 素材实际调用及失败

本批内置2次独立generate＋各1次定点edit，四raw完整保存于`assets/raw/luoyang_market_frontage_20261021ai/`，model/provider/cost工具未披露保持null。首稿都仅将AH作为材质/镜头参考，却继承过多屋顶形体及红边；书斋修正为直脊硬山灰砖门脸，宅门形体独立且门口净空，但修正版完整A1仍受弱alpha污染：书`[0,23,1369,1096]`占宽98.9877%，宅`[19,47,1345,1095]`占宽95.8785%，两者透明边距/占比FAIL。不导入、不把A16主体代替A1授准。

QA首稿量测自然1/`F735630D…471C7`；第一次edit量测因spec字段位置不同自然1/KeyError（`raw_v2_measurement.json`），NEW工具仅显式绑定两spec并映射同判据字段后，实际edit量测自然1/完整像素FAIL `07577F50…5FC53`，不是改宽标准。误传占位SHA的`DO_NOT_USE_precheck.json`也保留为无效输入FAIL，未计有效测量。

本批最终tasks SHA `7E03AF06D8BDE3333BC465784BC0D33D9A10ED629E212ED65B4B61339FD446A9`。已停止追加生图，向用户单独询问是否允许仅对两v2进行本地背景/边缘清理；未收到授权前不执行。上次AH许可不泛化。

### NPC生活文本

现源12组装室内类型/69家具条目；只有3房有staff，另9房空。36新增生活身份中5文化＋3搬运身份有日常/文化话题，其余28无明确对白。数字为现源身份/字段，不是同屏常驻数，不包含55计划槽。

Lore新建12既有身份/24句日常对白：城门候检与挑夫3、官署递文书与候见2、南市买卖与茶客4、码头货行与装卸3。保原primary/culture优先，不改姓名、职业、任务、奖励或flag；候选在`game/build/luoyang_city_completion_20261021ai_lore01/`，尚未正式绑定或配音。真实资源加载及残余核验结果见下。

Root实际资源加载：入口check-only自然0；GUI引擎119464报告573项/2失败/24ms，真实12 DialogScript/24 DialogNode已加载，571组件（类型/链路/零副作用/来源26/15存档/状态）通过，整体FAIL保留。两失败均QA误将culture生活人群5作为文化全部演员数，后者实际6（另原有书生）；不是资源或生产错误。该GUI子进程退出码未独立捕获，不以外壳0冒actual OS0。原报告SHA `0BB9CBDD83613CFE71A4EA2C6B9E06BC8157FB264B2C33A72C04A2C37AE94DF6`。

NEW只读残余84364自然0/74检查0失败，SHA `E30A50ECE82D8901C0BDE508D101694A4AB23E8E818FDD8B59B0734B0AA8439A`，精确绑定原报告571已完成/12/24，只补六culture＋三carrier的九身份排除与候选secondary-policy，不复加载12资源、不洗原FAIL。生活36中5文化crowd＋3carrier=8、28空对白仍成立；6是文化全部演员，不能混口径。资源可读不等于玩家已可与这12人聊新话题。

### 独立宅园干院几何及首图拒绝

未使用失败的新宅门：首干院复用已有`courtyard_wall_gate_v3.png`，实际门高139.92px、完整alpha约840×330，配4原树、草/石材质分层。Root用console入口check-only自然0；唯一geometry114084自然OS0/728ms，四路线2226采样逐875＋17、6矩形实体、5完整alpha包络、native3/packet整存储读回通过，19源首末同。报告SHA `91C95216C2E422FA7389EF291683DD25FE1D499ACD369D80B941367BE5BB88AF`。5次Image读取WARN与1退出ObjectDB警告，非clean。

只写新目录`game/data/maps/luoyang_estate_riverside_20261021ai/`内scene/layout/packet三候选及build mask；运行开关/manifest/连接未设。新mask未导入/晋升，不能启动正式新图。

Root随后唯一实际兼容渲染Sprite预览：console92516自然OS0、child121092，13真Sprite、1280×854、1486ms、来源同；PNG SHA `43583564E8BA6FF04B6F159FE5BED295FFFE8F10CB61AF35314059A07660F503`，report SHA `1640646B531A4AE1E4215A52F92C3875DAA0385FC1C47E90393FB55A66746776`。仅独立SubViewport裁图，不是Field/人物Physics/门往返。7退出Texture/RenderingServer ERROR，非clean。

Root/ART看过首图，明确艺术FAIL：1024px石带过宽、四树镜像且空旷、缺主厅/厢房/廊墙/花坛，不能部署或称完整园林。ART记录SHA `03D5DF3713A83E524F54CC74E2A0FD5B96EDF612F2146AA7E8BC3083DB785F94`。后继仅改地面：384px主路＋704×256门前庭，用原生材质分块而非非等比拉纹理，继承原6实体/4路线/完整mask，不重复2226采样。主厅、两厢、廊墙、低花圃仍是下一素材与布局工作，不拿告示亭或通用商楼冒充。

### 地面视觉后继及最终检查点

NEW `revision3_ground_visual_only/publish_and_preview_ground_visual_successor.gd` SHA `882CA7B3DADA22FFD797BD1CECBFD22C392000B0304991E46454BA70312071C8`，Root check-only自然0；唯一实际console119296自然OS0/child116964，1714ms、57真Sprite（44片64px原生前庭材质，不是44个实体）、scene/layout/packet完整读回与typed全逆通过。仅替两旧石带为384px路及704×256前庭，6草/5门树原行、6实体、原mask、四路线和2226旧几何证明全同，不重算mask/几何、不导入新PNG。

报告SHA `40E3387D1525B3EBF259FBF7555B8F91E7F555D9A0AFA6328000B975E7CF3005`，PNG SHA `B938F838E3B510B886708E9ADE2D2CC97CA94F2D8AACA33D61BA86F1169B42B1`；只写新build原生派生物，原91C9三native和首图保持。7个退出纹理/RenderingServer ERROR仍保留，非clean。Root/ART看过：尺度改善，但T形硬边、重复条带、镜像树与无主厅侧院仍为`NOT_READY_VISUAL_SCALE_IMPROVED`。ART记录SHA `C7853CDE93CD411B6E66FF129F5C7E498460F26701B4A3158F95020B2A54A1A2`，不部署。

QA按code-review只读核验6矩形同源进入mask/safe_body/generic layout.blockers，记录`FC9DDF0E…8807E5`；此为几何组件信用，不是Field真实碰撞、遮挡或门往返通过。新外场、Market25/37、三房返脚/归属、Router/source-index均未正式接好。

Root最终fresh2094：before `24D6D473AD2FED486C413CD2B0D407AD79B156A36BA5461530AFC9ACF6EBC637` → final `D99B40F75E6E48319DA83261208E0DBB0CAB0C91CFC519B72090258BED89781C`，仅tasks登记1授权差，余2093含15存档SHA/bytes/exactticks同，无意外变化。另当前56个实际source/artifact SHA逐一0差；仅用户editor51856和Ollama API100140保留，own引擎已自然退出，未代停用户。

检查点：`game/build/luoyang_city_completion_20261021ai_system01/CHECKPOINT_NOTREADY.json` SHA `60436A940A84F72F5275563F0CA31042D3026BAF19CD45BA71DD2D17E3C2B033`。正式仍ae，整城尚未补齐，没有新增加载指标。停止本批重复引擎检查；下一先按用户背景处理选择补齐两门脸、补宅园主厅/厢房/廊墙/花圃，再精确接两商铺/宅园和代表门往返；05+06街坊后续独立制作。
