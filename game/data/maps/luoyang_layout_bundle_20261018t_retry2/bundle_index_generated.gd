extends RefCounted
const FORMAL_ENABLED=false
const ENTRIES={
"ch4_s0_luoyang_gate": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json",
"manifest_sha256": "ea73efa58792bb2a7830f9a8af697b0d17742738fa3d55ded411a45629952692"
},
"ch4_s1_luoyang_yamen": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/manifest.json",
"manifest_sha256": "adadf68c62e50fa9e67116d3c887fb841520b738de72eed72255d6bdd971191b"
},
"ch4_s2_canal_docks": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s2_canal_docks/manifest.json",
"manifest_sha256": "f2e39682d47e39709f59d4866d0fc51b135b4dd33b276b92382f17072167c82d"
},
"ch4_s3_luoyang_market": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s3_luoyang_market/manifest.json",
"manifest_sha256": "8b3db011d70b23e5e902952f085c576cf5e7fc87fc2d174d85a4d9dc126d68fd"
}
}
static func entries() -> Dictionary: return ENTRIES.duplicate(true)
static func formal_enabled() -> bool: return FORMAL_ENABLED
