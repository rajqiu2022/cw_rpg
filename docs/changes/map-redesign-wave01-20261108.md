# 地图改造首批：清风普通客栈、中原旧驿

按[正式地图盘点](../audits/map-redesign-backlog-20261108.md)执行。保留原 scene ID、入口、任务和玩法数值；没有修改共享路由、项目设置或真实存档。此批正式接入两张，后续施工仍未完成。

## 清风普通客栈

- 正式 `interior_inn_hall` 保持原资源路径和原门，改用[新版布局](../../game/build/qingfeng_inn_20261108_runtime01/inn_layout.tres)。独立木地板/房壳和前墙四片、六个独立家具，柜台掌柜、堂中小二、左右客席、入口中轴各自留通路。账册交互移到柜台可接近的一侧，使用柜面原账册图形，不再在过道额外摆漂浮图标。原对话、四个身份和固定坐客脚保留。
- 使用既有内置 ImageGen [原图](../../assets/raw/interior_identity_20261106/inn_common_shell_v1.png)与[生成归档](../../game/build/interior_identity_20261106_art01/HANDOFF.md)。授权清边版 C3FF6419… 原字节正式安装；独立 Godot 导入无错误，使用 mipmap，不重画。历史室内与旧布局保留。洛阳高级客栈与其收费住宿仍未更换。
- 私有 GPU 实例 69664，正常退出 0 / 29 项通过。原室外门真实 Space 进屋，原到达脚，逐实体加载、门廊通行、家具阻挡，沿中轴实际走到出口并 Space 回到室外原台阶 (950,1838)。[正常画面](../../game/build/loading_20261106_system02/qingfeng_inn_redesign_03/appdata/Godot/app_userdata/云影侠传/qingfeng_inn_normal.png)。账册仅核正式行、动作和足形正探针，未在此次测试打开对白。
- 两个早期失败留存：第一次在村落门点摆位不适合真实按键；第二次成功进屋，但测试把有居中偏移的全局脚误当室内坐标。已纠正坐标参考并补走返程，不冒两次早期试验成功。

## 中原旧驿

- 正式汴州北门原目标 `openworld_bianzhou_old_post` 改用[新版布局](../../game/data/maps/openworld_bianzhou_old_post_layout_v2.tres)，原 3072×2048、遇敌、地图四个旧正探针和汴州返回保持。草土、支路、岩林、驿舍与马棚、废院和营地杂物共 40 个独立对象；主要实体按脚点排序并附底座碰撞。复用在库美术，无新增图片。初版正常图发现南接路偏离门脚，后继仅对齐路面，不改出入口。
- 私有 GPU 实例 71936 首轮实际汴州北门 Space 进返，24 项通过；末轮 26/0，闭门驿舍、木货车和麻袋替换后复核原北门进返和正常画面。[南接路](../../game/build/loading_20261106_system02/bianzhou_post_v2_03/appdata/Godot/app_userdata/云影侠传/old_post_v2_arrival.png)、[西营](../../game/build/loading_20261106_system02/bianzhou_post_v2_03/appdata/Godot/app_userdata/云影侠传/old_post_v2_west_post.png)、[东废院](../../game/build/loading_20261106_system02/bianzhou_post_v2_03/appdata/Godot/app_userdata/云影侠传/old_post_v2_east_ruin.png)。旧布局 v1 与背景留作回溯。

## 同轮林西反馈

正式山道洞口与石碑使用脚点深度和遮挡蒙版，物件全不透明，只为被挡的角色部分补半透明显示；原入口、物件形状及碰撞保留。普通矿药收获后整节点隐藏、鼠标和 F 不再选中、成功只走原获得物品提示。原补充周期和任务采集不变。私有 GPU 实例 66168 实际加载山道，测试洞口和碑前后、F 草矿和资源恢复，共 33/0。

三组测试均隔离 AppData、暂停检查点；15 个真实槽路径只看元数据且前后零差，不读取档案内容，不停止 Godot 编辑器。既有资源释放/图像导出警告仍保留。本轮不冒充全部地图已改、发布包验证或全图画面通过。
