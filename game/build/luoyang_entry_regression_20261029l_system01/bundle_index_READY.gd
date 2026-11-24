extends RefCounted
const FORMAL_ENABLED=true
const ENTRIES={
"ch4_s0_luoyang_gate": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json",
"manifest_sha256": "ca7bb8fac67147b7c0dd4f709353050931e348daa3d3b094db97a5a8f726cbc0"
},
"ch4_s1_luoyang_yamen": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/manifest.json",
"manifest_sha256": "1fbe82427efaf2ef3edf98a31b6d0c1d0170b07b0580e33d8d82d3622405a6bf"
},
"ch4_s2_canal_docks": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s2_canal_docks/manifest.json",
"manifest_sha256": "df379fe314140dc0969cc3ed850200cd29c042cc19be5f345a0c3f42252337bf"
},
"ch4_s3_luoyang_market": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s3_luoyang_market/manifest.json",
"manifest_sha256": "371687b6a888694b30c168507c4f4d44ee29792ac74de9e441d5d2740d8024ad"
}
}
static func entries() -> Dictionary: return ENTRIES.duplicate(true)
static func formal_enabled() -> bool: return FORMAL_ENABLED
