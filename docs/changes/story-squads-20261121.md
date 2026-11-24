# 伪旗哨站、雾林与机关廊的五名剧情敌人

五人各有一张 16 姿战斗图集。以冷孤云为身材和画风参照，按原技能表各接两套四帧武功。单挑阵型的备战高度为 202–212 游戏像素，多人战沿用阵型缩放。受击时人物仍站立，落败时先跪下再横倒。袖针出手时显示一枚银针；点烽手和雾阀守手施放「血影散星」时有三枚分向飞出的钢镖。

| 剧情对手 | 单挑基准高度 | 第一门武功 | 第二门武功 |
|---|---:|---|---|
| 伪烈云突袭手 | 207 px | 重斩：举起单刀后下劈 | 毒针：另一手发针，刀仍在手 |
| 茗雾截盟护卫 | 208 px | 雾隐三式：伏身短刃前刺 | 毒针：留刃护身，侧身发针 |
| 茗雾点烽手 | 202 px | 血影散星：拉开双臂，三镖扇射 | 毒针：收肘向左送出单针 |
| 茗雾机关监守 | 212 px | 雾隐三式：提膝转身，反手横刃 | 毒针：压低重心，抬腕平射 |
| 茗雾雾阀守手 | 205 px | 血影散星：低重心伸臂散镖 | 毒针：前手平送单针 |

## 朝向复查

点烽手开场时的两张备战帧原本朝右，攻击帧朝左。伪烈云突袭手的一张备战帧、雾阀守手的两张备战帧与一张步法帧也朝右。现在这六帧各自声明原画方向，战斗显示沿用当前目标方向。另重画雾阀守手普通攻击的头脸，使视线与伸出的手一致。五人共 80 帧，在正式角色渲染器中分别朝左、朝右检查了 160 次。实战图每行第一格取自该敌人施展武功后回到阵位的待机。

[点烽手同一阵位的改前改后](../../reports/story_squads_20261121/signal-facing-comparison.png) · [雾林全屏双方站位](../../reports/story_squads_20261121/facing8/woods/blockade_recovered.png) · [雾阀守手修正后的普攻全屏](../../reports/story_squads_20261121/facing8/gallery/valve_attack.png) · [渲染器朝向检查](../../reports/story_squads_20261121/facing-check2.log)

## 从剧情打到结算

第五章使用既有的 16 级伪旗哨站存档。步行与统领交谈，看完三段对白，原阵容为统领和两名突袭手。第八章使用第七章结算留下的 21 级存档，从聚义厅走到会盟集结地，按存档已有物品整备、点名，然后进入雾林。雾林与机关廊沿同一进度连续游玩，中间走外围连营查三旗，并实际交互断鼓、封雾。[哨站存档](../../reports/ch5_ch8_rebalance_20261120/captain_before.json) · [第七章结算存档](../../reports/late_campaign_20261119_213549/chapter7_settlement_autosave.json) · [集结地到雾林](../../reports/story_squads_20261121/stage.log)

测试读入存档副本，通过 PC 客户端的正式地图交互、对白和战斗回合进入结算。敌人由游戏 AI 选招，我方用普通指令防御、疗伤和攻击。每名敌人的两门武功、受击、倒地均从对应胜局的屏幕帧截取。对照图按同一像素比例裁切，完整截图保留界面、血条和战斗信息。

| 剧情入口 | 对照与全屏证据 |
|---|---|
| 伪旗哨站 · 与伪旗统领交谈 | [突袭手动作](../../reports/story_squads_20261121/outpost-actions.png) · [战前对白](../../reports/story_squads_20261121/facing5/outpost/story.png) · [胜利结算](../../reports/story_squads_20261121/facing5/outpost/victory.png) · [实测日志](../../reports/story_squads_20261121/facing5.log) |
| 雾林 · 与截盟使交谈 | [雾林双敌动作](../../reports/story_squads_20261121/woods-actions.png) · [战前对白](../../reports/story_squads_20261121/facing8/woods/story.png) · [胜利结算](../../reports/story_squads_20261121/facing8/woods/victory.png) · [第八章两战连续日志](../../reports/story_squads_20261121/facing8.log) |
| 机关廊 · 与机关监守交谈 | [机关廊双敌动作](../../reports/story_squads_20261121/gallery-actions.png) · [战前对白](../../reports/story_squads_20261121/facing8/gallery/story.png) · [胜利结算](../../reports/story_squads_20261121/facing8/gallery/victory.png) · [机关廊战前存档](../../reports/story_squads_20261121/facing8/gallery_entry.json) |

[余项名单、优先级与全量核查](../audits/story-squad-remaining-20261121.md)

