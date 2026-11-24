extends RefCounted
const FORMAL_ENABLED=false
const ENTRIES={
"ch4_s0_luoyang_gate": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json",
"manifest_sha256": "12d6a385fafeea7b0eb97ac1f7ad3aa2d6036f10554d0ffae95a975aa28e66d5"
},
"ch4_s1_luoyang_yamen": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/manifest.json",
"manifest_sha256": "26d35d35f825589cf66b47647a9f9181e1ef47e981dfd2f098e88911bd77451e"
},
"ch4_s2_canal_docks": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s2_canal_docks/manifest.json",
"manifest_sha256": "04fd8c561690bf8d6f242c1eac4fd68960f86cb7f14e532c1677e98766f7e59f"
},
"ch4_s3_luoyang_market": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s3_luoyang_market/manifest.json",
"manifest_sha256": "df187e01bb30240fcb16a11516250c8753922c1a0b7a9c5f60364f899bef6b14"
}
}
static func entries() -> Dictionary: return ENTRIES.duplicate(true)
static func formal_enabled() -> bool: return FORMAL_ENABLED
