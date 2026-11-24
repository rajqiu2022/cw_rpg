# 竹尾客栈、菜单与山贼洞窟

## 场景

- 竹尾客栈使用原有入口和大堂房壳。柜台留在左后，灶台、备菜案、酒架和粮袋靠后墙。两张上菜桌加两张茶桌分列两侧。茶客右向举杯，行脚客左向端碗，两个坐姿为单帧精灵。原柜台账册和四个 NPC 对话仍由原 ID 提供。[布局](../../game/data/maps/interior_inn_hall_layout_v2.tres) · [大堂截图](../../game/build/inn_ui_cave_20261109/07_inn.png)
- 山贼洞窟的左侧为休息和守卫区，中间为进出通道，右后为藏货区。支线「山寨暗记」开启后，可先与留守山贼对话并选择是否挑战。胜利写入洞窟守卫的独立旗标，再回原战斗脚点并提示调查右侧货箱。送货单和旗帜继续使用原支线完成条件，已经结案的状态继续生效。旧档如果仅赢过旧的可重复山贼战而尚未结案，需要击败新版守卫一次。[布局](../../game/data/maps/interior_bandit_cave_layout_v2.tres) · [战后调查截图](../../game/build/inn_ui_cave_20261109/09_cave_evidence.png)

## 界面

- 系统菜单与独立存档、读档页复用任务卷宗框架。I 打开背包，O 打开系统，Esc 展开右侧六个小按钮。生活技能页列出制药、采集和锻造，制药接原药方页，锻造使用现有铁匠铺。[系统](../../game/build/inn_ui_cave_20261109/01_system.png) · [存档](../../game/build/inn_ui_cave_20261109/02_save.png) · [读档](../../game/build/inn_ui_cave_20261109/03_load.png) · [生活技能](../../game/build/inn_ui_cave_20261109/06_life.png)
- 当前主线点击「查看追踪」回地图并显示目标，支线保留追踪和取消。交易按钮换成蓝灰直角框，位置与交易金额分开。[卷宗](../../game/build/inn_ui_cave_20261109/04_tracking.png) · [交易](../../game/build/inn_ui_cave_20261109/10_shop.png)

## 资源与验证

- 8 张内置 ImageGen 采用图与源图字节一致。分类资源库增加 8 张正式图和 8 张原图，保留原有缩略与点击放大。[生成记录和提示词](../../game/build/inn_ui_cave_20261109/imagegen_sources.json) · [分类资源库](../equipment-skill-catalog.html#resources)
- 桌面实机 77 项检查全过。按键与鼠标走正式控件，原门双向进出，洞窟实际选择、出招、胜利结算、同脚返回、读送货单和完成任务均通过。测试用独立存档目录，守卫血量在验证时调至 1 以缩短战斗。存读档测试覆盖入口、页面和空槽保护。[实机日志](../../game/build/inn_ui_cave_20261109/final_stdout.log)

