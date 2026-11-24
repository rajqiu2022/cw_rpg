# 八章任务交付与奖励核查

按八份章节计划对照 90 个任务 ID，并检查任务目录顶层其余 43 个定义。章节计划外仍有奇遇、替代路线和旧 ID。下表记录静态配置，运行验证集中在本轮改动与奖励共用逻辑。

## 本轮修正

- 竹尾村古道护商、山道清匪、营救丈夫、山寨暗记改为委托人结算。目标达成时记下复命地点。已完成的旧档保持完成状态，重聊只播放后续对白。
- 北林旧道的老猿互动只记调查结果，回竹尾晨市找参农沈伯交付。森林原两个出入口保留原位置与目标。
- 竹尾主街武馆入口接回武馆教头的基础陪练和高阶挑战选项。武馆试剑在训练现场判定胜利。
- 第八章「营里两件小事」等现场任务继续由原完成条件结算。须通过第三方交证的任务，例如失踪弟子的凌月派交证，保留原交付人。
- 洛阳文化任务还通过现有协调器判定正式交付；仅凭静态对白资源无法断定其正式区域可达。

## 桌面验证

- 在竹尾主街使用空格与委托人交谈，检查四个复命分支、金钱与物品到账，以及重聊后的对白。旧完成状态继续阻止重复领奖。[古道护商奖励框](evidence/quest-turn-in-rewards-20261112/quest_reward_caravan.png)
- 通过正式北林旧道调查老猿并从原门返回晨市。调查后任务仍在进行，沈伯交付后发奖，重聊进入事后对白。
- 第八章营地补给两处均完成后自动弹出奖励。隔离背包塞满时验证待入包数量写入任务存档数据，释放空位后自动补发。
- 通过方向键走入山道与洞窟触发区域。山道进入原战斗，洞窟实击败守卫后回到洞窟并读到旗帜线索。战斗验证使用隔离低血量前置。[山道持剑演出](evidence/quest-turn-in-rewards-20261112/road_sword_point.png) · [洞窟开场](evidence/quest-turn-in-rewards-20261112/cave_auto_dialogue.png)
- 两位村民使用独立四帧地图精灵并对应原对话立绘。沿用原配音，新对白暂以文字呈现。[焦急妇人](evidence/quest-turn-in-rewards-20261112/anxious_mother.png) · [卖菜大婶](evidence/quest-turn-in-rewards-20261112/older_vendor.png)

提示框显示任务定义经任务管理器实际发放的奖励。剧情节点单独交付的线索、信物等继续使用既有获取提示。桌面验证使用隔离存档环境，八章未逐战通关，移动发布包未实测。

## 定义与交付入口

“完成事件”中的旗标可能由交付对白设置。表中的对白来自资源引用，旧章节定义和部分脚本入口另由场景或运行时代码选择。

