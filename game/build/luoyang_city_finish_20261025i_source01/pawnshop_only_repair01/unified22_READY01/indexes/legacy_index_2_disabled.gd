extends RefCounted
const FORMAL_ENABLED=false
const ENTRIES={
"ch4_s0_luoyang_gate": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json",
"manifest_sha256": "30d3ed09f2fe0c82db3f008a3f918e8aa21ac7df1dd4259fe3917572e015419f"
},
"ch4_s1_luoyang_yamen": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/manifest.json",
"manifest_sha256": "8cc86693dbd3d0c03fd0f12924a19ebbeb62489e4e8150fa6884da367fcff77f"
},
"ch4_s2_canal_docks": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s2_canal_docks/manifest.json",
"manifest_sha256": "cf24b2aaab27388d64aafba082ae981b33703f52c573f5ffacec0145e4672497"
},
"ch4_s3_luoyang_market": {
"manifest_path": "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s3_luoyang_market/manifest.json",
"manifest_sha256": "f14bd63fb8ed2f64bd1cf89ca4677f1cadbe7112a7344abac2ec2c7006b47824"
}
}
static func entries() -> Dictionary: return ENTRIES.duplicate(true)
static func formal_enabled() -> bool: return FORMAL_ENABLED
