# 洛阳建筑与室内素材缺口审计 · 2026-10-16

## 结论与范围

本次为只读库存／分区设计审计，不是新增美术、正式扩建或实机验收完成。未运行引擎，未修改生产、素材、导入、测试或玩家文件，也未扫描整个 build 目录。

当前正式洛阳不能证明已有“建筑种类超过10、室内类型超过10”。去掉同图重复实例和墙、树、灯、摊位后，核心主建筑约5个功能家族：城门、府衙主厅、客栈、普通商住街坊／商铺、仓库。院门和角台可以登记为附属构筑物，但不以此凑主要建筑种类。

现有9份独立室内定义，实际上只有3种模板；正式runtime启用8处房门，西南街面中央立柱假门已禁用。资源定义数量、启用门数量、视觉模板数量、已实测往返数量必须分开。

## 1. 当前正式链与真实数量

四区canonical入口：

- `game/data/scenes/ch4_s0_luoyang_gate.tres`
- `game/data/scenes/ch4_s1_luoyang_yamen.tres`
- `game/data/scenes/ch4_s2_canal_docks.tres`
- `game/data/scenes/ch4_s3_luoyang_market.tres`

不能只看上述TRES的旧layout：正式效果还消费原C层、Gate城防第三层，以及南市／码头第四层。第四层选择与房门白名单见 `game/art/maps/luoyang_city_revision_runtime_20261015/bindings.json`；默认已开启，不代表原候选出版manifest中的历史PENDING字段被改写。

| 范围 | 实际可核事实 | 不能推导的结论 |
| --- | --- | --- |
| 南城门 | 城防manifest含28物件，主门、侧墙、角台、桥、树灯和货摊等 | 不是28种建筑 |
| 府衙 | 主厅、南院门、围墙、公告亭等；base对象名 `court_southwest_wing`／`court_southeast_wing` 使用的是 `native_wall_horizontal.png` | 两个wing名字不能算两座真实厢房 |
| 南市 | 第四层26物件；4个ward frontage共用 `street_row.png`，巷口摊继续复用货摊；现12门户／8启用房门 | 不等于26种建筑或8种室内 |
| 码头 | 第四层21物件，仓库、南街面、码头、船、箱、栏杆等 | 船、栏杆、箱不算建筑类别；旧船外观未升级 |

主要可核清单：

- `game/art/maps/luoyang_gate_fortification_v3_refined/runtime_manifest.json`
- `game/art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s1_luoyang_yamen/art_contract.json`
- `game/art/maps/luoyang_enclosure_v11/ch4_s1_luoyang_yamen/art_patch.json`
- `game/art/maps/luoyang_city_revision_retry2_20261015/ch4_s3_luoyang_market/candidate_manifest.json`
- `game/art/maps/luoyang_city_revision_v1_20261015/ch4_s2_canal_docks/candidate_manifest.json`

NPC方面，canonical定义分别为城门1、府衙3、码头3、南市8；码头runtime新增真人漕工头领，合计16份定义。失踪／获救脚夫共享位置并受互斥剧情条件控制，其他角色也有显隐条件；Field还会追加BountyManager动态NPC。因此16定义不代表默认同屏16人，更不能借历史其他测试的总节点数宣称当前城区人群密度。

## 2. 可复用外观与伪库存排除

| 资产 | 真实路径 | 状态与适用边界 |
| --- | --- | --- |
| 城门构件 | `game/art/maps/luoyang_modular_v3/source/south_gate_v1.png` | 已有生产链引用；连同独立城墙、角台使用，不变成普通住宅 |
| 连排商住街屋 | `game/art/maps/luoyang_modular_v3/source/street_row_v3.png` | 已有；四次摆放仍是一种连排街坊视觉 |
| 客栈 | `game/art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s3_luoyang_market/entities/inn.png` | 已有；与客栈厅堂匹配 |
| 普通铺面 | 同上目录 `shop.png` | 已有；当前进入书房，不是已完成的专用商店内景 |
| 货摊／药摊 | 同上目录 `goods_stall.png`、`medicine_stall.png` | 已有摊位，不冒完整书肆或医馆建筑 |
| 府衙主厅 | `game/art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s1_luoyang_yamen/entities/magistrate_hall.png` | 已有；已亲看主厅形态，但没有因此获得审案大堂室内 |
| 货栈仓库 | `game/art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s2_canal_docks/entities/north_canal_warehouse.png` | 已有；已亲看宽门货仓形态，尚缺匹配可入仓内景 |
| 独立小院住宅 | `assets/raw/luoyang_city_candidates_20261015/two_bay_residence_v1.png` | 已有候选，SHA前缀C64B40CA；亲看是院门＋正房，不是豪宅。provenance注明软alpha／边距待审，未导入、未有运行脚点／阻挡合同 |
| 旧小屋 | `game/art/modules/prop/prop_zhuwei_cottage_25d_v2.png` | 存在且亲看；侧转镜头与洛阳正面构件不同，不能沿用旧猜脚点直接接入 |

必须排除的“看文件名就算建筑”：

