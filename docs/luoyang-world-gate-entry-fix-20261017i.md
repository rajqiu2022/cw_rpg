# 大地图进入洛阳失败 · 2026-10-17i

## 结论：已修复并通过真实入口验证

用户确认退出游戏和编辑器后，Root重新核实进程均退出，精确备份当前Gate和8个导入文件，再部署62A9 Gate来源适配与四组关闭自动3D检测的新import/ctex。新原生纹理/原图的完整像素保持不变，历史56来源manifest与捕获报告不改写；存档、地图布局、碰撞及C/Field/Router未改。

唯一实机96048自然OS0，383检查/0失败，整份脚本56.820秒。普通正式world入口附近合法出生后正常行走96px（13个Physics输入样本），在原生已解锁入口按Space，成功进入洛阳南城门原脚[1536,1860]，Loading隐藏且玩家可动，随后正常行走32px（5样本）；合计20个真实Physics查询、原world半径5/17足点与城内34×24/87517分别核验。279测试来源首末保持，实际Gate完整来源包含新8路径、审批/证明闭包及h来源，不使用直接城市出生代替入口。自身Field退出正常。

Root已亲看普通视角`game/build/world_gate_stable_import_entry_20261017/96048_2544/real_world_space_gate_ready.png`（75AB38A4）。结果6E8AD7DB；完整stderr52Image/7退出纹理ERROR、0SCRIPT/ObjectDB，未称clean。Space至城门隐藏Loading且可动实测36.057秒，**本轮修复进不去，不宣称冷加载提速**。未跑往返、暖缓存、十一类室内或全城回归。

最终502既有事实仅Gate+4import+4ctex共9项授权变化，其余493包含15保存、用户project.godot与原C/Field/Router的SHA、长度、字符串ticks全部不变；部署后无再次漂移。当前所有Root测试进程已退出，用户可以重新启动普通工程测试。备份及证据在iroot01/final_guard.json。

## 现象与确证范围

用户报告在大地图进入洛阳，Loading结束后仍回到大地图。上一轮h验证的是码头默认public入场，没有覆盖本次世界→南城门路径，不能以码头327项通过否定用户反馈。

只读对照发现：Gate原`runtime_manifest.json`（6800370f）56个来源中恰4份`.import`漂移，其余52个逐SHA相同。四张源图和历史普通`.ctex`仍保持原字节。编辑器的3D自动检测把无损/no-mip导入切换成mode2、mip和`.s3tc.ctex`；法线图另从normal_map0改成1。四个旧expected配置的`detect_3d/compress_to=1`意味着单纯恢复旧配置还会重现，10月14日已发生过一次。

Gate读取A/B两份历史捕获报告时，`capture()`首先核对它们的来源目录，这四份import即使仍显示正常图像也会因SHA改变被拒；其后56来源manifest同样会拒。`C._fail`只收内部errors，用户日志中没有明确报错并不代表准备成功。Router预备失败结束Loading、保留原world Field，静态代码与现象相符；尚未捕获此次用户运行的内部error具体字符串，不能冒称已捕到某一行错误。

## 最小修复方案

1. 用四份完整旧expected字节作基准，仅将`detect_3d/compress_to=1`改为0，保留原无损/no-mip及其它参数，阻止再次自动切3D。
2. 在隔离同res路径小工程导入四张原图，验证完整RGBA、尺寸、23项设置及原普通ctex精确字节；不改原图。
3. 用新、显式四path/旧SHA/新SHA/实际导入证明的严格审批接入Gate来源判断。历史56来源manifest和A/B报告不改写；任意第五path、不同旧SHA或其它参数改变仍拒绝。正常转场首末来源核对记录实际新SHA，不把历史SHA伪装成当前。
4. 只测一次真正的大地图合法入口：正常短距离行走、空格进城，确认实际Gate出生、Loading隐藏、可走及原生Physics。不重跑全城，不启用g加载缓存或十一类室内。

## 部署前状态（历史记录）

已定位导入漂移，最小修复与专项测试准备中，尚未部署。Root已请用户保存并退出游戏109048与编辑器29308；未擅自停止。初查可用显存1018MiB，不启动重场景测试。用户本轮存档和project.godot变化均保留，不恢复到上轮h值。完整初始守护、日志快照和分工见`game/build/luoyang_world_gate_entry_fix_20261017i_root01/`。

## 隔离验证与实施前审查

隔离同res路径四图工程`game/build/luoyang_gate_stable_import_20261017_system01/`，prepared AD0AD8F8。66748导入自然OS0；四配置SHA与预期“旧expected唯一detect1→0”相同。实际新ctex并不与旧ctex整文件相同：四件都是长度相同、全文件仅offset19从13变12。该字节差异不冒称已由引擎源码解释，只记录实际字节。因而方案收敛为四对import/ctex共8个精确path授权，其余原56中的48项仍严格同，历史manifest/capture字节保持。

QA初稿预运行发现prepared.params23域错误未执行保留；90360真实诊断因ConfigFile `Array`与`PackedStringArray`错误比较抛SCRIPT异常，原30秒外守卫精确停止OS−1、无结果，完整日志保留。NEW retry3仅改实际原始Array逐元素精确比较。41192自然OS1/1505ms仍保留4个“旧ctex整文件SHA不同”断言失败；独立`full_rgba_pass=true`，四张raw/ResourceLoader/direct新ctex/direct旧ctex全部RGBA逐字节相同、23项参数正确、0mip。Root/QA独核该有限像素证据，不能把整个旧条件报告改称通过。报告SHA5AF6F69E、完整stderr4Image/0ERROR/SCRIPT。

6912纯8path验证自然OS0，78项0失败/406ms；错误历史SHA、任意bit改变、截短、第五路径/邻路径、raw不授权与PENDING不放行均通过。12来源和15保存只在该独立测试窗内首末相同；1ObjectDB提醒保留。结果9DFBBA45。这不是FINAL运行授权或真实world入城验证。

采用code-review做定点审查，约束为Gate来源边界＋新增显式审批，不修改C/Router/Field、旧地图几何或存档。Gate现役及四组正式import/ctex尚未替换；真实入口脚本仍NOTREADY，等用户退出后才能部署并运行一次固定120秒whole/60秒arrival的单程Space检查，不启动全城回归。

待部署包已冻结：helper F43F74F8、FINAL审批2BFE7F62、仅来源适配的Gate候选62A9F85D，交接`game/build/luoyang_gate_stable_import_20261017_system_source01/READY_HANDOFF.md`。Root已完整审helper、审批、Gate差异及交接，现役Gate仍E510，8个正式文件保持原样。下一用户退出后先做新鲜备份，再接Gate窄patch和8个已验证文件、编译、只跑一次真实入口；不复隔离RGBA/78纯例。最后观察502既有事实自本轮首exactticks全部相同，包括15保存、用户project配置、旧Gate和现役导入。

最终独立QA补核：96048实际C proof共624来源全部当前SHA相符、finalized=true；279测试来源首末/当前SHA长度同、15保存首末/当前同。158份观察无ROLLBACK，末Loading两owner及全部worker均idle、C_errors为空、Field完整且无failed。此后无新增引擎测试，最终部署状态以本文首节为准。
