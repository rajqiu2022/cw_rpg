# 第六章地下档库与白水旧路战斗动作

地下档库的焚册客持短剑，跨步使「茗雾扫风」，另一手发单枚毒针。白水旧路的截证客以弯刀连使「雾隐三式」，也会出袖针；寻迹者压低身体以短剑扫地，「血影散星」则同时发出三枚红缨镖。三人按主角的战斗比例绘制，各用 16 姿。受击时双脚着地、上身后仰，落败时先跪倒再伏地。[无界面遮挡的动作原帧](../../reports/ch6_mingwu_20261122/sprite-details.png)

实打中发现「茗雾扫风」的穿身突进只在指定旧招式上播放接触动作。现有专属出招帧的穿身技能会在接敌时完整播放，下半程再穿过目标。命中信号沿用出招中帧，每次穿身只触发一次。[战斗动作实现](../../game/scripts/battle/battle_actor.gd) · [两场六套武功映射](../../reports/ch6_mingwu_20261122/audit/skills.json)

## 同槽剧情实打

Windows PC 工程客户端从既有第五章伪旗统领战前档的隔离副本起步，击败统领，经章节结算、林西正屋的押送便笺和兵器架到地下档库，留下 17 级战前档。两张对比图都取自随后同一趟连续试玩。队伍用原有招式、架势和治疗，留足回合让敌方自行选招。两次开战均由现场对话触发。[第五章原档](../../reports/ch5_ch8_rebalance_20261120/captain_before.json) · [档库战前存档](../../reports/ch6_mingwu_20261122/late_campaign_stage/profile/roaming/Godot/app_userdata/云影侠传/save_0.json) · [到达档库记录](../../reports/ch6_mingwu_20261122/stage.log)

| 剧情路线 | 实战和交接 |
|---|---|
| 地下档库对话开战，击败两敌，胜利返场后查原册与涂改记录 | [开战对白](../../reports/ch6_mingwu_20261122/patrol/archive/story.png) · [焚册客动作](../../reports/ch6_mingwu_20261122/archive-actions.png) · [扫风归位全屏](../../reports/ch6_mingwu_20261122/patrol/archive/burner_return_sweep.png) · [胜利结算](../../reports/ch6_mingwu_20261122/patrol/archive/victory.png) |
| 回林西问师父，经档库去白水旧路，查里程碑和车辙，对话接战；胜利后回到旧路，同槽存为 18 级 | [开战对白](../../reports/ch6_mingwu_20261122/patrol/road/story.png) · [双敌动作](../../reports/ch6_mingwu_20261122/road-actions.png) · [截证客刀招归位](../../reports/ch6_mingwu_20261122/patrol/road/pursuer_return_mist.png) · [寻迹者散镖归位](../../reports/ch6_mingwu_20261122/patrol/road/tracker_return_darts.png) · [胜利结算](../../reports/ch6_mingwu_20261122/patrol/road/victory.png) |

图中每格均从 1600×900 游戏画面原比例裁切，保留战场上的血条、数字和遮挡。同一敌人完成普通攻击及两门武功后，镜头分别拍到其回到原阵位、恢复待机且面向玩家。捕获归位要求位置误差小于 3 个游戏坐标单位。另用正式角色节点检查 48 张帧的左右显示，共 96 项。两趟独立 PC 复跑都从同一档库检查点连续获胜。日志保留了原有场景来源校验及退出时的资源释放提示，本轮范围为 PC 工程客户端。[截图所用完整日志](../../reports/ch6_mingwu_20261122/patrol.log) · [另一趟同档复跑](../../reports/ch6_mingwu_20261122/final.log) · [双向检查](../../reports/ch6_mingwu_20261122/verify_facing.log)
