# 2026-11-01d 洛阳经堂、成人尺度与配对路口正式有限收口

状态：2026-11-02正式有限收口交试玩，停止引擎/成功路线复验。Root109688自然0、382检查0错/16INPUT，本次4条真实方向与1正常图通过；继承131104/25304各2条，合计**4pair/8条真实方向**，不是11pair/22端全部实机。Root亲看经堂前人物完整、完整五间寺堂等比与原门前接受；前05成人/mini有限接受继承，南口仍只授功能路口而非全ART。91216技术193/0但新堂遮人ART拒完整保留。最终guard158D1D01 PASS：134源=113原不可变+21独立后继，96现役叶/3额外runtime叶、171存档metadata精同/9缺席；只editor51856，0存档内容读写/反序列化/恢复。依据[标准S01–S07](../scene-art-quality-standard.md)。

## 原用户七项要求对应状态

| 原要求 | 本轮结果与准确边界 |
| --- | --- |
| 1 经堂像小民房 | 完整五间专属东经堂已采用，alpha可见950×486.724/门高约144.496；原门2220,2914、返脚2220,2990保。109688门前主角与僧完整，Root正常图有限接受；不是整座古寺重制。 |
| 2 岸驿卷轴疑似入口 | 该卷轴实为旧AdventureRuntime connector。古寺local入口改真实支路/近脚Space提示，古寺↔岸驿真双向已过；原World-origin岸驿进返事务保，不冒重跑World路线。 |
| 3 百工入口无法进入 | marker与trigger旧差82px、新口同脚；原Quarter准入旧3Regionpin另精修。131104百工双向真Space精落脚继承，不只扩大near；原点击派发保持，不冒22端鼠标逐一实测。 |
| 4 NPC成人偏小 | 六精ID配置、当场5resident；封砚秋原absent不补造。刀客实测132.000003、考官当帧134.955，目标约132非全员精132；原foot/body/业务/头像及可见条件保。前05正常图接受继承，不强拉坐姿/其它老人，不冒全六齐测。 |
| 5 出口像硬箭头、应读为路口 | 本批11pair同源口脚/方向/路肩/完整路牌与提示。正常南口仍是石地+路牌，Root只接受功能可读局部，**不授自然完整路口或全城ART**。 |
| 6 A↔B落脚方向需配对 | 11pair/22端静态合同含方向/固定安全落脚/返回。实际只4pair/8条真方向：南市↔百工、南市↔古寺、码头↔古寺、古寺↔岸驿；其余7pair未在本轮逐向新跑。 |
| 7 mini出口/建筑/服务应区分 | 同源建筑实景与出口/室内/服务语义标记已本批有限显示接受，mini只捕获新堂一次/过滤旧wing。原有主角头像保留，**不算本批新增头像功能**；不冒所有地图UI全验。 |

## 最终实际证据与守卫

- [109688实际报告](../../game/build/city_navigation_20261101d_residual06/actual/109688/result.json)：SHA`0864d5cad1295bc4d41512382b7ad03f78c38dbc44d23b87bc66d58a83765526`，382/0、16输入、4新真方向、4继承真方向、1新正常图；真实Docks consumer C2583/B接线成功，不用静态2562代替。该轮不重复前05成人/两已接受图。
- [修后经堂正常图](../../game/build/city_navigation_20261101d_residual06/actual/109688/temple_scripture_hall_front_people_normal.png)：SHA`25d7955c1885d1ca7d677664cf1ab715afca630411dfcebc00ac0337bd2f1d8c`；有效深度新堂265、主角273、守钟僧268，楼alpha1，人物在前完整。原后方Player maskedghost`.42`策略保留；这次不冒新增后方旅行验证。
- [最终03守卫](../../game/build/city_navigation_20261101d_supplement03/final_guard_ACTUAL.json)：SHA`158d1d015c3f6a3830eab97cbe36c50c71cb38d6186da31c34f17f267e98258b` PASS，Root批准auth`30868a03…`。直接继承原113final `fddbe8d354c0fce7b1b526ca3aa92ec02e2e80a6388a57f8d4d7a2470076ce77`，只一次最终171metadata pass；所有171精同、9absent，0真实档内容读/哈希/写/反序列化/恢复。Quarter两阶段、AC第三阶段及Art同key单行后继全双逆，distinct134不把子集重复算成136。

