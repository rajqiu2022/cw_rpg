# 洛阳地图加载加速 · 2026-10-17j

## 本轮范围

先验证并接入一座洛阳外场的存活Field复用：出城到大世界，再回同城；以及原客栈出屋返回时只刷新发生变化的任务对象。只使用已有g加载候选，不启用十一种新组装室内，不改地图布局、碰撞和存档。

保留的必须是同一个已完成完整冷校验的Field/Scene/静态物件、纹理、原生身体、导航Image及街区会话，而不是复制一个资源缓存。最多保留一座外场，512MiB为纹理等保守估算上限，不是实际显存测量。正常编辑造成元数据变化或存活身份失效时，必须丢弃并回原完整冷链；缓存命中不称新鲜全磁盘SHA。

## 现有首次进入耗时证据

复用已完成的i实际96048，不额外重复冷诊断。Space到Loading隐藏且可动36.057秒；624个来源合计2,920,484,647字节。

| 阶段 | 本次已记录耗时 |
| --- | ---: |
| 来源首轮完整SHA | 7.603秒 |
| 来源末轮观测窗口 | 约7.388秒 |
| BASE纯CPU | 3.410秒 |
| BASE主线程 | 5.916秒 |
| 城防模块CPU | 4.307秒 |
| Harbour纯CPU | 1.386秒 |
| 13项资源预读 | 0.214秒 |

这些阶段不是彼此独立的总时分解，不能直接相加算比例。主要问题不是资源预读队列；再次增加预读并发缺少收益证据。后续冷提速优先考虑同worker内精确审批收据复用及有界2/4文件并行完整SHA，须保留原1MiB合作取消、全join、首末完整校验，另原子实施。

## 验证计划

1. 单g加载flag做一次世界真实Space进Gate、真实Space出世界、再真实Space回同Gate；160秒整轮、每到达60秒、第二次从Space前到Loading隐藏可动严格小于2秒。核同实例、导航/物理及10名ambient身份、没有新增冷任务；另核一次排队取消与末真实park/newgame释放。
2. 单独最小原客栈dirty返回，不启新室内；现场确定现役房间的脚点/身体域后验证，避免套用已过时的42偏移或零偏移假设。只修改测试内内存状态，不写玩家保存。
3. 通过后Root精备resident源码，唯一切正式开关并做最小普通验证。此前g其它新室内维持候选，不因本轮缓存通过冒称正式接入。

code-review限定本轮生命周期与来源失效边界。冷加载仍保完整校验；实际缓存与正式普通测试通过之前，不报告提速达标。

## 已完成的候选实际验证

- `test_live_city_world_gate_warm_key_20261017j.gd`（5D58）唯一54952自然OS0，72.662秒、461检查、0失败。实际世界96px输入→Space首次Gate35.617052秒→Space出世界11.767157秒→原入口Space回同Gate1.539164秒（包括Loading隐藏、可移动）。同一Field/Scene/Player、39组Sprite/Texture、38个身体、原导航Image/完整RGBA及10名ambient四个原生身份保持。没有新增冷任务或完整校验；排队取消保原世界、末真实park/newgame释放10名ambient通过。624来源首次完整校验继续绑定，暖返回不称新鲜磁盘SHA。回执980.243ms不拿来代替完整1.539秒。
- 原客栈1124自然OS1，652检查、2失败，原源8DC7及结果7FE1保留。实际1.113257秒返回、静态/导航/10ambient保持通过，但夹具把回执`ambient_preserved`当成实际保留人数；Field先把`ambient`数组赋给`_npc_nodes`，再追加8位投影NPC，两者共享数组，所以回执读取的是最终总人数18，而非保留ambient的10人。本轮不为修测试而改Field。
- NEW retry2（9CF5）只精确拆分该检查：按原任务投影9定义减去未满足旗标的1人得到8个实际非ambient ID，逐ID核同；另外独立核10ambient四身份、总人数与两个旧回执字段严格18、任务/旗标/学者进度对话及原735/864返脚。54848自然OS0，36.517秒、672检查、0失败，进入原客栈1.372657秒、任务发生变化后返回1.121217秒，16px正常输入/原生Physics与1图通过。结果AA9BAA48。十一新室内仍关闭，原客栈legacy origin/native42/visual80.287分别记录，不冒美术脚点改造。

候选前后502项有限保护事实（含15玩家保存的完整SHA/长度/精确ticks）零差。两成功仍有旧退出纹理ERROR、Image加载提醒；dirty退出另有ObjectDB提醒，不能称clean。Root已看两张真实GPU图，只授加载功能/现役画面保持，不授全城美术完成。

dirty retry2的JSON中`detail.ambient_before`与`DIRTY_CURRENT_STATE.ambient_ids`因引用同一字典并在cleanup.clear后序列化成空字典；**不能称JSON完整留存前后十人映射**。冻结源当帧严格四ID相等/10人断言实际0失败，`ambient_after`十人完整身份仍在。此记录边界不补造原数据，不复跑已过流程。

## 正式接入完成

已全文精备resident旧20086323到`game/build/luoyang_load_acceleration_20261017j_root01/deployment_before/luoyang_resident_field_20261016.gd`。独立SYSTEM只读源审与Root完整字节比对确认唯一正式改动为`LIVE_WORLD_FORMAL_ENABLED := false`改`true`，正式F1730E46/4912字节；其它全文、C/Field/Router/LM、布局/素材/碰撞不变。

无任何userargs的正式键9B3B，唯一22920自然OS0，69.561秒/455检查/0失败。实际world96px、13次Physics→Space冷Gate35.259911秒→Space出world11.474573秒→同Gate真Space返回1.527325秒（直到Loading隐藏/可动）；完整校验次数保持1、0冷任务帧，624源首末proof绑定新residentF173。原39组Sprite/Texture、38身体/导航Image及完整RGBA/10ambient四原生身份精确保持；原1536/1860返脚再32px输入5样本、23原生查询/1图9D53BEDF通过。Root及QA独立读完整结果29259D01/实际GPU图。284自身源首末/current SHA/长度零差，15保存同；53Image/7退出Texture ERROR/0SCRIPT/ObjectDB非clean。

最终502保护事实恰resident一处授权变化，其余501包括15玩家保存、project、原C/Field/Router/LM与地图/素材的SHA/长度/精确ticks全同，部署后无漂移，所有own引擎已退出。详`game/build/luoyang_load_acceleration_20261017j_root01/final_guard.json`与execution_results.json。重启普通工程后即可测试，不需加候选开关。

本轮停止重复测试。下一独立冷加载优化才考虑有界完整文件SHA并行与精确审批收据复用；首入仍35秒、出世界仍11秒，不把同城暖返回收益算作这些路径的提速。只保留最近一座外场，换街区/来源失效或游戏重启后仍走冷链；十一新室内另待验收，不在本轮启用。
