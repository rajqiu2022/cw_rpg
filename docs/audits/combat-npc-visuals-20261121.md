# 可战斗角色的身高、画风与动作核查

2026-11-21，PC 开发版。通过正式战斗控制器逐个加载 122 份敌方定义（含动物和兼容条目），同时读取 6 名可招募队友的战斗配置。检查待机、移动、出招、受击、落败五种状态，按实际贴图像素去重，再对照造型图。竹尾三人在桌面客户端分别从武馆对话发起切磋，其余条目采用资源核查。

补测更新：第五章伪旗统领、第八章茗雾假令传使及护令客已换装专属武功动作，三人均实测至胜利结算。下表保留首次全量检查的时间点。[这三人的后续修复与实战截图](../changes/story-enemy-art-20261121.md)

五名以地图待机代替战斗动作的切磋 NPC 现已接入独立图集。逐人截图及武功对应关系见[五名切磋对手实测](../changes/field-sparring-art-20261121.md)。

本次续查已修第五章突袭手和第八章雾林、机关廊四人。当前动作缺失、受击与落败同图及通用散兵三类见[最新余项名单](story-squad-remaining-20261121.md)。

## 竹尾武馆实战

| 对手 | 原待机高度 | 改后实战待机首帧 | 实战动作 |
|---|---:|---:|---|
| 河滩练家子（战斗名「晨市练家子」） | 276 px | 205 px | 2 帧备战、2 帧步法、4 帧出招、4 帧受击、4 帧认输 |
| 游馆师兄 | 289 px | 208 px | 同上，青衫徒手出拳 |
| 沈家护院总管 | 291 px | 218 px | 同上，深色护院服，保留略魁梧的身形 |

原高度按正式单人阵型测算，改后取实际战斗可见矩形，均为游戏设计坐标。护院在第二章比武剧情中另有一份战斗定义，已共用武馆这套动作。林西乡勇教头也恢复了被地图待机覆盖的长兵器动作。罗望、何平入队后分别使用与交手时一致的刀、棍动作。

[游馆师兄待机](../../reports/combat_npcs_20261121/senior_guard_a.png) · [出拳](../../reports/combat_npcs_20261121/senior_strike.png) · [受击](../../reports/combat_npcs_20261121/senior_recoil.png) · [认输](../../reports/combat_npcs_20261121/senior_down.png) · [武馆三套原生角色图](../../reports/combat_npcs_20261121/originals/) · [制作提示词](../../reports/combat_npcs_20261121/prompts.txt)

## 全量检查结果

- 以单人阵型待机首帧超过 245 px 筛查身高异常，45 份人形配置已全部落回筛查线内。洞穴头狼保留较大的野兽体型。多人阵型会等比缩放双方。
- 缺少专门出招或受击帧的配置从 50 份降到 30 份。其中 5 人进战后还在使用地图待机，其余集中在蒙面客系列。第八章祭台的茗雾假令传使、茗雾护令客都在内。现有引擎仍表现冲近、位移或击退。
- 另有 9 份的受击图与落败图像素相同，包括第五章伪旗统领。17 份使用通用散兵动作。部分旧定义与正式章节敌人同名，第八章实际交战的苏雾笙、薛影都有独立四帧出招和四帧受击。
- 图版按每人统一缩略展示待机、出招、受击；缩略图用于辨认姿态与画风，身高以表中数值为准。场景入口列只列一处可查的静态引用；动态路由和兼容条目一起纳入核查。

[图版一](../../reports/combat_npcs_20261121/after/contacts0.jpg) · [图版二](../../reports/combat_npcs_20261121/after/contacts32.jpg) · [图版三](../../reports/combat_npcs_20261121/after/contacts64.jpg) · [图版四](../../reports/combat_npcs_20261121/after/contacts96.jpg) · [实际加载与逐帧摘要](../../reports/combat_npcs_20261121/after/result.json)

## 逐人明细

动作数字按待机／移动／出招／受击／落败排列，每项为实际加载帧数。数字加括号表示去重后有多少种画面。空状态记为 0。

