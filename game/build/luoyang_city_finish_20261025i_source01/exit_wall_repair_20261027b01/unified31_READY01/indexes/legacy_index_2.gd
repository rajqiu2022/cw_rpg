extends RefCounted
const FORMAL_ENABLED=true
const ENTRIES={
"ch4_s0_luoyang_gate": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json",
"manifest_sha256": "e7bf1f92db12d50c8d7276f9e95e4c80882e4de0b2987e76e5c6f49eadde15da"
},
"ch4_s1_luoyang_yamen": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/manifest.json",
"manifest_sha256": "6304b927dd667c9d1875cded692a7b9bbba45334f858bdf2d77bbb82dc910231"
},
"ch4_s2_canal_docks": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s2_canal_docks/manifest.json",
"manifest_sha256": "165e1c5b566e3dd6fca2e1eb6c071729d361082fdd907f42a671eb25ccceef7c"
},
"ch4_s3_luoyang_market": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s3_luoyang_market/manifest.json",
"manifest_sha256": "8a98b5308df801bc16ed63461400f0e9f4be5808615204dfc88f3897a5d680fe"
}
}
static func entries() -> Dictionary: return ENTRIES.duplicate(true)
static func formal_enabled() -> bool: return FORMAL_ENABLED
