# NPC 身份与语音核查

核查日期 2026-11-13。覆盖八章及开放场景中能从地图、布局、任务对白分支和现役覆盖配置追溯的对白。111 个地图入口中 61 个有纳入的 NPC 对白，计 126 个发言名、513 条地图分支记录。同一句跨图使用时分别计数。

Godot 核出 365 条可加载的台词，148 条没有可播的人物语音。365 条所选音频中，同一录音字节在不同发言名之间的重复有 0 组。声线表中的生成器预设仅用于定位候选，实际音频来源须靠哈希或听审确认。当前环境无法收听音频，整套录音的年龄听感与表演情绪待逐条试听；无台词 NPC、未收录的运行时动态对白不在统计内。

卖菜大婶与焦急妇人的九条在用语音已换录并在 Godot 实播。前者采用较低、更慢的声线，后者按求救、追问和致谢分开语速。旧后缀录音作为历史素材，游戏优先播放新分段。

角色设定采用[世界观角色谱](../world-bible.md)和场景立绘。

## 逐角色汇总

| 发言人 | 已核身份或配音方向 | 有音 / 分支 | 已对上录音来源 | 生成器预设 |
| --- | --- | ---: | --- | --- |
| 刑樊天 | 52 岁，师傅，沉稳 | 32 / 43 | 待追溯 | zh-CN-YunjianNeural |
| 戚云笙 | 21 岁，烈云盟盟主之女 | 27 / 29 | 待追溯 | zh-TW-HsiaoChenNeural |
| 封砚秋 | 24 岁，外在风度从容 | 18 / 21 | 待追溯 | 未登记 |
| 悦无姮 | 22 岁，凌月弟子，清冷 | 18 / 21 | 待追溯 | zh-CN-XiaoxiaoNeural |
| 苏雾笙 | 48 岁，茗雾庄主，文雅克制 | 9 / 18 | 待追溯 | zh-CN-YunjianNeural |
| 赵思颖 | 21 岁，医者 | 18 / 18 | 待追溯 | zh-CN-XiaoxiaoNeural |
| 沈青禾 | 按所列台词与立绘复核 | 13 / 13 | 待追溯 | zh-CN-XiaoxiaoNeural |
| 药师苏伯 | 年长男性，按立绘与称谓 | 7 / 13 | 待追溯 | zh-CN-YunjianNeural |
| 唐行舟 | 28 岁，爽朗 | 11 / 12 | 待追溯 | zh-CN-YunxiNeural |
| 薛影 | 27 岁，行事冷静 | 9 / 12 | 待追溯 | 未登记 |
| 守村人 | 较年长男性，晨市采用长者立绘 | 7 / 11 | 待追溯 | 未登记 |
| 护商镖师 | 按所列台词与立绘复核 | 7 / 11 | zh-CN-YunjianNeural | zh-CN-YunjianNeural |
| 诗会执事 | 按所列台词与立绘复核 | 9 / 10 | 待追溯 | 未登记 |
| 挑担脚夫 | 成年劳动者，换肩求助及答谢 | 6 / 8 | 待追溯 | 未登记 |
| 守钟僧 | 按所列台词与立绘复核 | 7 / 7 | 待追溯 | 未登记 |
| 杜青衫 | 48 岁，铁匠，粗粝 | 7 / 7 | 待追溯 | zh-CN-YunjianNeural |
| 漕工头领 | 按所列台词与立绘复核 | 7 / 7 | 待追溯 | 未登记 |
| 老漕卒 | 年长男性，按称谓 | 5 / 7 | 待追溯 | 未登记 |
| 老纸匠 | 年长工匠，按称谓 | 2 / 7 | 待追溯 | 未登记 |
| 外院录事 | 按所列台词与立绘复核 | 1 / 6 | zh-CN-YunyangNeural | 未登记 |
| 守窟僧 | 按所列台词与立绘复核 | 6 / 6 | 待追溯 | 未登记 |
| 客栈老板 | 按所列台词与立绘复核 | 5 / 6 | 待追溯 | zh-CN-YunjianNeural |
| 左明远 | 按所列台词与立绘复核 | 6 / 6 | 待追溯 | 未登记 |
| 武馆教头 | 按所列台词与立绘复核 | 6 / 6 | 待追溯 | zh-CN-YunjianNeural |
| 考校执事 | 按所列台词与立绘复核 | 2 / 6 | 待追溯 | 未登记 |
| 镖局枪手 | 按所列台词与立绘复核 | 0 / 6 | 待追溯 | 未登记 |
| 凌霜 | 45 岁，凌月掌门，沉稳冷静 | 5 / 5 | 待追溯 | zh-CN-XiaoxiaoNeural |
| 卖菜大婶 | 年长女性，按灰发立绘，担忧、叮嘱、释然 | 5 / 5 | zh-CN-XiaoxiaoNeural | zh-CN-XiaoxiaoNeural |
| 村塾先生 | 按所列台词与立绘复核 | 5 / 5 | 待追溯 | 未登记 |
| 伪旗统领 | 按所列台词与立绘复核 | 1 / 4 | 待追溯 | 未登记 |
| 古峰护粮守卫 | 按所列台词与立绘复核 | 4 / 4 | 待追溯 | 未登记 |
| 大会执事 | 按所列台词与立绘复核 | 3 / 4 | 待追溯 | 未登记 |
| 旧渡守望 | 按所列台词与立绘复核 | 2 / 4 | zh-CN-YunjianNeural | 未登记 |
| 段长风 | 按所列台词与立绘复核 | 0 / 4 | 待追溯 | 未登记 |
| 沈伯 | 年长男性，参农 | 2 / 4 | 待追溯 | 未登记 |
| 沈晚棠 | 按所列台词与立绘复核 | 4 / 4 | 待追溯 | zh-CN-XiaoxiaoNeural |
| 焦急妇人 | 中年女性，求救急切、等待疲惫、复命后松一口气 | 4 / 4 | zh-CN-XiaoyiNeural | zh-CN-XiaoyiNeural |
| 茶镇经手人 | 按所列台词与立绘复核 | 2 / 4 | zh-CN-YunjianNeural | 未登记 |
| 赵无忌 | 按所列台词与立绘复核 | 0 / 4 | 待追溯 | zh-CN-YunjianNeural |
| 会盟录事 | 按所列台词与立绘复核 | 3 / 3 | 待追溯 | 未登记 |
| 古疆雷 | 55 岁，古峰掌门 | 1 / 3 | 待追溯 | 未登记 |
| 大会乐师 | 按所列台词与立绘复核 | 3 / 3 | 待追溯 | zh-CN-XiaoxiaoNeural |
| 失踪脚夫 | 按所列台词与立绘复核 | 3 / 3 | 待追溯 | 未登记 |
| 守山弟子 | 按所列台词与立绘复核 | 3 / 3 | 待追溯 | 未登记 |
| 棋叟 | 按所列台词与立绘复核 | 3 / 3 | 待追溯 | 未登记 |
| 沈半盏 | 55 岁，酒馆老板，和气 | 3 / 3 | 待追溯 | zh-CN-YunjianNeural |
| 清虚道长 | 按所列台词与立绘复核 | 3 / 3 | 待追溯 | 未登记 |
| 游天鸿 | 按所列台词与立绘复核 | 0 / 3 | 待追溯 | 未登记 |
| 游方棋客 | 按所列台词与立绘复核 | 3 / 3 | 待追溯 | 未登记 |
| 游方道人 | 按所列台词与立绘复核 | 3 / 3 | 待追溯 | 未登记 |
| 玄真道长 | 62 岁，武当掌门 | 2 / 3 | 待追溯 | 未登记 |
| 被绑男子 | 按所列台词与立绘复核 | 2 / 3 | 待追溯 | zh-CN-YunxiNeural |
| 论剑执笔人 | 按所列台词与立绘复核 | 3 / 3 | 待追溯 | 未登记 |
| 走货郎 | 按所列台词与立绘复核 | 3 / 3 | 待追溯 | zh-CN-YunxiNeural |
| 合练教习 | 按所列台词与立绘复核 | 2 / 2 | 待追溯 | 未登记 |
| 寒岭守藏人 | 按所列台词与立绘复核 | 0 / 2 | 待追溯 | 未登记 |
| 店小二 | 按所列台词与立绘复核 | 2 / 2 | 待追溯 | zh-CN-YunxiNeural |
| 府衙老吏 | 按所列台词与立绘复核 | 2 / 2 | 待追溯 | 未登记 |
| 归田村民 | 按所列台词与立绘复核 | 0 / 2 | 待追溯 | 未登记 |
| 旧案幸存者 | 按所列台词与立绘复核 | 0 / 2 | 待追溯 | 未登记 |
| 旧渡记档人 | 按所列台词与立绘复核 | 2 / 2 | 待追溯 | 未登记 |
| 晒药婆婆 | 年长女性，按立绘与称谓 | 2 / 2 | 待追溯 | zh-CN-XiaoyiNeural |
| 楚泠 | 按所列台词与立绘复核 | 2 / 2 | 待追溯 | zh-CN-XiaoxiaoNeural |
| 江湖散兵 | 按所列台词与立绘复核 | 2 / 2 | 待追溯 | zh-CN-YunjianNeural |
| 汴州驿丞 | 按所列台词与立绘复核 | 0 / 2 | 待追溯 | 未登记 |
| 渡船管事 | 按所列台词与立绘复核 | 0 / 2 | 待追溯 | 未登记 |
| 烈云封渡寻迹手 | 按所列台词与立绘复核 | 0 / 2 | 待追溯 | 未登记 |
| 烈云强硬派巡守 | 按所列台词与立绘复核 | 0 / 2 | 待追溯 | 未登记 |
| 终局案卷吏 | 按所列台词与立绘复核 | 2 / 2 | 待追溯 | 未登记 |
| 范掌柜 | 按所列台词与立绘复核 | 2 / 2 | 待追溯 | 未登记 |
| 药铺学徒 | 按所列台词与立绘复核 | 0 / 2 | 待追溯 | 未登记 |
| 药铺掌柜 | 按所列台词与立绘复核 | 0 / 2 | 待追溯 | 未登记 |
| 襄州守备 | 按所列台词与立绘复核 | 0 / 2 | 待追溯 | 未登记 |
| 货郎 | 按所列台词与立绘复核 | 0 / 2 | 待追溯 | zh-CN-YunxiNeural |
| 走村货郎 | 按所列台词与立绘复核 | 0 / 2 | 待追溯 | zh-CN-YunxiNeural |
| 采药村妇 | 按所列台词与立绘复核 | 2 / 2 | 待追溯 | zh-CN-XiaoyiNeural |
| 金陵水巡 | 按所列台词与立绘复核 | 0 / 2 | 待追溯 | 未登记 |
| 霍长空 | 50 岁，华山掌门 | 1 / 2 | 待追溯 | 未登记 |
| 伪烈云盟首领 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 伪烈云突袭手 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 凌月弟子 | 年轻女性，答谢归还腰牌 | 1 / 1 | zh-CN-XiaoyiNeural | 未登记 |
| 华山剑士 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 古墓守卫 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 守门村民 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | zh-CN-YunjianNeural |
| 少林俗家·岳闻钟 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 巡村老兵 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 府尹 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 废宅守卫 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 捕快韩策 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 晒盐村民 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 武当守山弟子 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 武当弟子 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 洛阳地痞 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 洛阳门吏 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 潮门船头 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 烈云破阵校尉 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 留守山贼 | 按所列台词与立绘复核 | 1 / 1 | zh-CN-YunjianNeural | zh-CN-YunjianNeural |
| 矿洞巡哨 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 矿道灭口人 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 神秘商人 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | zh-CN-YunjianNeural |
| 聚义厅引路人 | 按所列台词与立绘复核 | 1 / 1 | zh-CN-YunjianNeural | 未登记 |
| 船夫赵大江 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 茗雾假令传使 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 茗雾内署护档使 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 茗雾寻迹者 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 茗雾封针使 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 茗雾截盟使 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 茗雾截证客 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 茗雾教习 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 茗雾断卷客 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 茗雾旧教习 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 茗雾暗哨 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 茗雾机关监守 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 茗雾焚册客 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 茗雾销卷使 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 茶客 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 茶岭茶农 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 蒙面人 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 蒙面头领 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 行旅货郎 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 观瀑老者 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 货栈账房 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 雪岭追兵 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 雪路劫粮客 | 按所列台词与立绘复核 | 1 / 1 | 待追溯 | 未登记 |
| 驿站记事 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |
| 黑衣人 | 按所列台词与立绘复核 | 0 / 1 | 待追溯 | 未登记 |

## 逐地图对白和音频

