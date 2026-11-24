extends RefCounted
const FORMAL_ENABLED=true
const ENTRIES={
"ch4_s0_luoyang_gate": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json",
"manifest_sha256": "4142c6c93d16220320d31e4394d55094716049d87fdd744ee2ef6bdb1bbfaefb"
},
"ch4_s1_luoyang_yamen": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/manifest.json",
"manifest_sha256": "040c7ea498eb7d12e78d96441e125668274e7db06d6092b41d1c6f615d7c7f0e"
},
"ch4_s2_canal_docks": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s2_canal_docks/manifest.json",
"manifest_sha256": "cb4796d06c353d1a0c4619bc4051905ebd12b30de8ed5f4f140fce7998b82705"
},
"ch4_s3_luoyang_market": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s3_luoyang_market/manifest.json",
"manifest_sha256": "2fc1ec1f4a693b49932a4614c376f9791c632e3d69864ab262e1408359f97463"
}
}
static func entries() -> Dictionary: return ENTRIES.duplicate(true)
static func formal_enabled() -> bool: return FORMAL_ENABLED