前述原113/96基线和所有早期FAIL/91216拒图不改写；02final和03备用capture未执行。旧7退出ERROR/ObjectDB及历史Image/WASAPI诊断保留，不称empty stderr。Root确认仅editor51856；下面制作/候选段落为**历史阶段记录**，不覆盖本节最终状态。

## 91216遮挡反例与精单行后继（历史拒证，109688已有限接受）

新quad用绝对z365，原`WorldContainer`祖先z=-100，主角/僧按相对footband参与却被减100；同样“365”不是相同有效深度。门前脚2990与2950本应在台基前，但被abs365压住；ghost又因脚在`FRONT`前方而正确早退，因此看不到头身。此为本轮引入的深度基准错误，不归咎于原人物大小或用户站位。[原拒图](../../game/build/city_navigation_20261101d_visual05/actual/91216/temple_scripture_hall_adult_scale_normal.png)与[原技术报告](../../game/build/city_navigation_20261101d_visual05/actual/91216/result.json)保留。

Root批准同`art01/live_art_view.gd`原path唯一`_quad.z_as_relative=false→true`，local365不变、SELF不变，不抬人z/楼透明、不改PNG/物理/门脚。E261全文[归档](../../game/build/luoyang_temple_adult_20261101d_art02/art01_E261_before_EXACT.gd.source)与[单行整文件双逆证明](../../game/build/luoyang_temple_adult_20261101d_art02/samepath_singleline_proof_READY.json)保；after`8B4D2413…`/22173bytes，显式96manifest`64B80A6D…→760534D8…`，同keys/仅该1leaf变化、其余95同。旧manifest[全文归档](../../game/build/city_navigation_20261101d_supplement02/manifest96_64B80_before_EXACT.json)，不是重置历史；独立art02path候选914D未作为production。109688门前原脚实际有效深度与正常图已关闭这项遮人bug，原后方`.42`策略保留但不冒本轮新增后方旅行验证。

两轮加载前置失败亦保：Quarter1282表只3Regionpin陈旧导致原工坊入口拒，Root先fresh2补采D834、精3+1修；后Docks AA/AC普通固定父C层仍锁旧F1，Root审核新固定字节逆层及既有EX AC1edge/机械source-map/index后继共21。21不交原113/96，含Quarter已修2项的第二阶段。fresh21/21全文备为9201D551、apply3CB1B016；最终03已验证Quarter两阶段，不跑会拒新after的旧supp01final，最终原113final只调用一次/171metadata只末次读。现158D1D01 PASS；02文件保未执行阶段历史；详[补充阶段计划与脚本](../../game/build/city_navigation_20261101d_supplement02/PLAN_PENDING_TARGETS.md)。

合后Root真实115984诊断AA author已成立，但actualC2583/expectedB2574，missing0/stale0/added9是原31e已准入的9Router历史snapshot。Ground精2第三阶段只在selectedACmanifest追加这9精键/保原2497值与其它JSON，ACindex只换manifestSHA；Root批准实际apply307CBE80，afterFA97DC9F/459BA3BD，原21/113/96边界不扩大。Root明确不再补03freshcapture，避免已授权apply竞态；以9201已固定stage2全文snapshot+3CB实际回执+Root核正式before建立1CE6/01FB→新after连续双逆。03capture脚本仅备用未执行，02guard/auth/preflight亦未执行未覆盖。最终03已逆这2至21after，再核21/Quarter早期阶段，最后只原113final一次；仍distinct134=113+21，非多加2成136。[03计划](../../game/build/city_navigation_20261101d_supplement03/PLAN_PENDING_TARGETS.md)保2583的实诊断与离线拟合边界；Root109688合后真实consumer与四新方向/堂正常图已过，158D1D01最终PASS。

## 新图正式采用 / 原制作处理证明保留

Root内置imagegen1次，无CLI/fallback/重生；model/provider/cost未公开，保持null，不冒具体模型ID。完整五间寺堂/牌匾/台基已Root与Art亲看：[prompt](../../prompts/city_navigation_20261101d/east_scripture_hall_v1.txt) SHA`23bd3f4d…`、[RAW](../../assets/raw/city_navigation_20261101d/east_scripture_hall_v1.png) SHA`82ff8ae6…`、[runtime](../../game/art/modules/city_navigation_20261101d/east_scripture_hall_v1.png) SHA`8bda9590…`。RAW1536×1024原字节保；授权框外A1仅清7291，四边64RGBA0至1664×1152，所有RGB/保护RGBA/全部alpha>1保持，无裁切/重采样。外灰主要A0隐藏RGB，不是应擦除的灰背景；更高alpha原边保。[逐字节处理报告](../../game/build/luoyang_temple_adult_20261101d_art01/media_ACTUAL.json)、[原图meta](../../assets/raw/city_navigation_20261101d/east_scripture_hall_v1.meta.json)、[统一登记](../../game/build/luoyang_temple_adult_20261101d_art01/asset_registration.json)。

