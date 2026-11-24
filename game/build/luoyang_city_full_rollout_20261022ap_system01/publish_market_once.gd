extends "res://build/luoyang_city_full_rollout_20261022ap_system01/publish_market.gd"
## Preserve the handed-off base bytes. Five rooms share most of 253 history
## leaves: one actual first read per unique source, one complete final read.
const BASE_SCRIPT="res://build/luoyang_city_full_rollout_20261022ap_system01/publish_market.gd"
const BASE_SHA="b75685b59be6743e4efab1c867fa79bd2259a0206020f0fbbb906eb7f9fa8a55"
func track(path: String,pin: String="") -> bool:
	if sources.has(path): return need(pin.is_empty() or sources[path]==pin,"DUPLICATE_SOURCE_DECLARATION:"+path)
	return super.track(path,pin)
func publication() -> Dictionary:
	if not track(BASE_SCRIPT,BASE_SHA): return {}
	return super.publication()