| 角色与资源 ID | 待机高度 px，改前 → 改后 | 五组帧数 | 本轮处理及待改项 | 一处关联来源 |
|---|---:|---|---|---|
| 古墓守卫 [ancient_tomb_guard](../../game/data/enemies/ancient_tomb_guard.tres) | 170 | 4 / 4 / 4 / 4 / 4 | 写实材质偏重，宜复核 | [encounter_ancient_tomb_guard](../../game/data/dialogs/encounter_ancient_tomb_guard.tres) |
| 竹尾野狗 [bamboo_feral_dog](../../game/data/enemies/bamboo_feral_dog.tres) | 222 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch2_s2_forest_edge](../../game/data/scenes/ch2_s2_forest_edge.tres) |
| 留守山贼 [bandit_cave_guard](../../game/data/enemies/bandit_cave_guard.tres) | 176 | 4 / 4(3) / 4 / 4(2) / 4(3) | 五种状态已取到 | [interior_bandit_cave_guard](../../game/data/dialogs/interior_bandit_cave_guard.tres) |
| 山贼 [bandit_mountain](../../game/data/enemies/bandit_mountain.tres) | 195 | 4(1) / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch1_side_caravan_road_start](../../game/data/dialogs/ch1_side_caravan_road_start.tres) |
| 上古魔将 [boss_ancient_demon](../../game/data/enemies/boss_ancient_demon.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | — |
| 洛阳府衙都头 [boss_luoyang_captain](../../game/data/enemies/boss_luoyang_captain.tres) | 256 → 225 | 4 / 0 / 0 / 0 / 0 | 校正身高；战斗调用地图待机；缺专门出招帧；缺专门受击帧 | [ch4_s1_luoyang_yamen](../../game/data/scenes/ch4_s1_luoyang_yamen.tres) |
| 苏雾笙·千年伪装者 [boss_su_wusheng](../../game/data/enemies/boss_su_wusheng.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | — |
| 薛影·暗影 [boss_xueying](../../game/data/enemies/boss_xueying.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | — |
| 薛影手下 [boss_xueying_agent](../../game/data/enemies/boss_xueying_agent.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | — |
| 赵无忌 [boss_zhao_wuji](../../game/data/enemies/boss_zhao_wuji.tres) | 230 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch1_s3_ruin_boss](../../game/data/dialogs/ch1_s3_ruin_boss.tres) |
| 黑狼韩魁 [bounty_black_wolf](../../game/data/enemies/bounty_black_wolf.tres) | 269 → 203 | 4(1) / 4 / 4 / 4 / 4 | 接回同造型的五组战斗动作 | [bianzhou_black_wolf](../../game/data/bounties/bianzhou_black_wolf.tres) |
| 白额鹿侯七 [bounty_border_deer](../../game/data/enemies/bounty_border_deer.tres) | 278 → 209 | 4 / 4 / 4 / 4 / 4 | 接回同造型的五组战斗动作 | [xiangzhou_white_deer](../../game/data/bounties/xiangzhou_white_deer.tres) |
| 飞索高顺 [bounty_gao_shun](../../game/data/enemies/bounty_gao_shun.tres) | 269 → 196 | 4 / 4 / 4 / 4 / 4 | 接回同造型的五组战斗动作 | [bianzhou_flying_rope](../../game/data/bounties/bianzhou_flying_rope.tres) |
| 墨手温迟 [bounty_ink_hand](../../game/data/enemies/bounty_ink_hand.tres) | 232 | 1 / 0 / 0 / 0 / 0 | 缺专门出招帧；缺专门受击帧 | [jinling_ink_hand](../../game/data/bounties/jinling_ink_hand.tres) |
| 矿豺石九 [bounty_mine_jackal](../../game/data/enemies/bounty_mine_jackal.tres) | 278 → 230 | 4 / 4 / 4 / 4 / 4 | 接回同造型的五组战斗动作 | [xiangzhou_mine_jackal](../../game/data/bounties/xiangzhou_mine_jackal.tres) |
| 赤疤彭六 [bounty_red_scar](../../game/data/enemies/bounty_red_scar.tres) | 270 → 213 | 1 / 0 / 0 / 0 / 0 | 校正身高；缺专门出招帧；缺专门受击帧 | [luoyang_red_scar](../../game/data/bounties/luoyang_red_scar.tres) |
| 盗印客柳三 [bounty_seal_thief](../../game/data/enemies/bounty_seal_thief.tres) | 249 → 213 | 1 / 0 / 0 / 0 / 0 | 校正身高；缺专门出招帧；缺专门受击帧 | [luoyang_seal_thief](../../game/data/bounties/luoyang_seal_thief.tres) |
| 水鬼阮无舟 [bounty_water_ghost](../../game/data/enemies/bounty_water_ghost.tres) | 249 → 213 | 1 / 0 / 0 / 0 / 0 | 校正身高；缺专门出招帧；缺专门受击帧 | [jinling_water_ghost](../../game/data/bounties/jinling_water_ghost.tres) |
| 驿道劫匪 [central_road_raider](../../game/data/enemies/central_road_raider.tres) | 269 → 196 | 4 / 4 / 4 / 4 / 4 | 接回同造型的五组战斗动作 | [openworld_bianzhou_old_post](../../game/data/scenes/openworld_bianzhou_old_post.tres) |
| 黑风探子 [central_road_scout](../../game/data/enemies/central_road_scout.tres) | 270 → 213 | 1 / 0 / 0 / 0 / 0 | 校正身高；缺专门出招帧；缺专门受击帧 | [openworld_bianzhou_old_post](../../game/data/scenes/openworld_bianzhou_old_post.tres) |
| 旧矿洞巡哨 [ch2_mine_sentry](../../game/data/enemies/ch2_mine_sentry.tres) | 175 | 4 / 4 / 4 / 4 / 4 | 蒙面人待机下摆在帧边截断 | [ch2_mine_workshop_sentries](../../game/data/dialogs/ch2_mine_workshop_sentries.tres) |
| 沈家护院总管 [ch2_tournament_guard](../../game/data/enemies/ch2_tournament_guard.tres) | 243 → 218 | 2 / 2 / 4 / 4 / 4 | 与武馆护院共用完整动作 | [ch2_tournament_offer](../../game/data/dialogs/ch2_tournament_offer.tres) |
| 伪旗统领 [ch5_false_banner_captain](../../game/data/enemies/ch5_false_banner_captain.tres) | 280 → 225 | 2(1) / 2(1) / 4 / 2(1) / 2(1) | 校正身高；受击与落败像素相同 | [ch5_false_banner_boss_prebattle](../../game/data/dialogs/ch5_false_banner_boss_prebattle.tres) |
| 伪烈云突袭手 [ch5_false_liuyun_striker](../../game/data/enemies/ch5_false_liuyun_striker.tres) | 208 | 2(1) / 2(1) / 3 / 2(1) / 2(1) | 受击与落败像素相同；受击沿用待机图；蓝衣待机与深色举刀出招衣形有别 | [ch5_false_banner_boss_prebattle](../../game/data/dialogs/ch5_false_banner_boss_prebattle.tres) |
| 矿道灭口人 [ch5_mine_tunnel_hunter](../../game/data/enemies/ch5_mine_tunnel_hunter.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | [ch5_mine_hunter_battle](../../game/data/dialogs/ch5_mine_hunter_battle.tres) |
| 雪路劫粮客 [ch5_relief_road_raider](../../game/data/enemies/ch5_relief_road_raider.tres) | 176 | 4 / 4(3) / 4 / 4(2) / 4(3) | 五种状态已取到 | [ch5_grain_convoy_battle](../../game/data/dialogs/ch5_grain_convoy_battle.tres) |
| 雪岭截路刀客 [ch5_snow_pass_pursuer](../../game/data/enemies/ch5_snow_pass_pursuer.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | [ch5_patrol_post_2](../../game/data/dialogs/ch5_patrol_post_2.tres) |
| 茗雾焚册客 [ch6_archive_burner](../../game/data/enemies/ch6_archive_burner.tres) | 270 → 213 | 2(1) / 2(1) / 3 / 2(1) / 2(1) | 校正身高；受击与落败像素相同；受击沿用待机图；蓝衣待机与深色举刀出招衣形有别 | [ch6_archive_prebattle](../../game/data/dialogs/ch6_archive_prebattle.tres) |
| 茗雾断卷客 [ch6_archive_exit_enforcer](../../game/data/enemies/ch6_archive_exit_enforcer.tres) | 169 | 4 / 4 / 4 / 4 / 4 | 写实材质偏重，宜复核 | [encounter_ch6_archive_exit_enforcer](../../game/data/dialogs/encounter_ch6_archive_exit_enforcer.tres) |
| 茗雾销卷使 [ch6_archive_reclaimer](../../game/data/enemies/ch6_archive_reclaimer.tres) | 192 | 4 / 4 / 4 / 4 / 4 | 蒙面人待机下摆在帧边截断 | [ch6_archive_prebattle](../../game/data/dialogs/ch6_archive_prebattle.tres) |
| 茗雾截证客 [ch6_convoy_pursuer](../../game/data/enemies/ch6_convoy_pursuer.tres) | 232 | 2(1) / 2(1) / 3 / 2(1) / 2(1) | 受击与落败像素相同；受击沿用待机图 | [ch6_baishui_prebattle](../../game/data/dialogs/ch6_baishui_prebattle.tres) |
| 茗雾寻迹者 [ch6_convoy_tracker](../../game/data/enemies/ch6_convoy_tracker.tres) | 270 → 213 | 2(1) / 2(1) / 3 / 2(1) / 2(1) | 校正身高；受击与落败像素相同；受击沿用待机图；蓝衣待机与深色举刀出招衣形有别 | [ch6_baishui_prebattle](../../game/data/dialogs/ch6_baishui_prebattle.tres) |
| 烈云强硬派巡守 [ch7_lieyun_hardliner_guard](../../game/data/enemies/ch7_lieyun_hardliner_guard.tres) | 232 | 2(1) / 2(1) / 3 / 2(1) / 2(1) | 受击与落败像素相同；受击沿用待机图 | [ch7_lieyun_hardliner_prebattle](../../game/data/dialogs/ch7_lieyun_hardliner_prebattle.tres) |
| 烈云封渡寻迹手 [ch7_lieyun_hardliner_tracker](../../game/data/enemies/ch7_lieyun_hardliner_tracker.tres) | 270 → 213 | 2(1) / 2(1) / 3 / 2(1) / 2(1) | 校正身高；受击与落败像素相同；受击沿用待机图；蓝衣待机与深色举刀出招衣形有别 | [ch7_lieyun_hardliner_prebattle](../../game/data/dialogs/ch7_lieyun_hardliner_prebattle.tres) |
| 茗雾焚令手 [ch7_mingwu_order_burner](../../game/data/enemies/ch7_mingwu_order_burner.tres) | 270 → 213 | 1 / 0 / 0 / 0 / 0 | 校正身高；缺专门出招帧；缺专门受击帧 | [ch7_inner_office_destroyers_prebattle](../../game/data/dialogs/ch7_inner_office_destroyers_prebattle.tres) |
| 茗雾内署护档使 [ch7_mingwu_record_guard](../../game/data/enemies/ch7_mingwu_record_guard.tres) | 232 | 1 / 0 / 0 / 0 / 0 | 缺专门出招帧；缺专门受击帧 | [ch7_inner_office_destroyers_prebattle](../../game/data/dialogs/ch7_inner_office_destroyers_prebattle.tres) |
| 茗雾假令传使 [ch8_false_order_courier](../../game/data/enemies/ch8_false_order_courier.tres) | 232 | 1 / 0 / 0 / 0 / 0 | 缺专门出招帧；缺专门受击帧 | [chapter_8_content_plan](../../game/data/chapters/chapter_8_content_plan.tres) |
| 茗雾护令客 [ch8_false_order_escort](../../game/data/enemies/ch8_false_order_escort.tres) | 270 → 213 | 1 / 0 / 0 / 0 / 0 | 校正身高；缺专门出招帧；缺专门受击帧 | [chapter_8_content_plan](../../game/data/chapters/chapter_8_content_plan.tres) |
| 茗雾机关监守 [ch8_mechanism_warden](../../game/data/enemies/ch8_mechanism_warden.tres) | 232 | 1 / 0 / 0 / 0 / 0 | 缺专门出招帧；缺专门受击帧 | [ch8_mechanism_prebattle](../../game/data/dialogs/ch8_mechanism_prebattle.tres) |
| 茗雾雾阀守手 [ch8_mist_valve_keeper](../../game/data/enemies/ch8_mist_valve_keeper.tres) | 270 → 213 | 1 / 0 / 0 / 0 / 0 | 校正身高；缺专门出招帧；缺专门受击帧 | [ch8_mechanism_prebattle](../../game/data/dialogs/ch8_mechanism_prebattle.tres) |
| 茗雾截盟护卫 [ch8_mistwood_blockade_guard](../../game/data/enemies/ch8_mistwood_blockade_guard.tres) | 232 | 1 / 0 / 0 / 0 / 0 | 缺专门出招帧；缺专门受击帧 | [ch8_mistwood_prebattle](../../game/data/dialogs/ch8_mistwood_prebattle.tres) |
| 茗雾点烽手 [ch8_mistwood_signal_burner](../../game/data/enemies/ch8_mistwood_signal_burner.tres) | 270 → 213 | 1 / 0 / 0 / 0 / 0 | 校正身高；缺专门出招帧；缺专门受击帧 | [ch8_mistwood_prebattle](../../game/data/dialogs/ch8_mistwood_prebattle.tres) |
| 苏雾笙·最后一令 [ch8_su_wusheng_final](../../game/data/enemies/ch8_su_wusheng_final.tres) | 172 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch8_su_final_common](../../game/data/dialogs/ch8_su_final_common.tres) |
| 薛影·最后一令 [ch8_xueying_last_guard](../../game/data/enemies/ch8_xueying_last_guard.tres) | 172 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch8_xueying_forced_battle](../../game/data/dialogs/ch8_xueying_forced_battle.tres) |
| 唐行舟 [companion_tang_xingzhou_spar](../../game/data/enemies/companion_tang_xingzhou_spar.tres) | 197 | 4(1) / 4 / 4 / 4 / 4 | 五种状态已取到 | [linxi_companion_tang_xingzhou](../../game/data/dialogs/linxi_companion_tang_xingzhou.tres) |
| 龙脉巨蟒 [dragon_vein_serpent](../../game/data/enemies/dragon_vein_serpent.tres) | 170 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch5_s4_abandoned_mine](../../game/data/scenes/ch5_s4_abandoned_mine.tres) |
| 伪装烈云盟刺客 [fake_liuyun_assassin](../../game/data/enemies/fake_liuyun_assassin.tres) | 170 | 4 / 4 / 4 / 4 / 4 | 写实材质偏重，宜复核 | [ch4_fake_assassin](../../game/data/dialogs/ch4_fake_assassin.tres) |
| 古峰山贼 [gufeng_bandit](../../game/data/enemies/gufeng_bandit.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | — |
| 古峰精英守卫 [gufeng_elite_guard](../../game/data/enemies/gufeng_elite_guard.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | — |
| 古峰雪熊 [gufeng_snow_bear](../../game/data/enemies/gufeng_snow_bear.tres) | 172 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch5_s3_snow_pass](../../game/data/scenes/ch5_s3_snow_pass.tres) |
| 古峰试炼者 [gufeng_trainee](../../game/data/enemies/gufeng_trainee.tres) | 268 → 213 | 4 / 0 / 0 / 0 / 0 | 校正身高；战斗调用地图待机；缺专门出招帧；缺专门受击帧 | [ch3_gufeng_trial](../../game/data/dialogs/ch3_gufeng_trial.tres) |
| 芦林斑虎 [jinling_reed_tiger](../../game/data/enemies/jinling_reed_tiger.tres) | 156 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [openworld_jinling_reed_marsh](../../game/data/scenes/openworld_jinling_reed_marsh.tres) |
| 凌月山守卫 [lingyue_guard](../../game/data/enemies/lingyue_guard.tres) | 230 | 4 / 0 / 0 / 0 / 0 | 战斗调用地图待机；缺专门出招帧；缺专门受击帧 | [ch3_lingyue_trial](../../game/data/dialogs/ch3_lingyue_trial.tres) |
| 武馆陪练弟子 [linxi_dojo_disciple](../../game/data/enemies/linxi_dojo_disciple.tres) | 209 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch1_martial_hall_master](../../game/data/dialogs/ch1_martial_hall_master.tres) |
| 武馆高阶弟子 [linxi_dojo_senior](../../game/data/enemies/linxi_dojo_senior.tres) | 207 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch1_martial_hall_master](../../game/data/dialogs/ch1_martial_hall_master.tres) |
| 林西乡勇教头 [linxi_south_militia_coach](../../game/data/enemies/linxi_south_militia_coach.tres) | 266 → 207 | 4 / 4 / 4 / 4 / 4 | 恢复长兵器战斗动作 | [linxi_village_scrollmap](../../game/data/scenes/linxi_village_scrollmap.tres) |
| 林西村外凶兽 [linxi_wild_beast](../../game/data/enemies/linxi_wild_beast.tres) | 172 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch1_forest_beast_pack_encounter](../../game/data/dialogs/ch1_forest_beast_pack_encounter.tres) |
| 烈云破阵校尉 [liuyun_elite](../../game/data/enemies/liuyun_elite.tres) | 171 | 4 / 4 / 4 / 4 / 4 | 写实材质偏重，宜复核 | [encounter_liuyun_elite](../../game/data/dialogs/encounter_liuyun_elite.tres) |
| 烈云盟守卫 [liuyun_guard](../../game/data/enemies/liuyun_guard.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | — |
| 洛阳巡捕 [luoyang_patrol](../../game/data/enemies/luoyang_patrol.tres) | 243 | 4 / 0 / 0 / 0 / 0 | 战斗调用地图待机；缺专门出招帧；缺专门受击帧 | [ch4_s1_luoyang_yamen](../../game/data/scenes/ch4_s1_luoyang_yamen.tres) |
| 洛阳地痞 [luoyang_thug](../../game/data/enemies/luoyang_thug.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | [ch4_canal_battle](../../game/data/dialogs/ch4_canal_battle.tres) |
| 蒙面杀手首领 [masked_killer_ambush](../../game/data/enemies/masked_killer_ambush.tres) | 192 | 4 / 4 / 4 / 4 / 4 | 蒙面人待机下摆在帧边截断 | [ch1_forest_yuewuxing](../../game/data/dialogs/ch1_forest_yuewuxing.tres) |
| 蒙面杀手精英 [masked_killer_elite](../../game/data/enemies/masked_killer_elite.tres) | 270 → 213 | 1 / 0 / 3 / 0 / 0 | 校正身高；缺专门受击帧；蓝衣待机与深色举刀出招衣形有别 | [ch2_rescue_yue_intro](../../game/data/dialogs/ch2_rescue_yue_intro.tres) |
| 蒙面杀手首领 [masked_killer_leader](../../game/data/enemies/masked_killer_leader.tres) | 249 → 225 | 1 / 0 / 3 / 1 / 0 | 校正身高 | [scene_script](../../game/scripts/domain/scene_script.gd) |
| 蒙面杀手 [masked_killer_minion](../../game/data/enemies/masked_killer_minion.tres) | 259 → 213 | 1 / 0 / 0 / 0 / 0 | 校正身高；缺专门出招帧；缺专门受击帧 | [ch2_forest_ambush_intro](../../game/data/dialogs/ch2_forest_ambush_intro.tres) |
| 矿场力士 [mine_brute](../../game/data/enemies/mine_brute.tres) | 278 → 209 | 4 / 4 / 4 / 4 / 4 | 接回同造型的五组战斗动作 | [openworld_v15_forest_outskirts](../../game/data/scenes/openworld_v15_forest_outskirts.tres) |
| 矿谷悍匪 [mine_outlaw](../../game/data/enemies/mine_outlaw.tres) | 269 → 203 | 4(1) / 4 / 4 / 4 / 4 | 接回同造型的五组战斗动作 | [openworld_v15_forest_outskirts](../../game/data/scenes/openworld_v15_forest_outskirts.tres) |
| 茗雾暗卫 [mingwu_dark_guard](../../game/data/enemies/mingwu_dark_guard.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | — |
| 茗雾封针使 [mingwu_elite_guard](../../game/data/enemies/mingwu_elite_guard.tres) | 170 | 4 / 4 / 4 / 4 / 4 | 写实材质偏重，宜复核 | [encounter_mingwu_elite_guard](../../game/data/dialogs/encounter_mingwu_elite_guard.tres) |
| 茗雾渗透者 [mingwu_infiltrator](../../game/data/enemies/mingwu_infiltrator.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | [ch3_tomb_battle](../../game/data/dialogs/ch3_tomb_battle.tres) |
| 茗雾外围守卫 [mingwu_outer_guard](../../game/data/enemies/mingwu_outer_guard.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | — |
| 茗雾暗哨 [mingwu_shadow](../../game/data/enemies/mingwu_shadow.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | [ch3_mingwu_trial](../../game/data/dialogs/ch3_mingwu_trial.tres) |
| 茗雾围困兵 [mingwu_siege_guard](../../game/data/enemies/mingwu_siege_guard.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | — |
| 茗雾密探 [mingwu_spy](../../game/data/enemies/mingwu_spy.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | [ch3_tomb_battle](../../game/data/dialogs/ch3_tomb_battle.tres) |
| 山寨大王 [mountain_bandit_king](../../game/data/enemies/mountain_bandit_king.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 通用散兵造型 | — |
| 关外刀匪 [openworld_snow_raider](../../game/data/enemies/openworld_snow_raider.tres) | 178 | 4 / 4(3) / 4 / 4(2) / 4(3) | 五种状态已取到 | [openworld_yanmen_cave_guard](../../game/data/dialogs/openworld_yanmen_cave_guard.tres) |
| 寒岭守藏人 [openworld_yanmen_cave_guard](../../game/data/enemies/openworld_yanmen_cave_guard.tres) | 179 | 4 / 4(3) / 4 / 4(2) / 4(3) | 五种状态已取到 | [openworld_yanmen_cave_guard](../../game/data/dialogs/openworld_yanmen_cave_guard.tres) |
| 水泽刺客 [reed_assassin](../../game/data/enemies/reed_assassin.tres) | 270 → 213 | 1 / 0 / 0 / 0 / 0 | 校正身高；缺专门出招帧；缺专门受击帧 | [openworld_jinling_reed_marsh](../../game/data/scenes/openworld_jinling_reed_marsh.tres) |
| 芦荡私枭 [reed_smuggler](../../game/data/enemies/reed_smuggler.tres) | 249 → 213 | 1 / 0 / 0 / 0 / 0 | 校正身高；缺专门出招帧；缺专门受击帧 | [openworld_jinling_reed_marsh](../../game/data/scenes/openworld_jinling_reed_marsh.tres) |
| 古寺埋伏兵 [temple_ambusher](../../game/data/enemies/temple_ambusher.tres) | 236 | 1 / 1 / 3(2) / 1 / 2 | 五种状态已取到 | [ch4_temple_ambush](../../game/data/dialogs/ch4_temple_ambush.tres) |
| 江湖散兵 [thug_lone](../../game/data/enemies/thug_lone.tres) | 196 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch1_corpse_examine](../../game/data/dialogs/ch1_corpse_examine.tres) |
| 山岭壮狼 [training_wolf_mountain_lv7](../../game/data/enemies/training_wolf_mountain_lv7.tres) | 172 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [openworld_yanmen_pass](../../game/data/scenes/openworld_yanmen_pass.tres) |
| 山林群狼 [training_wolf_pack_lv4](../../game/data/enemies/training_wolf_pack_lv4.tres) | 172 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [wild_training_candidates_20261012](../../game/data/config/wild_training_candidates_20261012.json) |
| 雪岭山狼 [training_wolf_snowridge_lv15](../../game/data/enemies/training_wolf_snowridge_lv15.tres) | 172 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [wild_training_candidates_20261012](../../game/data/config/wild_training_candidates_20261012.json) |
| 山林幼狼 [training_wolf_young_lv2](../../game/data/enemies/training_wolf_young_lv2.tres) | 172 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [wild_training_candidates_20261012](../../game/data/config/wild_training_candidates_20261012.json) |
| 流浪刀客 [wandering_blademaster](../../game/data/enemies/wandering_blademaster.tres) | 230 | 4 / 0 / 0 / 0 / 0 | 战斗调用地图待机；缺专门出招帧；缺专门受击帧 | [ch3_s2_trial_ground](../../game/data/scenes/ch3_s2_trial_ground.tres) |
| 游盗温七 [warrant_bianzhou_roaming_thief](../../game/data/enemies/warrant_bianzhou_roaming_thief.tres) | 269 → 196 | 4 / 4 / 4 / 4 / 4 | 接回同造型的五组战斗动作 | [bianzhou_roaming_thief](../../game/data/bounties/bianzhou_roaming_thief.tres) |
| 短镖罗望 [warrant_escort_luo](../../game/data/enemies/warrant_escort_luo.tres) | 269 → 196 | 4 / 4 / 4 / 4 / 4 | 接回同造型的五组战斗动作 | [jinling_wronged_escort](../../game/data/bounties/jinling_wronged_escort.tres) |
| 石渡何平 [warrant_ferryman_hei](../../game/data/enemies/warrant_ferryman_hei.tres) | 278 → 209 | 4 / 4 / 4 / 4 / 4 | 接回同造型的五组战斗动作 | [bianzhou_wronged_ferryman](../../game/data/bounties/bianzhou_wronged_ferryman.tres) |
| 夜鹞梁九 [warrant_jinling_night_kite](../../game/data/enemies/warrant_jinling_night_kite.tres) | 232 | 1 / 0 / 0 / 0 / 0 | 缺专门出招帧；缺专门受击帧 | [jinling_night_kite](../../game/data/bounties/jinling_night_kite.tres) |
| 断指裴安 [warrant_luoyang_case_robber](../../game/data/enemies/warrant_luoyang_case_robber.tres) | 270 → 213 | 1 / 0 / 0 / 0 / 0 | 校正身高；缺专门出招帧；缺专门受击帧 | [luoyang_case_robber](../../game/data/bounties/luoyang_case_robber.tres) |
| 灰手马敬 [warrant_qinghe_coal_robber](../../game/data/enemies/warrant_qinghe_coal_robber.tres) | 278 → 209 | 4 / 4 / 4 / 4 / 4 | 接回同造型的五组战斗动作 | [qinghe_coal_robber](../../game/data/bounties/qinghe_coal_robber.tres) |
| 翻舟许五 [warrant_qinghe_quay_thief](../../game/data/enemies/warrant_qinghe_quay_thief.tres) | 269 → 196 | 4 / 4 / 4 / 4 / 4 | 接回同造型的五组战斗动作 | [qinghe_quay_thief](../../game/data/bounties/qinghe_quay_thief.tres) |
| 割囊宋八 [warrant_redrock_caravan_cutpurse](../../game/data/enemies/warrant_redrock_caravan_cutpurse.tres) | 269 → 196 | 4 / 4 / 4 / 4 / 4 | 接回同造型的五组战斗动作 | [redrock_caravan_cutpurse](../../game/data/bounties/redrock_caravan_cutpurse.tres) |
| 破封卢循 [warrant_redrock_false_courier](../../game/data/enemies/warrant_redrock_false_courier.tres) | 269 → 196 | 4 / 4 / 4 / 4 / 4 | 接回同造型的五组战斗动作 | [redrock_false_courier](../../game/data/bounties/redrock_false_courier.tres) |
| 铁算盘任敖 [warrant_xiangzhou_mine_stamp](../../game/data/enemies/warrant_xiangzhou_mine_stamp.tres) | 278 → 230 | 4 / 4 / 4 / 4 / 4 | 接回同造型的五组战斗动作 | [xiangzhou_mine_stamp](../../game/data/bounties/xiangzhou_mine_stamp.tres) |
| 沙地野狗 [western_feral_dog](../../game/data/enemies/western_feral_dog.tres) | 222 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [adventure_config](../../game/data/maps/adventure_20261030k/adventure_config.json) |
| 沙狐 [western_sand_fox](../../game/data/enemies/western_sand_fox.tres) | 200 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [adventure_config](../../game/data/maps/adventure_20261030k/adventure_config.json) |
| 白水截证首领 [wild_elite_convoy](../../game/data/enemies/wild_elite_convoy.tres) | 232 | 2(1) / 2(1) / 3 / 2(1) / 2(1) | 受击与落败像素相同；受击沿用待机图 | [ch6_s4_baishui_convoy_route](../../game/data/scenes/ch6_s4_baishui_convoy_route.tres) |
| 机关廊精锐监守 [wild_elite_gallery](../../game/data/enemies/wild_elite_gallery.tres) | 232 | 1 / 0 / 0 / 0 / 0 | 缺专门出招帧；缺专门受击帧 | [ch8_s4_alliance_mechanism_gallery](../../game/data/scenes/ch8_s4_alliance_mechanism_gallery.tres) |
| 矿道伏杀头目 [wild_elite_hunter](../../game/data/enemies/wild_elite_hunter.tres) | 178 | 4 / 4(3) / 4 / 4(2) / 4(3) | 五种状态已取到 | [ch5_s4_abandoned_mine](../../game/data/scenes/ch5_s4_abandoned_mine.tres) |
| 烈云封渡队正 [wild_elite_lieyun](../../game/data/enemies/wild_elite_lieyun.tres) | 232 | 2(1) / 2(1) / 3 / 2(1) / 2(1) | 受击与落败像素相同；受击沿用待机图 | [ch7_s3_lieyun_outpost_outer_ward](../../game/data/scenes/ch7_s3_lieyun_outpost_outer_ward.tres) |
| 芦荡私船首领 [wild_elite_marsh](../../game/data/enemies/wild_elite_marsh.tres) | 270 → 213 | 1 / 0 / 0 / 0 / 0 | 校正身高；缺专门出招帧；缺专门受击帧 | [openworld_jinling_reed_marsh](../../game/data/scenes/openworld_jinling_reed_marsh.tres) |
| 矿谷刀匪头目 [wild_elite_mine](../../game/data/enemies/wild_elite_mine.tres) | 278 → 209 | 4 / 4 / 4 / 4 / 4 | 接回同造型的五组战斗动作 | [openworld_v15_forest_outskirts](../../game/data/scenes/openworld_v15_forest_outskirts.tres) |
| 茗雾截盟统领 [wild_elite_mistwood](../../game/data/enemies/wild_elite_mistwood.tres) | 232 | 1 / 0 / 0 / 0 / 0 | 缺专门出招帧；缺专门受击帧 | [ch8_s2_mistwood_blockade](../../game/data/scenes/ch8_s2_mistwood_blockade.tres) |
| 黑风游哨首领 [wild_elite_post](../../game/data/enemies/wild_elite_post.tres) | 270 → 213 | 1 / 0 / 0 / 0 / 0 | 校正身高；缺专门出招帧；缺专门受击帧 | [openworld_bianzhou_old_post](../../game/data/scenes/openworld_bianzhou_old_post.tres) |
| 拦路刀头 [wild_elite_road](../../game/data/enemies/wild_elite_road.tres) | 195 | 4(1) / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch1_s1_road](../../game/data/scenes/ch1_s1_road.tres) |
| 雪岭劫道首领 [wild_elite_snow](../../game/data/enemies/wild_elite_snow.tres) | 176 | 4 / 4(3) / 4 / 4(2) / 4(3) | 五种状态已取到 | [ch5_s1_relief_road](../../game/data/scenes/ch5_s1_relief_road.tres) |
| 古寺截路头目 [wild_elite_temple](../../game/data/enemies/wild_elite_temple.tres) | 270 → 213 | 1 / 0 / 0 / 0 / 0 | 校正身高；缺专门出招帧；缺专门受击帧 | [ch4_s5_temple_tunnel](../../game/data/scenes/ch4_s5_temple_tunnel.tres) |
| 西域雄狮 [wild_elite_western_lion](../../game/data/enemies/wild_elite_western_lion.tres) | 240 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [adventure_config](../../game/data/maps/adventure_20261030k/adventure_config.json) |
| 竹尾头狼 [wild_elite_wolf](../../game/data/enemies/wild_elite_wolf.tres) | 173 | 3 / 2 / 3 / 2 / 3 | 五种状态已取到 | [ch1_s3_zhuwei_forest](../../game/data/scenes/ch1_s3_zhuwei_forest.tres) |
| 雁门雪匪首领 [wild_elite_yanmen](../../game/data/enemies/wild_elite_yanmen.tres) | 178 | 4 / 4(3) / 4 / 4(2) / 4(3) | 五种状态已取到 | [openworld_yanmen_pass](../../game/data/scenes/openworld_yanmen_pass.tres) |
| 北林蒙面哨长 [wild_elite_zhuwei](../../game/data/enemies/wild_elite_zhuwei.tres) | 259 → 213 | 1 / 0 / 0 / 0 / 0 | 校正身高；缺专门出招帧；缺专门受击帧 | [ch2_s2_forest_edge](../../game/data/scenes/ch2_s2_forest_edge.tres) |
| 武当弟子 [wudang_disciple](../../game/data/enemies/wudang_disciple.tres) | 214 | 1 / 1 / 3(2) / 1 / 2 | 五种状态已取到 | [ch3_wudang_trial](../../game/data/dialogs/ch3_wudang_trial.tres) |
| 武林大会考官 [wulin_examiner](../../game/data/enemies/wulin_examiner.tres) | 210 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch3_huashan_trial](../../game/data/dialogs/ch3_huashan_trial.tres) |
| 寒岭苍鹰 [yanmen_eagle](../../game/data/enemies/yanmen_eagle.tres) | 113 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [openworld_yanmen_pass](../../game/data/scenes/openworld_yanmen_pass.tres) |
| 竹尾村山贼 [zhuwei_bandit](../../game/data/enemies/zhuwei_bandit.tres) | 203 | 4(1) / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch1_s3_outer_guard](../../game/data/dialogs/ch1_s3_outer_guard.tres) |
| 后山洞穴头狼 [zhuwei_cave_wolf](../../game/data/enemies/zhuwei_cave_wolf.tres) | 280 | 4(3) / 2 / 3 / 2 / 3 | 五种状态已取到 | [ch1_zhuwei_cave_wolf_encounter](../../game/data/dialogs/ch1_zhuwei_cave_wolf_encounter.tres) |
| 晨市练家子 [zhuwei_dojo_apprentice](../../game/data/enemies/zhuwei_dojo_apprentice.tres) | 276 → 205 | 2 / 2 / 4 / 4 / 4 | 新绘全套，武馆实战通过 | [ch2_s1_market_training_hall](../../game/data/scenes/ch2_s1_market_training_hall.tres) |
| 沈家护院总管 [zhuwei_dojo_guard](../../game/data/enemies/zhuwei_dojo_guard.tres) | 291 → 218 | 2 / 2 / 4 / 4 / 4 | 新绘全套，武馆实战通过 | [ch2_s1_market_training_hall](../../game/data/scenes/ch2_s1_market_training_hall.tres) |
| 游馆师兄 [zhuwei_dojo_senior](../../game/data/enemies/zhuwei_dojo_senior.tres) | 289 → 208 | 2 / 2 / 4 / 4 / 4 | 新绘全套，武馆实战通过 | [ch2_s1_market_training_hall](../../game/data/scenes/ch2_s1_market_training_hall.tres) |
| 洞穴野狼 [zhuwei_pack_wolf](../../game/data/enemies/zhuwei_pack_wolf.tres) | 172 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch1_forest_beast_pack_encounter](../../game/data/dialogs/ch1_forest_beast_pack_encounter.tres) |
| 段长风（队友） [duan_changfeng](../../game/data/companions/duan_changfeng.tres) | 209 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [openworld_bailu_ferry](../../game/data/scenes/openworld_bailu_ferry.tres) |
| 沈青禾（队友） [shen_qinghe](../../game/data/companions/shen_qinghe.tres) | 209 | 4(1) / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch5_disclosure_choice](../../game/data/dialogs/ch5_disclosure_choice.tres) |
| 唐行舟（队友） [tang_xingzhou](../../game/data/companions/tang_xingzhou.tres) | 197 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch5_disclosure_choice](../../game/data/dialogs/ch5_disclosure_choice.tres) |
| 罗望（队友） [warrant_escort_luo](../../game/data/companions/warrant_escort_luo.tres) | 359 → 196 | 4 / 4 / 4 / 4 / 4 | 队友与交手时沿用同一套刀／棍动作 | [jinling_wronged_escort](../../game/data/bounties/jinling_wronged_escort.tres) |
| 何平（队友） [warrant_ferryman_hei](../../game/data/companions/warrant_ferryman_hei.tres) | 224 → 209 | 4 / 4 / 4 / 4 / 4 | 队友与交手时沿用同一套刀／棍动作 | [bianzhou_wronged_ferryman](../../game/data/bounties/bianzhou_wronged_ferryman.tres) |
| 悦无姮（队友） [yuewuheng](../../game/data/companions/yuewuheng.tres) | 229 | 4 / 4 / 4 / 4 / 4 | 五种状态已取到 | [ch2_lingyue_arrival](../../game/data/dialogs/ch2_lingyue_arrival.tres) |

## 验证记录

[练家子切磋](../../reports/npc_shop_return_20261121/spar_apprentice.log) · [游馆师兄切磋](../../reports/npc_shop_return_20261121/spar_senior_final.log) · [护院切磋](../../reports/npc_shop_return_20261121/spar_guard.log) · [改前加载结果](../../reports/combat_npcs_20261121/before/result.json) · [改后加载结果](../../reports/combat_npcs_20261121/after/result.json)

武馆验证使用隔离存档，在武馆以开局战力从邀战对话进入切磋。三场都记录到 16 个姿态，完成胜利结算。三个旧版城市表现与导航模块仍在启动时报告来源校验错误，与改动前日志一致；PC 导出包尚未单独走查。
