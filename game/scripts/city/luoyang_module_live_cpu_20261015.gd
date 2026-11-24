extends RefCounted
## run(): exclusive third-layer CPU work, no Node/Texture/ResourceLoader/GPU.
## imported_same(): separate main-thread-only imported Texture readback.
const GATE = preload("res://scripts/city/luoyang_gate_fortification_contract_20261013.gd")
const MARKET = preload("res://scripts/city/luoyang_market_enrichment_contract_20261014.gd")
const CPU_WORKSPACE = preload("res://scripts/city/luoyang_base_cold_cpu_workspace_20261013.gd")
var _mutex:=Mutex.new()
var _cancelled:=false
var _token:=0
var _id: StringName
var _original: Dictionary={}
var _source_context: RefCounted
var _packet: Dictionary={}
var _joined:=false
var _done:=false
var _phase:="module.source"
var _completed:=0
var _total:=1
var elapsed_ms:=0

func configure(token: int,id: StringName,original: Dictionary,cpu_context: RefCounted=null) -> bool:
	if token<=0 or id not in [GATE.ID,MARKET.ID] or original.get("canonical_scene_id")!=String(id): return false
	if cpu_context!=null and (id!=GATE.ID or cpu_context.get_script()!=CPU_WORKSPACE or not cpu_context.matches_owner(token,id)): return false
	_token=token; _id=id; _original=original.duplicate(true)
	_source_context=cpu_context
	return true

func request_cancel() -> void:
	_mutex.lock(); _cancelled=true; _mutex.unlock()

func is_cancelled() -> bool:
	_mutex.lock(); var value:=_cancelled; _mutex.unlock(); return value

func set_progress(phase: String,completed: int,total: int) -> void:
	_mutex.lock(); _phase=phase; _completed=completed; _total=maxi(1,total); _mutex.unlock()

func status() -> Dictionary:
	_mutex.lock(); var value: Dictionary={"phase":_phase,"completed":_completed,"total":_total}; _mutex.unlock(); return value

func run() -> void:
	var started:=Time.get_ticks_msec()
	if is_cancelled(): return
	_packet=GATE.read_after_original_cpu(_original,is_cancelled,set_progress,_source_context,_token) if _id==GATE.ID else MARKET.read_after_original_cpu(_original,is_cancelled,set_progress)
	if is_cancelled(): _packet.clear(); return
	elapsed_ms=Time.get_ticks_msec()-started; _done=true

func mark_joined(token: int,id: StringName) -> bool:
	_joined=token==_token and id==_id and _done and not is_cancelled()
	return _joined

func packet(token: int,id: StringName) -> Dictionary:
	return _packet if _joined and token==_token and id==_id and not is_cancelled() else {}

func release() -> void:
	_original.clear(); _packet.clear(); _joined=false
	_source_context=null

static func imported_same(row: Dictionary) -> bool:
	# Main thread only; no source decode/Lanczos here, original full RGBA retained.
	var texture:=ResourceLoader.load(row.path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var decoded:=texture.get_image() if texture!=null else null
	if decoded==null or (decoded.is_compressed() and decoded.decompress()!=OK): return false
	decoded.convert(Image.FORMAT_RGBA8)
	var size: Vector2i=row.size
	return decoded.get_size()==size and decoded.get_data().slice(0,size.x*size.y*4)==row.bytes