真实可见主体alpha>128为1499×768，等比950/1499后950×486.7245；原生门洞手量约156×228→98.866×144.496（原像素landmark约±2px），不非等比压到560高。台基真实约842.262宽，不能假作710。新3rect闭合墙身保原2solid，原门2220,2914/返2220,2990不迁、其它Temple对象不移。旧1840直线现在穿新墙；1720/1740原本缺floor。有限静态原floor/全旧solid/新overlay已证可绕1536,3100→1640,3100→1640,2450→1800,2450→1800,2210；原门/钟调查/交纸末腿全脚保。首1640直北碰保留长案的[静态FAIL](../../game/build/luoyang_temple_adult_20261101d_art01/fit_audit01_FAIL.json)与[后继静态结果](../../game/build/luoyang_temple_adult_20261101d_art01/fit_audit_ACTUAL.json)分开保；非引擎或ART证明。

Root明确授权六名站立成人同样板约132：刀客、南市书生、大会考校官、封砚秋、牡丹诗会主持、军械铺掌柜；原两guard134.4不动，坐姿/其它老人排除。`live_art_view.gd`已由CityNavigationRuntime现役接入并独立冻结；原NPCNode继续动画/对白/方向/动态出生，显示calibration调整不重建body，foot/body/business/portrait/process保持。前05成人正常图接受继承，不把精六ID配置说成六人全部剧情状态/交互逐个实测。 实际证据为5resident/6配置ID，封砚秋原absent；刀客132.000003、考官当帧134.955，不冒全六齐测或全员精132。

图库制作时仅RAW/runtime2路径+2缩略增量5270→5272，当时登记为候选；本轮新堂已正式采用，以本节实际证据为准，旧元数据保持其制作阶段历史。旧5270record序列化前缀/非resources/旧cache成员精保、共享scanner未改，无全库build/scan。[增量证明](../../game/build/luoyang_temple_adult_20261101d_art01/catalog2_append_ACTUAL.json)。

## 原图精字节归档

以下副本均使用Copy-Item复制，源/副本bytes与SHA256一致；不重编码、不裁切、不清理。原文件均在 `C:/Users/rajqiu/AppData/Local/Temp/`，文件名为 `codex-clipboard-<UUID>.png`。

| 图 | UUID / 持久副本 | bytes / SHA256 |
| --- | --- | --- |
| 1 东经堂/守钟僧 | `92ca606c-0b96-43e9-8140-63040804c9a5` / [原图](../assets/scene-quality/20261101d/user-1.png) | 4684829 / `242fa85ebda55e5cefcfdb0984c6f13eab28ca47f60bda3012717b743782c324` |
| 2 | `f6736dc5-5ccb-4118-a54f-f997795f739a` / [原图](../assets/scene-quality/20261101d/user-2.png) | 2108866 / `867350ede474ae4ba26f9ce883ee25b0e5a0fff5ff78f3072646975a0713a0a7` |
| 3 | `2849a2c5-3242-4543-bbc6-77cdaff5a38a` / [原图](../assets/scene-quality/20261101d/user-3.png) | 4200221 / `0ffc3341c3eb8754b88389cde6cea4f1bf4af8c6ff12001a0f5c2a061ddb2655` |
| 4 南市刀客 | `5714afdc-b8d1-438c-9156-9f4de1660e69` / [原图](../assets/scene-quality/20261101d/user-4.png) | 2648510 / `0cb61c4d30a1f10f8e69cbb64d29f825801a29d31ea812f5a5949dacb5b6f35b` |
| 5 | `4102caa8-27b8-4c04-890e-bc3619dadae8` / [原图](../assets/scene-quality/20261101d/user-5.png) | 3082936 / `c41a66e1099faac994ace0bf737a64ccfbae68480ccf03d57c2eb4343d1a82e6` |
| 6 | `59972339-b827-49d1-94a1-b43c716392a6` / [原图](../assets/scene-quality/20261101d/user-6.png) | 11354305 / `5739f127662242a910627f0cd9165c7ba2b429da4b0e133cc95eb3d2f2b37423` |

