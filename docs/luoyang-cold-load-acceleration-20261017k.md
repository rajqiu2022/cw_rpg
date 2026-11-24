# 洛阳首次加载有限并发完整校验 · 2026-10-17k

change-id: luoyang-cold-load-20261017k

目标：只优化首次进城的来源完整SHA阶段，保留j已正式暖返回、现役地图/碰撞和全部存档。现有普通22920实测首次35.259911秒；i分项显示624来源约2.92GB首轮7.603秒、末轮观测窗口约7.388秒，资源预读仅约0.214秒，不能把这些重叠阶段直接相加算完整耗时。

角色与写权：producer读审、备份、唯一引擎运行及串联；system只写独立文件Thread helper和C最小候选、必要新Temple依赖绑定；qa写30秒CPU正确性/取消与60秒真实624源并发选择键、120秒整轮/60秒到达的真实world96px→Space冷Gate薄键，独立审结果。

设计：原WorkerThreadPool协调任务不变，内部最多4个独立Thread，不向同一池排子任务再等待，避免池耗尽死锁。每lane独占FileAccess/HashingContext；原1MiB完整读、错误/长度/位置/32字节摘要门槛和合作取消不减。全部子线程join后才合并完整路径map；missing、任何读取失败或取消都丢弃整组，不出部分proof。真实同路径全集独立SHA比对并测1/2/4，实测后才选生产并发，不能先承诺提速。

读文件：C.TransitionSourceJob及其原owner/cancel/join调用、j完整普通result、Temple当前v4严格来源绑定。

允许写文件：独立helper、C的该job委派与新source叶、必要NEW Temple v5绑定及helper路径；测试与本专题/进展证据。不得改C其它数学/导航、Field/Router/LM/residentF173/11room开关、旧JSON和历史proof、素材/布局/玩家保存。

验收：CPU独立完整SHA map精确相等、0byte合法、missing整组拒绝、真实运行中取消与全join；实际冷进城首末完整当前source proof、Loading隐藏可动、原875/17与34×24物理及32px输入、一图和实际延迟。源/保存有限保护事实首末完整SHA/长度/精确ticks保持；原4.188GiB heavy门槛不减，不停止用户进程。当前无Godot、显存free7300MiB。

状态：已默认接入4线程完整SHA并通过一次普通入口正确性验证；**仅来源阶段变快，首次整场加载本次43.975秒，未改善且更慢**。不授整体冷提速完成，不重复暖返回/客栈/全城套件。code-review用于线程取消、失败关闭和资源释放边界审查。

## CPU阶段实测

最初fixture52648在收尾发生SCRIPT类型错误（同步base virtual `exercise`被async子方法覆盖的值域待查），35秒原外守卫精停own/OS−1，无result，不冒通过。NEW只读诊断65112自然OS0/1.238秒，复用原14夹具，exercise返回/await前后字典比较/保存比较均实际TYPE_BOOL true；不能据此唯一排除所有线程问题。旧A70F utility与原两测试、helper80B9均不改。NEW utility0017只明确base异步stub并记录收尾原始比较类型，两NEW执行键保持所有预算与判据。

fixture33324自然OS0/72检查/0失败/1.788秒（原30秒）：14文件141,558,001字节，各边界/零文件与2/4线程完整SHA map逐字同独立FileAccess结果；缺失、重复、空输入、非String、非法并发、预取消均整组拒绝。实际读中external2在4块后取消至全join6.897ms，direct4在8块后6.877ms，均0部分结果、全线程回收。18来源与15保存首末/current完整SHA/长度同，stderr空；result6B9223EF。这里只授CPU正确性/有限取消，不是Field提速。

真实全集103704自然OS0/1265检查/0失败/51.160秒（原60秒）：j普通真实Gate首末624源2,920,484,646字节，独立完整FileAccess SHA12.302693秒；helper1线程14.153775秒，2线程6.924077秒，4线程3.640226秒。三档逐路径完整SHA map、每次完整字节数/3277块精确同，全部线程join，末624源重新全SHA相同；15保存同/空stderr，resultE650A9E6。既定顺序先serial会预热OS缓存，不冒同冷缓存统计结论，也不把纯文件速度当完整入城速度。

Root选择4线程，SYSTEM准备NEW final helper（只DEFAULT2→4）与必要来源绑定；初80B9/9CA2候选与全部失败保留。待最小接入并跑一次真实world96px→Space冷进城→32px物理/1图，之后才报告普通完整加载收益。

## 默认接入与真实入口结果

Root精备C82DF/Temple9D0A全文于kroot01/deployment_before，默认发布helper80261E1B、C9CA2F461（仅job委派/新source叶三hunk）、Temple DE5E929F（仅两BIND常量）及NEW v5绑定17A38004。v5只改当前C SHA、加helper与原v4/B900依赖和说明；旧source_first/source_final、所有旧字段/艺术/几何/原JSON完全保持。residentF173/Field/Router/LM/11室内开关不改。

最终薄键C71CDF4E全文审/proper自然0，显存free7201MiB高于原4.188GiB，无用户Godot进程。唯一普通无args39608自然OS0，73.626秒/407检查/0失败，原120秒整轮/60秒到达不延。真实world96px/13原生Physics、解锁Area Space→Gate原1536/1860、Loading隐藏可动、32px/5样本、总20原生查询/1图FE6E6E、ownexit与lease释放通过。当前625来源严格等于独立j实际624全集仅C换新SHA+新增helper，完整首末proof与每个SHA吻合，不是计数通过；Temple单独当前源守护，不伪加Gate集合。

实际Space到隐藏可动为**43.975秒**，此前j为35.259911秒、i为36.057秒，本轮不能声称首次加载改善。来源worker帧观察窗口首3.740900秒/末3.883064秒，native source_start3.960秒（j7.338秒/i7.603秒），说明来源阶段改善；观察窗口不是纯哈希内部秒表，单次非相同OS冷缓存条件。其它未改阶段j→k：BASE CPU3.258→4.869秒，BASE main5.731→9.888秒，moduleCPU4.272→7.739秒，harbour1.359→2.685秒，navigation.374→.688秒，resolve_total23.320→31.392秒。这些重叠/包含式分段不能机械相加归因，更不能直接判为环境、热降频或helper争抢；原因仍未证。Gate等待采样最大帧gap3.477884秒，明显卡顿未解决。

Root/QA实看真实GPU图及完整结果3AE5E786；288自身源首末/current SHA/长度同，15保存同，完整日志52Image/7退出Texture ERROR/1ObjectDB/0SCRIPT非clean。最终502有限事实只C与Temple helper两处授权差，其余500（含15保存/project/resident/Field/Router/LM/原地图素材/旧B900）SHA/长度/精确ticks同，两个NEW正式源单独绑定，部署后0漂移，所有own引擎已退。kroot01/final_guard.json及execution_results.json保留全部正负证据。

只读事后CPU观察为i9-13900K/约7%总负载，电源方案“卓越性能”；非测试同时采样，不用于倒推测试时资源竞争，未更改电源/用户进程。此原子停止引擎复测。下一独立任务应查未改BASE主线程materialization（capture.object_mapping约2.09秒、tree.mesh约1.01秒、paving约1.02秒、ground_pixels约.892秒）和module CPU的重复工作；不把本轮正确性PASS冒成整体提速完成。
