# 场景巡检索引 · 2026-11-12

这是静态登记表，不是逐图实机验收表。扫描 `game/data/scenes` 顶层全部 106 个 `.tres`（其中第 2–8 章 45 个）。结合桌面 `SceneRouter` 标注专用接管、旧别名和历史大地图；普通表项仍可能有事件、状态和运行时覆盖。对象纹理统计仅检查直接引用的布局；无独立对象不表示画面没有家具，也不等于缺陷。

## 顶层资源逐项

| 场景 ID | 资源中的显示名（接管后可能不同） | 静态分类 | 声明布局（非最终画面保证） |
| --- | --- | --- | --- |
| `adventure_luoyang_riverside_route` | 古寺外 · 岸驿曲径 | 声明了布局，待抽镜 | `luoyang_riverside_layout.tres` |
| `adventure_xiangzhou_deep_mine` | 襄州深矿 | 声明了布局，待抽镜 | `mine_layout.tres` |
| `adventure_zhuwei_hunting_ground` | 竹尾猎径 | 声明了布局，待抽镜 | `forest_layout.tres` |
| `ch1_s0_linxi_main_walkable` | 林西村 · 主街 | 正常入口待证 | `ch1_s0_linxi_main_layout_v2.tres` |
| `ch1_s1_road` | 林西村外 · 山道 | 专用场景 | `ch1_s1_road_layout_v5.tres` |
| `ch1_s2_qingfeng_walkable` | 竹尾村 · 村口 | 旧别名 | — |
| `ch1_s2_qingfeng` | 竹尾村 · 主街 | 专用场景 | `ch1_s2_qingfeng_layout_v2.tres` |
| `ch1_s3_ruin_inner` | 城西废宅 · 内堂 | 有背景、未检出独立纹理物件 | `ch1_s3_ruin_inner_layout_v1.tres` |
| `ch1_s3_west_ruin` | 竹尾村 · 城西废宅 | 有背景、未检出独立纹理物件 | `ch1_s3_west_ruin_layout_v2.tres` |
| `ch1_s3_zhuwei_forest` | 竹尾村外 · 后山密林 | 声明了布局，待抽镜 | `ch1_s3_zhuwei_forest_layout_v2.tres` |
| `ch1_s4_cave_deep_den` | 后山洞窟 · 头狼深窟 | 有背景、未检出独立纹理物件 | `ch1_s4_cave_deep_den_layout_v1.tres` |
| `ch1_s4_cave_mine_gallery` | 后山洞窟 · 废弃矿道 | 声明了布局，待抽镜 | `ch1_s4_cave_mine_gallery_layout_v2.tres` |
| `ch1_s4_cave_waterway` | 后山洞窟 · 地下水道 | 有背景、未检出独立纹理物件 | `ch1_s4_cave_waterway_layout_v1.tres` |
| `ch1_s4_zhuwei_beast_cave` | 后山洞窟 · 入口营地 | 有背景、未检出独立纹理物件 | `ch1_s4_zhuwei_beast_cave_layout_v3.tres` |
| `ch2_s1_market_inn` | 竹尾晨市 · 客栈大堂 | 声明了布局，待抽镜 | `ch2_s1_market_inn_layout_v2.tres` |
| `ch2_s1_market_training_hall` | 竹尾晨市 · 武馆 | 声明了布局，待抽镜 | `ch2_s1_market_training_hall_layout_v2.tres` |
| `ch2_s1_zhuwei_market` | 竹尾村 · 晨市 | 专用场景 | `ch2_s1_zhuwei_market_layout_v3.tres` |
| `ch2_s2_forest_edge` | 竹尾村外 · 北林旧道 | 声明了布局，待抽镜 | `ch2_s2_forest_edge_layout_v2.tres` |
| `ch2_s3_forest_ambush` | 密林 · 伏击场 | 声明了布局，待抽镜 | `ch2_s3_forest_ambush_layout_v2.tres` |
| `ch2_s4_lingyue_gate` | 凌月派 · 山门 | 专用场景 | `ch2_s4_lingyue_gate_layout_v1.tres` |
| `ch2_s5_bandit_cave` | 北林旧矿洞 · 废轨入口 | 声明了布局，待抽镜 | `ch2_s5_bandit_cave_entrance_layout_v3.tres` |
| `ch2_s5_mine_command` | 北林旧矿洞 · 深处账房 | 声明了布局，待抽镜 | `ch2_s5_mine_command_layout_v3.tres` |
| `ch2_s5_mine_workshop` | 北林旧矿洞 · 伪牌作坊 | 声明了布局，待抽镜 | `ch2_s5_mine_workshop_layout_v3.tres` |
| `ch2_s6_river_camp` | 竹尾村外·河滩营地 | 声明了布局，待抽镜 | `ch2_s6_river_camp_layout_v2.tres` |
| `ch3_s1_wulin_assembly` | 武林大会 · 长案前 | 声明了布局，待抽镜 | `ch3_s1_wulin_assembly_layout_v2.tres` |
| `ch3_s2_trial_ground` | 武林大会 · 考校场 | 声明了布局，待抽镜 | `ch3_s2_trial_ground_layout_v2.tres` |
| `ch3_s3_faction_training` | 五派营地·合练场 | 声明了布局，待抽镜 | `ch3_s3_faction_training_layout_v2.tres` |
| `ch3_s4_forbidden_tomb` | 大会后山·封禁石窟 | 声明了布局，待抽镜 | `ch3_s4_forbidden_tomb_layout_v2.tres` |
| `ch4_s0_luoyang_gate` | 洛阳 · 南城门 | 洛阳专用接管 | `ch4_s0_luoyang_gate_layout.tres` |
| `ch4_s1_luoyang_yamen` | 洛阳 · 府衙外院 | 洛阳专用接管 | `ch4_s1_luoyang_yamen_layout.tres` |
| `ch4_s2_canal_docks` | 洛阳 · 漕渠码头 | 洛阳专用接管 | `ch4_s2_canal_docks_layout.tres` |
| `ch4_s3_luoyang_market` | 洛阳 · 南市 | 洛阳专用接管 | `ch4_s3_luoyang_market_layout.tres` |
| `ch4_s4_ancient_temple` | 洛阳城外 · 古寺 | 洛阳专用接管 | `ch4_s4_ancient_temple_layout_v1.tres` |
| `ch4_s5_temple_tunnel` | 古寺·地下运货道 | 声明了布局，待抽镜 | `ch4_s5_temple_tunnel_layout_v2.tres` |
| `ch5_s1_relief_road` | 古峰 · 赈粮路 | 声明了布局，待抽镜 | `ch5_s1_relief_road_layout_v2.tres` |
| `ch5_s2_grain_convoy_camp` | 古峰 · 护粮营地 | 声明了布局，待抽镜 | `ch5_s2_grain_convoy_camp_layout_v3.tres` |
| `ch5_s3_snow_pass` | 古峰 · 雪岭关 | 声明了布局，待抽镜 | `ch5_s3_snow_pass_layout_v2.tres` |
| `ch5_s4_abandoned_mine` | 古峰 · 废弃矿道 | 声明了布局，待抽镜 | `ch5_s4_abandoned_mine_layout_v2_modular.tres` |
| `ch5_s5_false_banner_outpost` | 古峰 · 伪旗营地 | 声明了布局，待抽镜 | `ch5_s5_false_banner_outpost_layout_v2_modular.tres` |
| `ch6_s3_underground_archive` | 林西村 · 地下档案室 | 声明了布局，待抽镜 | `ch6_s3_underground_archive_layout_v2.tres` |
| `ch6_s4_baishui_convoy_route` | 林西村外 · 白水驿旧路 | 声明了布局，待抽镜 | `ch6_s4_baishui_convoy_route_layout_v2.tres` |
| `ch6_s5_ancient_road_inn` | 林西村外 · 古道客栈 | 声明了布局，待抽镜 | `ch6_s5_ancient_road_inn_layout_v2.tres` |
| `ch7_s1_lieyun_valley_ferry` | 烈云峡谷 · 旧渡 | 专用场景 | `ch7_s1_lieyun_valley_ferry_layout_v1.tres` |
| `ch7_s10_lieyun_night_transfer_station` | 烈云旧渡 · 夜航转运栈 | 声明了布局，待抽镜 | `ch7_s10_lieyun_night_transfer_station_layout_v2.tres` |
| `ch7_s2_mingwu_tea_town` | 茗雾山 · 茶镇 | 专用场景 | `ch7_s2_mingwu_tea_town_layout_v1.tres` |
| `ch7_s3_lieyun_outpost_outer_ward` | 烈云分舵 · 外区 | 声明了布局，待抽镜 | `ch7_s3_lieyun_outpost_outer_ward_layout_v2.tres` |
| `ch7_s4_mingwu_manor_outer_court` | 茗雾山庄 · 外院 | 声明了布局，待抽镜 | `ch7_s4_mingwu_manor_outer_court_layout_v2.tres` |
| `ch7_s5_lieyun_assembly_hall` | 烈云分舵 · 聚义厅 | 声明了布局，待抽镜 | `ch7_s5_lieyun_assembly_hall_layout_v2.tres` |
| `ch7_s6_mingwu_inner_court` | 茗雾山庄 · 内院 | 声明了布局，待抽镜 | `ch7_s6_mingwu_inner_court_layout_v2.tres` |
| `ch7_s7_lieyun_resettlement_archive` | 烈云分舵 · 安置档案室 | 声明了布局，待抽镜 | `ch7_s7_lieyun_resettlement_archive_layout_v2.tres` |
| `ch7_s8_mingwu_permission_archive` | 茗雾山庄 · 权限档案房 | 声明了布局，待抽镜 | `ch7_s8_mingwu_permission_archive_layout_v2.tres` |
| `ch7_s9_mingwu_seal_audit_room` | 茗雾山庄 · 封印审验室 | 声明了布局，待抽镜 | `ch7_s9_mingwu_seal_audit_room_layout_v2.tres` |
| `ch8_s1_alliance_staging_ground` | 茗雾外围 · 会盟集结地 | 声明了布局，待抽镜 | `ch8_s1_alliance_staging_ground_layout_v2.tres` |
| `ch8_s2_mistwood_blockade` | 茗雾外围 · 雾林阻截场 | 声明了布局，待抽镜 | `ch8_s2_mistwood_blockade_layout_v2.tres` |
| `ch8_s3_manor_perimeter_encampment` | 茗雾山庄 · 外围连营 | 声明了布局，待抽镜 | `ch8_s3_manor_perimeter_encampment_layout_v2.tres` |
| `ch8_s4_alliance_mechanism_gallery` | 会盟祭台下 · 机关廊 | 有背景、未检出独立纹理物件 | `ch8_s4_alliance_mechanism_gallery_layout_v1.tres` |
| `ch8_s5_alliance_ceremonial_platform` | 茗雾山庄 · 会盟祭台 | 有背景、未检出独立纹理物件 | `ch8_s5_alliance_ceremonial_platform_layout_v1.tres` |
| `ch8_s6_mingwu_main_hall` | 茗雾山庄 · 正厅 | 有背景、未检出独立纹理物件 | `ch8_s6_mingwu_main_hall_layout_v1.tres` |
| `ch8_s7_mingwu_rear_sanctum` | 茗雾山庄 · 后殿 | 有背景、未检出独立纹理物件 | `ch8_s7_mingwu_rear_sanctum_layout_v1.tres` |
| `interior_bandit_cave` | 山道·山贼洞窟 | 声明了布局，待抽镜 | `interior_bandit_cave_layout_v2.tres` |
| `interior_inn_hall` | 竹尾村·客栈大堂 | 声明了布局，待抽镜 | `interior_inn_hall_layout_v2.tres` |
| `interior_martial_hall` | 林西村·武馆 | 正常入口待证 | `interior_martial_hall_layout_v1.tres` |
| `interior_temple_tunnel` | 古寺·地道 | 正常入口待证 | `interior_temple_tunnel_layout_v1.tres` |
| `linxi_farmer_cottage` | 林西村 · 村民家 | 声明了布局，待抽镜 | `linxi_farmer_cottage_layout_v1.tres` |
| `linxi_herbal_home` | 林西村 · 采药人家 | 声明了布局，待抽镜 | `linxi_herbal_home_layout_v1.tres` |
| `linxi_hero_bedroom` | 林西村 - 冷孤云的卧室 | 声明了布局，待抽镜 | `linxi_hero_bedroom_layout_v1.tres` |
| `linxi_master_hall` | 林西村 - 师傅正屋 | 有背景、未检出独立纹理物件 | `linxi_master_hall_layout_v3.tres` |
| `linxi_scholar_house` | 林西村 · 私塾旧宅 | 有背景、未检出独立纹理物件 | `linxi_scholar_house_layout_v1.tres` |
| `linxi_south_apothecary_home` | 林西村南坊 · 药铺内堂 | 有背景、未检出独立纹理物件 | `linxi_south_apothecary_home_layout_v1.tres` |
| `linxi_south_scholar_house` | 林西村南坊 · 私塾 | 有背景、未检出独立纹理物件 | `linxi_south_classroom_layout_v1.tres` |
| `linxi_south_villager_home` | 林西村南坊 · 民居 | 有背景、未检出独立纹理物件 | `linxi_south_villager_home_layout_v1.tres` |
| `linxi_tutorial` | 林西村 · 师徒院落 | 专用场景 | `linxi_tutorial_layout_v2.tres` |
| `linxi_village_center` | 林西村 · 村中心 | 专用场景 | `linxi_village_center_layout_v1.tres` |
| `linxi_village_scrollmap` | 林西村 · 南坊 | 专用场景 | `linxi_village_scrollmap_layout_v1.tres` |
| `openworld_bailu_ferry` | 白鹿渡 · 接驳栈 | 专用场景 | `openworld_bailu_ferry_layout.tres` |
| `openworld_bianzhou_city` | 汴州城 · 中轴坊市 | 专用场景 | `openworld_bianzhou_city_layout_v2.tres` |
| `openworld_bianzhou_old_post` | 中原旧驿 · 荒道 | 声明了布局，待抽镜 | `openworld_bianzhou_old_post_layout_v2.tres` |
| `openworld_desert_city` | 沙漠城 | 专用场景 | — |
| `openworld_east_sea_port` | 东海埠 · 内河接驳栈 | 专用场景 | `openworld_east_sea_port_layout.tres` |
| `openworld_huashan_forecourt` | 华山派 · 山门 | 专用场景 | `openworld_huashan_forecourt_layout_v2.tres` |
| `openworld_huashan_sword_terrace` | 华山派 · 演武坪 | 声明了布局，待抽镜 | `openworld_huashan_sword_terrace_layout_v2.tres` |
| `openworld_huashan_waterfall_terrace` | 华山派 · 观瀑剑台 | 声明了布局，待抽镜 | `openworld_huashan_waterfall_terrace_layout_v2.tres` |
| `openworld_jinling_city` | 金陵城 · 水巷桥市 | 专用场景 | `openworld_jinling_city_layout_v2.tres` |
| `openworld_jinling_reed_marsh` | 江南芦荡 · 水泽 | 声明了布局，待抽镜 | `openworld_jinling_reed_marsh_layout_v2.tres` |
| `openworld_lanxi_zhai` | 岚溪寨 | 专用场景 | — |
| `openworld_lingyue_inner_court` | 凌月派 · 内庭 | 声明了布局，待抽镜 | `openworld_lingyue_inner_court_layout_v2.tres` |
| `openworld_qinghe_town` | 清河镇 · 行旅街 | 专用场景 | `openworld_qinghe_town_layout.tres` |
| `openworld_redrock_town` | 赤岩镇 | 专用场景 | — |
| `openworld_v15_bamboo_outskirts` | 林西竹溪林 · 建议2～4级 | 旧郊外方案，非新版 | `openworld_v15_bamboo_outskirts_layout_v1.tres` |
| `openworld_v15_forest_outskirts` | 襄州密林 · 建议7～8级 | 旧郊外方案，非新版 | `openworld_v15_forest_outskirts_layout_v1.tres` |
| `openworld_v15_marsh_outskirts` | 金陵南泽 · 建议10～11级 | 旧郊外方案，非新版 | `openworld_v15_marsh_outskirts_layout_v1.tres` |
| `openworld_wudang_gate` | 武当派 · 山门 | 专用场景 | `openworld_wudang_gate_layout_v1.tres` |
| `openworld_wudang_purple_cloud_court` | 武当派 · 紫霄宫前庭 | 声明了布局，待抽镜 | `openworld_wudang_purple_cloud_court_layout_v2.tres` |
| `openworld_wudang_taiji_court` | 武当派 · 太极场 | 专用场景 | `openworld_wudang_taiji_court_layout_v1.tres` |
| `openworld_xiangzhou_city` | 襄州城 · 江防校场 | 专用场景 | `openworld_xiangzhou_city_layout_v2.tres` |
| `openworld_xiangzhou_mine_valley` | 襄州矿谷 · 采坑 | 声明了布局，待抽镜 | `openworld_xiangzhou_mine_valley_layout_v2.tres` |
| `openworld_yanmen_hidden_cave` | 雁门关 · 寒岭藏剑洞 | 有背景、未检出独立纹理物件 | `openworld_yanmen_hidden_cave_layout.tres` |
| `openworld_yanmen_pass` | 雁门关 · 关外雪径 | 专用场景 | `openworld_yanmen_pass_layout.tres` |
| `world_map_jianghu_v13_staging` | 江湖行旅图 · v13 分层预览 | 历史地图／候选，不作现版 | `world_map_jianghu_v13_staging_layout.tres` |
| `world_map_jianghu_v14` | 江湖行旅图 | 历史地图／候选，不作现版 | `world_map_jianghu_layout_v14.tres` |
| `world_map_jianghu_v15` | 江湖行旅图 | 历史地图／候选，不作现版 | `world_map_jianghu_layout_v15.tres` |
| `world_map_jianghu` | 江湖行旅图 | 正式大地图逻辑入口 | — |
| `world_map_layered_cc0_candidate_20260929` | 中原授权物件分层候选（视觉未通过） | 历史地图／候选，不作现版 | `world_map_layered_cc0_candidate_20260929_layout.tres` |
| `world_map_layered_prototype_20260928` | 中原地形分层试样 | 历史地图／候选，不作现版 | `world_map_layered_prototype_20260928_layout.tres` |
| `world_map_native_coast_gen_v2_candidate_20260929` | 中原至东岸分层候选（待验收） | 历史地图／候选，不作现版 | `world_map_native_coast_gen_v2_candidate_20260929_layout.tres` |
| `yihongyuan27n_interior` | 怡红院·接待厅与雅座 | 洛阳专用接管 | — |

