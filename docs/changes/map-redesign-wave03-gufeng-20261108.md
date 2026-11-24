# 地图改造第三批 · 古峰赈粮路

正式 `ch5_s1_relief_road` 沿用原大地图古峰门及第五章入口。原一体背景留存，新场景改用 1920×1280 的独立雪地、岩脊、四段运粮路、翻覆粮车与路标。旧通行区域、归一化入口、布局版本、对话旗标、遇敌与奖励数据保留。粮车车体、车辕分别阻挡，旧碰撞占据的调查点旁留出脚底净空。

从真实 Field 消费者排查：两张旧地图的 `SceneScript.exits` 被空的 `map_layout.portals` 覆盖，旧热点转换只留下各自的 World 回程。新赈粮路布局显式登记「赶往护粮营地」，保留 `ch5_relief_road_cleared` 原门禁。营地仅接入已写在原场景的返赈粮路、去雪岭关两门，保留伪旗线索门禁，将营地 World 口与返赈粮路门分开；原营地底图、NPC、调查及战斗内容保留。未改共享 Field、Router 或 World 源。

## 资源

- 翻覆粮车采用内置 ImageGen 原生 1752×897 RGBA；[原图](../../assets/raw/gufeng_relief_20261108/grain_cart_v1.png) 与 [正式图](../../game/art/modules/gufeng_relief_20261108/grain_cart_v1.png) 同字节，SHA256 `AF38E6590667972E363A2352B12A9212F723F086E0ABFFE12DEFD57D69813ADF`，无本地改像素。[完整提示词](../../prompts/gufeng_relief_20261108/builtin-prompts.md)。
- 雪地、岩脊、道路、松树与路标复用在库组件，按原成人尺度和脚点摆放。不是全新北地建筑素材包。

## 验证与边界

[隔离桌面日志](../../game/build/loading_20261106_system02/gufeng_relief_v2_03/stdout.log)：33 项检查，0 失败，进程自然退出。真实 Space 从 World 古峰门进入、调查粮车并接原任务；营地门在未胜利时关闭，隔离测试设置原胜利旗标后实按进入；营地实际返回到赈粮路记忆的北口，南口返回古峰原大地图位置。核对营地战斗交互区仍在、雪岭关需伪旗线索；未实打伏击或营地战，也未进入雪岭关。局部测试点有定位，不是全程连续步行。

[粮车正常镜头](<../../game/build/loading_20261106_system02/gufeng_relief_v2_03/appdata/Godot/app_userdata/云影侠传/relief_road_v2_cart.png>)、[护粮营地岔口](<../../game/build/loading_20261106_system02/gufeng_relief_v2_03/appdata/Godot/app_userdata/云影侠传/relief_road_v2_pass.png>)。保留 01 缺门和 02 将配对返回误判为回退脚的测试失败；最终未放宽正式校验。保留既有纹理导出提醒及退出清理警告；15 个真实存档路径仅核元数据零差、未读写存档内容，Godot 编辑器 56568 保留。

护粮营地仍是旧美术，下一批再处理营地、雪岭关及后续地图；见[施工队列](../audits/map-redesign-backlog-20261108.md)。