- 亲看 `game/art/modules/building/building_11.png`、`building_15.png` 是植被裁片，`building_12.png` 是窄石条，`building_16.png` 是近黑裁片，不能算四种楼房。
- `game/art/modules/building/build_linxi_smithy_front.png` 确有PNG，但亲看为低清拱窗／夜间火光旧风格，与当前洛阳正面写实模块不匹配。只能当旧参考，不能称合格铁匠铺已齐。
- 完整旧城背景如 `game/art/backgrounds/bg_ch4_luoyang_yamen.png` 可作布局气氛参考，不能直接把其中所有房子当独立可摆放、可淡化、可进入模块。

## 3. 室内库存与外门匹配问题

`game/data/maps/luoyang_home_candidates_20261015/home_author.json` 的9室实际分布：客栈1、书房4、小宅4。SW小宅门禁用后，启用8门对应客栈1、书房4、小宅3。

| 真视觉类型 | 背景PNG（均位于 `game/art/backgrounds/`） | 当前资格 |
| --- | --- | --- |
| 客栈厅堂 | `bg_interior_inn_hall_v1.png` | 洛阳已接入，已关键实机往返 |
| 小宅起居 | `bg_linxi_farmer_cottage_25d_v2.png` | 洛阳已接入，NW门已关键实机往返 |
| 大宅书房 | `bg_linxi_scholar_house_25d_v2.png` | 已作为洛阳模板；不是豪宅正厅、医馆或仓库 |
| 医馆／草药诊堂 | `bg_linxi_herbal_home_25d_v1.png` | 现有图，亲看有药柜、诊床、药材。可借改造，不是已接洛阳 |
| 私塾课堂 | `bg_linxi_south_classroom_25d_v1.png` | 现有图，亲看有成排课桌／讲台。可借改造 |
| 武馆练功厅 | `bg_interior_martial_hall_v1.png` | 现有图，亲看有武器架、木人及训练空地。可借改造 |
| 官署文案／审印室 | `bg_ch7_mingwu_seal_audit_room_gameplay_v1.png` | 现有图，亲看有案桌、印柜；镜头／风格与原剧情需要重新净化适配，只计一种文案工作空间 |

因此可供借用的独立功能视觉约7类，但只有前3类已作为洛阳模板；不能把“库存可借”写成“7类洛阳室内已可玩”。英雄卧室只是已有民宅／卧室家族的变体，不为凑11再单列；地下洞穴档案室不冒城市货仓。

当前匹配缺口：普通shop、north_market_front、southeast_market_front、market_east_ward_frontage都进入large_study。若外面标的是药铺、书肆、军械铺，内景就必须有相应药柜／售书柜台／兵器货架和功能NPC，不能只是换入口label。独立room ID解决返门归属，不会自动产生新视觉类型。

所有借用室内需保留原PNG与旧场景，复制净化新定义，去除原Linxi／章节NPC、任务、loot、hide_flag、剧情对白与旧出口；每个洛阳外门明确自己的return foot。已有模板是legacy body-center，设计1536×1024在1920视口cover为1920×1280，不能把原生34×24身体／+42偏移也乘1.25。

## 4. 可实施扩建分区与目标类型

以下是建议目标，不是已完成资源或已批准坐标。先做地块／道路／功能表，再生成缺失资产；不在同一空地上追加一圈同款楼。当前C.SIZE和相关来源／875／4px路线合同固定3072×2048，不能为扩地随手改尺寸常量。第一阶段优先在四区拆减重复街面、替换成不同功能地块；空间不足时再显式设计新增街坊Scene与新合同，不把房子和人物缩小塞进去。

| 区域 | 目标外观类别（跨四区至少13种） | 外门与内景 | NPC与空间组织 |
| --- | --- | --- | --- |
| 南市 | 客栈、独立民宅、药铺、酒楼、书肆 | 客栈→厅堂；民宅→小宅；药铺→诊堂；酒楼→独立酒楼堂；书肆不能继续借大宅书房冒专用营业空间 | 建议新增8个市井角色，分在售货点／门边／街口，不列队站广场；客栈街、商贸街、住宅巷分开 |
| 府衙 | 官署、豪宅、私塾 | 官署主门→审案大堂，侧门→文案室；豪宅→正厅＋后院／书房；私塾→课堂 | 建议新增4角色：书吏、衙役、访事人、教书先生；官署轴线与富宅／学舍各独立地块，院墙内留园林与回廊 |
| 码头 | 仓库、铁匠作坊、行会会馆 | 仓门→货仓；作坊→炉砧工坊；会馆→议事／接待空间，复用大厅时不额外算新室内类 | 建议新增5角色：搬运、账房、船夫、匠人、行商；临水装卸线、仓院、作坊沿街分开，不堵渡口／漕工旧任务口 |
| 城门 | 城门楼、驿站 | 城门仍接官道／内城；驿站→接待厅／驿卒住宿，可复用已区分模板但不虚增内景种类 | 建议新增3角色：卫兵、驿卒、入城旅人；保城防＋护城河／桥，不在城墙脚塞一排民宅 |

