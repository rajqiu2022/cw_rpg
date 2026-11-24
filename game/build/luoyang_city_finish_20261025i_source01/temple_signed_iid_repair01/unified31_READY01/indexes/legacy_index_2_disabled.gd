extends RefCounted
const FORMAL_ENABLED=false
const ENTRIES={
"ch4_s0_luoyang_gate": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json",
"manifest_sha256": "2eb3e5ac6322f4f23b09937846031c8eb8fe66b8f48cc78b6185ef0c7823aab8"
},
"ch4_s1_luoyang_yamen": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/manifest.json",
"manifest_sha256": "be250212115932eefaad5c6b6aa340abe93589a3dd8381a0804400327ed004e9"
},
"ch4_s2_canal_docks": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s2_canal_docks/manifest.json",
"manifest_sha256": "119777792ffa0022b4477f72781f67d52186f30eec1f5bdcf02b0ebca7e0cfc7"
},
"ch4_s3_luoyang_market": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s3_luoyang_market/manifest.json",
"manifest_sha256": "45d99af284a742051f577f2bc204ad2b08576f52dc0861b4b4ec5785fd6e0d88"
}
}
static func entries() -> Dictionary: return ENTRIES.duplicate(true)
static func formal_enabled() -> bool: return FORMAL_ENABLED
