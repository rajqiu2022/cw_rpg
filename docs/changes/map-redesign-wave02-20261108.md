# 地图改造第二批 · 襄州矿谷与江南芦荡

2026-11-08，桌面工作区。两图正式 ID 不变，正式 `SceneScript` 指向 v2 布置；旧 `layout_v1` 和原底图保留。无新主线、遇敌改数值、付费机制或大地图入口。

| 地图 | 这次实际接入 | 仍沿用 |
| --- | --- | --- |
| 襄州原矿谷 | 岩谷采坑台、碎石地面、分支运矿道路和车辙、工作棚和台、货车与独立深矿洞口。大件图和脚底阻挡分开；车旁仍有可走绕行线。 | 原城北门、矿谷南口、两矿一草、三个遇敌组合、深矿 G 入口及精确返回脚。不是重做深矿。 |
| 金陵江南芦荡 | 芦苇水泽与独立水边通行掩码、渔棚、纸作坊、东侧木栈台与南岸客渡、柳树和分叉土路。箭头放在原渡口对应的木台上。 | 原金陵渡口两向、原三草药点、三组敌人和原几率；没有新增生产 NPC 或船票。 |

芦荡水泽为 ImageGen 新生成的 1900×828 RGBA 素材。工程 [正式图](../../game/art/modules/jinling_reed_marsh_20261108/reed_pool_v1.png) 与 [原图](../../assets/raw/jinling_reed_marsh_20261108/reed_pool_v1.png) 原字节一致，SHA256 为 `F6F8524B7E448EFBF4EB5FAD8A53F178AAC638895B98E0CEE15C76764249C333`。无像素清理、缩放重编码或用程序生成替代。保留 [完整提示词](../../prompts/jinling_reed_marsh_20261108/builtin-prompts.md)。栈桥、建筑及其他物件复用工程正式素材。SVG 只作为导航掩码。

## 真实运行证据

- [矿谷隔离日志](../../game/build/loading_20261106_system02/xiangzhou_mine_v2_04/stdout.log)：49 项检查、0 失败、进程正常退出。襄州城最后一段用 W 走入原门，Space 进入原矿谷；两矿一草实际 F 交互各得 2，HUD 每次只发一次，采后隐藏，返回后仍隐藏；G 进入原深矿，S 走近原出口、Space 返回 (1000,1500)，从南口 Space 返回襄州北门。矿谷 [洞口](<../../game/build/loading_20261106_system02/xiangzhou_mine_v2_04/appdata/Godot/app_userdata/云影侠传/mine_valley_v2_shaft.png>)、[工场](<../../game/build/loading_20261106_system02/xiangzhou_mine_v2_04/appdata/Godot/app_userdata/云影侠传/mine_valley_v2_workyard.png>)。
- [芦荡隔离日志](../../game/build/loading_20261106_system02/map_marsh_v2_1108_03/stdout.log)：37 项检查、0 失败、进程正常退出。金陵原渡口 Space 进返；原尺寸、出生脚、深池阻挡和新增浅岸负例、三处草药脚点及采集宿主均过。没有逐株采摘或重新打原遭遇。芦荡 [渡口](<../../game/build/loading_20261106_system02/map_marsh_v2_1108_03/appdata/Godot/app_userdata/云影侠传/marsh_v2_arrival.png>)、[西岸](<../../game/build/loading_20261106_system02/map_marsh_v2_1108_03/appdata/Godot/app_userdata/云影侠传/marsh_v2_west_camp.png>)、[东岸](<../../game/build/loading_20261106_system02/map_marsh_v2_1108_03/appdata/Godot/app_userdata/云影侠传/marsh_v2_east_bank.png>)。
- 个别测试视角和局部采集起步位置使用隔离测试定位，不冒充全图连续游历。芦荡首次脚本拼接有重复函数的解析失败；矿谷早期 runner 错把深矿继承的 Area 范围标志当作真实脚范围，失败日志保留。正式校验和地图门禁未放松。两末轮来源无运行期间变化、15 个真实存档路径仅元数据零差，未读写真实存档内容；Godot 编辑器 56568 保留。既有角色贴图导出提示和退出清理报错保留；未做导出包验收。

## 后续边界

洛阳高级客栈的新版壳及家具候选已核对，不接入冒充完成。原掌柜/服务和南市往返要随严格来源链一并保留。古峰赈粮路仍为旧图，已定位粮车调查、伏击对白、World 返回和护粮营地门禁，作为下一张接手。其它场景继续以[盘点清单](../audits/map-redesign-backlog-20261108.md)为准。