## 东经堂：先换建筑用途与体量，不放大小民房

现役 `region_runtime_manifest_BUILD.json` 的author指向 `game/build/luoyang_yihongyuan_20261029n_system01/output/58540/regions_author_READY.json`。Temple binding为 `visual_finish04_BUILD/output/67124/luoyang_temple_region_27d.bin`（`70b37efd…`）。本轮未改这些源。

- 实际owner：`ch4_s4_ancient_temple/finish_i_temple_east_sutra_house`；作者plot明确使用 `game/art/modules/luoyang_estate_components_20261021am/wing.png`，不是专用经堂。
- `region_field.gd::_refresh_region_chunks`把compiled render实例化为完整 `Sprite2D`，不是切片墙或Polygon形变；原门深度child是 `RegionTempleWingDoorDepth`，不可在换主体后继续悬挂旧厢房门洞切片。
- 原图2202×1289，alpha>0 bbox `(367,215)-(1835,1074)`。render画布908.325×531.713，即等比0.4125；可见屋身仅约605.55×354.34。不能把画布908误当可见建筑宽。
- 旧钟经院lot：x1776..2816/y2304..3136，1040×832。Temple总界3072×4608。原门脚2220,2914/触发144×32，返脚2220,2990；原守钟僧2450,2950、长椅2340,3020；古钟plot anchor2290,2330/画布313.5见方。
- 必须保通的本地线：西侧x1840从y3100至2210；原东经堂末腿2220,3100→2220,2914；古钟调查从2220,3100经2744,3100→2744,2455→2450,2455。单把1200宽屋放原位会覆盖旧lot/侧路，不能宣称只视觉换皮无布局影响。

### 完整现货盘点与决策

| 完整候选 | 实际图 / 可见核心 | 判断 |
| --- | --- | --- |
| 古寺 `ancient_temple_assembled_20261016/temple_hall_v1.png` | RGBA1536×1024；alpha>128 bbox33,117..1503,881 | 三间正面寺殿，身份比厢房合适；但现正殿已使用0.7。复用0.62仅约911×474主体，重复正殿且有淡灰alpha晕，不能满足本轮明显五间体量要求。保为备选，不冒已采用。 |
| 宅院 `luoyang_estate_components_20261021am/main_hall.png` | RGBA2560×1072；alpha>0 bbox427,179..2133,893 | 仍宅院语汇，不为东经堂推荐。 |
| 华山 `huashan_map_20261029m/main_hall.png` | RGBA1924×1282；alpha>128 bbox278,344..1677,961 | 五间带偏厦的斜侧殿、门扇闭合；门轴与占地不合原点，不能直接放进旧厢房矩形。 |
| 古钟/残佛/整图背景 | `ancient_bell_v1.png`、`broken_buddha_v1.png`、古寺完整背景 | 前两是陈设而非完整钟楼/经堂；背景不得裁片冒模块。此次按相关完整建筑文件名/已知同风格目录查，不冒全图库穷尽。 |

Root决定生成新的完整五间经堂。下列为未实施的平面候选，须Root审核实际alpha/footprint与有限实机；不是已证明安全：

| 对象 | 候选世界参数 | 与原路/业务的关系 |
| --- | --- | --- |
| 五间经堂可见主体 | bbox x1820..3020/y2240..2890，1200×650；中央台阶前脚2420,2890 | 屋檐可越实体边，但不能以屋顶bbox设solid；扩大旧lot，不能隐称原布局不变。 |
| 地面墙基/门道 | 墙基候选x1880..2960/y2520..2860；中门开口x2340..2500延至门脚 | 必须按新图可见墙脚重新提outline，左右及后身真阻挡，中门净道保全脚。候选数值待新图，不把旧厢房solid原封当新堂。 |
| 东经堂原业务门 | 触发脚2420,2914，返脚2420,2990；target仍`temple27d_sutra_room`/原内脚768,1120 | 只移动此原门/末腿，业务、室内、门ID不另造；主横路y3100保。 |
| 西侧通路 | 原x1840保 | 与候选墙基左边40px，须全脚17×12及NPC体校核，屋檐遮挡另验有效z。 |
| 东侧古钟调查路 | 候选x3030或3040后接前庭 | 与世界东边仅32–42px，必须有限实测完整脚；新图若需更宽墙基应重排，不能抹掉路线。 |
| 古钟/守钟僧/椅 | 候选钟2740,3240；僧2740,3050；椅2780,3390 | 避新堂屋身和门轴，钟/僧对白业务保；需同步现役render/solid、NPC foot、调查末腿，检查原佛像/花坛等实际consumer，不先声称无碰撞。 |

