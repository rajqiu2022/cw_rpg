# 怡红院红木家具和两层楼梯 · 2026-11-08

- 一楼 `yihongyuan27n_interior`：三张旧桌换成红木描金茶桌，保留桌脚锚、原碰撞和一楼十位 NPC 的位置与原业务。左侧独立楼梯的踏面与栏杆分层绘制，栏杆两侧阻挡，不让人物从半途横穿。台阶 x416 避开原茶桌，原南市正门不变。
- 二楼 `yihongyuan27n_upper`：独立雅阁，有梅花、山水壁画和两组茶座。楼下到二楼的落点 `(768,832)` 在楼梯口里面；二楼返回落点 `(416,576)` 在一楼台阶前。楼梯口使用原有场景传送输入，不新增任务或强行切剧情。
- [内置图像生成提示词](../../prompts/yihongyuan_floors_20261107/builtin-prompts.md)；[原图目录](../../assets/raw/yihongyuan_floors_20261107)；[游戏素材目录](../../game/art/modules/yihongyuan_floors_20261107)。茶桌、楼梯、二楼内景三张 PNG 原字节未改，导入后基础 RGBA 一致，保留 mipmap。[导入凭证](../../game/build/yihongyuan_floors_20261107_art01/floor_media_formal_install_receipt.json)

候选编译 58076：44 项检查、0 失败，检查两侧不能横入楼梯、两层上下口和旧房间迁移样本。早期编译一次测试脚本类型推断失败；下一轮旧坐标确实撞原桌，留下失败记录。该失败轮检测到两个真实存档文件元数据发生变化，当时用户游戏独立运行；测试在隔离目录中执行，不读取、写入或恢复其内容。

[来源闭包与回退](../../game/build/loading_20261106_system03/YIHONG_FLOORS_SOURCE_HANDOFF.md)。正式只改这处楼层和必要的来源记录，未改其他九个房间包或洛阳入口业务。没有新增三楼；二楼这批仅做场景与家具，不新增 NPC、对白、剧情。

桌面实际 49752：20 项检查、208 个输入 tick、0 失败，退出码 0。原南市正门进入，走到踏面按空格上楼；实际脚走到二楼口按空格回到一楼梯脚，再从原正门精确返回 `(5206.18,4280)`。洛阳城门来源实际 1759/1759 精确匹配，未复走世界大地图进城。初次 43484 因测试把新楼层不支持的小地图当作可移动就绪条件而超时；两向目的地准入 38428 均通过，后继只修测试判据，没有放宽游戏来源校验。二楼暂无小地图；一楼原小地图保留。正式测试前后源和 15 个真实存档槽位的元数据未变，编辑器保留；旧音频/退出告警保留。

[一楼新桌](../../game/build/yihongyuan_floors_20261107_qa01/actual/49752/lower_hall.png) · [一楼楼梯](../../game/build/yihongyuan_floors_20261107_qa01/actual/49752/lower_stair_treads.png) · [二楼雅阁](../../game/build/yihongyuan_floors_20261107_qa01/actual/49752/upper_salon.png) · [实测报告](../../game/build/yihongyuan_floors_20261107_qa01/actual/49752/result.json)
