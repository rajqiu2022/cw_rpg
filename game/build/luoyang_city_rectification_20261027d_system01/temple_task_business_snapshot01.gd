extends RefCounted
## Successor Temple task adapter candidate.  It keeps the old canonical scene as
## the paper-task oracle, but requires the actual successor child to contain the
## two monk entities, four non-speaker base interactions and separated portals.
const TEMPLE=preload("res://build/luoyang_city_rectification_20261027d_system01/temple_source_business_snapshot01.gd")
const TASK=preload("res://scripts/city/luoyang_layout_quest_20261018t.gd")

static func project(scene: SceneScript,flags: Dictionary,states: Dictionary,input: Array,render_objects: Array) -> Dictionary:
	if not TEMPLE.is_scene(scene): return {"ok":false,"error":"TEMPLE_TASK_CHILD_UNBOUND"}
	var original:=TEMPLE.original_scene()
	if original==null: return {"ok":false,"error":"TEMPLE_TASK_REAL_CANONICAL_MISSING"}
	var original_interactions:=TEMPLE.legacy_interactions(original)
	var authored: Dictionary=TEMPLE.author(TEMPLE.binding())
	var source_base: Array=TEMPLE.successor_interactions(original_interactions,authored)
	var source_portals: Array=TEMPLE.successor_portals(original)
	if original_interactions.size()!=6 or source_base.size()!=4 or source_portals.size()!=2: return {"ok":false,"error":"TEMPLE_TASK_SUCCESSOR_SOURCE_COUNT_CHANGED"}
	if not _equal_value(input,source_base) or not _equal_value(scene.map_layout.portals,source_portals): return {"ok":false,"error":"TEMPLE_TASK_INTERACTION_OR_PORTAL_SOURCE_CHANGED"}
	if not _equal_value(scene.npcs,TEMPLE.successor_npcs()): return {"ok":false,"error":"TEMPLE_TASK_MONK_SOURCE_CHANGED"}
	var task: Variant=load("res://build/luoyang_city_rectification_20261027d_system01/temple_paper_task_business_snapshot01.gd")
	if not task.task_successor_ready(): return {"ok":false,"error":"TEMPLE_TASK_SUCCESSOR_DEFINITION_OR_DIALOG_SOURCE_CHANGED"}
	var old_projected: Dictionary=task.project(original,flags,states,original_interactions)
	if old_projected.get("ok")!=true or not old_projected.get("matched",false) or not old_projected.npcs.is_empty() or not old_projected.visual_objects.is_empty(): return {"ok":false,"error":"TEMPLE_TASK_ORIGINAL_ORACLE_REFUSED"}
	# The old task layer may still change/remove only the paper hotspot.  The two
	# legacy hidden-speaker rows are verified against the oracle, then explicitly
	# excluded from the successor child rather than silently retained.
	for item: Dictionary in original_interactions:
		if item.id=="legacy_hotspot_3": continue
		var found: int=0
		for row: Dictionary in old_projected.interactions:
			if row.get("id")==item.id:
				if not _equal_value(row,item): return {"ok":false,"error":"TEMPLE_NON_PAPER_TASK_DELTA"}
				found+=1
		if found!=1: return {"ok":false,"error":"TEMPLE_NON_PAPER_TASK_MISSING"}
	var projected_base: Array=TEMPLE.successor_interactions(old_projected.interactions,authored)
	if projected_base.size()!=old_projected.interactions.size()-2: return {"ok":false,"error":"TEMPLE_TASK_RELOCATION_OR_SPEAKER_REMOVAL_REFUSED"}
	var base: Dictionary={"ok":true,"matched":true,"npcs":scene.npcs.duplicate(true),"visual_objects":render_objects.duplicate(true),"interactions":projected_base,"receipt":{"old_task_receipt":old_projected.receipt.duplicate(true)}}
	var projected: Dictionary=TASK.project_temple(base,source_portals,flags,states)
	if projected.get("ok")!=true or projected.get("matched")!=true: return {"ok":false,"error":"TEMPLE_LAYOUT_QUEST_SUCCESSOR_REFUSED:"+String(projected.get("error","UNKNOWN"))}
	if not _equal_value(projected.portals,source_portals): return {"ok":false,"error":"TEMPLE_PROJECTED_PORTALS_CHANGED"}
	projected.receipt["source_scene_id"]=String(scene.scene_id)
	projected.receipt["new_child_path"]=scene.resource_path
	projected.receipt["canonical_oracle_path"]=original.resource_path
	projected.receipt["canonical_oracle_sha256"]=TEMPLE.ORIGINAL_SHA
	projected.receipt["old_task_receipt"]=old_projected.receipt.duplicate(true)
	projected.receipt["only_paper_phase_delta_in_old_task_layer"]=true
	projected.receipt["two_legacy_speaker_hotspots_absent_from_actual_layout"]=true
	projected.receipt["successor_portals_are_actual_scene_data"]=true
	projected.receipt["new_geometry_unmodified"]=true
	return projected