| 场景 | 发言人 | 对白节点 | 游戏情绪键 | 实际选择 |
| --- | --- | --- | --- | --- |
| ch1_s0_linxi_main_walkable | 杜青衫 | [ch1_main_street_duqingshan / start](../../game/data/dialogs/ch1_main_street_duqingshan.tres) | normal | [10.4 秒](../../game/art/audio/voices/ch1/ch1_main_street_duqingshan/%E6%9D%9C%E9%9D%92%E8%A1%AB_start_enormal.mp3) |
| ch1_s0_linxi_main_walkable | 沈半盏 | [ch1_main_street_shenbanzhan / n3](../../game/data/dialogs/ch1_main_street_shenbanzhan.tres) | normal | [11.3 秒](../../game/art/audio/voices/ch1/ch1_main_street_shenbanzhan/%E6%B2%88%E5%8D%8A%E7%9B%8F_n3_enormal.mp3) |
| ch1_s0_linxi_main_walkable | 沈半盏 | [ch1_main_street_shenbanzhan / n5](../../game/data/dialogs/ch1_main_street_shenbanzhan.tres) | normal | [16.6 秒](../../game/art/audio/voices/ch1/ch1_main_street_shenbanzhan/%E6%B2%88%E5%8D%8A%E7%9B%8F_n5_enormal.mp3) |
| ch1_s0_linxi_main_walkable | 沈半盏 | [ch1_main_street_shenbanzhan / start](../../game/data/dialogs/ch1_main_street_shenbanzhan.tres) | normal | [7.1 秒](../../game/art/audio/voices/ch1/ch1_main_street_shenbanzhan/%E6%B2%88%E5%8D%8A%E7%9B%8F_start_enormal.mp3) |
| ch1_s0_linxi_main_walkable | 走货郎 | [ch1_main_street_vendor / n3](../../game/data/dialogs/ch1_main_street_vendor.tres) | normal | [16.9 秒](../../game/art/audio/voices/ch1/ch1_main_street_vendor/%E8%B5%B0%E8%B4%A7%E9%83%8E_n3_enormal.mp3) |
| ch1_s0_linxi_main_walkable | 走货郎 | [ch1_main_street_vendor / n5](../../game/data/dialogs/ch1_main_street_vendor.tres) | normal | [21.0 秒](../../game/art/audio/voices/ch1/ch1_main_street_vendor/%E8%B5%B0%E8%B4%A7%E9%83%8E_n5_enormal.mp3) |
| ch1_s0_linxi_main_walkable | 走货郎 | [ch1_main_street_vendor / start](../../game/data/dialogs/ch1_main_street_vendor.tres) | normal | [9.0 秒](../../game/art/audio/voices/ch1/ch1_main_street_vendor/%E8%B5%B0%E8%B4%A7%E9%83%8E_start_enormal.mp3) |
| ch1_s0_linxi_main_walkable | 武馆教头 | [ch1_martial_hall_master / basic](../../game/data/dialogs/ch1_martial_hall_master.tres) | normal | [6.5 秒](../../game/art/audio/voices/ch1/ch1_martial_hall_master/%E6%AD%A6%E9%A6%86%E6%95%99%E5%A4%B4_basic_enormal.mp3) |
| ch1_s0_linxi_main_walkable | 武馆教头 | [ch1_martial_hall_master / senior](../../game/data/dialogs/ch1_martial_hall_master.tres) | normal | [5.9 秒](../../game/art/audio/voices/ch1/ch1_martial_hall_master/%E6%AD%A6%E9%A6%86%E6%95%99%E5%A4%B4_senior_enormal.mp3) |
| ch1_s0_linxi_main_walkable | 武馆教头 | [ch1_martial_hall_master / start](../../game/data/dialogs/ch1_martial_hall_master.tres) | normal | [6.9 秒](../../game/art/audio/voices/ch1/ch1_martial_hall_master/%E6%AD%A6%E9%A6%86%E6%95%99%E5%A4%B4_start_enormal.mp3) |
| ch1_s1_road | 江湖散兵 | [ch1_road_corpse / n4](../../game/data/dialogs/ch1_road_corpse.tres) | threat | [11.8 秒](../../game/art/audio/voices/ch1/ch1_road_corpse/%E6%B1%9F%E6%B9%96%E6%95%A3%E5%85%B5_n4_ethreat.mp3) |
| ch1_s1_road | 江湖散兵 | [ch1_road_corpse / n6](../../game/data/dialogs/ch1_road_corpse.tres) | normal | [6.6 秒](../../game/art/audio/voices/ch1/ch1_road_corpse/%E6%B1%9F%E6%B9%96%E6%95%A3%E5%85%B5_n6_enormal.mp3) |
| ch1_s1_road | 范掌柜 | [ch1_side_caravan_road_start / start](../../game/data/dialogs/ch1_side_caravan_road_start.tres) | normal | [8.0 秒](../../game/art/audio/voices/ch1/ch1_side_caravan_road_start/%E8%8C%83%E6%8E%8C%E6%9F%9C_start_seg01_dialog.mp3) |
| ch1_s1_road | 范掌柜 | [ch1_side_caravan_victory / thanks](../../game/data/dialogs/ch1_side_caravan_victory.tres) | normal | [7.6 秒](../../game/art/audio/voices/ch1/ch1_side_caravan_victory/%E8%8C%83%E6%8E%8C%E6%9F%9C_thanks_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 武馆教头 | [ch1_martial_hall_master / basic](../../game/data/dialogs/ch1_martial_hall_master.tres) | normal | [6.5 秒](../../game/art/audio/voices/ch1/ch1_martial_hall_master/%E6%AD%A6%E9%A6%86%E6%95%99%E5%A4%B4_basic_enormal.mp3) |
| ch1_s2_qingfeng | 武馆教头 | [ch1_martial_hall_master / senior](../../game/data/dialogs/ch1_martial_hall_master.tres) | normal | [5.9 秒](../../game/art/audio/voices/ch1/ch1_martial_hall_master/%E6%AD%A6%E9%A6%86%E6%95%99%E5%A4%B4_senior_enormal.mp3) |
| ch1_s2_qingfeng | 武馆教头 | [ch1_martial_hall_master / start](../../game/data/dialogs/ch1_martial_hall_master.tres) | normal | [6.9 秒](../../game/art/audio/voices/ch1/ch1_martial_hall_master/%E6%AD%A6%E9%A6%86%E6%95%99%E5%A4%B4_start_enormal.mp3) |
| ch1_s2_qingfeng | 护商镖师 | [ch1_s2_bandit_cave_done / start](../../game/data/dialogs/ch1_s2_bandit_cave_done.tres) | normal | 无可播人物语音 |
| ch1_s2_qingfeng | 护商镖师 | [ch1_s2_bandit_cave_rumour / accept](../../game/data/dialogs/ch1_s2_bandit_cave_rumour.tres) | normal | [9.8 秒](../../game/art/audio/voices/ch1/ch1_s2_bandit_cave_rumour/%E6%8A%A4%E5%95%86%E9%95%96%E5%B8%88_accept_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 护商镖师 | [ch1_s2_bandit_cave_rumour / start](../../game/data/dialogs/ch1_s2_bandit_cave_rumour.tres) | normal | [10.4 秒](../../game/art/audio/voices/ch1/ch1_s2_bandit_cave_rumour/%E6%8A%A4%E5%95%86%E9%95%96%E5%B8%88_start_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 护商镖师 | [ch1_s2_bandit_cave_turnin / start](../../game/data/dialogs/ch1_s2_bandit_cave_turnin.tres) | normal | 无可播人物语音 |
| ch1_s2_qingfeng | 护商镖师 | [ch1_s2_bandit_cave_waiting / start](../../game/data/dialogs/ch1_s2_bandit_cave_waiting.tres) | normal | [7.8 秒](../../game/art/audio/voices/ch1/ch1_s2_bandit_cave_waiting/%E6%8A%A4%E5%95%86%E9%95%96%E5%B8%88_start.mp3) |
| ch1_s2_qingfeng | 镖局枪手 | [ch1_s2_caravan_spearman_idle / start](../../game/data/dialogs/ch1_s2_caravan_spearman_idle.tres) | normal | 无可播人物语音 |
| ch1_s2_qingfeng | 焦急妇人 | [ch1_s2_crying_woman / start](../../game/data/dialogs/ch1_s2_crying_woman.tres) | fear | [8.6 秒](../../game/art/audio/voices/ch1/ch1_s2_crying_woman/%E7%84%A6%E6%80%A5%E5%A6%87%E4%BA%BA_start_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 焦急妇人 | [ch1_s2_crying_woman_done / start](../../game/data/dialogs/ch1_s2_crying_woman_done.tres) | normal | [5.6 秒](../../game/art/audio/voices/ch1/ch1_s2_crying_woman_done/%E7%84%A6%E6%80%A5%E5%A6%87%E4%BA%BA_start_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 焦急妇人 | [ch1_s2_crying_woman_turnin / start](../../game/data/dialogs/ch1_s2_crying_woman_turnin.tres) | normal | [7.7 秒](../../game/art/audio/voices/ch1/ch1_s2_crying_woman_turnin/%E7%84%A6%E6%80%A5%E5%A6%87%E4%BA%BA_start_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 焦急妇人 | [ch1_s2_crying_woman_waiting / start](../../game/data/dialogs/ch1_s2_crying_woman_waiting.tres) | normal | [7.3 秒](../../game/art/audio/voices/ch1/ch1_s2_crying_woman_waiting/%E7%84%A6%E6%80%A5%E5%A6%87%E4%BA%BA_start_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 守村人 | [ch1_s2_guard / notice](../../game/data/dialogs/ch1_s2_guard.tres) | normal | [10.0 秒](../../game/art/audio/voices/ch1/ch1_s2_guard/%E5%AE%88%E6%9D%91%E4%BA%BA_notice_enormal.mp3) |
| ch1_s2_qingfeng | 守村人 | [ch1_s2_guard / start](../../game/data/dialogs/ch1_s2_guard.tres) | normal | [9.0 秒](../../game/art/audio/voices/ch1/ch1_s2_guard/%E5%AE%88%E6%9D%91%E4%BA%BA_start_enormal.mp3) |
| ch1_s2_qingfeng | 守村人 | [ch1_s2_guard_after_report / start](../../game/data/dialogs/ch1_s2_guard_after_report.tres) | normal | 无可播人物语音 |
| ch1_s2_qingfeng | 守村人 | [ch1_s2_guard_report / reply](../../game/data/dialogs/ch1_s2_guard_report.tres) | normal | [9.2 秒](../../game/art/audio/voices/ch1/ch1_s2_guard_report/%E5%AE%88%E6%9D%91%E4%BA%BA_reply_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 客栈老板 | [ch1_s2_inn_keeper / b](../../game/data/dialogs/ch1_s2_inn_keeper.tres) | normal | [7.3 秒](../../game/art/audio/voices/ch1/ch1_s2_inn_keeper/%E5%AE%A2%E6%A0%88%E8%80%81%E6%9D%BF_b_enormal.mp3) |
| ch1_s2_qingfeng | 客栈老板 | [ch1_s2_inn_keeper / start](../../game/data/dialogs/ch1_s2_inn_keeper.tres) | concerned | [5.2 秒](../../game/art/audio/voices/ch1/ch1_s2_inn_keeper/%E5%AE%A2%E6%A0%88%E8%80%81%E6%9D%BF_start.mp3) |
| ch1_s2_qingfeng | 店小二 | [ch1_s2_inn_waiter / start](../../game/data/dialogs/ch1_s2_inn_waiter.tres) | normal | [7.1 秒](../../game/art/audio/voices/ch1/ch1_s2_inn_waiter/%E5%BA%97%E5%B0%8F%E4%BA%8C_start_enormal.mp3) |
| ch1_s2_qingfeng | 神秘商人 | [ch1_s2_merchant / start](../../game/data/dialogs/ch1_s2_merchant.tres) | normal | [7.4 秒](../../game/art/audio/voices/ch1/ch1_s2_merchant/%E7%A5%9E%E7%A7%98%E5%95%86%E4%BA%BA_start_enormal.mp3) |
| ch1_s2_qingfeng | 护商镖师 | [ch1_s2_patrol_scout / accept](../../game/data/dialogs/ch1_s2_patrol_scout.tres) | normal | [6.5 秒](../../game/art/audio/voices/ch1/ch1_s2_patrol_scout/%E6%8A%A4%E5%95%86%E9%95%96%E5%B8%88_accept_enormal.mp3) |
| ch1_s2_qingfeng | 护商镖师 | [ch1_s2_patrol_scout / start](../../game/data/dialogs/ch1_s2_patrol_scout.tres) | normal | [7.8 秒](../../game/art/audio/voices/ch1/ch1_s2_patrol_scout/%E6%8A%A4%E5%95%86%E9%95%96%E5%B8%88_start_enormal.mp3) |
| ch1_s2_qingfeng | 护商镖师 | [ch1_s2_patrol_scout_done / start](../../game/data/dialogs/ch1_s2_patrol_scout_done.tres) | normal | 无可播人物语音 |
| ch1_s2_qingfeng | 护商镖师 | [ch1_s2_patrol_scout_turnin / start](../../game/data/dialogs/ch1_s2_patrol_scout_turnin.tres) | normal | 无可播人物语音 |
| ch1_s2_qingfeng | 护商镖师 | [ch1_s2_patrol_scout_waiting / start](../../game/data/dialogs/ch1_s2_patrol_scout_waiting.tres) | normal | [6.1 秒](../../game/art/audio/voices/ch1/ch1_s2_patrol_scout_waiting/%E6%8A%A4%E5%95%86%E9%95%96%E5%B8%88_start.mp3) |
| ch1_s2_qingfeng | 护商镖师 | [ch1_s2_scout_main_clue / start](../../game/data/dialogs/ch1_s2_scout_main_clue.tres) | normal | [9.0 秒](../../game/art/audio/voices/ch1/ch1_s2_scout_main_clue/%E6%8A%A4%E5%95%86%E9%95%96%E5%B8%88_start_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 卖菜大婶 | [ch1_s2_vegetable_vendor / accept](../../game/data/dialogs/ch1_s2_vegetable_vendor.tres) | normal | [6.4 秒](../../game/art/audio/voices/ch1/ch1_s2_vegetable_vendor/%E5%8D%96%E8%8F%9C%E5%A4%A7%E5%A9%B6_accept_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 卖菜大婶 | [ch1_s2_vegetable_vendor / start](../../game/data/dialogs/ch1_s2_vegetable_vendor.tres) | concerned | [10.5 秒](../../game/art/audio/voices/ch1/ch1_s2_vegetable_vendor/%E5%8D%96%E8%8F%9C%E5%A4%A7%E5%A9%B6_start_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 卖菜大婶 | [ch1_s2_vegetable_vendor_done / start](../../game/data/dialogs/ch1_s2_vegetable_vendor_done.tres) | normal | [6.3 秒](../../game/art/audio/voices/ch1/ch1_s2_vegetable_vendor_done/%E5%8D%96%E8%8F%9C%E5%A4%A7%E5%A9%B6_start_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 卖菜大婶 | [ch1_s2_vegetable_vendor_turnin / start](../../game/data/dialogs/ch1_s2_vegetable_vendor_turnin.tres) | normal | [6.8 秒](../../game/art/audio/voices/ch1/ch1_s2_vegetable_vendor_turnin/%E5%8D%96%E8%8F%9C%E5%A4%A7%E5%A9%B6_start_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 卖菜大婶 | [ch1_s2_vegetable_vendor_waiting / start](../../game/data/dialogs/ch1_s2_vegetable_vendor_waiting.tres) | normal | [8.7 秒](../../game/art/audio/voices/ch1/ch1_s2_vegetable_vendor_waiting/%E5%8D%96%E8%8F%9C%E5%A4%A7%E5%A9%B6_start_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 镖局枪手 | [ch1_side_caravan_done / start](../../game/data/dialogs/ch1_side_caravan_done.tres) | normal | 无可播人物语音 |
| ch1_s2_qingfeng | 镖局枪手 | [ch1_side_caravan_offer / accept](../../game/data/dialogs/ch1_side_caravan_offer.tres) | normal | 无可播人物语音 |
| ch1_s2_qingfeng | 镖局枪手 | [ch1_side_caravan_offer / start](../../game/data/dialogs/ch1_side_caravan_offer.tres) | normal | 无可播人物语音 |
| ch1_s2_qingfeng | 镖局枪手 | [ch1_side_caravan_turnin / start](../../game/data/dialogs/ch1_side_caravan_turnin.tres) | normal | 无可播人物语音 |
| ch1_s2_qingfeng | 镖局枪手 | [ch1_side_caravan_waiting / start](../../game/data/dialogs/ch1_side_caravan_waiting.tres) | normal | 无可播人物语音 |
| ch1_s2_qingfeng | 挑担脚夫 | [huilan_openworld_balance / right](../../game/data/dialogs/huilan_openworld_balance.tres) | normal | [7.6 秒](../../game/art/audio/voices/hui/huilan_openworld_balance/%E6%8C%91%E6%8B%85%E8%84%9A%E5%A4%AB_right_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 挑担脚夫 | [huilan_openworld_balance / start](../../game/data/dialogs/huilan_openworld_balance.tres) | normal | [8.9 秒](../../game/art/audio/voices/hui/huilan_openworld_balance/%E6%8C%91%E6%8B%85%E8%84%9A%E5%A4%AB_start_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 挑担脚夫 | [huilan_openworld_balance / wrong](../../game/data/dialogs/huilan_openworld_balance.tres) | normal | [6.9 秒](../../game/art/audio/voices/hui/huilan_openworld_balance/%E6%8C%91%E6%8B%85%E8%84%9A%E5%A4%AB_wrong_seg01_dialog.mp3) |
| ch1_s2_qingfeng | 挑担脚夫 | [huilan_openworld_balance_done / start](../../game/data/dialogs/huilan_openworld_balance_done.tres) | normal | 无可播人物语音 |
| ch1_s2_qingfeng_walkable | 守门村民 | [ch1_zhuwei_arrival / n3](../../game/data/dialogs/ch1_zhuwei_arrival.tres) | concerned | [8.3 秒](../../game/art/audio/voices/ch1/ch1_zhuwei_arrival/%E5%AE%88%E9%97%A8%E6%9D%91%E6%B0%91_n3.mp3) |
| ch1_s3_ruin_inner | 赵无忌 | [ch1_s3_ruin_after_boss / n2](../../game/data/dialogs/ch1_s3_ruin_after_boss.tres) | normal | 无可播人物语音 |
| ch1_s3_ruin_inner | 赵无忌 | [ch1_s3_ruin_boss / n3](../../game/data/dialogs/ch1_s3_ruin_boss.tres) | normal | 无可播人物语音 |
| ch1_s3_ruin_inner | 赵无忌 | [ch1_s3_ruin_boss / n5](../../game/data/dialogs/ch1_s3_ruin_boss.tres) | normal | 无可播人物语音 |
| ch1_s3_ruin_inner | 赵无忌 | [ch1_s3_ruin_boss / start](../../game/data/dialogs/ch1_s3_ruin_boss.tres) | normal | 无可播人物语音 |
| ch1_s3_west_ruin | 被绑男子 | [ch1_s3_bound_man / c](../../game/data/dialogs/ch1_s3_bound_man.tres) | normal | [7.9 秒](../../game/art/audio/voices/ch1/ch1_s3_bound_man/%E8%A2%AB%E7%BB%91%E7%94%B7%E5%AD%90_c_enormal.mp3) |
| ch1_s3_west_ruin | 被绑男子 | [ch1_s3_bound_man / start](../../game/data/dialogs/ch1_s3_bound_man.tres) | fear | [3.8 秒](../../game/art/audio/voices/ch1/ch1_s3_bound_man/%E8%A2%AB%E7%BB%91%E7%94%B7%E5%AD%90_start_efear.mp3) |
| ch1_s3_west_ruin | 被绑男子 | [ch1_s3_bound_man_guarded / start](../../game/data/dialogs/ch1_s3_bound_man_guarded.tres) | normal | 无可播人物语音 |
| ch1_s3_west_ruin | 废宅守卫 | [ch1_s3_outer_guard / start](../../game/data/dialogs/ch1_s3_outer_guard.tres) | normal | [3.8 秒](../../game/art/audio/voices/ch1/ch1_s3_outer_guard/%E5%BA%9F%E5%AE%85%E5%AE%88%E5%8D%AB_start_enormal.mp3) |
| ch2_s1_market_inn | 棋叟 | [ch2_go_puzzle / right](../../game/data/dialogs/ch2_go_puzzle.tres) | normal | [5.5 秒](../../game/art/audio/voices/ch2/ch2_go_puzzle/%E6%A3%8B%E5%8F%9F_right_seg01_dialog.mp3) |
| ch2_s1_market_inn | 棋叟 | [ch2_go_puzzle / start](../../game/data/dialogs/ch2_go_puzzle.tres) | normal | [6.9 秒](../../game/art/audio/voices/ch2/ch2_go_puzzle/%E6%A3%8B%E5%8F%9F_start_seg01_dialog.mp3) |
| ch2_s1_market_inn | 棋叟 | [ch2_go_puzzle / wrong](../../game/data/dialogs/ch2_go_puzzle.tres) | normal | [6.6 秒](../../game/art/audio/voices/ch2/ch2_go_puzzle/%E6%A3%8B%E5%8F%9F_wrong_seg01_dialog.mp3) |
| ch2_s1_market_inn | 客栈老板 | [ch2_missing_disciple_offer / start](../../game/data/dialogs/ch2_missing_disciple_offer.tres) | normal | [7.4 秒](../../game/art/audio/voices/ch2/ch2_missing_disciple_offer/%E5%AE%A2%E6%A0%88%E8%80%81%E6%9D%BF_start.mp3) |
| ch2_s1_market_inn | 楚泠 | [ch2_moon_guqin_offer / start](../../game/data/dialogs/ch2_moon_guqin_offer.tres) | normal | [8.3 秒](../../game/art/audio/voices/ch2/ch2_moon_guqin_offer/%E6%A5%9A%E6%B3%A0_start_seg01_dialog.mp3) |
| ch2_s1_market_inn | 楚泠 | [ch2_moon_guqin_turnin / start](../../game/data/dialogs/ch2_moon_guqin_turnin.tres) | normal | [8.8 秒](../../game/art/audio/voices/ch2/ch2_moon_guqin_turnin/%E6%A5%9A%E6%B3%A0_start_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 船夫赵大江 | [ch2_boat_gang_offer / start](../../game/data/dialogs/ch2_boat_gang_offer.tres) | normal | [10.4 秒](../../game/art/audio/voices/ch2/ch2_boat_gang_offer/%E8%88%B9%E5%A4%AB%E8%B5%B5%E5%A4%A7%E6%B1%9F_start_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 沈晚棠 | [ch2_canglong_fragment_upper / start](../../game/data/dialogs/ch2_canglong_fragment_upper.tres) | normal | [8.7 秒](../../game/art/audio/voices/ch2/ch2_canglong_fragment_upper/%E6%B2%88%E6%99%9A%E6%A3%A0_start_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 封砚秋 | [ch2_guyun_feng_first_meeting / correct](../../game/data/dialogs/ch2_guyun_feng_first_meeting.tres) | normal | [14.3 秒](../../game/art/audio/voices/ch2/ch2_guyun_feng_first_meeting/%E5%B0%81%E7%A0%9A%E7%A7%8B_correct_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 封砚秋 | [ch2_guyun_feng_first_meeting / puzzle](../../game/data/dialogs/ch2_guyun_feng_first_meeting.tres) | normal | [11.1 秒](../../game/art/audio/voices/ch2/ch2_guyun_feng_first_meeting/%E5%B0%81%E7%A0%9A%E7%A7%8B_puzzle_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 封砚秋 | [ch2_guyun_feng_first_meeting / start](../../game/data/dialogs/ch2_guyun_feng_first_meeting.tres) | normal | [11.8 秒](../../game/art/audio/voices/ch2/ch2_guyun_feng_first_meeting/%E5%B0%81%E7%A0%9A%E7%A7%8B_start_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 封砚秋 | [ch2_guyun_feng_first_meeting / wrong](../../game/data/dialogs/ch2_guyun_feng_first_meeting.tres) | normal | [8.3 秒](../../game/art/audio/voices/ch2/ch2_guyun_feng_first_meeting/%E5%B0%81%E7%A0%9A%E7%A7%8B_wrong_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 沈伯 | [ch2_herb_thief_complete / n2](../../game/data/dialogs/ch2_herb_thief_complete.tres) | normal | [7.5 秒](../../game/art/audio/voices/ch2/ch2_herb_thief_complete/%E6%B2%88%E4%BC%AF_n2_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 沈伯 | [ch2_herb_thief_done / start](../../game/data/dialogs/ch2_herb_thief_done.tres) | normal | 无可播人物语音 |
| ch2_s1_zhuwei_market | 沈伯 | [ch2_herb_thief_offer / start](../../game/data/dialogs/ch2_herb_thief_offer.tres) | normal | [9.3 秒](../../game/art/audio/voices/ch2/ch2_herb_thief_offer/%E6%B2%88%E4%BC%AF_start_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 沈伯 | [ch2_herb_thief_waiting / start](../../game/data/dialogs/ch2_herb_thief_waiting.tres) | normal | 无可播人物语音 |
| ch2_s1_zhuwei_market | 药铺掌柜 | [ch2_market_apothecary / shop](../../game/data/dialogs/ch2_market_apothecary.tres) | normal | 无可播人物语音 |
| ch2_s1_zhuwei_market | 药铺掌柜 | [ch2_market_apothecary / start](../../game/data/dialogs/ch2_market_apothecary.tres) | normal | 无可播人物语音 |
| ch2_s1_zhuwei_market | 守村人 | [ch2_market_gatekeeper_done / start](../../game/data/dialogs/ch2_market_gatekeeper_done.tres) | normal | 无可播人物语音 |
| ch2_s1_zhuwei_market | 守村人 | [ch2_market_gatekeeper_early_visit / start](../../game/data/dialogs/ch2_market_gatekeeper_early_visit.tres) | concerned | 无可播人物语音 |
| ch2_s1_zhuwei_market | 守村人 | [ch2_market_gatekeeper_followup / start](../../game/data/dialogs/ch2_market_gatekeeper_followup.tres) | normal | [7.6 秒](../../game/art/audio/voices/ch2/ch2_market_gatekeeper_followup/%E5%AE%88%E6%9D%91%E4%BA%BA_start_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 守村人 | [ch2_market_gatekeeper_wait / start](../../game/data/dialogs/ch2_market_gatekeeper_wait.tres) | normal | 无可播人物语音 |
| ch2_s1_zhuwei_market | 货郎 | [ch2_market_hawker / n3](../../game/data/dialogs/ch2_market_hawker.tres) | normal | 无可播人物语音 |
| ch2_s1_zhuwei_market | 货郎 | [ch2_market_hawker / start](../../game/data/dialogs/ch2_market_hawker.tres) | normal | 无可播人物语音 |
| ch2_s1_zhuwei_market | 捕快韩策 | [ch2_river_death_offer / start](../../game/data/dialogs/ch2_river_death_offer.tres) | normal | [11.2 秒](../../game/art/audio/voices/ch2/ch2_river_death_offer/%E6%8D%95%E5%BF%AB%E9%9F%A9%E7%AD%96_start_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 沈晚棠 | [ch2_tournament_after / start](../../game/data/dialogs/ch2_tournament_after.tres) | normal | [8.1 秒](../../game/art/audio/voices/ch2/ch2_tournament_after/%E6%B2%88%E6%99%9A%E6%A3%A0_start_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 沈晚棠 | [ch2_tournament_complete / start](../../game/data/dialogs/ch2_tournament_complete.tres) | normal | [8.5 秒](../../game/art/audio/voices/ch2/ch2_tournament_complete/%E6%B2%88%E6%99%9A%E6%A3%A0_start_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 沈晚棠 | [ch2_tournament_offer / start](../../game/data/dialogs/ch2_tournament_offer.tres) | normal | [7.5 秒](../../game/art/audio/voices/ch2/ch2_tournament_offer/%E6%B2%88%E6%99%9A%E6%A3%A0_start_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 守村人 | [ch2_zhuwei_intro / n2](../../game/data/dialogs/ch2_zhuwei_intro.tres) | normal | [9.9 秒](../../game/art/audio/voices/ch2/ch2_zhuwei_intro/%E5%AE%88%E6%9D%91%E4%BA%BA_n2_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 守村人 | [ch8_aftermath_zhuwei / end](../../game/data/dialogs/ch8_aftermath_zhuwei.tres) | normal | [10.2 秒](../../game/art/audio/voices/ch8/ch8_aftermath_zhuwei/%E5%AE%88%E6%9D%91%E4%BA%BA_end_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 守村人 | [ch8_aftermath_zhuwei / start](../../game/data/dialogs/ch8_aftermath_zhuwei.tres) | normal | [11.3 秒](../../game/art/audio/voices/ch8/ch8_aftermath_zhuwei/%E5%AE%88%E6%9D%91%E4%BA%BA_start_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 戚云笙 | [ch8_relationship_qi_yunsheng / independent](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) | normal | [9.8 秒](../../game/art/audio/voices/ch8/ch8_relationship_qi_yunsheng/%E6%88%9A%E4%BA%91%E7%AC%99_independent_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 戚云笙 | [ch8_relationship_qi_yunsheng / start](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) | normal | [9.9 秒](../../game/art/audio/voices/ch8/ch8_relationship_qi_yunsheng/%E6%88%9A%E4%BA%91%E7%AC%99_start_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 戚云笙 | [ch8_relationship_qi_yunsheng / together](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) | normal | [10.6 秒](../../game/art/audio/voices/ch8/ch8_relationship_qi_yunsheng/%E6%88%9A%E4%BA%91%E7%AC%99_together_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 悦无姮 | [ch8_relationship_yuewuheng / independent](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) | normal | [7.7 秒](../../game/art/audio/voices/ch8/ch8_relationship_yuewuheng/%E6%82%A6%E6%97%A0%E5%A7%AE_independent_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 悦无姮 | [ch8_relationship_yuewuheng / start](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) | normal | [8.5 秒](../../game/art/audio/voices/ch8/ch8_relationship_yuewuheng/%E6%82%A6%E6%97%A0%E5%A7%AE_start_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 悦无姮 | [ch8_relationship_yuewuheng / together](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) | normal | [6.0 秒](../../game/art/audio/voices/ch8/ch8_relationship_yuewuheng/%E6%82%A6%E6%97%A0%E5%A7%AE_together_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 赵思颖 | [ch8_relationship_zhao_siying / independent](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) | normal | [7.9 秒](../../game/art/audio/voices/ch8/ch8_relationship_zhao_siying/%E8%B5%B5%E6%80%9D%E9%A2%96_independent_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 赵思颖 | [ch8_relationship_zhao_siying / start](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) | normal | [10.6 秒](../../game/art/audio/voices/ch8/ch8_relationship_zhao_siying/%E8%B5%B5%E6%80%9D%E9%A2%96_start_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 赵思颖 | [ch8_relationship_zhao_siying / together](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) | normal | [7.9 秒](../../game/art/audio/voices/ch8/ch8_relationship_zhao_siying/%E8%B5%B5%E6%80%9D%E9%A2%96_together_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 挑担脚夫 | [huilan_openworld_balance / right](../../game/data/dialogs/huilan_openworld_balance.tres) | normal | [7.6 秒](../../game/art/audio/voices/hui/huilan_openworld_balance/%E6%8C%91%E6%8B%85%E8%84%9A%E5%A4%AB_right_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 挑担脚夫 | [huilan_openworld_balance / start](../../game/data/dialogs/huilan_openworld_balance.tres) | normal | [8.9 秒](../../game/art/audio/voices/hui/huilan_openworld_balance/%E6%8C%91%E6%8B%85%E8%84%9A%E5%A4%AB_start_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 挑担脚夫 | [huilan_openworld_balance / wrong](../../game/data/dialogs/huilan_openworld_balance.tres) | normal | [6.9 秒](../../game/art/audio/voices/hui/huilan_openworld_balance/%E6%8C%91%E6%8B%85%E8%84%9A%E5%A4%AB_wrong_seg01_dialog.mp3) |
| ch2_s1_zhuwei_market | 挑担脚夫 | [huilan_openworld_balance_done / start](../../game/data/dialogs/huilan_openworld_balance_done.tres) | normal | 无可播人物语音 |
| ch2_s3_forest_ambush | 蒙面人 | [ch2_forest_ambush_intro / start](../../game/data/dialogs/ch2_forest_ambush_intro.tres) | normal | 无可播人物语音 |
| ch2_s3_forest_ambush | 悦无姮 | [ch2_hideout_intro / start](../../game/data/dialogs/ch2_hideout_intro.tres) | normal | [9.8 秒](../../game/art/audio/voices/ch2/ch2_hideout_intro/%E6%82%A6%E6%97%A0%E5%A7%AE_start.mp3) |
| ch2_s3_forest_ambush | 悦无姮 | [ch2_rescue_victory / courier_first](../../game/data/dialogs/ch2_rescue_victory.tres) | normal | [7.3 秒](../../game/art/audio/voices/ch2/ch2_rescue_victory/%E6%82%A6%E6%97%A0%E5%A7%AE_courier_first.mp3) |
| ch2_s3_forest_ambush | 悦无姮 | [ch2_rescue_victory / n3](../../game/data/dialogs/ch2_rescue_victory.tres) | normal | [7.2 秒](../../game/art/audio/voices/ch2/ch2_rescue_victory/%E6%82%A6%E6%97%A0%E5%A7%AE_n3.mp3) |
| ch2_s3_forest_ambush | 悦无姮 | [ch2_rescue_victory / rescue_first](../../game/data/dialogs/ch2_rescue_victory.tres) | normal | [9.0 秒](../../game/art/audio/voices/ch2/ch2_rescue_victory/%E6%82%A6%E6%97%A0%E5%A7%AE_rescue_first.mp3) |
| ch2_s3_forest_ambush | 悦无姮 | [ch2_rescue_victory / spoils](../../game/data/dialogs/ch2_rescue_victory.tres) | normal | [9.8 秒](../../game/art/audio/voices/ch2/ch2_rescue_victory/%E6%82%A6%E6%97%A0%E5%A7%AE_spoils.mp3) |
| ch2_s3_forest_ambush | 悦无姮 | [ch2_rescue_victory / start](../../game/data/dialogs/ch2_rescue_victory.tres) | normal | [7.6 秒](../../game/art/audio/voices/ch2/ch2_rescue_victory/%E6%82%A6%E6%97%A0%E5%A7%AE_start.mp3) |
| ch2_s3_forest_ambush | 悦无姮 | [ch2_rescue_yue_intro / n2](../../game/data/dialogs/ch2_rescue_yue_intro.tres) | normal | 无可播人物语音 |
| ch2_s4_lingyue_gate | 凌霜 | [ch2_lingyue_arrival / n2](../../game/data/dialogs/ch2_lingyue_arrival.tres) | normal | [8.7 秒](../../game/art/audio/voices/ch2/ch2_lingyue_arrival/%E5%87%8C%E9%9C%9C_n2_seg01_dialog.mp3) |
| ch2_s4_lingyue_gate | 悦无姮 | [ch2_lingyue_arrival / n3](../../game/data/dialogs/ch2_lingyue_arrival.tres) | normal | [8.6 秒](../../game/art/audio/voices/ch2/ch2_lingyue_arrival/%E6%82%A6%E6%97%A0%E5%A7%AE_n3.mp3) |
| ch2_s4_lingyue_gate | 凌霜 | [ch2_lingyue_arrival / start](../../game/data/dialogs/ch2_lingyue_arrival.tres) | normal | [7.3 秒](../../game/art/audio/voices/ch2/ch2_lingyue_arrival/%E5%87%8C%E9%9C%9C_start_seg01_dialog.mp3) |
| ch2_s4_lingyue_gate | 凌月弟子 | [ch2_missing_disciple_complete / n2](../../game/data/dialogs/ch2_missing_disciple_complete.tres) | normal | [7.8 秒](../../game/art/audio/voices/ch2/ch2_missing_disciple_complete/%E5%87%8C%E6%9C%88%E5%BC%9F%E5%AD%90_n2_seg01_dialog.mp3) |
| ch2_s4_lingyue_gate | 守山弟子 | [huilan_openworld_bell / right](../../game/data/dialogs/huilan_openworld_bell.tres) | normal | [9.4 秒](../../game/art/audio/voices/hui/huilan_openworld_bell/%E5%AE%88%E5%B1%B1%E5%BC%9F%E5%AD%90_right_seg01_dialog.mp3) |
| ch2_s4_lingyue_gate | 守山弟子 | [huilan_openworld_bell / start](../../game/data/dialogs/huilan_openworld_bell.tres) | normal | [11.4 秒](../../game/art/audio/voices/hui/huilan_openworld_bell/%E5%AE%88%E5%B1%B1%E5%BC%9F%E5%AD%90_start_seg01_dialog.mp3) |
| ch2_s4_lingyue_gate | 守山弟子 | [huilan_openworld_bell / wrong](../../game/data/dialogs/huilan_openworld_bell.tres) | normal | [6.4 秒](../../game/art/audio/voices/hui/huilan_openworld_bell/%E5%AE%88%E5%B1%B1%E5%BC%9F%E5%AD%90_wrong_seg01_dialog.mp3) |
| ch2_s5_mine_command | 蒙面头领 | [ch2_hideout_battle / start](../../game/data/dialogs/ch2_hideout_battle.tres) | normal | [6.8 秒](../../game/art/audio/voices/ch2/ch2_hideout_battle/%E8%92%99%E9%9D%A2%E5%A4%B4%E9%A2%86_start_seg01_dialog.mp3) |
| ch2_s5_mine_workshop | 矿洞巡哨 | [ch2_mine_workshop_sentries / start](../../game/data/dialogs/ch2_mine_workshop_sentries.tres) | normal | 无可播人物语音 |
| ch3_s1_wulin_assembly | 大会执事 | [ch3_assembly_early_visit / start](../../game/data/dialogs/ch3_assembly_early_visit.tres) | normal | 无可播人物语音 |
| ch3_s1_wulin_assembly | 苏雾笙 | [ch3_assembly_intro / n2](../../game/data/dialogs/ch3_assembly_intro.tres) | normal | [8.8 秒](../../game/art/audio/voices/ch3/ch3_assembly_intro/%E8%8B%8F%E9%9B%BE%E7%AC%99_n2_seg01_dialog.mp3) |
| ch3_s1_wulin_assembly | 凌霜 | [ch3_assembly_intro / n3](../../game/data/dialogs/ch3_assembly_intro.tres) | normal | [10.3 秒](../../game/art/audio/voices/ch3/ch3_assembly_intro/%E5%87%8C%E9%9C%9C_n3_seg01_dialog.mp3) |
| ch3_s1_wulin_assembly | 凌霜 | [ch3_assembly_review / end](../../game/data/dialogs/ch3_assembly_review.tres) | normal | [6.0 秒](../../game/art/audio/voices/ch3/ch3_assembly_review/%E5%87%8C%E9%9C%9C_end_seg01_dialog.mp3) |
| ch3_s1_wulin_assembly | 少林俗家·岳闻钟 | [ch3_assembly_review / shaolin](../../game/data/dialogs/ch3_assembly_review.tres) | normal | [15.7 秒](../../game/art/audio/voices/ch3/ch3_assembly_review/%E5%B0%91%E6%9E%97%E4%BF%97%E5%AE%B6%C2%B7%E5%B2%B3%E9%97%BB%E9%92%9F_shaolin_seg01_dialog.mp3) |
| ch3_s1_wulin_assembly | 大会执事 | [ch3_assembly_review / start](../../game/data/dialogs/ch3_assembly_review.tres) | normal | [8.8 秒](../../game/art/audio/voices/ch3/ch3_assembly_review/%E5%A4%A7%E4%BC%9A%E6%89%A7%E4%BA%8B_start_seg01_dialog.mp3) |
| ch3_s1_wulin_assembly | 大会执事 | [ch3_assembly_wait / start](../../game/data/dialogs/ch3_assembly_wait.tres) | normal | [6.0 秒](../../game/art/audio/voices/ch3/ch3_assembly_wait/%E5%A4%A7%E4%BC%9A%E6%89%A7%E4%BA%8B_start_seg01_dialog.mp3) |
| ch3_s1_wulin_assembly | 悦无姮 | [ch3_lingyue_complete / start](../../game/data/dialogs/ch3_lingyue_complete.tres) | normal | [8.6 秒](../../game/art/audio/voices/ch3/ch3_lingyue_complete/%E6%82%A6%E6%97%A0%E5%A7%AE_start_seg01_dialog.mp3) |
| ch3_s1_wulin_assembly | 悦无姮 | [ch3_lingyue_trial / start](../../game/data/dialogs/ch3_lingyue_trial.tres) | normal | 无可播人物语音 |
| ch3_s1_wulin_assembly | 大会执事 | [ch3_luoyang_dispatch / start](../../game/data/dialogs/ch3_luoyang_dispatch.tres) | normal | [8.8 秒](../../game/art/audio/voices/ch3/ch3_luoyang_dispatch/%E5%A4%A7%E4%BC%9A%E6%89%A7%E4%BA%8B_start_seg01_dialog.mp3) |
| ch3_s1_wulin_assembly | 游方棋客 | [huilan_openworld_board / right](../../game/data/dialogs/huilan_openworld_board.tres) | normal | [7.2 秒](../../game/art/audio/voices/hui/huilan_openworld_board/%E6%B8%B8%E6%96%B9%E6%A3%8B%E5%AE%A2_right_seg01_dialog.mp3) |
| ch3_s1_wulin_assembly | 游方棋客 | [huilan_openworld_board / start](../../game/data/dialogs/huilan_openworld_board.tres) | normal | [9.6 秒](../../game/art/audio/voices/hui/huilan_openworld_board/%E6%B8%B8%E6%96%B9%E6%A3%8B%E5%AE%A2_start_seg01_dialog.mp3) |
| ch3_s1_wulin_assembly | 游方棋客 | [huilan_openworld_board / wrong](../../game/data/dialogs/huilan_openworld_board.tres) | normal | [4.7 秒](../../game/art/audio/voices/hui/huilan_openworld_board/%E6%B8%B8%E6%96%B9%E6%A3%8B%E5%AE%A2_wrong_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 清虚道长 | [ch3_alchemy_trial / retry](../../game/data/dialogs/ch3_alchemy_trial.tres) | normal | [6.0 秒](../../game/art/audio/voices/ch3/ch3_alchemy_trial/%E6%B8%85%E8%99%9A%E9%81%93%E9%95%BF_retry_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 清虚道长 | [ch3_alchemy_trial / start](../../game/data/dialogs/ch3_alchemy_trial.tres) | normal | [9.2 秒](../../game/art/audio/voices/ch3/ch3_alchemy_trial/%E6%B8%85%E8%99%9A%E9%81%93%E9%95%BF_start_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 清虚道长 | [ch3_alchemy_trial / success](../../game/data/dialogs/ch3_alchemy_trial.tres) | normal | [6.5 秒](../../game/art/audio/voices/ch3/ch3_alchemy_trial/%E6%B8%85%E8%99%9A%E9%81%93%E9%95%BF_success_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 大会乐师 | [ch3_canglong_fragment_middle / start](../../game/data/dialogs/ch3_canglong_fragment_middle.tres) | normal | [8.6 秒](../../game/art/audio/voices/ch3/ch3_canglong_fragment_middle/%E5%A4%A7%E4%BC%9A%E4%B9%90%E5%B8%88_start_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 古疆雷 | [ch3_faction_choice / gufeng](../../game/data/dialogs/ch3_faction_choice.tres) | normal | 无可播人物语音 |
| ch3_s2_trial_ground | 霍长空 | [ch3_faction_choice / huashan](../../game/data/dialogs/ch3_faction_choice.tres) | normal | 无可播人物语音 |
| ch3_s2_trial_ground | 凌霜 | [ch3_faction_choice / lingyue](../../game/data/dialogs/ch3_faction_choice.tres) | normal | [6.9 秒](../../game/art/audio/voices/ch3/ch3_faction_choice/%E5%87%8C%E9%9C%9C_lingyue_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 苏雾笙 | [ch3_faction_choice / mingwu](../../game/data/dialogs/ch3_faction_choice.tres) | normal | 无可播人物语音 |
| ch3_s2_trial_ground | 考校执事 | [ch3_faction_choice / start](../../game/data/dialogs/ch3_faction_choice.tres) | normal | 无可播人物语音 |
| ch3_s2_trial_ground | 考校执事 | [ch3_faction_choice / wanderer](../../game/data/dialogs/ch3_faction_choice.tres) | normal | 无可播人物语音 |
| ch3_s2_trial_ground | 玄真道长 | [ch3_faction_choice / wudang](../../game/data/dialogs/ch3_faction_choice.tres) | normal | 无可播人物语音 |
| ch3_s2_trial_ground | 古疆雷 | [ch3_gufeng_complete / start](../../game/data/dialogs/ch3_gufeng_complete.tres) | normal | [8.1 秒](../../game/art/audio/voices/ch3/ch3_gufeng_complete/%E5%8F%A4%E7%96%86%E9%9B%B7_start_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 古疆雷 | [ch3_gufeng_trial / start](../../game/data/dialogs/ch3_gufeng_trial.tres) | normal | 无可播人物语音 |
| ch3_s2_trial_ground | 大会乐师 | [ch3_guqin_side / n3](../../game/data/dialogs/ch3_guqin_side.tres) | normal | [6.0 秒](../../game/art/audio/voices/ch3/ch3_guqin_side/%E5%A4%A7%E4%BC%9A%E4%B9%90%E5%B8%88_n3_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 大会乐师 | [ch3_guqin_side / start](../../game/data/dialogs/ch3_guqin_side.tres) | normal | [6.9 秒](../../game/art/audio/voices/ch3/ch3_guqin_side/%E5%A4%A7%E4%BC%9A%E4%B9%90%E5%B8%88_start_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 封砚秋 | [ch3_guyun_returning_diagram / correct](../../game/data/dialogs/ch3_guyun_returning_diagram.tres) | normal | [13.8 秒](../../game/art/audio/voices/ch3/ch3_guyun_returning_diagram/%E5%B0%81%E7%A0%9A%E7%A7%8B_correct_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 封砚秋 | [ch3_guyun_returning_diagram / puzzle](../../game/data/dialogs/ch3_guyun_returning_diagram.tres) | normal | [8.4 秒](../../game/art/audio/voices/ch3/ch3_guyun_returning_diagram/%E5%B0%81%E7%A0%9A%E7%A7%8B_puzzle_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 封砚秋 | [ch3_guyun_returning_diagram / start](../../game/data/dialogs/ch3_guyun_returning_diagram.tres) | normal | [10.0 秒](../../game/art/audio/voices/ch3/ch3_guyun_returning_diagram/%E5%B0%81%E7%A0%9A%E7%A7%8B_start_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 封砚秋 | [ch3_guyun_returning_diagram / wrong](../../game/data/dialogs/ch3_guyun_returning_diagram.tres) | normal | [8.0 秒](../../game/art/audio/voices/ch3/ch3_guyun_returning_diagram/%E5%B0%81%E7%A0%9A%E7%A7%8B_wrong_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 霍长空 | [ch3_huashan_complete / start](../../game/data/dialogs/ch3_huashan_complete.tres) | normal | [7.6 秒](../../game/art/audio/voices/ch3/ch3_huashan_complete/%E9%9C%8D%E9%95%BF%E7%A9%BA_start_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 华山剑士 | [ch3_huashan_trial / start](../../game/data/dialogs/ch3_huashan_trial.tres) | normal | 无可播人物语音 |
| ch3_s2_trial_ground | 悦无姮 | [ch3_lingyue_complete / start](../../game/data/dialogs/ch3_lingyue_complete.tres) | normal | [8.6 秒](../../game/art/audio/voices/ch3/ch3_lingyue_complete/%E6%82%A6%E6%97%A0%E5%A7%AE_start_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 悦无姮 | [ch3_lingyue_trial / start](../../game/data/dialogs/ch3_lingyue_trial.tres) | normal | 无可播人物语音 |
| ch3_s2_trial_ground | 苏雾笙 | [ch3_mingwu_complete / n2](../../game/data/dialogs/ch3_mingwu_complete.tres) | normal | [8.5 秒](../../game/art/audio/voices/ch3/ch3_mingwu_complete/%E8%8B%8F%E9%9B%BE%E7%AC%99_n2_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 茗雾教习 | [ch3_mingwu_trial / start](../../game/data/dialogs/ch3_mingwu_trial.tres) | normal | 无可播人物语音 |
| ch3_s2_trial_ground | 论剑执笔人 | [ch3_sword_forum_side / finish](../../game/data/dialogs/ch3_sword_forum_side.tres) | normal | [5.6 秒](../../game/art/audio/voices/ch3/ch3_sword_forum_side/%E8%AE%BA%E5%89%91%E6%89%A7%E7%AC%94%E4%BA%BA_finish_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 论剑执笔人 | [ch3_sword_forum_side / retry](../../game/data/dialogs/ch3_sword_forum_side.tres) | normal | [6.4 秒](../../game/art/audio/voices/ch3/ch3_sword_forum_side/%E8%AE%BA%E5%89%91%E6%89%A7%E7%AC%94%E4%BA%BA_retry_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 论剑执笔人 | [ch3_sword_forum_side / start](../../game/data/dialogs/ch3_sword_forum_side.tres) | normal | [6.5 秒](../../game/art/audio/voices/ch3/ch3_sword_forum_side/%E8%AE%BA%E5%89%91%E6%89%A7%E7%AC%94%E4%BA%BA_start_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 考校执事 | [ch3_trial_intro / start](../../game/data/dialogs/ch3_trial_intro.tres) | normal | 无可播人物语音 |
| ch3_s2_trial_ground | 考校执事 | [ch3_wanderer_complete / finish](../../game/data/dialogs/ch3_wanderer_complete.tres) | normal | [11.7 秒](../../game/art/audio/voices/ch3/ch3_wanderer_complete/%E8%80%83%E6%A0%A1%E6%89%A7%E4%BA%8B_finish_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 考校执事 | [ch3_wanderer_complete / start](../../game/data/dialogs/ch3_wanderer_complete.tres) | normal | [14.2 秒](../../game/art/audio/voices/ch3/ch3_wanderer_complete/%E8%80%83%E6%A0%A1%E6%89%A7%E4%BA%8B_start_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 考校执事 | [ch3_wanderer_trial / start](../../game/data/dialogs/ch3_wanderer_trial.tres) | normal | 无可播人物语音 |
| ch3_s2_trial_ground | 游方道人 | [ch3_weiqi_side / right](../../game/data/dialogs/ch3_weiqi_side.tres) | normal | [6.3 秒](../../game/art/audio/voices/ch3/ch3_weiqi_side/%E6%B8%B8%E6%96%B9%E9%81%93%E4%BA%BA_right_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 游方道人 | [ch3_weiqi_side / start](../../game/data/dialogs/ch3_weiqi_side.tres) | normal | [5.3 秒](../../game/art/audio/voices/ch3/ch3_weiqi_side/%E6%B8%B8%E6%96%B9%E9%81%93%E4%BA%BA_start_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 游方道人 | [ch3_weiqi_side / wrong](../../game/data/dialogs/ch3_weiqi_side.tres) | normal | [4.0 秒](../../game/art/audio/voices/ch3/ch3_weiqi_side/%E6%B8%B8%E6%96%B9%E9%81%93%E4%BA%BA_wrong_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 玄真道长 | [ch3_wudang_complete / finish](../../game/data/dialogs/ch3_wudang_complete.tres) | normal | [12.1 秒](../../game/art/audio/voices/ch3/ch3_wudang_complete/%E7%8E%84%E7%9C%9F%E9%81%93%E9%95%BF_finish_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 玄真道长 | [ch3_wudang_complete / start](../../game/data/dialogs/ch3_wudang_complete.tres) | normal | [8.9 秒](../../game/art/audio/voices/ch3/ch3_wudang_complete/%E7%8E%84%E7%9C%9F%E9%81%93%E9%95%BF_start_seg01_dialog.mp3) |
| ch3_s2_trial_ground | 武当弟子 | [ch3_wudang_trial / start](../../game/data/dialogs/ch3_wudang_trial.tres) | normal | 无可播人物语音 |
| ch3_s3_faction_training | 合练教习 | [ch3_training_battle / start](../../game/data/dialogs/ch3_training_battle.tres) | normal | [8.5 秒](../../game/art/audio/voices/ch3/ch3_training_battle/%E5%90%88%E7%BB%83%E6%95%99%E4%B9%A0_start_seg01_dialog.mp3) |
| ch3_s3_faction_training | 合练教习 | [ch3_training_result / start](../../game/data/dialogs/ch3_training_result.tres) | normal | [8.7 秒](../../game/art/audio/voices/ch3/ch3_training_result/%E5%90%88%E7%BB%83%E6%95%99%E4%B9%A0_start_seg01_dialog.mp3) |
| ch3_s4_forbidden_tomb | 茗雾暗哨 | [ch3_tomb_battle / b](../../game/data/dialogs/ch3_tomb_battle.tres) | normal | [3.9 秒](../../game/art/audio/voices/ch3/ch3_tomb_battle/%E8%8C%97%E9%9B%BE%E6%9A%97%E5%93%A8_b_seg01_dialog.mp3) |
| ch3_s4_forbidden_tomb | 古墓守卫 | [encounter_ancient_tomb_guard / start](../../game/data/dialogs/encounter_ancient_tomb_guard.tres) | normal | 无可播人物语音 |
| ch4_s0_luoyang_gate | 赵思颖 | [ch4_case_clue / c](../../game/data/dialogs/ch4_case_clue.tres) | normal | [7.2 秒](../../game/art/audio/voices/ch4/ch4_case_clue/%E8%B5%B5%E6%80%9D%E9%A2%96_c_seg01_dialog.mp3) |
| ch4_s0_luoyang_gate | 赵思颖 | [ch4_case_clue / start](../../game/data/dialogs/ch4_case_clue.tres) | normal | [8.0 秒](../../game/art/audio/voices/ch4/ch4_case_clue/%E8%B5%B5%E6%80%9D%E9%A2%96_start_seg01_dialog.mp3) |
| ch4_s0_luoyang_gate | 洛阳门吏 | [openworld_luoyang_gate_sergeant / start](../../game/data/dialogs/openworld_luoyang_gate_sergeant.tres) | normal | 无可播人物语音 |
| ch4_s1_luoyang_yamen | 赵思颖 | [ch4_case_clue / c](../../game/data/dialogs/ch4_case_clue.tres) | normal | [7.2 秒](../../game/art/audio/voices/ch4/ch4_case_clue/%E8%B5%B5%E6%80%9D%E9%A2%96_c_seg01_dialog.mp3) |
| ch4_s1_luoyang_yamen | 赵思颖 | [ch4_case_clue / start](../../game/data/dialogs/ch4_case_clue.tres) | normal | [8.0 秒](../../game/art/audio/voices/ch4/ch4_case_clue/%E8%B5%B5%E6%80%9D%E9%A2%96_start_seg01_dialog.mp3) |
| ch4_s1_luoyang_yamen | 府尹 | [ch4_yamen_intro / b](../../game/data/dialogs/ch4_yamen_intro.tres) | normal | [7.8 秒](../../game/art/audio/voices/ch4/ch4_yamen_intro/%E5%BA%9C%E5%B0%B9_b_seg01_dialog.mp3) |
| ch4_s1_luoyang_yamen | 终局案卷吏 | [ch8_aftermath_luoyang / end](../../game/data/dialogs/ch8_aftermath_luoyang.tres) | normal | [8.7 秒](../../game/art/audio/voices/ch8/ch8_aftermath_luoyang/%E7%BB%88%E5%B1%80%E6%A1%88%E5%8D%B7%E5%90%8F_end_seg01_dialog.mp3) |
| ch4_s1_luoyang_yamen | 终局案卷吏 | [ch8_aftermath_luoyang / start](../../game/data/dialogs/ch8_aftermath_luoyang.tres) | normal | [9.7 秒](../../game/art/audio/voices/ch8/ch8_aftermath_luoyang/%E7%BB%88%E5%B1%80%E6%A1%88%E5%8D%B7%E5%90%8F_start_seg01_dialog.mp3) |
| ch4_s1_luoyang_yamen | 戚云笙 | [ch8_relationship_qi_yunsheng / independent](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) | normal | [9.8 秒](../../game/art/audio/voices/ch8/ch8_relationship_qi_yunsheng/%E6%88%9A%E4%BA%91%E7%AC%99_independent_seg01_dialog.mp3) |
| ch4_s1_luoyang_yamen | 戚云笙 | [ch8_relationship_qi_yunsheng / start](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) | normal | [9.9 秒](../../game/art/audio/voices/ch8/ch8_relationship_qi_yunsheng/%E6%88%9A%E4%BA%91%E7%AC%99_start_seg01_dialog.mp3) |
| ch4_s1_luoyang_yamen | 戚云笙 | [ch8_relationship_qi_yunsheng / together](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) | normal | [10.6 秒](../../game/art/audio/voices/ch8/ch8_relationship_qi_yunsheng/%E6%88%9A%E4%BA%91%E7%AC%99_together_seg01_dialog.mp3) |
| ch4_s1_luoyang_yamen | 悦无姮 | [ch8_relationship_yuewuheng / independent](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) | normal | [7.7 秒](../../game/art/audio/voices/ch8/ch8_relationship_yuewuheng/%E6%82%A6%E6%97%A0%E5%A7%AE_independent_seg01_dialog.mp3) |
| ch4_s1_luoyang_yamen | 悦无姮 | [ch8_relationship_yuewuheng / start](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) | normal | [8.5 秒](../../game/art/audio/voices/ch8/ch8_relationship_yuewuheng/%E6%82%A6%E6%97%A0%E5%A7%AE_start_seg01_dialog.mp3) |
| ch4_s1_luoyang_yamen | 悦无姮 | [ch8_relationship_yuewuheng / together](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) | normal | [6.0 秒](../../game/art/audio/voices/ch8/ch8_relationship_yuewuheng/%E6%82%A6%E6%97%A0%E5%A7%AE_together_seg01_dialog.mp3) |
| ch4_s1_luoyang_yamen | 赵思颖 | [ch8_relationship_zhao_siying / independent](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) | normal | [7.9 秒](../../game/art/audio/voices/ch8/ch8_relationship_zhao_siying/%E8%B5%B5%E6%80%9D%E9%A2%96_independent_seg01_dialog.mp3) |
| ch4_s1_luoyang_yamen | 赵思颖 | [ch8_relationship_zhao_siying / start](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) | normal | [10.6 秒](../../game/art/audio/voices/ch8/ch8_relationship_zhao_siying/%E8%B5%B5%E6%80%9D%E9%A2%96_start_seg01_dialog.mp3) |
| ch4_s1_luoyang_yamen | 赵思颖 | [ch8_relationship_zhao_siying / together](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) | normal | [7.9 秒](../../game/art/audio/voices/ch8/ch8_relationship_zhao_siying/%E8%B5%B5%E6%80%9D%E9%A2%96_together_seg01_dialog.mp3) |
| ch4_s1_luoyang_yamen | 府衙老吏 | [huilan_openworld_water_rule / start](../../game/data/dialogs/huilan_openworld_water_rule.tres) | normal | [11.6 秒](../../game/art/audio/voices/hui/huilan_openworld_water_rule/%E5%BA%9C%E8%A1%99%E8%80%81%E5%90%8F_start_seg01_dialog.mp3) |
| ch4_s1_luoyang_yamen | 府衙老吏 | [huilan_openworld_water_rule / wrong](../../game/data/dialogs/huilan_openworld_water_rule.tres) | normal | [5.9 秒](../../game/art/audio/voices/hui/huilan_openworld_water_rule/%E5%BA%9C%E8%A1%99%E8%80%81%E5%90%8F_wrong_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 洛阳地痞 | [ch4_canal_battle / b](../../game/data/dialogs/ch4_canal_battle.tres) | normal | [5.3 秒](../../game/art/audio/voices/ch4/ch4_canal_battle/%E6%B4%9B%E9%98%B3%E5%9C%B0%E7%97%9E_b_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 失踪脚夫 | [ch4_canal_battle / start](../../game/data/dialogs/ch4_canal_battle.tres) | normal | [7.3 秒](../../game/art/audio/voices/ch4/ch4_canal_battle/%E5%A4%B1%E8%B8%AA%E8%84%9A%E5%A4%AB_start_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 漕工头领 | [ch4_canal_grudge_offer / start](../../game/data/dialogs/ch4_canal_grudge_offer.tres) | normal | [9.1 秒](../../game/art/audio/voices/ch4/ch4_canal_grudge_offer/%E6%BC%95%E5%B7%A5%E5%A4%B4%E9%A2%86_start_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 漕工头领 | [ch4_canal_grudge_turnin / end](../../game/data/dialogs/ch4_canal_grudge_turnin.tres) | normal | [12.8 秒](../../game/art/audio/voices/ch4/ch4_canal_grudge_turnin/%E6%BC%95%E5%B7%A5%E5%A4%B4%E9%A2%86_end_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 赵思颖 | [ch4_canal_result / b](../../game/data/dialogs/ch4_canal_result.tres) | normal | [7.8 秒](../../game/art/audio/voices/ch4/ch4_canal_result/%E8%B5%B5%E6%80%9D%E9%A2%96_b_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 失踪脚夫 | [ch4_canal_result / rescue_first](../../game/data/dialogs/ch4_canal_result.tres) | normal | [8.4 秒](../../game/art/audio/voices/ch4/ch4_canal_result/%E5%A4%B1%E8%B8%AA%E8%84%9A%E5%A4%AB_rescue_first_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 失踪脚夫 | [ch4_canal_result / start](../../game/data/dialogs/ch4_canal_result.tres) | normal | [7.8 秒](../../game/art/audio/voices/ch4/ch4_canal_result/%E5%A4%B1%E8%B8%AA%E8%84%9A%E5%A4%AB_start_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 漕工头领 | [ch4_city_tasks_20261016_canal_after / start](../../game/data/dialogs/luoyang_city_tasks_20261016/canal_after.tres) | normal | [10.0 秒](../../game/art/audio/voices/ch4/ch4_city_tasks_20261016_canal_after/%E6%BC%95%E5%B7%A5%E5%A4%B4%E9%A2%86_start_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 漕工头领 | [ch4_city_tasks_20261016_canal_offer / accepted](../../game/data/dialogs/luoyang_city_tasks_20261016/canal_offer.tres) | normal | [8.8 秒](../../game/art/audio/voices/ch4/ch4_city_tasks_20261016_canal_offer/%E6%BC%95%E5%B7%A5%E5%A4%B4%E9%A2%86_accepted_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 漕工头领 | [ch4_city_tasks_20261016_canal_offer / offer](../../game/data/dialogs/luoyang_city_tasks_20261016/canal_offer.tres) | normal | [9.2 秒](../../game/art/audio/voices/ch4/ch4_city_tasks_20261016_canal_offer/%E6%BC%95%E5%B7%A5%E5%A4%B4%E9%A2%86_offer_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 漕工头领 | [ch4_city_tasks_20261016_canal_progress / start](../../game/data/dialogs/luoyang_city_tasks_20261016/canal_progress.tres) | normal | [10.5 秒](../../game/art/audio/voices/ch4/ch4_city_tasks_20261016_canal_progress/%E6%BC%95%E5%B7%A5%E5%A4%B4%E9%A2%86_start_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 漕工头领 | [ch4_city_tasks_20261016_canal_report / report](../../game/data/dialogs/luoyang_city_tasks_20261016/canal_report.tres) | normal | [13.4 秒](../../game/art/audio/voices/ch4/ch4_city_tasks_20261016_canal_report/%E6%BC%95%E5%B7%A5%E5%A4%B4%E9%A2%86_report_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 老漕卒 | [ch4_city_tasks_20261016_canal_witness / detail](../../game/data/dialogs/luoyang_city_tasks_20261016/canal_witness.tres) | normal | 无可播人物语音 |
| ch4_s2_canal_docks | 老漕卒 | [ch4_city_tasks_20261016_canal_witness / start](../../game/data/dialogs/luoyang_city_tasks_20261016/canal_witness.tres) | normal | 无可播人物语音 |
| ch4_s2_canal_docks | 老漕卒 | [ch4_city_tasks_20261016_hanjia_after / start](../../game/data/dialogs/luoyang_city_tasks_20261016/hanjia_after.tres) | normal | [10.1 秒](../../game/art/audio/voices/ch4/ch4_city_tasks_20261016_hanjia_after/%E8%80%81%E6%BC%95%E5%8D%92_start_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 老漕卒 | [ch4_city_tasks_20261016_hanjia_offer / accepted](../../game/data/dialogs/luoyang_city_tasks_20261016/hanjia_offer.tres) | normal | [6.8 秒](../../game/art/audio/voices/ch4/ch4_city_tasks_20261016_hanjia_offer/%E8%80%81%E6%BC%95%E5%8D%92_accepted_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 老漕卒 | [ch4_city_tasks_20261016_hanjia_offer / start](../../game/data/dialogs/luoyang_city_tasks_20261016/hanjia_offer.tres) | normal | [9.3 秒](../../game/art/audio/voices/ch4/ch4_city_tasks_20261016_hanjia_offer/%E8%80%81%E6%BC%95%E5%8D%92_start_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 老漕卒 | [ch4_city_tasks_20261016_hanjia_progress / start](../../game/data/dialogs/luoyang_city_tasks_20261016/hanjia_progress.tres) | normal | [9.6 秒](../../game/art/audio/voices/ch4/ch4_city_tasks_20261016_hanjia_progress/%E8%80%81%E6%BC%95%E5%8D%92_start_seg01_dialog.mp3) |
| ch4_s2_canal_docks | 老漕卒 | [ch4_hanjia_blade_offer / start](../../game/data/dialogs/ch4_hanjia_blade_offer.tres) | normal | [9.3 秒](../../game/art/audio/voices/ch4/ch4_hanjia_blade_offer/%E8%80%81%E6%BC%95%E5%8D%92_start_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 老纸匠 | [ch4_city_tasks_20261016_artisan_after / start](../../game/data/dialogs/luoyang_city_tasks_20261016/artisan_after.tres) | normal | 无可播人物语音 |
| ch4_s3_luoyang_market | 老纸匠 | [ch4_city_tasks_20261016_artisan_daily / start](../../game/data/dialogs/luoyang_city_tasks_20261016/artisan_daily.tres) | normal | 无可播人物语音 |
| ch4_s3_luoyang_market | 左明远 | [ch4_city_tasks_20261016_paper_after / start](../../game/data/dialogs/luoyang_city_tasks_20261016/paper_after.tres) | normal | [9.8 秒](../../game/art/audio/voices/ch4/ch4_city_tasks_20261016_paper_after/%E5%B7%A6%E6%98%8E%E8%BF%9C_start_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 老纸匠 | [ch4_city_tasks_20261016_paper_hint / detail](../../game/data/dialogs/luoyang_city_tasks_20261016/paper_hint.tres) | normal | 无可播人物语音 |
| ch4_s3_luoyang_market | 老纸匠 | [ch4_city_tasks_20261016_paper_hint / start](../../game/data/dialogs/luoyang_city_tasks_20261016/paper_hint.tres) | normal | 无可播人物语音 |
| ch4_s3_luoyang_market | 老纸匠 | [ch4_city_tasks_20261016_paper_hint_repeat / start](../../game/data/dialogs/luoyang_city_tasks_20261016/paper_hint_repeat.tres) | normal | 无可播人物语音 |
| ch4_s3_luoyang_market | 左明远 | [ch4_city_tasks_20261016_paper_offer / offer](../../game/data/dialogs/luoyang_city_tasks_20261016/paper_offer.tres) | normal | [7.7 秒](../../game/art/audio/voices/ch4/ch4_city_tasks_20261016_paper_offer/%E5%B7%A6%E6%98%8E%E8%BF%9C_offer_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 左明远 | [ch4_city_tasks_20261016_paper_offer / start](../../game/data/dialogs/luoyang_city_tasks_20261016/paper_offer.tres) | normal | [8.4 秒](../../game/art/audio/voices/ch4/ch4_city_tasks_20261016_paper_offer/%E5%B7%A6%E6%98%8E%E8%BF%9C_start_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 左明远 | [ch4_city_tasks_20261016_paper_progress / start](../../game/data/dialogs/luoyang_city_tasks_20261016/paper_progress.tres) | normal | [9.1 秒](../../game/art/audio/voices/ch4/ch4_city_tasks_20261016_paper_progress/%E5%B7%A6%E6%98%8E%E8%BF%9C_start_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 老纸匠 | [ch4_city_tasks_20261016_paper_ready / start](../../game/data/dialogs/luoyang_city_tasks_20261016/paper_ready.tres) | normal | [8.5 秒](../../game/art/audio/voices/ch4/ch4_city_tasks_20261016_paper_ready/%E8%80%81%E7%BA%B8%E5%8C%A0_start_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 左明远 | [ch4_city_tasks_20261016_paper_report / paper](../../game/data/dialogs/luoyang_city_tasks_20261016/paper_report.tres) | normal | [9.8 秒](../../game/art/audio/voices/ch4/ch4_city_tasks_20261016_paper_report/%E5%B7%A6%E6%98%8E%E8%BF%9C_paper_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 封砚秋 | [ch4_guyun_sword_notches / correct](../../game/data/dialogs/ch4_guyun_sword_notches.tres) | normal | [14.0 秒](../../game/art/audio/voices/ch4/ch4_guyun_sword_notches/%E5%B0%81%E7%A0%9A%E7%A7%8B_correct_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 封砚秋 | [ch4_guyun_sword_notches / puzzle](../../game/data/dialogs/ch4_guyun_sword_notches.tres) | normal | [7.2 秒](../../game/art/audio/voices/ch4/ch4_guyun_sword_notches/%E5%B0%81%E7%A0%9A%E7%A7%8B_puzzle_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 封砚秋 | [ch4_guyun_sword_notches / start](../../game/data/dialogs/ch4_guyun_sword_notches.tres) | normal | [11.5 秒](../../game/art/audio/voices/ch4/ch4_guyun_sword_notches/%E5%B0%81%E7%A0%9A%E7%A7%8B_start_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 封砚秋 | [ch4_guyun_sword_notches / wrong](../../game/data/dialogs/ch4_guyun_sword_notches.tres) | normal | [8.7 秒](../../game/art/audio/voices/ch4/ch4_guyun_sword_notches/%E5%B0%81%E7%A0%9A%E7%A7%8B_wrong_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 赵思颖 | [ch4_heal_veteran_offer / start](../../game/data/dialogs/ch4_heal_veteran_offer.tres) | normal | [7.8 秒](../../game/art/audio/voices/ch4/ch4_heal_veteran_offer/%E8%B5%B5%E6%80%9D%E9%A2%96_start_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 左明远 | [ch4_luoyang_paper_offer / start](../../game/data/dialogs/ch4_luoyang_paper_offer.tres) | normal | [10.0 秒](../../game/art/audio/voices/ch4/ch4_luoyang_paper_offer/%E5%B7%A6%E6%98%8E%E8%BF%9C_start_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 诗会执事 | [ch4_peony_poetry / retry](../../game/data/dialogs/ch4_peony_poetry.tres) | normal | [5.5 秒](../../game/art/audio/voices/ch4/ch4_peony_poetry/%E8%AF%97%E4%BC%9A%E6%89%A7%E4%BA%8B_retry.mp3) |
| ch4_s3_luoyang_market | 诗会执事 | [ch4_peony_poetry / start](../../game/data/dialogs/ch4_peony_poetry.tres) | normal | [6.5 秒](../../game/art/audio/voices/ch4/ch4_peony_poetry/%E8%AF%97%E4%BC%9A%E6%89%A7%E4%BA%8B_start.mp3) |
| ch4_s3_luoyang_market | 诗会执事 | [ch4_peony_poetry / success](../../game/data/dialogs/ch4_peony_poetry.tres) | normal | [5.1 秒](../../game/art/audio/voices/ch4/ch4_peony_poetry/%E8%AF%97%E4%BC%9A%E6%89%A7%E4%BA%8B_success.mp3) |
| ch4_s3_luoyang_market | 诗会执事 | [luoyang_layout_quest_20261018t/peony_after / start](../../game/data/dialogs/luoyang_layout_quest_20261018t/peony_after.tres) | normal | [5.6 秒](../../game/art/audio/voices/luo/luoyang_layout_quest_20261018t/peony_after/%E8%AF%97%E4%BC%9A%E6%89%A7%E4%BA%8B_start_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 诗会执事 | [luoyang_layout_quest_20261018t/peony_investigate / choice](../../game/data/dialogs/luoyang_layout_quest_20261018t/peony_investigate.tres) | normal | 无可播人物语音 |
| ch4_s3_luoyang_market | 诗会执事 | [luoyang_layout_quest_20261018t/peony_investigate / retry](../../game/data/dialogs/luoyang_layout_quest_20261018t/peony_investigate.tres) | normal | [5.5 秒](../../game/art/audio/voices/luo/luoyang_layout_quest_20261018t/peony_investigate/%E8%AF%97%E4%BC%9A%E6%89%A7%E4%BA%8B_retry_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 诗会执事 | [luoyang_layout_quest_20261018t/peony_investigate / success](../../game/data/dialogs/luoyang_layout_quest_20261018t/peony_investigate.tres) | normal | [8.6 秒](../../game/art/audio/voices/luo/luoyang_layout_quest_20261018t/peony_investigate/%E8%AF%97%E4%BC%9A%E6%89%A7%E4%BA%8B_success_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 诗会执事 | [luoyang_layout_quest_20261018t/peony_offer / offer](../../game/data/dialogs/luoyang_layout_quest_20261018t/peony_offer.tres) | normal | [8.3 秒](../../game/art/audio/voices/luo/luoyang_layout_quest_20261018t/peony_offer/%E8%AF%97%E4%BC%9A%E6%89%A7%E4%BA%8B_offer_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 诗会执事 | [luoyang_layout_quest_20261018t/peony_progress / start](../../game/data/dialogs/luoyang_layout_quest_20261018t/peony_progress.tres) | normal | [5.3 秒](../../game/art/audio/voices/luo/luoyang_layout_quest_20261018t/peony_progress/%E8%AF%97%E4%BC%9A%E6%89%A7%E4%BA%8B_start_seg01_dialog.mp3) |
| ch4_s3_luoyang_market | 诗会执事 | [luoyang_layout_quest_20261018t/peony_report / report](../../game/data/dialogs/luoyang_layout_quest_20261018t/peony_report.tres) | normal | [7.1 秒](../../game/art/audio/voices/luo/luoyang_layout_quest_20261018t/peony_report/%E8%AF%97%E4%BC%9A%E6%89%A7%E4%BA%8B_report_seg01_dialog.mp3) |
| ch4_s4_ancient_temple | 守钟僧 | [ch4_baima_bell / retry](../../game/data/dialogs/ch4_baima_bell.tres) | normal | [6.4 秒](../../game/art/audio/voices/ch4/ch4_baima_bell/%E5%AE%88%E9%92%9F%E5%83%A7_retry_seg01_dialog.mp3) |
| ch4_s4_ancient_temple | 守钟僧 | [ch4_baima_bell / start](../../game/data/dialogs/ch4_baima_bell.tres) | normal | [6.5 秒](../../game/art/audio/voices/ch4/ch4_baima_bell/%E5%AE%88%E9%92%9F%E5%83%A7_start_seg01_dialog.mp3) |
| ch4_s4_ancient_temple | 守钟僧 | [ch4_baima_bell / success](../../game/data/dialogs/ch4_baima_bell.tres) | normal | [6.1 秒](../../game/art/audio/voices/ch4/ch4_baima_bell/%E5%AE%88%E9%92%9F%E5%83%A7_success_seg01_dialog.mp3) |
| ch4_s4_ancient_temple | 赵思颖 | [ch4_heal_veteran_turnin / end](../../game/data/dialogs/ch4_heal_veteran_turnin.tres) | normal | [5.9 秒](../../game/art/audio/voices/ch4/ch4_heal_veteran_turnin/%E8%B5%B5%E6%80%9D%E9%A2%96_end_seg01_dialog.mp3) |
| ch4_s4_ancient_temple | 守窟僧 | [ch4_longmen_mystery / end](../../game/data/dialogs/ch4_longmen_mystery.tres) | normal | [8.0 秒](../../game/art/audio/voices/ch4/ch4_longmen_mystery/%E5%AE%88%E7%AA%9F%E5%83%A7_end_seg01_dialog.mp3) |
| ch4_s4_ancient_temple | 守窟僧 | [ch4_longmen_mystery / start](../../game/data/dialogs/ch4_longmen_mystery.tres) | normal | [6.8 秒](../../game/art/audio/voices/ch4/ch4_longmen_mystery/%E5%AE%88%E7%AA%9F%E5%83%A7_start_seg01_dialog.mp3) |
| ch4_s4_ancient_temple | 老纸匠 | [ch4_luoyang_paper_turnin / start](../../game/data/dialogs/ch4_luoyang_paper_turnin.tres) | normal | [8.7 秒](../../game/art/audio/voices/ch4/ch4_luoyang_paper_turnin/%E8%80%81%E7%BA%B8%E5%8C%A0_start.mp3) |
| ch4_s4_ancient_temple | 黑衣人 | [ch4_temple_ambush / start](../../game/data/dialogs/ch4_temple_ambush.tres) | normal | 无可播人物语音 |
| ch4_s4_ancient_temple | 赵思颖 | [ch4_tunnel_intro / start](../../game/data/dialogs/ch4_tunnel_intro.tres) | normal | [8.2 秒](../../game/art/audio/voices/ch4/ch4_tunnel_intro/%E8%B5%B5%E6%80%9D%E9%A2%96_start_seg01_dialog.mp3) |
| ch4_s4_ancient_temple | 守钟僧 | [luoyang_layout_quest_20261018t/baima_after / start](../../game/data/dialogs/luoyang_layout_quest_20261018t/baima_after.tres) | normal | [4.4 秒](../../game/art/audio/voices/luo/luoyang_layout_quest_20261018t/baima_after/%E5%AE%88%E9%92%9F%E5%83%A7_start_seg01_dialog.mp3) |
| ch4_s4_ancient_temple | 守钟僧 | [luoyang_layout_quest_20261018t/baima_offer / offer](../../game/data/dialogs/luoyang_layout_quest_20261018t/baima_offer.tres) | normal | [10.4 秒](../../game/art/audio/voices/luo/luoyang_layout_quest_20261018t/baima_offer/%E5%AE%88%E9%92%9F%E5%83%A7_offer_seg01_dialog.mp3) |
| ch4_s4_ancient_temple | 守钟僧 | [luoyang_layout_quest_20261018t/baima_progress / start](../../game/data/dialogs/luoyang_layout_quest_20261018t/baima_progress.tres) | normal | [7.4 秒](../../game/art/audio/voices/luo/luoyang_layout_quest_20261018t/baima_progress/%E5%AE%88%E9%92%9F%E5%83%A7_start_seg01_dialog.mp3) |
| ch4_s4_ancient_temple | 守钟僧 | [luoyang_layout_quest_20261018t/baima_report / report](../../game/data/dialogs/luoyang_layout_quest_20261018t/baima_report.tres) | normal | [9.4 秒](../../game/art/audio/voices/luo/luoyang_layout_quest_20261018t/baima_report/%E5%AE%88%E9%92%9F%E5%83%A7_report_seg01_dialog.mp3) |
| ch4_s4_ancient_temple | 守窟僧 | [luoyang_layout_quest_20261018t/longmen_after / start](../../game/data/dialogs/luoyang_layout_quest_20261018t/longmen_after.tres) | normal | [7.3 秒](../../game/art/audio/voices/luo/luoyang_layout_quest_20261018t/longmen_after/%E5%AE%88%E7%AA%9F%E5%83%A7_start_seg01_dialog.mp3) |
| ch4_s4_ancient_temple | 守窟僧 | [luoyang_layout_quest_20261018t/longmen_offer / offer](../../game/data/dialogs/luoyang_layout_quest_20261018t/longmen_offer.tres) | normal | [9.8 秒](../../game/art/audio/voices/luo/luoyang_layout_quest_20261018t/longmen_offer/%E5%AE%88%E7%AA%9F%E5%83%A7_offer_seg01_dialog.mp3) |
| ch4_s4_ancient_temple | 守窟僧 | [luoyang_layout_quest_20261018t/longmen_progress / start](../../game/data/dialogs/luoyang_layout_quest_20261018t/longmen_progress.tres) | normal | [8.4 秒](../../game/art/audio/voices/luo/luoyang_layout_quest_20261018t/longmen_progress/%E5%AE%88%E7%AA%9F%E5%83%A7_start_seg01_dialog.mp3) |
| ch4_s4_ancient_temple | 守窟僧 | [luoyang_layout_quest_20261018t/longmen_report / report](../../game/data/dialogs/luoyang_layout_quest_20261018t/longmen_report.tres) | normal | [10.6 秒](../../game/art/audio/voices/luo/luoyang_layout_quest_20261018t/longmen_report/%E5%AE%88%E7%AA%9F%E5%83%A7_report_seg01_dialog.mp3) |
| ch4_s5_temple_tunnel | 伪烈云盟首领 | [ch4_tunnel_boss / start](../../game/data/dialogs/ch4_tunnel_boss.tres) | normal | 无可播人物语音 |
| ch4_s5_temple_tunnel | 赵思颖 | [ch4_tunnel_result / start](../../game/data/dialogs/ch4_tunnel_result.tres) | normal | [7.9 秒](../../game/art/audio/voices/ch4/ch4_tunnel_result/%E8%B5%B5%E6%80%9D%E9%A2%96_start_seg01_dialog.mp3) |
| ch5_s1_relief_road | 雪路劫粮客 | [ch5_relief_road_battle / start](../../game/data/dialogs/ch5_relief_road_battle.tres) | normal | [6.6 秒](../../game/art/audio/voices/ch5/ch5_relief_road_battle/%E9%9B%AA%E8%B7%AF%E5%8A%AB%E7%B2%AE%E5%AE%A2_start_seg01_dialog.mp3) |
| ch5_s1_relief_road | 古峰护粮守卫 | [ch5_relief_road_victory / start](../../game/data/dialogs/ch5_relief_road_victory.tres) | normal | [8.3 秒](../../game/art/audio/voices/ch5/ch5_relief_road_victory/%E5%8F%A4%E5%B3%B0%E6%8A%A4%E7%B2%AE%E5%AE%88%E5%8D%AB_start_seg01_dialog.mp3) |
| ch5_s2_grain_convoy_camp | 古峰护粮守卫 | [ch5_false_banner_evidence / b](../../game/data/dialogs/ch5_false_banner_evidence.tres) | normal | [5.1 秒](../../game/art/audio/voices/ch5/ch5_false_banner_evidence/%E5%8F%A4%E5%B3%B0%E6%8A%A4%E7%B2%AE%E5%AE%88%E5%8D%AB_b_seg01_dialog.mp3) |
| ch5_s2_grain_convoy_camp | 伪烈云突袭手 | [ch5_grain_convoy_battle / start](../../game/data/dialogs/ch5_grain_convoy_battle.tres) | normal | [5.8 秒](../../game/art/audio/voices/ch5/ch5_grain_convoy_battle/%E4%BC%AA%E7%83%88%E4%BA%91%E7%AA%81%E8%A2%AD%E6%89%8B_start_seg01_dialog.mp3) |
| ch5_s2_grain_convoy_camp | 古峰护粮守卫 | [ch5_grain_convoy_intro / start](../../game/data/dialogs/ch5_grain_convoy_intro.tres) | normal | [8.4 秒](../../game/art/audio/voices/ch5/ch5_grain_convoy_intro/%E5%8F%A4%E5%B3%B0%E6%8A%A4%E7%B2%AE%E5%AE%88%E5%8D%AB_start_seg01_dialog.mp3) |
| ch5_s2_grain_convoy_camp | 古峰护粮守卫 | [ch5_grain_convoy_victory / start](../../game/data/dialogs/ch5_grain_convoy_victory.tres) | normal | [6.9 秒](../../game/art/audio/voices/ch5/ch5_grain_convoy_victory/%E5%8F%A4%E5%B3%B0%E6%8A%A4%E7%B2%AE%E5%AE%88%E5%8D%AB_start_seg01_dialog.mp3) |
| ch5_s3_snow_pass | 雪岭追兵 | [ch5_snow_pass_battle / start](../../game/data/dialogs/ch5_snow_pass_battle.tres) | normal | [6.5 秒](../../game/art/audio/voices/ch5/ch5_snow_pass_battle/%E9%9B%AA%E5%B2%AD%E8%BF%BD%E5%85%B5_start_seg01_dialog.mp3) |
| ch5_s3_snow_pass | 唐行舟 | [ch5_snow_pass_intro / start](../../game/data/dialogs/ch5_snow_pass_intro.tres) | normal | [7.6 秒](../../game/art/audio/voices/ch5/ch5_snow_pass_intro/%E5%94%90%E8%A1%8C%E8%88%9F_start_seg01_dialog.mp3) |
| ch5_s3_snow_pass | 沈青禾 | [ch5_snow_pass_victory / start](../../game/data/dialogs/ch5_snow_pass_victory.tres) | normal | [7.4 秒](../../game/art/audio/voices/ch5/ch5_snow_pass_victory/%E6%B2%88%E9%9D%92%E7%A6%BE_start_seg01_dialog.mp3) |
| ch5_s4_abandoned_mine | 矿道灭口人 | [ch5_mine_hunter_battle / start](../../game/data/dialogs/ch5_mine_hunter_battle.tres) | weary | [7.1 秒](../../game/art/audio/voices/ch5/ch5_mine_hunter_battle/%E7%9F%BF%E9%81%93%E7%81%AD%E5%8F%A3%E4%BA%BA_start_seg01_dialog.mp3) |
| ch5_s4_abandoned_mine | 沈青禾 | [ch5_mine_hunter_victory / start](../../game/data/dialogs/ch5_mine_hunter_victory.tres) | normal | [6.3 秒](../../game/art/audio/voices/ch5/ch5_mine_hunter_victory/%E6%B2%88%E9%9D%92%E7%A6%BE_start_seg01_dialog.mp3) |
| ch5_s4_abandoned_mine | 唐行舟 | [ch5_mine_intro / b](../../game/data/dialogs/ch5_mine_intro.tres) | normal | 无可播人物语音 |
| ch5_s4_abandoned_mine | 旧案幸存者 | [ch5_mine_survivor_testimony / b](../../game/data/dialogs/ch5_mine_survivor_testimony.tres) | normal | 无可播人物语音 |
| ch5_s4_abandoned_mine | 旧案幸存者 | [ch5_mine_survivor_testimony / start](../../game/data/dialogs/ch5_mine_survivor_testimony.tres) | solemn | 无可播人物语音 |
| ch5_s5_false_banner_outpost | 沈青禾 | [ch5_disclosure_choice / hold](../../game/data/dialogs/ch5_disclosure_choice.tres) | angry | [10.5 秒](../../game/art/audio/voices/ch5/ch5_disclosure_choice/%E6%B2%88%E9%9D%92%E7%A6%BE_hold_seg01_dialog.mp3) |
| ch5_s5_false_banner_outpost | 唐行舟 | [ch5_disclosure_choice / publish](../../game/data/dialogs/ch5_disclosure_choice.tres) | normal | [10.6 秒](../../game/art/audio/voices/ch5/ch5_disclosure_choice/%E5%94%90%E8%A1%8C%E8%88%9F_publish_seg01_dialog.mp3) |
| ch5_s5_false_banner_outpost | 伪旗统领 | [ch5_false_banner_boss_prebattle / c](../../game/data/dialogs/ch5_false_banner_boss_prebattle.tres) | threat | 无可播人物语音 |
| ch5_s5_false_banner_outpost | 伪旗统领 | [ch5_false_banner_boss_prebattle / start](../../game/data/dialogs/ch5_false_banner_boss_prebattle.tres) | threat | 无可播人物语音 |
| ch5_s5_false_banner_outpost | 伪旗统领 | [ch5_false_banner_boss_victory / b](../../game/data/dialogs/ch5_false_banner_boss_victory.tres) | weary | [8.3 秒](../../game/art/audio/voices/ch5/ch5_false_banner_boss_victory/%E4%BC%AA%E6%97%97%E7%BB%9F%E9%A2%86_b_seg01_dialog.mp3) |
| ch5_s5_false_banner_outpost | 唐行舟 | [ch5_false_banner_boss_victory / d](../../game/data/dialogs/ch5_false_banner_boss_victory.tres) | normal | [9.7 秒](../../game/art/audio/voices/ch5/ch5_false_banner_boss_victory/%E5%94%90%E8%A1%8C%E8%88%9F_d_seg01_dialog.mp3) |
| ch5_s5_false_banner_outpost | 伪旗统领 | [ch5_false_banner_captain_followup / start](../../game/data/dialogs/ch5_false_banner_captain_followup.tres) | weary | 无可播人物语音 |
| ch5_s5_false_banner_outpost | 唐行舟 | [ch5_false_banner_outpost_intro / start](../../game/data/dialogs/ch5_false_banner_outpost_intro.tres) | solemn | [7.8 秒](../../game/art/audio/voices/ch5/ch5_false_banner_outpost_intro/%E5%94%90%E8%A1%8C%E8%88%9F_start_seg01_dialog.mp3) |
| ch5_s5_false_banner_outpost | 沈青禾 | [ch5_false_banner_poisoned_weapons / start](../../game/data/dialogs/ch5_false_banner_poisoned_weapons.tres) | concerned | [9.5 秒](../../game/art/audio/voices/ch5/ch5_false_banner_poisoned_weapons/%E6%B2%88%E9%9D%92%E7%A6%BE_start_seg01_dialog.mp3) |
| ch6_s3_underground_archive | 茗雾焚册客 | [ch6_archive_prebattle / fight](../../game/data/dialogs/ch6_archive_prebattle.tres) | threat | [4.5 秒](../../game/art/audio/voices/ch6/ch6_archive_prebattle/%E8%8C%97%E9%9B%BE%E7%84%9A%E5%86%8C%E5%AE%A2_fight_seg01_dialog.mp3) |
| ch6_s3_underground_archive | 茗雾销卷使 | [ch6_archive_prebattle / start](../../game/data/dialogs/ch6_archive_prebattle.tres) | threat | [7.6 秒](../../game/art/audio/voices/ch6/ch6_archive_prebattle/%E8%8C%97%E9%9B%BE%E9%94%80%E5%8D%B7%E4%BD%BF_start_seg01_dialog.mp3) |
| ch6_s3_underground_archive | 茗雾断卷客 | [encounter_ch6_archive_exit_enforcer / start](../../game/data/dialogs/encounter_ch6_archive_exit_enforcer.tres) | normal | 无可播人物语音 |
| ch6_s4_baishui_convoy_route | 茗雾寻迹者 | [ch6_baishui_prebattle / fight](../../game/data/dialogs/ch6_baishui_prebattle.tres) | threat | 无可播人物语音 |
| ch6_s4_baishui_convoy_route | 茗雾截证客 | [ch6_baishui_prebattle / start](../../game/data/dialogs/ch6_baishui_prebattle.tres) | threat | 无可播人物语音 |
| ch7_s1_lieyun_valley_ferry | 旧渡守望 | [ch7_lieyun_arrival / guard](../../game/data/dialogs/ch7_lieyun_arrival.tres) | solemn | [9.2 秒](../../game/art/audio/voices/ch7/ch7_lieyun_arrival/%E6%97%A7%E6%B8%A1%E5%AE%88%E6%9C%9B_guard_seg01_dialog.mp3) |
| ch7_s1_lieyun_valley_ferry | 旧渡守望 | [ch7_lieyun_gatekeeper_alerted / start](../../game/data/dialogs/ch7_lieyun_gatekeeper_alerted.tres) | concerned | 无可播人物语音 |
| ch7_s1_lieyun_valley_ferry | 旧渡守望 | [ch7_lieyun_gatekeeper_open / start](../../game/data/dialogs/ch7_lieyun_gatekeeper_open.tres) | solemn | 无可播人物语音 |
| ch7_s1_lieyun_valley_ferry | 旧渡守望 | [ch7_outer_routes_open / open](../../game/data/dialogs/ch7_outer_routes_open.tres) | normal | [9.5 秒](../../game/art/audio/voices/ch7/ch7_outer_routes_open/%E6%97%A7%E6%B8%A1%E5%AE%88%E6%9C%9B_open_seg01_dialog.mp3) |
| ch7_s2_mingwu_tea_town | 茶镇经手人 | [ch7_mingwu_arrival / broker](../../game/data/dialogs/ch7_mingwu_arrival.tres) | normal | [10.2 秒](../../game/art/audio/voices/ch7/ch7_mingwu_arrival/%E8%8C%B6%E9%95%87%E7%BB%8F%E6%89%8B%E4%BA%BA_broker_seg01_dialog.mp3) |
| ch7_s2_mingwu_tea_town | 茶镇经手人 | [ch7_mingwu_broker_alerted / start](../../game/data/dialogs/ch7_mingwu_broker_alerted.tres) | concerned | 无可播人物语音 |
| ch7_s2_mingwu_tea_town | 茶镇经手人 | [ch7_mingwu_broker_open / start](../../game/data/dialogs/ch7_mingwu_broker_open.tres) | normal | 无可播人物语音 |
| ch7_s2_mingwu_tea_town | 茶镇经手人 | [ch7_outer_routes_open / open](../../game/data/dialogs/ch7_outer_routes_open.tres) | normal | [9.1 秒](../../game/art/audio/voices/ch7/ch7_outer_routes_open/%E8%8C%B6%E9%95%87%E7%BB%8F%E6%89%8B%E4%BA%BA_open_seg01_dialog.mp3) |
| ch7_s3_lieyun_outpost_outer_ward | 聚义厅引路人 | [ch7_inner_routes_open / open](../../game/data/dialogs/ch7_inner_routes_open.tres) | normal | [8.2 秒](../../game/art/audio/voices/ch7/ch7_inner_routes_open/%E8%81%9A%E4%B9%89%E5%8E%85%E5%BC%95%E8%B7%AF%E4%BA%BA_open_seg01_dialog.mp3) |
| ch7_s3_lieyun_outpost_outer_ward | 烈云封渡寻迹手 | [ch7_lieyun_hardliner_prebattle / fight](../../game/data/dialogs/ch7_lieyun_hardliner_prebattle.tres) | threat | 无可播人物语音 |
| ch7_s3_lieyun_outpost_outer_ward | 烈云强硬派巡守 | [ch7_lieyun_hardliner_prebattle / start](../../game/data/dialogs/ch7_lieyun_hardliner_prebattle.tres) | threat | 无可播人物语音 |
| ch7_s3_lieyun_outpost_outer_ward | 烈云封渡寻迹手 | [ch7_lieyun_hardliner_prebattle_alerted / fight](../../game/data/dialogs/ch7_lieyun_hardliner_prebattle_alerted.tres) | threat | 无可播人物语音 |
| ch7_s3_lieyun_outpost_outer_ward | 烈云强硬派巡守 | [ch7_lieyun_hardliner_prebattle_alerted / start](../../game/data/dialogs/ch7_lieyun_hardliner_prebattle_alerted.tres) | threat | 无可播人物语音 |
| ch7_s3_lieyun_outpost_outer_ward | 烈云破阵校尉 | [encounter_liuyun_elite / start](../../game/data/dialogs/encounter_liuyun_elite.tres) | normal | 无可播人物语音 |
| ch7_s4_mingwu_manor_outer_court | 封砚秋 | [ch7_guyun_mingwu_catalog / correct](../../game/data/dialogs/ch7_guyun_mingwu_catalog.tres) | normal | [13.5 秒](../../game/art/audio/voices/ch7/ch7_guyun_mingwu_catalog/%E5%B0%81%E7%A0%9A%E7%A7%8B_correct_seg01_dialog.mp3) |
| ch7_s4_mingwu_manor_outer_court | 封砚秋 | [ch7_guyun_mingwu_catalog / puzzle](../../game/data/dialogs/ch7_guyun_mingwu_catalog.tres) | normal | [13.0 秒](../../game/art/audio/voices/ch7/ch7_guyun_mingwu_catalog/%E5%B0%81%E7%A0%9A%E7%A7%8B_puzzle_seg01_dialog.mp3) |
| ch7_s4_mingwu_manor_outer_court | 封砚秋 | [ch7_guyun_mingwu_catalog / start](../../game/data/dialogs/ch7_guyun_mingwu_catalog.tres) | normal | [13.3 秒](../../game/art/audio/voices/ch7/ch7_guyun_mingwu_catalog/%E5%B0%81%E7%A0%9A%E7%A7%8B_start_seg01_dialog.mp3) |
| ch7_s4_mingwu_manor_outer_court | 封砚秋 | [ch7_guyun_mingwu_catalog / wrong](../../game/data/dialogs/ch7_guyun_mingwu_catalog.tres) | normal | [8.5 秒](../../game/art/audio/voices/ch7/ch7_guyun_mingwu_catalog/%E5%B0%81%E7%A0%9A%E7%A7%8B_wrong_seg01_dialog.mp3) |
| ch7_s4_mingwu_manor_outer_court | 外院录事 | [ch7_inner_routes_open / open](../../game/data/dialogs/ch7_inner_routes_open.tres) | normal | [7.7 秒](../../game/art/audio/voices/ch7/ch7_inner_routes_open/%E5%A4%96%E9%99%A2%E5%BD%95%E4%BA%8B_open_seg01_dialog.mp3) |
| ch7_s4_mingwu_manor_outer_court | 外院录事 | [ch7_mingwu_outer_clerk / start](../../game/data/dialogs/ch7_mingwu_outer_clerk.tres) | concerned | 无可播人物语音 |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch7_authorization_routes_open / start](../../game/data/dialogs/ch7_authorization_routes_open.tres) | normal | [11.5 秒](../../game/art/audio/voices/ch7/ch7_authorization_routes_open/%E6%88%9A%E4%BA%91%E7%AC%99_start_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch7_dead_code_routes_open / start](../../game/data/dialogs/ch7_dead_code_routes_open.tres) | solemn | [13.1 秒](../../game/art/audio/voices/ch7/ch7_dead_code_routes_open/%E6%88%9A%E4%BA%91%E7%AC%99_start_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch7_disclosure_strategy_choice / choice](../../game/data/dialogs/ch7_disclosure_strategy_choice.tres) | normal | 无可播人物语音 |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch7_disclosure_strategy_choice / converge](../../game/data/dialogs/ch7_disclosure_strategy_choice.tres) | normal | [9.6 秒](../../game/art/audio/voices/ch7/ch7_disclosure_strategy_choice/%E6%88%9A%E4%BA%91%E7%AC%99_converge_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch7_disclosure_strategy_choice / start](../../game/data/dialogs/ch7_disclosure_strategy_choice.tres) | normal | [9.8 秒](../../game/art/audio/voices/ch7/ch7_disclosure_strategy_choice/%E6%88%9A%E4%BA%91%E7%AC%99_start_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch7_identity_routes_open / start](../../game/data/dialogs/ch7_identity_routes_open.tres) | normal | [11.9 秒](../../game/art/audio/voices/ch7/ch7_identity_routes_open/%E6%88%9A%E4%BA%91%E7%AC%99_start_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch7_personal_signature_inquiry_open / start](../../game/data/dialogs/ch7_personal_signature_inquiry_open.tres) | normal | [9.5 秒](../../game/art/audio/voices/ch7/ch7_personal_signature_inquiry_open/%E6%88%9A%E4%BA%91%E7%AC%99_start_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch7_qi_yunsheng_after_testimony / start](../../game/data/dialogs/ch7_qi_yunsheng_after_testimony.tres) | normal | [9.3 秒](../../game/art/audio/voices/ch7/ch7_qi_yunsheng_after_testimony/%E6%88%9A%E4%BA%91%E7%AC%99_start_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch7_qi_yunsheng_meeting / admit](../../game/data/dialogs/ch7_qi_yunsheng_meeting.tres) | solemn | [11.6 秒](../../game/art/audio/voices/ch7/ch7_qi_yunsheng_meeting/%E6%88%9A%E4%BA%91%E7%AC%99_admit_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch7_qi_yunsheng_meeting / record](../../game/data/dialogs/ch7_qi_yunsheng_meeting.tres) | solemn | [13.8 秒](../../game/art/audio/voices/ch7/ch7_qi_yunsheng_meeting/%E6%88%9A%E4%BA%91%E7%AC%99_record_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch7_qi_yunsheng_meeting / start](../../game/data/dialogs/ch7_qi_yunsheng_meeting.tres) | normal | [10.8 秒](../../game/art/audio/voices/ch7/ch7_qi_yunsheng_meeting/%E6%88%9A%E4%BA%91%E7%AC%99_start_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch7_witness_protection_choice / choice](../../game/data/dialogs/ch7_witness_protection_choice.tres) | normal | 无可播人物语音 |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch7_witness_protection_choice / converge](../../game/data/dialogs/ch7_witness_protection_choice.tres) | normal | [8.0 秒](../../game/art/audio/voices/ch7/ch7_witness_protection_choice/%E6%88%9A%E4%BA%91%E7%AC%99_converge_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch7_witness_protection_choice / start](../../game/data/dialogs/ch7_witness_protection_choice.tres) | normal | [11.8 秒](../../game/art/audio/voices/ch7/ch7_witness_protection_choice/%E6%88%9A%E4%BA%91%E7%AC%99_start_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch7_xueying_identity_conclusion / confirm](../../game/data/dialogs/ch7_xueying_identity_conclusion.tres) | normal | [10.7 秒](../../game/art/audio/voices/ch7/ch7_xueying_identity_conclusion/%E6%88%9A%E4%BA%91%E7%AC%99_confirm_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch8_aftermath_lieyun / end](../../game/data/dialogs/ch8_aftermath_lieyun.tres) | normal | [10.2 秒](../../game/art/audio/voices/ch8/ch8_aftermath_lieyun/%E6%88%9A%E4%BA%91%E7%AC%99_end_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch8_aftermath_lieyun / start](../../game/data/dialogs/ch8_aftermath_lieyun.tres) | normal | [12.6 秒](../../game/art/audio/voices/ch8/ch8_aftermath_lieyun/%E6%88%9A%E4%BA%91%E7%AC%99_start_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch8_relationship_qi_yunsheng / independent](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) | normal | [9.8 秒](../../game/art/audio/voices/ch8/ch8_relationship_qi_yunsheng/%E6%88%9A%E4%BA%91%E7%AC%99_independent_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch8_relationship_qi_yunsheng / start](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) | normal | [9.9 秒](../../game/art/audio/voices/ch8/ch8_relationship_qi_yunsheng/%E6%88%9A%E4%BA%91%E7%AC%99_start_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 戚云笙 | [ch8_relationship_qi_yunsheng / together](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) | normal | [10.6 秒](../../game/art/audio/voices/ch8/ch8_relationship_qi_yunsheng/%E6%88%9A%E4%BA%91%E7%AC%99_together_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 悦无姮 | [ch8_relationship_yuewuheng / independent](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) | normal | [7.7 秒](../../game/art/audio/voices/ch8/ch8_relationship_yuewuheng/%E6%82%A6%E6%97%A0%E5%A7%AE_independent_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 悦无姮 | [ch8_relationship_yuewuheng / start](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) | normal | [8.5 秒](../../game/art/audio/voices/ch8/ch8_relationship_yuewuheng/%E6%82%A6%E6%97%A0%E5%A7%AE_start_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 悦无姮 | [ch8_relationship_yuewuheng / together](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) | normal | [6.0 秒](../../game/art/audio/voices/ch8/ch8_relationship_yuewuheng/%E6%82%A6%E6%97%A0%E5%A7%AE_together_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 赵思颖 | [ch8_relationship_zhao_siying / independent](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) | normal | [7.9 秒](../../game/art/audio/voices/ch8/ch8_relationship_zhao_siying/%E8%B5%B5%E6%80%9D%E9%A2%96_independent_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 赵思颖 | [ch8_relationship_zhao_siying / start](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) | normal | [10.6 秒](../../game/art/audio/voices/ch8/ch8_relationship_zhao_siying/%E8%B5%B5%E6%80%9D%E9%A2%96_start_seg01_dialog.mp3) |
| ch7_s5_lieyun_assembly_hall | 赵思颖 | [ch8_relationship_zhao_siying / together](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) | normal | [7.9 秒](../../game/art/audio/voices/ch8/ch8_relationship_zhao_siying/%E8%B5%B5%E6%80%9D%E9%A2%96_together_seg01_dialog.mp3) |
| ch7_s6_mingwu_inner_court | 外院录事 | [ch7_mingwu_clerk_witness_alerted / limit](../../game/data/dialogs/ch7_mingwu_clerk_witness_alerted.tres) | fear | 无可播人物语音 |
| ch7_s6_mingwu_inner_court | 外院录事 | [ch7_mingwu_clerk_witness_alerted / start](../../game/data/dialogs/ch7_mingwu_clerk_witness_alerted.tres) | fear | 无可播人物语音 |
| ch7_s6_mingwu_inner_court | 外院录事 | [ch7_mingwu_clerk_witness_direct / limit](../../game/data/dialogs/ch7_mingwu_clerk_witness_direct.tres) | fear | 无可播人物语音 |
| ch7_s6_mingwu_inner_court | 外院录事 | [ch7_mingwu_clerk_witness_direct / start](../../game/data/dialogs/ch7_mingwu_clerk_witness_direct.tres) | fear | 无可播人物语音 |
| ch7_s7_lieyun_resettlement_archive | 旧渡记档人 | [ch7_lieyun_record_keeper_testimony / limit](../../game/data/dialogs/ch7_lieyun_record_keeper_testimony.tres) | concerned | [10.2 秒](../../game/art/audio/voices/ch7/ch7_lieyun_record_keeper_testimony/%E6%97%A7%E6%B8%A1%E8%AE%B0%E6%A1%A3%E4%BA%BA_limit_seg01_dialog.mp3) |
| ch7_s7_lieyun_resettlement_archive | 旧渡记档人 | [ch7_lieyun_record_keeper_testimony / start](../../game/data/dialogs/ch7_lieyun_record_keeper_testimony.tres) | solemn | [10.3 秒](../../game/art/audio/voices/ch7/ch7_lieyun_record_keeper_testimony/%E6%97%A7%E6%B8%A1%E8%AE%B0%E6%A1%A3%E4%BA%BA_start_seg01_dialog.mp3) |
| ch7_s9_mingwu_seal_audit_room | 茗雾内署护档使 | [ch7_inner_office_destroyers_prebattle / start](../../game/data/dialogs/ch7_inner_office_destroyers_prebattle.tres) | threat | [7.2 秒](../../game/art/audio/voices/ch7/ch7_inner_office_destroyers_prebattle/%E8%8C%97%E9%9B%BE%E5%86%85%E7%BD%B2%E6%8A%A4%E6%A1%A3%E4%BD%BF_start_seg01_dialog.mp3) |
| ch7_s9_mingwu_seal_audit_room | 茗雾旧教习 | [ch7_mingwu_instructor_recognition / start](../../game/data/dialogs/ch7_mingwu_instructor_recognition.tres) | solemn | [10.9 秒](../../game/art/audio/voices/ch7/ch7_mingwu_instructor_recognition/%E8%8C%97%E9%9B%BE%E6%97%A7%E6%95%99%E4%B9%A0_start_seg01_dialog.mp3) |
| ch7_s9_mingwu_seal_audit_room | 茗雾封针使 | [encounter_mingwu_elite_guard / start](../../game/data/dialogs/encounter_mingwu_elite_guard.tres) | normal | 无可播人物语音 |
| ch8_s1_alliance_staging_ground | 会盟录事 | [ch8_muster_luoyang / start](../../game/data/dialogs/ch8_muster_luoyang.tres) | normal | [9.5 秒](../../game/art/audio/voices/ch8/ch8_muster_luoyang/%E4%BC%9A%E7%9B%9F%E5%BD%95%E4%BA%8B_start_seg01_dialog.mp3) |
| ch8_s1_alliance_staging_ground | 会盟录事 | [ch8_muster_public / start](../../game/data/dialogs/ch8_muster_public.tres) | normal | [8.9 秒](../../game/art/audio/voices/ch8/ch8_muster_public/%E4%BC%9A%E7%9B%9F%E5%BD%95%E4%BA%8B_start_seg01_dialog.mp3) |
| ch8_s1_alliance_staging_ground | 会盟录事 | [ch8_muster_split / start](../../game/data/dialogs/ch8_muster_split.tres) | normal | [8.4 秒](../../game/art/audio/voices/ch8/ch8_muster_split/%E4%BC%9A%E7%9B%9F%E5%BD%95%E4%BA%8B_start_seg01_dialog.mp3) |
| ch8_s2_mistwood_blockade | 茗雾截盟使 | [ch8_mistwood_prebattle / start](../../game/data/dialogs/ch8_mistwood_prebattle.tres) | normal | [7.3 秒](../../game/art/audio/voices/ch8/ch8_mistwood_prebattle/%E8%8C%97%E9%9B%BE%E6%88%AA%E7%9B%9F%E4%BD%BF_start_seg01_dialog.mp3) |
| ch8_s4_alliance_mechanism_gallery | 茗雾机关监守 | [ch8_mechanism_prebattle / start](../../game/data/dialogs/ch8_mechanism_prebattle.tres) | normal | [7.0 秒](../../game/art/audio/voices/ch8/ch8_mechanism_prebattle/%E8%8C%97%E9%9B%BE%E6%9C%BA%E5%85%B3%E7%9B%91%E5%AE%88_start_seg01_dialog.mp3) |
| ch8_s5_alliance_ceremonial_platform | 茗雾假令传使 | [ch8_false_order_prebattle / start](../../game/data/dialogs/ch8_false_order_prebattle.tres) | normal | [7.6 秒](../../game/art/audio/voices/ch8/ch8_false_order_prebattle/%E8%8C%97%E9%9B%BE%E5%81%87%E4%BB%A4%E4%BC%A0%E4%BD%BF_start_seg01_dialog.mp3) |
| ch8_s5_alliance_ceremonial_platform | 苏雾笙 | [ch8_su_first_confrontation / choice](../../game/data/dialogs/ch8_su_first_confrontation.tres) | normal | 无可播人物语音 |
| ch8_s5_alliance_ceremonial_platform | 苏雾笙 | [ch8_su_first_confrontation / evidence](../../game/data/dialogs/ch8_su_first_confrontation.tres) | normal | [9.6 秒](../../game/art/audio/voices/ch8/ch8_su_first_confrontation/%E8%8B%8F%E9%9B%BE%E7%AC%99_evidence_seg01_dialog.mp3) |
| ch8_s5_alliance_ceremonial_platform | 苏雾笙 | [ch8_su_first_confrontation / motive](../../game/data/dialogs/ch8_su_first_confrontation.tres) | normal | [10.6 秒](../../game/art/audio/voices/ch8/ch8_su_first_confrontation/%E8%8B%8F%E9%9B%BE%E7%AC%99_motive_seg01_dialog.mp3) |
| ch8_s5_alliance_ceremonial_platform | 苏雾笙 | [ch8_su_first_confrontation / save](../../game/data/dialogs/ch8_su_first_confrontation.tres) | normal | [7.8 秒](../../game/art/audio/voices/ch8/ch8_su_first_confrontation/%E8%8B%8F%E9%9B%BE%E7%AC%99_save_seg01_dialog.mp3) |
| ch8_s5_alliance_ceremonial_platform | 苏雾笙 | [ch8_su_first_confrontation / start](../../game/data/dialogs/ch8_su_first_confrontation.tres) | normal | [9.3 秒](../../game/art/audio/voices/ch8/ch8_su_first_confrontation/%E8%8B%8F%E9%9B%BE%E7%AC%99_start_seg01_dialog.mp3) |
| ch8_s5_alliance_ceremonial_platform | 刑樊天 | [ch8_truth_disclosure_full / arts](../../game/data/dialogs/ch8_truth_disclosure_full.tres) | normal | [12.7 秒](../../game/art/audio/voices/ch8/ch8_truth_disclosure_full/%E5%88%91%E6%A8%8A%E5%A4%A9_arts_seg01_dialog.mp3) |
| ch8_s5_alliance_ceremonial_platform | 戚云笙 | [ch8_truth_disclosure_full / witness](../../game/data/dialogs/ch8_truth_disclosure_full.tres) | normal | [14.6 秒](../../game/art/audio/voices/ch8/ch8_truth_disclosure_full/%E6%88%9A%E4%BA%91%E7%AC%99_witness_seg01_dialog.mp3) |
| ch8_s5_alliance_ceremonial_platform | 刑樊天 | [ch8_truth_disclosure_joint / arts](../../game/data/dialogs/ch8_truth_disclosure_joint.tres) | normal | [10.3 秒](../../game/art/audio/voices/ch8/ch8_truth_disclosure_joint/%E5%88%91%E6%A8%8A%E5%A4%A9_arts_seg01_dialog.mp3) |
| ch8_s5_alliance_ceremonial_platform | 戚云笙 | [ch8_truth_disclosure_joint / witness](../../game/data/dialogs/ch8_truth_disclosure_joint.tres) | normal | [11.0 秒](../../game/art/audio/voices/ch8/ch8_truth_disclosure_joint/%E6%88%9A%E4%BA%91%E7%AC%99_witness_seg01_dialog.mp3) |
| ch8_s5_alliance_ceremonial_platform | 刑樊天 | [ch8_truth_disclosure_staged / arts](../../game/data/dialogs/ch8_truth_disclosure_staged.tres) | normal | [12.1 秒](../../game/art/audio/voices/ch8/ch8_truth_disclosure_staged/%E5%88%91%E6%A8%8A%E5%A4%A9_arts_seg01_dialog.mp3) |
| ch8_s5_alliance_ceremonial_platform | 戚云笙 | [ch8_truth_disclosure_staged / witness](../../game/data/dialogs/ch8_truth_disclosure_staged.tres) | normal | [12.5 秒](../../game/art/audio/voices/ch8/ch8_truth_disclosure_staged/%E6%88%9A%E4%BA%91%E7%AC%99_witness_seg01_dialog.mp3) |
| ch8_s6_mingwu_main_hall | 苏雾笙 | [ch8_su_xueying_authorization / choice](../../game/data/dialogs/ch8_su_xueying_authorization.tres) | normal | 无可播人物语音 |
| ch8_s6_mingwu_main_hall | 薛影 | [ch8_su_xueying_authorization / choice](../../game/data/dialogs/ch8_su_xueying_authorization.tres) | normal | 无可播人物语音 |
| ch8_s6_mingwu_main_hall | 薛影 | [ch8_su_xueying_authorization / rescue](../../game/data/dialogs/ch8_su_xueying_authorization.tres) | normal | [10.3 秒](../../game/art/audio/voices/ch8/ch8_su_xueying_authorization/%E8%96%9B%E5%BD%B1_rescue_seg01_dialog.mp3) |
| ch8_s6_mingwu_main_hall | 薛影 | [ch8_su_xueying_authorization / responsibility](../../game/data/dialogs/ch8_su_xueying_authorization.tres) | normal | [8.8 秒](../../game/art/audio/voices/ch8/ch8_su_xueying_authorization/%E8%96%9B%E5%BD%B1_responsibility_seg01_dialog.mp3) |
| ch8_s6_mingwu_main_hall | 苏雾笙 | [ch8_su_xueying_authorization / start](../../game/data/dialogs/ch8_su_xueying_authorization.tres) | normal | [9.6 秒](../../game/art/audio/voices/ch8/ch8_su_xueying_authorization/%E8%8B%8F%E9%9B%BE%E7%AC%99_start_seg01_dialog.mp3) |
| ch8_s6_mingwu_main_hall | 苏雾笙 | [ch8_su_xueying_authorization / su_answer](../../game/data/dialogs/ch8_su_xueying_authorization.tres) | normal | [9.3 秒](../../game/art/audio/voices/ch8/ch8_su_xueying_authorization/%E8%8B%8F%E9%9B%BE%E7%AC%99_su_answer_seg01_dialog.mp3) |
| ch8_s6_mingwu_main_hall | 薛影 | [ch8_su_xueying_authorization / testify](../../game/data/dialogs/ch8_su_xueying_authorization.tres) | normal | [11.1 秒](../../game/art/audio/voices/ch8/ch8_su_xueying_authorization/%E8%96%9B%E5%BD%B1_testify_seg01_dialog.mp3) |
| ch8_s6_mingwu_main_hall | 薛影 | [ch8_su_xueying_authorization / xueying](../../game/data/dialogs/ch8_su_xueying_authorization.tres) | normal | [7.7 秒](../../game/art/audio/voices/ch8/ch8_su_xueying_authorization/%E8%96%9B%E5%BD%B1_xueying_seg01_dialog.mp3) |
| ch8_s7_mingwu_rear_sanctum | 苏雾笙 | [ch8_su_final_common / battle](../../game/data/dialogs/ch8_su_final_common.tres) | normal | 无可播人物语音 |
| ch8_s7_mingwu_rear_sanctum | 刑樊天 | [ch8_su_final_common / master](../../game/data/dialogs/ch8_su_final_common.tres) | normal | 无可播人物语音 |
| ch8_s7_mingwu_rear_sanctum | 苏雾笙 | [ch8_su_final_common / su](../../game/data/dialogs/ch8_su_final_common.tres) | normal | 无可播人物语音 |
| ch8_s7_mingwu_rear_sanctum | 苏雾笙 | [ch8_su_final_prelude_dead / start](../../game/data/dialogs/ch8_su_final_prelude_dead.tres) | normal | 无可播人物语音 |
| ch8_s7_mingwu_rear_sanctum | 苏雾笙 | [ch8_su_final_prelude_mingwu / start](../../game/data/dialogs/ch8_su_final_prelude_mingwu.tres) | normal | 无可播人物语音 |
| ch8_s7_mingwu_rear_sanctum | 苏雾笙 | [ch8_su_final_prelude_surrender / start](../../game/data/dialogs/ch8_su_final_prelude_surrender.tres) | normal | 无可播人物语音 |
| ch8_s7_mingwu_rear_sanctum | 苏雾笙 | [ch8_su_final_prelude_testify / start](../../game/data/dialogs/ch8_su_final_prelude_testify.tres) | normal | 无可播人物语音 |
| ch8_s7_mingwu_rear_sanctum | 刑樊天 | [ch8_su_final_victory / master](../../game/data/dialogs/ch8_su_final_victory.tres) | normal | [8.7 秒](../../game/art/audio/voices/ch8/ch8_su_final_victory/%E5%88%91%E6%A8%8A%E5%A4%A9_master_seg01_dialog.mp3) |
| ch8_s7_mingwu_rear_sanctum | 苏雾笙 | [ch8_su_final_victory / su](../../game/data/dialogs/ch8_su_final_victory.tres) | normal | [8.3 秒](../../game/art/audio/voices/ch8/ch8_su_final_victory/%E8%8B%8F%E9%9B%BE%E7%AC%99_su_seg01_dialog.mp3) |
| ch8_s7_mingwu_rear_sanctum | 薛影 | [ch8_xueying_battle_victory / last](../../game/data/dialogs/ch8_xueying_battle_victory.tres) | normal | [9.0 秒](../../game/art/audio/voices/ch8/ch8_xueying_battle_victory/%E8%96%9B%E5%BD%B1_last_seg01_dialog.mp3) |
| ch8_s7_mingwu_rear_sanctum | 薛影 | [ch8_xueying_forced_battle / start](../../game/data/dialogs/ch8_xueying_forced_battle.tres) | normal | 无可播人物语音 |
| ch8_s7_mingwu_rear_sanctum | 薛影 | [ch8_xueying_resolution_choice / battle](../../game/data/dialogs/ch8_xueying_resolution_choice.tres) | normal | [7.1 秒](../../game/art/audio/voices/ch8/ch8_xueying_resolution_choice/%E8%96%9B%E5%BD%B1_battle_seg01_dialog.mp3) |
| ch8_s7_mingwu_rear_sanctum | 薛影 | [ch8_xueying_resolution_choice / choice](../../game/data/dialogs/ch8_xueying_resolution_choice.tres) | normal | 无可播人物语音 |
| ch8_s7_mingwu_rear_sanctum | 薛影 | [ch8_xueying_resolution_choice / start](../../game/data/dialogs/ch8_xueying_resolution_choice.tres) | normal | [10.2 秒](../../game/art/audio/voices/ch8/ch8_xueying_resolution_choice/%E8%96%9B%E5%BD%B1_start_seg01_dialog.mp3) |
| ch8_s7_mingwu_rear_sanctum | 薛影 | [ch8_xueying_resolution_choice / surrender](../../game/data/dialogs/ch8_xueying_resolution_choice.tres) | normal | [9.8 秒](../../game/art/audio/voices/ch8/ch8_xueying_resolution_choice/%E8%96%9B%E5%BD%B1_surrender_seg01_dialog.mp3) |
| ch8_s7_mingwu_rear_sanctum | 薛影 | [ch8_xueying_resolution_choice / testify](../../game/data/dialogs/ch8_xueying_resolution_choice.tres) | normal | [9.7 秒](../../game/art/audio/voices/ch8/ch8_xueying_resolution_choice/%E8%96%9B%E5%BD%B1_testify_seg01_dialog.mp3) |
| east_cangpu_city | 驿站记事 | [east_cangpu_clerk / start](../../game/data/dialogs/east_cangpu_clerk.tres) | normal | 无可播人物语音 |
| east_salt_bay_village | 晒盐村民 | [east_salt_bay_resident / start](../../game/data/dialogs/east_salt_bay_resident.tres) | normal | 无可播人物语音 |
| east_tea_ridge_village | 茶岭茶农 | [east_tea_ridge_farmer / start](../../game/data/dialogs/east_tea_ridge_farmer.tres) | normal | 无可播人物语音 |
| east_tidegate_port | 货栈账房 | [east_tidegate_clerk / start](../../game/data/dialogs/east_tidegate_clerk.tres) | normal | 无可播人物语音 |
| east_tidegate_port | 潮门船头 | [east_tidegate_sail / start](../../game/data/dialogs/east_tidegate_sail.tres) | normal | 无可播人物语音 |
| interior_bandit_cave | 留守山贼 | [interior_bandit_cave_guard / start](../../game/data/dialogs/interior_bandit_cave_guard.tres) | normal | [6.8 秒](../../game/art/audio/voices/int/interior_bandit_cave_guard/%E7%95%99%E5%AE%88%E5%B1%B1%E8%B4%BC_start_seg01_dialog.mp3) |
| interior_inn_hall | 客栈老板 | [ch1_s2_inn_keeper / b](../../game/data/dialogs/ch1_s2_inn_keeper.tres) | normal | [7.3 秒](../../game/art/audio/voices/ch1/ch1_s2_inn_keeper/%E5%AE%A2%E6%A0%88%E8%80%81%E6%9D%BF_b_enormal.mp3) |
| interior_inn_hall | 客栈老板 | [ch1_s2_inn_keeper / start](../../game/data/dialogs/ch1_s2_inn_keeper.tres) | concerned | [5.2 秒](../../game/art/audio/voices/ch1/ch1_s2_inn_keeper/%E5%AE%A2%E6%A0%88%E8%80%81%E6%9D%BF_start.mp3) |
| interior_inn_hall | 客栈老板 | [ch1_s2_inn_keeper_repeat / reply](../../game/data/dialogs/ch1_s2_inn_keeper_repeat.tres) | normal | 无可播人物语音 |
| interior_inn_hall | 店小二 | [ch1_s2_inn_waiter / start](../../game/data/dialogs/ch1_s2_inn_waiter.tres) | normal | [7.1 秒](../../game/art/audio/voices/ch1/ch1_s2_inn_waiter/%E5%BA%97%E5%B0%8F%E4%BA%8C_start_enormal.mp3) |
| interior_inn_hall | 茶客 | [interior_inn_guest_chatter / start](../../game/data/dialogs/interior_inn_guest_chatter.tres) | normal | 无可播人物语音 |
| linxi_tutorial | 刑樊天 | [ch1_return_to_master / n10](../../game/data/dialogs/ch1_return_to_master.tres) | normal | [5.5 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n10_seg02_dialog.mp3) · [6.6 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n10_seg04_dialog.mp3) · [6.4 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n10_seg06_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch1_return_to_master / n2](../../game/data/dialogs/ch1_return_to_master.tres) | normal | [1.8 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n2_seg02_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch1_return_to_master / n4](../../game/data/dialogs/ch1_return_to_master.tres) | normal | [9.9 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n4_seg02_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch1_return_to_master / n6](../../game/data/dialogs/ch1_return_to_master.tres) | normal | [3.2 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n6_seg02_dialog.mp3) · [6.5 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n6_seg04_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch1_return_to_master / n8](../../game/data/dialogs/ch1_return_to_master.tres) | normal | [3.2 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n8_seg01_dialog.mp3) · [12.4 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n8_seg03_dialog.mp3) |
| linxi_tutorial | 杜青衫 | [ch1_tutorial_duqingshan / n3](../../game/data/dialogs/ch1_tutorial_duqingshan.tres) | normal | [13.5 秒](../../game/art/audio/voices/ch1/ch1_tutorial_duqingshan/%E6%9D%9C%E9%9D%92%E8%A1%AB_n3_enormal.mp3) |
| linxi_tutorial | 杜青衫 | [ch1_tutorial_duqingshan / n5](../../game/data/dialogs/ch1_tutorial_duqingshan.tres) | normal | [13.1 秒](../../game/art/audio/voices/ch1/ch1_tutorial_duqingshan/%E6%9D%9C%E9%9D%92%E8%A1%AB_n5_enormal.mp3) |
| linxi_tutorial | 杜青衫 | [ch1_tutorial_duqingshan / start](../../game/data/dialogs/ch1_tutorial_duqingshan.tres) | happy | [10.2 秒](../../game/art/audio/voices/ch1/ch1_tutorial_duqingshan/%E6%9D%9C%E9%9D%92%E8%A1%AB_start_ehappy.mp3) |
| linxi_tutorial | 杜青衫 | [ch1_tutorial_duqingshan_after_sword / start](../../game/data/dialogs/ch1_tutorial_duqingshan_after_sword.tres) | normal | [8.2 秒](../../game/art/audio/voices/ch1/ch1_tutorial_duqingshan_after_sword/%E6%9D%9C%E9%9D%92%E8%A1%AB_start_enormal.mp3) |
| linxi_tutorial | 杜青衫 | [ch1_tutorial_duqingshan_idle / n2](../../game/data/dialogs/ch1_tutorial_duqingshan_idle.tres) | concerned | [11.1 秒](../../game/art/audio/voices/ch1/ch1_tutorial_duqingshan_idle/%E6%9D%9C%E9%9D%92%E8%A1%AB_n2_econcerned.mp3) |
| linxi_tutorial | 杜青衫 | [ch1_tutorial_duqingshan_idle / start](../../game/data/dialogs/ch1_tutorial_duqingshan_idle.tres) | normal | [11.2 秒](../../game/art/audio/voices/ch1/ch1_tutorial_duqingshan_idle/%E6%9D%9C%E9%9D%92%E8%A1%AB_start_enormal.mp3) |
| linxi_tutorial | 刑樊天 | [ch1_tutorial_xingfantian / ask](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) | concerned | [11.9 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_ask_seg02_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch1_tutorial_xingfantian / ask3](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) | solemn | [3.7 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_ask3_seg01_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch1_tutorial_xingfantian / merge](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) | weary | [3.5 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_merge_seg02_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch1_tutorial_xingfantian / merge3](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) | concerned | [10.3 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_merge3_seg01_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch1_tutorial_xingfantian / merge5](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) | solemn | [7.8 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_merge5_seg02_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch1_tutorial_xingfantian / merge8](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) | solemn | [10.6 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_merge8_seg02_dialog.mp3) · [6.0 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_merge8_seg04_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch1_tutorial_xingfantian / n3](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) | normal | [9.6 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_n3_seg01_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch1_tutorial_xingfantian / n6](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) | concerned | [1.8 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_n6_seg01_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch1_tutorial_xingfantian / start](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) | normal | [4.6 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_start_seg01_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch1_tutorial_xingfantian / train2](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) | normal | [5.8 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_train2_seg01_dialog.mp3) · [1.9 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_train2_seg03_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch1_tutorial_xingfantian_idle / start](../../game/data/dialogs/ch1_tutorial_xingfantian_idle.tres) | concerned | [7.3 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian_idle/%E5%88%91%E6%A8%8A%E5%A4%A9_start_seg01_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch6_master_after_choice / start](../../game/data/dialogs/ch6_master_after_choice.tres) | solemn | 无可播人物语音 |
| linxi_tutorial | 刑樊天 | [ch6_master_after_records / master](../../game/data/dialogs/ch6_master_after_records.tres) | solemn | [10.5 秒](../../game/art/audio/voices/ch6/ch6_master_after_records/%E5%88%91%E6%A8%8A%E5%A4%A9_master.mp3) |
| linxi_tutorial | 刑樊天 | [ch6_master_confrontation / choice](../../game/data/dialogs/ch6_master_confrontation.tres) | normal | 无可播人物语音 |
| linxi_tutorial | 刑樊天 | [ch6_master_confrontation / converge](../../game/data/dialogs/ch6_master_confrontation.tres) | normal | [11.1 秒](../../game/art/audio/voices/ch6/ch6_master_confrontation/%E5%88%91%E6%A8%8A%E5%A4%A9_converge.mp3) |
| linxi_tutorial | 刑樊天 | [ch6_master_confrontation / independent](../../game/data/dialogs/ch6_master_confrontation.tres) | weary | [8.4 秒](../../game/art/audio/voices/ch6/ch6_master_confrontation/%E5%88%91%E6%A8%8A%E5%A4%A9_independent.mp3) |
| linxi_tutorial | 刑樊天 | [ch6_master_confrontation / master](../../game/data/dialogs/ch6_master_confrontation.tres) | solemn | [11.7 秒](../../game/art/audio/voices/ch6/ch6_master_confrontation/%E5%88%91%E6%A8%8A%E5%A4%A9_master.mp3) |
| linxi_tutorial | 刑樊天 | [ch6_master_confrontation / protect](../../game/data/dialogs/ch6_master_confrontation.tres) | concerned | [9.0 秒](../../game/art/audio/voices/ch6/ch6_master_confrontation/%E5%88%91%E6%A8%8A%E5%A4%A9_protect.mp3) |
| linxi_tutorial | 刑樊天 | [ch6_master_confrontation / public](../../game/data/dialogs/ch6_master_confrontation.tres) | solemn | [7.8 秒](../../game/art/audio/voices/ch6/ch6_master_confrontation/%E5%88%91%E6%A8%8A%E5%A4%A9_public.mp3) |
| linxi_tutorial | 刑樊天 | [ch6_master_return_followup / start](../../game/data/dialogs/ch6_master_return_followup.tres) | weary | 无可播人物语音 |
| linxi_tutorial | 刑樊天 | [ch6_return_intro / answer](../../game/data/dialogs/ch6_return_intro.tres) | solemn | [8.2 秒](../../game/art/audio/voices/ch6/ch6_return_intro/%E5%88%91%E6%A8%8A%E5%A4%A9_answer.mp3) |
| linxi_tutorial | 刑樊天 | [ch6_return_intro / master](../../game/data/dialogs/ch6_return_intro.tres) | weary | [8.8 秒](../../game/art/audio/voices/ch6/ch6_return_intro/%E5%88%91%E6%A8%8A%E5%A4%A9_master.mp3) |
| linxi_tutorial | 封砚秋 | [ch8_guyun_feng_ready / start](../../game/data/dialogs/ch8_guyun_feng_ready.tres) | normal | 无可播人物语音 |
| linxi_tutorial | 封砚秋 | [ch8_guyun_feng_waiting / start](../../game/data/dialogs/ch8_guyun_feng_waiting.tres) | normal | 无可播人物语音 |
| linxi_tutorial | 刑樊天 | [ch8_guyun_master_waiting / start](../../game/data/dialogs/ch8_guyun_master_waiting.tres) | normal | 无可播人物语音 |
| linxi_tutorial | 刑樊天 | [ch8_guyun_recollection / n2](../../game/data/dialogs/ch8_guyun_recollection.tres) | normal | [9.2 秒](../../game/art/audio/voices/ch8/ch8_guyun_recollection/%E5%88%91%E6%A8%8A%E5%A4%A9_n2_seg01_dialog.mp3) |
| linxi_tutorial | 封砚秋 | [ch8_guyun_recollection / n3](../../game/data/dialogs/ch8_guyun_recollection.tres) | normal | [7.8 秒](../../game/art/audio/voices/ch8/ch8_guyun_recollection/%E5%B0%81%E7%A0%9A%E7%A7%8B_n3_seg01_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch8_guyun_recollection / n4](../../game/data/dialogs/ch8_guyun_recollection.tres) | normal | [15.1 秒](../../game/art/audio/voices/ch8/ch8_guyun_recollection/%E5%88%91%E6%A8%8A%E5%A4%A9_n4_seg01_dialog.mp3) |
| linxi_tutorial | 封砚秋 | [ch8_guyun_recollection / start](../../game/data/dialogs/ch8_guyun_recollection.tres) | normal | [11.4 秒](../../game/art/audio/voices/ch8/ch8_guyun_recollection/%E5%B0%81%E7%A0%9A%E7%A7%8B_start_seg01_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch8_linxi_final_return / master](../../game/data/dialogs/ch8_linxi_final_return.tres) | normal | [10.0 秒](../../game/art/audio/voices/ch8/ch8_linxi_final_return/%E5%88%91%E6%A8%8A%E5%A4%A9_master_seg01_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch8_linxi_final_return / start](../../game/data/dialogs/ch8_linxi_final_return.tres) | normal | [9.1 秒](../../game/art/audio/voices/ch8/ch8_linxi_final_return/%E5%88%91%E6%A8%8A%E5%A4%A9_start_seg01_dialog.mp3) |
| linxi_tutorial | 刑樊天 | [ch8_master_after_breakthrough / start](../../game/data/dialogs/ch8_master_after_breakthrough.tres) | normal | 无可播人物语音 |
| linxi_tutorial | 刑樊天 | [ch8_master_breakthrough_unready / n3](../../game/data/dialogs/ch8_master_breakthrough_unready.tres) | normal | 无可播人物语音 |
| linxi_tutorial | 刑樊天 | [ch8_master_breakthrough_unready / start](../../game/data/dialogs/ch8_master_breakthrough_unready.tres) | normal | 无可播人物语音 |
| linxi_tutorial | 刑樊天 | [ch8_master_ultimate_breakthrough / n2](../../game/data/dialogs/ch8_master_ultimate_breakthrough.tres) | normal | 无可播人物语音 |
| linxi_tutorial | 封砚秋 | [ch8_master_ultimate_breakthrough / n3](../../game/data/dialogs/ch8_master_ultimate_breakthrough.tres) | normal | 无可播人物语音 |
| linxi_tutorial | 刑樊天 | [ch8_master_ultimate_breakthrough / n5](../../game/data/dialogs/ch8_master_ultimate_breakthrough.tres) | normal | 无可播人物语音 |
| linxi_tutorial | 刑樊天 | [ch8_master_ultimate_breakthrough / n7](../../game/data/dialogs/ch8_master_ultimate_breakthrough.tres) | normal | 无可播人物语音 |
| linxi_village_center | 药铺学徒 | [linxi_center_apothecary_apprentice / start](../../game/data/dialogs/linxi_center_apothecary_apprentice.tres) | warm | 无可播人物语音 |
| linxi_village_center | 归田村民 | [linxi_center_farmer / start](../../game/data/dialogs/linxi_center_farmer.tres) | calm | 无可播人物语音 |
| linxi_village_center | 晒药婆婆 | [linxi_center_granny / start](../../game/data/dialogs/linxi_center_granny.tres) | warm | [10.3 秒](../../game/art/audio/voices/lin/linxi_center_granny/%E6%99%92%E8%8D%AF%E5%A9%86%E5%A9%86_start_seg01_dialog.mp3) |
| linxi_village_center | 采药村妇 | [linxi_center_herb_gatherer / start](../../game/data/dialogs/linxi_center_herb_gatherer.tres) | quiet | [8.4 秒](../../game/art/audio/voices/lin/linxi_center_herb_gatherer/%E9%87%87%E8%8D%AF%E6%9D%91%E5%A6%87_start_seg01_dialog.mp3) |
| linxi_village_center | 药师苏伯 | [linxi_center_herbalist / buy](../../game/data/dialogs/linxi_center_herbalist.tres) | warm | 无可播人物语音 |
| linxi_village_center | 药师苏伯 | [linxi_center_herbalist / leave](../../game/data/dialogs/linxi_center_herbalist.tres) | warm | 无可播人物语音 |
| linxi_village_center | 药师苏伯 | [linxi_center_herbalist / start](../../game/data/dialogs/linxi_center_herbalist.tres) | warm | 无可播人物语音 |
| linxi_village_center | 药师苏伯 | [linxi_center_herbalist_ledger_verify / verify](../../game/data/dialogs/linxi_center_herbalist_ledger_verify.tres) | normal | [11.9 秒](../../game/art/audio/voices/lin/linxi_center_herbalist_ledger_verify/%E8%8D%AF%E5%B8%88%E8%8B%8F%E4%BC%AF_verify_seg01_dialog.mp3) |
| linxi_village_center | 走村货郎 | [linxi_center_peddler / start](../../game/data/dialogs/linxi_center_peddler.tres) | quiet | 无可播人物语音 |
| linxi_village_center | 药师苏伯 | [linxi_cliff_herb_done / start](../../game/data/dialogs/linxi_cliff_herb_done.tres) | normal | [10.4 秒](../../game/art/audio/voices/lin/linxi_cliff_herb_done/%E8%8D%AF%E5%B8%88%E8%8B%8F%E4%BC%AF_start_seg01_dialog.mp3) |
| linxi_village_center | 药师苏伯 | [linxi_cliff_herb_offer / accept](../../game/data/dialogs/linxi_cliff_herb_offer.tres) | normal | [9.3 秒](../../game/art/audio/voices/lin/linxi_cliff_herb_offer/%E8%8D%AF%E5%B8%88%E8%8B%8F%E4%BC%AF_accept_seg01_dialog.mp3) |
| linxi_village_center | 药师苏伯 | [linxi_cliff_herb_offer / ask](../../game/data/dialogs/linxi_cliff_herb_offer.tres) | normal | [11.6 秒](../../game/art/audio/voices/lin/linxi_cliff_herb_offer/%E8%8D%AF%E5%B8%88%E8%8B%8F%E4%BC%AF_ask_seg01_dialog.mp3) |
| linxi_village_center | 药师苏伯 | [linxi_cliff_herb_offer / start](../../game/data/dialogs/linxi_cliff_herb_offer.tres) | normal | [12.8 秒](../../game/art/audio/voices/lin/linxi_cliff_herb_offer/%E8%8D%AF%E5%B8%88%E8%8B%8F%E4%BC%AF_start_seg01_dialog.mp3) |
| linxi_village_center | 药师苏伯 | [linxi_cliff_herb_turnin / finish](../../game/data/dialogs/linxi_cliff_herb_turnin.tres) | normal | [10.4 秒](../../game/art/audio/voices/lin/linxi_cliff_herb_turnin/%E8%8D%AF%E5%B8%88%E8%8B%8F%E4%BC%AF_finish_seg01_dialog.mp3) |
| linxi_village_center | 药师苏伯 | [linxi_cliff_herb_waiting / start](../../game/data/dialogs/linxi_cliff_herb_waiting.tres) | normal | [6.1 秒](../../game/art/audio/voices/lin/linxi_cliff_herb_waiting/%E8%8D%AF%E5%B8%88%E8%8B%8F%E4%BC%AF_start_seg01_dialog.mp3) |
| linxi_village_center | 沈青禾 | [linxi_companion_shen_qinghe / joined](../../game/data/dialogs/linxi_companion_shen_qinghe.tres) | happy | [6.0 秒](../../game/art/audio/voices/lin/linxi_companion_shen_qinghe/%E6%B2%88%E9%9D%92%E7%A6%BE_joined_seg01_dialog.mp3) |
| linxi_village_center | 沈青禾 | [linxi_companion_shen_qinghe / later](../../game/data/dialogs/linxi_companion_shen_qinghe.tres) | angry | [7.0 秒](../../game/art/audio/voices/lin/linxi_companion_shen_qinghe/%E6%B2%88%E9%9D%92%E7%A6%BE_later_seg01_dialog.mp3) |
| linxi_village_center | 沈青禾 | [linxi_companion_shen_qinghe / offer](../../game/data/dialogs/linxi_companion_shen_qinghe.tres) | normal | [8.9 秒](../../game/art/audio/voices/lin/linxi_companion_shen_qinghe/%E6%B2%88%E9%9D%92%E7%A6%BE_offer_seg01_dialog.mp3) |
| linxi_village_center | 沈青禾 | [linxi_companion_shen_qinghe / offer_later](../../game/data/dialogs/linxi_companion_shen_qinghe.tres) | angry | [6.0 秒](../../game/art/audio/voices/lin/linxi_companion_shen_qinghe/%E6%B2%88%E9%9D%92%E7%A6%BE_offer_later_seg01_dialog.mp3) |
| linxi_village_center | 沈青禾 | [linxi_companion_shen_qinghe / pushback](../../game/data/dialogs/linxi_companion_shen_qinghe.tres) | angry | [10.8 秒](../../game/art/audio/voices/lin/linxi_companion_shen_qinghe/%E6%B2%88%E9%9D%92%E7%A6%BE_pushback_seg01_dialog.mp3) |
| linxi_village_center | 沈青禾 | [linxi_companion_shen_qinghe / start](../../game/data/dialogs/linxi_companion_shen_qinghe.tres) | concerned | [12.4 秒](../../game/art/audio/voices/lin/linxi_companion_shen_qinghe/%E6%B2%88%E9%9D%92%E7%A6%BE_start_seg01_dialog.mp3) |
| linxi_village_center | 沈青禾 | [linxi_companion_shen_qinghe_offer / joined](../../game/data/dialogs/linxi_companion_shen_qinghe_offer.tres) | happy | [6.3 秒](../../game/art/audio/voices/lin/linxi_companion_shen_qinghe_offer/%E6%B2%88%E9%9D%92%E7%A6%BE_joined_seg01_dialog.mp3) |
| linxi_village_center | 沈青禾 | [linxi_companion_shen_qinghe_offer / later](../../game/data/dialogs/linxi_companion_shen_qinghe_offer.tres) | angry | [5.0 秒](../../game/art/audio/voices/lin/linxi_companion_shen_qinghe_offer/%E6%B2%88%E9%9D%92%E7%A6%BE_later_seg01_dialog.mp3) |
| linxi_village_center | 沈青禾 | [linxi_companion_shen_qinghe_offer / start](../../game/data/dialogs/linxi_companion_shen_qinghe_offer.tres) | angry | [13.5 秒](../../game/art/audio/voices/lin/linxi_companion_shen_qinghe_offer/%E6%B2%88%E9%9D%92%E7%A6%BE_start_seg01_dialog.mp3) |
| linxi_village_center | 唐行舟 | [linxi_companion_tang_xingzhou / challenge](../../game/data/dialogs/linxi_companion_tang_xingzhou.tres) | happy | [6.0 秒](../../game/art/audio/voices/lin/linxi_companion_tang_xingzhou/%E5%94%90%E8%A1%8C%E8%88%9F_challenge_seg01_dialog.mp3) |
| linxi_village_center | 唐行舟 | [linxi_companion_tang_xingzhou / later](../../game/data/dialogs/linxi_companion_tang_xingzhou.tres) | normal | [4.9 秒](../../game/art/audio/voices/lin/linxi_companion_tang_xingzhou/%E5%94%90%E8%A1%8C%E8%88%9F_later_seg01_dialog.mp3) |
| linxi_village_center | 唐行舟 | [linxi_companion_tang_xingzhou / start](../../game/data/dialogs/linxi_companion_tang_xingzhou.tres) | normal | [10.1 秒](../../game/art/audio/voices/lin/linxi_companion_tang_xingzhou/%E5%94%90%E8%A1%8C%E8%88%9F_start_seg01_dialog.mp3) |
| linxi_village_center | 唐行舟 | [linxi_companion_tang_xingzhou_after_spar / joined](../../game/data/dialogs/linxi_companion_tang_xingzhou_after_spar.tres) | normal | [5.9 秒](../../game/art/audio/voices/lin/linxi_companion_tang_xingzhou_after_spar/%E5%94%90%E8%A1%8C%E8%88%9F_joined_seg01_dialog.mp3) |
| linxi_village_center | 唐行舟 | [linxi_companion_tang_xingzhou_after_spar / later](../../game/data/dialogs/linxi_companion_tang_xingzhou_after_spar.tres) | normal | [6.0 秒](../../game/art/audio/voices/lin/linxi_companion_tang_xingzhou_after_spar/%E5%94%90%E8%A1%8C%E8%88%9F_later_seg01_dialog.mp3) |
| linxi_village_center | 唐行舟 | [linxi_companion_tang_xingzhou_after_spar / offer](../../game/data/dialogs/linxi_companion_tang_xingzhou_after_spar.tres) | normal | [9.6 秒](../../game/art/audio/voices/lin/linxi_companion_tang_xingzhou_after_spar/%E5%94%90%E8%A1%8C%E8%88%9F_offer_seg01_dialog.mp3) |
| linxi_village_center | 唐行舟 | [linxi_companion_tang_xingzhou_after_spar / start](../../game/data/dialogs/linxi_companion_tang_xingzhou_after_spar.tres) | normal | [9.7 秒](../../game/art/audio/voices/lin/linxi_companion_tang_xingzhou_after_spar/%E5%94%90%E8%A1%8C%E8%88%9F_start_seg01_dialog.mp3) |
| linxi_village_scrollmap | 村塾先生 | [ch1_side_stone_teacher_done / start](../../game/data/dialogs/ch1_side_stone_teacher_done.tres) | normal | [8.3 秒](../../game/art/audio/voices/ch1/ch1_side_stone_teacher_done/%E6%9D%91%E5%A1%BE%E5%85%88%E7%94%9F_start_seg01_dialog.mp3) |
| linxi_village_scrollmap | 村塾先生 | [ch1_side_stone_teacher_offer / accept](../../game/data/dialogs/ch1_side_stone_teacher_offer.tres) | normal | [8.6 秒](../../game/art/audio/voices/ch1/ch1_side_stone_teacher_offer/%E6%9D%91%E5%A1%BE%E5%85%88%E7%94%9F_accept_seg01_dialog.mp3) |
| linxi_village_scrollmap | 村塾先生 | [ch1_side_stone_teacher_offer / start](../../game/data/dialogs/ch1_side_stone_teacher_offer.tres) | normal | [13.4 秒](../../game/art/audio/voices/ch1/ch1_side_stone_teacher_offer/%E6%9D%91%E5%A1%BE%E5%85%88%E7%94%9F_start_seg01_dialog.mp3) |
| linxi_village_scrollmap | 村塾先生 | [ch1_side_stone_teacher_turnin / start](../../game/data/dialogs/ch1_side_stone_teacher_turnin.tres) | normal | [8.0 秒](../../game/art/audio/voices/ch1/ch1_side_stone_teacher_turnin/%E6%9D%91%E5%A1%BE%E5%85%88%E7%94%9F_start_seg01_dialog.mp3) |
| linxi_village_scrollmap | 村塾先生 | [ch1_side_stone_teacher_waiting / start](../../game/data/dialogs/ch1_side_stone_teacher_waiting.tres) | normal | [7.0 秒](../../game/art/audio/voices/ch1/ch1_side_stone_teacher_waiting/%E6%9D%91%E5%A1%BE%E5%85%88%E7%94%9F_start_seg01_dialog.mp3) |
| linxi_village_scrollmap | 药铺学徒 | [linxi_center_apothecary_apprentice / start](../../game/data/dialogs/linxi_center_apothecary_apprentice.tres) | warm | 无可播人物语音 |
| linxi_village_scrollmap | 归田村民 | [linxi_center_farmer / start](../../game/data/dialogs/linxi_center_farmer.tres) | calm | 无可播人物语音 |
| linxi_village_scrollmap | 晒药婆婆 | [linxi_center_granny / start](../../game/data/dialogs/linxi_center_granny.tres) | warm | [10.3 秒](../../game/art/audio/voices/lin/linxi_center_granny/%E6%99%92%E8%8D%AF%E5%A9%86%E5%A9%86_start_seg01_dialog.mp3) |
| linxi_village_scrollmap | 采药村妇 | [linxi_center_herb_gatherer / start](../../game/data/dialogs/linxi_center_herb_gatherer.tres) | quiet | [8.4 秒](../../game/art/audio/voices/lin/linxi_center_herb_gatherer/%E9%87%87%E8%8D%AF%E6%9D%91%E5%A6%87_start_seg01_dialog.mp3) |
| linxi_village_scrollmap | 药师苏伯 | [linxi_center_herbalist / buy](../../game/data/dialogs/linxi_center_herbalist.tres) | warm | 无可播人物语音 |
| linxi_village_scrollmap | 药师苏伯 | [linxi_center_herbalist / leave](../../game/data/dialogs/linxi_center_herbalist.tres) | warm | 无可播人物语音 |
| linxi_village_scrollmap | 药师苏伯 | [linxi_center_herbalist / start](../../game/data/dialogs/linxi_center_herbalist.tres) | warm | 无可播人物语音 |
| linxi_village_scrollmap | 走村货郎 | [linxi_center_peddler / start](../../game/data/dialogs/linxi_center_peddler.tres) | quiet | 无可播人物语音 |
| linxi_village_scrollmap | 巡村老兵 | [linxi_scrollmap_veteran / start](../../game/data/dialogs/linxi_scrollmap_veteran.tres) | normal | 无可播人物语音 |
| openworld_bailu_ferry | 渡船管事 | [openworld_bailu_ferry_boat / start](../../game/data/dialogs/openworld_bailu_ferry_boat.tres) | normal | 无可播人物语音 |
| openworld_bailu_ferry | 段长风 | [openworld_duan_changfeng_done / start](../../game/data/dialogs/openworld_duan_changfeng_done.tres) | normal | 无可播人物语音 |
| openworld_bailu_ferry | 段长风 | [openworld_duan_changfeng_join / join](../../game/data/dialogs/openworld_duan_changfeng_join.tres) | normal | 无可播人物语音 |
| openworld_bailu_ferry | 段长风 | [openworld_duan_changfeng_join / start](../../game/data/dialogs/openworld_duan_changfeng_join.tres) | normal | 无可播人物语音 |
| openworld_bailu_ferry | 段长风 | [openworld_duan_changfeng_offer / start](../../game/data/dialogs/openworld_duan_changfeng_offer.tres) | normal | 无可播人物语音 |
| openworld_bianzhou_city | 汴州驿丞 | [openworld_bianzhou_guide / board_location](../../game/data/dialogs/openworld_bianzhou_guide.tres) | normal | 无可播人物语音 |
| openworld_bianzhou_city | 汴州驿丞 | [openworld_bianzhou_guide / start](../../game/data/dialogs/openworld_bianzhou_guide.tres) | normal | 无可播人物语音 |
| openworld_east_sea_port | 渡船管事 | [openworld_east_sea_port_boat / start](../../game/data/dialogs/openworld_east_sea_port_boat.tres) | normal | 无可播人物语音 |
| openworld_huashan_waterfall_terrace | 游天鸿 | [openworld_huashan_lanhui_lesson / leave](../../game/data/dialogs/openworld_huashan_lanhui_lesson.tres) | normal | 无可播人物语音 |
| openworld_huashan_waterfall_terrace | 游天鸿 | [openworld_huashan_lanhui_lesson / lesson](../../game/data/dialogs/openworld_huashan_lanhui_lesson.tres) | normal | 无可播人物语音 |
| openworld_huashan_waterfall_terrace | 观瀑老者 | [openworld_huashan_lanhui_lesson / start](../../game/data/dialogs/openworld_huashan_lanhui_lesson.tres) | normal | 无可播人物语音 |
| openworld_huashan_waterfall_terrace | 游天鸿 | [openworld_huashan_lanhui_revisit / start](../../game/data/dialogs/openworld_huashan_lanhui_revisit.tres) | normal | 无可播人物语音 |
| openworld_jinling_city | 金陵水巡 | [openworld_jinling_guide / board_location](../../game/data/dialogs/openworld_jinling_guide.tres) | normal | 无可播人物语音 |
| openworld_jinling_city | 金陵水巡 | [openworld_jinling_guide / start](../../game/data/dialogs/openworld_jinling_guide.tres) | normal | 无可播人物语音 |
| openworld_qinghe_town | 行旅货郎 | [openworld_qinghe_supply / start](../../game/data/dialogs/openworld_qinghe_supply.tres) | normal | 无可播人物语音 |
| openworld_wudang_gate | 武当守山弟子 | [openworld_wudang_gate_disciple / start](../../game/data/dialogs/openworld_wudang_gate_disciple.tres) | normal | 无可播人物语音 |
| openworld_xiangzhou_city | 襄州守备 | [openworld_xiangzhou_guide / board_location](../../game/data/dialogs/openworld_xiangzhou_guide.tres) | normal | 无可播人物语音 |
| openworld_xiangzhou_city | 襄州守备 | [openworld_xiangzhou_guide / start](../../game/data/dialogs/openworld_xiangzhou_guide.tres) | normal | 无可播人物语音 |
| openworld_yanmen_hidden_cave | 寒岭守藏人 | [openworld_yanmen_cave_guard / start](../../game/data/dialogs/openworld_yanmen_cave_guard.tres) | normal | 无可播人物语音 |
| openworld_yanmen_hidden_cave | 寒岭守藏人 | [openworld_yanmen_cave_guard_victory / start](../../game/data/dialogs/openworld_yanmen_cave_guard_victory.tres) | normal | 无可播人物语音 |
