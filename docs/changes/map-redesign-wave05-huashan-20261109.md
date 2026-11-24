# 第五批现役地图改造：华山演武坪与观瀑剑台

两张原 ID 改用独立 3072×2048 地形与陈设，原 v1 布局和一体图保留。不改华山山门户外地图、真实高差系统、任务数值、门禁或存档结构。本批沿用已入库贴图，没有新出图。

- `openworld_huashan_sword_terrace`：南北阶道穿过中央石铺练剑区，两列兵器架分开，北侧设置小舍和备具棚，侧缘用松岩围合。阶梯只作为这一层场景的台基画面，未添加高程模拟。
- `openworld_huashan_waterfall_terrace`：西侧亭台和游天鸿，东侧叠瀑、剑碑与藏经小楼。栏边、碑脚、瀑潭和岩石使用对应阻挡，保留访客接近游天鸿的空间。藏经楼不是新的可进房间，瀑布贴图非水流动画。

原山门→演武坪落脚 (1536,1812.48)，演武坪→观瀑剑台 (1351.68,1761.28)，反向返回演武坪原门锚 (1536,215.04)，回山门 (2700,2580)。布局版本、旧行走轮廓、门 ID/热区和对白资源未改。现役来源清单仅同步这两个 SceneScript 与新布局文件的实际摘要，原校验仍启用。

桌面检查 [43/0](../../game/build/loading_20261106_system02/huashan_terraces_1109_04/stdout.log)：四次真实 Space 双向切图，原落脚、代表性通行和潭边阻挡、靠近游天鸿打开原「岚回三叠」对白均通过。镜头取样和门前接近点使用隔离测试定位，未声称从山脚连续步行、学成武功或验过真实读档。首轮碰撞点和返程断言失败，以及第三轮过硬拼路被退回，原日志和截图保留。正式末轮自然退出，15 个真实档位只查元数据且零变化，Godot 编辑器保留；旧退出纹理清理报错仍有。

实机图：[演武坪](../../game/build/loading_20261106_system02/huashan_terraces_1109_04/appdata/Godot/app_userdata/云影侠传/inner_courts_huashan_training.png)、[游天鸿](../../game/build/loading_20261106_system02/huashan_terraces_1109_04/appdata/Godot/app_userdata/云影侠传/inner_courts_huashan_elder.png)、[观瀑剑台](../../game/build/loading_20261106_system02/huashan_terraces_1109_04/appdata/Godot/app_userdata/云影侠传/inner_courts_huashan_falls.png)。局部铺石边仍偏直，不能关闭华山整个山体与地表接缝的历史美术余项。
