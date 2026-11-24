"""Root approved y926 data successor and one finite three-payload CPU input; never engine."""
from pathlib import Path
import json,hashlib,copy,difflib
import numpy as np
from PIL import Image
N=Path(__file__).resolve().parent;G=N.parents[1];OUT=N/'Temple_visible_arrival_local01_NOTREADY'
P='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):return 'res://'+str(p.relative_to(G)).replace('\\','/')
pins={}
def read(p,w):
    p=G/p[6:]if isinstance(p,str)and p.startswith('res://')else Path(p)
    raw=p.read_bytes();assert sha(raw)==w.lower(),(str(p),sha(raw),w);pins[res(p)]=w.lower();return raw
def encode(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode('utf8')
def emit(name,b):
    if not isinstance(b,bytes):b=encode(b)
    with (OUT/name).open('xb')as f:f.write(b)
    return {'path':res(OUT/name),'sha256':sha(b),'bytes':len(b)}
oldpath=N/'author_temple_source_compiled03_NOTREADY.json';oldraw=read(oldpath,'0a8ab1db61b0f8109b26c2b82921be17869278a4f02934b96c47230775e102a3');old=json.loads(oldraw);new=copy.deepcopy(old)
source_routes=[{'id':'default_to_market_return','points_px':[[768,737.28],[730,926],[170,926]]},{'id':'default_to_docks_return','points_px':[[768,737.28],[768,926],[1380,926]]}]
operations=[]
for replacement in source_routes:
    found=[r for r in new['required_routes']if r['id']==replacement['id']];assert len(found)==1
    operations.append({'path':['required_routes',new['required_routes'].index(found[0]),'points_px'],'before':copy.deepcopy(found[0]['points_px']),'after':replacement['points_px']});found[0]['points_px']=replacement['points_px']
for index,row in enumerate(new['finish_i_effective_portal_local_migrations']):
    assert row['new_local_source_foot_px'][1]==980
    before=copy.deepcopy(row['new_local_source_foot_px']);after=[before[0],926]
    operations.append({'path':['finish_i_effective_portal_local_migrations',index,'new_local_source_foot_px'],'before':before,'after':after});row['new_local_source_foot_px']=after
for index,row in enumerate(new['finish_i_incoming_target_migrations']):
    assert row['target_source_foot_px'][1]==980
    for key,after in [('target_source_foot_px',[row['target_source_foot_px'][0],926]),('target_world_foot_f32',[row['target_world_foot_f32'][0],1157.5])]:
        operations.append({'path':['finish_i_incoming_target_migrations',index,key],'before':copy.deepcopy(row[key]),'after':after});row[key]=after
restored=copy.deepcopy(new)
for op in reversed(operations):
    node=restored
    for key in op['path'][:-1]:node=node[key]
    assert node[op['path'][-1]]==op['after'];node[op['path'][-1]]=op['before']
assert restored==old and new['geometry']==old['geometry'] and new['placements']==old['placements'] and new['interaction_relocations']==old['interaction_relocations']
newraw=encode(new);oldlines=oldraw.decode('utf8').splitlines(True);newlines=newraw.decode('utf8').splitlines(True);hunks=[]
for tag,a,b,c,d in difflib.SequenceMatcher(None,oldlines,newlines,autojunk=False).get_opcodes():
    if tag!='equal':hunks.append({'old_line':a,'new_line':c,'old':''.join(oldlines[a:b]),'new':''.join(newlines[c:d])})
back=newlines[:]
for hunk in reversed(hunks):
    at=hunk['new_line'];fragment=hunk['new'].splitlines(True);assert back[at:at+len(fragment)]==fragment;back[at:at+len(fragment)]=hunk['old'].splitlines(True)
assert ''.join(back).encode()==oldraw
author_pin=emit('author_temple_visible_portals04_NOTREADY.json',newraw);pins[author_pin['path']]=author_pin['sha256']
natural_path=N/'temple_signed_iid_repair01/expected_Temple_natural_sources_READONLY.json';natural=json.loads(read(natural_path,'a0c525ed72fbb2d30617c8074087bc9f20c8d5a27210afba2f879ad2730bbf8b'))
for path in ['res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_temple_assembly_20261016.gd']:read(path,natural['source_sha256'][path])
binding=json.loads(read(N/'family_visual_material_loading_repair01/closure_READY01/finish8_binding_READY.json','26b8b652aaa73a93c3123ff4287be63d6952124a6ce9b424c27aa2a30d316ff5'))
sids=['ch4_s4_ancient_temple','ch4_s3_luoyang_market','ch4_s2_canal_docks'];payloads={sid:binding['scenes'][sid]['payload']for sid in sids}
for spec in payloads.values():read(spec['path'],spec['sha256'])
runtime_path='res://build/luoyang_city_finish_20261025i_system01/Temple_visible_arrival03_NOTREADY/finish8_runtime_visible_Temple_CANDIDATE.gd'
read(runtime_path,'74be6359fa36e7699b5e8ba2f3832c11241e1c1b873649590d8aac65775b5f99')
# These GUI files are a new finite read-only diagnostic snapshot, NOT a claim that old runtime
# source maps had declared them. No production ordinary classifications are changed here.
ui_facts={}
for path in ['res://scripts/field/exit_zone.gd','res://scenes/exit_zone.tscn','res://art/ui/field_hud/portal_arrow_amber_v2.png']:
    raw=(G/path[6:]).read_bytes();pins[path]=sha(raw);ui_facts[path]={'sha256':sha(raw),'bytes':len(raw),'authority_kind':'ROOT_REQUESTED_FINITE_HUD_SOURCE_SNAPSHOT_NOT_OLD_DECLARED_RUNTIME_LEAF'}
with Image.open(G/'art/ui/field_hud/portal_arrow_amber_v2.png')as image:
    assert image.size==(300,375);arrow={'canvas_px':list(image.size),'complete_A1_xyxy':list(image.getchannel('A').getbbox()),'no_pixel_write':True}
backup=json.loads(read(N/'temple_signed_iid_repair01/current_377B_backup31_ROOT_ACTUAL.json','8e8f484f0f9b0531969b4e227b5f71abd818dc4935fd568890ad79501bb76026'))
pairs=[{'temple_portal_id':'legacy_portal_6','old_source_foot':[170,980],'new_source_foot':[170,926],'incoming_scene':'ch4_s3_luoyang_market','incoming_portal_id':'to_ancient_temple','incoming_actual_source_foot':[1170,1600]}, {'temple_portal_id':'legacy_portal_7','old_source_foot':[1380,980],'new_source_foot':[1380,926],'incoming_scene':'ch4_s2_canal_docks','incoming_portal_id':'canal_world_ferry','incoming_actual_source_foot':[2140,1840]}]
fixture={'schema':1,'ready':False,'root_run_authorized':False,'author':author_pin,'sources':pins,'payloads':payloads,'pairs':pairs,'routes':[{'id':r['id'],'source_points':r['points_px']}for r in source_routes],'original_two_monks':[{'id':'temple_bell_keeper_20261018t','source_foot':[600,900]},{'id':'temple_cave_keeper_20261018t','source_foot':[936,900]}],'save_absolute_paths':list(backup['save15']),'original_GUI_source_snapshot':ui_facts,'original_arrow_measurement':arrow,'original_label_declared_box':[200,30],'original_hotspots_native_storage_unchanged_because_nonempty_layout_portals_take_precedence':True,'output_root':P+'Temple_visible_arrival_local01_NOTREADY/output_NOTREADY/','no_old_mask_or87517_replay':True,'no_canonical_writes':True}
input_pin=emit('input_NOTREADY.json',fixture)
script_path=OUT/'check_visible_arrival_NOTREADY.gd';script_raw=script_path.read_bytes();script_pin={'path':res(script_path),'sha256':sha(script_raw),'bytes':len(script_raw)}
proof=emit('author_source_four_pairs_complete_inverse_BUILD.json',{'status':'ROOT_APPROVED_Y926_AUTHOR_SOURCE_SCOPE_NOT_EXECUTED','parent':{'path':res(oldpath),'sha256':sha(oldraw),'bytes':len(oldraw)},'candidate':author_pin,'typed_operations':operations,'complete_raw_hunks':hunks,'whole_typed_inverse':restored==old,'whole_byte_inverse':''.join(back).encode()==oldraw,'all_geometry_placement_assets_floor_25bases_NPCs_and_nonportal_interactions_identical':True,'source_payload_change_allowance':{'Temple':['portal_after[legacy_portal_6].pos','portal_after[legacy_portal_7].pos'],'Market_Docks':['portal_after[exact_id].target_pos','new_route_contracts[0].expected_normalized','new_route_contracts[0].source_target_pos','new_route_contracts[0].target_foot_px','new_route_contracts[0].source_portal_row.target_pos']},'native_hotspots_and_layout_storage_untouched':True,'effective_hotspot_semantics':'Exact original layout portal rows take precedence in Field1076..1090. portal_after changes effective exit only after original T FIRST. No new hotspot IDs or historical builder execution.','runtime_counterpart':{'path':runtime_path,'sha256':'74be6359fa36e7699b5e8ba2f3832c11241e1c1b873649590d8aac65775b5f99'},'engine_calls':0,'canonical_writes':0})
handoff={'status':'ROOT_REVIEW_ONLY_TEMPLE_TWO_VISIBLE_ARRIVALS_THREE_PAYLOADS_NOTREADY','script':script_pin,'input':input_pin,'author':author_pin,'author_inverse':proof,'project':'res://'+str((OUT/'project.godot').relative_to(G)).replace('\\','/'),'finite_scope':'Only2 sourcefeet+2 new routes continuous34x24 vs fixed original25/Floor/two34x30monks, original declared marker/label boxes and complete max arrow canvas,3payload wholetyped/raw inverse. No mask or PNG in engine.','prompt_control_box_not_Font_GPU_pixel_PASS':True,'Root_only_run_after_review_and_mechanical_READY':True,'no_Stage_or_canonical_writes':True}
print(json.dumps(emit('handoff_NOTREADY.json',handoff)))
