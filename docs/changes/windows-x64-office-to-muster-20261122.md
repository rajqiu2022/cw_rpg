# Windows x64 Release · 从烈云旧渡到第八章会盟集结地

从[第七章 18 级存档二](../../reports/windows_release_ch6_20261122/chapter7/save_1.json)开始，冷孤云沿用原有的单人阵容。独立 Windows Release 进程在隔离用户目录运行，不能读取工程，EXE 与 PCK 的[摘要](../../reports/windows_release_ch7_20261122/tested-sha256.txt)与前次发行包一致。

| 路段 | 发行包实测 | 画面 |
|---|---|---|
| 旧渡、茶镇和两侧外院 | 查旧渡印记、递送桌和转运账，回烈云查封渡名册，实胜强硬派巡守和封渡寻迹手，见改革派引路人。 | [茗雾茶镇](../../reports/windows_release_ch7_20261122/01-tea-town.jpg) · [封渡战](../../reports/windows_release_ch7_20261122/02-ferry-battle.jpg) |
| 外院护脉支线 | 内路一开，先回茗雾外院问老药工，从西侧转运桌下取回反装脉案。交差得一枚冰心玉，换下原来的丹砂佩。 | [老药工委托](../../reports/windows_release_ch7_20261122/03-offer.jpg) · [领奖](../../reports/windows_release_ch7_20261122/04-reward.jpg) |
| 双线核证与证人转移 | 往返聚义厅、安置档房、权限档案房、夜航栈和审验室，追查死籍、通行身份与内署命令。聚义厅选择分开转移证人，一人交行义帮，一人留烈云暗线。 | [护证选择](../../reports/windows_release_ch7_20261122/05-split.jpg) |
| 内署毁档 | 点腕巡守、截流巡守、护档使与焚令手三场均由现场 NPC 对话接战并胜利返场，三次入战前均核对主角佩戴冰心玉。审验室胜后、取私印底令前写入存档二，退出游戏。 | [点腕](../../reports/windows_release_ch7_20261122/06-wrist-battle.jpg) · [截流](../../reports/windows_release_ch7_20261122/07-current-battle.jpg) · [护档使](../../reports/windows_release_ch7_20261122/08-keeper-battle.jpg) |
| 内署冷读与回访 | 新进程从主菜单读回同档。经档房、内院回外院，再找药工，只出现买伤药与告辞。随后原路返回审验室。三处胜旗都在，相应对手均已退场，从读档到回访结束开战事件为 0。 | [回访药工](../../reports/windows_release_ch7_20261122/09-revisit.jpg) · [内署存档](../../reports/windows_release_ch7_20261122/office-slot-2.json) |
| 取令与结章 | 回审验室取到苏雾笙私印底令，再回聚义厅选「先公开可核验核心，继续保护证人」。完成第七章十一项主线，点击进入第八章，在会盟集结地存档。 | [私印底令](../../reports/windows_release_ch7_20261122/10-directive.jpg) · [第七章结算](../../reports/windows_release_ch7_20261122/11-settlement.jpg) |
| 第八章重启 | 另启进程读回会盟集结地，实走并打开任务卷宗。「会盟点名」进行中，下一步找会盟录事；分开护证选择和冰心玉装备均保留。 | [集结地](../../reports/windows_release_ch7_20261122/12-staging.jpg) · [任务卷宗](../../reports/windows_release_ch7_20261122/13-journal.jpg) |

首次交差冰心玉从 0 枚变为 1 枚。内署重启回访前后均为 1 枚冰心玉、4445 两、9124 可用阅历、20 级 744 经验。取令前存档为 20 级。[第八章存档二](../../reports/windows_release_ch7_20261122/chapter8/save_1.json)为 21 级，SHA-256 为 `b6001ce3f24a6cdc3bac77b04a89bf7c607c780e27d3dd47621b34dde6056693`。

全程使用地图通路、现场对白、现有角色的战斗指令与存读档功能。测试未改任务旗或战果。记录覆盖本次走到的路线，运行日志保留了已有的城市模块来源检查及释放资源告警。

[双线与内署三战](../../reports/windows_release_ch7_20261122/route.log) · [冷读回访至第八章](../../reports/windows_release_ch7_20261122/finish.log) · [第八章冷读](../../reports/windows_release_ch7_20261122/cold.log)
