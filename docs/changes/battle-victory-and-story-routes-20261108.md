# 胜利动作、短曲与八章路线复测

冷孤云胜出后原地挥右手。四个关键帧按抬手、举至肩前、挥到额前、回落播放一次。空手用拳礼，刀剑和棍沿各帧虎口跟随转动，前景手指压住柄，原有兵器光效随武器移动。拳套继续显示双手材质和粒子。普通遭遇、剧情战、切磋胜出均走同一个庆祝入口。

「凯旋 · 挥手礼」是一段 3.72 秒的原创短曲。用鼓击、拨弦和竹笛音色合成，抬手起乐，挥到最高处进入上行旋律，胜利结算沿用同一次播放。音乐走原 BGM 总线。桌面实测确认起播、跨结算连续播放和场景回程，测试音频输出使用 Dummy 驱动。

- [正式胜利精灵图](../../game/art/characters/battle_victory_20261108/victory_salute.png) · [内置 imagegen 最终提示词](../../game/build/victory_quest_20261108/victory_prompt.json)
- [胜利短曲 WAV](../../game/art/audio/bgm/bgm_victory_salute_20261108.wav) · [合成脚本](../../game/build/victory_quest_20261108/compose_victory.py)
- [七星剑实机](../../game/build/victory_quest_20261108/salute_seven_star_sword.png) · [金箍棍实机](../../game/build/victory_quest_20261108/salute_golden_hoop_staff.png) · [空手切磋实机](../../game/build/victory_quest_20261108/salute_unarmed.png) · [资源图鉴](../equipment-skill-catalog.html)
- [战斗日志](../../game/build/victory_quest_20261108/final_victory_stdout.log)共 112 项通过，覆盖剑、刀、棍、拳套、空手四帧及结算后回林西原脚点。

武当到武林会场的去程已有入口，会场旧版只提供江湖大地图出口。本轮补上「返回武当山门」，两端共用武当山门的原入口脚点 (1700, 3875)。会场出口与前往江湖大地图的箭头分开。章前可往返并解让位棋，第二章完成后仍可从同一门触发大会验案。

| 章 | 正式场景实测 | 通过 |
| --- | --- | ---: |
| 一 | 林西中心区、南区两间民居各走一趟，进屋落在室内门附近，返回各自原门脚点 | [26](../../game/build/victory_quest_20261108/pass3_1_stdout.log) |
| 二 | 北林废轨入口、焦黑领料簿、账房账册和直达凌月；凌月内庭、复命、失踪弟子；竹尾回澜三个交互 | [28](../../game/build/victory_quest_20261108/mine_final_stdout.log) + [61](../../game/build/victory_quest_20261108/pass3_lingyue_stdout.log) + [35](../../game/build/victory_quest_20261108/pass3_huilan_stdout.log) |
| 三 | 武当山门与会场双向、原门落脚、章前让位棋、章后从同一门进大会 | [21](../../game/build/victory_quest_20261108/assembly_return_stdout.log) |
| 四 | 洛阳府衙正式导航就绪后实按空格完成含嘉旧水则，并确认第八章案卷吏能生成 | [10](../../game/build/victory_quest_20261108/final_yamen_stdout.log) |
| 五 | 古峰赈粮路、护粮营地、雪岭关、废弃矿洞、伪旗哨站；实触伪旗和幸存者，核对矿洞往返 | [42](../../game/build/victory_quest_20261108/pass3_5_stdout.log) |
| 六 | 师傅正屋查旁注、挪动兵器架开暗门，地下档案室走原门双向，确认接取「地底原册」 | [23](../../game/build/victory_quest_20261108/pass3_6_stdout.log) |
| 七 | 烈云与茗雾完成双线求证、与茶镇经手人对白开门，两处进入外区再回各自原门 | [40](../../game/build/victory_quest_20261108/pass4_7_stdout.log) |
| 八 | 会盟点名、雾林往返、外围比对假令、机关廊双敌战斗回原脚点并续播胜利对白，拆鼓、封雾及祭台往返 | [67](../../game/build/victory_quest_20261108/guard_battle_stdout.log) |

路线用隔离状态分段验证，部分前置战斗预设胜利旗。机关廊经 NPC 正式对白触发双敌战斗，调整测试战斗数值后用正常攻击结束，再通过正式胜利结算回程。未从新游戏逐战打完全部剧情和分支。早期测试的误按、未等刷新和旧断言日志留存。胜利音乐一度写入洛阳来源锁定的 AudioManager，已按原 SHA 恢复，改由战斗和结算传入新曲，复测通过原府衙准入。真实存档未参与。
