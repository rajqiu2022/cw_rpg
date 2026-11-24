# Windows x64 Release · 灯布上的乌痕至第七章

从[林西村 16 级存档二](../../reports/windows_release_ch5_20261122/chapter6/save_1.json)开始。游戏进程在 Windows AppContainer 中使用独立存档目录，无法读取工程。正式 EXE 和 PCK 的 [SHA-256](../../reports/windows_release_ch6_20261122/tested-sha256.txt) 与上轮发行物一致。驱动走地图、触发现场交互、使用角色已有装备和战斗指令，通过主菜单与系统菜单读写存档二。三次启动均为桌面 Release 进程。

| 路段 | 实测结果 | 截图 |
|---|---|---|
| 林西村到正屋暗门 | 先接送药人委托，在茶桌托盘下取灯布，交差得丹砂佩。主角装备后查押运旁注与兵器架，从暗门入库。 | [送药人](../../reports/windows_release_ch6_20261122/01-wick-offer.jpg) · [领取丹砂佩](../../reports/windows_release_ch6_20261122/02-pendant.jpg) |
| 地下档库 | 依次战胜掌灯巡守、守架巡守、销卷使与焚册客。三个战斗入口均记录主角佩戴同一件丹砂佩。查原册和涂改栏后，「地底原册」完成，在档库写入存档二并退出。 | [掌灯巡守](../../reports/windows_release_ch6_20261122/03-lamp-battle.jpg) · [守架巡守](../../reports/windows_release_ch6_20261122/04-shelf-battle.jpg) · [销卷使](../../reports/windows_release_ch6_20261122/05-reclaimer-battle.jpg) · [取回原册](../../reports/windows_release_ch6_20261122/06-archive.jpg) |
| 档库重启 | 从主菜单读回同槽，原册证物、三场胜利和饰品装备均保留。回正屋再找送药人只有看药箱与告辞的选项。重新走暗门，三处剧情对手均已退场；从启动到再次进库，开战事件为 0。 | [送药人回访](../../reports/windows_release_ch6_20261122/07-revisit.jpg) · [档库再入](../../reports/windows_release_ch6_20261122/08-archive-cold.jpg) |
| 白水旧路与古道客栈 | 带原册回林西问师，经档库到白水旧路，查里程碑和车辙，击败截证客与寻迹者。回林西选「我可以原谅，但你必须公开作证」，到古道客栈读戚云笙的信。结算显示主线完成 6 项、支线完成 1 项。 | [白水战](../../reports/windows_release_ch6_20261122/09-baishui-battle.jpg) · [古道留书](../../reports/windows_release_ch6_20261122/10-letter.jpg) · [结算](../../reports/windows_release_ch6_20261122/11-settlement.jpg) |
| 第七章续玩 | 点击进入第七章，选择先查烈云。旧渡对话结束后写入存档二；另启进程读回，实走 99 个游戏坐标单位，打开卷宗确认「双线求证」进行中。 | [旧渡落点](../../reports/windows_release_ch6_20261122/12-ferry.jpg) · [任务卷宗](../../reports/windows_release_ch6_20261122/13-journal.jpg) |

首次交差丹砂佩由 0 枚增为 1 枚。中途重启回访送药人前后均为 1 枚、3481 两、6044 可用阅历、16 级 624 经验。副本中实打三次剧情战，白水旧路一次；未改任务旗、战果或存档数据。

[档库重启点](../../reports/windows_release_ch6_20261122/archive-slot-2.json)及[第七章续玩存档二](../../reports/windows_release_ch6_20261122/chapter7/save_1.json)均已在新进程读回。交付档为 18 级，位于烈云峡谷旧渡，SHA-256 为 `1a676d05016ce4fc8f7c3b8647e884056b7d45603033dcd0ab243b9c407ac101`。

最初在茶桌中心按交互未成功，调整验收走位到托盘可交互边缘后，自原档重新跑通。沿途未出现资源拒载或剧情阻断，原发行包继续使用。日志仍有原有的城市来源校验、对话朝向回退及退出资源释放告警。

[林西至档库日志](../../reports/windows_release_ch6_20261122/archive.log) · [档库重启至第七章日志](../../reports/windows_release_ch6_20261122/road.log) · [第七章重启日志](../../reports/windows_release_ch6_20261122/cold.log)
