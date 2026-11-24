extends RefCounted
## ROOT-reviewed generated manifest authority; separate from legacy input closure.
const FORMAL_ENABLED=true
const ENTRIES={
	"ch4_s0_luoyang_gate": {
		"manifest_path": "res://data/maps/luoyang_precomputed_bundle_20261018r3/ch4_s0_luoyang_gate/manifest.json",
		"manifest_sha256": "f8cde53833a3587c68cd529300cc896e64bf8414daf255599f6377eea3401195"
	},
	"ch4_s1_luoyang_yamen": {
		"manifest_path": "res://data/maps/luoyang_precomputed_bundle_20261018r3/ch4_s1_luoyang_yamen/manifest.json",
		"manifest_sha256": "966c888629953546b108de5fc1893b7537ee0b4b6d88b74a17575e458819e221"
	},
	"ch4_s2_canal_docks": {
		"manifest_path": "res://data/maps/luoyang_precomputed_bundle_20261018r3/ch4_s2_canal_docks/manifest.json",
		"manifest_sha256": "923257f80cf974f0da7f5a53c8523963425c03c688d6dadcf437bb8ffd0102d1"
	},
	"ch4_s3_luoyang_market": {
		"manifest_path": "res://data/maps/luoyang_precomputed_bundle_20261018r3/ch4_s3_luoyang_market/manifest.json",
		"manifest_sha256": "2366dcb6461de06ef1be98f489171fb5cdf93140a3535530bbe7eedd08b159bc"
	}
}
static func entries() -> Dictionary: return ENTRIES.duplicate(true)
static func formal_enabled() -> bool: return FORMAL_ENABLED