## 桌面注册表的额外目标

- 大地图现版 `world_map_jianghu_v16`：由 `world_contract_dispatch03.gd` 转到 `world_v16_scene03.tres`，不以顶层 v13/v14/v15 资源评现版画面。
- 洛阳府衙街／南市共用 `luoyang_civic_market_region_27d`，另有 `luoyang_estate_region_27d`、`luoyang_temple_region_27d`；这三项是区域宿主，不额外当成三个独立城市。宅园另有 `estate27d_living_hall`、`estate27d_west_study`、`estate27d_east_bedroom`；古寺另有 `temple27d_main_hall`、`temple27d_monks_room`、`temple27d_sutra_room`；怡红院另有 `yihongyuan27n_upper`。
- 百工民坊 `luoyang_artisan_residential_20261022ap`、洛水园林 `luoyang_riverside_garden_20261022ap`、宅园旧入口别名 `luoyang_estate_riverside_20261021ai` 按各自路由对照，不能仅用主城顶层表项覆盖。
- `luoyang_layout_rooms_20261018t/registry.json` 的 12 项房间定义：`luoyang_canal_warehouse_interior_20261016`、`luoyang_functional_mansion_candidate_20261016`、`luoyang_functional_pawnshop_candidate_20261016`、`luoyang_market_inn_interior_20261015`、`luoyang_market_market_east_ward_frontage_interior_20261015`、`luoyang_market_market_northeast_rear_frontage_interior_20261015`、`luoyang_market_market_northwest_rear_frontage_interior_20261015`、`luoyang_market_market_west_ward_frontage_interior_20261015`、`luoyang_market_north_market_front_interior_20261015`、`luoyang_market_shop_interior_20261015`、`luoyang_market_southeast_market_front_interior_20261015`、`luoyang_yamen_official_hall_20261018t`。这是登记定义，不宣称每个门都启用；需沿对应街区正式门复核。

未将 `game/build` 中所有试验副本纳入计数，也未把尚未核实的动态事件小房间视为通过。