static func _equal_value(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b): return false
	if a is Resource: return b is Resource and a.resource_path == b.resource_path and a.get_script() == b.get_script()
	if a is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not _equal_value(a[i], b[i]): return false
		return true
	if a is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _equal_value(a[key], b[key]): return false
		return true
	return a == b

## Ordinary business/resource declarations derive solely from fixed original
## tables; the old196 owner/control sources are not a new Region authority.
const BUSINESS_SOURCES: Dictionary={
  "res://build/luoyang_city_finish_20261025i_source01/garden_estate_exit_repair_20261027c01/closure_READY01/Temple_binding_READY.json": "ca6d8cf4e42517ae92eb8ff0647fa93ba50d2c9ffcfb260469258b65f4279703",
  "res://data/maps/luoyang_temple_assembly_20261016/binding_editor_save_recovery_v14.json": "2a46baf36fc2667d0c62b789914738b72e30b085906dd066bcf55d594a0cd406",
  "res://data/maps/luoyang_temple_assembly_20261016/author.json": "d03aa28b5eec9ad91296b8d3cc1d6aeb6782bde8be69b268d81f05550b63410a",
  "res://data/scenes/luoyang_temple_layout_quest_20261018t/temple.tres": "81fbe0934e11fc6cbab21855e97b7bd956eee52f8b532e445693349786ffd4d9",
  "res://data/maps/luoyang_temple_layout_quest_20261018t/layout.tres": "2138694bfede79cde8223c0101003bb7885225ae9ea24a66f584a8f9072f1448",
  "res://data/scenes/ch4_s4_ancient_temple.tres": "1570a4d9cfcb0508a12bfa639052db8aec11ab25634a3f5c606d19cbe2223730",
  "res://data/maps/ch4_s4_ancient_temple_layout_v1.tres": "c639287b0afff4c5e2e8ad667438a5b023102a1215549610189540c8e96a26f0",
  "res://data/luoyang_city_tasks_20261016/overlay.json": "9e654f67be48a8da93232e0f2b66e109cdd769577fb53545f72f81885e90a3bb",
  "res://data/scenes/ch4_s3_luoyang_market.tres": "2df5059ab647d956e7b37c8bb5f7d0d568d575deac7931b3ccadb5451c6fe8f6",
  "res://data/scenes/ch4_s2_canal_docks.tres": "51527c472d4c4ce33e00f1a07754411cc433f770c5882614187f165a7834b34d",
  "res://data/dialogs/ch4_canal_grudge_offer.tres": "431d43b11cf55a8f53aad96f71a077def8c1ef78477cdfb094da2cf34207dc80",
  "res://data/dialogs/ch4_canal_grudge_turnin.tres": "620c8939e0fcf1dc5ae64034bf77d900f2fc12569a14c288d119a88640df4da7",
  "res://data/dialogs/ch4_luoyang_paper_offer.tres": "2898f3f9389fb463a058c2b60baa72cf95ab5ec47706939e5b3aaa583a7290f0",
  "res://data/dialogs/ch4_luoyang_paper_turnin.tres": "ecfbef4ec933433974de40c3fcb15826dbfdce4b7a76e62728f03539be330cd3",
  "res://data/dialogs/ch4_hanjia_blade_offer.tres": "30eba1843f543e152e9269203a66b4507087d4045d745a30f0c186a88c51b5fa",
  "res://data/quests/q_ch4_side_06_canal_grudge.tres": "f886b6cf5f16592662bbf36c468c54fe0f7f5167be8555d662e6f805622a652e",
  "res://data/quests/q_ch4_side_02_luoyang_paper.tres": "4d44b5cd1892e9a18e002011421efdd70fb799bf06cffa7aa6b60d233df74c21",
  "res://data/quests/q_ch4_side_07_hanjia_blade.tres": "4fc77c40ca955bdd68c1bfc1ce10302f440273880304ca1b340dd60a27615935",
  "res://art/characters/npc_zhuwei_merchant_idle_down_25d_4f_v3_runtime.png": "2082d5dbe2c73b4d397c091d068901aa0e50a991149856f716b7bc428ef0c3ad",
  "res://art/characters/portraits/generic/portrait_generic_older_man_v1.png": "f74ac5192e1a7c82d9953be77bfcfe1837aa2edc4a5b1087400f2acfdd605785",
  "res://data/dialogs/luoyang_city_tasks_20261016/canal_offer.tres": "6eb0999362c46fe96417c90063992cf556e9684fe8faa44a2ccc600a6eff2dd9",
  "res://data/dialogs/luoyang_city_tasks_20261016/canal_progress.tres": "cb20e62b8e017dae94a89ae98a7da9f0a015937751427d2380f964e981faafbc",
  "res://data/dialogs/luoyang_city_tasks_20261016/canal_witness.tres": "b912dd2874df21ffe77a519d4c1a68bd62e5135a149b2df045cf7ade709894ea",
  "res://data/dialogs/luoyang_city_tasks_20261016/canal_warehouse_clue.tres": "f03f8543025224b071eb89ae5c45a471ab490fb39f61c7f6c5990fbf67b0b945",
  "res://data/dialogs/luoyang_city_tasks_20261016/canal_evidence.tres": "bd8b944b95e5a45a19b36190fd47ea08465ee89ce16887965bb8999973873389",
  "res://data/dialogs/luoyang_city_tasks_20261016/canal_report.tres": "dadce640ea5ad2030c663922154dd8cc9b39c412b5ef9ac326c1ff1846ff5e6d",
  "res://data/dialogs/luoyang_city_tasks_20261016/canal_after.tres": "b32e16aacdd75b419132d7bdafb8bd1e1f47fa27deebedc89ac60b18c15ef683",
  "res://data/dialogs/luoyang_city_tasks_20261016/paper_offer.tres": "ffcb3fa9791598f2b0640c8a24dab9f05896e517f58874bc38bd6cf1d782d31a",
  "res://data/dialogs/luoyang_city_tasks_20261016/paper_progress.tres": "5dba5671ca38e54ffe2719fb7d0369d717a578ac33c81de202c1572e18322d0c",
  "res://data/dialogs/luoyang_city_tasks_20261016/paper_hint.tres": "140bb3688cc765f0c06efac8e802e299fe9796b5d6e6b89662ebb35f81a0f041",
  "res://data/dialogs/luoyang_city_tasks_20261016/paper_hint_repeat.tres": "43c34b6eb2e2594aa5c29274ce2c88e32810d310685fdc1466b60fd92b60190e",
  "res://data/dialogs/luoyang_city_tasks_20261016/paper_materials.tres": "df2b0e06e30f4a64d34515ae2d301d604a18608c55a3d03994747b63f25e3a9d",
  "res://data/dialogs/luoyang_city_tasks_20261016/paper_ready.tres": "84e5d1ade74c9e8f14d54710a053b82cf65c40933910be0014f38b34f1ea5b69",
  "res://data/dialogs/luoyang_city_tasks_20261016/paper_report.tres": "3ff08b10721f9300b010b07bd91d7d13f0f29bcccf28f7005a473890ffa9477f",
  "res://data/dialogs/luoyang_city_tasks_20261016/paper_after.tres": "2782afd8f34f4055c1593f238af5a924584f3000ef9628067d8f7a0758c975bc",
  "res://data/dialogs/luoyang_city_tasks_20261016/artisan_daily.tres": "5b5c82642a69fcb4ca618c6b33f2ff78b8ea255c472383698695ba9c4ab60689",
  "res://data/dialogs/luoyang_city_tasks_20261016/artisan_after.tres": "6a51db1e8231ec9a17555bd7ac72b9d303d0bc466d06a52ae78ac7f57db93b4c",
  "res://data/dialogs/luoyang_city_tasks_20261016/hanjia_progress.tres": "a1a76cf9cc0c5daa0ebb9929e948adf8cc61b0383e6d344f9f08a8bb695562e6",
  "res://data/dialogs/luoyang_city_tasks_20261016/hanjia_after.tres": "1cfe9907ff0108a93f25b049d5176dd90d2a01909bbf5b2bdc86f5a2011a3743",
  "res://data/dialogs/luoyang_city_tasks_20261016/hanjia_offer.tres": "cfaa62ac38673f5ac97213a6f0a8d05ac0a940411887fea96829906d660796ae",
  "res://build/luoyang_layout_quest_20261018t_task_integration_source01/task_runtime_binding.json": "28c74795ce107f9e6a5f845394dad7e7ffe0969a45502d8c46aa128ce8a4406e",
  "res://scripts/city/luoyang_layout_quest_20261018t.gd": "95c7d38fd1c6baddcded5a90d33fea8d696c7aad6ee67df33c6ebf074bc70bfb",
  "res://data/dialogs/luoyang_layout_quest_20261018t/baima_after.tres": "70cfc910f3996d54fd79db4b8560f663c01907c8fe255e24cefad61146d4321e",
  "res://data/dialogs/luoyang_layout_quest_20261018t/baima_investigate.tres": "006401ce5ebb862c70b819056c2a61e0d7811c41dba9c70b80384e7dd819e503",
  "res://data/dialogs/luoyang_layout_quest_20261018t/baima_offer.tres": "a55193e19234fcf70b40d15ca7371cacb9996d12e07805eb59dc605b6f5d92d3",
  "res://data/dialogs/luoyang_layout_quest_20261018t/baima_progress.tres": "eaafd4e574137273c43f5a8fa47aaf788d0810a04c754aa9004f57ca9feb14f0",
  "res://data/dialogs/luoyang_layout_quest_20261018t/baima_report.tres": "203f38aed4f0e75dd75d5c6857d467f67f20a83f7baf4c5dcfcec1f4583ded8b",
  "res://data/dialogs/luoyang_layout_quest_20261018t/longmen_after.tres": "493a7993e7bb0da0a0d46a12e0edcff38cbf9bf2178915e4f8f62e568a2d5561",
  "res://data/dialogs/luoyang_layout_quest_20261018t/longmen_investigate.tres": "3b986600525199f89ce767983d86ddd79e221838a42050585c5ed79405d2525a",
  "res://data/dialogs/luoyang_layout_quest_20261018t/longmen_offer.tres": "8e9e82844b5dfb0452e2b0f30e1fbe38f1d1c55194ce6ca8804124950de2beae",
  "res://data/dialogs/luoyang_layout_quest_20261018t/longmen_progress.tres": "17d26799df87a01bca9af271761f07e644c3ff3a9efdfbfe6b0314df20ff11ad",
  "res://data/dialogs/luoyang_layout_quest_20261018t/longmen_report.tres": "5193570c35ba3f71c4465edf45c94cb25208da5f507826f5012646638882e7a6",
  "res://data/dialogs/luoyang_layout_quest_20261018t/peony_after.tres": "039ef163d4f3f3a3a5b21f0cd2cad48dc7bcbb6750b8c25f05b41b99cdcc3040",
  "res://data/dialogs/luoyang_layout_quest_20261018t/peony_investigate.tres": "05b06ea0204a4981062a9633ba4d9c00ff4015fb6c6fb99fa1bf05ff9868cf31",
  "res://data/dialogs/luoyang_layout_quest_20261018t/peony_offer.tres": "d9f773452b7ae1c7c3e41c7586e2697130b8ac693f30780c0485085effcee4a9",
  "res://data/dialogs/luoyang_layout_quest_20261018t/peony_progress.tres": "52175dd6b4d380d64f0566a701e3dda8f332b46f541b91e3aa8620f73e532b18",
  "res://data/dialogs/luoyang_layout_quest_20261018t/peony_report.tres": "b13412509939d1dcbf8f507898903de8bcf29da0e505d23da33d4f1fd969eafa",
  "res://data/quests/q_ch4_side_03_peony_poetry.tres": "b8048767c8ee62ef61156e5e98e71cfab94b00239f8d3f5e7bc8686d046f594c",
  "res://data/quests/q_ch4_side_04_longmen_mystery.tres": "9fabaa5bd92cf7a5c14dc05489c100f7222f3cf8eb7263e054cab97ec82dd38e",
  "res://data/quests/q_ch4_side_05_baima_bell.tres": "0a60f548af721cb645d91b7e1e01f5bf3e7d9e7535c17e044d3a4de73b414410",
  "res://art/characters/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png": "6268061eab18d2bf8c1ea0c13873f0d718feb82a119f00a67edf7c52bcb077ad",
  "res://art/characters/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png.import": "55fdbb3fd6e7aa8e179635e028a5de7930d32c2213d03f0ddc943dd1aedd6732",
  "res://.godot/imported/npc_temple_gate_monk_idle_down_1f_v1.png-5a32dda14a63529913ae5db13222be4d.ctex": "caada462bfc70d556977b07873d86cd0ed9a959e8ac4fd6ab269632dfa5d25dc"
}
static func source_declarations() -> Dictionary:
	return BUSINESS_SOURCES.duplicate(true)
static func dependency_paths() -> Array[String]:
	var paths: Array[String]=[
		"res://build/luoyang_city_rectification_20261027d_system01/temple_task_business_snapshot01.gd",
		"res://build/luoyang_city_rectification_20261027d_system01/temple_source_business_snapshot01.gd",
		"res://build/luoyang_city_rectification_20261027d_system01/temple_paper_task_business_snapshot01.gd"]
	for path: String in BUSINESS_SOURCES: paths.append(path)
	return paths
