# 第七章封渡与内署战斗动作

| 敌人 | 近战与暗器 |
|---|---|
| 烈云强硬派巡守 | 甲衣、宽刃刀。普攻平挥，「重斩」举刀过顶再下劈，另一手可以发单针。 |
| 烈云封渡寻迹手 | 斗笠、短刀和镖囊。近身压低出刀，「血影散星」扬腕放出三枚红缨镖，「毒针」沿腕线平射。 |
| 茗雾内署护档使 | 窄剑使「雾隐三式」，袖内藏针。单发毒针与两袖同时放出的「封针散手」各有动作。 |
| 茗雾焚令手 | 兜帽短袍，腰佩火筒，贴身用短刃。侧身撒镖会展开红缨扇面，发毒针时则收紧手肘。 |

四人分别有待机、移步、普攻、受击、跪倒和伏地动作。战场显示按主角比例标定，四人的标定待机身高依表序为 213、204、211、202 像素。六十八姿逐一在正式角色节点上检查左右两向，共 136 项。[动作原帧](../../reports/ch7_ferry_office_20261122/frames.png) · [引擎读出的武功映射](../../reports/ch7_ferry_office_20261122/audit/skills.json) · [朝向记录](../../reports/ch7_ferry_office_20261122/facing.log)

护档使蓄势时将两扇银针交叉扣在胸前，这个姿势随战场预警一直留到玩家作出应对。受击会先后仰，仍在蓄势时再收回扣针姿。打断会恢复普通待机。正常放招时他压身、双手向前撒针，随后归位。单独用正式角色节点检查了蓄势期间受击、解除蓄势和一次出手只触发一次命中信号。[蓄势动作检查](../../reports/ch7_ferry_office_20261122/windup.log)


## 同一存档的 PC 实战

沿用上一轮第六章白水旧路结算后的 18 级存档副本。从客栈结算进入第七章，查两处外线、转运账和封渡名册后，在烈云分舵留下 19 级战前档。此后在同一个 PC 游戏进程、同一存档槽从两句证词一路追到私印底令。护证选择「分开转移」，沿途用地图出口、对话和线索推进，保留正常野外遭遇。[存档到达封渡的记录](../../reports/ch7_ferry_office_20261122/stage.log) · [全程试玩日志](../../reports/ch7_ferry_office_20261122/story.log)

| 剧情战 | 实机证据 |
|---|---|
| 烈云封渡。巡守对话开战，击败两敌，回分舵见改革派引路人 | [开战](../../reports/ch7_ferry_office_20261122/story/ferry/story.png) · [动作对比](../../reports/ch7_ferry_office_20261122/ferry-actions.png) · [重斩归位全屏](../../reports/ch7_ferry_office_20261122/story/ferry/patrol_return_heavy.png) · [胜利](../../reports/ch7_ferry_office_20261122/story/ferry/victory.png) |
| 内署毁档。经内院证词、注销册、夜航转运时间、旧教习和内署底卷，护证后回审验室对话开战。胜利返场取到苏雾笙私印底令，原槽 23 级 | [开战](../../reports/ch7_ferry_office_20261122/story/office/story.png) · [动作对比](../../reports/ch7_ferry_office_20261122/office-actions.png) · [封针散手全过程](../../reports/ch7_ferry_office_20261122/seal-actions.png) · [带预警的全屏蓄势](../../reports/ch7_ferry_office_20261122/story/office/keeper_charge_held.png) · [胜利](../../reports/ch7_ferry_office_20261122/story/office/victory.png) |

两场均从场内 NPC 对话进入并由正常胜利结算返回。截图取自 Windows PC 工程客户端的 1600×900 游戏画面。归位捕获要求同一敌人打出该招、进入待机且与原阵位的距离小于 3 个游戏坐标单位。四人各自普攻与九套武功的出手、归位均朝向我方。近战时的队友和血条遮挡保留。