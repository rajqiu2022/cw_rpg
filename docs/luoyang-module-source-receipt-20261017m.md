# 洛阳加载 m：Gate module 来源收据复用

change-id: luoyang-module-source-receipt-20261017m

目标：只消除 Gate module 在同一次完整来源首检之后的重复 SHA 读取，保留首末完整625叶校验、审批域、图像/几何与同步行为。

背景：l 普通首次到可移动24.705秒，其中 module CPU4.258秒。静态成功路径至少重复读776,303,462字节；这是读取量，不代表整个4.258秒都能省掉。

角色：producer 负责源审/保护/精备/唯一引擎/接入；system 产四实现源候选；QA 产旧新等价和失效检查。禁止各角色私跑引擎或越权改测试通过。

读文件：C、module CPU、Gate contract、stable-import helper、BASE workspace、l实际结果、旧v6依赖。

写域：四源候选先位于build/source01，审后Root备份部署；Temple仅依赖v7与两个常量。世界、美术、布局、NAV、玩家保存、resident/Router/Loading与十一室内开关不改。

高风险：同transition receipt线程生命周期；须真实workspace脚本身份、token/id/已join/未取消，缺叶或失效拒绝且无磁盘fallback。旧审批原15叶、精确四对八path及raw/import/ctex全保留，旧历史证据不重写。同步/null/Web与Market算法保持。

验收顺序：

1. 四源精确diff审查；实际CPU仅一个真实joined workspace，新旧完整Gate packet逐字节相同、imports全部像素相同，取消/未join/wrongtoken/id/缺叶/错SHA与审批变体负例拒绝。原30秒预算。
2. 审后精备与最小正式接线；一次普通无flags world96真Space→Gate原出生/Loading隐藏可动→32px/Physics/一图/退出，沿原120秒整轮与60秒到达/原仪器。
3. 统计整链与module分项，不把读取量或局部收益冒完整提速。所有失败和退出告警保留。首末506有限源保护（含15保存），仅明确授权源可变；新依赖单核。

源码审查完成：四实现源仅上述receipt接线，C实际live Gate显式调用已有`_owns_base_live_attempt`拒绝null/失效，原同步API保兼容；Market传null不改算法。取消仍先全cancel、join module后才释放workspace。原旧审批和像素/几何算法保持。QA版只两条preload路径适配，canonical候选保持正式路径。Temple v7只现役C SHA替换及追加prior-v6/三实现叶，其余原root字段和历史首末证据均精确保持。静态独核纠正24次兼容调用，读取量下界1,138,955,450字节；原776MB是低估下界，不作为完整计数。

## CPU完成，正式入口测试中

CPU键8064583F已Root全文审、parse40428的console wrapper自然0/空stderr。实际运行console wrapper25200自然OS0，真实Godot子进程93528完整结果8401F4DF，303检查零失败、11.217秒（30秒预算）。未持子进程Process退出码，不补称93528自然OS0；引擎均已退出，未重跑。原旧Gate完整packet4.147619秒，新实际Module入口1.481秒；全部native var bytes、两份25,165,824字节RGBA及walk字节精确相同。真实workspace1、OLD1、NEW Module1及既定失效/批准反例通过。101真实用源与15保存首末相等，QA另当前核同；8Image提醒、0ERROR/SCRIPT/ObjectDB。顺序/cache影响仍有，不冒整场收益。

Root精备五旧脚本全文后部署六候选（四实现+Temple两const+NEWv7），六整文件SHA全同source01。506初始事实到部署前0差；原506集合未包含STABLE helper，部署后实际仅C/Gate/Module/Temple四差，余502保持。STABLE旧源由CPU101集合及部署前独立File.Copy全文备份/原F43F SHA保护，不把它虚列为原506第五差。初稿guard比较误期望五差是Root读域计数错误，未涉及测试/生产变更；已明确纠正，不造首事实。最终另核Stable新SHA/bytes与NEWv7。

普通键5739D6DA仅ready与CPU证据从NOTREADY草稿固化；原k三观察/动作方法全文相同，C预期常量更新，独立l625全map只四SHA更新。Root GUIexe直接parse105368自然0/空stderr；唯一GUIexe29348普通无flags执行，原120/60，不复全城/暖返回。

## 已完成：正式路径有限实测

Root直接持有GUIexe Process的29348自然OS0已捕获，实际41.202秒/417检查/0失败。result `game/build/luoyang_module_source_cold_gate_20261017m/29348_2549/result.json` SHA `FF19BC8134B378B7A716242CDD1B6D2590C6069FBE0B106F0A6419DC52B1032F`。world96px/13实际Physics→原解锁Area按Space→Gate原1536,1860出生，Loading隐藏可动22.952秒→32px/5样本，总20查询；原导航/ownField退出/lease释放通过，Cerrors与Fieldfailed均0。PNG F5BA3AC4已Root/独立QA实看：普通城门人群与出口正常，无回退大世界。

完整625来源逐path/SHA独立对比l实际map，恰C/Module/Gate/Stable四值更新，无新增/缺失，finalized true；291自身源首末和QA额外当前SHA/bytes相同，15保存首末/当前相同。506最终事实只有C/Gate/Module/Temple四个授权源变化，余502（含15保存、project、世界、素材、布局等）SHA/bytes/精确ticks全同；对部署后快照0漂移。STABLE另CPU101事实/精确备份保护，当前新2900 SHA/bytes/ticks对部署后事实相同；NEWv7 ACAF单核，旧v6不动。全部own引擎已退出。

**本次首次进城22.952秒，上一轮24.705秒，单次减少1.753秒。** module CPU从l4258ms降为1675ms，与旧新CPU等价对照局部收益一致，但不承诺固定比例。其它实测source首2313ms、BASE CPU3526ms/main5481ms、harbour1371ms、resolve15748ms；阶段含式/重叠不能机械求和。最大Gate等待gap1689830us，仍约1.69秒卡顿，未授全程流畅或秒进。日志52Image/7旧退出Texture ERROR/0SCRIPT/0ObjectDB，非clean，不抹历史退出问题。

可重启普通游戏测试。C3DEB/Module95F1/Gate2371/Stable2900/Temple9584+NEWv7ACAF已接，完整备份与 final_guard/execution_results 在 `game/build/luoyang_loading_20261017m_root01/`。本轮停止任何重复引擎验收，不顺带授Market/Yamen/Docks运行、暖返回重验或十一新室内完成。下一原子可查tree二次CACHE_IGNORE加载与主线程长片段，须另做范围/等价验证，不由本轮自动扩展。