| 范围 | 任务 | 完成事件 | 接取／完成对白 |
| --- | --- | --- | --- |
| 第1章 · 主线 | 领取佩剑 `q_ch1_main_get_sword` | `flag_set:got_sword` | `ch1_tutorial_xingfantian` |
| 第1章 · 主线 | 回禀师傅 `q_ch1_main_return_master` | `flag_set:returned_to_master` | `ch1_road_after_battle`、`ch1_road_return_to_village` |
| 第1章 · 主线 | 启程前往竹尾村 `q_ch1_main_road` | `enemy_defeated:thug_lone` | `ch1_road_enter`、`ch1_road_intro`、`ch1_tutorial_duqingshan` |
| 第1章 · 主线 | 师门授艺 `q_ch1_main_training` | `flag_set:master_training_done` | `ch1_return_to_master`、`ch1_s3_ruin_boss_unprepared`；`ch1_return_to_master` |
| 第1章 · 主线 | 村中异闻 `q_ch1_main_village_inquiry` | `flag_set:zhuwei_village_inquiry_done` | `ch1_s2_guard`、`ch1_s2_intro`、`ch1_zhuwei_arrival`；`ch1_s2_guard_report` |
| 第1章 · 主线 | 雾纹匪踪 `q_ch1_main_west_ruin` | `flag_set:chapter1_complete` | `ch1_s3_ruin_watch_roster`；`ch1_s3_ruin_orders` |
| 第1章 · 主线 | 潜入废宅 `q_ch1_main_west_ruin_trace` | `flag_set:zhao_wuji_identified` | `ch1_zhuwei_cave_clue` |
| 第1章 · 主线 | 前往竹尾村 `q_ch1_main_zhuwei` | `scene_entered:ch1_s2_qingfeng` | `ch1_return_to_master`、`ch1_road_to_zhuwei`；`ch1_forest_yuewuxing_talk`、`ch1_s2_intro`、`ch1_zhuwei_arrival` |
| 第1章 · 主线 | 后山兽踪 `q_ch1_main_zhuwei_wilds` | `flag_set:clue_west_ruin_supply_route` | `ch1_s2_guard_report`；`ch1_zhuwei_cave_clue` |
| 第1章 · 支线 | 营救丈夫 `q_ch1_side_01_rescue_husband` | 显式结算 | `ch1_s2_crying_woman`；`ch1_s2_crying_woman_turnin` |
| 第1章 · 支线 | 悬崖采药 `q_ch1_side_02_cliff_herb` | `flag_set:cliff_herb_delivered` | `linxi_cliff_herb_offer`；`linxi_cliff_herb_turnin` |
| 第1章 · 支线 | 残碑认字 `q_ch1_side_03_stone_inscription` | `flag_set:stone_inscription_deciphered` | `ch1_side_stone_teacher_offer` |
| 第1章 · 支线 | 古道护商 `q_ch1_side_06_caravan_escort` | 显式结算 | `ch1_side_caravan_offer`；`ch1_side_caravan_turnin` |
| 第1章 · 支线 | 山道清匪 `q_ch1_side_08_mountain_patrol` | 显式结算 | `ch1_s2_patrol_scout`；`ch1_s2_patrol_scout_turnin` |
| 第1章 · 支线 | 武馆试剑 `q_ch1_side_09_martial_hall` | `enemy_defeated:linxi_dojo_senior` | `ch1_martial_hall_master` |
| 第1章 · 支线 | 山寨暗记 `q_ch1_side_10_bandit_cave` | 显式结算 | `ch1_s2_bandit_cave_rumour`；`ch1_s2_bandit_cave_turnin` |
| 第1章 · 支线 | 旧账上的云字 `q_ch1_side_11_old_ledger` | `flag_set:linxi_old_ledger_verified` | `linxi_scholar_house_ledger`；`linxi_center_herbalist_ledger_verify` |
| 第1章 · 支线 | 林间止血草 `q_ch1_side_12_forest_medicine` | `flag_set:zhuwei_forest_herb_delivered` | `ch1_s2_vegetable_vendor`；`ch1_s2_vegetable_vendor_turnin` |
| 第2章 · 主线 | 竹尾调查 `q_ch2_main_01_investigate` | `flag_set:heard_about_missing_lingyue` | `ch2_zhuwei_intro` |
| 第2章 · 主线 | 密林援手 `q_ch2_main_02_rescue_yue` | `flag_set:ch2_rescue_complete` | `ch2_forest_route`；`ch2_rescue_victory` |
| 第2章 · 主线 | 追查伪令牌 `q_ch2_main_03_trace_hideout` | `flag_set:ch2_hideout_cleared` | `ch2_hideout_intro`；`ch2_hideout_result` |
| 第2章 · 主线 | 山门复命 `q_ch2_main_04_report_lingyue` | `flag_set:chapter2_complete` | `ch2_hideout_result`；`ch2_lingyue_arrival` |
| 第2章 · 支线 | 失踪弟子 `q_ch2_side_01_missing_disciple` | `flag_set:found_missing_disciple_clue` | `ch2_missing_disciple_offer`；`ch2_missing_disciple_complete` |
| 第2章 · 支线 | 珍珑棋局 `q_ch2_side_02_go_puzzle` | `flag_set:go_puzzle_solved` | `ch2_go_puzzle`；`ch2_go_puzzle` |
| 第2章 · 支线 | 河中女尸案 `q_ch2_side_03_river_death` | `flag_set:river_death_case_solved` | `ch2_river_death_offer` |
| 第2章 · 支线 | 药田黑手 `q_ch2_side_04_herb_thief` | `flag_set:herb_thief_found` | `ch2_herb_thief_offer`；`ch2_herb_thief_complete` |
| 第2章 · 支线 | 竹尾论武 `q_ch2_side_05_martial_tournament` | `flag_set:tournament_won` | `ch2_tournament_offer`；`ch2_tournament_complete` |
| 第2章 · 支线 | 月下琴声 `q_ch2_side_06_moon_guqin` | `flag_set:guqin_mystery_solved` | `ch2_moon_guqin_offer` |
| 第2章 · 支线 | 漕河风波 `q_ch2_side_07_boat_gang` | `flag_set:boat_feud_resolved` | `ch2_boat_gang_offer` |
| 第2章 · 支线 | 无名残卷 `q_secret_canglong_three_pages` | `flag_set:canglong_manual_assembled` | `ch2_canglong_fragment_upper`、`ch3_canglong_fragment_middle`、`ch4_canglong_assemble`、`ch4_luoyang_paper_turnin`、`paper_report`；`ch4_canglong_assemble` |
| 第3章 · 主线 | 大会验案 `q_ch3_main_00_assembly_clues` | `flag_set:assembly_evidence_checked` | `ch3_assembly_intro`；`ch3_assembly_review` |
| 第3章 · 主线 | 江湖道路 `q_ch3_main_01_join_faction` | `flag_set:joined_faction` | `ch3_assembly_review`；`ch3_luoyang_dispatch` |
| 第3章 · 主线 | 同门合练 `q_ch3_main_02_faction_training` | `flag_set:ch3_training_complete` | `ch3_luoyang_dispatch`；`ch3_training_result` |
| 第3章 · 主线 | 禁地雾纹 `q_ch3_main_03_token_conspiracy` | `flag_set:chapter3_complete` | `ch3_training_result`；`ch3_tomb_result` |
| 第3章 · 支线 | 古琴遗谱 `q_ch3_side_01_guqin_manual` | `flag_set:guqin_manual_translated` | `ch3_guqin_side`；`ch3_guqin_side` |
| 第3章 · 支线 | 残局对弈 `q_ch3_side_02_weiqi_match` | `flag_set:weiqi_trick_solved` | `ch3_weiqi_side`；`ch3_weiqi_side` |
| 第3章 · 支线 | 丹房试药 `q_ch3_side_03_alchemy_trial` | `flag_set:alchemy_trial_survived` | `ch3_alchemy_trial`；`ch3_alchemy_trial` |
| 第3章 · 支线 | 禁地探秘 `q_ch3_side_04_forbidden_tomb` | `flag_set:forbidden_tomb_explored` | `ch3_forbidden_crypt_side`；`ch3_forbidden_crypt_side` |
| 第3章 · 支线 | 论剑大会 `q_ch3_side_05_sword_forum` | `flag_set:sword_forum_hosted` | `ch3_sword_forum_side`；`ch3_sword_forum_side` |
| 第4章 · 主线 | 洛阳奇案 `q_ch4_main_01_luoyang_case` | `flag_set:luoyang_case_found_clue` | `ch4_yamen_intro`；`ch4_case_clue` |
| 第4章 · 主线 | 古寺密谋 `q_ch4_main_02_ancient_temple` | `flag_set:captured_fake_liuyun_witness` | `ch4_case_clue`；`ch4_fake_assassin`、`ch4_fake_assassin_capture` |
| 第4章 · 主线 | 运河灭口案 `q_ch4_main_03_canal_witness` | `flag_set:ch4_canal_witness_saved` | `ch4_case_clue`；`ch4_canal_result` |
| 第4章 · 主线 | 古寺地道 `q_ch4_main_04_tunnel_mastermind` | `flag_set:chapter4_complete` | `ch4_tunnel_intro`；`ch4_tunnel_result` |
| 第4章 · 支线 | 救治老卒 `q_ch4_side_01_heal_veteran` | `flag_set:healed_veteran` | `ch4_heal_veteran_offer`；`ch4_heal_veteran_turnin` |
| 第4章 · 支线 | 洛阳纸贵 `q_ch4_side_02_luoyang_paper` | `flag_set:luoyang_paper_helped` | `ch4_luoyang_paper_offer`、`paper_offer`；`ch4_luoyang_paper_turnin`、`paper_report` |
| 第4章 · 支线 | 牡丹诗会 `q_ch4_side_03_peony_poetry` | 显式结算 | `ch4_peony_poetry`、`peony_offer`；`ch4_peony_poetry`、`peony_report` |
| 第4章 · 支线 | 龙门谜踪 `q_ch4_side_04_longmen_mystery` | 显式结算 | `ch4_longmen_mystery`、`longmen_offer`；`ch4_longmen_mystery`、`longmen_report` |
| 第4章 · 支线 | 白马古钟 `q_ch4_side_05_baima_bell` | 显式结算 | `baima_offer`、`ch4_baima_bell`；`baima_report`、`ch4_baima_bell` |
| 第4章 · 支线 | 漕运恩怨 `q_ch4_side_06_canal_grudge` | `flag_set:canal_feud_resolved` | `canal_offer`、`ch4_canal_grudge_offer`；`canal_report`、`ch4_canal_grudge_turnin` |
| 第4章 · 支线 | 含嘉旧刃 `q_ch4_side_07_hanjia_blade` | `flag_set:hanjia_blade_recovered` | `ch4_hanjia_blade_offer`、`hanjia_offer`；`ch4_hanjia_blade_recover` |
| 第5章 · 主线 | 雪路急援 `q_ch5_main_01_relief_route` | `flag_set:ch5_relief_road_cleared` | `ch5_relief_road_intro`；`ch5_relief_road_victory` |
| 第5章 · 主线 | 护住赈粮车队 `q_ch5_main_02_grain_convoy` | `evidence_acquired:ev_ch5_false_banner_cloth` | `ch5_relief_road_victory` |
| 第5章 · 主线 | 雪岭断路 `q_ch5_main_03_snow_pass` | `flag_set:ch5_snow_pass_cleared` | `ch5_snow_pass_intro` |
| 第5章 · 主线 | 矿灯未熄 `q_ch5_main_04_mine_survivor` | `testimony_heard:ts_ch5_old_case_survivor` | `ch5_snow_pass_victory` |
| 第5章 · 主线 | 伪旗归处 `q_ch5_main_05_false_banner_outpost` | `evidence_acquired:ev_ch5_poisoned_false_banner_blade`、`flag_set:ch5_false_banner_captain_defeated` | `ch5_false_banner_outpost_intro` |
| 第5章 · 主线 | 旧债如何公示 `q_ch5_main_06_disclosure_choice` | `flag_set:ch5_disclosure_choice_made` | `ch5_false_banner_boss_victory`；`ch5_disclosure_choice` |
| 第5章 · 支线 | 少记的两袋粮 `q_ch5_side_01_relief_receipt` | `flag_set:ch5_relief_receipt_reported` | `ch5_relief_receipt_start` |
| 第6章 · 主线 | 归村问师 `q_ch6_main_01_homecoming` | `flag_set:ch6_master_found` | `ch6_return_intro`；`ch6_return_intro` |
| 第6章 · 主线 | 旧居暗门 `q_ch6_main_02_old_residence` | `scene_entered:ch6_s3_underground_archive` | `ch6_return_intro` |
| 第6章 · 主线 | 地底原册 `q_ch6_main_03_underground_archive` | `flag_set:ch6_archive_reclaimers_defeated`、`evidence_acquired:ev_ch6_revised_escort_note`、`evidence_acquired:ev_ch6_parent_convoy_roster`、`flag_set:ch6_archive_records_secured` | `ch6_archive_intro` |
| 第6章 · 主线 | 白水旧路 `q_ch6_main_04_old_convoy_route` | `flag_set:ch6_baishui_milestone_checked`、`evidence_acquired:ev_ch6_baishui_transfer_marks`、`flag_set:ch6_convoy_pursuers_defeated` | `ch6_master_after_records` |
| 第6章 · 主线 | 问师改证 `q_ch6_main_05_master_confrontation` | `flag_set:ch6_master_choice_made` | `ch6_master_confrontation`；`ch6_master_confrontation` |
| 第6章 · 主线 | 古道留书 `q_ch6_main_06_ancient_road_letter` | `flag_set:ch6_qiyun_letter_read` | `ch6_master_confrontation`；`ch6_qiyun_letter` |
| 第6章 · 支线 | 三缺一的驿签 `q_ch6_side_04_courier_tally` | `flag_set:ch6_courier_tally_resolved` | `ch6_courier_tally_start` |
| 第7章 · 主线 | 两路先后 `q_ch7_main_01_choose_first_route` | `flag_set:ch7_first_route_arrived` | `ch7_route_choice`；`ch7_lieyun_arrival`、`ch7_mingwu_arrival` |
| 第7章 · 主线 | 双线求证 `q_ch7_main_02_compare_two_fronts` | `flag_set:ch7_lieyun_entry_seen`、`flag_set:ch7_mingwu_entry_seen` | `ch7_lieyun_arrival`、`ch7_mingwu_arrival` |
| 第7章 · 主线 | 外院互证 `q_ch7_main_03_outer_wards` | `evidence_acquired:ev_ch7_lieyun_quarantine_formula`、`flag_set:ch7_lieyun_hardliners_defeated`、`evidence_acquired:ev_ch7_mingwu_transfer_ledger_gap` | `ch7_outer_routes_open` |
| 第7章 · 主线 | 内证初声 `q_ch7_main_04_reform_and_witness` | `testimony_heard:ts_ch7_qi_yunsheng_open_record`、`testimony_heard:ts_ch7_mingwu_dead_disciple_code` | `ch7_inner_routes_open` |
| 第7章 · 主线 | 死名活权 `q_ch7_main_05_dead_name_live_access` | `evidence_acquired:ev_ch7_mingwu_revoked_access_roll`、`testimony_heard:ts_ch7_lieyun_posthumous_code_use` | `ch7_dead_code_routes_open` |
| 第7章 · 主线 | 三证合身 `q_ch7_main_06_threefold_identity_check` | `evidence_acquired:ev_ch7_mingwu_counterseal_chain`、`testimony_heard:ts_ch7_mingwu_instructor_recognized_xueying`、`evidence_acquired:ev_ch7_posthumous_route_timeline` | `ch7_identity_routes_open` |
| 第7章 · 主线 | 影归其名 `q_ch7_main_07_confirm_xueying_identity` | `flag_set:ch7_xueying_identity_confirmed` | `ch7_xueying_identity_conclusion`；`ch7_xueying_identity_conclusion` |
| 第7章 · 主线 | 死籍密令 `q_ch7_main_08_inner_office_authorization` | `evidence_acquired:ev_ch7_inner_office_authorization`、`evidence_acquired:ev_ch7_xueying_retrieval_objectives` | `ch7_authorization_routes_open` |
| 第7章 · 主线 | 护证分流 `q_ch7_main_09_protect_witnesses` | `flag_set:ch7_witness_protection_resolved` | `ch7_witness_protection_choice`；`ch7_witness_protection_choice` |
| 第7章 · 主线 | 内署亲令 `q_ch7_main_10_personal_authorization` | `flag_set:ch7_inner_office_destroyers_defeated`、`evidence_acquired:ev_ch7_su_personal_signed_directive` | `ch7_personal_signature_inquiry_open` |
| 第7章 · 主线 | 证据何时公开 `q_ch7_main_11_disclosure_strategy` | `flag_set:ch7_disclosure_strategy_resolved` | `ch7_disclosure_strategy_choice`；`ch7_disclosure_strategy_choice` |
| 第7章 · 支线 | 茶篓差半斤 `q_ch7_side_05_tea_basket` | `flag_set:ch7_tea_basket_verified` | `ch7_tea_basket_start` |
| 第8章 · 主线 | 会盟点名 `q_ch8_main_01_alliance_muster` | `flag_set:ch8_alliance_mustered` | `ch8_alliance_intro`；`ch8_muster_luoyang`、`ch8_muster_public`、`ch8_muster_split` |
| 第8章 · 主线 | 雾林断讯 `q_ch8_main_02_mistwood_blockade` | `flag_set:ch8_mistwood_blockade_cleared` | `ch8_muster_luoyang`、`ch8_muster_public`、`ch8_muster_split` |
| 第8章 · 主线 | 三旗互杀局 `q_ch8_main_03_false_order_matrix` | `flag_set:ch8_false_order_matrix_checked` | `ch8_mistwood_victory`；`ch8_false_order_matrix` |
| 第8章 · 主线 | 断鼓封雾 `q_ch8_main_04_drum_mist_mechanisms` | `flag_set:ch8_mechanism_guards_defeated`、`flag_set:ch8_false_drum_disabled`、`flag_set:ch8_mist_vents_disabled` | `ch8_false_order_matrix` |
| 第8章 · 主线 | 终局分工 `q_ch8_main_05_final_alliance_roles` | `flag_set:ch8_allies_assigned` | `ch8_platform_intro`；`ch8_roles_luoyang`、`ch8_roles_public`、`ch8_roles_split` |
| 第8章 · 主线 | 截住首令 `q_ch8_main_06_first_false_order` | `flag_set:ch8_first_false_order_stopped` | `ch8_roles_luoyang`、`ch8_roles_public`、`ch8_roles_split` |
| 第8章 · 主线 | 庄主问局 `q_ch8_main_07_su_first_confrontation` | `flag_set:ch8_su_first_confrontation_done` | `ch8_false_order_victory`；`ch8_su_first_confrontation` |
| 第8章 · 主线 | 死士问命 `q_ch8_main_08_su_xueying_authorization` | `flag_set:ch8_su_xueying_authorization_exposed` | `ch8_su_first_confrontation`；`ch8_su_xueying_authorization` |
| 第8章 · 主线 | 最后撤离 `q_ch8_main_09_final_evacuation` | `flag_set:ch8_final_evacuation_complete` | `ch8_su_xueying_authorization`；`ch8_final_evacuation_luoyang`、`ch8_final_evacuation_public`、`ch8_final_evacuation_split` |
| 第8章 · 主线 | 影断旧令 `q_ch8_main_10_xueying_resolution` | `flag_set:ch8_xueying_resolution_done` | `ch8_final_evacuation_luoyang`、`ch8_final_evacuation_public`、`ch8_final_evacuation_split`；`ch8_xueying_battle_victory`、`ch8_xueying_resolution_choice` |
| 第8章 · 主线 | 最后一令 `q_ch8_main_11_su_final_order` | `enemy_defeated:ch8_su_wusheng_final` | `ch8_xueying_battle_victory`、`ch8_xueying_resolution_choice`；`ch8_su_final_victory` |
| 第8章 · 主线 | 旧案见光 `q_ch8_main_12_truth_disclosure` | `flag_set:ch8_truth_disclosure_settled` | `ch8_su_final_victory`；`ch8_truth_disclosure_full`、`ch8_truth_disclosure_joint`、`ch8_truth_disclosure_staged` |
| 第8章 · 主线 | 江湖余波 `q_ch8_main_13_aftermath_returns` | `flag_set:ch8_aftermath_luoyang_done`、`flag_set:ch8_aftermath_lieyun_done`、`flag_set:ch8_aftermath_zhuwei_done`、`flag_set:ch8_relationship_epilogue_done`、`flag_set:ch8_linxi_final_return_done` | `ch8_truth_disclosure_full`、`ch8_truth_disclosure_joint`、`ch8_truth_disclosure_staged`；`ch8_linxi_final_return` |
| 第8章 · 支线 | 营里两件小事 `q_ch8_side_01_camp_supplies` | `flag_set:ch8_camp_supplies_west_done`、`flag_set:ch8_camp_supplies_east_done` | `ch8_camp_supplies_start` |
| 计划外定义 | 下山试剑 `q_ch1_main_01_thug` | `enemy_defeated:thug_lone` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 前往竹尾村 `q_ch1_main_02_qingfeng` | `flag_set:chapter1_complete` | `ch1_road_after_thug` |
| 计划外定义 | 独猎猛虎 `q_ch1_side_04_tiger_hunt` | `flag_set:tiger_hunted` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 祠堂失窃 `q_ch1_side_05_ancestral_theft` | `flag_set:ancestral_hall_case_solved` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 村口试剑 `q_ch1_side_07_village_duel` | `flag_set:village_duel_won` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 援手救人 `q_ch1_side_yuewuxing` | `flag_set:chapter1_complete` | `ch1_forest_yuewuxing`；`ch1_forest_yuewuxing_talk` |
| 计划外定义 | 古峰·豪侠试炼 `q_ch3_gufeng_drink` | `flag_set:ch3_gufeng_complete` | `ch3_gufeng_complete` |
| 计划外定义 | 华山·剑宗气宗 `q_ch3_huashan_unity` | `flag_set:ch3_huashan_complete` | `ch3_huashan_complete` |
| 计划外定义 | 凌月·白晚晴案 `q_ch3_lingyue_clue` | `flag_set:ch3_lingyue_complete` | `ch3_lingyue_complete` |
| 计划外定义 | 茗雾·暗影身法 `q_ch3_mingwu_shadow` | `flag_set:ch3_mingwu_complete` | `ch3_mingwu_complete` |
| 计划外定义 | 散修·五证互校 `q_ch3_wanderer_investigate` | `flag_set:ch3_wanderer_complete` | `ch3_wanderer_complete` |
| 计划外定义 | 武当·掌痕疑云 `q_ch3_wudang_investigate` | `flag_set:ch3_wudang_complete` | `ch3_wudang_complete` |
| 计划外定义 | 强项旧事 `q_ch4_side_08_qiangxiang_receipt` | 显式结算 | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 河洛九数 `q_ch4_side_09_luoshu_numbers` | 显式结算 | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 洛水归信 `q_ch4_side_10_luoshui_letter` | 显式结算 | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 驰援古峰 `q_ch5_main_01_gufeng_defense` | `enemy_defeated:mingwu_assassin_squad` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 浪子令狐封 `q_ch5_main_02_meet_linghu` | `flag_set:met_linghu_feng` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 暗香之谜 `q_ch5_side_01_qi_incense` | `flag_set:found_qi_incense_clue` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 绝壁仙草 `q_ch5_side_02_cliff_immortal_herb` | `flag_set:cliff_immortal_herb_collected` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 古墓玄机 `q_ch5_side_03_ancient_tomb_trap` | `flag_set:ancient_tomb_cleared` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 药香追踪 `q_ch5_side_04_incense_trail` | `flag_set:incense_trail_followed` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 山涧奇遇 `q_ch5_side_05_mountain_stream` | `flag_set:mountain_stream_encounter` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 回乡探师 `q_ch6_main_01_return_home` | `enemy_defeated:mingwu_thugs_fanxuan` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 师徒误会 `q_ch6_main_02_confront_master` | `flag_set:confronted_fanxuan` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 古道留书 `q_ch6_side_01_qi_letter` | `flag_set:found_qi_letter` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 旧居遗物 `q_ch6_side_02_home_belongings` | `flag_set:home_belongings_found` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 故人相托 `q_ch6_side_03_old_friend` | `flag_set:old_friend_mission_done` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 深入烈云 `q_ch7_main_01_infiltrate_lieyun` | `flag_set:met_qi_yunsheng` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 烈云真相 `q_ch7_main_02_truth_revealed` | `flag_set:lieyun_evidence_shown` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 令狐倒戈 `q_ch7_side_01_linghu_betrayal` | `flag_set:linghu_defected` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 暗语密信 `q_ch7_side_02_cipher_message` | `flag_set:cipher_decoded` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 试剑台 `q_ch7_side_03_proving_ground` | `flag_set:proving_ground_cleared` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 红衣往事 `q_ch7_side_04_red_robe_memory` | `flag_set:red_robe_memory_read` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 围攻茗雾 `q_ch8_main_01_mingwu_siege` | `flag_set:reached_mingwu_main_hall` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 雾林决战·薛影 `q_ch8_main_02_xueying_duel` | `enemy_defeated:xueying` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 最终决战·苏雾笙 `q_ch8_main_03_final_boss` | `enemy_defeated:suwusheng` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 山庄秘道 `q_ch8_side_02_secret_passage` | `flag_set:mingwu_passage_cleared` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 师门遗训 `q_ch8_side_03_master_legacy` | `flag_set:master_legacy_read` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 千年宿怨 `q_ch8_side_04_millennium_grudge` | `flag_set:millennium_scroll_read` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 沧浪义约 `q_legend_canghai_zhenyue_palms` | `flag_set:boat_feud_resolved`、`flag_set:ch4_canal_witness_saved`、`flag_set:xingyi_grain_convoy_saved`、`flag_set:xingyi_three_oaths_complete` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 回澜移劲 `q_legend_huilan_redirecting_art` | `flag_set:huilan_echo_understood`、`flag_set:huilan_bell_counterforce_understood`、`flag_set:huilan_yielding_position_understood`、`flag_set:huilan_water_rule_understood`、`flag_set:huilan_balance_understood`、`flag_set:huilan_openworld_trial_complete` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 涤脉禅关 `q_legend_jingang_tempered_meridians` | `flag_set:shaolin_lay_disciple_met`、`flag_set:baima_bell_solved`、`flag_set:shaolin_burned_script_returned`、`flag_set:shaolin_meridian_trial_complete` | 由场景、自动接取或运行时代码驱动 |
| 计划外定义 | 孤云归式 `q_legend_wanxiang_breaking_sword` | `flag_set:guyun_feng_first_met`、`flag_set:guyun_returning_diagram_solved`、`flag_set:guyun_luoyang_notches_solved`、`flag_set:guyun_mingwu_catalog_preserved`、`flag_set:guyun_master_recollection_done`、`flag_set:guyun_master_book_read` | 由场景、自动接取或运行时代码驱动 |

另外检查目录中的洛阳候选包。候选资源需由正式协调器加载才会生效，未计入上述顶层定义。

- `qiangxiang_receipt` · `data/quests/luoyang_culture_candidates_20261019w/qiangxiang_receipt.tres`
