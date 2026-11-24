"""Prepare Root-only new-domain formal pair/entry residual. Does not launch."""
from pathlib import Path
import json,hashlib
T=Path(__file__).resolve().parent
O=T/'formal_residual01'
assert not O.exists()
src=(T/'keepalive01/same_pair_probe.gd').read_text(encoding='utf-8')
src=src[:src.index('\nfunc install_diagnostic()')]
src=src.replace('## Same-window diagnostic only; in-memory timers, not formal functional admission.','## One formal affected pair and one Gate actual C-to-B source-set admission. No instrumentation.')
src=src.replace('const HOME := "res://build/loading_20261106_system03/keepalive01/"','const HOME := "res://build/loading_20261106_system03/formal_residual01/"')
src=src.replace('var instrumented_scripts: Array[GDScript] = []\nvar finish_runtime: GDScript\nvar instrumentation_ready := false\n','var gate_admission: Dictionary = {}\n')
src=src.replace('\tif not install_diagnostic():\n','\tif not formal_sources_exact():\n')
src=src.replace('\tEngine.set_meta("loading03_trace", {"enabled":true,"rows":[],"stack":[],"dropped":0})\n','')
src=src.replace('\tawait create_timer(1.0,true,false,true).timeout\n\tfinish()','\tawait create_timer(1.0,true,false,true).timeout\n\tgate_admission = check_gate_sources()\n\tneed(gate_admission.get("passed",false), "GATE_REAL_C_TO_B_EXACT_SET")\n\tfinish()')
start=src.index('\tvar trace: Dictionary=Engine.get_meta(')
end=src.index('\tvar output := HOME',start)
src=src[:start]+'''\tresult["scope"]="FORMAL_ONE_TRUE_YAMEN_ARTISAN_PAIR_PLUS_GATE_SOURCE_ADMISSION_NOT_TRAVEL_MATRIX"
\tresult["gate_source_admission"] = gate_admission
\tresult["passed"]=errors.is_empty()
\tresult["checks"]=checks
\tresult["errors"]=errors
\tresult["limits"]="No memory reload or candidate instrumentation. Gate is real source collector admission only, not World-to-Gate input travel. All prior warnings retained. One pair measurement is not broad performance acceptance."
'''+src[end:]
src+='''
func formal_sources_exact() -> bool:
\tvar receipt: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(HOME+"../keepalive_closure_READY01/receipt.json"))
\tfor row: Dictionary in receipt.targets:
\t\tvar path: String="res://"+String(row.target).trim_prefix("game/")
\t\tif not need(FileAccess.get_sha256(path)==String(row.new_sha256),"ADOPTED_EXACT_SOURCE:"+path): return false
\tvar leaf: Dictionary=receipt.new_runtime_leaf
\treturn need(FileAccess.get_sha256(leaf.path)==leaf.sha256,"EXACT_NEW_ROUTER_IMMUTABLE_LEAF")

func check_gate_sources() -> Dictionary:
\tvar id: StringName=&"ch4_s0_luoyang_gate"
\tvar path: String=router.call("field_scene_resource_path",id)
\tvar scene: Resource=load(path)
\tvar c: GDScript=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
\tvar b: GDScript=load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
\tvar actual: Dictionary=c.call("_transition_sources",scene,true)
\tvar config: Dictionary=b.call("manifest",id)
\tvar expected: Dictionary=config.get("legacy_source_sha256",{}).duplicate(true)
\texpected.merge(config.get("runtime_authority_sha256",{}))
\texpected.merge(config.get("artifacts",{}))
\tfor index: String in [b.INDEX,b.ESTATE_INDEX,b.AO_INDEX,b.AP_INDEX,b.AP_ENV_INDEX,b.AP_EXEC_INDEX,b.AP_QUARTER_INDEX,b.MG_INDEX]:
\t\texpected[index]=FileAccess.get_sha256(index)
\tvar entry: Dictionary=b.call("_entry",id)
\tif not entry.is_empty():expected[entry.manifest_path]=entry.manifest_sha256
\tvar extra: Dictionary={}
\tvar missing: Dictionary={}
\tvar different: Dictionary={}
\tfor p: String in actual:
\t\tif not expected.has(p):extra[p]=actual[p]
\t\telif actual[p]!=expected[p]:different[p]={"expected":expected[p],"actual":actual[p]}
\tfor p: String in expected:
\t\tif not actual.has(p):missing[p]=expected[p]
\tvar admitted: Dictionary=b.call("describe",id,actual)
\treturn {"scope":"GATE_ACTUAL_C_TO_B_NO_TRAVEL","passed":not config.is_empty() and not admitted.is_empty() and actual==expected,"actual_count":actual.size(),"expected_count":expected.size(),"extra":extra,"missing":missing,"different":different,"actual_sources":actual,"expected_sources":expected,"admitted":not admitted.is_empty()}
'''
O.mkdir();(O/'.gdignore').write_bytes(b'');(O/'formal_pair_probe.gd').write_text(src,encoding='utf-8',newline='\n')
receipt=json.loads((T/'keepalive_closure_READY01/receipt.json').read_text(encoding='utf-8'))
paths=[r['target'] for r in receipt['targets']]
paths += [receipt['new_runtime_leaf']['path'],'res://build/loading_20261106_system03/keepalive_closure_READY01/receipt.json','res://build/loading_20261106_system03/formal_residual01/formal_pair_probe.gd','res://build/loading_20261106_system03/formal_residual01/launch_ROOT_ONLY.ps1','res://project.godot','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/city/luoyang_precomputed_bundle_20261018r.gd','res://build/city_navigation_20261101d_candidate01/city_navigation_runtime.gd','res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd','res://build/city_navigation_20261101d_candidate01/navigation_geometry.gd','res://scripts/city/luoyang_quarters_family_20261022ap.gd','res://build/luoyang_gate_short_walls_20261029m_system01/closure_READY01/finish8_runtime_READY.gd']
(O/'source_inventory.json').write_text(json.dumps({'source_paths':list(dict.fromkeys(paths))},indent=2)+'\n',encoding='utf-8')
inventory_sha=hashlib.sha256((O/'source_inventory.json').read_bytes()).hexdigest()
launch='''$ErrorActionPreference = 'Stop'
$inventory = 'F:\\Code\\RPG_GAME\\game\\build\\loading_20261106_system03\\formal_residual01\\source_inventory.json'
& 'F:\\Code\\RPG_GAME\\game\\build\\loading_20261106_system02\\run_metadata_protected_ROOT_ONLY.ps1' -RunName 'run05_formal_scoped_keepalive' -Entry 'res://build/loading_20261106_system03/formal_residual01/formal_pair_probe.gd' -SourcePathsFile $inventory -SourcePathsSHA '%s' -Gpu -TimeoutSeconds 90
exit $LASTEXITCODE
'''%inventory_sha
(O/'launch_ROOT_ONLY.ps1').write_text(launch,encoding='utf-8')
print(json.dumps({'fixture':str(O),'protected_paths':len(set(paths)),'inventory_sha256':inventory_sha}))
