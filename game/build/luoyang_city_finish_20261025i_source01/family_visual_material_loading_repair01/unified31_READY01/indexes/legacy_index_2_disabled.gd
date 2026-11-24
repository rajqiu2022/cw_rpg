extends RefCounted
const FORMAL_ENABLED=false
const ENTRIES={
"ch4_s0_luoyang_gate": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json",
"manifest_sha256": "eb68223bca907423fb6fcf0cb970e605deb0ae249276df902b5ab9c86324e4ea"
},
"ch4_s1_luoyang_yamen": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/manifest.json",
"manifest_sha256": "2005f25c19068c18d033199078bbdf78bd6eeab693e5f5ab73b6d97f8312be97"
},
"ch4_s2_canal_docks": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s2_canal_docks/manifest.json",
"manifest_sha256": "e804816a1b0814d4082f54fa14e64fd82fa9bbfc554a9e658d3790c47029793c"
},
"ch4_s3_luoyang_market": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s3_luoyang_market/manifest.json",
"manifest_sha256": "747ae2e5318c0b6d259a9a86fcdd914abd11493dc70a47562b7e47a7352ef620"
}
}
static func entries() -> Dictionary: return ENTRIES.duplicate(true)
static func formal_enabled() -> bool: return FORMAL_ENABLED
