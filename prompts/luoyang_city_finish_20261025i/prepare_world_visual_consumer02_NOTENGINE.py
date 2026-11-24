"""System/Source interface candidate only: exact path dispatch, never deploy or render."""
from pathlib import Path
import hashlib,json,re,difflib
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01/world24d_heads01'
SOURCE=ROOT/'game/data/maps/world_map_v15_complete_v9c_source.json';LAYOUT=ROOT/'game/data/maps/world_map_jianghu_layout_v15.tres'
TEMPLATE=OUT/'world_bridge_shore_visual_override01_NOTREADY.gd'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,v):
    assert not p.exists()
    with p.open('xb') as f:f.write(v if isinstance(v,bytes) else (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode())
source=json.loads(SOURCE.read_bytes());assert sha(SOURCE)=='85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f'
fixture=json.loads((ROOT/'game/build/world_water_bridge_20261024d_system01/native_sample01/project/input_candidate02_ROOT_READY.json').read_bytes())
layout=LAYOUT.read_text(encoding='utf-8');expected=[];entries=[];source_rows=[]
for part in fixture['bridge']['parts']:
    ident=part['id'];needle='"id": '+json.dumps(ident)+','
    assert layout.count(needle)==1
    at=layout.index(needle);start=layout.rfind('\n}, {',0,at)+6;end=layout.find('\n}, {',at)
    block=layout[start:end]
    def prop(k):
        m=re.search(r'^"'+re.escape(k)+r'": (.*?)(?:,)?$',block,re.M);assert m,(ident,k)
        return m.group(1).rstrip(',')
    row=next(x for x in source['objects'] if x['id']==ident)
    path=json.loads(prop('texture'));assert path==row['texture']
    pin=source['asset_sha256'][path];assert sha(ROOT/('game/'+path[6:]))==pin
    render=prop('render_size_px');m=re.fullmatch(r'Vector2\(([^,]+), ([^)]+)\)',render);assert m
    size=[int(float(m.group(1))),int(float(m.group(2)))];assert size==[int(x) for x in row['source_size_px']]
    pos=prop('pos');assert re.fullmatch(r'Vector2\([^,]+, [^)]+\)',pos)
    sort=prop('sort_by_feet');z=prop('z_index')
    expected.append(json.dumps(ident)+':{"texture":'+json.dumps(path)+',"png_sha256":'+json.dumps(pin)+',"native_size":Vector2i('+str(size[0])+','+str(size[1])+'),"pos":'+pos+',"sort_by_feet":'+sort+',"z_index":'+z+'}')
    entries.append({'id':ident,'old_path':path,'old_sha256':pin,'path':'res://art/maps/world_bridge_shore_20261025i/entities/'+ident+'.png','sha256':None,'source_size_px':size,'status':'REQUIRES_REAL_COHERENT_EXPORT_NOT_A_SAMPLE_CROP'})
    source_rows.append({'id':ident,'actual_layout_block_sha256':hashlib.sha256(block.encode()).hexdigest(),'literal_pos_from_actual_TRES':pos,'literal_render_size_from_actual_TRES':render,'all_physical_fields':'Originaldictionaryuntouched; onlyindexpathresolved,not datatexture mutation','original_source_record':row})
code=TEMPLATE.read_text(encoding='utf-8')
anchor='const EXPECTED: Dictionary={} # Builder inserts exact17old render rows, not runtimeobserved expected.'
assert code.count(anchor)==1
module=code.replace(anchor,'const EXPECTED: Dictionary={\n'+',\n'.join(expected)+'\n}')
modulepath=OUT/'world_bridge_shore_visual_override02_FIXED_NOTREADY.gd';save(modulepath,module.encode())
world=ROOT/'game/scripts/world/world_v15_visible_stream_20261018r.gd'
background=ROOT/'game/scripts/field/background_chunk_streamer.gd'
assert sha(world)=='9da2f8b5de0983fa5c23ca07ab651ab4dc0462e7b0353028fbfc96664f5dbba1'
assert sha(background)=='68db675234eb77d11416b75fe0c653b8672116b3649b0d90bc299327815c0bc8'
target='res://scripts/world/world_bridge_shore_visual_override_20261025i.gd'
hookpairs=[(world,[( 'const WORLD_CONTRACT = preload("res://scripts/world/world_map_v15_contract.gd")','const WORLD_CONTRACT = preload("res://scripts/world/world_map_v15_contract.gd")\nconst BRIDGE_SHORE_VISUAL = preload("'+target+'")'),('\t\tvar path:=String(data.get("texture",""))','\t\tvar path:=BRIDGE_SHORE_VISUAL.object_path(data)')]),(background,[('const WORLD_VISUAL_PATCH := preload("res://scripts/world/world_farmland_visual_patch_resolver_20261015.gd")','const WORLD_VISUAL_PATCH := preload("res://scripts/world/world_farmland_visual_patch_resolver_20261015.gd")\nconst BRIDGE_SHORE_VISUAL := preload("'+target+'")'),('\t_chunks = WORLD_VISUAL_PATCH.effective_chunks(definition, prefer_desktop)','\t_chunks = BRIDGE_SHORE_VISUAL.effective_chunks(WORLD_VISUAL_PATCH.effective_chunks(definition, prefer_desktop), definition)')])]
hunks=[]
for p,swaps in hookpairs:
    before=p.read_bytes();text=before.decode();after=text
    for old,new in swaps:assert after.count(old)==1;after=after.replace(old,new)
    inverse=after
    for old,new in reversed(swaps):assert inverse.count(new)==1;inverse=inverse.replace(new,old)
    assert inverse.encode()==before
    candidate=OUT/(p.stem+'_VISUAL_HOOK_CANDIDATE.gd');save(candidate,after.encode())
    diff=''.join(difflib.unified_diff(text.splitlines(keepends=True),after.splitlines(keepends=True),fromfile=p.relative_to(ROOT).as_posix(),tofile=candidate.relative_to(ROOT).as_posix()))
    save(OUT/(p.stem+'_visual_hook.diff'),diff.encode())
    hunks.append({'production_target':p.relative_to(ROOT).as_posix(),'old_sha256':sha(p),'candidate':candidate.relative_to(ROOT).as_posix(),'candidate_sha256':sha(candidate),'exact_old_whole_byte_inverse':True,'swaps':[{'old':a,'new':b} for a,b in swaps]})
approval={'schema':1,'approved':False,'approved_by':None,'scope':'DESKTOP_BRIDGE01_17_VISUALS_AND_R1C2_SHADOW_COHERENT_ONLY','parent_source_path':'res://data/maps/world_map_v15_complete_v9c_source.json','parent_source_sha256':sha(SOURCE),'coherent_export_receipt':{'path':None,'sha256':None},'import_proof':{'path':None,'sha256':None},'entries':entries,'chunk':{'old_path':'res://art/maps/world_map_v15_complete_v9c/chunks/r1_c2_visual.png','old_sha256':'22390cbb28822f88d6e99d89fa6898d4fa9bff8c74c9d35329adcb29b5c3d636','path':'res://art/maps/world_bridge_shore_20261025i/chunks/r1_c2_visual.png','sha256':None,'logical_rect':[3072,1024,1536,1024],'draw_scale':1.0},'all64walk_or_physical_or_scene_records_mutated':False,'missing_entries_are_not_assumed_generated':True}
save(OUT/'approved_visual_manifest_SCHEMA_NOTREADY.json',approval)
contract={'status':'EXACT_SYSTEM_CONSUMER_SOURCE_INTERFACE_CANDIDATE_NOT_ACTIVE_NOT_DEPLOYED','module':modulepath.relative_to(ROOT).as_posix(),'module_sha256':sha(modulepath),'proposed_new_canonical_module':target,'module_READY':False,'approval_SHA_empty':True,'canonical_writes':0,'old_SOURCE_sha256':sha(SOURCE),'actual_layout_current_readonly_SHA256':sha(LAYOUT),'actual_TRES_typed_render_tuples_not_unrounded_JSON':True,'seventeen_source_records':source_rows,'candidate_hunks':hunks,'consumer_order':{'objects':'WorldVisibleStream.make_index object_path only; sameindexfeedsinitial_selectionandthreadedloads; physicalFieldinputobjectsunchanged','background':'BackgroundChunkStreamer.configure wraps existingfarmland effective_chunks, thenonlyr1c2path; all12farmlandentriesandother63chunkdictsretained','Field_attach':'Nochange. Fixedoriginaldata.pos/render_size/rotation/depth used withexactnewnativecanvas. No newruntime3D.'},'source_stage_required':'Source/Rootmuststage2consumerGD+1NEWmodule+approvalordinarysource+18export/importtuples, preserveoldSOURCE/layout/64walk;do NOTaddcityOWNEDorrelaxfinitegate. Currentmodulewithfalsecannotgrantactualworldimprovement.','still_missing_before_activation':['ART/Rootsinglefinitecandidateactualapproval','Realcoherent18textureexportwithoriginalshadowreceiver/casterownership; samplePNGisnot croppedcomponents','Independent18raw/import/directctexwholeRGBAproof','ExplicitRootmanifestfillednulls->fixedSHAandNEWmoduleREADYtrue/APPROVAL_SHA; RootsourceclosureStageonlythenproduction'], 'capture_blocker':'Formalr1c2maycontainshadowsfromotheroriginalcasters; must useoriginalcastersetorprovefiniteoldshadowownership,notjustpastebridgecutout/samplebackground. Noautomaticfull64recapture.','web':'Deliberatelyallold onweb; do not mixnewshorechunkwitholdbridge','runtime_tests_needed':'Onlychangedbridgecontext:sourcebound18pathactivation,old17physical+64walksame,actor/raildepthandcrossingtwoshoreapproaches; no rerunallworldgeometry or cityoldcomponents','no_imagegen_no_engine':True}
save(OUT/'world_visual_consumer_source_interface02_NOTREADY.json',contract)
print(json.dumps({'module_sha256':sha(modulepath),'interface_sha256':sha(OUT/'world_visual_consumer_source_interface02_NOTREADY.json'),'hunks':[{k:r[k] for k in ['production_target','candidate_sha256']} for r in hunks],'engine':0,'formal':0}))
