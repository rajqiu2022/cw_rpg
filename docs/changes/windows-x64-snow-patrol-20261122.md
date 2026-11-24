# Windows x64 Release 实测 · 雪路三哨与第六章续玩

从[救人线 12 级存档二](../../reports/windows_release_ch4_20261122/rescue-chapter5-slot-2.json)起步。正式 EXE、PCK 的 SHA-256 与上一轮发行物一致。游戏进程在 Windows AppContainer 运行，不能读取工程源码。验收驱动在游戏窗口内走地图、与 NPC 交互、选战斗指令并操作读写档菜单。战斗使用原存档的队伍、装备和药品。

| 顺序 | 游戏内实际经过 | 证据 |
|---|---|---|
| 1 | 赈粮路击退劫粮客，进营保住车队、查验伪旗，向古峰护粮守卫打听并接下委托 | [守卫委托](../../reports/windows_release_ch5_20261122/02-offer.jpg) |
| 2 | 回赈粮路清翻车旁的第一哨，经护粮营上雪岭关清第二哨，进废弃矿道听取幸存者证词并清第三哨 | [第一哨](../../reports/windows_release_ch5_20261122/post-1-battle.jpg) · [第二哨](../../reports/windows_release_ch5_20261122/post-2-battle.jpg) · [第三哨](../../reports/windows_release_ch5_20261122/post-3-battle.jpg) |
| 3 | 从矿道经雪岭回营，守卫给甲，任务完成。使用系统菜单写入存档二并退出 | [奖励](../../reports/windows_release_ch5_20261122/03-reward.jpg) · [营地存档](../../reports/windows_release_ch5_20261122/earned-camp-slot-2.json) |
| 4 | 启动新进程，继续游戏读取存档二。再找同一守卫，说的是过雪岭、穿废矿去哨站的指路对白 | [重启回访](../../reports/windows_release_ch5_20261122/04-revisit.jpg) |
| 5 | 装上领取的重甲，保留原有烬河断岳刀。查哨站兵器台，找统领接战，单人阵容实际对上统领与一名突袭手。获胜后选择先公示已证实的栽赃链 | [统领战](../../reports/windows_release_ch5_20261122/05-commander.jpg) · [五章结算](../../reports/windows_release_ch5_20261122/06-settlement.jpg) |
| 6 | 结算显示主线 6 项、支线 1 项。点击进入第六章，林西与刑樊天谈完后「归村问师」结案、「旧居暗门」接取。存盘后再次退出重启，同档读回能走动并打开任务卷宗 | [林西实景](../../reports/windows_release_ch5_20261122/07-chapter-six.jpg) · [卷宗](../../reports/windows_release_ch5_20261122/08-journal.jpg) |

| 奖励核对 | 领奖前 | 领奖后 | 重启再交谈后 |
|---|---:|---:|---:|
| 玄铁重甲（件） | 0 | 1 | 1 |
| 银两 | 2637 | 2697 | 2697 |
| 可用阅历 | 4527 | 4787 | 4787 |
| 累计经验（含已升级部分） | 4507 | 4767 | 4767 |

[第六章存档二](../../reports/windows_release_ch5_20261122/chapter6/save_1.json)为 v14，冷孤云 16 级，落点「林西村」。下一步是去刑樊天正屋查书案上的押运旁注。存档 SHA-256 为 `c91beb13c9ea426095bfdefdc9f6367c275b197ec334816ab9a8f5a2d633838c`。核对了起始档、领奖档与跨章档各自的读回摘要，三个进程分别为 87108, 10992, 32292。玩家原档保留。

本次路线的交互、战斗与跨章均正常。测试走位在赈粮路和雪岭弯道有过失败，调整走位后原发行包通过。沿途部分 NPC 对话使用镜像朝向，日志另有此前已记录的城市来源检查和退出时渲染资源释放告警。检查覆盖这段路线上实际加载的资源。

[三哨日志](../../reports/windows_release_ch5_20261122/patrol.log) · [领奖后重启至跨章日志](../../reports/windows_release_ch5_20261122/commander.log) · [第六章冷读日志](../../reports/windows_release_ch5_20261122/cold.log) · [发行文件摘要](../../reports/windows_release_ch5_20261122/package-sha256.txt)
