extends SceneTree
## Two original bounties after NORMAL_SHOP_EQUIP_HEAL visible UI strategy. Not a SIX slot.
## Passive health strategy_modified=false applies only to the unchanged D699 observer.
## Requires outer before/after source and all15 player precise UTC ticks.
## No world15, historical migration, approval signing or production writes.
const PHASE_PATH := "res://tests/helpers/luoyang_enclosure_v11_bounty_shop_equip_heal_phase_20261012.gd"
const SAVE_PATH := "res://tests/helpers/luoyang_enclosure_v11_city_only_current_save.gd"
const RAW_PATH := "res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd"
const TARGET_RAW_PATH := "res://tests/helpers/luoyang_enclosure_v11_target_root_and_feet_raw_20261011.gd"
const CONTRACT_PATH := "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const ENGINE_SHA := "975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
const BRIDGE_PATH := "res://scripts/autoload/platform_bridge.gd"
const BRIDGE_SHA := "eec9dd3cc56e310c436ff542e3ed4228c9f7216be8608b6959c69717718c500a"
const IDS: Array[String]=["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
const PROTECTED: Array[String]=["res://data/scenes/world_map_jianghu.tres","res://data/config/outskirts_native_adoption.json"]
const MUSIC_TRACK_IDS: Array[String]=["city_luoyang","city_bianzhou","city_jinling","city_xiangzhou","town_qinghe","pass_yanmen","village_zhuwei","village_night","outskirts_zhuxi_linxi","outskirts_forest_xiangzhou","outskirts_wetland_jinling","story_tension","story_warm","story_joy","story_danger","battle_spar","battle_river","battle_village","battle_mountain","battle_boss","exploration_mountain","exploration_journey","battle_default"]
const BOUNTY_SOURCES: Array[String]=[
	"res://scenes/bounty_board.tscn",
	"res://scripts/ui/bounty_board.gd",
	"res://scripts/autoload/bounty_manager.gd",
	"res://scripts/domain/bounty_def.gd",
	"res://data/bounties/luoyang_red_scar.tres",
	"res://data/bounties/luoyang_seal_thief.tres",
	"res://data/scenes/openworld_bianzhou_old_post.tres",
	"res://data/scenes/openworld_xiangzhou_mine_valley.tres",
	"res://data/enemies/bounty_red_scar.tres",
	"res://data/enemies/central_road_scout.tres",
	"res://data/enemies/bounty_seal_thief.tres",
	"res://data/enemies/mine_outlaw.tres",
	"res://data/enemies/central_road_raider.tres",
	"res://data/enemies/mine_brute.tres",
]
const PINNED: Dictionary={
	"res://tests/helpers/battle_shop_equip_heal_ui_probe_20261012.gd":"0deeab11e38cd72be41e31395a7f75274e70dfa65992d58583fef4a5c6f89a1e",
	"res://tests/helpers/luoyang_enclosure_v11_bounty_travel_ready_health_phase_20261012.gd":"f5a5551fe19c94cf44636a24494c8d4d4b76a8986e28265b07e075b33d2a2922",
	"res://tests/test_luoyang_enclosure_v11_bounty_travel_ready_health_20261012.gd":"2a30c2b15aac2091f98e31de967169fa6e226f53ae79888ae4a9efd235d969ac",
	"res://tests/helpers/luoyang_enclosure_v11_bounty_shop_equip_heal_phase_20261012.gd":"6c917be98bcec9da616b467e6d4d1bd96666e1e0b7bc03f84a779d40849f3971",
	"res://tests/helpers/luoyang_bounty_health_observation_input_driver_20261012.gd":"d69975fc078b31277b6ed747076c8e1d6d42ed0bcddab090157a90b485ada7b8",
	"res://tests/test_luoyang_enclosure_v11_bounty_live_field_continuation_20261011.gd":"307f9419db38b10ef03230e96a74ee3a0f8b62cc1a00afa9c307ec53dc083888",
	"res://scripts/autoload/loading_manager.gd":"019a2210d6bfd3d13a2d6c939389d3f67c6c9671ffa36d89c563f54fc4b07910",
	"res://scripts/autoload/event_bus.gd":"c42bdb64161dfec0aa7e65e6027b0b335dee358f84558068abb54ccd26785db8",
	"res://scripts/domain/character_stats.gd":"2e502cb6868981ebed1e4c81b88179467fa4dd2aa55e9f0260cfb6002e0aa6a0",
	"res://scripts/battle/battle_combatant.gd":"0c7bcfc193ece9b42ec27e66dca589b5765a9218e2967e79f201d139b367db29",
	"res://tests/helpers/luoyang_enclosure_v11_bounty_encounter_continuation_phase_20261011.gd":"07f171092bec8669dbd25a62ac50ce363c573120a8b023d168810f0a25066893",
	"res://tests/test_luoyang_enclosure_v11_bounty_encounter_continuation_20261011.gd":"e76592e680602a6e48dc18cec2171e7cd2e3900ae24060b61378d1635540d92b",
	"res://tests/helpers/luoyang_bounty_live_field_input_driver_20261011.gd":"905a37e4170bb4fbc0a1f661602262910508c8574858670820d48f0a4d142199",
	"res://scenes/battle.tscn":"8476a5c23a4eec1194d65a390daeaebf860d93845f203aed9e2768d8907cbaa9",
	"res://scripts/battle/battle_controller.gd":"bad948d80679350289dc70c1a550c522a8173cc4c88bef75f02b2db3e6b4a087",
	"res://tests/helpers/luoyang_enclosure_v11_bounty_only_observation_phase_20261011.gd":"5932a7f6cd156b7e70b37f3ad463da80a63d6abd7b6343f11b2795dab7ad4546",
	"res://tests/test_luoyang_enclosure_v11_bounty_only_observation_20261011.gd":"4a2867577a8877fda36b4d69c4617d3d6027c3e0d46c775ae516fa08d2d04095",
	"res://tests/helpers/luoyang_enclosure_v11_bounty_live_field_continuation_phase_20261011.gd":"9e59b6977d8dee0ee4bc349d2ecdddec2d3760b5357508892da4dc404768ec65",
	"res://tests/test_luoyang_enclosure_v11_authored_input_repairs_focused_20261011.gd":"d4973b585fb84baa8c73ed2aadd124705b62264f3f7586dc090eef4ddc2e8277",
	"res://scripts/ui/bounty_board.gd":"c6646f2da0a75527dfc41196081f806a6a08de7f77725a6af567a735487c4583",
	"res://scripts/autoload/bounty_manager.gd":"823a22d748d4ee846b5d68c6479b4e7d0ffd3e8fe859a8525dc0aa9db42111ed",
	"res://data/bounties/luoyang_red_scar.tres":"49420f431307ddc913d5671872d0d843d27d47c3446e3cbda942ab5083201463",
	"res://data/bounties/luoyang_seal_thief.tres":"64b4ed66c835789811bb5baa05ad725f422143c0f6bbfaca9906839df6034a24",
	"res://scripts/audio/music_catalog.gd":"cafbabdd3d82f1ebf6d694e9cc6f2eb2cf04744a4febb36a0503eb0cdf3c39e4",
	"res://scripts/autoload/scene_router.gd":"f3ead7459632188350e1e3383ee915c83b71c1b86d36dadf718bd338a4324eca",
	"res://tests/helpers/luoyang_enclosure_v11_authored_input_repairs_focused_phase_20261011.gd":"9bd4bc5115c5611365b8c7fd390d2fcd07a607c2bcc5f460b45dad8ac58f93da",
	"res://tests/helpers/luoyang_enclosure_v11_city_only_indirect_market_return_phase_20261011.gd":"3c37cf6568f1cd1ba6d41c28c276879ca6a352205c9c5a9f8b8acdaabf0ab1a6",
	"res://tests/helpers/luoyang_enclosure_v11_city_only_phase.gd":"47006fbee07d3d4c88c223816ca3876bdfde2bf3b1583ff5b6ca674c2944045a",
	"res://scripts/field/field_walkable_controller.gd":"e545834700715e23540a5036ffaeb01e2ba412b62e14f81c5abd7b28a08ee1ed",
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"558a3edfaa368ff52b67ff0eaade7505191011928c2a724897efc727e43887f6",
	"res://tests/helpers/luoyang_wasapi_catalog3_continuity_20261011.gd":"62acbff384fecf1de7309907745c2e736bdaefd6f3b3d34b7e8dcb86fe9e9f6a",
	"res://tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd":"3291a768f9cab0ca7ae8d348f4d86532c3aefb846d0749424663dcc13d07b892",
	"res://scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd":"f926cf876da1afe746411ff5a007a49894b191040e57e709bdbc486021b3e535",
	"res://scripts/city/luoyang_city3_motion_guard_20261009.gd":"aacd53e5020bc5a40353d9cf7537662c44139fa7f861e3a54c6faf59e8ba3a93",
	"res://scripts/field/player.gd":"9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419",
	"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://data/scenes/world_map_jianghu.tres":"838380fdb05d08b4b521d92efb12a13369358090740dc5c7d4cb7c9ec6f4c015",
	"res://data/maps/world_map_jianghu_layout_v14.tres":"3dfa1f251b5a5319b8cc6d6b902932fde6382470ae597c697e391252e98f2b3b",
}
## Finite current Shop/Inventory authored stock+UI literal resource closure.
## Imports and deps.dest_files are additionally tracked by the original _track.
const SHOP_PINNED: Dictionary={
	"res://art/ui/button/btn_menu_frame_hover.png":"fad9845347518f27bfbaab111dc4da48a9a72441ca76d949c765403dd1bffa2c",
	"res://art/ui/button/btn_menu_frame_normal.png":"6d15e3ac0e92c26a3448fd4ad912e878c6584535c44273bf56edcab93804bc65",
	"res://art/ui/button/btn_menu_frame_pressed.png":"61f25c346d96459c8fba0109089e9e57e8562d09c56ca3f85788c0dc2df6da3e",
	"res://art/ui/character/character_confirm_panel_v2.png":"c006a4ed3d3f1dde26f6a17e70c4f4254b3eef922fb592bc5665a0cdb41270f8",
	"res://art/ui/inventory/buttons/btn_close_hover.png":"cdd6136523fd2e91c4d58a12a1db8849b0037f4a9c6c7d6487b86d7006eaae20",
	"res://art/ui/inventory/buttons/btn_close_normal.png":"f967a3bd8793c5b2f1d25acee9d9368801988da1288589148568ff456b11d92a",
	"res://art/ui/inventory/buttons/btn_close_pressed.png":"1aa6a3c27291caa6435e6076c03b34e2fe85e188e1595b3d7d0e87e8a2a6a1d4",
	"res://art/ui/inventory/buttons/btn_drop_hover.png":"00ae1c20af292999a9ddfdf7840f4fe1bd282be417f5d6912fc7e73b895f99f8",
	"res://art/ui/inventory/buttons/btn_drop_normal.png":"f81f248bda3e05100337f10767a838b578d0927d70cbfe9518de1c4ed72dc9f3",
	"res://art/ui/inventory/buttons/btn_drop_pressed.png":"37ccdef743550f5e21bbcc815e34d2f9f7b38be4b9f82ae77e70caab61e42128",
	"res://art/ui/inventory/buttons/btn_equip_hover.png":"584ee3264169a72a275eabc794aa784aa8a9c2be6b8eaac4b563c3da7d0b9dab",
	"res://art/ui/inventory/buttons/btn_equip_normal.png":"dab72799440c66b6b3ac84d72f9c400cc5297b7c63db5b310a9fff8d3e446c0c",
	"res://art/ui/inventory/buttons/btn_equip_pressed.png":"ad47108c1d91907b5a8775d9871d036c014bdb98ff0b0ae7f5b28ac908b45551",
	"res://art/ui/inventory/buttons/btn_use_hover.png":"851c62db49c65511d7e96408606b36c43e5cace4a30edd85e32424720c2ad46b",
	"res://art/ui/inventory/buttons/btn_use_normal.png":"9b7db5bbe15075e260dd567ed4236c11b154422faa5a325c8b11a01cfa15de8f",
	"res://art/ui/inventory/buttons/btn_use_pressed.png":"05b984ce45288c1cf96ae8e36b6d1c5eec073ec42c264742f482e32ece9d2a00",
	"res://art/ui/inventory/buttons/btn_x_hover.png":"08bfb1788e6b0f46d7816377bd6581997663480107454353330c9d7f5c6ca069",
	"res://art/ui/inventory/buttons/btn_x_normal.png":"1456ec79a4f48260cb8b9b7364e0166c8eb9b9eef26f5939954619d8c6fc082a",
	"res://art/ui/inventory/buttons/btn_x_pressed.png":"b377b64f4fa01d40bb1560ec7e91f8bc1b97d95c322ea8793c073b7f55e7b267",
	"res://art/ui/inventory/cells/cell_default.png":"9f68a094dd8c5f40b5c394f72e8b13f3cb88478c822a7530d31a2a6a8a3123fd",
	"res://art/ui/inventory/cells/cell_empty.png":"c140dee1837f31fc37ec41e7e5da8a8a656b5a2d5c4de12627f9297f8aef6864",
	"res://art/ui/inventory/cells/cell_selected.png":"14d22882c4e57a3f3d55dc6301d94e5cfa1b82d61088370c7ba2b2efb5927558",
	"res://art/ui/inventory/icons/icon_antidote_pill.png":"097a17431b3d4d192ce982bba0293c91e96d86f61aff69bee16f192d7b4c0687",
	"res://art/ui/inventory/icons/icon_armor.png":"c75b14c35bf1b02f9317fd83e89069af3fbc928e623e0f47b551a47bb3e8ac99",
	"res://art/ui/inventory/icons/icon_battle_helmet.png":"a9ee5c9a8ff966e4cf118732cfd845119275b09059f5f131375f2cc62db6a6ee",
	"res://art/ui/inventory/icons/icon_cloth_boots.png":"a5d9942b55de767376e5a9c2fdf798efbce392ce630f6fa07c01f0e1d9d529b5",
	"res://art/ui/inventory/icons/icon_deer_leather_boots.png":"9bdfe7821c1c47a1a15e2b8743b62050523e4a82014e2cbbffabc605ee556b26",
	"res://art/ui/inventory/icons/icon_dragon_horn_crown.png":"3a78efe31b007e0c7db899315e1a7fa0a1a65415c95edd51a3f571087de7b355",
	"res://art/ui/inventory/icons/icon_dragon_scale_armor.png":"d9b4a18ea4029c7c0abcb5f1256997cee8afea5e914e872882edc5b0c370d3e3",
	"res://art/ui/inventory/icons/icon_dragon_scale_bracers.png":"3df811fca91ad56c553cd76a0212b81cd2071b062b02c63a482f65e7b382e651",
	"res://art/ui/inventory/icons/icon_dragon_tendon_staff.png":"c026f892e52eac4076ce07ecb8a908c70da5c910986d9632394709279916dfe8",
	"res://art/ui/inventory/icons/icon_healing_pill_minor.png":"87fa06b93218c8f90312636430b3edd29c07cf50b1d8a43c13c31169345a0447",
	"res://art/ui/inventory/icons/icon_heavy_iron_sword.png":"153d650279dd7772732ae649a3c44bfc78d59d598f2704fac1fdb111a50a0b4e",
	"res://art/ui/inventory/icons/icon_iron_great_blade.png":"bc8726c521e9060ec8014194419eec72b54530d4becc3317d22cc93cf5cc7f3e",
	"res://art/ui/inventory/icons/icon_iron_helmet.png":"81dfc47de2dcc38e153c3753bf0eb56833cbd57a12f14b2849ec5228c0a11454",
	"res://art/ui/inventory/icons/icon_iron_knuckles.png":"3c5faa2708694794440ded6459866ebfad926e90ce6e9fad90c1732469bcb7fa",
	"res://art/ui/inventory/icons/icon_iron_staff.png":"3e34afc45b273e767fe6eb22da1338839249d3f1f9414e83aa89dc32353825bb",
	"res://art/ui/inventory/icons/icon_key.png":"7b0c67697850c5b6ddd9f0bb2d59ef7a669ed866bd4ddf60451b8b9a3dcf07c9",
	"res://art/ui/inventory/icons/icon_leather_bracers.png":"be8b7b8843e3dbb252cd9904ea40d195073dc660159f2a73a8cf45e569041c96",
	"res://art/ui/inventory/icons/icon_mana_pill.png":"c24251479a83d2c6c3144e3663c90fda785af188ecf2e8256d8faad2453f5585",
	"res://art/ui/inventory/icons/icon_ore.png":"46db0236bf393d222b61987a98cef66089ff62cb72865b0029d737f46bed5104",
	"res://art/ui/inventory/icons/icon_potion.png":"aae2c574e97239d92203c30186f0bf0b3e6b3c635ef3e49a3d0e74f9a8dea110",
	"res://art/ui/inventory/icons/icon_revive_pill.png":"d814893543a50cf26f94208227e364408a03981aeae86e0d57edfcb7924ab08e",
	"res://art/ui/inventory/icons/icon_ring.png":"64d80a5c488d651b00d475d7bb2e445313e2ec5ac5acffa4e0455fa2b05182d9",
	"res://art/ui/inventory/icons/icon_scroll.png":"eb2a6972545198afeaec884c6020a5cfde53136bee06bb33c892eba0ba5545f8",
	"res://art/ui/inventory/icons/icon_shaolin_fahua_staff.png":"3e0091ae634cfbafa0da890c04545b1b3b4118ac0235cd10a65728921b9557b3",
	"res://art/ui/inventory/icons/icon_steel_gauntlets.png":"b925e68d7d893a97e094e6e7f6ef7403b103e33f24610e41c01da5a9e00e1658",
	"res://art/ui/inventory/icons/icon_sword.png":"963d982b566b01b6f8e318d9f545f9ae9bfc11331d7fa28d3e4b6061fc362290",
	"res://art/ui/inventory/icons/icon_thunder_gauntlets.png":"b524bb8e48f33766562b37b3a4d637834b31ca5b26cfced192c45a35fc9cb70e",
	"res://art/ui/inventory/icons/icon_tiger_roar_blade.png":"614678dd3da65b71b306ea0ea31a74d5aae027a115ef633f9b7d9bfc450291fb",
	"res://art/ui/inventory/panel_bg.png":"3f215838a2b1f811090c6ab87174b0df231e55e1d9793d7575420a17cfcd62a7",
	"res://art/ui/inventory/reading/readable_panel_bg_v1.png":"80681fff6f1298ccc132dfbbaf48d452233ac03c6e2c5adbe9bed6451c3a64eb",
	"res://art/ui/inventory/tabs/tab_all_normal.png":"e3aee72ef51d5ad3190de597b2ac1c7c4a46a708dc3cd8a751d24af457ae53e0",
	"res://art/ui/inventory/tabs/tab_all_pressed.png":"d95a934f4d71d89d45894918055294c7add46f20dec6b5970545e294525e555d",
	"res://art/ui/inventory/tabs/tab_all_selected.png":"3bf1cc93314e84d951c4b1d35b6fd958a789217c17a082a51e54a6c3dbf7b6d8",
	"res://art/ui/inventory/tabs/tab_consumable_normal.png":"6ddc679874460ae8f7530353f8b92f79a46d9d66553030ac5ca30bb4242a2238",
	"res://art/ui/inventory/tabs/tab_consumable_pressed.png":"042315206bb176a9b71300a9c9e5dfb29b42940c56ec2739b75e7074302cc346",
	"res://art/ui/inventory/tabs/tab_consumable_selected.png":"f1ffde956122481028b5285819a075fb1675396cf024005e901c6af2f3dfc420",
	"res://art/ui/inventory/tabs/tab_equipment_normal.png":"cd8bff83228cfce5aeb813ec51067d0b7d69d98ab1d7e26ed2b29c1a1618ba57",
	"res://art/ui/inventory/tabs/tab_equipment_pressed.png":"6e00d3b5bc005491b9aa64279759c68fa2e4ce1b5ecafbaec1d9503cc62637f1",
	"res://art/ui/inventory/tabs/tab_equipment_selected.png":"67725ae8172ccd7ffb9cd1b1d8b5f1919d6efa1cd45d493106aeb97cd582bd5c",
	"res://art/ui/inventory/tabs/tab_key_normal.png":"87d15f43aca9de3c01afaac8f3e718ec291c0c29e3ab386fbe1ff25727a35f8d",
	"res://art/ui/inventory/tabs/tab_key_pressed.png":"47f0274469e9190e6c8cb359298fcb2dc1b96def450ac2ca1f1029a642f2ceca",
	"res://art/ui/inventory/tabs/tab_key_selected.png":"bad8ff8681f2903476d2e110a058b96da545bad69a8143c89b5fb3df5c01671f",
	"res://art/ui/inventory/tabs/tab_material_normal.png":"a686cf8cbd66468b276a3219752ccb6137206ba47125792fced1f117e4f0af74",
	"res://art/ui/inventory/tabs/tab_material_pressed.png":"ae85a6fecf22cece689c528a78b24437d498936fc38ebeaccf8925b385b1fd00",
	"res://art/ui/inventory/tabs/tab_material_selected.png":"432071c806ddf6b301d275649c60c130ba09fb8af5582a8f976c28a15658c9c2",
	"res://art/ui/shop/buttons_v2/shop_rect_hover.png":"9376a02db233ae97fa1eda7a3cf159a2c2118de8b88ab416b29ff6efbd10d0ab",
	"res://art/ui/shop/buttons_v2/shop_rect_normal.png":"ec98813c1afafaa3e265bdc4734f9597c171a49a03f89dedf5dd8f73b581dc70",
	"res://art/ui/shop/buttons_v2/shop_rect_pressed.png":"bf3890d5a2d3ddfc995311b48692f3d97a293deecd2aa60e443a23060abad2af",
	"res://art/ui/shop/shop_trade_confirm_panel_v1.png":"15d0a5de9f56ac0ccebafbefa671af0c7d8db2c9fb587a2d2c909d1cb2972fce",
	"res://art/ui/shop/tabs_v1/shop_tab_inactive.png":"098ae770d11c10825e22d9faf86a840c62b5d709ab723fc3be5e26508906e599",
	"res://art/ui/shop/tabs_v1/shop_tab_selected.png":"bca87582947fd670a1d0926546dbfb3261f2808b0196b612f6a2dd23bf198b4e",
	"res://art/ui/shop/ui_shop_panel_quest_style_v2.png":"a1d78b35720b4db1e33a1bce72fd6185b302213aad32d0682c32e6165e46b325",
	"res://data/equipment/battle_helmet.tres":"84358d54f173a434b9c8a28ce9368f70e7c9865e706a0ecc8e615612d0262a70",
	"res://data/equipment/cloth_boots.tres":"41679eb951ac4d874f179592abb60081fb561f9e42f3a6b84522c6fb4af0fd25",
	"res://data/equipment/dark_iron_armor.tres":"26d2847f428406891f2080930c935a2edbc8b7734e3021c3472b66339bfd2b1d",
	"res://data/equipment/dark_iron_boots.tres":"04d2dd685fa79047ebf7dcdd0572b14660340ea825304d3d54aa57481270a9e3",
	"res://data/equipment/diamond_gauntlets.tres":"2726ff2adee6e13508952953b6967086d71330e46e4cd96cc8be7008d5b25796",
	"res://data/equipment/dragon_horn_crown.tres":"6b56d9bf5ae6f87d7e71abcea6ea47c7c341039cc1749ff30a1946ad0b78458d",
	"res://data/equipment/dragon_scale_armor.tres":"58005e52a3d2b6cddfc28c651c536790da9b2fb2a4863b27f899dc1ed2cc7370",
	"res://data/equipment/dragon_scale_bracers.tres":"adb4b40ceda4d591ae3e6ad269ba9ebcfe16f82bbc693ac15b896381984e4d81",
	"res://data/equipment/dragon_tendon_staff.tres":"051e0b9f1f77604c729610aafe3653e712245993c8d4db9295a2f10199a03dc7",
	"res://data/equipment/heavy_iron_sword.tres":"28362757293b086969284e3365e6ef93c246876890e315ed056edf53dd0929b9",
	"res://data/equipment/iron_great_blade.tres":"27aac87d391c5406233cf459ab56bed008a26249d4f09a96b57be1c7ffb253ca",
	"res://data/equipment/iron_knuckles.tres":"4855262e811d47549fc8a93ef3d469cc8868c1c6205f8ca2d60a6f1a9b1b99df",
	"res://data/equipment/iron_staff.tres":"1b1e83047cbd8098dfbd1784b077379ee737baa9169f1e0edd66d28809bb2342",
	"res://data/equipment/shaolin_fahua_staff.tres":"05239f2f7e8ce927fffbf0391e8b06161c057fba95e1d7e22c4c5554f4982c83",
	"res://data/equipment/thunder_gauntlets.tres":"3ef8e0fd85b4948c9502670862b1e038f8f6da294cf7bc853f12a424a9febeaa",
	"res://data/equipment/tiger_roar_blade.tres":"43bd0c4c4046b26f88da7175b0594fac8cf300ccea3173d4e57b8edffc12bfe6",
	"res://data/items/antidote_pill.tres":"5b3e62d9af8c6b618dc3c3735fa8244b377caba7a069a1dc804410522eda3072",
	"res://data/items/healing_pill_minor.tres":"8744f4ba0275afa251062c2a80c451905dd135cc06dd08e427b5d4d47e0c768c",
	"res://data/items/mana_pill.tres":"2e3e46f5961c26926f0515f5cf6d3d4ee5a080860812b177bbb443167e6ce9de",
	"res://data/items/revive_pill.tres":"e6a32c6e3ea84213297db23291fa6e7044c03fe1d79188ae012dd9538ec8dd1e",
	"res://data/shops/luoyang_armory.tres":"3d88e7e116bbb737a2dcf9efb3e21505bfbf88b864c3f5155bc64e972e9af6df",
	"res://scenes/shop.tscn":"773f244352efcd0cf7e9b39b47605e90af83f5411a3c7bf63e2af3c75b624489",
	"res://scenes/ui/formal_choice_menu.tscn":"4eb73f5ab14d17f12a8dba4c1e3a2a147e5bb98e4846bafc1356d23156158266",
	"res://scenes/ui/formal_confirm_dialog.tscn":"d4337c00a7333560bee3ace369c8760bec42710ac0d33624c69d0114f8b6ef69",
	"res://scenes/ui/inventory_panel.tscn":"4c4022cf1f88029b2d806f24286257d07e1508db1e610395c9bb5397a080a8e7",
	"res://scenes/ui/reading_panel.tscn":"77f8451cccd026d55cc16e256417481695bb3067633233d967429dda4001a8ac",
	"res://scripts/autoload/inventory.gd":"727a2742aff63569f2a4d91ff5b69ac28191d5e146f600084e29e1f9dd76f276",
	"res://scripts/domain/equipment.gd":"26d703ab90b421af6ed08c22c53173947add367b61429250c77b2fe01d2fdb74",
	"res://scripts/domain/item.gd":"01857f622de1352454ba92710bf0a41d54525dff2fe114b400025f92a2fd144c",
	"res://scripts/domain/shop_def.gd":"f4e99a4a159a7501457432d950b0d88618397ec6c678914b38b7c199210b11cb",
	"res://scripts/ui/equipment_stat_presentation.gd":"80030c93dcd11058ae15b8f18c2ec60d0884949b49f0767073fbaffc6a550791",
	"res://scripts/ui/formal_choice_menu.gd":"6ce13694778cbe9babc813a82bd89fa4ffbf1142768b7ecd60d2486413254daf",
	"res://scripts/ui/formal_confirm_dialog.gd":"ec2037b90a384139e09ffcccac91ad9a5afbe2d9c078acf1bfff6b1f58c98202",
	"res://scripts/ui/inventory_panel.gd":"434f0fba79f444a753987484f627331928092e3f2550247226eeb4f7bd2170be",
	"res://scripts/ui/reading_panel.gd":"3b428b99a7b8bff20f0979188a6b4aaf8cafd6bd07edc7772a6c54b4551c5320",
	"res://scripts/ui/shop_ui.gd":"dac1ab50975c8582091df0effb0fc381f9aae9b0c583dc3fd6fdbc02f3413cc4",
	"res://scripts/ui/wuxia_theme.gd":"2bef5ea479c92f05c3933f867ad5c57ef9e428b682b779949fc947b60d92afd0",
}
var checks: int=0
var failed: int=0
var output: String=""
var paths: Dictionary={}
var first: Dictionary={}
var players: Dictionary={}
var slot: Variant
var contract: Script
var checkpoint: Dictionary={}

static func fixture_sources() -> Array[String]:
	# Outer wrapper expands the ordinary literal .gd dependency closure.
	var sources: Array[String]=[PHASE_PATH,SAVE_PATH,RAW_PATH,TARGET_RAW_PATH,CONTRACT_PATH,BRIDGE_PATH,
		"res://tests/test_luoyang_enclosure_v11_bounty_shop_equip_heal_20261012.gd",
		"res://tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd",
		"res://tests/helpers/luoyang_enclosure_v11_city_only_phase.gd",
		"res://tests/helpers/luoyang_wasapi_catalog3_continuity_20261011.gd",
		"res://data/maps/world_map_jianghu_layout_v14.tres",
		"res://scripts/autoload/scene_router.gd","res://scripts/city/luoyang_layered_v3_contract.gd",
		"res://data/scenes/world_map_jianghu.tres","res://data/config/outskirts_native_adoption.json",
		"res://data/scenes/ch4_s0_luoyang_gate.tres","res://data/scenes/ch4_s1_luoyang_yamen.tres",
		"res://data/scenes/ch4_s2_canal_docks.tres","res://data/scenes/ch4_s3_luoyang_market.tres"]
	sources.append_array(BOUNTY_SOURCES)
	for path: String in SHOP_PINNED: sources.append(path)
	sources.append("res://tests/helpers/battle_shop_equip_heal_ui_probe_20261012.gd")
	for id: String in MUSIC_TRACK_IDS: sources.append("res://art/audio/bgm/wuxia_20261011/"+id+".wav")
	return sources

static func mode(args: Array) -> Dictionary:
	for value: Variant in args:
		if typeof(value)!=TYPE_STRING: return {}
		if value.begins_with("--city-qa-phase="): return {}
	for required: String in ["--luoyang-bounty-only-observation","--fresh-start-only","--luoyang-enclosure-v11-candidate","--luoyang-v3-candidate"]:
		if args.count(required)!=1: return {}
	for forbidden: String in ["--luoyang-city-only-fresh","--candidate-before-cutover","--outskirts-candidate-preview","--outskirts-complete-v5","--qa-phase=release"]:
		if forbidden in args: return {}
	return {"phase":"bounty_only_diagnostic","candidate":true}

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failed+=1; push_error("[CITY ONLY FRESH FAIL] "+label)
	return ok

func _file(path: String) -> Dictionary:
	var present: bool=FileAccess.file_exists(path)
	var file: FileAccess=FileAccess.open(path,FileAccess.READ) if present else null
	return {"exists":present,"bytes":file.get_length() if file!=null else 0,"sha256":FileAccess.get_sha256(path) if present else "ABSENT","mtime_seconds":FileAccess.get_modified_time(path) if present else 0}

func _normal_files() -> Dictionary:
	var result: Dictionary={}
	for index in 5:
		for suffix: String in ["",".bak",".tmp"]:
			var path: String="user://save_%d.json%s"%[index,suffix]
			result[path]=_file(path)
	return result

func _track(path: String) -> void:
	if paths.has(path): return
	paths[path]=true
	if not _check(FileAccess.file_exists(path),"required consumed source exists "+path): return
	if path.get_extension().to_lower() in ["png","jpg","jpeg","webp","wav","ogg","mp3"]:
		var import_path: String=path+".import"
		_track(import_path)
		var config:=ConfigFile.new()
		if _check(config.load(import_path)==OK,"actual import metadata "+path):
			if config.has_section_key("deps","dest_files"):
				var destinations: Variant=config.get_value("deps","dest_files")
				if _check(destinations is Array or destinations is PackedStringArray,"actual import destination list "+path):
					for destination: Variant in destinations:
						if _check(typeof(destination)==TYPE_STRING and not destination.is_empty(),"typed imported destination "+path): _track(destination)
			else:
				_check(config.get_value("remap","importer","") in ["keep","skip"],"no compiled output only explicit keep/skip "+path)
	if path.get_extension()!="gd": return
	var pattern:=RegEx.new()
	pattern.compile('res://[^"\\\r\n]+[.]gd')
	var body: String=FileAccess.get_file_as_string(path)
	for source_match: RegExMatch in pattern.search_all(body):
		# A quoted .gd leaf, never a .gdshader substring or a directory.
		if source_match.get_end()<body.length() and body.substr(source_match.get_end(),1) in ['"',"'"]:
			_track(source_match.get_string())

func _snapshot() -> Dictionary:
	var result: Dictionary={}
	# Each unique path is freshly read once per endpoint, never a reused digest.
	for path: String in paths: result[path]=_file(path)
	return result

func _write(name: String,value: Dictionary) -> bool:
	var path: String=output+name
	if FileAccess.file_exists(path): return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	var encoded: String=JSON.stringify(value,"\t",true)
	file.store_string(encoded); file.flush()
	var ok: bool=file.get_error()==OK
	file.close()
	var parser:=JSON.new()
	return ok and parser.parse(FileAccess.get_file_as_string(path))==OK and parser.data==JSON.parse_string(encoded)

func _run() -> void:
	# First public suspension, before any await or fixture.
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): quit(1); return
	var default: Variant=bridge.call("is_checkpoint_saves_suspended")
	bridge.call("set_checkpoint_saves_suspended",true)
	checkpoint={"default_suspended":default,"before_any_await":bridge.call("is_checkpoint_saves_suspended"),"automatic_checkpoint_saves_tested":false,"restored_before_exit":false}
	_check(typeof(default)==TYPE_BOOL and default==false and checkpoint.before_any_await==true and FileAccess.get_sha256(BRIDGE_PATH).to_lower()==BRIDGE_SHA,"exact public defaultfalse/suspendtrue checkpoint source")
	players=_normal_files(); slot=root.get_node("SaveManager").get("active_slot")
	var selected: Dictionary=mode(Array(OS.get_cmdline_user_args()))
	_check(not selected.is_empty(),"explicit unmixed original two-bounty observation mode, not original six")
	output="res://build/joint_world_luoyang_20261003_qa/luoyang_bounty_shop_equip_heal_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique actual evidence output")
	var scripts: Dictionary={}
	for path: String in [get_script().resource_path,PHASE_PATH,SAVE_PATH,RAW_PATH,TARGET_RAW_PATH,CONTRACT_PATH,BRIDGE_PATH,"res://scripts/autoload/scene_router.gd","res://scripts/city/luoyang_layered_v3_contract.gd"]:
		_track(path)
		var script: Script=load(path) as Script
		_check(script!=null and script.can_instantiate(),"actual script load/can_instantiate "+path)
		scripts[path]=script
	for path: String in PINNED:
		_track(path)
		_check(PINNED[path].length()==64 and FileAccess.get_sha256(path).to_lower()==PINNED[path],"exact current/source pin "+path)
	for path: String in SHOP_PINNED:
		_track(path)
		_check(SHOP_PINNED[path].length()==64 and FileAccess.get_sha256(path).to_lower()==SHOP_PINNED[path],"exact dynamic Shop/Inventory stock/UI source "+path)
	for path: String in BOUNTY_SOURCES: _track(path)
	for id: String in MUSIC_TRACK_IDS: _track("res://art/audio/bgm/wuxia_20261011/"+id+".wav")
	for path: String in PROTECTED: _track(path)
	for id: String in IDS: _track("res://data/scenes/"+id+".tres")
	for id: String in IDS:
		_track("res://data/maps/luoyang_v3_legacy/"+id+"_scene.tres")
		_track("res://data/maps/luoyang_v3_legacy/"+id+"_layout.tres")
	_check(AudioServer.get_driver_name()=="WASAPI" and FileAccess.get_sha256(OS.get_executable_path()).to_lower()==ENGINE_SHA and Engine.time_scale==1.0,"actual WASAPI/executable/ordinary time")
	contract=scripts.get(CONTRACT_PATH) as Script
	var records: Dictionary={}
	if failed==0:
		var reader: RefCounted=(scripts[RAW_PATH] as Script).new()
		for id: String in IDS:
			for path: String in [contract.call("base_manifest_path",StringName(id)),contract.call("manifest_path",StringName(id))]:
				_track(path)
			var record: Dictionary=reader.call("independent_record",StringName(id))
			_check(not record.is_empty(),"current independently SHA-bound BASE + new patch "+id)
			if record.is_empty(): continue
			records[id]=record.duplicate(true)
			if record.has("ground_capture_path"): _track(String(record.ground_capture_path))
			for path: String in record.asset_sha256: _track(path)
			if record.has("enclosure_patch_path"):
				var patch: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(record.enclosure_patch_path))
				_track(String(patch.export_plan_path))
			for path: String in [contract.call("candidate_path",StringName(id)),contract.call("layout_path",StringName(id))]:
				if FileAccess.file_exists(path): _track(path)
		reader.call("release"); reader=null
	first=_snapshot()
	_check(_write("source_before.json",first),"initial unique source snapshot")
	var report: Dictionary={}
	if failed==0:
		var phase: RefCounted=(scripts[PHASE_PATH] as Script).new()
		report=await phase.call("run_bounty_diagnostic",self,output)
		_check(report.get("complete")==true,"both original bounties, unchanged UI/input/Physics/reward gates")
		phase=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	for tick in 8: await process_frame
	var cleanup_start: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-cleanup_start<9000000: await process_frame
	root.get_node("AudioManager").call("stop_bgm",.15)
	var drain: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-drain<250000: await process_frame
	for shape: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for tick in 4: await process_frame
	var last: Dictionary=_snapshot()
	_check(first==last,"all consumed unique source/asset bytes and modification seconds unchanged")
	_check(players==_normal_files() and slot==root.get_node("SaveManager").get("active_slot"),"all15 normal player existence/bytes/SHA/mtime_seconds and slot unchanged")
	_check(bridge.call("is_checkpoint_saves_suspended")==true and AudioServer.get_driver_name()=="WASAPI" and FileAccess.get_sha256(OS.get_executable_path()).to_lower()==ENGINE_SHA and Engine.time_scale==1.0,"checkpoint remains suspended; actual audio/engine/time intact")
	var result: Dictionary={"battle_strategy_modified":true,"Attack_only":false,"strategy_scope":"NORMAL_SHOP_EQUIP_HEAL","passive_health_strategy_modified_false_scope":"D699_OBSERVER_ONLY","schema":1,"scope":"LUOYANG_TWO_BOUNTY_NORMAL_SHOP_EQUIP_HEAL_NOT_SIX","six_slot_eligible":false,"full_gameplay_tested":false,"full_geometry_tested":false,"mode":selected,"complete":failed==0 and report.get("complete")==true,"checks":checks+1,"failures":failed,"stage":report,"diagnostic_collection_complete":report.get("diagnostic_collection_complete",false),"source_before":first,"source_after":last,"players_before":players,"players_after":_normal_files(),"active_slot_before":slot,"active_slot_after":root.get_node("SaveManager").get("active_slot"),"checkpoint_suspension":checkpoint,"actual_audio_driver":AudioServer.get_driver_name(),"engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"historical_compatibility_tested":false,"world_subject_version":14,"world_full_tested":false,"formal_approved":false,"exact_UTCticks":"ROOT_EXTERNAL_FRESH_BEFORE_AFTER_REQUIRED","stderr_acceptance":"ROOT_MUST_READ_COMPLETE_LOG_AND_ACTUAL_OS_EXIT","output":output}
	_check(_write("result.json",result),"limited original bounty-observation final result checked readback")
	print("BOUNTY_ONLY_OBSERVATION_RESULT "+output+"result.json checks="+str(checks)+" failures="+str(failed))
	quit(0 if failed==0 else 1)