### 图前历史规格（1200方案已撤，非当前采用参数）

新完整五间佛寺经堂，近正面轻俯视，灰瓦出檐、五间柱网、肃静经堂格扇与中央真实暗门洞、连续石台基与中央短阶；与古寺旧正殿同材质时代但更宽的五间横向比例，不画成放大住宅或正殿复制。全部檐角/台基/台阶完整，透明背景，无人、树、庭院、地平线、单独地面阴影板，不把地面画入可走场。

目标是**运行时alpha可见主体1200×650**，不是PNG画布1200×650；净门洞世界高150–165、宽150–165，成人128高可自然进入。可请求1536×1024或更大原生图，但实出尺寸不能当请求尺寸，须实量alpha主体/门框/底脚后统一等比定标，禁止非等比压图、切檐、裁总图或将门洞挖透明遮住人。中央门槛/阶前脚有明确像素坐标；屋身墙脚、屋檐投影、可走阶踏面分开交付/记录，以便同源NAV与有效遮挡。看一张带成人正常镜头样板后再推广。

## 南市：修前最后覆盖者与同因有限清单（历史测量）

`logical_terminal_projector05_pure_presentation.gd::_catalog/_display`先应用目录形象、专用覆盖及`source.npc_visual_scale`；其默认为1.0。`region_field.gd::_create_region_actor`映射scale到sprite_scale，再由 `logical_context_bridge04_pure_presentation.gd::configure_actor_before_ready`配置；`region_actor_visuals.gd`只覆盖古寺另一洞守者的图/头像，不改刀客。NPCNode::_ready之后`_apply_sprite_scale`是本次校准倍率最后实际执行者。11c gait只处理声明的巡行walk，不更改此刀客scale；11b seated/decor不拥有这些南市actor。

| 精ID / 当前来源 | alpha实际高度与最终结果 | 本批处理边界 |
| --- | --- | --- |
| `spar_luoyang_blademaster` / `npc_linxi_martial_hall_master_idle_down_25d_4f_v2_runtime.png` | PNG640×160，4帧alpha高均120；家族触发140px成人校准，但作者.82仍乘，120×(.82×140/120)=114.8 | 用户明确投诉。现脚2800,4240；只display目标约132，保foot、17×15半体、可切磋60:15、原头像/源strip、slot/交互。 |
| `luoyang_paper_scholar` / 专用`npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png` | 末级_catalog已替换旧waiter，160×160/alpha(57,24)..(104,144)高120；region27d_calibrate_adult=true+.82，同114.8 | 真正同因consumer，现脚5430,3010。只display目标约132，保文化/任务主行为及专用头像，不把旧waiter当最终图。 |
| `spar_luoyang_shen_guard`、`spar_luoyang_patrol` | .96×140=134.4 | 落本轮120–140范围，保留，不为凑统一尺寸改它们。 |
| examiner/封砚秋、诗会主持/军械掌柜 | 修前未校准旧.82机制：examiner strip alpha134..139→约109.9..114.0；merchant140→114.8 | Root随后明确授权纳入六精ID本批显示校准；原NPC/剧情可见条件保，不扩其它老人/坐姿。 |

两同因actor显示乘数若以114.8为输入，132/114.8≈1.14982578。应按实际当前sprite全局scale与alpha逐帧核值而非仅改 `sprite_scale` 属性（那样不会自动重算Sprite且可能改变锚）。独立display接入只对精ID/原纹理/原倍率/ground-anchored前置条件生效，保真实脚、body、prompt和名字关系；对白切图/动态出生后同样保持尺度，不能一进场大、对白后又变小。不重写NPCNode通用成人规则或其它场景业务。

## 本轮缺陷最终状态 / 原关闭条件