建议新增20个常驻市井角色是配置目标，不是同屏承诺。已有真实素材可借：`game/art/characters/npc_linxi_farmer_idle_down_25d_4f_v1_runtime.png`、`npc_zhuwei_inn_waiter_idle_down_25d_4f_v2_runtime.png`、`npc_zhuwei_merchant_idle_down_25d_4f_v3_runtime.png`、`npc_zhuwei_crying_woman_idle_down_25d_4f_v2_runtime.png`，以及street_expansion商人／护卫家族。只能复用相符身份，不能用绑缚村民当普通行人，或所有男女老幼都套同一商人脸；可见身高按真实帧非透明像素校准，不只统一scale。固定点角色可先落地，动态路线须另授正常导航／避让，不冒已有walk四向齐全。

空间门槛建议在绘制前由主控冻结：主街约200–260逻辑像素、巷道120–160像素、独立地块留约80–120像素空隙；这些目前是设计建议，不是已测硬阈值。应以投影后实际可见轮廓／屋檐和物理基础检查净距，而非只比两个foot点；连续街屋只在明确同一连排模块内允许贴接。相邻地块不能屋顶叠门、民宅压仓门、树墙堵正面。不要再次把inn与NW后排街屋的屋顶投影挤在同一区域。

## 5. 必须补作的资源，不伪造现成

外观目标13类中，现成可借的核心是城门、府衙、客栈、仓库四类；独立小院只有待审候选。药铺、酒楼、书肆、真正豪宅、私塾正面、合风格铁匠作坊、行会会馆、驿站尚无本轮证明可直接采用的专用外观，须新作或明确模块化重构。不能仅在同一shop PNG上换匾额就算全齐。

室内可把上述7类可借视觉作为基础，再至少新增5类真布局，形成12类目标：

1. 府衙审案大堂：官案、两侧差役位、听审区，不用普通书房冒大堂。
2. 货栈／粮仓：货架、麻袋、装卸通道，和书柜档案室区分。
3. 铁匠工坊：炉、砧、工具、成品架、工作安全区域。
4. 豪宅正厅：完整礼仪会客尺度／屏风／侧房组织，不把普通小宅放大。
5. 酒楼营业大堂：酒柜、客桌、出餐通道；和已有客栈厅堂需有可见布局差异，不只是换色命名。

专用书肆可以在后续增作，不能拿现有large_study只换名算第13类。庭院／花园本身可作为区域层次，但不自动算一个室内模板。

## 6. 来源与“授权”边界

`assets/catalog/luoyang-assets.json` 是20条试点登记，不是全工程素材许可审核。其现役adopted只说明工程引用；城门、客栈、街屋、府衙等多为项目生成／派生，来源 `game/art/maps/luoyang_modular_v3/source/generation_record.json` 明确 `original_not_cc0=true`，不能统一写成CC0或已审商用。

已有外部授权证据主要覆盖Poly Haven石材、部分植被／树竹派生，不等于有一套现成11种中式建筑包。`game/art/external/opengameart/yughues_bamboo_v1/` 下保有许可文件；石材／树木许可不能传递给混合生成建筑。

`assets/raw/luoyang_city_candidates_20261015/provenance.json` 记录小院和船由真实builtin生图产生，工具未披露model，不能写gpt-image-2／特定provider；其状态仍candidate_only_not_imported_or_adopted。新资产必须逐项记录来源／原图SHA／可用条款证据／风格与sprite合同，未知保持未知。

## 7. 最小关键验收方案（待实现后另授权，不在本轮运行）

- 数量用semantic building type／interior template清单核对：外观功能、轮廓和内布局确有差别；相同PNG／同SHA副本、同模板不同ID、换label／颜色不增类型。外观与内景分别达11以上才授用户数量要求。
- 出版前做四区分块总览，核地块、主街、庭院、屋顶投影与门轴；先看不挤、风格可辨，再做有限实机，不用巨大测试框架代替视觉审查。
- 所有新房门CPU检查原875整鞋、17点、全部物件solid与≤4px公开路线，门、NPC、交互不互抢；新增室内各做出生→功能点→出口路，源和导入完整RGBA及正确cover坐标绑定。
- 实机只选本轮新形态的代表：独立宅、专用营业空间、豪宅各一次正常approach／Space／室内行走／Space精确返原门；同模板额外房门做数据绑定／CPU闭包，不自动整夜重跑全城全六。
- 各代表同帧核门前不淡化、屋后.55→回前1、Collider物理底座与可见脚点一致；新增NPC看实际可见像素高度、旗标显隐和真人交互目标，不让箱子代替人或NPC埋在屋顶。
- 保留924来源闭包经验：新图、.import、.ctex均显式入首末保护；玩家15保存／精确ticks与旧资产不变。Loading public接受／ready与取消恢复沿既有严格合同，不能因扩建回退成同步长卡或吞掉验证。

本审计只给真实存量、缺口和实施建议。正式四区、当前Loading成果和历史失败保持原状；扩建接入须主控逐阶段批准。
