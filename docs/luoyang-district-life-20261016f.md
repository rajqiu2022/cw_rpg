# 洛阳四区生活化配套 · 2026-10-16f

本批按分区空间与环境叙事设计制作，范围为南市、府衙外院、南城门、漕渠码头；不是全城艺术或十种组装室内完成。

## 实际变化

- 南市：增加货摊、成组货箱、灯树等12件陈设；原重复药摊换专用草药摊；新增10名居民，4名真实8帧行走、6名静驻，分布为买药、采购、店伙、茶客与过路人。
- 府衙：两处商铺式厢房换为封闭官署门脸；增加8件告示、灯树等配套；新增6名军士、书办及候事百姓，2名真实行走、4名静驻。
- 城门：增加11件路边候检、货物与灯树陈设，原城防、护城河、桥和10名既有来往NPC保持，不把普通民房堆到城门前。
- 码头：增加10件成组货物、摊点与灯树陈设；保留既有两种写实船、仓街、10名既有居民与原任务NPC。

合计41件新增陈设、3处门脸替换、16名新居民（6移动/10静驻）。不能把44条摆位或41件陈设计为44/41种新建筑。

所有新摆件都有实际底座，附加到原生物理和原行走守卫；旧NAV、门口、任务、奖励和BGM不变。低物件保留不透明，只用现有人物局部遮挡显示；高棚屋顶沿用淡化策略。东官署新图唯一显式绘制脚为[2610,1210]/.46，旧Scene/record/solid仍[2640,1210]，另加新可见底座，不缩人物或改原路线。

## 新素材与来源

仅2次内置imagegen首稿，无重试、无外部API或CLI兜底，实际模型未暴露记null。原图、完整提示词与生成结果：

- `assets/raw/luoyang_district_life_20261016f/official_service_annex_v1.png`
- `assets/raw/luoyang_district_life_20261016f/herbal_medicine_stall_v1.png`
- `assets/raw/luoyang_district_life_20261016f/provenance.json`
- `prompts/qa/luoyang_district_life_20261016f/`

两图1536×1024，透明A1尾迹保持原样，严格10%透明留边未达标仍记录FAIL。另4张既有素材同字节NEW别名，避免修改旧import。6张新目标均隔离import、23参数、完整RGBA核对；新增2张还做真实import/directCTEX全RGBA独核。生成图不声明为CC0。

## 有限验证与保留失败

- 发布110620：实际自然OS0，4472ms、12,130路线/NPC中心样本；独立CPU111920自然OS0、447/0、7513ms，同12,130样本，16新+20保留NPC路线、85保护脚点和边界反例通过。
- 首独立CPU85776整体FAIL保留。49784单点诊断确认矩形floor内点2241,1362被原生point-in-polygon误拒，mask全白、无solid命中；NEW测试辅助仅用精确矩形范围算术，不加epsilon，不修改生产几何、原路线或旧测试。
- 南市110080实际ready/785-source、新10人、4人各8自然walk帧、正常INPUT/Physics/原portal和总览通过，但测试错认为Router.reset会销毁当前Field，10条退出断言失败，整体FAIL不冲销。另做只离场验证，不重这些已过项。
- 城门98148自然OS0、242/0、37.665s；码头83680自然OS0、241/0、27.378s。均正常短INPUT、11次原生Physics查询、原入口可用及实际总览通过。
- 府衙54944完整结果318/0、46.333s、46次Physics、两张实图；新侧巷正常INPUT、新门脸邻空不误淡化与真实Field退出通过。进程gone，但45秒wrapper先结束，OS码未捕，不能记自然OS0。

四区截图Root与独立QA实看。测试用Dummy，不授音乐耳审。Image提醒及原退出纹理/资源/ObjectDB错误保留，不记clean。所有输出及精确源备份在`game/build/luoyang_district_life_20261016f_root01/`与`system01/`。

## 接入状态与待办

Root与独立ART/QA认可配套增量供试玩后，完整精备false源码7E8FA8C6，再仅改`FORMAL_ENABLED=true`，新R2CBEA52C、BIND8BCE/G C320/C82DF/Field5A89不变。南市最窄退出31068自然OS0、251/0、30.177s，真实Field退出/lease释放/10演员弱引用无效通过，110080整体FAIL保持。

四区无candidate参数、默认null出生均自然OS0：南市109020=241/0/30.864s、府衙69000=238/0/41.204s、城门98036=239/0/37.489s、码头107596=238/0/27.769s。累计956/0，各106来源首末和15保存同，均真32px输入/5步原生Physics/7查询、Loading隐藏/可动及真实Field释放，4普通出生PNG由Root与QA亲看。时间是整份验收脚本，不是纯加载耗时或冷提速。退出纹理/资源告警仍保留，各0SCRIPT，非clean。

古寺原binding保留，因C/Field两授权钩子变更，NEW依赖binding v2与Temple helper两行显式pin已接。只一次普通出生29668自然OS0、240/0、5.788s，114实际own-source首末/116追踪源、15保存同、1普通PNG通过，不重七站。

最终外部498条原事实仅C/Field/素材任务注册/Temple两pin四处授权变化，其余494条含15保存SHA/字节/exactticks相同；用户editor108140仍在，无停止用户进程。正式开关已默认生效，可重启普通游戏试玩。本轮不再自动重复功能组。

实机总览：[南市](../game/build/luoyang_city_life_gpu_20261016f/market/110080_2548/market_whole_layout.png) · [府衙](../game/build/luoyang_city_life_gpu_20261016f/yamen/54944_2426/yamen_whole_layout.png) · [城门](../game/build/luoyang_city_life_gpu_20261016f/gate/98148_2458/gate_whole_layout.png) · [码头](../game/build/luoyang_city_life_gpu_20261016f/docks/83680_2537/docks_whole_layout.png)。

仍待：大面积灰地变化、不同街坊的建筑体量与差异、院落花园、其余室内组装、首次加载性能。原府衙孤立烘焙树影未在本批消除，不以这批人流配套冒全城改造完成。
