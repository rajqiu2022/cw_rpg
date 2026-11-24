"""Prepare System-owned render-only successor and Root-only media promoter text.
No production copy, import, engine, PNG or source-authority writes.
"""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'game/build/luoyang_city_finish_20261025i_art01/world24d_heads01'
OUT=BASE/'world18_ingress04'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def new(p,b):
    assert not p.exists(),p;p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as h:h.write(b)
def main():
    parent=BASE/'world_bridge_shore_visual_override02_FIXED_NOTREADY.gd'
    assert sha(parent)=='f6bef64cbec4cfca11e243807891e4b88712e112cb94ebef20d489eed90de4b8'
    compact=OUT/'actual_joint_export_compact_receipt.json';assert sha(compact)=='6afe7ad022eda99286ed76d1c687c1d9a3cd2ad45b33deec26eec02c4cdc1ffd'
    script=parent.read_text(encoding='utf-8');before=script
    anchor='const OLD_ROOT: String="res://art/maps/world_map_v15_complete_v9c/"'
    addition='\nconst CAPTURE_PATH: String="res://build/luoyang_city_finish_20261025i_art01/world24d_heads01/world18_ingress04/actual_joint_export_compact_receipt.json"\nconst CAPTURE_SHA: String="6afe7ad022eda99286ed76d1c687c1d9a3cd2ad45b33deec26eec02c4cdc1ffd"\nconst BRIDGE_REPORT: String="res://build/luoyang_city_finish_20261025i_art01/world24d_heads01/coherent18_01/project_ROOT_READY_05/coherent18_output/112968_1092042/result.json"\nconst BRIDGE_REPORT_SHA: String="914add21d9d5f0d16cdf2f72ebbe33e0fee6bb08b732ca1616e44125cc18b95f"\nconst WATER_REPORT: String="res://build/luoyang_city_finish_20261025i_art01/world24d_heads01/coherent18_01/water_receiver02_ROOT_READY_02/water_receiver02_output/112884_1163034/result.json"\nconst WATER_REPORT_SHA: String="f1530acd718b054169dc288aff424fbcb583c08525008a5120d11090a2707b3c"'
    assert script.count(anchor)==1;script=script.replace(anchor,anchor+addition)
    anchor='\tvar capture:=_small_json(String(receipt.path))'
    addition='''
	if receipt.get("path")!=CAPTURE_PATH or receipt.get("sha256")!=CAPTURE_SHA: return "Exact accepted dual-source receipt differs"
	if capture.get("actual_bridge_report")!={"path":BRIDGE_REPORT,"sha256":BRIDGE_REPORT_SHA} or capture.get("actual_water_report")!={"path":WATER_REPORT,"sha256":WATER_REPORT_SHA} or not _sha(BRIDGE_REPORT,BRIDGE_REPORT_SHA) or not _sha(WATER_REPORT,WATER_REPORT_SHA): return "Actual17 plus actualwater source pins differ"
	if capture.get("capture_scope")!="ACTUAL17_MEMBERS_PLUS_ACTUAL_WATER_ONLY_RECEIVER_NO_LAND_REPLACEMENT" or capture.get("rejected_old_receiver_adopted")!=false or capture.get("dry_RGBA_exact")!=true or capture.get("all_chunk_alpha_old_exact")!=true: return "Rejected receiver or unapproved visible land replacement refused"
	var water: Dictionary=capture.get("water_composite",{})
	if water.get("dry_changed_pixels")!=0 or water.get("outside_or_no_alpha_changed_pixels")!=0 or water.get("native_water_alpha_intersection")!=true or water.get("no_additive_shadow")!=true: return "Finite actualwater/dry boundary proof differs"
	var capture_exports: Dictionary={}
	for row: Dictionary in capture.get("export_rows",[]):
		var p: String=String(row.get("path",""))
		if capture_exports.has(p): return "Duplicate source export row"
		capture_exports[p]=row
	if capture_exports.size()!=18: return "Exactly18 accepted dual-source exports required"'''
    assert script.count(anchor)==1;script=script.replace(anchor,anchor+addition)
    anchor='\t\tvar error:=_proof_row(imports.get(path,{}),path,String(entry.sha256),old.native_size)'
    addition='\t\tvar export_row: Dictionary=capture_exports.get(path,{})\n\t\tif export_row.get("sha256")!=entry.sha256 or export_row.get("actual_export_report_sha256")!=BRIDGE_REPORT_SHA or not _size(export_row.get("size"),old.native_size): return "Bridge media is not the exact accepted original17 export"\n'
    assert script.count(anchor)==1;script=script.replace(anchor,addition+anchor)
    anchor='\tvar error:=_proof_row(imports.get(new_path,{}),new_path,String(chunk.sha256),Vector2i(1536,1024))'
    addition='\tvar export_chunk: Dictionary=capture_exports.get(new_path,{})\n\tif export_chunk.get("sha256")!=chunk.sha256 or chunk.sha256!="bf90b660f27990f206b86b351b78da3a4171af1123f3912542f8bb7758d94a00" or export_chunk.get("actual_export_report_sha256")!=WATER_REPORT_SHA: return "Chunk is not the accepted water-only receiver"\n'
    assert script.count(anchor)==1;script=script.replace(anchor,addition+anchor)
    new(OUT/'world_bridge_shore_visual_override03_NOTREADY.gd',script.encode())
    # Preserve full original as exact source inverse; no canonical module change.
    restored=script.replace(addition+anchor,anchor,1)
    # Whole parent bytes are retained, with explicit matching hash authority.
    interface=json.loads((BASE/'world_visual_consumer_source_interface02_NOTREADY.json').read_text(encoding='utf-8'))
    for r in interface['candidate_hunks']:
        assert sha(ROOT/r['production_target'])==r['old_sha256'] and sha(ROOT/r['candidate'])==r['candidate_sha256']
    inverse={'parent_sha256':sha(parent),'parent_whole_text':before,'new_sha256':sha(OUT/'world_bridge_shore_visual_override03_NOTREADY.gd'),'whole_parent_recoverable_exact':hashlib.sha256(before.encode()).hexdigest()==sha(parent),'canonical_writes':0}
    new(OUT/'consumer03_whole_source_inverse.json',enc(inverse))
    interface.update({'status':'EXACT_DUAL_ACTUAL_SOURCE_CONSUMER03_CANDIDATE_NOT_ACTIVE','module':str((OUT/'world_bridge_shore_visual_override03_NOTREADY.gd').relative_to(ROOT)),'module_sha256':sha(OUT/'world_bridge_shore_visual_override03_NOTREADY.gd'),'actual_reports':json.loads(compact.read_text(encoding='utf-8'))['actual_bridge_report']|{'water':json.loads(compact.read_text(encoding='utf-8'))['actual_water_report']},'capture_blocker':'Resolved finite local ownership by acceptedwater-only receiver; no wholeworld or riverbank style approval','still_missing_before_activation':['actual18 isolatedimport fullRGBA + natural process receipts','NEW54 byte promotion','Root approvalmanifest true/pinned and module READYtrue only after exact proof','Source stage current2hook+1module+ordinary receipt/import/18media closure; no cityOWNED expansion']})
    new(OUT/'consumer03_source_interface_NOTREADY.json',enc(interface))
    # Exact mature CreateNew promoter copied only as NEW text, variable facts
    # are supplied by a later fixed plan after real import, never guessed now.
    old=ROOT/'game/build/luoyang_city_finish_20261025i_art01/promote_ten_media30_ROOT_ONLY.ps1'
    assert sha(old)=='221eb7ead0bc4a360a75c0e580ee1f46a3d587b286c1de7ce5fbc257e2f7d1ef'
    ps=old.read_text(encoding='utf-8')
    ps=ps.replace("$isolate='F:/Code/RPG_GAME/game/build/luoyang_city_finish_20261025i_art01/ten_media_isolate_ROOT_PREPARED'","$isolate='F:/Code/RPG_GAME/game/build/luoyang_city_finish_20261025i_art01/world24d_heads01/world18_ingress04/isolate_ROOT_PREPARED'")
    ps=ps.replace("$taskRoot='F:/Code/RPG_GAME/game/build/luoyang_city_finish_20261025i_art01'","$taskRoot='F:/Code/RPG_GAME/game/build/luoyang_city_finish_20261025i_art01/world24d_heads01/world18_ingress04'")
    ps=ps.replace('ten_media30_promotion_plan01_CANDIDATE.json','world18_media54_promotion_plan_CANDIDATE.json').replace('ten_media30_promotion_ROOT_EXECUTED.json','world18_media54_promotion_ROOT_EXECUTED.json')
    ps=ps.replace('TEN_NEW_MEDIA30_MECHANICAL_PROMOTION_CANDIDATE_NOT_EXECUTED','WORLD18_NEW_MEDIA54_MECHANICAL_PROMOTION_CANDIDATE_NOT_EXECUTED').replace('Count -ne 30','Count -ne 54').replace('Count -eq 30','Count -eq 54').replace('leaves=30','leaves=54').replace('warnings=10','warnings=18')
    start=ps.index('$r=Get-Content');end=ps.index('foreach($p in $plan.protected_before.Keys)',start)
    ps=ps[:start]+'''$r=Get-Content -LiteralPath $plan.import_result_path -Raw|ConvertFrom-Json -AsHashtable
if(!$r.passed -or $r.failures.Count -ne 0 -or $r.rows.Count -ne 18 -or $r.scope -cne 'EXACT_JOINT18_NATIVE_WORLD_EXPORTS_ISOLATED_FULL_RGBA_NOT_RUNTIME' -or $r.prepared_sha256 -cne $plan.prepared_sha256){throw 'EXACT_JOINT18_FULL_RGBA_PASS_REQUIRED'}
if($plan.process_receipts.Count -ne 2){throw 'EXACT_TWO_REAL_PROCESS_RECEIPTS_REQUIRED'}
foreach($processRow in $plan.process_receipts){
 $p=Get-Content -LiteralPath $processRow.path -Raw|ConvertFrom-Json -AsHashtable
 if((Sha $processRow.path) -cne $processRow.sha256 -or $p.actual_natural_console_exit_code -ne 0 -or !$p.retained_process_WaitForExit -or $p.stopped_by_tool -or $p.main_promotion){throw 'BOTH_REAL_NATURAL_PROCESS_EXITS_REQUIRED'}
}
''' +ps[end:]
    ps=ps.replace('THIRTY','FIFTYFOUR').replace('Thirty','Fiftyfour').replace('thirty','fiftyfour')
    new(OUT/'promote_world18_media54_ROOT_ONLY.ps1',ps.encode())
    new(OUT/'consumer03_and_promoter_static_receipt.json',enc({'consumer03_sha256':sha(OUT/'world_bridge_shore_visual_override03_NOTREADY.gd'),'promoter_sha256':sha(OUT/'promote_world18_media54_ROOT_ONLY.ps1'),'interface_sha256':sha(OUT/'consumer03_source_interface_NOTREADY.json'),'actual_reports_fixed':[P for P in ['914add21d9d5f0d16cdf2f72ebbe33e0fee6bb08b732ca1616e44125cc18b95f','f1530acd718b054169dc288aff424fbcb583c08525008a5120d11090a2707b3c']],'canonical_writes':0,'engine':0,'promoter_plan_pending_actual_import':True}))
    print((OUT/'consumer03_and_promoter_static_receipt.json').read_text(encoding='utf-8'))
if __name__=='__main__':main()
