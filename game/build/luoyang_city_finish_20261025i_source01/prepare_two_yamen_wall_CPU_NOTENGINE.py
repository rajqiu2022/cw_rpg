"""Root narrowed batch: two Yamen walls only; old failed Gate/Inn proposals stay intact."""
from pathlib import Path
import hashlib,json,re,difflib,copy
N=Path(__file__).resolve().parent;G=N.parents[1];OUT=N/'street_edges_yamen02_local01_NOTREADY'
assert not OUT.exists(),'NEW namespace only'
PREFIX='res://build/luoyang_city_finish_20261025i_source01/'
SID='ch4_s1_luoyang_yamen'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):return 'res://'+str(p.relative_to(G)).replace('\\','/')
def fixed(p,w):
    p=G/p[6:] if isinstance(p,str) and p.startswith('res://') else Path(p)
    b=p.read_bytes();assert sha(b)==w.lower(),(str(p),sha(b),w);return b
def encode(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode('utf8')
outputs={}
def emit(name,b):
    if not isinstance(b,bytes):b=encode(b)
    with (OUT/name).open('xb') as f:f.write(b)
    p={'path':res(OUT/name),'sha256':sha(b),'bytes':len(b)};outputs[name]=p;return p
old_fixture_path=N/'street_edges04_local01_NOTREADY/input_NOTREADY.json'
old_fixture=json.loads(fixed(old_fixture_path,'92507a41674ed0148ce45ef8e3c8a289b95a8701fc8c8b1f9a07fc2817352c37'))
old_author_path=N/'street_edges04_BUILD01/author_five_street_edges01_NOTREADY.json'
old_author_raw=fixed(old_author_path,'e44e15872d1f5a4305cd5d21086e6ed54a6e1bca7e2f961806d7ec99570d54e5');old_author=json.loads(old_author_raw)
author=copy.deepcopy(old_author);author['status']='ROOT_NARROWED_YAMEN_TWO_FIXED_WALLS_BUILD_ONLY_NOT_CPU_OR_FIELD_PASS'
author['lots']=[r for r in author['lots'] if r['scene_id']==SID]
assert len(author['lots'])==2
author['counts']['new_rows']=2;author['counts']['new_ground_polygons']=2
author['Root_scope_decision']={'kept_exact_lots':[r['lot_id'] for r in author['lots']],'Gate2_rejected_original_moat_occupation':True,'Inn_new_return_abandoned_original_route_conflict':True,'no_replacement_anchor_search':True,'source_support_diagnostic':{'path':PREFIX+'street_edges04_local01_NOTREADY/original_water_support_conflicts_READONLY.json','sha256':'ad60b7fbf9619e02347fade0629745a866928a46eb6cf331ef4a8a5bea90cc34'},'root_message_approval_only_not_actual_CPU_result':True}
assert author['lots']==[r for r in old_author['lots'] if r['scene_id']==SID]
candidate_raw=encode(author)
# Complete raw author inverse, including metadata/count/subset changes; not a permissive pointer gate.
ops=[]
for tag,a,b,c,d in difflib.SequenceMatcher(None,old_author_raw.decode().splitlines(True),candidate_raw.decode().splitlines(True),autojunk=False).get_opcodes():
    if tag=='equal':continue
    old=''.join(old_author_raw.decode().splitlines(True)[a:b]);new=''.join(candidate_raw.decode().splitlines(True)[c:d]);ops.append({'old':old,'new':new,'old_line_start':a,'new_line_start':c})
lines=candidate_raw.decode().splitlines(True)
for op in reversed(ops):
    start=op['new_line_start'];part=op['new'].splitlines(True);assert lines[start:start+len(part)]==part
    lines[start:start+len(part)]=op['old'].splitlines(True)
assert ''.join(lines).encode()==old_author_raw

OUT.mkdir();author_pin=emit('author_two_yamen_walls_NOTREADY.json',candidate_raw)
fixture=copy.deepcopy(old_fixture)
fixture['status']='ROOT_TWO_YAMEN_WALL_DOMAINS_REVIEW_ONLY_NOT_READY'
fixture['author']=author_pin
for key in ['parent_complete_A1','protected_strips','NPC_guards','portal_guards','route_guards','scenes','source_provenance','excluded_original_ground_A1_rows']:
    fixture[key]={SID:fixture[key][SID]}
fixture['author_new_domain_pixels']=sum(r['domain_pixels'] for r in author['lots']);assert fixture['author_new_domain_pixels']==5606
fixture['output_root']=PREFIX+'street_edges_yamen02_local01_NOTREADY/output_NOTREADY/'
fixture['Root_scope_Gate_and_Inn_excluded']=True
needed={author_pin['path']:author_pin['sha256'],res(old_author_path):sha(old_author_raw)}
old_sources=old_fixture['sources']
for suffix in ['temple_signed_iid_repair01/unified31_READY01/unified31_ROOT_BACKUP_FIXED_NOT_STAGE.json','author_gate_yamen_axis09_three_body_substitutions_NOTREADY.json','family_visual_material_loading_repair01/closure_READY01/finish8_binding_READY.json','temple_signed_iid_repair01/current_377B_backup31_ROOT_ACTUAL.json']:
    path=PREFIX+suffix;needed[path]=old_sources[path]
for path in old_sources:
    if any(s in path for s in ['84632_1726/manifest.json','author_courts_NOTREADY.json','author_retry2.json','yamen_clerk_overlay_PENDING.json']):needed[path]=old_sources[path]
for key in ['payload','mask']:
    pin=fixture['scenes'][SID][key];needed[pin['path']]=pin['sha256']
for row in fixture['parent_complete_A1'][SID]:
    path=row['source_texture'];needed[path]=old_sources[path]
    if path.endswith('.tres'):
        text=fixed(path,old_sources[path]).decode('utf8')
        for texture in re.findall(r'path="(res://[^"\n]+\.png)"',text):needed[texture]=old_sources[texture]
for row in author['lots']:
    path=row['source_asset']['texture'];needed[path]=old_sources[path]
for path,wanted in needed.items():fixed(path,wanted)
fixture['sources']=needed
fixture_pin=emit('input_NOTREADY.json',fixture)

original_script=(N/'street_edges04_local01_NOTREADY/check_four_walls_NOTREADY.gd').read_bytes()
text=original_script.decode('utf8')
old_lots='const LOTS: Array[String]=["EDGE04_GATE_WEST_INSPECTION_COMPOUND","EDGE04_GATE_EAST_PROVISION_COMPOUND","EDGE04_YAMEN_WEST_ARCHIVE_COMPOUND","EDGE04_YAMEN_EAST_RUNNER_COMPOUND"]'
new_lots='const LOTS: Array[String]=["EDGE04_YAMEN_WEST_ARCHIVE_COMPOUND","EDGE04_YAMEN_EAST_RUNNER_COMPOUND"]'
changes=[(old_lots,new_lots),('ids.size()==4','ids.size()==2'),('EXACT_ROOT_FOUR_ITEMS_NO_INN_NO_AUTO_REPAIR','EXACT_ROOT_TWO_YAMEN_ITEMS_NO_GATE_NO_INN_NO_AUTO_REPAIR'),('street_edges04_local01_NOTREADY','street_edges_yamen02_local01_NOTREADY'),('check_four_walls_NOTREADY.gd','check_two_yamen_walls_NOTREADY.gd'),('PENDING_FIXED_AUTHOR_AND_ROOT_REVIEW',fixture_pin['sha256']),('ROOT_FINITE_FOUR_NEW_WALL_DOMAINS_NOT_FIELD_OR_INDEPENDENT_PRIOR','ROOT_FINITE_TWO_YAMEN_NEW_WALL_DOMAINS_NOT_FIELD_OR_INDEPENDENT_PRIOR'),('four_domain_inverse.bin','two_Yamen_domain_inverse.bin'),('only_four_new_domains','only_two_Yamen_new_domains'),('Root-only four fixed new wall domains.','Root-only two fixed Yamen wall domains.')]
for old,new in changes:
    assert old in text,old;text=text.replace(old,new)
back=text
for old,new in reversed(changes):assert new in back;back=back.replace(new,old)
assert back.encode()==original_script
script_pin=emit('check_two_yamen_walls_NOTREADY.gd',text.encode())
project=(N/'street_edges04_local01_NOTREADY/project.godot').read_bytes().replace(b'Root finite four street edges CPU only',b'Root finite two Yamen wall domains CPU only')
emit('project.godot',project)
proof={'status':'BUILD_ONLY_EXACT_YAMEN_TWO_ITEMS_NO_ENGINE_OR_STAGE','author_parent':{'path':res(old_author_path),'sha256':sha(old_author_raw),'bytes':len(old_author_raw)},'author_candidate':author_pin,'author_all_raw_hunks':ops,'author_complete_raw_inverse':True,'kept_lot_values_exact':True,'script_parent':{'path':res(N/'street_edges04_local01_NOTREADY/check_four_walls_NOTREADY.gd'),'sha256':sha(original_script),'bytes':len(original_script)},'script_candidate':script_pin,'script_exact_literal_changes':[{'old':a,'new':b}for a,b in changes],'script_complete_raw_inverse':True,'four_proposals_and_known_rejections_preserved':True,'new_cpu_only_named_two_polygons_vs_all_frozen_original_solids':True,'new_cpu_only_one_parent_payload_and_mask':True,'route_count':len(fixture['route_guards'][SID]),'NPC_count':len(fixture['NPC_guards'][SID]),'source_count':len(needed),'new_pixel_query_budget':5606,'no_early_reject_between_named_lots':True,'Root_CPU_NOT_RUN':True,'no_canonical_writes':True}
proof_pin=emit('scope_and_complete_inverse_BUILD.json',proof)
handoff={'status':'ROOT_REVIEW_ONLY_NOTREADY_DO_NOT_EXECUTE_KNOWN_REJECTED_OLD_FOUR_ITEM_KEY','script':script_pin,'input':fixture_pin,'author':author_pin,'proof':proof_pin,'project_path':res(OUT/'project.godot'),'Root_authorization_required_before_mechanical_READY':True,'only_two_Yamen_wall_domains':True,'Gate_moat_Inn_routes_unchanged':True,'no_full_old_geometry_replay':True,'canonical_writes':0}
print(json.dumps({'handoff':emit('handoff_NOTREADY.json',handoff),'artifacts':outputs},ensure_ascii=False))
