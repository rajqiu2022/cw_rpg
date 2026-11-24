# 洛阳加载 o：转场尾段五组计时

change-id: luoyang-tail-profile-20261017o

目标：诊断 n 的3.204秒帧间隔，不混入算法优化或承诺提速。

背景：n最大间隔frame1667→1668跨C.activefalse→true，实际是transition proof发布附近里程碑。需分清Harbour导入读回/场景比较、导航提交、proof快照与同token重复比较。旧数据无法唯一归因。

写域：C+Harbour runtime仅计时scalars，记录至既有main_timings固定5行；Temple v9仅必要依赖SHA与旧v8引用/两常量。Source01候选先审不直接写现役；Root负责509事实保护、精备、部署与唯一引擎；system单写实现，QA单写薄键。

固定组：tail.harbour.import_readback / tail.harbour.materialize_serialized / tail.nav.commit / tail.proof.publish / tail.packet.validate。每组只同token/id/count/total/max usec和时间/帧边界，写前核captured token/id当前owner；失配静默不记，不影响错误/return。包含式分组不能求和。proof原字典表达式全文不拆；不增加await、删校验或改变调用次数。Router不改；同步/Web算法不变。

验收：一次普通无flags world96真实Space→Gate原出生/Loading hidden可动→32px/20Physics/1PNG/退出，原120whole/60arrival沿n bounded gap事件。读取同token的五组计时，整数非负/边界合理/count按原实际，不假定packet仅一次。完整625首末、像素/几何/保存检查全保；不重树/module CPU或暖/全城/室内。计时只是观测不授性能通过。

源码审完：C06244只固定5组token/id guarded scalar row，Harbour26E2只live两处timer，proof原字典全文不拆/原拒因与return/owner/await保留。同步/Web只有原算法，不混优化；固定计时最多5行，无Resource/Node/大字节日志。新Templev9 62D9只C现SHA替换+Harbour/priorv8追加，所有历史root/首末保持；helperA85A仅两const。

Root509鲜事实至部署前0差，精备三旧源全文后部署四候选，整SHA全同。509仅C/Harbour/Temple三授权差，余506保持；625原Gate source set只两实现SHA换，无增/缺，v9独立guard不伪加Gate leaf。普通执行键8F940BF6从7113 NOTREADY只固化ready/Temple双pin；沿n动作/bounded gap，不跑slice或新CPU。

GUIexe直接parse42496自然0/空stderr；唯一普通110208直接捕获自然OS0，526检查/0失败，whole44.116s，保持原120whole/60arrival。实际world96px INPUT/13Physics→原Area Space→Gate原出生[1536,1860]/Loading hidden可动21.837s→32px INPUT/5samples，合计20Physics及own Field/lease退出。Root与QA实看PNG02F73D，正常Gate无回退。

## 实际计时及边界

五行均为实际token2/SceneGate，原生15整数域与内部边界独审通过：

| 组 | 次数 | 总耗时 | 单次最长 |
|---|---:|---:|---:|
| tail.harbour.import_readback | 1 | 51,671us | 51,671us |
| tail.harbour.materialize_serialized | 1 | 6,942us | 6,942us |
| tail.nav.commit | 1 | 7,677us | 7,677us |
| tail.proof.publish | 1 | 63,553us | 63,553us |
| tail.packet.validate | 9 | 817,389us | 91,634us |

最大帧间隔1,664,372us：frame1336→1337，区间[37,248,663,38,913,035]us；C.activefalse/token0/空scene→true/token2/Gate，BASE/所有worker两端false。import结束37,248,613us，早于gap起点50us，不相交；materialize+commit+publish共78,172us在gap内。packet9次跨frame1337..1501，最长91,634us发生frame1501，不能把累计817,389us全算入此gap。未测到单次秒级组；不能将主停顿归因于快照、导航提交或Harbour比较，更不能断言某未计时函数就是原因。

下一最窄范围：C resolve尾余→Router `_go_field_from_portal_prepared` / `_prepare_joint_portal_arrival`（含`_fresh_source_portal_matches`的world Scene/layout完整SHA及CACHE_MODE_IGNORE读取）→`_go_field_smart_prepared`→LoadingManager.transition_to同步handoff。这只是未覆盖候选链，须分项计时后再决定优化；Field首setup出现在更晚边界，不能解释本次1336→1337 gap。不追加树/module/全城/warm/室内回归。

## 保护与证据

结果：`game/build/luoyang_tail_profile_gate_20261017o/110208_2574/result.json`，SHA80330EE8D1F48DA4539F3EDAAC28D916827960ACAAD51B6CA8E7F35CEC34FDAE。完整625来源仅C/Harbour两SHA换，余623同且无增缺；自身295来源首末及QA current相同，15保存首末及current不变。Root509事实仅C/Harbour/Temple三授权差，余506 SHA/bytes/exact-string-ticks保持，v9单核、部署后0漂移，own engines全gone。详`game/build/luoyang_loading_20261017o_root01/final_guard.json`及`execution_results.json`。

完整日志52Image/7旧退出Texture ERROR/0SCRIPT/0ObjectDB，非clean。本轮只接观测、没有加载算法优化；单次入场21.837s不作为较n38.017s的提速收益或冷暖性能结论。功能与计时完整性通过，加载加速目标仍待；停止o引擎复测。