| ID | 状态 | 功能证据 | ART证据 |
| --- | --- | --- | --- |
| TEMPLE-01 东经堂身份/体量及本轮遮人回归 | 本轮局部已修/Root正常图有限接受 | 原门/返脚/compiled/旧2solid保，新runtime3实体及overlay；这项不冒本轮真入经堂内景往返另测 | 109688有效深度楼265/主角273/僧268+正常图完整；91216拒图保，非整寺ART。 |
| NPC-02 南市刀客及同因站立成人 | 本轮局部已修/正常图有限接受 | 六精ID配置/5resident，封砚秋原absent；body/foot/业务/头像/可见条件保 | 前05刀客132.000003/考官134.955当帧；不把160画布当身高，不冒全六齐测/全员132。 |

最初定位阶段曾是0引擎/0生产写；随后Root已按上述精授权正式接入。Art角色只处理新媒体/新helper和本地文档，所有引擎、生产合入及唯一最终guard均Root执行。当前停止复验交试玩，整城ART和未实测7pair仍不在本轮完成信用内。

## 11-01d 入口配对及 Docks 来源后继（历史过程，最终结果见首节）

本节为后续实际进展，前文“待实施/0旧源写”只描述最初美术方案阶段，不作为当前状态。独立 `CityNavigationRuntime` 已由 Root 接一行 autoload；本轮有限11条跨区 pair 使用同一端点数据约束实际触发脚、方向、固定安全落脚、返回关系、道路口与 mini 语义，保留其余建筑/剧情门、原业务锁及 World-origin 岸驿返回事务。实现位于 `game/build/city_navigation_20261101d_candidate01/`，不重写 Region compiled/旧 Router 的门户准入规则；原完整木路牌、同 UV 石路与有限全脚安全延伸用于路口，不能把裸箭头或一小块异材地毯当作完成证据。

原截图“百工箭头处点击仍须靠近”有实际几何原因：Civic `market_to_artisan` 的 trigger 在1700,4560，旧 marker 被世界边缘钳到4478，画面与实际入口相差82px。新口与交互提示同脚，仍使用原 Field 点击派发及同一 `_can_enter`，没有仅放大 near 范围、关闭碰撞检查或只修键盘。古寺卷轴是 AdventureRuntime 通用 `icon_scroll.png` connector，不是地上任务物品；本批把 local 岸驿入口改成真实支路与近处空格提示，原 World-origin 入口及返 World 流程不接管。11 pair 的精22端点及方向表以 `navigation_pairs.gd` 为准，不扩成所有建筑门重构。

### 已有真实成功与失败继承

- Root `114340` 首实机 ready/96源/22静态端点/Gate+Civic attach 已过；QA把单目标提示“空格 · 前往百工民坊”误要求包含整条 pair 标题，0输入失败。原整轮FAIL保留，不修改生产文案迎合错误 oracle。
- `123768` 真短S后百工口 can_enter、label、mini 已过，首次 Space 被原 `AP_QUARTERS.validation_begin()` 静默拒；不是新口距离或 v3 参数错误。Quarter manifest1282源全核恰3个旧 Region pin（Field53736563→FDB375D9、EntryED25FB74→E35CD056、RegionManifest749E8D4E→AF1BB975）。Root补采后只做该 manifest3值及 index单SHA后继，原1282键/其它1279值/所有其它JSON保持。
- Root `131104` 百工双向真实 Space 精落脚全过；后续成人图 QA 取刀客正南120点2800,4360，原 floor union 不支持，整轮FAIL保留。只读现役Civic E197C636 compiled 确认刀客实际2800,4240，东侧2920,4240全34×24脚/所有旧solid/NPC巡路扩脚安全；只改 QA 固定近点，原 actor/地形不改。
- Root `25304` residual03 自然1/144检查/8输入：Market↔Temple 两真向分别1536,304及3072,4366已过，累计百工与本 pair 四方向信用继承。其后 QA 公开请求 Docks 返回 accepted=true，但30s仍在Civic，因未记录异步 public state而缺少原错误证据；0图，原整轮FAIL与stdout/stderr/result均保，不将 accepted当加载成功，也不重跑这四个已过方向。

### Docks 真实拒因：AA 普通 C 前驱断层，早于4个 manifest 旧 pin

