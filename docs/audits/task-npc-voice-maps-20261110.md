# 逐地图任务 NPC 语音明细

审计日期 2026-11-10。地图概况包含全部扫描入口。任务对白按「地图 × 对白资源 × 节点 × 发言人」计数，同一句在不同地图或结局分支出现时会重复列出。

下表的可加载表示 Godot 能读取到有时长的人物语音。点开可播文件，可按台词和情绪逐条试听。缺音条目给出运行时查找路径，便于补配。直接关联含接取、完成、进度旗标、证据或任务门槛。关联分支按同任务对白命名和动作链补列。普通对白只计地图概况，不进入下方明细。

[返回审计结论](task-npc-voice-20261110.md)

## 地图概况

| 地图 | 场景 ID | 任务 NPC 名称数 | 任务语音可加载 / 总条目 | 其他对白可加载 / 总条目 |
|---|---|---:|---:|---:|
| 古寺外 · 岸驿曲径 | [adventure_luoyang_riverside_route](../../game/data/scenes/adventure_luoyang_riverside_route.tres) | 0 | 0 / 0 | 0 / 0 |
| 襄州深矿 | [adventure_xiangzhou_deep_mine](../../game/data/scenes/adventure_xiangzhou_deep_mine.tres) | 0 | 0 / 0 | 0 / 0 |
| 竹尾猎径 | [adventure_zhuwei_hunting_ground](../../game/data/scenes/adventure_zhuwei_hunting_ground.tres) | 0 | 0 / 0 | 0 / 0 |
| [林西村 · 主街](#map-4) | [ch1_s0_linxi_main_walkable](../../game/data/scenes/ch1_s0_linxi_main_walkable.tres) | 1 | 3 / 3 | 7 / 7 |
| [林西村外 · 山道](#map-5) | [ch1_s1_road](../../game/data/scenes/ch1_s1_road.tres) | 1 | 0 / 2 | 1 / 2 |
| [竹尾村 · 主街](#map-6) | [ch1_s2_qingfeng](../../game/data/scenes/ch1_s2_qingfeng.tres) | 6 | 13 / 26 | 2 / 4 |
| [竹尾村 · 村口](#map-7) | [ch1_s2_qingfeng_walkable](../../game/data/scenes/ch1_s2_qingfeng_walkable.tres) | 1 | 1 / 1 | 0 / 0 |
| 城西废宅 · 内堂 | [ch1_s3_ruin_inner](../../game/data/scenes/ch1_s3_ruin_inner.tres) | 0 | 0 / 0 | 0 / 4 |
| [竹尾村 · 城西废宅](#map-9) | [ch1_s3_west_ruin](../../game/data/scenes/ch1_s3_west_ruin.tres) | 1 | 2 / 2 | 1 / 1 |
| 竹尾村外 · 后山密林 | [ch1_s3_zhuwei_forest](../../game/data/scenes/ch1_s3_zhuwei_forest.tres) | 0 | 0 / 0 | 0 / 0 |
| 后山洞窟 · 头狼深窟 | [ch1_s4_cave_deep_den](../../game/data/scenes/ch1_s4_cave_deep_den.tres) | 0 | 0 / 0 | 0 / 0 |
| 后山洞窟 · 废弃矿道 | [ch1_s4_cave_mine_gallery](../../game/data/scenes/ch1_s4_cave_mine_gallery.tres) | 0 | 0 / 0 | 0 / 0 |
| 后山洞窟 · 地下水道 | [ch1_s4_cave_waterway](../../game/data/scenes/ch1_s4_cave_waterway.tres) | 0 | 0 / 0 | 0 / 0 |
| 后山洞窟 · 入口营地 | [ch1_s4_zhuwei_beast_cave](../../game/data/scenes/ch1_s4_zhuwei_beast_cave.tres) | 0 | 0 / 0 | 0 / 0 |
| [竹尾晨市 · 客栈大堂](#map-15) | [ch2_s1_market_inn](../../game/data/scenes/ch2_s1_market_inn.tres) | 3 | 2 / 6 | 0 / 0 |
| 竹尾晨市 · 武馆 | [ch2_s1_market_training_hall](../../game/data/scenes/ch2_s1_market_training_hall.tres) | 0 | 0 / 0 | 0 / 0 |
| [竹尾村 · 晨市](#map-17) | [ch2_s1_zhuwei_market](../../game/data/scenes/ch2_s1_zhuwei_market.tres) | 10 | 4 / 27 | 0 / 7 |
| [竹尾村外 · 北林旧道](#map-18) | [ch2_s2_forest_edge](../../game/data/scenes/ch2_s2_forest_edge.tres) | 1 | 0 / 1 | 0 / 0 |
| [密林 · 伏击场](#map-19) | [ch2_s3_forest_ambush](../../game/data/scenes/ch2_s3_forest_ambush.tres) | 1 | 0 / 6 | 0 / 2 |
| [凌月派 · 山门](#map-20) | [ch2_s4_lingyue_gate](../../game/data/scenes/ch2_s4_lingyue_gate.tres) | 4 | 2 / 7 | 0 / 0 |
| 北林旧矿洞 · 废轨入口 | [ch2_s5_bandit_cave](../../game/data/scenes/ch2_s5_bandit_cave.tres) | 0 | 0 / 0 | 0 / 0 |
| [北林旧矿洞 · 深处账房](#map-22) | [ch2_s5_mine_command](../../game/data/scenes/ch2_s5_mine_command.tres) | 1 | 0 / 1 | 0 / 0 |
| 北林旧矿洞 · 伪牌作坊 | [ch2_s5_mine_workshop](../../game/data/scenes/ch2_s5_mine_workshop.tres) | 0 | 0 / 0 | 0 / 1 |
| 竹尾村外·河滩营地 | [ch2_s6_river_camp](../../game/data/scenes/ch2_s6_river_camp.tres) | 0 | 0 / 0 | 0 / 0 |
| [武林大会 · 长案前](#map-25) | [ch3_s1_wulin_assembly](../../game/data/scenes/ch3_s1_wulin_assembly.tres) | 6 | 2 / 11 | 0 / 2 |
| [武林大会 · 考校场](#map-26) | [ch3_s2_trial_ground](../../game/data/scenes/ch3_s2_trial_ground.tres) | 11 | 3 / 24 | 1 / 14 |
| [五派营地·合练场](#map-27) | [ch3_s3_faction_training](../../game/data/scenes/ch3_s3_faction_training.tres) | 1 | 0 / 2 | 0 / 0 |
| [大会后山·封禁石窟](#map-28) | [ch3_s4_forbidden_tomb](../../game/data/scenes/ch3_s4_forbidden_tomb.tres) | 1 | 0 / 1 | 0 / 0 |
| [洛阳 · 南城门](#map-29) | [ch4_s0_luoyang_gate](../../game/data/scenes/ch4_s0_luoyang_gate.tres) | 1 | 2 / 2 | 0 / 1 |
| [洛阳 · 府衙外院](#map-30) | [ch4_s1_luoyang_yamen](../../game/data/scenes/ch4_s1_luoyang_yamen.tres) | 6 | 2 / 16 | 0 / 0 |
| [洛阳 · 漕渠码头](#map-31) | [ch4_s2_canal_docks](../../game/data/scenes/ch4_s2_canal_docks.tres) | 5 | 1 / 17 | 0 / 2 |
| [洛阳 · 南市](#map-32) | [ch4_s3_luoyang_market](../../game/data/scenes/ch4_s3_luoyang_market.tres) | 5 | 1 / 22 | 0 / 5 |
| [洛阳城外 · 古寺](#map-33) | [ch4_s4_ancient_temple](../../game/data/scenes/ch4_s4_ancient_temple.tres) | 4 | 2 / 16 | 0 / 1 |
| [古寺·地下运货道](#map-34) | [ch4_s5_temple_tunnel](../../game/data/scenes/ch4_s5_temple_tunnel.tres) | 1 | 1 / 1 | 0 / 1 |
| [古峰 · 赈粮路](#map-35) | [ch5_s1_relief_road](../../game/data/scenes/ch5_s1_relief_road.tres) | 2 | 0 / 2 | 0 / 0 |
| [古峰 · 护粮营地](#map-36) | [ch5_s2_grain_convoy_camp](../../game/data/scenes/ch5_s2_grain_convoy_camp.tres) | 2 | 0 / 4 | 0 / 0 |
| [古峰 · 雪岭关](#map-37) | [ch5_s3_snow_pass](../../game/data/scenes/ch5_s3_snow_pass.tres) | 3 | 0 / 3 | 0 / 0 |
| [古峰 · 废弃矿道](#map-38) | [ch5_s4_abandoned_mine](../../game/data/scenes/ch5_s4_abandoned_mine.tres) | 2 | 0 / 2 | 0 / 3 |
| [古峰 · 伪旗营地](#map-39) | [ch5_s5_false_banner_outpost](../../game/data/scenes/ch5_s5_false_banner_outpost.tres) | 3 | 0 / 6 | 0 / 3 |
| [林西村 · 地下档案室](#map-40) | [ch6_s3_underground_archive](../../game/data/scenes/ch6_s3_underground_archive.tres) | 2 | 0 / 2 | 0 / 0 |
| 林西村外 · 白水驿旧路 | [ch6_s4_baishui_convoy_route](../../game/data/scenes/ch6_s4_baishui_convoy_route.tres) | 0 | 0 / 0 | 0 / 2 |
| 林西村外 · 古道客栈 | [ch6_s5_ancient_road_inn](../../game/data/scenes/ch6_s5_ancient_road_inn.tres) | 0 | 0 / 0 | 0 / 0 |
| 烈云旧渡 · 夜航转运栈 | [ch7_s10_lieyun_night_transfer_station](../../game/data/scenes/ch7_s10_lieyun_night_transfer_station.tres) | 0 | 0 / 0 | 0 / 0 |
| [烈云峡谷 · 旧渡](#map-44) | [ch7_s1_lieyun_valley_ferry](../../game/data/scenes/ch7_s1_lieyun_valley_ferry.tres) | 1 | 0 / 2 | 0 / 2 |
| [茗雾山 · 茶镇](#map-45) | [ch7_s2_mingwu_tea_town](../../game/data/scenes/ch7_s2_mingwu_tea_town.tres) | 1 | 0 / 2 | 0 / 2 |
| [烈云分舵 · 外区](#map-46) | [ch7_s3_lieyun_outpost_outer_ward](../../game/data/scenes/ch7_s3_lieyun_outpost_outer_ward.tres) | 1 | 0 / 1 | 0 / 4 |
| [茗雾山庄 · 外院](#map-47) | [ch7_s4_mingwu_manor_outer_court](../../game/data/scenes/ch7_s4_mingwu_manor_outer_court.tres) | 2 | 0 / 5 | 0 / 1 |
| [烈云分舵 · 聚义厅](#map-48) | [ch7_s5_lieyun_assembly_hall](../../game/data/scenes/ch7_s5_lieyun_assembly_hall.tres) | 3 | 0 / 22 | 0 / 4 |
| 茗雾山庄 · 内院 | [ch7_s6_mingwu_inner_court](../../game/data/scenes/ch7_s6_mingwu_inner_court.tres) | 0 | 0 / 0 | 0 / 4 |
| [烈云分舵 · 安置档案室](#map-50) | [ch7_s7_lieyun_resettlement_archive](../../game/data/scenes/ch7_s7_lieyun_resettlement_archive.tres) | 1 | 0 / 2 | 0 / 0 |
| 茗雾山庄 · 权限档案房 | [ch7_s8_mingwu_permission_archive](../../game/data/scenes/ch7_s8_mingwu_permission_archive.tres) | 0 | 0 / 0 | 0 / 0 |
| [茗雾山庄 · 封印审验室](#map-52) | [ch7_s9_mingwu_seal_audit_room](../../game/data/scenes/ch7_s9_mingwu_seal_audit_room.tres) | 2 | 0 / 2 | 0 / 0 |
| [茗雾外围 · 会盟集结地](#map-53) | [ch8_s1_alliance_staging_ground](../../game/data/scenes/ch8_s1_alliance_staging_ground.tres) | 1 | 0 / 3 | 0 / 0 |
| [茗雾外围 · 雾林阻截场](#map-54) | [ch8_s2_mistwood_blockade](../../game/data/scenes/ch8_s2_mistwood_blockade.tres) | 1 | 0 / 1 | 0 / 0 |
| 茗雾山庄 · 外围连营 | [ch8_s3_manor_perimeter_encampment](../../game/data/scenes/ch8_s3_manor_perimeter_encampment.tres) | 0 | 0 / 0 | 0 / 0 |
| [会盟祭台下 · 机关廊](#map-56) | [ch8_s4_alliance_mechanism_gallery](../../game/data/scenes/ch8_s4_alliance_mechanism_gallery.tres) | 1 | 0 / 1 | 0 / 0 |
| [茗雾山庄 · 会盟祭台](#map-57) | [ch8_s5_alliance_ceremonial_platform](../../game/data/scenes/ch8_s5_alliance_ceremonial_platform.tres) | 4 | 0 / 12 | 0 / 0 |
| [茗雾山庄 · 正厅](#map-58) | [ch8_s6_mingwu_main_hall](../../game/data/scenes/ch8_s6_mingwu_main_hall.tres) | 2 | 0 / 8 | 0 / 0 |
| [茗雾山庄 · 后殿](#map-59) | [ch8_s7_mingwu_rear_sanctum](../../game/data/scenes/ch8_s7_mingwu_rear_sanctum.tres) | 3 | 0 / 8 | 0 / 8 |
| [山道·山贼洞窟](#map-60) | [interior_bandit_cave](../../game/data/scenes/interior_bandit_cave.tres) | 1 | 0 / 1 | 0 / 0 |
| [竹尾村·客栈大堂](#map-61) | [interior_inn_hall](../../game/data/scenes/interior_inn_hall.tres) | 1 | 2 / 2 | 1 / 3 |
| 林西村·武馆 | [interior_martial_hall](../../game/data/scenes/interior_martial_hall.tres) | 0 | 0 / 0 | 0 / 0 |
| 古寺·地道 | [interior_temple_tunnel](../../game/data/scenes/interior_temple_tunnel.tres) | 0 | 0 / 0 | 0 / 0 |
| 林西村 · 村民家 | [linxi_farmer_cottage](../../game/data/scenes/linxi_farmer_cottage.tres) | 0 | 0 / 0 | 0 / 0 |
| 林西村 · 采药人家 | [linxi_herbal_home](../../game/data/scenes/linxi_herbal_home.tres) | 0 | 0 / 0 | 0 / 0 |
| 林西村 - 冷孤云的卧室 | [linxi_hero_bedroom](../../game/data/scenes/linxi_hero_bedroom.tres) | 0 | 0 / 0 | 0 / 0 |
| 林西村 - 师傅正屋 | [linxi_master_hall](../../game/data/scenes/linxi_master_hall.tres) | 0 | 0 / 0 | 0 / 0 |
| 林西村 · 私塾旧宅 | [linxi_scholar_house](../../game/data/scenes/linxi_scholar_house.tres) | 0 | 0 / 0 | 0 / 0 |
| 林西村南坊 · 药铺内堂 | [linxi_south_apothecary_home](../../game/data/scenes/linxi_south_apothecary_home.tres) | 0 | 0 / 0 | 0 / 0 |
| 林西村南坊 · 私塾 | [linxi_south_scholar_house](../../game/data/scenes/linxi_south_scholar_house.tres) | 0 | 0 / 0 | 0 / 0 |
| 林西村南坊 · 民居 | [linxi_south_villager_home](../../game/data/scenes/linxi_south_villager_home.tres) | 0 | 0 / 0 | 0 / 0 |
| [林西村 · 师徒院落](#map-72) | [linxi_tutorial](../../game/data/scenes/linxi_tutorial.tres) | 3 | 18 / 33 | 4 / 16 |
| [林西村 · 村中心](#map-73) | [linxi_village_center](../../game/data/scenes/linxi_village_center.tres) | 1 | 0 / 7 | 18 / 24 |
| [林西村 · 南坊](#map-74) | [linxi_village_scrollmap](../../game/data/scenes/linxi_village_scrollmap.tres) | 1 | 0 / 5 | 2 / 9 |
| 白鹿渡 · 接驳栈 | [openworld_bailu_ferry](../../game/data/scenes/openworld_bailu_ferry.tres) | 0 | 0 / 0 | 0 / 5 |
| 汴州城 · 中轴坊市 | [openworld_bianzhou_city](../../game/data/scenes/openworld_bianzhou_city.tres) | 0 | 0 / 0 | 0 / 2 |
| 中原旧驿 · 荒道 | [openworld_bianzhou_old_post](../../game/data/scenes/openworld_bianzhou_old_post.tres) | 0 | 0 / 0 | 0 / 0 |
| 沙漠城 | [openworld_desert_city](../../game/data/scenes/openworld_desert_city.tres) | 0 | 0 / 0 | 0 / 0 |
| 东海埠 · 内河接驳栈 | [openworld_east_sea_port](../../game/data/scenes/openworld_east_sea_port.tres) | 0 | 0 / 0 | 0 / 1 |
| 华山派 · 山门 | [openworld_huashan_forecourt](../../game/data/scenes/openworld_huashan_forecourt.tres) | 0 | 0 / 0 | 0 / 0 |
| 华山派 · 演武坪 | [openworld_huashan_sword_terrace](../../game/data/scenes/openworld_huashan_sword_terrace.tres) | 0 | 0 / 0 | 0 / 0 |
| 华山派 · 观瀑剑台 | [openworld_huashan_waterfall_terrace](../../game/data/scenes/openworld_huashan_waterfall_terrace.tres) | 0 | 0 / 0 | 0 / 4 |
| 金陵城 · 水巷桥市 | [openworld_jinling_city](../../game/data/scenes/openworld_jinling_city.tres) | 0 | 0 / 0 | 0 / 2 |
| 江南芦荡 · 水泽 | [openworld_jinling_reed_marsh](../../game/data/scenes/openworld_jinling_reed_marsh.tres) | 0 | 0 / 0 | 0 / 0 |
| 岚溪寨 | [openworld_lanxi_zhai](../../game/data/scenes/openworld_lanxi_zhai.tres) | 0 | 0 / 0 | 0 / 0 |
| 凌月派 · 内庭 | [openworld_lingyue_inner_court](../../game/data/scenes/openworld_lingyue_inner_court.tres) | 0 | 0 / 0 | 0 / 0 |
| 清河镇 · 行旅街 | [openworld_qinghe_town](../../game/data/scenes/openworld_qinghe_town.tres) | 0 | 0 / 0 | 0 / 1 |
| 赤岩镇 | [openworld_redrock_town](../../game/data/scenes/openworld_redrock_town.tres) | 0 | 0 / 0 | 0 / 0 |
| 林西竹溪林 · 建议2～4级 | [openworld_v15_bamboo_outskirts](../../game/data/scenes/openworld_v15_bamboo_outskirts.tres) | 0 | 0 / 0 | 0 / 0 |
| 襄州密林 · 建议7～8级 | [openworld_v15_forest_outskirts](../../game/data/scenes/openworld_v15_forest_outskirts.tres) | 0 | 0 / 0 | 0 / 0 |
| 金陵南泽 · 建议10～11级 | [openworld_v15_marsh_outskirts](../../game/data/scenes/openworld_v15_marsh_outskirts.tres) | 0 | 0 / 0 | 0 / 0 |
| 武当派 · 山门 | [openworld_wudang_gate](../../game/data/scenes/openworld_wudang_gate.tres) | 0 | 0 / 0 | 0 / 1 |
| 武当派 · 紫霄宫前庭 | [openworld_wudang_purple_cloud_court](../../game/data/scenes/openworld_wudang_purple_cloud_court.tres) | 0 | 0 / 0 | 0 / 0 |
| 武当派 · 太极场 | [openworld_wudang_taiji_court](../../game/data/scenes/openworld_wudang_taiji_court.tres) | 0 | 0 / 0 | 0 / 0 |
| 襄州城 · 江防校场 | [openworld_xiangzhou_city](../../game/data/scenes/openworld_xiangzhou_city.tres) | 0 | 0 / 0 | 0 / 2 |
| 襄州矿谷 · 采坑 | [openworld_xiangzhou_mine_valley](../../game/data/scenes/openworld_xiangzhou_mine_valley.tres) | 0 | 0 / 0 | 0 / 0 |
| 雁门关 · 寒岭藏剑洞 | [openworld_yanmen_hidden_cave](../../game/data/scenes/openworld_yanmen_hidden_cave.tres) | 0 | 0 / 0 | 0 / 2 |
| 雁门关 · 关外雪径 | [openworld_yanmen_pass](../../game/data/scenes/openworld_yanmen_pass.tres) | 0 | 0 / 0 | 0 / 0 |
| 江湖行旅图 | [world_map_jianghu](../../game/data/scenes/world_map_jianghu.tres) | 0 | 0 / 0 | 0 / 0 |
| 江湖行旅图 · v13 分层预览 | [world_map_jianghu_v13_staging](../../game/data/scenes/world_map_jianghu_v13_staging.tres) | 0 | 0 / 0 | 0 / 0 |
| 江湖行旅图 | [world_map_jianghu_v14](../../game/data/scenes/world_map_jianghu_v14.tres) | 0 | 0 / 0 | 0 / 0 |
| 江湖行旅图 | [world_map_jianghu_v15](../../game/data/scenes/world_map_jianghu_v15.tres) | 0 | 0 / 0 | 0 / 0 |
| 中原授权物件分层候选（视觉未通过） | [world_map_layered_cc0_candidate_20260929](../../game/data/scenes/world_map_layered_cc0_candidate_20260929.tres) | 0 | 0 / 0 | 0 / 0 |
| 中原地形分层试样 | [world_map_layered_prototype_20260928](../../game/data/scenes/world_map_layered_prototype_20260928.tres) | 0 | 0 / 0 | 0 / 0 |
| 中原至东岸分层候选（待验收） | [world_map_native_coast_gen_v2_candidate_20260929](../../game/data/scenes/world_map_native_coast_gen_v2_candidate_20260929.tres) | 0 | 0 / 0 | 0 / 0 |
| 怡红院·接待厅与雅座 | [yihongyuan27n_interior](../../game/data/scenes/yihongyuan27n_interior.tres) | 0 | 0 / 0 | 0 / 0 |

## 任务对白逐句检查

同一地图先列可播台词，再列缺音。括号内为引擎计算的情绪标签，分段 MP3 沿用录制时的演绎。旁白、主角、总录文书和仅舞台说明单独处理，不计入任务 NPC 指标。

<a id="map-4"></a>
### 林西村 · 主街 · ch1_s0_linxi_main_walkable

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 武馆教头 | [ch1_martial_hall_master](../../game/data/dialogs/ch1_martial_hall_master.tres) · basic · normal | 点到为止。输赢不重要，记住对方出手前的肩、肘、腰。 | [语音 1 · 6.5 秒](../../game/art/audio/voices/ch1/ch1_martial_hall_master/%E6%AD%A6%E9%A6%86%E6%95%99%E5%A4%B4_basic_enormal.mp3)（情绪后缀） |
| 武馆教头 | [ch1_martial_hall_master](../../game/data/dialogs/ch1_martial_hall_master.tres) · senior · normal | 高阶弟子不会留手。赢下这一场，才算能独自下山。 | [语音 1 · 5.9 秒](../../game/art/audio/voices/ch1/ch1_martial_hall_master/%E6%AD%A6%E9%A6%86%E6%95%99%E5%A4%B4_senior_enormal.mp3)（情绪后缀） |
| 武馆教头 | [ch1_martial_hall_master](../../game/data/dialogs/ch1_martial_hall_master.tres) · start · normal | 练剑靠的不是逞强，是一招一式地把根基打稳。要和弟子过几手么？ | [语音 1 · 6.9 秒](../../game/art/audio/voices/ch1/ch1_martial_hall_master/%E6%AD%A6%E9%A6%86%E6%95%99%E5%A4%B4_start_enormal.mp3)（情绪后缀） |

<a id="map-5"></a>
### 林西村外 · 山道 · ch1_s1_road

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 范掌柜 | [ch1_side_caravan_road_start](../../game/data/dialogs/ch1_side_caravan_road_start.tres) · start · normal | 护商镖师说你会来。前面转过乱石坡就是最窄的弯道，山匪若要截货，多半会在那里动手。 | 缺音 · <code>res://art/audio/voices/ch1/ch1_side_caravan_road_start/范掌柜_start.mp3</code> |
| 范掌柜 | [ch1_side_caravan_victory](../../game/data/dialogs/ch1_side_caravan_victory.tres) · thanks · normal | 这趟货能平安过去，村里的伤药就不会断。我按说好的付酬，再添些蜀锦和药材给你。 | 缺音 · <code>res://art/audio/voices/ch1/ch1_side_caravan_victory/范掌柜_thanks.mp3</code> |

<a id="map-6"></a>
### 竹尾村 · 主街 · ch1_s2_qingfeng

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 卖菜大婶 | [ch1_s2_vegetable_vendor](../../game/data/dialogs/ch1_s2_vegetable_vendor.tres) · accept · normal | 它多长在背阴的石缝边。别为了采药惊动林里的猛兽。 | [语音 1 · 5.9 秒](../../game/art/audio/voices/ch1/ch1_s2_vegetable_vendor/%E5%8D%96%E8%8F%9C%E5%A4%A7%E5%A9%B6_accept_seg01_dialog.mp3)（分段） |
| 卖菜大婶 | [ch1_s2_vegetable_vendor](../../game/data/dialogs/ch1_s2_vegetable_vendor.tres) · start · concerned | 最近村外不太平，我不敢进后山。少侠若要去密林，能否替我带一束叶缘泛红的止血草回来？ | [语音 1 · 11.0 秒](../../game/art/audio/voices/ch1/ch1_s2_vegetable_vendor/%E5%8D%96%E8%8F%9C%E5%A4%A7%E5%A9%B6_start_seg01_dialog.mp3)（分段） |
| 卖菜大婶 | [ch1_s2_vegetable_vendor_done](../../game/data/dialogs/ch1_s2_vegetable_vendor_done.tres) · start · normal · 关联分支 | 多谢少侠。后山还有猛兽，采药也别离道路太远。 | [语音 1 · 5.9 秒](../../game/art/audio/voices/ch1/ch1_s2_vegetable_vendor_done/%E5%8D%96%E8%8F%9C%E5%A4%A7%E5%A9%B6_start_seg01_dialog.mp3)（分段） |
| 卖菜大婶 | [ch1_s2_vegetable_vendor_turnin](../../game/data/dialogs/ch1_s2_vegetable_vendor_turnin.tres) · start · normal | 正是这种止血草！这几日受伤的人多，有它就能多备几包伤药。 | [语音 1 · 6.4 秒](../../game/art/audio/voices/ch1/ch1_s2_vegetable_vendor_turnin/%E5%8D%96%E8%8F%9C%E5%A4%A7%E5%A9%B6_start_seg01_dialog.mp3)（分段） |
| 卖菜大婶 | [ch1_s2_vegetable_vendor_waiting](../../game/data/dialogs/ch1_s2_vegetable_vendor_waiting.tres) · start · normal | 少侠，我托你找的止血草有消息了吗？叶缘泛红、长在背阴石缝旁的那种。 | [语音 1 · 7.9 秒](../../game/art/audio/voices/ch1/ch1_s2_vegetable_vendor_waiting/%E5%8D%96%E8%8F%9C%E5%A4%A7%E5%A9%B6_start_seg01_dialog.mp3)（分段） |
| 守村人 | [ch1_s2_guard](../../game/data/dialogs/ch1_s2_guard.tres) · notice · normal | 告示上说，失踪的人最后在城西废宅附近出现。最近山匪也突然多了，若要查，先在村里备些药，再去问问护商镖师。 | [语音 1 · 10.0 秒](../../game/art/audio/voices/ch1/ch1_s2_guard/%E5%AE%88%E6%9D%91%E4%BA%BA_notice_enormal.mp3)（情绪后缀） |
| 守村人 | [ch1_s2_guard](../../game/data/dialogs/ch1_s2_guard.tres) · start · normal | 外乡人？从林西村来的？你来得正是时候，村口刚贴了一张凌月派弟子失踪的告示。 | [语音 1 · 9.0 秒](../../game/art/audio/voices/ch1/ch1_s2_guard/%E5%AE%88%E6%9D%91%E4%BA%BA_start_enormal.mp3)（情绪后缀） |
| 客栈老板 | [ch1_s2_inn_keeper](../../game/data/dialogs/ch1_s2_inn_keeper.tres) · b · normal | 尤其[color=#e3a64a]城西的那处废宅[/color]—— 半月内已经死了三波路人，连衙门都不敢往里钻。 | [语音 1 · 7.3 秒](../../game/art/audio/voices/ch1/ch1_s2_inn_keeper/%E5%AE%A2%E6%A0%88%E8%80%81%E6%9D%BF_b_enormal.mp3)（情绪后缀） |
| 客栈老板 | [ch1_s2_inn_keeper](../../game/data/dialogs/ch1_s2_inn_keeper.tres) · start · concerned | 客官从外面来？ 这阵子可不太平，少在城外多走动。 | [语音 1 · 5.2 秒](../../game/art/audio/voices/ch1/ch1_s2_inn_keeper/%E5%AE%A2%E6%A0%88%E8%80%81%E6%9D%BF_start.mp3)（无后缀回退） |
| 护商镖师 | [ch1_s2_patrol_scout](../../game/data/dialogs/ch1_s2_patrol_scout.tres) · accept · normal | 山匪不会总站在一处。多在山道上走动，听见异响就当心。 | [语音 1 · 6.5 秒](../../game/art/audio/voices/ch1/ch1_s2_patrol_scout/%E6%8A%A4%E5%95%86%E9%95%96%E5%B8%88_accept_enormal.mp3)（情绪后缀） |
| 护商镖师 | [ch1_s2_patrol_scout](../../game/data/dialogs/ch1_s2_patrol_scout.tres) · start · normal | 我巡到村东时，看见一群野兽从后山密林里惊逃出来，林里像有什么东西把它们逼疯了。林西村外那段山道也有山匪游荡，商队都不敢走。 | [语音 1 · 7.8 秒](../../game/art/audio/voices/ch1/ch1_s2_patrol_scout/%E6%8A%A4%E5%95%86%E9%95%96%E5%B8%88_start_enormal.mp3)（情绪后缀） |
| 焦急妇人 | [ch1_s2_crying_woman](../../game/data/dialogs/ch1_s2_crying_woman.tres) · start · fear | 公子……公子救命！ 我夫君三天前被一伙黑衣人掳走，到现在没回来—— 他们往城西去了。 | [语音 1 · 6.5 秒](../../game/art/audio/voices/ch1/ch1_s2_crying_woman/%E7%84%A6%E6%80%A5%E5%A6%87%E4%BA%BA_start_seg01_dialog.mp3)（分段） |
| 焦急妇人 | [ch1_s2_crying_woman_waiting](../../game/data/dialogs/ch1_s2_crying_woman_waiting.tres) · start · normal · 关联分支 | 公子，我夫君有消息了吗？他被带去城西以后，我一夜都没合眼。 | [语音 1 · 6.3 秒](../../game/art/audio/voices/ch1/ch1_s2_crying_woman_waiting/%E7%84%A6%E6%80%A5%E5%A6%87%E4%BA%BA_start_seg01_dialog.mp3)（分段） |
| 守村人 | [ch1_s2_guard_report](../../game/data/dialogs/ch1_s2_guard_report.tres) · reply · normal | 那就对上了。林里原有一处兽穴，近来夜里常有车辙通向那里。少侠若要查，务必小心。 | 缺音 · <code>res://art/audio/voices/ch1/ch1_s2_guard_report/守村人_reply.mp3</code> |
| 护商镖师 | [ch1_s2_bandit_cave_rumour](../../game/data/dialogs/ch1_s2_bandit_cave_rumour.tres) · accept · normal | 洞里还有人看守货物。击退留守的人以后，留意褪色旗帜下面的货箱，兴许能找到送货记号。 | 缺音 · <code>res://art/audio/voices/ch1/ch1_s2_bandit_cave_rumour/护商镖师_accept.mp3</code> |
| 护商镖师 | [ch1_s2_bandit_cave_rumour](../../game/data/dialogs/ch1_s2_bandit_cave_rumour.tres) · start · normal | 你击退的只是巡路山匪。我顺着脚印找过，他们在山道中央石脊后藏了个洞窟，里头常有人操练。 | 缺音 · <code>res://art/audio/voices/ch1/ch1_s2_bandit_cave_rumour/护商镖师_start.mp3</code> |
| 护商镖师 | [ch1_s2_bandit_cave_waiting](../../game/data/dialogs/ch1_s2_bandit_cave_waiting.tres) · start · normal | 山道石脊后的洞窟查得怎样了？若看到旗帜或送货记号，记得先记下来。 | 缺音 · <code>res://art/audio/voices/ch1/ch1_s2_bandit_cave_waiting/护商镖师_start.mp3</code> |
| 护商镖师 | [ch1_s2_patrol_scout_waiting](../../game/data/dialogs/ch1_s2_patrol_scout_waiting.tres) · start · normal | 山道上的匪徒清理得怎么样了？商队还不敢恢复通行。 | 缺音 · <code>res://art/audio/voices/ch1/ch1_s2_patrol_scout_waiting/护商镖师_start.mp3</code> |
| 护商镖师 | [ch1_s2_scout_main_clue](../../game/data/dialogs/ch1_s2_scout_main_clue.tres) · start · normal | 我巡到村东时，看见一群野兽从后山密林里惊逃出来，林里像有什么东西把它们逼疯了。 | 缺音 · <code>res://art/audio/voices/ch1/ch1_s2_scout_main_clue/护商镖师_start.mp3</code> |
| 护商镖师 | [ch1_side_caravan_done](../../game/data/dialogs/ch1_side_caravan_done.tres) · start · normal | 范掌柜的货已经进村了。古道能重新走商，比多抓两个散匪更让百姓安心。 | 缺音 · <code>res://art/audio/voices/ch1/ch1_side_caravan_done/护商镖师_start.mp3</code> |
| 护商镖师 | [ch1_side_caravan_offer](../../game/data/dialogs/ch1_side_caravan_offer.tres) · accept · normal | 范掌柜停在旧碑往东的弯道。见到人先认货旗，别被山匪换旗诱开。 | 缺音 · <code>res://art/audio/voices/ch1/ch1_side_caravan_offer/护商镖师_accept.mp3</code> |
| 护商镖师 | [ch1_side_caravan_offer](../../game/data/dialogs/ch1_side_caravan_offer.tres) · start · normal | 有支小商队要走林西古道。领头的范掌柜押着蜀锦和伤药，偏偏山匪刚被打散，最容易趁商路恢复时再扑一次。我们缺一个能照应后队的人。 | 缺音 · <code>res://art/audio/voices/ch1/ch1_side_caravan_offer/护商镖师_start.mp3</code> |
| 护商镖师 | [ch1_side_caravan_waiting](../../game/data/dialogs/ch1_side_caravan_waiting.tres) · start · normal | 范掌柜还在林西古道等你。商队不动，竹尾村的药材和布匹就都进不来。 | 缺音 · <code>res://art/audio/voices/ch1/ch1_side_caravan_waiting/护商镖师_start.mp3</code> |
| 挑担脚夫 | [huilan_openworld_balance](../../game/data/dialogs/huilan_openworld_balance.tres) · right · normal | 这回肩上像只过了一阵风。原来换力不是把旧劲丢掉，是让它托住下一步。 | 缺音 · <code>res://art/audio/voices/hui/huilan_openworld_balance/挑担脚夫_right.mp3</code> |
| 挑担脚夫 | [huilan_openworld_balance](../../game/data/dialogs/huilan_openworld_balance.tres) · start · normal | 我这肩伤不是担子重，是换肩时总把一头先放死。两筐还在晃，硬换便像有人从背后推我。 | 缺音 · <code>res://art/audio/voices/hui/huilan_openworld_balance/挑担脚夫_start.mp3</code> |
| 挑担脚夫 | [huilan_openworld_balance](../../game/data/dialogs/huilan_openworld_balance.tres) · wrong · normal | 那一下断得太硬，重量全砸在肩上。要让两头的摆势替人换力。 | 缺音 · <code>res://art/audio/voices/hui/huilan_openworld_balance/挑担脚夫_wrong.mp3</code> |

<a id="map-7"></a>
### 竹尾村 · 村口 · ch1_s2_qingfeng_walkable

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 守门村民 | [ch1_zhuwei_arrival](../../game/data/dialogs/ch1_zhuwei_arrival.tres) · n3 · concerned | 少侠是外乡人吧？今晚先住下。那片林子这几日不太平，进去的人，一个都没回来。 | [语音 1 · 8.3 秒](../../game/art/audio/voices/ch1/ch1_zhuwei_arrival/%E5%AE%88%E9%97%A8%E6%9D%91%E6%B0%91_n3.mp3)（无后缀回退） |

<a id="map-9"></a>
### 竹尾村 · 城西废宅 · ch1_s3_west_ruin

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 被绑男子 | [ch1_s3_bound_man](../../game/data/dialogs/ch1_s3_bound_man.tres) · c · normal | 壮士大恩…… 那带头的姓赵，似乎与茗雾山庄什么 [color=#e3a64a]地下密窟[/color] 有关—— 小的这就走！ | [语音 1 · 7.9 秒](../../game/art/audio/voices/ch1/ch1_s3_bound_man/%E8%A2%AB%E7%BB%91%E7%94%B7%E5%AD%90_c_enormal.mp3)（情绪后缀） |
| 被绑男子 | [ch1_s3_bound_man](../../game/data/dialogs/ch1_s3_bound_man.tres) · start · fear | 壮士……壮士救命！ 是我浑家请你来的吧？ | [语音 1 · 3.8 秒](../../game/art/audio/voices/ch1/ch1_s3_bound_man/%E8%A2%AB%E7%BB%91%E7%94%B7%E5%AD%90_start_efear.mp3)（情绪后缀） |

<a id="map-15"></a>
### 竹尾晨市 · 客栈大堂 · ch2_s1_market_inn

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 楚泠 | [ch2_moon_guqin_offer](../../game/data/dialogs/ch2_moon_guqin_offer.tres) · start · normal | 谷雨观每逢满月便有琴声。若你真想查，先在观外听完整支曲子，别惊动里面的人。 | [语音 1 · 8.3 秒](../../game/art/audio/voices/ch2/ch2_moon_guqin_offer/%E6%A5%9A%E6%B3%A0_start_seg01_dialog.mp3)（分段） |
| 楚泠 | [ch2_moon_guqin_turnin](../../game/data/dialogs/ch2_moon_guqin_turnin.tres) · start · normal | 不是鬼，是我在祭师父。你听出了《广陵散》的末指，也替我守住了这点清净。 | [语音 1 · 8.8 秒](../../game/art/audio/voices/ch2/ch2_moon_guqin_turnin/%E6%A5%9A%E6%B3%A0_start_seg01_dialog.mp3)（分段） |
| 客栈老板 | [ch2_missing_disciple_offer](../../game/data/dialogs/ch2_missing_disciple_offer.tres) · start · normal | 失踪的凌月弟子曾住我这里。她落下一枚铜扣，或许能帮你辨认行踪。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_missing_disciple_offer/客栈老板_start.mp3</code> |
| 棋叟 | [ch2_go_puzzle](../../game/data/dialogs/ch2_go_puzzle.tres) · right · normal | 以闲子断气路，好。局破了，这枚玉棋归你。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_go_puzzle/棋叟_right.mp3</code> |
| 棋叟 | [ch2_go_puzzle](../../game/data/dialogs/ch2_go_puzzle.tres) · start · normal | 黑棋封住四面，白棋只剩一口气。年轻人，可敢落一子？ | 缺音 · <code>res://art/audio/voices/ch2/ch2_go_puzzle/棋叟_start.mp3</code> |
| 棋叟 | [ch2_go_puzzle](../../game/data/dialogs/ch2_go_puzzle.tres) · wrong · normal | 只看眼前，三步后仍是死局。再看看那枚最不像棋的棋。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_go_puzzle/棋叟_wrong.mp3</code> |

<a id="map-17"></a>
### 竹尾村 · 晨市 · ch2_s1_zhuwei_market

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 沈晚棠 | [ch2_canglong_fragment_upper](../../game/data/dialogs/ch2_canglong_fragment_upper.tres) · start · normal | 这页旧纸夹在剑匣底层，家里没人看得懂。你在擂台上懂得留手，它也该交给懂分寸的人。 | [语音 1 · 8.7 秒](../../game/art/audio/voices/ch2/ch2_canglong_fragment_upper/%E6%B2%88%E6%99%9A%E6%A3%A0_start_seg01_dialog.mp3)（分段） |
| 沈晚棠 | [ch2_tournament_after](../../game/data/dialogs/ch2_tournament_after.tres) · start · normal · 关联分支 | 山外路长，旧纸里的招式未必还能练成。若真找齐了，先辨笔势，再辨真伪。 | [语音 1 · 8.1 秒](../../game/art/audio/voices/ch2/ch2_tournament_after/%E6%B2%88%E6%99%9A%E6%A3%A0_start_seg01_dialog.mp3)（分段） |
| 沈晚棠 | [ch2_tournament_complete](../../game/data/dialogs/ch2_tournament_complete.tres) · start · normal | 你没有硬拼，借他收势时一步逼出圈。剑归你，喝酒的事，等你从凌月山回来再说。 | [语音 1 · 8.5 秒](../../game/art/audio/voices/ch2/ch2_tournament_complete/%E6%B2%88%E6%99%9A%E6%A3%A0_start_seg01_dialog.mp3)（分段） |
| 沈晚棠 | [ch2_tournament_offer](../../game/data/dialogs/ch2_tournament_offer.tres) · start · normal | 擂台彩头是一柄传家剑。想拿便上来，最后一轮由我家护院总管应战。 | [语音 1 · 7.5 秒](../../game/art/audio/voices/ch2/ch2_tournament_offer/%E6%B2%88%E6%99%9A%E6%A3%A0_start_seg01_dialog.mp3)（分段） |
| 守村人 | [ch2_market_gatekeeper_followup](../../game/data/dialogs/ch2_market_gatekeeper_followup.tres) · start · normal | 天亮前有辆炭车去了河滩。我当时没查，后来才在车轴旁捡到一缕白布。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_market_gatekeeper_followup/守村人_start.mp3</code> |
| 守村人 | [ch2_zhuwei_intro](../../game/data/dialogs/ch2_zhuwei_intro.tres) · n2 · normal | 又少了一个。可怪就怪在这里：有人说她们结伴进了北林，也有人看见凌月派的白布挂在出村炭车上。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_zhuwei_intro/守村人_n2.mp3</code> |
| 守村人 | [ch8_aftermath_zhuwei](../../game/data/dialogs/ch8_aftermath_zhuwei.tres) · end · normal | 晨市商路已经恢复，证人也没有被人堵门。大家未必信江湖规矩，却开始相信手里那份盖着不同印的抄本。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_aftermath_zhuwei/守村人_end.mp3</code> |
| 守村人 | [ch8_aftermath_zhuwei](../../game/data/dialogs/ch8_aftermath_zhuwei.tres) · start · normal | 公示传到竹尾以后，最先来的不是掌门，是当年失踪弟子的家人。他们终于知道孩子死在哪一段路，也知道谁改过名册。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_aftermath_zhuwei/守村人_start.mp3</code> |
| 封砚秋 | [ch2_guyun_feng_first_meeting](../../game/data/dialogs/ch2_guyun_feng_first_meeting.tres) · correct · normal | 正是丙剑。招式会骗人，日积月累的磨痕不会。我叫封砚秋，替人整理旧谱，也替旧谱寻找还肯认真看剑的人。以后或许还会遇见。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_guyun_feng_first_meeting/封砚秋_correct.mp3</code> |
| 封砚秋 | [ch2_guyun_feng_first_meeting](../../game/data/dialogs/ch2_guyun_feng_first_meeting.tres) · puzzle · normal | 甲剑缺口在正锋，乙剑弯在剑脊，丙剑护手内侧被磨亮。哪一柄最像主人在收剑时强行拧腕，久而久之伤了自己的力路？ | 缺音 · <code>res://art/audio/voices/ch2/ch2_guyun_feng_first_meeting/封砚秋_puzzle.mp3</code> |
| 封砚秋 | [ch2_guyun_feng_first_meeting](../../game/data/dialogs/ch2_guyun_feng_first_meeting.tres) · start · normal | 旧书摊收来三柄断剑。卖剑的人都说是正面硬折，我却觉得其中一柄毁在收势。你若看得出来，替我省一趟冤枉路。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_guyun_feng_first_meeting/封砚秋_start.mp3</code> |
| 封砚秋 | [ch2_guyun_feng_first_meeting](../../game/data/dialogs/ch2_guyun_feng_first_meeting.tres) · wrong · normal | 那是撞上外物留下的伤，不是持剑人的习惯。别看断在哪里，要看力从哪里回到手上。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_guyun_feng_first_meeting/封砚秋_wrong.mp3</code> |
| 悦无姮 | [ch8_relationship_yuewuheng](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) · independent · normal | 好。同行过的路不会因为分开就作废；下次相见，我们仍可把背后交给对方。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_yuewuheng/悦无姮_independent.mp3</code> |
| 悦无姮 | [ch8_relationship_yuewuheng](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) · start · normal | 从竹尾救人到今日公示，我们并肩时最多说的是下一步去哪，很少说路走完以后怎么办。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_yuewuheng/悦无姮_start.mp3</code> |
| 悦无姮 | [ch8_relationship_yuewuheng](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) · together · normal | 那便不定归处。哪里有人拿名号压过事实，我们就往哪里去。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_yuewuheng/悦无姮_together.mp3</code> |
| 戚云笙 | [ch8_relationship_qi_yunsheng](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) · independent · normal | 也好。真正的尊重不是把谁带走。往后你查你的路，我改我的盟，原页仍可互相核验。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_qi_yunsheng/戚云笙_independent.mp3</code> |
| 戚云笙 | [ch8_relationship_qi_yunsheng](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) · start · normal | 我还要留在烈云一段时间，把外部复核真正变成规矩。可我不想余生都只做一块写着“圣姑”的牌位。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_qi_yunsheng/戚云笙_start.mp3</code> |
| 戚云笙 | [ch8_relationship_qi_yunsheng](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) · together · normal | 说定了。不是我放下烈云跟你走，也不是你留下替我守盟；等规矩能离开我们照样运转，再一起出峡谷。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_qi_yunsheng/戚云笙_together.mp3</code> |
| 挑担脚夫 | [huilan_openworld_balance](../../game/data/dialogs/huilan_openworld_balance.tres) · right · normal | 这回肩上像只过了一阵风。原来换力不是把旧劲丢掉，是让它托住下一步。 | 缺音 · <code>res://art/audio/voices/hui/huilan_openworld_balance/挑担脚夫_right.mp3</code> |
| 挑担脚夫 | [huilan_openworld_balance](../../game/data/dialogs/huilan_openworld_balance.tres) · start · normal | 我这肩伤不是担子重，是换肩时总把一头先放死。两筐还在晃，硬换便像有人从背后推我。 | 缺音 · <code>res://art/audio/voices/hui/huilan_openworld_balance/挑担脚夫_start.mp3</code> |
| 挑担脚夫 | [huilan_openworld_balance](../../game/data/dialogs/huilan_openworld_balance.tres) · wrong · normal | 那一下断得太硬，重量全砸在肩上。要让两头的摆势替人换力。 | 缺音 · <code>res://art/audio/voices/hui/huilan_openworld_balance/挑担脚夫_wrong.mp3</code> |
| 捕快韩策 | [ch2_river_death_offer](../../game/data/dialogs/ch2_river_death_offer.tres) · start · normal | 清溪河漂来一具红衣女尸。仵作说泡了三日，身上却没半根水草。你若肯帮忙，先去河埠头看鞋底与衣角。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_river_death_offer/捕快韩策_start.mp3</code> |
| 沈伯 | [ch2_herb_thief_offer](../../game/data/dialogs/ch2_herb_thief_offer.tres) · start · normal | 参田又被刨了，田埂却只有三趾足印。若是山兽，我认；这痕迹偏偏像穿过草鞋。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_herb_thief_offer/沈伯_start.mp3</code> |
| 船夫赵大江 | [ch2_boat_gang_offer](../../game/data/dialogs/ch2_boat_gang_offer.tres) · start · normal | 青龙帮和白鹄帮为泊位打得头破血流。那张漕运批文看着新，墨却旧得不对。你可愿替我查查纸与印？ | 缺音 · <code>res://art/audio/voices/ch2/ch2_boat_gang_offer/船夫赵大江_start.mp3</code> |
| 赵思颖 | [ch8_relationship_zhao_siying](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) · independent · normal | 好。你走江湖，我守医路；遇到不能只靠药或只靠剑的事，再写信给对方。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_zhao_siying/赵思颖_independent.mp3</code> |
| 赵思颖 | [ch8_relationship_zhao_siying](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) · start · normal | 案卷会留在府衙，伤和病却不会等案卷审完。洛阳城外还有很多人，只知道亲人死了，不知道该怎样继续活。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_zhao_siying/赵思颖_start.mp3</code> |
| 赵思颖 | [ch8_relationship_zhao_siying](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) · together · normal | 那就先从下一座没有医馆的驿站开始。剑不必挂起，知道什么时候不拔剑也很重要。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_zhao_siying/赵思颖_together.mp3</code> |

<a id="map-18"></a>
### 竹尾村外 · 北林旧道 · ch2_s2_forest_edge

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 沈伯 | [ch2_herb_thief_complete](../../game/data/dialogs/ch2_herb_thief_complete.tres) · n2 · normal | 那就给它留两垄。人念旧，畜生也念旧。少侠，这些药你带上。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_herb_thief_complete/沈伯_n2.mp3</code> |

<a id="map-19"></a>
### 密林 · 伏击场 · ch2_s3_forest_ambush

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 悦无姮 | [ch2_hideout_intro](../../game/data/dialogs/ch2_hideout_intro.tres) · start · normal | 令牌松脂、北行血点、河滩车辙都在旧矿洞附近交会。三个人各说了一部分真话，也都漏掉了一部分。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_hideout_intro/悦无姮_start.mp3</code> |
| 悦无姮 | [ch2_rescue_victory](../../game/data/dialogs/ch2_rescue_victory.tres) · courier_first · normal | 去吧，伤者交给我。你追回文书后立刻回来，别把追线索变成逞强。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_rescue_victory/悦无姮_courier_first.mp3</code> |
| 悦无姮 | [ch2_rescue_victory](../../game/data/dialogs/ch2_rescue_victory.tres) · n3 · normal | 他们不用烈云盟的合击步，毒烟也不对。令牌只能说明有人想让我们相信它。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_rescue_victory/悦无姮_n3.mp3</code> |
| 悦无姮 | [ch2_rescue_victory](../../game/data/dialogs/ch2_rescue_victory.tres) · rescue_first · normal | 先救人。活人的记忆会乱，却总比死人的沉默多一条路。信使留下的车辙，我记住了。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_rescue_victory/悦无姮_rescue_first.mp3</code> |
| 悦无姮 | [ch2_rescue_victory](../../game/data/dialogs/ch2_rescue_victory.tres) · spoils · normal | 这副竹弩的毒匣已经拆了，机括还能用。听竹叶落地再扣弦——别盯着手，先听风。我只教一遍。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_rescue_victory/悦无姮_spoils.mp3</code> |
| 悦无姮 | [ch2_rescue_victory](../../game/data/dialogs/ch2_rescue_victory.tres) · start · normal | 多谢。我叫悦无姮，凌月派弟子。若你晚来半刻，我未必护得住师妹。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_rescue_victory/悦无姮_start.mp3</code> |

<a id="map-20"></a>
### 凌月派 · 山门 · ch2_s4_lingyue_gate

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 凌霜 | [ch2_lingyue_arrival](../../game/data/dialogs/ch2_lingyue_arrival.tres) · n2 · normal | 五派即将在山下召开武林大会，查议数起命案。你既已卷入，不妨亲眼看看各家证词。 | [语音 1 · 8.7 秒](../../game/art/audio/voices/ch2/ch2_lingyue_arrival/%E5%87%8C%E9%9C%9C_n2_seg01_dialog.mp3)（分段） |
| 凌霜 | [ch2_lingyue_arrival](../../game/data/dialogs/ch2_lingyue_arrival.tres) · start · normal | 你救我门下弟子，也没有拿一块假令牌就给烈云盟定罪。凌月派承你这份情。 | [语音 1 · 7.3 秒](../../game/art/audio/voices/ch2/ch2_lingyue_arrival/%E5%87%8C%E9%9C%9C_start_seg01_dialog.mp3)（分段） |
| 凌月弟子 | [ch2_missing_disciple_complete](../../game/data/dialogs/ch2_missing_disciple_complete.tres) · n2 · normal | 这确是她的腰牌。多谢少侠，我会报给凌霜师姐，也给竹尾客栈捎个平安信。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_missing_disciple_complete/凌月弟子_n2.mp3</code> |
| 守山弟子 | [huilan_openworld_bell](../../game/data/dialogs/huilan_openworld_bell.tres) · right · normal | 停了。你不是消掉风力，只把钟身与钟舌的来势换了先后。这个‘逆’字，比蛮力难学。 | 缺音 · <code>res://art/audio/voices/hui/huilan_openworld_bell/守山弟子_right.mp3</code> |
| 守山弟子 | [huilan_openworld_bell](../../game/data/dialogs/huilan_openworld_bell.tres) · start · normal | 这口旧钟逆风便乱响。门中人总想拉紧钟绳，越拉，钟舌撞得越凶。你若能让它停稳，便替我省下半日。 | 缺音 · <code>res://art/audio/voices/hui/huilan_openworld_bell/守山弟子_start.mp3</code> |
| 守山弟子 | [huilan_openworld_bell](../../game/data/dialogs/huilan_openworld_bell.tres) · wrong · normal | 两股力正好撞在一处，响得更凶。先顺一程，再借回摆。 | 缺音 · <code>res://art/audio/voices/hui/huilan_openworld_bell/守山弟子_wrong.mp3</code> |
| 悦无姮 | [ch2_lingyue_arrival](../../game/data/dialogs/ch2_lingyue_arrival.tres) · n3 · normal | 明日我带你去大会。那里人人都有证词，也人人都有不愿说的部分。今晚先养足精神。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_lingyue_arrival/悦无姮_n3.mp3</code> |

<a id="map-22"></a>
### 北林旧矿洞 · 深处账房 · ch2_s5_mine_command

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 蒙面头领 | [ch2_hideout_battle](../../game/data/dialogs/ch2_hideout_battle.tres) · start · normal · 关联分支 | 账册今夜就烧。你既跟到这里，便和那些多管闲事的人一起留下。 | 缺音 · <code>res://art/audio/voices/ch2/ch2_hideout_battle/蒙面头领_start.mp3</code> |

<a id="map-25"></a>
### 武林大会 · 长案前 · ch3_s1_wulin_assembly

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 凌霜 | [ch3_assembly_intro](../../game/data/dialogs/ch3_assembly_intro.tres) · n3 · normal | 冷孤云带回的令牌崭新无损，与密林死者的旧伤并不相称。他有资格参加考校，也有资格继续查下去。 | [语音 1 · 10.3 秒](../../game/art/audio/voices/ch3/ch3_assembly_intro/%E5%87%8C%E9%9C%9C_n3_seg01_dialog.mp3)（分段） |
| 凌霜 | [ch3_assembly_review](../../game/data/dialogs/ch3_assembly_review.tres) · end · normal | 先通过考校，取得查案资格。往后的证据，你亲自去找。 | [语音 1 · 6.0 秒](../../game/art/audio/voices/ch3/ch3_assembly_review/%E5%87%8C%E9%9C%9C_end_seg01_dialog.mp3)（分段） |
| 大会执事 | [ch3_assembly_review](../../game/data/dialogs/ch3_assembly_review.tres) · start · normal | 伤势仿招、令牌拼旧、旧纸新墨。三处破绽不是答案，却足够证明有人想让五派互相猜疑。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_assembly_review/大会执事_start.mp3</code> |
| 大会执事 | [ch3_assembly_wait](../../game/data/dialogs/ch3_assembly_wait.tres) · start · normal · 关联分支 | 先看长案上的三样证物。别急着猜凶手，只记它们哪里对不上。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_assembly_wait/大会执事_start.mp3</code> |
| 大会执事 | [ch3_luoyang_dispatch](../../game/data/dialogs/ch3_luoyang_dispatch.tres) · start · normal | 洛阳急报：三名死者身份毫无关联，却都接触过同一批运货人。现场另有一封自称烈云盟的密信。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_luoyang_dispatch/大会执事_start.mp3</code> |
| 少林俗家·岳闻钟 | [ch3_assembly_review](../../game/data/dialogs/ch3_assembly_review.tres) · shaolin · normal | 方才你查验伤势时，呼吸有一瞬滞在右肋。那不是今日的新伤。若以后路过嵩山，持这枚木叶到罗汉坡找我——先说清楚，我只替你引路，寺里的法门要靠你自己挣来。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_assembly_review/少林俗家·岳闻钟_shaolin.mp3</code> |
| 悦无姮 | [ch3_lingyue_complete](../../game/data/dialogs/ch3_lingyue_complete.tres) · start · normal | 真正的月纹顺着棍势收势缝制。遗物上那枚反纹，只像一个记得图样却不懂棍路的人仿的。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_lingyue_complete/悦无姮_start.mp3</code> |
| 游方棋客 | [huilan_openworld_board](../../game/data/dialogs/huilan_openworld_board.tres) · right · normal | 让一格，不是白送一格。来势被引偏，原本压你的棋反成了堵住自己的墙。 | 缺音 · <code>res://art/audio/voices/hui/huilan_openworld_board/游方棋客_right.mp3</code> |
| 游方棋客 | [huilan_openworld_board](../../game/data/dialogs/huilan_openworld_board.tres) · start · normal | 这盘棋不问胜负，只问你肯不肯让开。黑子从正面压来，白子若守住眼前两格，三路皆死。 | 缺音 · <code>res://art/audio/voices/hui/huilan_openworld_board/游方棋客_start.mp3</code> |
| 游方棋客 | [huilan_openworld_board](../../game/data/dialogs/huilan_openworld_board.tres) · wrong · normal | 你只盯着不能丢的地方，便替对手把力路铺直了。 | 缺音 · <code>res://art/audio/voices/hui/huilan_openworld_board/游方棋客_wrong.mp3</code> |
| 苏雾笙 | [ch3_assembly_intro](../../game/data/dialogs/ch3_assembly_intro.tres) · n2 · normal | 茗雾亦折损门下。今日各派应先验明证物，再论罪责，免得亲者痛、仇者快。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_assembly_intro/苏雾笙_n2.mp3</code> |

<a id="map-26"></a>
### 武林大会 · 考校场 · ch3_s2_trial_ground

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 大会乐师 | [ch3_canglong_fragment_middle](../../game/data/dialogs/ch3_canglong_fragment_middle.tres) · start · normal | 我重抄旧谱时，发现夹层里还有一页。字不像曲谱，气口却正好藏在减字谱的拍子里。 | [语音 1 · 8.6 秒](../../game/art/audio/voices/ch3/ch3_canglong_fragment_middle/%E5%A4%A7%E4%BC%9A%E4%B9%90%E5%B8%88_start_seg01_dialog.mp3)（分段） |
| 大会乐师 | [ch3_guqin_side](../../game/data/dialogs/ch3_guqin_side.tres) · n3 · normal | 正是！谱子能奏通了。这份抄本送你，权当谢礼。 | [语音 1 · 6.0 秒](../../game/art/audio/voices/ch3/ch3_guqin_side/%E5%A4%A7%E4%BC%9A%E4%B9%90%E5%B8%88_n3_seg01_dialog.mp3)（分段） |
| 大会乐师 | [ch3_guqin_side](../../game/data/dialogs/ch3_guqin_side.tres) · start · normal | 这半页旧谱缺了三处节拍。少侠习武重吐纳，或许能从句读里听出来。 | [语音 1 · 6.9 秒](../../game/art/audio/voices/ch3/ch3_guqin_side/%E5%A4%A7%E4%BC%9A%E4%B9%90%E5%B8%88_start_seg01_dialog.mp3)（分段） |
| 古疆雷 | [ch3_gufeng_complete](../../game/data/dialogs/ch3_gufeng_complete.tres) · start · normal | 不拼蛮力，专打甲片接缝。好！古峰要的是敢上前，也知道怎么回来的人。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_gufeng_complete/古疆雷_start.mp3</code> |
| 封砚秋 | [ch3_guyun_returning_diagram](../../game/data/dialogs/ch3_guyun_returning_diagram.tres) · correct · normal | 卸、引、归，三步一口气。你师门那两式看似朴素，却把“归”字藏得很深。我要去洛阳查几柄同路数的旧剑，若你也去，留心军械铺。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_guyun_returning_diagram/封砚秋_correct.mp3</code> |
| 封砚秋 | [ch3_guyun_returning_diagram](../../game/data/dialogs/ch3_guyun_returning_diagram.tres) · puzzle · normal | 三图分别是：卸去正面来力、引偏剑锋、借空隙回到中线。正确次序是什么？ | 缺音 · <code>res://art/audio/voices/ch3/ch3_guyun_returning_diagram/封砚秋_puzzle.mp3</code> |
| 封砚秋 | [ch3_guyun_returning_diagram](../../game/data/dialogs/ch3_guyun_returning_diagram.tres) · start · normal | 晨市看断剑的人果然来了。大会旧库里有三张回锋残图，顺序被人倒置；排错一步，运劲便会反噬腕脉。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_guyun_returning_diagram/封砚秋_start.mp3</code> |
| 封砚秋 | [ch3_guyun_returning_diagram](../../game/data/dialogs/ch3_guyun_returning_diagram.tres) · wrong · normal | 中线未空便抢着回剑，只会与来势撞在一处。先让手臂活下来，再谈反攻。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_guyun_returning_diagram/封砚秋_wrong.mp3</code> |
| 悦无姮 | [ch3_lingyue_complete](../../game/data/dialogs/ch3_lingyue_complete.tres) · start · normal | 真正的月纹顺着棍势收势缝制。遗物上那枚反纹，只像一个记得图样却不懂棍路的人仿的。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_lingyue_complete/悦无姮_start.mp3</code> |
| 清虚道长 | [ch3_alchemy_trial](../../game/data/dialogs/ch3_alchemy_trial.tres) · retry · normal | 火猛则药焦。先闻香、再看烟，莫把胆气当医理。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_alchemy_trial/清虚道长_retry.mp3</code> |
| 清虚道长 | [ch3_alchemy_trial](../../game/data/dialogs/ch3_alchemy_trial.tres) · start · normal | 新丹药力太烈。古人尝草辨性，靠的不是逞强，而是知止。你可愿替我守这一炉？ | 缺音 · <code>res://art/audio/voices/ch3/ch3_alchemy_trial/清虚道长_start.mp3</code> |
| 清虚道长 | [ch3_alchemy_trial](../../game/data/dialogs/ch3_alchemy_trial.tres) · success · normal | 苦气散而回甘，正是火候。你守住了炉，也守住了分寸。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_alchemy_trial/清虚道长_success.mp3</code> |
| 游方道人 | [ch3_weiqi_side](../../game/data/dialogs/ch3_weiqi_side.tres) · right · normal | 舍小取势，七步反围。斗笠归你，记住今日这手取舍。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_weiqi_side/游方道人_right.mp3</code> |
| 游方道人 | [ch3_weiqi_side](../../game/data/dialogs/ch3_weiqi_side.tres) · start · normal | 白龙被困。你若能救活，这顶旧斗笠便归你。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_weiqi_side/游方道人_start.mp3</code> |
| 游方道人 | [ch3_weiqi_side](../../game/data/dialogs/ch3_weiqi_side.tres) · wrong · normal | 贪一角，便会丢全局。再想。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_weiqi_side/游方道人_wrong.mp3</code> |
| 玄真道长 | [ch3_wudang_complete](../../game/data/dialogs/ch3_wudang_complete.tres) · finish · normal | 可以。绕指柔剑、绵掌与揽雀尾的入门谱都交给你。兼修并不冲突，只是每一重都要另耗历练，莫贪多而不求精。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_wudang_complete/玄真道长_finish.mp3</code> |
| 玄真道长 | [ch3_wudang_complete](../../game/data/dialogs/ch3_wudang_complete.tres) · start · normal | 你看得不错。凶手倒踏旧印，又从另一方向补了掌痕。那套身法是模仿，不是铁证。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_wudang_complete/玄真道长_start.mp3</code> |
| 考校执事 | [ch3_wanderer_complete](../../game/data/dialogs/ch3_wanderer_complete.tres) · finish · normal | 江湖客牌收好。从今日起，多走村镇、多寻武教头，也别错过不留姓名的高人。五类兵器都备得起，五路武功便都学得成。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_wanderer_complete/考校执事_finish.mp3</code> |
| 考校执事 | [ch3_wanderer_complete](../../game/data/dialogs/ch3_wanderer_complete.tres) · start · normal | 你不借师门名望，也过了这一关。大会先给你一册自选散谱，这只决定眼下从哪一门起步，不会锁住以后。各地武教头、奇遇高人与残卷，仍可让你兼学五系。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_wanderer_complete/考校执事_start.mp3</code> |
| 苏雾笙 | [ch3_mingwu_complete](../../game/data/dialogs/ch3_mingwu_complete.tres) · n2 · normal | 各派器物常由同一批匠人承制，相似不足为奇。你能注意到尺寸，观察力可用。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_mingwu_complete/苏雾笙_n2.mp3</code> |
| 论剑执笔人 | [ch3_sword_forum_side](../../game/data/dialogs/ch3_sword_forum_side.tres) · finish · normal | 今日不排名次，只记一句：门户是来处，不是尽头。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_sword_forum_side/论剑执笔人_finish.mp3</code> |
| 论剑执笔人 | [ch3_sword_forum_side](../../game/data/dialogs/ch3_sword_forum_side.tres) · retry · normal | 这样只会各说各话。论剑要让人看见自己原先没看见的东西。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_sword_forum_side/论剑执笔人_retry.mp3</code> |
| 论剑执笔人 | [ch3_sword_forum_side](../../game/data/dialogs/ch3_sword_forum_side.tres) · start · normal | 两派争的是剑快还是气长。你若只许说一句，该怎么劝？ | 缺音 · <code>res://art/audio/voices/ch3/ch3_sword_forum_side/论剑执笔人_start.mp3</code> |
| 霍长空 | [ch3_huashan_complete](../../game/data/dialogs/ch3_huashan_complete.tres) · start · normal | 你以气稳剑、以剑导气，两边弟子都该闭嘴想一想。华山先收下这场和气。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_huashan_complete/霍长空_start.mp3</code> |

<a id="map-27"></a>
### 五派营地·合练场 · ch3_s3_faction_training

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 合练教习 | [ch3_training_battle](../../game/data/dialogs/ch3_training_battle.tres) · start · normal · 关联分支 | 江湖争斗不会等你打完一个再来一个。今日两名同门夹攻，你要学会先破阵眼。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_training_battle/合练教习_start.mp3</code> |
| 合练教习 | [ch3_training_result](../../game/data/dialogs/ch3_training_result.tres) · start · normal | 你没有被人数牵着走。大会证物里的步法却恰恰相反，像是把五派招式硬拼在一起。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_training_result/合练教习_start.mp3</code> |

<a id="map-28"></a>
### 大会后山·封禁石窟 · ch3_s4_forbidden_tomb

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 茗雾暗哨 | [ch3_tomb_battle](../../game/data/dialogs/ch3_tomb_battle.tres) · b · normal · 关联分支 | 封口。一个也不能走出石窟。 | 缺音 · <code>res://art/audio/voices/ch3/ch3_tomb_battle/茗雾暗哨_b.mp3</code> |

<a id="map-29"></a>
### 洛阳 · 南城门 · ch4_s0_luoyang_gate

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 赵思颖 | [ch4_case_clue](../../game/data/dialogs/ch4_case_clue.tres) · c · normal | 码头夜里换了三拨守卫。先救出目击脚夫，才能找到古寺真正的暗门。 | [语音 1 · 7.2 秒](../../game/art/audio/voices/ch4/ch4_case_clue/%E8%B5%B5%E6%80%9D%E9%A2%96_c_seg01_dialog.mp3)（分段） |
| 赵思颖 | [ch4_case_clue](../../game/data/dialogs/ch4_case_clue.tres) · start · normal | 纸张水印来自城外旧寺，药粉却是近三日才配出的。有人在用旧名号包装新案。 | [语音 1 · 8.0 秒](../../game/art/audio/voices/ch4/ch4_case_clue/%E8%B5%B5%E6%80%9D%E9%A2%96_start_seg01_dialog.mp3)（分段） |

<a id="map-30"></a>
### 洛阳 · 府衙外院 · ch4_s1_luoyang_yamen

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 赵思颖 | [ch4_case_clue](../../game/data/dialogs/ch4_case_clue.tres) · c · normal | 码头夜里换了三拨守卫。先救出目击脚夫，才能找到古寺真正的暗门。 | [语音 1 · 7.2 秒](../../game/art/audio/voices/ch4/ch4_case_clue/%E8%B5%B5%E6%80%9D%E9%A2%96_c_seg01_dialog.mp3)（分段） |
| 赵思颖 | [ch4_case_clue](../../game/data/dialogs/ch4_case_clue.tres) · start · normal | 纸张水印来自城外旧寺，药粉却是近三日才配出的。有人在用旧名号包装新案。 | [语音 1 · 8.0 秒](../../game/art/audio/voices/ch4/ch4_case_clue/%E8%B5%B5%E6%80%9D%E9%A2%96_start_seg01_dialog.mp3)（分段） |
| 府尹 | [ch4_yamen_intro](../../game/data/dialogs/ch4_yamen_intro.tres) · b · normal | 你带门派信物而来，便由你查这桩案子。先看卷宗，再去城西问运货人。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_yamen_intro/府尹_b.mp3</code> |
| 府衙老吏 | [huilan_openworld_water_rule](../../game/data/dialogs/huilan_openworld_water_rule.tres) · start · normal | 这方圆形石刻留着含嘉旧水则，谁爱看谁看。上游暴涨时，三道支渠只能开两道；全开则城南倒灌，全关则冲垮正闸。 | 缺音 · <code>res://art/audio/voices/hui/huilan_openworld_water_rule/府衙老吏_start.mp3</code> |
| 府衙老吏 | [huilan_openworld_water_rule](../../game/data/dialogs/huilan_openworld_water_rule.tres) · wrong · normal | 水走得快，不等于城守得住。水则记的是方向，不只是水量。 | 缺音 · <code>res://art/audio/voices/hui/huilan_openworld_water_rule/府衙老吏_wrong.mp3</code> |
| 悦无姮 | [ch8_relationship_yuewuheng](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) · independent · normal | 好。同行过的路不会因为分开就作废；下次相见，我们仍可把背后交给对方。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_yuewuheng/悦无姮_independent.mp3</code> |
| 悦无姮 | [ch8_relationship_yuewuheng](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) · start · normal | 从竹尾救人到今日公示，我们并肩时最多说的是下一步去哪，很少说路走完以后怎么办。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_yuewuheng/悦无姮_start.mp3</code> |
| 悦无姮 | [ch8_relationship_yuewuheng](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) · together · normal | 那便不定归处。哪里有人拿名号压过事实，我们就往哪里去。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_yuewuheng/悦无姮_together.mp3</code> |
| 戚云笙 | [ch8_relationship_qi_yunsheng](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) · independent · normal | 也好。真正的尊重不是把谁带走。往后你查你的路，我改我的盟，原页仍可互相核验。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_qi_yunsheng/戚云笙_independent.mp3</code> |
| 戚云笙 | [ch8_relationship_qi_yunsheng](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) · start · normal | 我还要留在烈云一段时间，把外部复核真正变成规矩。可我不想余生都只做一块写着“圣姑”的牌位。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_qi_yunsheng/戚云笙_start.mp3</code> |
| 戚云笙 | [ch8_relationship_qi_yunsheng](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) · together · normal | 说定了。不是我放下烈云跟你走，也不是你留下替我守盟；等规矩能离开我们照样运转，再一起出峡谷。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_qi_yunsheng/戚云笙_together.mp3</code> |
| 终局案卷吏 | [ch8_aftermath_luoyang](../../game/data/dialogs/ch8_aftermath_luoyang.tres) · end · normal | 已记。府衙只保管其中一份，不拥有最后解释权；民间与门派副本可以随时核对我们的页码和封印。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_aftermath_luoyang/终局案卷吏_end.mp3</code> |
| 终局案卷吏 | [ch8_aftermath_luoyang](../../game/data/dialogs/ch8_aftermath_luoyang.tres) · start · normal | 三份原卷已经分别入库。苏雾笙由洛阳、五派和行义帮共同看押；任何提审都必须三方同时登记。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_aftermath_luoyang/终局案卷吏_start.mp3</code> |
| 赵思颖 | [ch8_relationship_zhao_siying](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) · independent · normal | 好。你走江湖，我守医路；遇到不能只靠药或只靠剑的事，再写信给对方。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_zhao_siying/赵思颖_independent.mp3</code> |
| 赵思颖 | [ch8_relationship_zhao_siying](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) · start · normal | 案卷会留在府衙，伤和病却不会等案卷审完。洛阳城外还有很多人，只知道亲人死了，不知道该怎样继续活。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_zhao_siying/赵思颖_start.mp3</code> |
| 赵思颖 | [ch8_relationship_zhao_siying](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) · together · normal | 那就先从下一座没有医馆的驿站开始。剑不必挂起，知道什么时候不拔剑也很重要。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_zhao_siying/赵思颖_together.mp3</code> |

<a id="map-31"></a>
### 洛阳 · 漕渠码头 · ch4_s2_canal_docks

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 赵思颖 | [ch4_canal_result](../../game/data/dialogs/ch4_canal_result.tres) · b · normal | 他的内伤拖不得，东岸那名信使却正带着余下文书逃走。你我必须立刻分工。 | [语音 1 · 7.8 秒](../../game/art/audio/voices/ch4/ch4_canal_result/%E8%B5%B5%E6%80%9D%E9%A2%96_b_seg01_dialog.mp3)（分段） |
| 失踪脚夫 | [ch4_canal_battle](../../game/data/dialogs/ch4_canal_battle.tres) · start · normal · 关联分支 | 货不是运去仓库，是半夜换船送到城外古寺。他们发现我抄了船号！ | 缺音 · <code>res://art/audio/voices/ch4/ch4_canal_battle/失踪脚夫_start.mp3</code> |
| 失踪脚夫 | [ch4_canal_result](../../game/data/dialogs/ch4_canal_result.tres) · rescue_first · normal | 我记得他们换船的次序，也记得领头人故意亮出烈云盟暗号。只要我活着，就能去府衙作证。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_canal_result/失踪脚夫_rescue_first.mp3</code> |
| 失踪脚夫 | [ch4_canal_result](../../game/data/dialogs/ch4_canal_result.tres) · start · normal | 这是原始货单。收货人用了烈云盟暗号，可押运人的腰牌新得连汗渍都没有。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_canal_result/失踪脚夫_start.mp3</code> |
| 洛阳地痞 | [ch4_canal_battle](../../game/data/dialogs/ch4_canal_battle.tres) · b · normal · 关联分支 | 交出货单。今晚河里多一具尸体，没人会问。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_canal_battle/洛阳地痞_b.mp3</code> |
| 漕工头领 | [ch4_canal_grudge_offer](../../game/data/dialogs/ch4_canal_grudge_offer.tres) · start · normal | 两帮为泊位打得头破血流，可昨夜那批箱子两边都说没接过。你若肯查，先看箱底的泥。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_canal_grudge_offer/漕工头领_start.mp3</code> |
| 漕工头领 | [ch4_canal_grudge_turnin](../../game/data/dialogs/ch4_canal_grudge_turnin.tres) · end · normal | 中间人跑了，假契还在。两帮先停手，把伤者送医。这副玄铜拳套是旧漕卒压舱护身的物件，你替我们止住械斗，便收下吧。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_canal_grudge_turnin/漕工头领_end.mp3</code> |
| 漕工头领 | [ch4_city_tasks_20261016_canal_after](../../game/data/dialogs/luoyang_city_tasks_20261016/canal_after.tres) · start · normal · 关联分支 | 两边已把伤者送去医治，往后的货契也要当面核验。幕后是谁还得查，但不能再让漕工替人流血。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_city_tasks_20261016_canal_after/漕工头领_start.mp3</code> |
| 漕工头领 | [ch4_city_tasks_20261016_canal_offer](../../game/data/dialogs/luoyang_city_tasks_20261016/canal_offer.tres) · accepted · normal | 先去问东边的老漕卒。他昨夜守过栈桥，能分清货是从水上来，还是从仓巷拖出来的。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_city_tasks_20261016_canal_offer/漕工头领_accepted.mp3</code> |
| 漕工头领 | [ch4_city_tasks_20261016_canal_offer](../../game/data/dialogs/luoyang_city_tasks_20261016/canal_offer.tres) · offer · normal | 两帮为泊位争得厉害，昨夜那批货却谁也不认。我得留在这里照看伤者，想请你替我们查清来路。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_city_tasks_20261016_canal_offer/漕工头领_offer.mp3</code> |
| 漕工头领 | [ch4_city_tasks_20261016_canal_progress](../../game/data/dialogs/luoyang_city_tasks_20261016/canal_progress.tres) · start · normal · 关联分支 | 我会在货场等你。先问老漕卒昨夜的动静，再沿他的线索去查废仓；这里堆的只是待运货，不是要你找的证物。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_city_tasks_20261016_canal_progress/漕工头领_start.mp3</code> |
| 漕工头领 | [ch4_city_tasks_20261016_canal_report](../../game/data/dialogs/luoyang_city_tasks_20261016/canal_report.tres) · report · normal | 中间人不见了，假契和泥样却抵赖不了。两帮先停手，把伤者送医。这副玄铜拳套是旧漕卒压舱护身的物件，便作你止住械斗的谢礼。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_city_tasks_20261016_canal_report/漕工头领_report.mp3</code> |
| 老漕卒 | [ch4_city_tasks_20261016_hanjia_after](../../game/data/dialogs/luoyang_city_tasks_20261016/hanjia_after.tres) · start · normal · 关联分支 | 旧刃重见天日，守粮同袍的污名也该洗清了。码头的后生还在走这条水路，旧事不该只剩传言。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_city_tasks_20261016_hanjia_after/老漕卒_start.mp3</code> |
| 老漕卒 | [ch4_city_tasks_20261016_hanjia_offer](../../game/data/dialogs/luoyang_city_tasks_20261016/hanjia_offer.tres) · accepted · normal | 看刀背，不要只认刀鞘。旧主人的事，不能再让旁人随口定论。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_city_tasks_20261016_hanjia_offer/老漕卒_accepted.mp3</code> |
| 老漕卒 | [ch4_city_tasks_20261016_hanjia_offer](../../game/data/dialogs/luoyang_city_tasks_20261016/hanjia_offer.tres) · start · normal | 那把旧刀不是帮派信物，是守仓卒的佩刀。十八年前人失踪了，刀却在这几夜又被人拿来挑事。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_city_tasks_20261016_hanjia_offer/老漕卒_start.mp3</code> |
| 老漕卒 | [ch4_city_tasks_20261016_hanjia_progress](../../game/data/dialogs/luoyang_city_tasks_20261016/hanjia_progress.tres) · start · normal · 关联分支 | 那把旧刀的来历，仍要到废水则碑旁查。若能看清刀背铭文，就能知道旧主人到底守住了什么。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_city_tasks_20261016_hanjia_progress/老漕卒_start.mp3</code> |
| 老漕卒 | [ch4_hanjia_blade_offer](../../game/data/dialogs/ch4_hanjia_blade_offer.tres) · start · normal | 那把旧刀不是帮派信物，是守仓卒的佩刀。十八年前人失踪了，刀却在这几夜又被人拿来挑事。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_hanjia_blade_offer/老漕卒_start.mp3</code> |

<a id="map-32"></a>
### 洛阳 · 南市 · ch4_s3_luoyang_market

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 赵思颖 | [ch4_heal_veteran_offer](../../game/data/dialogs/ch4_heal_veteran_offer.tres) · start · normal | 城外老卒旧伤复发，寻常止血药压不住。古寺背阴石缝里有一味石菖蒲。 | [语音 1 · 7.8 秒](../../game/art/audio/voices/ch4/ch4_heal_veteran_offer/%E8%B5%B5%E6%80%9D%E9%A2%96_start_seg01_dialog.mp3)（分段） |
| 封砚秋 | [ch4_guyun_sword_notches](../../game/data/dialogs/ch4_guyun_sword_notches.tres) · correct · normal | 正是斜线。三种兵器看似三种答案，其实都在问同一件事：旧力已尽，新力未生。茗雾外院有一份更早的兵谱目录，我得回去确认它是否还在。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_guyun_sword_notches/封砚秋_correct.mp3</code> |
| 封砚秋 | [ch4_guyun_sword_notches](../../game/data/dialogs/ch4_guyun_sword_notches.tres) · puzzle · normal | 若依次对应长棍、暗器、重刀，林西剑法该在哪一道痕前先收锋、再换力？ | 缺音 · <code>res://art/audio/voices/ch4/ch4_guyun_sword_notches/封砚秋_puzzle.mp3</code> |
| 封砚秋 | [ch4_guyun_sword_notches](../../game/data/dialogs/ch4_guyun_sword_notches.tres) · start · normal | 洛阳军械铺留着三道试兵痕：宽钝凹槽、细密连点、贴着旧痕滑开的斜线。有人把批注撕了，只能从痕迹还原三次交手。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_guyun_sword_notches/封砚秋_start.mp3</code> |
| 封砚秋 | [ch4_guyun_sword_notches](../../game/data/dialogs/ch4_guyun_sword_notches.tres) · wrong · normal | 那样仍是在拿剑刃和兵器比硬。你师门的路数不抢第一下，它等的是对方不得不换力的那一刻。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_guyun_sword_notches/封砚秋_wrong.mp3</code> |
| 左明远 | [ch4_city_tasks_20261016_paper_after](../../game/data/dialogs/luoyang_city_tasks_20261016/paper_after.tres) · start · normal · 关联分支 | 青白藤纸已够我誊抄这批案卷。以后若纸坊再缺料，我们先相互照应，总不能让一场连雨断了读书人的笔。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_city_tasks_20261016_paper_after/左明远_start.mp3</code> |
| 左明远 | [ch4_city_tasks_20261016_paper_offer](../../game/data/dialogs/luoyang_city_tasks_20261016/paper_offer.tres) · offer · normal | 若你愿意帮忙，先问纸摊的老纸匠。他知道哪处旧纸坊还留着可用的藤皮。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_city_tasks_20261016_paper_offer/左明远_offer.mp3</code> |
| 左明远 | [ch4_city_tasks_20261016_paper_offer](../../game/data/dialogs/luoyang_city_tasks_20261016/paper_offer.tres) · start · normal | 洛阳文章多，纸价也跟着涨。如今我只求一叠能抄案卷的藤纸，偏偏连雨断了纸坊原料。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_city_tasks_20261016_paper_offer/左明远_start.mp3</code> |
| 左明远 | [ch4_city_tasks_20261016_paper_progress](../../game/data/dialogs/luoyang_city_tasks_20261016/paper_progress.tres) · start · normal · 关联分支 | 老纸匠就在纸铺前，我会在这里等消息。先问清能用的原料放在哪里，莫到旁人的货箱里乱翻。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_city_tasks_20261016_paper_progress/左明远_start.mp3</code> |
| 左明远 | [ch4_city_tasks_20261016_paper_report](../../game/data/dialogs/luoyang_city_tasks_20261016/paper_report.tres) · paper · normal | 多谢。我请人把料送去纸铺，你且稍候。木模的夹层也松了，里面似乎还夹着一页旧纸。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_city_tasks_20261016_paper_report/左明远_paper.mp3</code> |
| 左明远 | [ch4_luoyang_paper_offer](../../game/data/dialogs/ch4_luoyang_paper_offer.tres) · start · normal | 洛阳文章多，纸价也跟着涨。人说左思《三都赋》写成后洛阳纸贵，如今我只求一叠能抄案卷的藤纸。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_luoyang_paper_offer/左明远_start.mp3</code> |
| 老纸匠 | [ch4_city_tasks_20261016_paper_ready](../../game/data/dialogs/luoyang_city_tasks_20261016/paper_ready.tres) · start · normal · 关联分支 | 既找到了干藤皮和木模，就先回左明远那里报个信。东西交到纸铺，我便替他赶制藤纸。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_city_tasks_20261016_paper_ready/老纸匠_start.mp3</code> |
| 诗会执事 | [ch4_peony_poetry](../../game/data/dialogs/ch4_peony_poetry.tres) · retry · normal | 花在城中开，也在市井开。再想想洛阳为何记得它。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_peony_poetry/诗会执事_retry.mp3</code> |
| 诗会执事 | [ch4_peony_poetry](../../game/data/dialogs/ch4_peony_poetry.tres) · start · normal | 洛阳人爱牡丹，今日不比辞藻，只续一句：花开动城，花落又当如何？ | 缺音 · <code>res://art/audio/voices/ch4/ch4_peony_poetry/诗会执事_start.mp3</code> |
| 诗会执事 | [ch4_peony_poetry](../../game/data/dialogs/ch4_peony_poetry.tres) · success · normal | 好。不是把典故背出来，而是把城里人的心意接住了。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_peony_poetry/诗会执事_success.mp3</code> |
| 诗会执事 | [luoyang_layout_quest_20261018t/peony_after](../../game/data/dialogs/luoyang_layout_quest_20261018t/peony_after.tres) · start · normal · 关联分支 | 你的续句已收在诗册里。花期虽短，城里总有人记得。 | 缺音 · <code>res://art/audio/voices/luo/luoyang_layout_quest_20261018t/peony_after/诗会执事_start.mp3</code> |
| 诗会执事 | [luoyang_layout_quest_20261018t/peony_investigate](../../game/data/dialogs/luoyang_layout_quest_20261018t/peony_investigate.tres) · choice · normal | 花开动城，花落又当如何？ | 缺音 · <code>res://art/audio/voices/luo/luoyang_layout_quest_20261018t/peony_investigate/诗会执事_choice.mp3</code> |
| 诗会执事 | [luoyang_layout_quest_20261018t/peony_investigate](../../game/data/dialogs/luoyang_layout_quest_20261018t/peony_investigate.tres) · retry · normal | 花在城中开，也在市井开。再想想洛阳为何记得它。 | 缺音 · <code>res://art/audio/voices/luo/luoyang_layout_quest_20261018t/peony_investigate/诗会执事_retry.mp3</code> |
| 诗会执事 | [luoyang_layout_quest_20261018t/peony_investigate](../../game/data/dialogs/luoyang_layout_quest_20261018t/peony_investigate.tres) · success · normal | 好。不是把典故背出来，而是把城里人的心意接住了。我先把续句录下，你再来取诗会彩头。 | 缺音 · <code>res://art/audio/voices/luo/luoyang_layout_quest_20261018t/peony_investigate/诗会执事_success.mp3</code> |
| 诗会执事 | [luoyang_layout_quest_20261018t/peony_offer](../../game/data/dialogs/luoyang_layout_quest_20261018t/peony_offer.tres) · offer · normal | 洛阳人爱牡丹，今日不比辞藻，只续一句：花开动城，花落又当如何？愿意入会作答么？ | 缺音 · <code>res://art/audio/voices/luo/luoyang_layout_quest_20261018t/peony_offer/诗会执事_offer.mp3</code> |
| 诗会执事 | [luoyang_layout_quest_20261018t/peony_progress](../../game/data/dialogs/luoyang_layout_quest_20261018t/peony_progress.tres) · start · normal · 关联分支 | 续句想好了便正式作答；记得写花，也写城里记花的人。 | 缺音 · <code>res://art/audio/voices/luo/luoyang_layout_quest_20261018t/peony_progress/诗会执事_start.mp3</code> |
| 诗会执事 | [luoyang_layout_quest_20261018t/peony_report](../../game/data/dialogs/luoyang_layout_quest_20261018t/peony_report.tres) · report · normal | 你的续句已经录入诗册。这份彩头归你，愿你日后仍记得花落之后的一城人心。 | 缺音 · <code>res://art/audio/voices/luo/luoyang_layout_quest_20261018t/peony_report/诗会执事_report.mp3</code> |

<a id="map-33"></a>
### 洛阳城外 · 古寺 · ch4_s4_ancient_temple

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 赵思颖 | [ch4_heal_veteran_turnin](../../game/data/dialogs/ch4_heal_veteran_turnin.tres) · end · normal | 药够了。老卒醒后说，护身符留给真正肯回头救人的人。 | [语音 1 · 5.9 秒](../../game/art/audio/voices/ch4/ch4_heal_veteran_turnin/%E8%B5%B5%E6%80%9D%E9%A2%96_end_seg01_dialog.mp3)（分段） |
| 赵思颖 | [ch4_tunnel_intro](../../game/data/dialogs/ch4_tunnel_intro.tres) · start · normal | 正殿香灰下有新鲜车轮印，墙后还透着风。这里运货靠的不是寺门，是地道。 | [语音 1 · 8.2 秒](../../game/art/audio/voices/ch4/ch4_tunnel_intro/%E8%B5%B5%E6%80%9D%E9%A2%96_start_seg01_dialog.mp3)（分段） |
| 守窟僧 | [ch4_longmen_mystery](../../game/data/dialogs/ch4_longmen_mystery.tres) · end · normal | 怪声解了，旧工匠留下的排水图也保住了。传说有趣，真相同样值得留下。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_longmen_mystery/守窟僧_end.mp3</code> |
| 守窟僧 | [ch4_longmen_mystery](../../game/data/dialogs/ch4_longmen_mystery.tres) · start · normal | 石壁每逢夜雨便响，游人说是龙门显灵。我只怕有人借声掩门。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_longmen_mystery/守窟僧_start.mp3</code> |
| 守窟僧 | [luoyang_layout_quest_20261018t/longmen_after](../../game/data/dialogs/luoyang_layout_quest_20261018t/longmen_after.tres) · start · normal · 关联分支 | 水槽已清，排水图也收好了。往后再有雨声，寺里人知道该看哪里。 | 缺音 · <code>res://art/audio/voices/luo/luoyang_layout_quest_20261018t/longmen_after/守窟僧_start.mp3</code> |
| 守窟僧 | [luoyang_layout_quest_20261018t/longmen_offer](../../game/data/dialogs/luoyang_layout_quest_20261018t/longmen_offer.tres) · offer · normal | 石壁每逢夜雨便响，游人说是龙门显灵。我只怕有人借声掩门。你可愿替我查清水槽与暗缝？ | 缺音 · <code>res://art/audio/voices/luo/luoyang_layout_quest_20261018t/longmen_offer/守窟僧_offer.mp3</code> |
| 守窟僧 | [luoyang_layout_quest_20261018t/longmen_progress](../../game/data/dialogs/luoyang_layout_quest_20261018t/longmen_progress.tres) · start · normal · 关联分支 | 先看石壁脚下的水槽，再看铜钱落回哪一道暗缝。没有查明机关，我也不敢封门。 | 缺音 · <code>res://art/audio/voices/luo/luoyang_layout_quest_20261018t/longmen_progress/守窟僧_start.mp3</code> |
| 守窟僧 | [luoyang_layout_quest_20261018t/longmen_report](../../game/data/dialogs/luoyang_layout_quest_20261018t/longmen_report.tres) · report · normal | 原来是旧工匠留下的水位机关。怪声解了，排水图也能妥善收存。传说有趣，真相同样值得留下。 | 缺音 · <code>res://art/audio/voices/luo/luoyang_layout_quest_20261018t/longmen_report/守窟僧_report.mp3</code> |
| 守钟僧 | [ch4_baima_bell](../../game/data/dialogs/ch4_baima_bell.tres) · retry · normal | 一夜无人，钟却又响了。若不是人推，便看风从哪里来。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_baima_bell/守钟僧_retry.mp3</code> |
| 守钟僧 | [ch4_baima_bell](../../game/data/dialogs/ch4_baima_bell.tres) · start · normal | 古钟连夜自鸣。寺中不怕鬼神，只怕有人借鬼神伤人。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_baima_bell/守钟僧_start.mp3</code> |
| 守钟僧 | [ch4_baima_bell](../../game/data/dialogs/ch4_baima_bell.tres) · success · normal | 纸角在裂缝处连颤三次。补缝之后，古钟终于安静。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_baima_bell/守钟僧_success.mp3</code> |
| 守钟僧 | [luoyang_layout_quest_20261018t/baima_after](../../game/data/dialogs/luoyang_layout_quest_20261018t/baima_after.tres) · start · normal · 关联分支 | 东墙补过之后，古钟再没有无故自鸣。 | 缺音 · <code>res://art/audio/voices/luo/luoyang_layout_quest_20261018t/baima_after/守钟僧_start.mp3</code> |
| 守钟僧 | [luoyang_layout_quest_20261018t/baima_offer](../../game/data/dialogs/luoyang_layout_quest_20261018t/baima_offer.tres) · offer · normal | 古钟连夜自鸣。寺中不怕鬼神，只怕有人借鬼神伤人。你可愿替我查梁木、钟杵与东墙砖缝？ | 缺音 · <code>res://art/audio/voices/luo/luoyang_layout_quest_20261018t/baima_offer/守钟僧_offer.mp3</code> |
| 守钟僧 | [luoyang_layout_quest_20261018t/baima_progress](../../game/data/dialogs/luoyang_layout_quest_20261018t/baima_progress.tres) · start · normal · 关联分支 | 先别守着钟杵等人。钟楼没有脚印，看看风是否从东墙砖缝里钻进来。 | 缺音 · <code>res://art/audio/voices/luo/luoyang_layout_quest_20261018t/baima_progress/守钟僧_start.mp3</code> |
| 守钟僧 | [luoyang_layout_quest_20261018t/baima_report](../../game/data/dialogs/luoyang_layout_quest_20261018t/baima_report.tres) · report · normal | 薄纸既在东墙连颤三次，便不是人推钟杵。把暗缝补好，今夜古钟应能安静。多谢少侠。 | 缺音 · <code>res://art/audio/voices/luo/luoyang_layout_quest_20261018t/baima_report/守钟僧_report.mp3</code> |
| 老纸匠 | [ch4_luoyang_paper_turnin](../../game/data/dialogs/ch4_luoyang_paper_turnin.tres) · start · normal | 旧货箱的藤皮能用。你带来的这块水印木模也怪，鱼鳞纹是十八年前那批官纸才有的。 | 缺音 · <code>res://art/audio/voices/ch4/ch4_luoyang_paper_turnin/老纸匠_start.mp3</code> |

<a id="map-34"></a>
### 古寺·地下运货道 · ch4_s5_temple_tunnel

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 赵思颖 | [ch4_tunnel_result](../../game/data/dialogs/ch4_tunnel_result.tres) · start · normal | 首领还活着。地道里的印版、药粉和账册足以证明有人系统地伪造各派身份。 | [语音 1 · 7.9 秒](../../game/art/audio/voices/ch4/ch4_tunnel_result/%E8%B5%B5%E6%80%9D%E9%A2%96_start_seg01_dialog.mp3)（分段） |

<a id="map-35"></a>
### 古峰 · 赈粮路 · ch5_s1_relief_road

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 古峰护粮守卫 | [ch5_relief_road_victory](../../game/data/dialogs/ch5_relief_road_victory.tres) · start · normal | 多谢少侠。前营还有两车粮和十几名脚夫，他们若再被围，山上今晚就要断炊。 | 缺音 · <code>res://art/audio/voices/ch5/ch5_relief_road_victory/古峰护粮守卫_start.mp3</code> |
| 雪路劫粮客 | [ch5_relief_road_battle](../../game/data/dialogs/ch5_relief_road_battle.tres) · start · normal · 关联分支 | 粮车留下，人可以滚。山上的灾民饿不饿，与我们无关。 | 缺音 · <code>res://art/audio/voices/ch5/ch5_relief_road_battle/雪路劫粮客_start.mp3</code> |

<a id="map-36"></a>
### 古峰 · 护粮营地 · ch5_s2_grain_convoy_camp

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 伪烈云突袭手 | [ch5_grain_convoy_battle](../../game/data/dialogs/ch5_grain_convoy_battle.tres) · start · normal · 关联分支 | 烈云盟办事，不留活口。挡路的连同粮车一起烧。 | 缺音 · <code>res://art/audio/voices/ch5/ch5_grain_convoy_battle/伪烈云突袭手_start.mp3</code> |
| 古峰护粮守卫 | [ch5_false_banner_evidence](../../game/data/dialogs/ch5_false_banner_evidence.tres) · b · normal | 也就是说，这些人故意让我们以为是烈云盟来抢粮？ | 缺音 · <code>res://art/audio/voices/ch5/ch5_false_banner_evidence/古峰护粮守卫_b.mp3</code> |
| 古峰护粮守卫 | [ch5_grain_convoy_intro](../../game/data/dialogs/ch5_grain_convoy_intro.tres) · start · normal · 关联分支 | 他们穿着烈云盟衣裳，却专挑粮车和脚夫下手。真要寻仇，何必先断灾民口粮？ | 缺音 · <code>res://art/audio/voices/ch5/ch5_grain_convoy_intro/古峰护粮守卫_start.mp3</code> |
| 古峰护粮守卫 | [ch5_grain_convoy_victory](../../game/data/dialogs/ch5_grain_convoy_victory.tres) · start · normal | 脚夫都在，粮也只烧坏一角。那面破旗是领头人撤退时扯落的。 | 缺音 · <code>res://art/audio/voices/ch5/ch5_grain_convoy_victory/古峰护粮守卫_start.mp3</code> |

<a id="map-37"></a>
### 古峰 · 雪岭关 · ch5_s3_snow_pass

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 唐行舟 | [ch5_snow_pass_intro](../../game/data/dialogs/ch5_snow_pass_intro.tres) · start · normal | 这条雪路只够两人并肩。前头那几处新扎的火纹旗，像是故意让山下看见。 | 缺音 · <code>res://art/audio/voices/ch5/ch5_snow_pass_intro/唐行舟_start.mp3</code> |
| 沈青禾 | [ch5_snow_pass_victory](../../game/data/dialogs/ch5_snow_pass_victory.tres) · start · normal | 他们退得太齐，不像溃败，倒像完成了拖延。矿道里的人恐怕已经遇险。 | 缺音 · <code>res://art/audio/voices/ch5/ch5_snow_pass_victory/沈青禾_start.mp3</code> |
| 雪岭追兵 | [ch5_snow_pass_battle](../../game/data/dialogs/ch5_snow_pass_battle.tres) · start · normal · 关联分支 | 烈云盟封路，外人退下！再往前一步，便把命留在雪里。 | 缺音 · <code>res://art/audio/voices/ch5/ch5_snow_pass_battle/雪岭追兵_start.mp3</code> |

<a id="map-38"></a>
### 古峰 · 废弃矿道 · ch5_s4_abandoned_mine

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 沈青禾 | [ch5_mine_hunter_victory](../../game/data/dialogs/ch5_mine_hunter_victory.tres) · start · normal | 追兵倒下以后，左侧作业间的矿灯仍在晃。那里的人一直听着。 | 缺音 · <code>res://art/audio/voices/ch5/ch5_mine_hunter_victory/沈青禾_start.mp3</code> |
| 矿道灭口人 | [ch5_mine_hunter_battle](../../game/data/dialogs/ch5_mine_hunter_battle.tres) · start · normal · 关联分支 | 旧矿早塌了，哪里还有活口。你们若肯转身，今夜就当没见过我们。 | 缺音 · <code>res://art/audio/voices/ch5/ch5_mine_hunter_battle/矿道灭口人_start.mp3</code> |

<a id="map-39"></a>
### 古峰 · 伪旗营地 · ch5_s5_false_banner_outpost

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 伪旗统领 | [ch5_false_banner_boss_victory](../../game/data/dialogs/ch5_false_banner_boss_victory.tres) · b · weary | 你以为证明旗是假的，烈云就干净了？他们当年也截错过货队，毒死过不该死的人。 | 缺音 · <code>res://art/audio/voices/ch5/ch5_false_banner_boss_victory/伪旗统领_b.mp3</code> |
| 唐行舟 | [ch5_disclosure_choice](../../game/data/dialogs/ch5_disclosure_choice.tres) · publish · normal | 那就只写已经核实的部分：伪旗、毒粉、赈粮和灭口。烈云旧债另列一卷，等证词补齐再公示。 | 缺音 · <code>res://art/audio/voices/ch5/ch5_disclosure_choice/唐行舟_publish.mp3</code> |
| 唐行舟 | [ch5_false_banner_boss_victory](../../game/data/dialogs/ch5_false_banner_boss_victory.tres) · d · normal | 封蜡匣里只有三项差事，落款被割得太干净。眼下足以拆穿伪旗，却还不能把最终发令者钉死。 | 缺音 · <code>res://art/audio/voices/ch5/ch5_false_banner_boss_victory/唐行舟_d.mp3</code> |
| 唐行舟 | [ch5_false_banner_outpost_intro](../../game/data/dialogs/ch5_false_banner_outpost_intro.tres) · start · solemn | 矿道北壁的风从这边灌下去。兵器台还没来得及收，山顶那座校场倒站得齐整。 | 缺音 · <code>res://art/audio/voices/ch5/ch5_false_banner_outpost_intro/唐行舟_start.mp3</code> |
| 沈青禾 | [ch5_disclosure_choice](../../game/data/dialogs/ch5_disclosure_choice.tres) · hold · angry | 先把活人送下山。谁敢说你在包庇，我替你把两份卷宗都拍到他桌上——一份栽赃，一份旧债，谁也别想少。 | 缺音 · <code>res://art/audio/voices/ch5/ch5_disclosure_choice/沈青禾_hold.mp3</code> |
| 沈青禾 | [ch5_false_banner_poisoned_weapons](../../game/data/dialogs/ch5_false_banner_poisoned_weapons.tres) · start · concerned | 刀槽里的粉不是风雪。沾水后发黏，会拖住伤口凝血；可这股药味和烈云火炼毒完全不同。 | 缺音 · <code>res://art/audio/voices/ch5/ch5_false_banner_poisoned_weapons/沈青禾_start.mp3</code> |

<a id="map-40"></a>
### 林西村 · 地下档案室 · ch6_s3_underground_archive

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 茗雾焚册客 | [ch6_archive_prebattle](../../game/data/dialogs/ch6_archive_prebattle.tres) · fight · threat | 他认得封蜡。动手，别让他带一页出去。 | 缺音 · <code>res://art/audio/voices/ch6/ch6_archive_prebattle/茗雾焚册客_fight.mp3</code> |
| 茗雾销卷使 | [ch6_archive_prebattle](../../game/data/dialogs/ch6_archive_prebattle.tres) · start · threat | 退回去。这些只是抄错的废册，留着只会让更多人拿假名字互相寻仇。 | 缺音 · <code>res://art/audio/voices/ch6/ch6_archive_prebattle/茗雾销卷使_start.mp3</code> |

<a id="map-44"></a>
### 烈云峡谷 · 旧渡 · ch7_s1_lieyun_valley_ferry

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 旧渡守望 | [ch7_lieyun_arrival](../../game/data/dialogs/ch7_lieyun_arrival.tres) · guard · solemn | 玉佩是真的。你可以查外渡，也可以问这里的人；但进内门之前，我们同样要核对你带来的原册。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_lieyun_arrival/旧渡守望_guard.mp3</code> |
| 旧渡守望 | [ch7_outer_routes_open](../../game/data/dialogs/ch7_outer_routes_open.tres) · open · normal | 烈云分舵外区与茗雾山庄外院同时开放。调查顺序会改变对方的防备，但不会阻断取证。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_outer_routes_open/旧渡守望_open.mp3</code> |

<a id="map-45"></a>
### 茗雾山 · 茶镇 · ch7_s2_mingwu_tea_town

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 茶镇经手人 | [ch7_mingwu_arrival](../../game/data/dialogs/ch7_mingwu_arrival.tres) · broker · normal | 客人若为买茶，镇上处处可看；若问十八年前的换车簿，须等外院核验身份。近日假文书太多。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_mingwu_arrival/茶镇经手人_broker.mp3</code> |
| 茶镇经手人 | [ch7_outer_routes_open](../../game/data/dialogs/ch7_outer_routes_open.tres) · open · normal | 烈云分舵外区与茗雾山庄外院同时开放。调查顺序会改变对方的防备，但不会阻断取证。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_outer_routes_open/茶镇经手人_open.mp3</code> |

<a id="map-46"></a>
### 烈云分舵 · 外区 · ch7_s3_lieyun_outpost_outer_ward

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 聚义厅引路人 | [ch7_inner_routes_open](../../game/data/dialogs/ch7_inner_routes_open.tres) · open · normal | 烈云聚义厅与茗雾山庄内院同时开放。任何一份证词都必须与既有物证核对。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_inner_routes_open/聚义厅引路人_open.mp3</code> |

<a id="map-47"></a>
### 茗雾山庄 · 外院 · ch7_s4_mingwu_manor_outer_court

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 外院录事 | [ch7_inner_routes_open](../../game/data/dialogs/ch7_inner_routes_open.tres) · open · normal | 烈云聚义厅与茗雾山庄内院同时开放。任何一份证词都必须与既有物证核对。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_inner_routes_open/外院录事_open.mp3</code> |
| 封砚秋 | [ch7_guyun_mingwu_catalog](../../game/data/dialogs/ch7_guyun_mingwu_catalog.tres) · correct · normal | 乙本。缺失那页原本记着一门旧剑法的全名，余下只剩“孤云”二字和刑樊天师门的旧印。我会保住目录；若我们都活着离开茗雾，带它回林西问他。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_guyun_mingwu_catalog/封砚秋_correct.mp3</code> |
| 封砚秋 | [ch7_guyun_mingwu_catalog](../../game/data/dialogs/ch7_guyun_mingwu_catalog.tres) · puzzle · normal | 甲本封蜡崭新、页码连续；乙本旧蜡开裂、缺一页但穿线孔方向始终一致；丙本没有封蜡，页次被重新抄齐。哪一本最可能是未改过的原目录？ | 缺音 · <code>res://art/audio/voices/ch7/ch7_guyun_mingwu_catalog/封砚秋_puzzle.mp3</code> |
| 封砚秋 | [ch7_guyun_mingwu_catalog](../../game/data/dialogs/ch7_guyun_mingwu_catalog.tres) · start · normal | 我没有在晨市说实话。我是茗雾外院录事，负责把旧谱改名、拆卷、重新编号。有人命我烧掉这三份目录，我只来得及藏下一份真本。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_guyun_mingwu_catalog/封砚秋_start.mp3</code> |
| 封砚秋 | [ch7_guyun_mingwu_catalog](../../game/data/dialogs/ch7_guyun_mingwu_catalog.tres) · wrong · normal | 重抄最容易做得整齐。原物反而会留下缺页、旧孔和修补，只要这些痕迹彼此说得通。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_guyun_mingwu_catalog/封砚秋_wrong.mp3</code> |

<a id="map-48"></a>
### 烈云分舵 · 聚义厅 · ch7_s5_lieyun_assembly_hall

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 悦无姮 | [ch8_relationship_yuewuheng](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) · independent · normal | 好。同行过的路不会因为分开就作废；下次相见，我们仍可把背后交给对方。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_yuewuheng/悦无姮_independent.mp3</code> |
| 悦无姮 | [ch8_relationship_yuewuheng](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) · start · normal | 从竹尾救人到今日公示，我们并肩时最多说的是下一步去哪，很少说路走完以后怎么办。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_yuewuheng/悦无姮_start.mp3</code> |
| 悦无姮 | [ch8_relationship_yuewuheng](../../game/data/dialogs/ch8_relationship_yuewuheng.tres) · together · normal | 那便不定归处。哪里有人拿名号压过事实，我们就往哪里去。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_yuewuheng/悦无姮_together.mp3</code> |
| 戚云笙 | [ch7_authorization_routes_open](../../game/data/dialogs/ch7_authorization_routes_open.tres) · start · normal | 既然人是薛影，下一问就是谁让一个死者继续通行。复核印底卷和夜航路包都还在，先查机构授权与行动目标。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_authorization_routes_open/戚云笙_start.mp3</code> |
| 戚云笙 | [ch7_dead_code_routes_open](../../game/data/dialogs/ch7_dead_code_routes_open.tres) · start · solemn | 录事说的是内门暗号，就一定有登记人与注销日。聚义厅后档还保存旧渡副签，两边合起来，才能知道“死者权限”活了多久。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_dead_code_routes_open/戚云笙_start.mp3</code> |
| 戚云笙 | [ch7_disclosure_strategy_choice](../../game/data/dialogs/ch7_disclosure_strategy_choice.tres) · choice · normal | 第七章证据如何公开？ | 缺音 · <code>res://art/audio/voices/ch7/ch7_disclosure_strategy_choice/戚云笙_choice.mp3</code> |
| 戚云笙 | [ch7_disclosure_strategy_choice](../../game/data/dialogs/ch7_disclosure_strategy_choice.tres) · converge · normal | 证据按你的方式出峡谷。下一步，是去问苏雾笙：她想用这些真实旧罪，把江湖推到哪里。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_disclosure_strategy_choice/戚云笙_converge.mp3</code> |
| 戚云笙 | [ch7_disclosure_strategy_choice](../../game/data/dialogs/ch7_disclosure_strategy_choice.tres) · start · normal | 烈云旧罪、薛影身份、内署授权和证人安置都已成卷。现在决定公开多少、何时公开。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_disclosure_strategy_choice/戚云笙_start.mp3</code> |
| 戚云笙 | [ch7_identity_routes_open](../../game/data/dialogs/ch7_identity_routes_open.tres) · start · normal | 权限归属只是第一层。去审验两枚复核印，再把死后每次换马、过渡和封包排成一条线；旧教习也愿意当面辨认。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_identity_routes_open/戚云笙_start.mp3</code> |
| 戚云笙 | [ch7_personal_signature_inquiry_open](../../game/data/dialogs/ch7_personal_signature_inquiry_open.tres) · start · normal | 机构密令还缺个人签发。审验室焚毁箱底有一份庄主私印底令，内署已经派人回去灭证。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_personal_signature_inquiry_open/戚云笙_start.mp3</code> |
| 戚云笙 | [ch7_witness_protection_choice](../../game/data/dialogs/ch7_witness_protection_choice.tres) · choice · normal | 如何安置两名证人？ | 缺音 · <code>res://art/audio/voices/ch7/ch7_witness_protection_choice/戚云笙_choice.mp3</code> |
| 戚云笙 | [ch7_witness_protection_choice](../../game/data/dialogs/ch7_witness_protection_choice.tres) · converge · normal | 照你的方案办。证人先活下来，授权链才有机会走到真正签发的人面前。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_witness_protection_choice/戚云笙_converge.mp3</code> |
| 戚云笙 | [ch7_witness_protection_choice](../../game/data/dialogs/ch7_witness_protection_choice.tres) · start · normal | 内署已经知道有人开口。录事和旧教习今晚必须离开原处，你来决定他们分开、公开留下，还是交给洛阳官面保护。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_witness_protection_choice/戚云笙_start.mp3</code> |
| 戚云笙 | [ch7_xueying_identity_conclusion](../../game/data/dialogs/ch7_xueying_identity_conclusion.tres) · confirm · normal | 实际使用者确认是薛影本人。身份已经定下，谁授权他、为何让他以死者身份行动，才是下一层。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_xueying_identity_conclusion/戚云笙_confirm.mp3</code> |
| 戚云笙 | [ch8_aftermath_lieyun](../../game/data/dialogs/ch8_aftermath_lieyun.tres) · end · normal | 我也是这个意思。烈云不求换一块“正派”牌匾，只求以后谁再要我们认罪或喊冤，都先把原页摊开。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_aftermath_lieyun/戚云笙_end.mp3</code> |
| 戚云笙 | [ch8_aftermath_lieyun](../../game/data/dialogs/ch8_aftermath_lieyun.tres) · start · normal | 烈云被栽下的罪已经洗清，旧部真正做过的错也没有跟着消失。聚义厅撤掉了只能由盟主调阅的密柜，药册和误杀记录改由三人共签。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_aftermath_lieyun/戚云笙_start.mp3</code> |
| 戚云笙 | [ch8_relationship_qi_yunsheng](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) · independent · normal | 也好。真正的尊重不是把谁带走。往后你查你的路，我改我的盟，原页仍可互相核验。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_qi_yunsheng/戚云笙_independent.mp3</code> |
| 戚云笙 | [ch8_relationship_qi_yunsheng](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) · start · normal | 我还要留在烈云一段时间，把外部复核真正变成规矩。可我不想余生都只做一块写着“圣姑”的牌位。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_qi_yunsheng/戚云笙_start.mp3</code> |
| 戚云笙 | [ch8_relationship_qi_yunsheng](../../game/data/dialogs/ch8_relationship_qi_yunsheng.tres) · together · normal | 说定了。不是我放下烈云跟你走，也不是你留下替我守盟；等规矩能离开我们照样运转，再一起出峡谷。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_qi_yunsheng/戚云笙_together.mp3</code> |
| 赵思颖 | [ch8_relationship_zhao_siying](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) · independent · normal | 好。你走江湖，我守医路；遇到不能只靠药或只靠剑的事，再写信给对方。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_zhao_siying/赵思颖_independent.mp3</code> |
| 赵思颖 | [ch8_relationship_zhao_siying](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) · start · normal | 案卷会留在府衙，伤和病却不会等案卷审完。洛阳城外还有很多人，只知道亲人死了，不知道该怎样继续活。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_zhao_siying/赵思颖_start.mp3</code> |
| 赵思颖 | [ch8_relationship_zhao_siying](../../game/data/dialogs/ch8_relationship_zhao_siying.tres) · together · normal | 那就先从下一座没有医馆的驿站开始。剑不必挂起，知道什么时候不拔剑也很重要。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_relationship_zhao_siying/赵思颖_together.mp3</code> |

<a id="map-50"></a>
### 烈云分舵 · 安置档案室 · ch7_s7_lieyun_resettlement_archive

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 旧渡记档人 | [ch7_lieyun_record_keeper_testimony](../../game/data/dialogs/ch7_lieyun_record_keeper_testimony.tres) · limit · concerned | 我没看清脸，也不敢说死者回来了。只因当时觉得不对，私下留了一张副签；日期和暗号压痕都还在右柜。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_lieyun_record_keeper_testimony/旧渡记档人_limit.mp3</code> |
| 旧渡记档人 | [ch7_lieyun_record_keeper_testimony](../../game/data/dialogs/ch7_lieyun_record_keeper_testimony.tres) · start · solemn | 那暗号我见过。死亡名册送到旧渡后一个月，有个遮面人持同样的压签走茶路，连更次口令都没有错。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_lieyun_record_keeper_testimony/旧渡记档人_start.mp3</code> |

<a id="map-52"></a>
### 茗雾山庄 · 封印审验室 · ch7_s9_mingwu_seal_audit_room

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 茗雾内署护档使 | [ch7_inner_office_destroyers_prebattle](../../game/data/dialogs/ch7_inner_office_destroyers_prebattle.tres) · start · threat | 查到机构密令便该停手。个人押记若见光，山庄再无回旋余地。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_inner_office_destroyers_prebattle/茗雾内署护档使_start.mp3</code> |
| 茗雾旧教习 | [ch7_mingwu_instructor_recognition](../../game/data/dialogs/ch7_mingwu_instructor_recognition.tres) · start · solemn | 复核那夜，他落印前摘过一次面巾。我教了薛影十年，不会认错那张脸。但我一个人的话，不能替你定案。 | 缺音 · <code>res://art/audio/voices/ch7/ch7_mingwu_instructor_recognition/茗雾旧教习_start.mp3</code> |

<a id="map-53"></a>
### 茗雾外围 · 会盟集结地 · ch8_s1_alliance_staging_ground

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 会盟录事 | [ch8_muster_luoyang](../../game/data/dialogs/ch8_muster_luoyang.tres) · start · normal | 洛阳府衙已把两份口供封入官卷，证人不随先遣队。公开稍慢，但截盟者无法靠杀人销毁全部记录。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_muster_luoyang/会盟录事_start.mp3</code> |
| 会盟录事 | [ch8_muster_public](../../game/data/dialogs/ch8_muster_public.tres) · start · normal | 两名证人都在聚义厅公开名册上。烈云增派明哨，公开性更强，雾林截盟者也更容易找到目标。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_muster_public/会盟录事_start.mp3</code> |
| 会盟录事 | [ch8_muster_split](../../game/data/dialogs/ch8_muster_split.tres) · start · normal | 一名证人随行义帮民路，一名留烈云暗线；两份口供分开保管，任一路失联都不会抹掉全证。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_muster_split/会盟录事_start.mp3</code> |

<a id="map-54"></a>
### 茗雾外围 · 雾林阻截场 · ch8_s2_mistwood_blockade

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 茗雾截盟使 | [ch8_mistwood_prebattle](../../game/data/dialogs/ch8_mistwood_prebattle.tres) · start · normal | 信号一响，证人路线和会盟人数都会送进山庄。你们走不到第二道门。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_mistwood_prebattle/茗雾截盟使_start.mp3</code> |

<a id="map-56"></a>
### 会盟祭台下 · 机关廊 · ch8_s4_alliance_mechanism_gallery

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 茗雾机关监守 | [ch8_mechanism_prebattle](../../game/data/dialogs/ch8_mechanism_prebattle.tres) · start · normal | 鼓点和雾阀只差一声令。你拆一处，我们便在另一处先开会盟。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_mechanism_prebattle/茗雾机关监守_start.mp3</code> |

<a id="map-57"></a>
### 茗雾山庄 · 会盟祭台 · ch8_s5_alliance_ceremonial_platform

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 刑樊天 | [ch8_truth_disclosure_full](../../game/data/dialogs/ch8_truth_disclosure_full.tres) · arts · normal | 危险点穴图、茶毒配方和控息残式公开来源、危害与使用记录；具体穴位次序和制毒比例分封三匣，由洛阳、五派、行义帮各执一钥。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_truth_disclosure_full/刑樊天_arts.mp3</code> |
| 刑樊天 | [ch8_truth_disclosure_joint](../../game/data/dialogs/ch8_truth_disclosure_joint.tres) · arts · normal | 危险武学按“来源、危害、实操”拆成三册，三方各保一册。没有另两册，任何人都无法复原完整杀招。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_truth_disclosure_joint/刑樊天_arts.mp3</code> |
| 刑樊天 | [ch8_truth_disclosure_staged](../../game/data/dialogs/ch8_truth_disclosure_staged.tres) · arts · normal | 危险武学先公开目录、来历和受害记录，招式路径与配方暂封；六个月后由外部医者、武师和官府共同复核是否保留研究副本。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_truth_disclosure_staged/刑樊天_arts.mp3</code> |
| 戚云笙 | [ch8_truth_disclosure_full](../../game/data/dialogs/ch8_truth_disclosure_full.tres) · witness · normal | 愿意署名的人公开姓名，不愿公开者以核验编号代替；无论是否署名，当前住处和护送路线一律删去。完整公开事实，不等于公开活人的藏身处。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_truth_disclosure_full/戚云笙_witness.mp3</code> |
| 戚云笙 | [ch8_truth_disclosure_joint](../../game/data/dialogs/ch8_truth_disclosure_joint.tres) · witness · normal | 证人身份分为公开名册和密封名册；密封名册必须三方同时到场才能查阅，单方调人、问话或转押一律无效。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_truth_disclosure_joint/戚云笙_witness.mp3</code> |
| 戚云笙 | [ch8_truth_disclosure_staged](../../game/data/dialogs/ch8_truth_disclosure_staged.tres) · witness · normal | 证词先以编号和三方核验印公开，姓名待证人迁至稳定住处并重新确认意愿后追加。任何延后都要写明期限与负责者。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_truth_disclosure_staged/戚云笙_witness.mp3</code> |
| 苏雾笙 | [ch8_su_first_confrontation](../../game/data/dialogs/ch8_su_first_confrontation.tres) · choice · normal | 如何回应苏雾笙？ | 缺音 · <code>res://art/audio/voices/ch8/ch8_su_first_confrontation/苏雾笙_choice.mp3</code> |
| 苏雾笙 | [ch8_su_first_confrontation](../../game/data/dialogs/ch8_su_first_confrontation.tres) · evidence · normal | 底令是真的，旧罪也是真的。你能证明我动过局，却不能证明没有这场局，江湖就会更好。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_su_first_confrontation/苏雾笙_evidence.mp3</code> |
| 苏雾笙 | [ch8_su_first_confrontation](../../game/data/dialogs/ch8_su_first_confrontation.tres) · motive · normal | 让所有门派先拥有同一个敌人，再由能控制恐惧的人制定秩序。没有共同恐惧，所谓会盟只是一桌旧账。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_su_first_confrontation/苏雾笙_motive.mp3</code> |
| 苏雾笙 | [ch8_su_first_confrontation](../../game/data/dialogs/ch8_su_first_confrontation.tres) · save · normal | 你总把活人放在答案前面。可不让江湖先痛一次，他们永远不会接受同一套规矩。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_su_first_confrontation/苏雾笙_save.mp3</code> |
| 苏雾笙 | [ch8_su_first_confrontation](../../game/data/dialogs/ch8_su_first_confrontation.tres) · start · normal | 你断了鼓、封了雾，也截了第一轮令。可各派旧债都是真的——没有我，他们一样会互相清算。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_su_first_confrontation/苏雾笙_start.mp3</code> |
| 茗雾假令传使 | [ch8_false_order_prebattle](../../game/data/dialogs/ch8_false_order_prebattle.tres) · start · normal | 令一出手，各派都会看见自己想看的敌人。你拦得住我，拦不住他们彼此猜疑。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_false_order_prebattle/茗雾假令传使_start.mp3</code> |

<a id="map-58"></a>
### 茗雾山庄 · 正厅 · ch8_s6_mingwu_main_hall

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 苏雾笙 | [ch8_su_xueying_authorization](../../game/data/dialogs/ch8_su_xueying_authorization.tres) · choice · normal | 如何拆开苏雾笙与薛影的私人命令链？ | 缺音 · <code>res://art/audio/voices/ch8/ch8_su_xueying_authorization/苏雾笙_choice.mp3</code> |
| 苏雾笙 | [ch8_su_xueying_authorization](../../game/data/dialogs/ch8_su_xueying_authorization.tres) · start · normal | 他原本连名字都没有。是我把他从死人堆里带出来，给他药、给他住处，也教他这世上只有命令不会背叛。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_su_xueying_authorization/苏雾笙_start.mp3</code> |
| 苏雾笙 | [ch8_su_xueying_authorization](../../game/data/dialogs/ch8_su_xueying_authorization.tres) · su_answer · normal | 我没有伪造他的苦难，也没有伪造各派的旧债。我只教他别再把命交给那些会删掉他名字的人。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_su_xueying_authorization/苏雾笙_su_answer.mp3</code> |
| 薛影 | [ch8_su_xueying_authorization](../../game/data/dialogs/ch8_su_xueying_authorization.tres) · choice · normal | 如何拆开苏雾笙与薛影的私人命令链？ | 缺音 · <code>res://art/audio/voices/ch8/ch8_su_xueying_authorization/薛影_choice.mp3</code> |
| 薛影 | [ch8_su_xueying_authorization](../../game/data/dialogs/ch8_su_xueying_authorization.tres) · rescue · normal | 西侧两道门。一道通药圃，一道通旧驿坡。封令柜后还有六名抄录人，后殿落闸前必须带走。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_su_xueying_authorization/薛影_rescue.mp3</code> |
| 薛影 | [ch8_su_xueying_authorization](../../game/data/dialogs/ch8_su_xueying_authorization.tres) · responsibility · normal | 我记得每一张脸。被当作刀，不等于刀下的人就没有死。若活到天明，我会受审。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_su_xueying_authorization/薛影_responsibility.mp3</code> |
| 薛影 | [ch8_su_xueying_authorization](../../game/data/dialogs/ch8_su_xueying_authorization.tres) · testify · normal | 北道截口供、洛阳烧副卷、竹尾留活口引人入局……都不是盟令，是庄主亲令。每次只给我一句，不留全卷。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_su_xueying_authorization/薛影_testify.mp3</code> |
| 薛影 | [ch8_su_xueying_authorization](../../game/data/dialogs/ch8_su_xueying_authorization.tres) · xueying · normal | 旧名在名册上已经死了。庄主给我的每一道命令，都是我还能活着的理由。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_su_xueying_authorization/薛影_xueying.mp3</code> |

<a id="map-59"></a>
### 茗雾山庄 · 后殿 · ch8_s7_mingwu_rear_sanctum

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 刑樊天 | [ch8_su_final_victory](../../game/data/dialogs/ch8_su_final_victory.tres) · master · normal | 我会先认自己改过的那一行。不是替他求情，是不让任何人再拿我的沉默替自己免责。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_su_final_victory/刑樊天_master.mp3</code> |
| 苏雾笙 | [ch8_su_final_victory](../../game/data/dialogs/ch8_su_final_victory.tres) · su · normal | 你赢了一场。可只要旧卷里那些名字还被各派捂着，今日的我就会换个姓氏再回来。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_su_final_victory/苏雾笙_su.mp3</code> |
| 薛影 | [ch8_xueying_battle_victory](../../game/data/dialogs/ch8_xueying_battle_victory.tres) · last · normal | 原来没有命令，也能选最后一步。把我的亲令证词留下……别再让下一个孩子只剩一个名字。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_xueying_battle_victory/薛影_last.mp3</code> |
| 薛影 | [ch8_xueying_resolution_choice](../../game/data/dialogs/ch8_xueying_resolution_choice.tres) · battle · normal | 那便不再为庄主，也不再为一个死人的名字。这一次，是我自己选。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_xueying_resolution_choice/薛影_battle.mp3</code> |
| 薛影 | [ch8_xueying_resolution_choice](../../game/data/dialogs/ch8_xueying_resolution_choice.tres) · choice · normal | 证人已撤、亲令在册。如何处置薛影？ | 缺音 · <code>res://art/audio/voices/ch8/ch8_xueying_resolution_choice/薛影_choice.mp3</code> |
| 薛影 | [ch8_xueying_resolution_choice](../../game/data/dialogs/ch8_xueying_resolution_choice.tres) · start · normal | 西侧两路都已空，封令柜也有人接手。庄主给我的最后一令，已经没有可以威胁的人。你还要我做什么？ | 缺音 · <code>res://art/audio/voices/ch8/ch8_xueying_resolution_choice/薛影_start.mp3</code> |
| 薛影 | [ch8_xueying_resolution_choice](../../game/data/dialogs/ch8_xueying_resolution_choice.tres) · surrender · normal | 我不求赦。竹尾、洛阳、北道，哪一笔该问，就一笔一笔问。针套和后殿令都留在这里。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_xueying_resolution_choice/薛影_surrender.mp3</code> |
| 薛影 | [ch8_xueying_resolution_choice](../../game/data/dialogs/ch8_xueying_resolution_choice.tres) · testify · normal | 我会从第一道亲令说起，也会说哪些人不是任务，却因为看见了我而死。作证以后，该伏的法仍旧伏。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_xueying_resolution_choice/薛影_testify.mp3</code> |

<a id="map-60"></a>
### 山道·山贼洞窟 · interior_bandit_cave

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 留守山贼 | [interior_bandit_cave_guard](../../game/data/dialogs/interior_bandit_cave_guard.tres) · start · normal | 这洞是爷们看货的地方。再往里一步，可别怪我不客气。 | 缺音 · <code>res://art/audio/voices/int/interior_bandit_cave_guard/留守山贼_start.mp3</code> |

<a id="map-61"></a>
### 竹尾村·客栈大堂 · interior_inn_hall

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 客栈老板 | [ch1_s2_inn_keeper](../../game/data/dialogs/ch1_s2_inn_keeper.tres) · b · normal | 尤其[color=#e3a64a]城西的那处废宅[/color]—— 半月内已经死了三波路人，连衙门都不敢往里钻。 | [语音 1 · 7.3 秒](../../game/art/audio/voices/ch1/ch1_s2_inn_keeper/%E5%AE%A2%E6%A0%88%E8%80%81%E6%9D%BF_b_enormal.mp3)（情绪后缀） |
| 客栈老板 | [ch1_s2_inn_keeper](../../game/data/dialogs/ch1_s2_inn_keeper.tres) · start · concerned | 客官从外面来？ 这阵子可不太平，少在城外多走动。 | [语音 1 · 5.2 秒](../../game/art/audio/voices/ch1/ch1_s2_inn_keeper/%E5%AE%A2%E6%A0%88%E8%80%81%E6%9D%BF_start.mp3)（无后缀回退） |

<a id="map-72"></a>
### 林西村 · 师徒院落 · linxi_tutorial

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 刑樊天 | [ch1_return_to_master](../../game/data/dialogs/ch1_return_to_master.tres) · n10 · normal | （站起身，声音比刚才轻了三分） ……这吐纳法没有名字。我也没有给它取过名字。 （他看着你) 但你记住——内力不是练出来的，是磨出来的。每天磨。 （他转身走向屋内，在门口停了半步，没有回头） 打不过就跑。活着回来。 这句话我只说这一次。 | [语音 1 · 5.5 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n10_seg02_dialog.mp3)、[语音 2 · 6.6 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n10_seg04_dialog.mp3)、[语音 3 · 6.4 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n10_seg06_dialog.mp3)（分段） |
| 刑樊天 | [ch1_return_to_master](../../game/data/dialogs/ch1_return_to_master.tres) · n2 · normal | （放下手中的茶杯，目光从你脸上的擦伤扫到衣角的血迹） ……打赢了？ | [语音 1 · 1.8 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n2_seg02_dialog.mp3)（分段） |
| 刑樊天 | [ch1_return_to_master](../../game/data/dialogs/ch1_return_to_master.tres) · n4 · normal | （站起身，走到你跟前，突然伸手按住你右肩——你疼得一缩） 你受伤了。不是那个散兵伤的——是你自己剑法里的破绽。第一式你已经熟了，但只靠一式，你连竹尾村都到不了。 | [语音 1 · 9.9 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n4_seg02_dialog.mp3)（分段） |
| 刑樊天 | [ch1_return_to_master](../../game/data/dialogs/ch1_return_to_master.tres) · n6 · normal | （嘴角微微一抽——可能是笑，也可能只是忍住了没叹气） 不教第一式了。教第二式。 （他走到院中，抽出自己的木剑） 过来。今天教你'以退为进'——不是让你退，是让你的剑退，你的人不退。 | [语音 1 · 3.2 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n6_seg02_dialog.mp3)、[语音 2 · 6.5 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n6_seg04_dialog.mp3)（分段） |
| 刑樊天 | [ch1_return_to_master](../../game/data/dialogs/ch1_return_to_master.tres) · n8 · normal | 剑法有了。还差一口气。 （他盘膝坐下，示意你也坐下） 闭上眼睛。吸气——别急着呼。……听见没，你自己的心跳。太快了。你这样出去，三招之内气息就会乱——比剑法更快让你输。 | [语音 1 · 3.2 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n8_seg01_dialog.mp3)、[语音 2 · 12.4 秒](../../game/art/audio/voices/ch1/ch1_return_to_master/%E5%88%91%E6%A8%8A%E5%A4%A9_n8_seg03_dialog.mp3)（分段） |
| 刑樊天 | [ch1_tutorial_xingfantian](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) · ask · concerned | （沉默良久）……上个月，武当大弟子陆青云死了。这个月，华山顾凌雪、古峰雷彻、凌月白晚晴、少林圆觉——全死了。 | [语音 1 · 11.9 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_ask_seg02_dialog.mp3)（分段） |
| 刑樊天 | [ch1_tutorial_xingfantian](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) · ask3 · solemn | 江湖传言是烈云盟干的。 | [语音 1 · 3.7 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_ask3_seg01_dialog.mp3)（分段） |
| 刑樊天 | [ch1_tutorial_xingfantian](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) · merge · weary | （长叹一声）……孤云。你今年二十了。 | [语音 1 · 3.5 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_merge_seg02_dialog.mp3)（分段） |
| 刑樊天 | [ch1_tutorial_xingfantian](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) · merge3 · concerned | 我知道你想下山。你从小就想——每次有货郎进村，你都追着问外面的消息。今天，我不拦你。 | [语音 1 · 10.3 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_merge3_seg01_dialog.mp3)（分段） |
| 刑樊天 | [ch1_tutorial_xingfantian](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) · merge5 · solemn | （刑樊天打断你的话，从怀中掏出一个青色酒葫芦，递到你手中。） 不是突然。是时候了。带着——林西的酒，你在外面喝不到。 | [语音 1 · 7.8 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_merge5_seg02_dialog.mp3)（分段） |
| 刑樊天 | [ch1_tutorial_xingfantian](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) · merge8 · solemn | （一字一顿）江湖上，不是每个对你笑的人都可信。不是每个骂你的人都是敌人。酒可以多喝，但话要少说。 （他转过身去，不再看你）先去铁匠铺拿你的剑。杜青衫已经等了两天了。 | [语音 1 · 10.6 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_merge8_seg02_dialog.mp3)、[语音 2 · 6.0 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_merge8_seg04_dialog.mp3)（分段） |
| 刑樊天 | [ch1_tutorial_xingfantian](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) · n3 · normal | 第三招“扫叶式”，你手腕总是多转半圈。少转半圈，剑尖能快三分。快了三分，你的命就多三分。 | [语音 1 · 9.6 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_n3_seg01_dialog.mp3)（分段） |
| 刑樊天 | [ch1_tutorial_xingfantian](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) · n6 · concerned | ……先练剑。 | [语音 1 · 1.8 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_n6_seg01_dialog.mp3)（分段） |
| 刑樊天 | [ch1_tutorial_xingfantian](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) · start · normal | 醒了？过来，把昨天那套剑法再走一遍。 | [语音 1 · 4.6 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_start_seg01_dialog.mp3)（分段） |
| 刑樊天 | [ch1_tutorial_xingfantian](../../game/data/dialogs/ch1_tutorial_xingfantian.tres) · train2 · normal | ……嗯。勉强及格。你那招“扫叶”还是多了半圈，不过—— （他顿了顿） 今天不纠了。 | [语音 1 · 5.8 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_train2_seg01_dialog.mp3)、[语音 2 · 1.9 秒](../../game/art/audio/voices/ch1/ch1_tutorial_xingfantian/%E5%88%91%E6%A8%8A%E5%A4%A9_train2_seg03_dialog.mp3)（分段） |
| 杜青衫 | [ch1_tutorial_duqingshan](../../game/data/dialogs/ch1_tutorial_duqingshan.tres) · n3 · normal | （手上动作不停，铁锤在砧上哐哐响）你师傅那人，什么时候商量过？他半夜敲我家门，就一句“给孤云打把好剑”——然后就走了。 一句话值三百两。老子打了三天。 | [语音 1 · 13.5 秒](../../game/art/audio/voices/ch1/ch1_tutorial_duqingshan/%E6%9D%9C%E9%9D%92%E8%A1%AB_n3_enormal.mp3)（情绪后缀） |
| 杜青衫 | [ch1_tutorial_duqingshan](../../game/data/dialogs/ch1_tutorial_duqingshan.tres) · n5 · normal | 拿着。不是宝剑——但林西村的铁，竹尾村的水，淬出来的刃比你张嘴快。 （他咧嘴一笑）你看人家铁匠刘——他就从来不废话，我只管打铁。 | [语音 1 · 13.1 秒](../../game/art/audio/voices/ch1/ch1_tutorial_duqingshan/%E6%9D%9C%E9%9D%92%E8%A1%AB_n5_enormal.mp3)（情绪后缀） |
| 杜青衫 | [ch1_tutorial_duqingshan](../../game/data/dialogs/ch1_tutorial_duqingshan.tres) · start · happy | 哈哈，冷小子！你师傅三天前就让我把剑打好。今天我一看——这小子还没来拿？再不来，我就把它卖了。 | [语音 1 · 10.2 秒](../../game/art/audio/voices/ch1/ch1_tutorial_duqingshan/%E6%9D%9C%E9%9D%92%E8%A1%AB_start_ehappy.mp3)（情绪后缀） |
| 刑樊天 | [ch6_master_after_records](../../game/data/dialogs/ch6_master_after_records.tres) · master · solemn | 是我改的。可裁走去向的人不是我。去白水驿，重走那段押运路；回来后，我把该承担的都说清楚。 | 缺音 · <code>res://art/audio/voices/ch6/ch6_master_after_records/刑樊天_master.mp3</code> |
| 刑樊天 | [ch6_master_confrontation](../../game/data/dialogs/ch6_master_confrontation.tres) · choice · normal | 你如何处理刑樊天的证词与安全？ | 缺音 · <code>res://art/audio/voices/ch6/ch6_master_confrontation/刑樊天_choice.mp3</code> |
| 刑樊天 | [ch6_master_confrontation](../../game/data/dialogs/ch6_master_confrontation.tres) · converge · normal | 这册《玄霜诀》只到藏息篇，不能替你把路走完。拿着它。村外古道还有人在等你——桌上的火漆不是我的。 | 缺音 · <code>res://art/audio/voices/ch6/ch6_master_confrontation/刑樊天_converge.mp3</code> |
| 刑樊天 | [ch6_master_confrontation](../../game/data/dialogs/ch6_master_confrontation.tres) · independent · weary | 你不信我，也该由我受着。我把旧路和封蜡样式都交给你，之后只在暗处替你盯追兵。 | 缺音 · <code>res://art/audio/voices/ch6/ch6_master_confrontation/刑樊天_independent.mp3</code> |
| 刑樊天 | [ch6_master_confrontation](../../game/data/dialogs/ch6_master_confrontation.tres) · master · solemn | 因为追那辆窄车的人没有停过。我把你的去向改成失散，想让他们以为线索断了。可我也把你该有的选择一起藏了二十年。 | 缺音 · <code>res://art/audio/voices/ch6/ch6_master_confrontation/刑樊天_master.mp3</code> |
| 刑樊天 | [ch6_master_confrontation](../../game/data/dialogs/ch6_master_confrontation.tres) · protect · concerned | 先保人再补证，不等于永远不作证。等你找到能接上裁页的人，我会出来把改过的那一行认下。 | 缺音 · <code>res://art/audio/voices/ch6/ch6_master_confrontation/刑樊天_protect.mp3</code> |
| 刑樊天 | [ch6_master_confrontation](../../game/data/dialogs/ch6_master_confrontation.tres) · public · solemn | 好。该我署名的那一页，我亲自重写；该我承担的后果，不再让你替我挡。 | 缺音 · <code>res://art/audio/voices/ch6/ch6_master_confrontation/刑樊天_public.mp3</code> |
| 刑樊天 | [ch6_return_intro](../../game/data/dialogs/ch6_return_intro.tres) · answer · solemn | 先把原册保下来。你看见什么，回来当面问我。我不再替你挑该知道哪一段。 | 缺音 · <code>res://art/audio/voices/ch6/ch6_return_intro/刑樊天_answer.mp3</code> |
| 刑樊天 | [ch6_return_intro](../../game/data/dialogs/ch6_return_intro.tres) · master · weary | 先别问我。两个人翻进正屋，一个往地下去了。找的是十八年前的旧册，不是银钱。 | 缺音 · <code>res://art/audio/voices/ch6/ch6_return_intro/刑樊天_master.mp3</code> |
| 刑樊天 | [ch8_guyun_recollection](../../game/data/dialogs/ch8_guyun_recollection.tres) · n2 · normal | 因为我也只练到第九重。我师父从未传我第十重，只说我把剑当成了答案，而不是一条回来的路。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_guyun_recollection/刑樊天_n2.mp3</code> |
| 刑樊天 | [ch8_guyun_recollection](../../game/data/dialogs/ch8_guyun_recollection.tres) · n4 · normal | 地下档案室最上层有一只封死的旧木匣。我一直以为里面只是师父留下的押运账，原来他把剑解藏在账页夹层。去兵器架前的暗门，我们一起把它取出来。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_guyun_recollection/刑樊天_n4.mp3</code> |
| 刑樊天 | [ch8_linxi_final_return](../../game/data/dialogs/ch8_linxi_final_return.tres) · master · normal | 这就够了。我改过的那一行已经署名认下；往后若有人再问你师承，不必替我遮，也不必只记我的错。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_linxi_final_return/刑樊天_master.mp3</code> |
| 刑樊天 | [ch8_linxi_final_return](../../game/data/dialogs/ch8_linxi_final_return.tres) · start · normal | 洛阳、烈云、竹尾都走过了？你回来不是为了告诉我赢了，而是要告诉我赢以后留下了什么。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_linxi_final_return/刑樊天_start.mp3</code> |
| 封砚秋 | [ch8_guyun_recollection](../../game/data/dialogs/ch8_guyun_recollection.tres) · n3 · normal | 原目录缺页处盖着你师门旧印。那本书也许没有送进茗雾，而是一直留在林西。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_guyun_recollection/封砚秋_n3.mp3</code> |
| 封砚秋 | [ch8_guyun_recollection](../../game/data/dialogs/ch8_guyun_recollection.tres) · start · normal | 晨市断剑、回锋残图、洛阳试痕和茗雾原目录都指向同一套换力记号。可冷孤云已把林西剑法练到第九重，仍然少了最后一段。 | 缺音 · <code>res://art/audio/voices/ch8/ch8_guyun_recollection/封砚秋_start.mp3</code> |

<a id="map-73"></a>
### 林西村 · 村中心 · linxi_village_center

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 药师苏伯 | [linxi_center_herbalist_ledger_verify](../../game/data/dialogs/linxi_center_herbalist_ledger_verify.tres) · verify · normal | 这是旧时药铺的批货记号。这样成批买止血散和迷香的，不像寻常商旅。你把账页收好，往后或许能和别处的货单对上。 | 缺音 · <code>res://art/audio/voices/lin/linxi_center_herbalist_ledger_verify/药师苏伯_verify.mp3</code> |
| 药师苏伯 | [linxi_cliff_herb_done](../../game/data/dialogs/linxi_cliff_herb_done.tres) · start · normal | 那束止血藤已经入药。往后再遇见临崖药草，也只取够用的一段——山里东西长得慢，经不起人人贪多。 | 缺音 · <code>res://art/audio/voices/lin/linxi_cliff_herb_done/药师苏伯_start.mp3</code> |
| 药师苏伯 | [linxi_cliff_herb_offer](../../game/data/dialogs/linxi_cliff_herb_offer.tres) · accept · normal | 多谢。山路上刚出过事，药草没有人命要紧。若见石缝边那一小簇，割近根处一段就够。 | 缺音 · <code>res://art/audio/voices/lin/linxi_cliff_herb_offer/药师苏伯_accept.mp3</code> |
| 药师苏伯 | [linxi_cliff_herb_offer](../../game/data/dialogs/linxi_cliff_herb_offer.tres) · ask · normal | 你若还要经过村外山道，可愿替我带一束回来？藤叶背面泛青，断口有淡淡辛味。别往崖外探身，够不着便算了。 | 缺音 · <code>res://art/audio/voices/lin/linxi_cliff_herb_offer/药师苏伯_ask.mp3</code> |
| 药师苏伯 | [linxi_cliff_herb_offer](../../game/data/dialogs/linxi_cliff_herb_offer.tres) · start · normal | 你从山道回来后，苏伯就一直留意你肩上的伤。他说近来伤药用得快，有一味青崖止血藤却只生在临崖石缝里，药铺学徒不敢去取。 | 缺音 · <code>res://art/audio/voices/lin/linxi_cliff_herb_offer/药师苏伯_start.mp3</code> |
| 药师苏伯 | [linxi_cliff_herb_turnin](../../game/data/dialogs/linxi_cliff_herb_turnin.tres) · finish · normal | 叶背、气味都对。你肯给药藤留根，比多采一把更难得。药铺能多备几包伤药，学徒也不必冒险上崖。 | 缺音 · <code>res://art/audio/voices/lin/linxi_cliff_herb_turnin/药师苏伯_finish.mp3</code> |
| 药师苏伯 | [linxi_cliff_herb_waiting](../../game/data/dialogs/linxi_cliff_herb_waiting.tres) · start · normal | 青崖止血藤找到了吗？我只要一束，够药铺续上几日便好。 | 缺音 · <code>res://art/audio/voices/lin/linxi_cliff_herb_waiting/药师苏伯_start.mp3</code> |

<a id="map-74"></a>
### 林西村 · 南坊 · linxi_village_scrollmap

| NPC | 对白节点与情绪 | 台词 | 实际语音 / 缺音路径 |
|---|---|---|---|
| 村塾先生 | [ch1_side_stone_teacher_done](../../game/data/dialogs/ch1_side_stone_teacher_done.tres) · start · normal | 我把碑文抄进了村塾的旧册。往后孩子们学‘信’字时，也该知道求证比轻信更难。 | 缺音 · <code>res://art/audio/voices/ch1/ch1_side_stone_teacher_done/村塾先生_start.mp3</code> |
| 村塾先生 | [ch1_side_stone_teacher_offer](../../game/data/dialogs/ch1_side_stone_teacher_offer.tres) · accept · normal | 带些清水，把浮尘慢慢润开，再用纸压住纹路。别用刀刮，碑上每一道旧痕都可能是字。 | 缺音 · <code>res://art/audio/voices/ch1/ch1_side_stone_teacher_offer/村塾先生_accept.mp3</code> |
| 村塾先生 | [ch1_side_stone_teacher_offer](../../game/data/dialogs/ch1_side_stone_teacher_offer.tres) · start · normal | 村外山道有块旧碑，风雨磨得只剩几笔。我年轻时拓过半张，却始终没弄清它在劝后人什么。你若还要经过那里，可愿替我取一张完整拓本？ | 缺音 · <code>res://art/audio/voices/ch1/ch1_side_stone_teacher_offer/村塾先生_start.mp3</code> |
| 村塾先生 | [ch1_side_stone_teacher_turnin](../../game/data/dialogs/ch1_side_stone_teacher_turnin.tres) · start · normal | 这回看清了：‘见疑求证，不以名号定善恶。’它不是武功口诀，是前人留给过路人的一句劝诫。 | 缺音 · <code>res://art/audio/voices/ch1/ch1_side_stone_teacher_turnin/村塾先生_start.mp3</code> |
| 村塾先生 | [ch1_side_stone_teacher_waiting](../../game/data/dialogs/ch1_side_stone_teacher_waiting.tres) · start · normal | 那块残碑的拓本取到了吗？山道近来不安稳，认字不值得拿性命去换。 | 缺音 · <code>res://art/audio/voices/ch1/ch1_side_stone_teacher_waiting/村塾先生_start.mp3</code> |

## 任务 NPC 配音身份索引

已注明的年龄来自[世界观角色设定](../world-bible.md)及[剧情角色记录](../agents/lore-memory.md)。称谓和立绘资产提供参考。未找到明确设定的角色保留待定。这里的性别和年龄描述用于校对角色，成品听感仍需试听。

| 发言名称 | 角色性别和年龄依据 | 有语音 / 总条目 | 出现的情绪标签 |
|---|---|---:|---|
| 会盟录事 | 性别和年龄待角色表 | 0 / 3 | normal |
| 伪旗统领 | 性别和年龄待角色表 | 0 / 1 | weary |
| 伪烈云突袭手 | 性别和年龄待角色表 | 0 / 1 | normal |
| 凌月弟子 | 性别和年龄待角色表 | 0 / 1 | normal |
| 凌霜 | 女 · 45 岁 | 4 / 4 | normal |
| 刑樊天 | 男 · 52 岁 | 15 / 32 | concerned、normal、solemn、weary |
| 卖菜大婶 | 女 · 中年角色，具体年龄待定 | 5 / 5 | concerned、normal |
| 古峰护粮守卫 | 性别和年龄待角色表 | 0 / 4 | normal |
| 古疆雷 | 男 · 55 岁 | 0 / 1 | normal |
| 合练教习 | 性别和年龄待角色表 | 0 / 2 | normal |
| 唐行舟 | 男 · 21 岁 | 0 / 4 | normal、solemn |
| 外院录事 | 性别和年龄待角色表 | 0 / 1 | normal |
| 大会乐师 | 性别和年龄待角色表 | 3 / 3 | normal |
| 大会执事 | 性别和年龄待角色表 | 0 / 3 | normal |
| 失踪脚夫 | 性别和年龄待角色表 | 0 / 3 | normal |
| 守山弟子 | 性别和年龄待角色表 | 0 / 3 | normal |
| 守村人 | 男 · 年长立绘，具体年龄待定 | 2 / 7 | normal |
| 守窟僧 | 性别和年龄待角色表 | 0 / 6 | normal |
| 守钟僧 | 性别和年龄待角色表 | 0 / 7 | normal |
| 守门村民 | 性别和年龄待角色表 | 1 / 1 | concerned |
| 客栈老板 | 性别和年龄待角色表 | 4 / 5 | concerned、normal |
| 封砚秋 | 性别和年龄待角色表 | 0 / 18 | normal |
| 少林俗家·岳闻钟 | 性别和年龄待角色表 | 0 / 1 | normal |
| 左明远 | 性别和年龄待角色表 | 0 / 6 | normal |
| 府尹 | 性别和年龄待角色表 | 0 / 1 | normal |
| 府衙老吏 | 年长角色，性别和年龄待角色表 | 0 / 2 | normal |
| 悦无姮 | 女 · 22 岁 | 0 / 18 | normal |
| 戚云笙 | 女 · 21 岁 | 0 / 25 | normal、solemn |
| 护商镖师 | 性别和年龄待角色表 | 2 / 11 | normal |
| 挑担脚夫 | 性别和年龄待角色表 | 0 / 6 | normal |
| 捕快韩策 | 性别和年龄待角色表 | 0 / 1 | normal |
| 旧渡守望 | 性别和年龄待角色表 | 0 / 2 | normal、solemn |
| 旧渡记档人 | 性别和年龄待角色表 | 0 / 2 | concerned、solemn |
| 村塾先生 | 性别和年龄待角色表 | 0 / 5 | normal |
| 杜青衫 | 男 · 48 岁 | 3 / 3 | happy、normal |
| 棋叟 | 男 · 年长角色，具体年龄待定 | 0 / 3 | normal |
| 楚泠 | 性别和年龄待角色表 | 2 / 2 | normal |
| 武馆教头 | 性别和年龄待角色表 | 3 / 3 | normal |
| 沈伯 | 男 · 年长角色，具体年龄待定 | 0 / 2 | normal |
| 沈晚棠 | 性别和年龄待角色表 | 4 / 4 | normal |
| 沈青禾 | 女 · 主角青梅，具体年龄待定 | 0 / 4 | angry、concerned、normal |
| 洛阳地痞 | 性别和年龄待角色表 | 0 / 1 | normal |
| 清虚道长 | 性别和年龄待角色表 | 0 / 3 | normal |
| 游方棋客 | 性别和年龄待角色表 | 0 / 3 | normal |
| 游方道人 | 性别和年龄待角色表 | 0 / 3 | normal |
| 漕工头领 | 性别和年龄待角色表 | 0 / 7 | normal |
| 焦急妇人 | 女 · 成年，具体年龄待定 | 2 / 2 | fear、normal |
| 玄真道长 | 男 · 62 岁 | 0 / 2 | normal |
| 留守山贼 | 性别和年龄待角色表 | 0 / 1 | normal |
| 矿道灭口人 | 性别和年龄待角色表 | 0 / 1 | normal |
| 终局案卷吏 | 性别和年龄待角色表 | 0 / 2 | normal |
| 老漕卒 | 年长角色，性别和年龄待角色表 | 0 / 5 | normal |
| 老纸匠 | 年长角色，性别和年龄待角色表 | 0 / 2 | normal |
| 考校执事 | 性别和年龄待角色表 | 0 / 2 | normal |
| 聚义厅引路人 | 性别和年龄待角色表 | 0 / 1 | normal |
| 船夫赵大江 | 性别和年龄待角色表 | 0 / 1 | normal |
| 苏雾笙 | 男 · 48 岁 | 0 / 11 | normal |
| 范掌柜 | 性别和年龄待角色表 | 0 / 2 | normal |
| 茗雾假令传使 | 性别和年龄待角色表 | 0 / 1 | normal |
| 茗雾内署护档使 | 性别和年龄待角色表 | 0 / 1 | threat |
| 茗雾截盟使 | 性别和年龄待角色表 | 0 / 1 | normal |
| 茗雾旧教习 | 性别和年龄待角色表 | 0 / 1 | solemn |
| 茗雾暗哨 | 性别和年龄待角色表 | 0 / 1 | normal |
| 茗雾机关监守 | 性别和年龄待角色表 | 0 / 1 | normal |
| 茗雾焚册客 | 性别和年龄待角色表 | 0 / 1 | threat |
| 茗雾销卷使 | 性别和年龄待角色表 | 0 / 1 | threat |
| 茶镇经手人 | 性别和年龄待角色表 | 0 / 2 | normal |
| 药师苏伯 | 男 · 年长角色，具体年龄待定 | 0 / 7 | normal |
| 蒙面头领 | 性别和年龄待角色表 | 0 / 1 | normal |
| 薛影 | 男 · 27 岁 | 0 / 11 | normal |
| 被绑男子 | 男 · 年龄待角色表 | 2 / 2 | fear、normal |
| 论剑执笔人 | 性别和年龄待角色表 | 0 / 3 | normal |
| 诗会执事 | 性别和年龄待角色表 | 0 / 10 | normal |
| 赵思颖 | 女 · 21 岁 | 9 / 18 | normal |
| 雪岭追兵 | 性别和年龄待角色表 | 0 / 1 | normal |
| 雪路劫粮客 | 性别和年龄待角色表 | 0 / 1 | normal |
| 霍长空 | 男 · 50 岁 | 0 / 1 | normal |

## 尚未定位到现役地图入口的任务对白

- [ch1_road_enter](../../game/data/dialogs/ch1_road_enter.tres) · q_ch1_main_road
- [ch4_fake_assassin](../../game/data/dialogs/ch4_fake_assassin.tres) · q_ch4_main_02_ancient_temple
- [ch4_fake_assassin_capture](../../game/data/dialogs/ch4_fake_assassin_capture.tres) · q_ch4_main_02_ancient_temple

## Godot 无法加载为有效音频的文件

以下为全目录健康检查，与上文现役任务语音分开统计。部分文件属于旧路径或已有可用分段替代。

- [art/audio/voices/ch1/ch1_corpse_examine/旁白_start_enormal.mp3](../../game/art/audio/voices/ch1/ch1_corpse_examine/%E6%97%81%E7%99%BD_start_enormal.mp3) · 45,792 字节，Godot 无有效音频
- [art/audio/voices/ch1/ch1_forest_victory/蒙面杀手首领_n2.mp3](../../game/art/audio/voices/ch1/ch1_forest_victory/%E8%92%99%E9%9D%A2%E6%9D%80%E6%89%8B%E9%A6%96%E9%A2%86_n2.mp3) · 0 字节
- [art/audio/voices/ch1/ch1_forest_victory/蒙面杀手首领_n4.mp3](../../game/art/audio/voices/ch1/ch1_forest_victory/%E8%92%99%E9%9D%A2%E6%9D%80%E6%89%8B%E9%A6%96%E9%A2%86_n4.mp3) · 0 字节
- [art/audio/voices/ch1/ch1_forest_yuewuxing/蒙面杀手乙_fight2.mp3](../../game/art/audio/voices/ch1/ch1_forest_yuewuxing/%E8%92%99%E9%9D%A2%E6%9D%80%E6%89%8B%E4%B9%99_fight2.mp3) · 0 字节
- [art/audio/voices/ch1/ch1_forest_yuewuxing/蒙面杀手甲_n3.mp3](../../game/art/audio/voices/ch1/ch1_forest_yuewuxing/%E8%92%99%E9%9D%A2%E6%9D%80%E6%89%8B%E7%94%B2_n3.mp3) · 0 字节
- [art/audio/voices/ch1/ch1_forest_yuewuxing/蒙面杀手甲_n5.mp3](../../game/art/audio/voices/ch1/ch1_forest_yuewuxing/%E8%92%99%E9%9D%A2%E6%9D%80%E6%89%8B%E7%94%B2_n5.mp3) · 0 字节
- [art/audio/voices/ch1/ch1_main_street_duqingshan/杜青衫_start.mp3](../../game/art/audio/voices/ch1/ch1_main_street_duqingshan/%E6%9D%9C%E9%9D%92%E8%A1%AB_start.mp3) · 56,016 字节，Godot 无有效音频
- [art/audio/voices/ch1/ch1_road_corpse/江湖散兵_n4.mp3](../../game/art/audio/voices/ch1/ch1_road_corpse/%E6%B1%9F%E6%B9%96%E6%95%A3%E5%85%B5_n4.mp3) · 0 字节
- [art/audio/voices/ch1/ch1_road_corpse/江湖散兵_n6.mp3](../../game/art/audio/voices/ch1/ch1_road_corpse/%E6%B1%9F%E6%B9%96%E6%95%A3%E5%85%B5_n6.mp3) · 0 字节
- [art/audio/voices/ch1/ch1_tutorial_blacksmith/铁匠刘_start.mp3](../../game/art/audio/voices/ch1/ch1_tutorial_blacksmith/%E9%93%81%E5%8C%A0%E5%88%98_start.mp3) · 0 字节
- [art/audio/voices/ch1/ch1_tutorial_blacksmith/铁匠刘_tip.mp3](../../game/art/audio/voices/ch1/ch1_tutorial_blacksmith/%E9%93%81%E5%8C%A0%E5%88%98_tip.mp3) · 0 字节
- [art/audio/voices/ch1/ch1_tutorial_duqingshan/杜青衫_n3.mp3](../../game/art/audio/voices/ch1/ch1_tutorial_duqingshan/%E6%9D%9C%E9%9D%92%E8%A1%AB_n3.mp3) · 32,112 字节，Godot 无有效音频
- [art/audio/voices/ch1/ch1_tutorial_duqingshan/杜青衫_n5.mp3](../../game/art/audio/voices/ch1/ch1_tutorial_duqingshan/%E6%9D%9C%E9%9D%92%E8%A1%AB_n5.mp3) · 67,248 字节，Godot 无有效音频
- [art/audio/voices/ch1/ch1_tutorial_duqingshan/杜青衫_start.mp3](../../game/art/audio/voices/ch1/ch1_tutorial_duqingshan/%E6%9D%9C%E9%9D%92%E8%A1%AB_start.mp3) · 58,752 字节，Godot 无有效音频
- [art/audio/voices/ch1/ch1_tutorial_duqingshan_after_sword/杜青衫_start.mp3](../../game/art/audio/voices/ch1/ch1_tutorial_duqingshan_after_sword/%E6%9D%9C%E9%9D%92%E8%A1%AB_start.mp3) · 40,896 字节，Godot 无有效音频
- [art/audio/voices/ch1/ch1_tutorial_duqingshan_idle/杜青衫_n2.mp3](../../game/art/audio/voices/ch1/ch1_tutorial_duqingshan_idle/%E6%9D%9C%E9%9D%92%E8%A1%AB_n2.mp3) · 47,088 字节，Godot 无有效音频
- [art/audio/voices/ch1/ch1_tutorial_duqingshan_idle/杜青衫_start.mp3](../../game/art/audio/voices/ch1/ch1_tutorial_duqingshan_idle/%E6%9D%9C%E9%9D%92%E8%A1%AB_start.mp3) · 56,016 字节，Godot 无有效音频
- [art/audio/voices/ch1/杜青衫/ch1_main_street_duqingshan.mp3](../../game/art/audio/voices/ch1/%E6%9D%9C%E9%9D%92%E8%A1%AB/ch1_main_street_duqingshan.mp3) · 56,016 字节，Godot 无有效音频
- [art/audio/voices/ch1/江湖散兵/ch1_road_corpse.mp3](../../game/art/audio/voices/ch1/%E6%B1%9F%E6%B9%96%E6%95%A3%E5%85%B5/ch1_road_corpse.mp3) · 0 字节
- [art/audio/voices/ch1/蒙面杀手乙/ch1_forest_yuewuxing.mp3](../../game/art/audio/voices/ch1/%E8%92%99%E9%9D%A2%E6%9D%80%E6%89%8B%E4%B9%99/ch1_forest_yuewuxing.mp3) · 0 字节
- [art/audio/voices/ch1/蒙面杀手甲/ch1_forest_yuewuxing.mp3](../../game/art/audio/voices/ch1/%E8%92%99%E9%9D%A2%E6%9D%80%E6%89%8B%E7%94%B2/ch1_forest_yuewuxing.mp3) · 0 字节
- [art/audio/voices/ch1/蒙面杀手首领/ch1_forest_victory.mp3](../../game/art/audio/voices/ch1/%E8%92%99%E9%9D%A2%E6%9D%80%E6%89%8B%E9%A6%96%E9%A2%86/ch1_forest_victory.mp3) · 0 字节
- [art/audio/voices/ch1/铁匠刘/ch1_tutorial_blacksmith.mp3](../../game/art/audio/voices/ch1/%E9%93%81%E5%8C%A0%E5%88%98/ch1_tutorial_blacksmith.mp3) · 0 字节
