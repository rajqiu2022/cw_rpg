# 洛阳房屋间距与拼装室内接入 · 2026-10-17p

change-id: luoyang-building-spacing-and-interiors-20261017p

## 目标与边界

用户图中码头独立建筑的屋檐和主体明显交叠；需检查洛阳实际装配布局，而不是只放大碰撞通道。追加要求：正式建筑内部仍是旧整图，须实际接入底图与独立物件。

拆分：

1. System只读定位码头叠房，QA独立盘点城门、府衙、南市、码头、古寺的独立建筑视觉间距；故意城墙接门、同栋建筑组件不算独立房屋错误。
2. 对已定位问题准备最小重排：按完整屋檐轮廓保留可见巷隙，位置/物理底座/遮挡脚点/门口与任务通路同步；不改历史发布与proof、不缩碰撞来伪造通行。
3. 核对11类室内正式路由。当前十新房模块`luoyang_assembled_interiors_20261016g.gd`的`FORMAL_ENABLED=false`，只有已接入铁匠铺默认启用；候选CPU通过不能替代真实Field绘制与入口检查。先审来源与接线，再在关键实测通过后切默认。

本轮暂停加载尾段优化，不混改Router性能逻辑、世界地图、任务奖励或存档。不生成新素材；优先使用既有底图和独立家具。

## 当前实际状态

截图NPC称谓对应码头`docks_rope_carrier`、`docks_goods_broker`附近，Root/System/QA三方实看确认三栋独立房屋互叠：

| 房屋 | 原脚点 | 完整渲染尺寸 |
|---|---|---|
| 原北仓 north_canal_warehouse | 870,580 | 1099.88×549.94 |
| 新大仓 harbour_main_warehouse | 1450,650 | 952.32×634.88 |
| 右供货铺 harbour_quay_supply_shop | 1930,530 | 614.40×409.60 |

可见轮廓诊断（alpha>=8仅测量、未改图）：新大仓与北仓交叠约400.84×341.68px，与右铺约351.36×293.02px。不是只有阴影/AABB误判。去掉重复无门大仓后，北仓到右铺连全部A>0尾迹仍有117.50px水平缝；原北仓门754,610与NPC、任务、三新室内门轴都可保持。

Root批准只准备NEW source-bound撤仓child：完整父证明后只删除该唯一ID的渲染及六点solid，并由原raw_walk与剩余底座重建新导航；Harbour/District只显式适配新identity。不能只隐藏Sprite留下ghost collision，不能篡改旧93032出版或历史proof。现阶段候选制作中，未部署。

室内候选已有普通民宅、市场档口、书斋、客栈大堂、客房、药铺、布庄、当铺、仓栈、富家会客厅十种，另保留铁匠铺。十新房共59件独立家具（每房4–8件），旧铁匠6件。337唯一来源与11author核验0漂移。Root已看空商业shell及独立当票柜，不以原整图家具当组件。

最小候选包`game/build/luoyang_spacing_interiors_20261017p_source01/`：before B84FC5A6全文，candidate9E8E02AF全文仅一次bool false→true，Root已审完整diff；registry72555195不改。Router→C→functional→assembled_rooms→g路径优先于旧revision，同一个客栈/民宅ID换新room路径，并非另造不可达ID。Temple v9固定124源不含g模块，本bool不需要新Temple版本；不为形式凭空新binding。三新门仍需真实Space/Physics，十房实际图与代表遮挡薄键准备中。

Root新鲜保护815路径（含15玩家槽文件、509原边界和室内完整来源），9缺席均原save文件空位；路径事实保存在`game/build/luoyang_spacing_interiors_20261017p_root01/guard_before.json`。用户游戏仍在，任何后续用户存档变化均保留，不恢复、不冒整轮保存零差。

用户现有编辑器102696及运行游戏102312均保持；当前显存可用1417MiB。已请用户保存退出。在退出与显存恢复前不启动重GPU，不私停用户进程，不降低原4.188GiB门槛。当前只做源码/布局/来源核查与候选准备。

## 验收

关键点：修后叠房局部实际画面；独立屋檐间可见间隔；原门前34×24人物Physics可达与正确返回；十新室内真实Field具有空房壳和独立Sprite家具而非烘焙家具底图；代表低件/高件遮挡正常。复用已过CPU，不重复全城剧情或旧整套六槽，不将功能通过冒充艺术全部完成。

## 本轮实际结果与停止点

Root只运行不占重GPU的headless候选检查：108260 proper自然OS0/空stderr；首CPU11088自然OS1/2005ms，NEW helper误传四实参给实际三参`C._safe_body_cpu`，原源8E311与原publisher全文、FAIL结果和日志全部保留。System retry1仅四行五调用移除不支持的第四参数，原cancel检查不变，helper E74A2595；没有改原C判据、身体或预算。

唯一retry1 CPU67340自然OS0/3442ms（原60秒预算）：原父raw-minus-solids全RGBA重建精确；28→27只撤唯一大仓；33040像素从blocked恢复walkable，没有旧可走像素变blocked。保2739原路线/人群采样、46新恢复路径采样、2812 District组合采样/10底座与六移动NPC通路，原仓门754,610保持。新walk/layout/Scene/manifest已生成，**尚未导入新walk、binding仍PENDING、formalfalse、没有新画面或原生Physics信用**。2Image提醒，无SCRIPT/ERROR。

结果`game/build/luoyang_spacing_publication_20261017p/67340_1837/result.json`，SHA38844700A468CB966123926C694DAAE739458289650B4CDA0A04F972D1338DFD，103来源；walk SHA54F106D679B8B7DAC59077F9411988A164666B9D32EB8CD8A49A7DCD03CDFF12。CPU证明不是全城美术完成，也不是加载提速。

十房NOTREADY键A223148C已备，34392 check-only自然OS0/空stderr，180秒共享whole/每房60arrival、10图/59件实际计划，**未执行实际房间测试**。Root对Field pin误读Temple嵌套历史277B为current的质疑经绝对路径及815事实复核纠正，current真实638CD8，原QA pins正确、不造无意义retry。

Root末核815事实（含15save SHA/bytes/exact-string-ticks）0变化，所有旧生产源/素材/NAV保持。用户editor102696/game102312仍活，Root自有108260/11088/67340/34392均自然退出、没有私停用户。完整`final_guard.json`、`execution_results.json`与日志在p_root01。

下一必须用户保存退出并恢复原VRAM门槛，才做新walk隔离导入/冻结child binding及关键Docks实图/Physics、十新室内实际接入和三门往返。室内正式bool仍false；不得报告已替换或全部洛阳间距已修。其它区盘点详`docs/luoyang-building-spacing-audit-20261017p.md`。本轮停止追加引擎，等待用户退出。
