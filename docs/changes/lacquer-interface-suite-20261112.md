# 八个新版游戏界面

以现役菜单按钮的墨蓝漆面、古铜细边和青玉嵌角为基准统一八个界面。主标题和固定操作题字来自 PNG，角色数据、任务内容、商品和奖励随游戏状态更新。列表、详情和操作区按每个界面的用途布置。

| 界面 | 本次设计 | 正式游戏截图 |
| --- | --- | --- |
| 系统 | 设置、保存游戏、读取存档分别切换，右侧显示音量或槽位 | [设置](../../game/build/lacquer_ui_20261112/01-system.png) · [存档](../../game/build/lacquer_ui_20261112/01b-save.png) · [读档](../../game/build/lacquer_ui_20261112/01c-load.png) |
| 角色装备 | 区分人物属性、装备和行囊，统一物品格及使用、丢弃按钮 | [角色行囊](../../game/build/lacquer_ui_20261112/02-character.png) |
| 任务 | 左侧筛选与任务列表，右侧放线索、奖励和追踪 | [任务卷宗](../../game/build/lacquer_ui_20261112/03-quest.png) |
| 武学招式 | 独立的招式与心法页签，技能列表、说明和操作分区 | [招式](../../game/build/lacquer_ui_20261112/04-skill.png) · [心法](../../game/build/lacquer_ui_20261112/04b-internal.png) |
| 生活技能 | 左侧技能名与图标，右侧显示用法和地点 | [制药](../../game/build/lacquer_ui_20261112/05-life.png) · [采集](../../game/build/lacquer_ui_20261112/05c-gather.png) · [锻造](../../game/build/lacquer_ui_20261112/05d-smith.png) · [药方](../../game/build/lacquer_ui_20261112/05b-recipes.png) · [制造](../../game/build/lacquer_ui_20261112/06c-smithing.png) |
| NPC 交易 | 加入商品图标，整理价格、数量、买卖页签和结算确认 | [商店](../../game/build/lacquer_ui_20261112/06-shop.png) · [交易确认](../../game/build/lacquer_ui_20261112/06b-checkout.png) |
| 战斗胜利 | 暖金题字，奖励和返回按钮各有固定位置 | [胜利](../../game/build/lacquer_ui_20261112/07-victory.png) |
| 战斗失败 | 朱砂题字和偏冷的背景，沿用同套信息布局 | [失败](../../game/build/lacquer_ui_20261112/08-defeat.png) |

桌面 1920×1080 游戏运行验证共 56 项，全部通过。测试涵盖设置与存读档页切换、装备筛选、任务筛选和章节选择、武学页签、药方与锻造、商店改数量及取消结算、胜负结算和返回地图。胜负结算使用正式路由和隔离测试数据。未验证手机、发布包、写入真实存档或实际成交。引擎退出仍报告已有的纹理与资源清理警告。[实测日志](../../game/build/lacquer_ui_20261112/verify.log)

美术原图与正式 PNG 字节一致。[生图提示词](../../assets/raw/ui/lacquer_20261112/prompts.txt) · [共用资源定义](../../game/scripts/ui/lacquer_ui.gd) · [界面接入](../../game/scripts/ui/lacquer_interface_suite.gd)

关闭按钮统一用同一套方形图，按画框尺寸定位到右上角内侧。角色页为装备栏预留空间，使用更靠左的定位。桌面逐页点击，含系统的存档和读档页，共 63 项通过。[关闭按钮验证日志](../../game/build/lacquer_ui_20261112/verify-close-buttons.log)

内置 ImageGen 为两个 490×74 武学页签和三个 284×63 生活技能入口生成了带题字的素材。图集原字节进入工程，使用透明区域裁框并在游戏中等比缩小。桌面 25 项通过，包括来回切页、选择招式后刷新列表、生活技能右栏说明和打开药方。任务页标签、章节下拉、任务列表和共用画框仍有旧的拉伸适配，本批只替换上述五个入口。[新页签实测](../../game/build/lacquer_ui_20261112/verify-illustrated-tabs.log) · [武学图集](../../game/art/ui/lacquer_20261112/martial_tabs.png) · [生活技能图集](../../game/art/ui/lacquer_20261112/life_tabs.png)
