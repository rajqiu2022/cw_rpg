extends RefCounted
const FORMAL_ENABLED=true
const ENTRIES={
"ch4_s0_luoyang_gate": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json",
"manifest_sha256": "9fa292109aa99e187b0f61481a1ed6020a49dbd33b706f8526c48dd0eb23c32d"
},
"ch4_s1_luoyang_yamen": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/manifest.json",
"manifest_sha256": "89747ea62fee76a66444eca026cf6e46fa701c131782866787e4a669367e4338"
},
"ch4_s2_canal_docks": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s2_canal_docks/manifest.json",
"manifest_sha256": "320046e483269a3e64a267e399a92217d33398a0486d292f245aaac14f8cf6cd"
},
"ch4_s3_luoyang_market": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s3_luoyang_market/manifest.json",
"manifest_sha256": "1266bc8dad40349e17c0344b962152a247af47f551e7dc732a38d09765dffaf1"
}
}
static func entries() -> Dictionary: return ENTRIES.duplicate(true)
static func formal_enabled() -> bool: return FORMAL_ENABLED
