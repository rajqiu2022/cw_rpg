extends RefCounted
const FORMAL_ENABLED=true
const ENTRIES={
"ch4_s0_luoyang_gate": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json",
"manifest_sha256": "a0332d6662df76689ddaffb0060bf7bdf0861a701a92d360a475de6caa2e8074"
},
"ch4_s1_luoyang_yamen": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/manifest.json",
"manifest_sha256": "29c6d42a1d2a55ad6904c9310291c6047d4019f91b379ce5047517673b62286c"
},
"ch4_s2_canal_docks": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s2_canal_docks/manifest.json",
"manifest_sha256": "8dfa0ec412afcebd73fd30edce3703a2a3b7a01e9743a219b4d7476562ee2ef7"
},
"ch4_s3_luoyang_market": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s3_luoyang_market/manifest.json",
"manifest_sha256": "edf9149a58e1b02b9e55f4aa4bfb911d3e70176d5851c0addecad65c9328303a"
}
}
static func entries() -> Dictionary: return ENTRIES.duplicate(true)
static func formal_enabled() -> bool: return FORMAL_ENABLED
