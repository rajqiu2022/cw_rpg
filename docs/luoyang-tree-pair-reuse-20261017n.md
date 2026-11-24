# 洛阳加载 n：同次树模型复用与卡顿现场记录

目标：消除live树模型已完整验证后再次CACHE_IGNORE加载同两资源；补有界最大gap现场，不能事先宣称解决m最大1.689830秒停顿。

证据：m tree.mesh514073us，第二次tree.load263508us，中间有yield。旧_busy只保最大gap数，没有时间/帧/前后阶段；arrival仅状态签名变化记录，615帧跨17.595秒不是单帧停顿，不能拿累计stage推唯一归因。

写域：Original checker live-only持有首次成功pair；Note/BASE仅pin，Temple NEWv8仅必要current3SHA与priorv7/两常量。C/m四源/workspace/Field/Router/Loading/resident/素材/布局/保存不改。Root精审备份接入/唯一引擎，system候选单写，QA薄键单写。

验收：独立GUI glcompat slice30s做真实树Mesh全ARRAY_MAX/材质Texture全RGBA与mip/实际实例引用/错误不产pair与取消释放，不在冷Gate同进程预热。之后一次普通无flagsworld96 Space→Gate原出生hidden可动→32px/Physics/1图/ownexit，原120whole/60arrival/625完整首末保留。新增maxgap诊断只新max且有界小标量；仪器变化公开，不把跟m的单次延迟差冒严格因果。所有原失败/退出告警保留。

508鲜初始事实含15保存、Stable与v7。候选FB11/Note3B07/BASEEE8F/Temple0538+NEWv8F8FE已Root全文diff审：Original仅live tree可选输出首次实际Meshpair，所有原几何math块完整；同步/其他调用默认null仍旧流程，9保护函数保持，三处owner/yield及每个出口local.clear保留。Note/BASE仅固定SHA，v8仅既有3currentSHA改+priorv7追加，历史root/firstfinal不动。生产仍未改。

首slice B99347D7已GUIexe parse11088自然0/空stderr，唯一实际24564自然OS1、65检查/2失败/6.584秒（30秒未超）。结果22DF8DBA保留：旧sync树和新live完整几何/映射/材质流程均返回空error，新tree.load观测27us；额外依赖guard错误假设所有纹理import均`remap.path`，实际树branch_arm_1k只有合法`path.s3tc`，编译源校验断言拒。第二末断言是complete=false，不是超30秒。该局部成功不冲销整组FAIL或授正式。

NEW QA薄键AC83CFAC只修合法import表示，显式精确source_file/type/单remap/dest_files与既有m625实际ctex SHA绑定，不省compiled判据；旧测试与失败结果不改。Root parse58188自然0/空stderr；GUI57656自然OS0、184/0/8.223秒，结果AAC57405。真实旧sync/新live完整slice error同空；全部原数组slot、材质全RGBA+mip、首次pair同ID交接、伪path/ID拒、同计数vertex差异错误同且无pair、实际mesh后取消及显式test holder清理弱ref通过。内部locals不可直接weak-observe，实际cancel返回与源审local.clear为有限证据，不冒0泄漏。

24自身源首末与独立当前SHA/bytes同，15保存同；7旧退出TextureERROR/0SCRIPT/Image/ObjectDB非clean。new retained load26us是局部观测；旧sync1.421377秒/新live含yield2.322871秒固定顺序，不是速度基准。禁止用26us冒全链收益。

508鲜guard到部署前0差，Root精备四旧脚本全文，部署OriginalFB11/Note3B07/BASEEE8F/Temple0538+NEWv8F8FE五整SHA全同候选；508仅四授权源变化，余504保持，m四源/C/Field等不动。普通键7F17从F4F6 NOTREADY只固化ready/结果path/SHA；新增maxgap每域最多一条小标量事件，明确非原m相同仪器。Root GUIexe parse71140自然0/空stderr，唯一普通108616按原120/60运行。

## 最终：局部复用正确，整体提速未达成

GUI108616直接持Process，已捕自然OS0；425检查/0失败/68.825秒，result `game/build/luoyang_tree_pair_cold_gate_20261017n/108616_2528/result.json` SHA `8F54A420BF0C46FF5AF899129A1C604A077D419A6C394EFB3B64348840A9C0DE`。真实world96px/13Physics→解锁Area按Space→Gate原1536,1860→Loading隐藏可动→32px/5样本，总20query/原NAV/ownField退出/lease释放通过。625完整finalized source与m逐path比较仅Original/Note/BASE三SHA换，余622（含m四源）同，无增/缺；295自身源首末及独立当前SHA/bytes同，15保存同。PNG456A6384已Root/QA实看正常门前人群/出口，无回退world。

**首次入城本次38.017秒，比m22.952秒更慢，不授整体提速。** tree.load19us确认不再第二次加载，但tree.mesh867544us与材质86858us仍完整执行。其它未改source首3974ms、BASE CPU5202/main8345ms、module2755ms、harbour2752ms、resolve25348ms也比m慢；没有现场因果证据，不凭此归环境、树复用或新诊断。原最大1.69秒没有事件，新仪器也不是严格相同对照，不能用单次差异承诺固定收益。

新增有界事件把本次最大3204269us限定在frame1667→1668、observed57264202us：C activefalse/token0/空scene→active/token2/Gate，前后BASE与所有worker均false、sources_finalizedfalse。仅能将下一排查圈到完成返回/receipt发布附近的同步间隔，不能唯一归给某个函数或称最大卡顿已解。不补造m旧事件。

最终508事实恰四授权旧源差，余504含15保存/世界/素材/布局/m四源/project等SHA/bytes/精确ticks全同；对部署后0漂移，NEWv8另核F8FE，全部own引擎已退出。52Image/7旧退出Texture ERROR/1ObjectDB/0SCRIPT非clean；首24564失败与AC83修夹具记录全部保留。证据在 `game/build/luoyang_loading_20261017n_root01/final_guard.json`、`execution_results.json`及完整日志。

保持此正确局部复用接线，停止n重复引擎验收；源码复审没有具体需回退的正确性风险，不以整场变慢推定pair有害。下一仅转场尾同步间隔细分，不扩全城/暖返回/十一新内景或修改用户环境，不把未达整体提速写成成功。

下一范围已由只读源码收敛：`active`定义为`_transition_validation`非空，live完成处的整条snapshot赋值使其变true。只量①Harbour join后的实际导航Texture读回/fullRGBA；②Harbour materialize/Scene CACHE_IGNORE载入与完整serialized_equal；③C `_revision_commit`的record/25MB mask/solids提交；④C transition_storage深拷贝/record-solids副本/mask SHA及Router同token重复比较。这四组无现成独立计时，不能直接删检查、转线程或把帧间差值唯一归某组；前后worker false也不等于间隔内从未有worker/回调。