Root只读诊断01 `138260` 及独立诊断02 `113404` 均自然0、不发旅行请求。`113404` 的 [原报告](../../game/build/city_navigation_20261101d_docks_diagnostic02/actual/113404/result.json)证明：实际选中的是 AC workyard manifest（非 dormant retry2 Docks包），文件实际 SHA 与入口 `387CEBDE…C657EC` 精同；但 `B.manifest()` 在读取/承认该 header 前先调用 `_aa(id).author()`，其返回空，真实 C collector 因而为0。不能把 raw manifest 静态哈希审计冒充完整 C/B通过。

AA author22源只有普通 C 历史边不匹配：原期望 `C68272DD…`，既有逆链最外硬要求当前 C 等于固定29m `FINISH_C_SHA=F1C8DA74…`，而当前正式 C 已是 `7EC013FE…`。所以 `ordinary_c_source_admitted()` 立即 false，AA author空、B header空；错误早于 AC manifest 的4个旧值。AC原 author还继承旧AA普通边与已有DT approved链，不可通过跳过AA、直调 Router private prepared路径或放宽 ordinary/OWNED guard解决。

完整离线审查还确认现役 AC manifest 的 legacy2494源恰4个旧值：林西民房布局0F5FD386→已正式ADC0AFC3，以及上述3个Region源；runtime authority62与artifacts3本身精同。这些是旧已采用来源的精继承，不授权修改林西房屋或 Region 内容。诊断01重复连接toast的单个 QA-only ERROR保留；诊断02先 `is_connected`，不改旧 EventBus。

### Root授权的精21合入与有限闭包证据

Root评审后批准“当前正式 C→固定F1C8”的整字节逆层：仅为原普通来源证明在内存中恢复旧 bytes，当前 C/World16规则不改。AA增加该层并保留全部4个旧 C逆层；AA本体变化又由 AC增加“新AA→固定FE1D”的整逆层，保留全部4个旧AA逆层。AC本来就是 EX 的既有 OWNED键，因此只追加其1条完整逆边，不扩 OWNED，不修改任何其它 owner row，原 Router approved整链精同。

最终 [候选闭包](../../game/build/luoyang_navigation_docks_20261101d_successor02/candidate_closure_READY.json) SHA `1CA6D7CF…F13124`：沿既有33潜在域精算后仅21个实际目标——AA/AC两个普通逆层GD、EX一处既有AC edge、11个真实引用的source-map manifest及7个原index；排除其余12未变项，不盲写33源。新增必要runtime仅3叶：C整逆proof、AA整逆proof、AC owned snapshot，经原 AA/AC `source_paths`、EX source pins及受影响 B预期图有限接入；snapshot使用原EX要求的 `res://build/luoyang_` 命名，没有放宽目录guard。旧 author JSON、旧proof文件、payload/NAV/媒体不改。

离线虚拟合入核验：selected AC三个顶层预期map合计2562项/Gate1722项/Quarter1285项全SHA无差；这不是合后真实 C collector计数或功能通过。两新逆层、旧C四层最终C682、旧AA四层最终13D90、EX新增AC edge的完整正逆均精同。Quarter由补充01的1282源后继到本闭包1285源，增加的是上述3个精runtime叶，不得倒写补充01的历史键数。

Root fresh21 capture `9201D551…43C392` 已有21全文备份。Root随后明确授权本角色合入：实现AA/AC两GD用 `apply_patch`，其余19个已审source-map/index候选用原生复制；[实际合入回执](../../game/build/luoyang_navigation_docks_20261101d_successor02/apply_ACTUAL.json) SHA `3CB1B016…E40491` 记录21实际after SHA/bytes全部匹配、从实际after精offset整逆回Root备份并正向恢复精同。21目标与原113/独立96冻结叶交集均0；C7EC013FE、RouterA93F4CAC、RegionFieldFDB375D9/EntryE35CD056/ManifestAF1BB975及10bin实核精同。原113/96/171save基线未重写，本角色0引擎/0存档内容或metadata读取；Root并行的新堂遮头helper后继属于另条显式授权，不回滚或借本回执接纳。

**后继已由Root109688完成Docks↔Temple/古寺↔岸驿四真方向及修后经堂正常图，382/0/16INPUT/自然0；最终158D1D01统一guard PASS，停止复验。**百工/MarketTemple四成功方向按原报告继承，累计4pair8真腿。115984实际C2583比B多9历史snapshot的精2第三阶段已按本篇前段补齐，不用静态2562冒实际collector。旧FAIL、WASAPI及既有7退出ERROR/ObjectDB/Imagewarnings保，不冒11pair全实机/全部洛阳ART/旧World矩阵复验。
