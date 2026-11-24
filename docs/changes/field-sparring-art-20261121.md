# 五名切磋对手的战斗动作

洛阳巡捕、府衙都头、古峰试炼者、凌月守山人和流浪刀客各有 16 个战斗姿态。原来五人共用的战斗读图分支已移除，角色在备战、移动、普通攻击、武功、受击与落败时均使用自己的图集。制作时以主角为画风参照，以地图人物核对服色和装束。巡捕使用直剑，都头使用金装具腰刀，凌月守山人用木棍。人物受击时仍站立，落败时屈膝、侧卧收势。

## PC 切磋实测

读取既有存档的隔离副本。洛阳队伍从码头走到府衙街区，再步行找市街巡捕和府衙都头。考校场使用另一份存档，从武林会场查验伤口、令牌和纸条，与大会执事核对线索后走进考校场。五人在战场上的普通攻击及本门武功均经游戏 AI 选择。凌月守山人一路上遇到两名陪练，打完这场路遇战后继续前往邀战。每名对手都经过地图交互、「请赐教」和切磋确认。战斗图从 PC 客户端已绘制的 1600×900 画面截取。

| 切磋对手 | 实战可见待机身高¹ | 武功动作 | 邀战与结算 |
|---|---:|---|---|
| 洛阳巡捕 | 203 | 华山一剑，弓步直刺 | [邀战](../../reports/field_sparring_art_20261121/market/luoyang_patrol/invitation.png) · [胜局](../../reports/field_sparring_art_20261121/market/luoyang_patrol/victory.png) |
| 洛阳府衙都头 | 214 | 重斩，双手发力横刀扫出 | [邀战](../../reports/field_sparring_art_20261121/live/boss_luoyang_captain/invitation.png) · [胜局](../../reports/field_sparring_art_20261121/live/boss_luoyang_captain/victory.png) |
| 古峰试炼者 | 207 | 开山一刀，举刀踏步下劈 | [邀战](../../reports/field_sparring_art_20261121/live/gufeng_trainee/invitation.png) · [胜局](../../reports/field_sparring_art_20261121/live/gufeng_trainee/victory.png) |
| 凌月守山人 | 201 | 凌月点星棍，换步用棍梢点出 | [邀战](../../reports/field_sparring_art_20261121/live/lingyue_guard/invitation.png) · [胜局](../../reports/field_sparring_art_20261121/live/lingyue_guard/victory.png) |
| 流浪刀客 | 209 | 开山一刀由高向下，伏虎沉身低斩 | [邀战](../../reports/field_sparring_art_20261121/wulin/wandering_blademaster/invitation.png) · [胜局](../../reports/field_sparring_art_20261121/wulin/wandering_blademaster/victory.png) |

¹ 单人切磋阵型下待机首帧透明外框的游戏坐标像素。地图尺寸与战斗画面采用各自的缩放。

[洛阳实战对照](../../reports/field_sparring_art_20261121/luoyang-actions.png) · [考校场实战对照](../../reports/field_sparring_art_20261121/trial-actions.png) · [制作原图](../../reports/field_sparring_art_20261121/originals/) · [制作提示词](../../reports/field_sparring_art_20261121/prompts.txt)

引擎重新加载了 122 份敌方定义及 6 名可招募队友，五人的各状态均取到战斗帧。此前盘点出的五份地图待机替代已全部消除。[全量复核](../../reports/field_sparring_art_20261121/current/result.json)

洛阳巡捕沿街区从府衙侧走到市街，与他切磋后返回市街原地；流浪刀客的两种刀法均在考校场同场胜局中实拍。[巡捕](../../reports/field_sparring_art_20261121/market_patrol.log) · [都头](../../reports/field_sparring_art_20261121/boss_luoyang_captain.log) · [古峰](../../reports/field_sparring_art_20261121/gufeng_trainee.log) · [凌月](../../reports/field_sparring_art_20261121/lingyue_guard_retry.log) · [刀客](../../reports/field_sparring_art_20261121/wulin.log)
