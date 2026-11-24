# Windows x64 Release 第四章双线实测

沿用 2026-11-22 的 Windows x64 Release 包。[ZIP](../../dist/YunYing-Windows-x64-Release-20261122.zip) · [实测 EXE、PCK 的 SHA-256](../../reports/windows_release_ch4_20261122/tested-files.sha256)

## 起点和共同存档

从主菜单读取上轮府衙「存档二」的逐字节副本，落在案情榜旁 (1300.422, 1693.525)。给冷孤云装备原包里的烬河断岳刀，步行至码头，与失踪脚夫交谈，打赢两名洛阳地痞，返回码头后从系统菜单保存。此时 10 级、477 气血、1427 两，尚未得到原始货单。救人和追使分别在独立进程、独立存档目录读入这一文件，SHA-256 均为 `8c596dc977ddf843211658ce40baf4bb85c5a8447214109f45770323d7a86dd1`。[府衙起点](../../reports/windows_release_ch4_20261122/common/00-office.jpg) · [码头战斗](../../reports/windows_release_ch4_20261122/common/01-docks-battle.jpg) · [选择前存档](../../reports/windows_release_ch4_20261122/common-docks-slot-2.json) · [共同路段日志](../../reports/windows_release_ch4_20261122/start.log)

| 检查点 | 留下救治脚夫 | 截住信使 |
|---|---|---|
| 选择与调查结果 | 核实原始货单和「脚夫的夜运口供」，记录脚夫存活。[对白](../../reports/windows_release_ch4_20261122/rescue/03-rescue.jpg) | 核实原始货单、信使携带的完整残卷和「被截信使的口供」，记录信使被捕。[对白](../../reports/windows_release_ch4_20261122/pursue/03-pursue.jpg) |
| 古寺与存档 | 从调查点触发并打赢伏击，调查暗道，在地下运货道存进第二槽，随后退出。[古寺战斗](../../reports/windows_release_ch4_20261122/rescue/04-temple-battle.jpg) · [地道存档](../../reports/windows_release_ch4_20261122/rescue-tunnel-slot-2.json) | 从同一剧情入口打赢伏击、调查暗道，在地道存进第二槽并退出。[古寺战斗](../../reports/windows_release_ch4_20261122/pursue/04-temple-battle.jpg) · [地道存档](../../reports/windows_release_ch4_20261122/pursue-tunnel-slot-2.json) |
| 重启续玩 | 从主菜单读回地道 (960, 888.16)。核对救人结果与已胜伏击，交谈开战，打赢伪烈云盟首领及两名伏兵，清点印版和账册。[首领战](../../reports/windows_release_ch4_20261122/rescue/06-tunnel-battle.jpg) · [续玩日志](../../reports/windows_release_ch4_20261122/rescue-resume.log) | 从主菜单读回相同脚点。追使证物与口供保留，已胜伏击保留，打赢同一场首领战并清点物证。[首领战](../../reports/windows_release_ch4_20261122/pursue/06-tunnel-battle.jpg) · [续玩日志](../../reports/windows_release_ch4_20261122/pursue-resume.log) |
| 第四章结算 | 「洛阳奇案」「古寺密谋」「运河灭口案」「古寺地道」四项完成，点击「进入第 5 章」。[结算](../../reports/windows_release_ch4_20261122/rescue/07-settlement.jpg) | 四项主线完成，点击同一结算按钮。[结算](../../reports/windows_release_ch4_20261122/pursue/07-settlement.jpg) |
| 第五章落点 | 到达赈粮路，开场对白接取「雪路急援」，可行走。12 级存槽，另起进程读回后，任务手记显示「进行中」。[任务手记](../../reports/windows_release_ch4_20261122/rescue/10-journal.jpg) · [续玩存档](../../reports/windows_release_ch4_20261122/rescue-chapter5-slot-2.json) | 同样到达赈粮路、接取任务并能行走。12 级存槽，冷读后任务和追使结果保留。[任务手记](../../reports/windows_release_ch4_20261122/pursue/10-journal.jpg) · [续玩存档](../../reports/windows_release_ch4_20261122/pursue-chapter5-slot-2.json) |

两条线各自在地道冷读时核对了古寺胜利标记和互斥的证物、证词、选择标记及城市结果。两份最终存档均保留活捉首领的结果，从第五章冷读时均触发零场战斗。[截图对照](../../reports/windows_release_ch4_20261122/branch-comparison.jpg) · [存档与进程交接校验](../../reports/windows_release_ch4_20261122/verification.txt)

Windows AppContainer 中从发行 EXE 运行，游戏进程无法读取工程源码。外置测试脚本使用主菜单、正式地图交互、对白选项、战斗指令和系统存档界面，部分行走和战斗加速。两线均走通，未发现资源漏打、任务拒绝或读档卡点，沿用原发行包。仍有既有的三个可选模块来源告警、个别 NPC 对话朝向回退及退出时的资源释放告警。
