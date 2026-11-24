"""Independent small-text static audit. No engine, collector, media/native decode."""
import copy,hashlib,json,pathlib,re
GAME=pathlib.Path(__file__).resolve().parents[2]
S=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
ROOT=GAME/'build/luoyang_city_full_rollout_20261022ap_root01'
BASE=S/'performance100_unified_life_garden_scholar_BUILD'
def raw(p):return pathlib.Path(p).read_bytes()
def sha(p):return hashlib.sha256(raw(p)).hexdigest()
def txt(p):return raw(p).decode('utf-8')
def obj(p):return json.loads(txt(p))
def need(v,label):
    if not v:raise AssertionError(label)
def res(p):
    need(p.startswith('res://') and '..' not in p,'RES_PATH')
    return GAME/p[6:]
def strict(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return list(a)==list(b) and all(strict(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(strict(x,y) for x,y in zip(a,b))
    return a==b
def invert(record):
    old=res(record['parent']['path']);new=res(record['candidate']['path'])
    need(sha(old)==record['parent']['sha256'] and sha(new)==record['candidate']['sha256'],'PAIR_PIN')
    a=txt(old);b=txt(new);forward=a;back=b
    for h in record['hunks']:
        need(forward.count(h['old'])==1,'SINGLE_OLD_HUNK')
        forward=forward.replace(h['old'],h['new'])
    for h in reversed(record['hunks']):
        need(back.count(h['new'])==1,'SINGLE_NEW_HUNK')
        back=back.replace(h['new'],h['old'])
    need(forward.encode('utf-8')==raw(new) and back.encode('utf-8')==raw(old),'WHOLE_UTF8_FORWARD_REVERSE')
    need(raw(old).endswith(b'\n') and raw(new).endswith(b'\n'),'GD_OR_JSON_FINAL_LF_PRESERVED')
    return {'target':record.get('target'),'hunks':len(record['hunks']),'parent_CR':raw(old).count(b'\r'),'candidate_CR':raw(new).count(b'\r'),'candidate_SHA':sha(new)}

proof_path=BASE/'whole_code_data_execution_inverse_BUILD.json'
scope_path=BASE/'exact28_scope_PROPOSAL_NOT_APPROVED.json'
need(sha(proof_path)=='057b5b935bd86b04b5b710de0d3224ff4cba23d98f5d4c1377987f7fe0b71cf3','FIXED_PROOF')
need(sha(scope_path)=='a716540f4c5e710bbd21031677926f33f3e885649653a1501d954f804ab4b616','FIXED_SCOPE')
proof=obj(proof_path);scope=obj(scope_path)
audits=[invert(r) for r in proof['records'].values()]
contract_key='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
contract=proof[contract_key];audits.append(invert(contract))
binding=proof['temple_binding'];audits.append(invert(binding))
old_contract=obj(res(contract['parent']['path']));new_contract=obj(res(contract['candidate']['path']))
field='res://scripts/field/field_walkable_controller.gd'
coord='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'
temple='res://scripts/city/luoyang_temple_assembly_20261016.gd'
changed={k for k in old_contract['source_sha256'] if old_contract['source_sha256'][k]!=new_contract['source_sha256'].get(k)}
need(changed=={field} and list(old_contract['source_sha256'])==list(new_contract['source_sha256']),'CONTRACT_FIELD_ONLY')
restored=copy.deepcopy(new_contract);restored['source_sha256'][field]=old_contract['source_sha256'][field]
need(strict(restored,old_contract),'WHOLE_TYPED_CONTRACT_INVERSE')
old_binding=obj(res(binding['parent']['path']));new_binding=obj(res(binding['candidate']['path']))
changed_binding={k for k in old_binding['source_delta'] if old_binding['source_delta'][k]!=new_binding['source_delta'].get(k)}
need(changed_binding=={field,coord,contract_key} and list(old_binding['source_delta'])==list(new_binding['source_delta']),'BINDING_ONLY3_DELTA_VALUES')
restored=copy.deepcopy(new_binding)
for k in changed_binding:restored['source_delta'][k]=old_binding['source_delta'][k]
need(strict(restored,old_binding),'WHOLE_TYPED_BINDING_INVERSE')
parent_binding=res(new_binding['parent_binding_path'])
need(sha(parent_binding)==new_binding['parent_binding_sha256'],'FIXED_PARENT_BINDING_SHA')
merged_old=dict(obj(parent_binding)['source_sha256']);merged_old.update(old_binding['source_delta'])
merged_new=dict(obj(parent_binding)['source_sha256']);merged_new.update(new_binding['source_delta'])
need(len(merged_old)==len(merged_new)==189 and set(merged_old)==set(merged_new),'MERGED189_NO_KEYSET_CHANGE')
need({k for k in merged_old if merged_old[k]!=merged_new[k]}==changed_binding,'MERGED_ONLY3_OF189')

old_path=res(proof['execution_parent']['path']);new_path=res(proof['execution_candidate']['path'])
need(sha(old_path)==proof['execution_parent']['sha256'] and sha(new_path)=='a971de4023f2f61fd67738f62608354bf9a1a38173aefa5718e233b5d6174395','EXECUTION_PINS')
old=obj(old_path);new=obj(new_path);restored=copy.deepcopy(new)
need(list(old['owned'])==list(new['owned']) and len(old['owned'])==10,'EXACT10_MEMBERSHIP_ORDER')
changed_owned={k for k in old['owned'] if old['owned'][k]!=new['owned'][k]}
need(changed_owned=={field,coord,temple},'ONLY3_OWNED_CHANGED')
edge_rows=[]
for k,row in old['owned'].items():
    now=new['owned'][k]
    if k in changed_owned:
        need(len(now['edges'])==len(row['edges'])+1 and strict(now['edges'][:-1],row['edges']),'OLD_EDGE_HISTORY_EXACT')
        e=now['edges'][-1];code=proof['records'][k]
        need(e['old_sha256']==row['current_sha256']==code['parent']['sha256'] and e['new_sha256']==now['current_sha256']==code['candidate']['sha256'],'EDGE_OLD_NEW_EXACT')
        need(e['old_snapshot']==code['parent']['path'] and e['new_snapshot']==code['candidate']['path'] and e['whole_inverse'] is True,'EXACT_SNAPSHOT_AUTHORITY')
        # Recorded edge replacements and direct code proof must reconstruct the same full bytes.
        x=txt(res(e['old_snapshot']))
        for h in e['replacements']:
            need(x.count(h['old'])==1,'EDGE_REPLACEMENT_SINGLE')
            x=x.replace(h['old'],h['new'])
        need(x.encode('utf-8')==raw(res(e['new_snapshot'])),'EDGE_COMPLETE_CODE_RECONSTRUCTION')
        restored['owned'][k]=copy.deepcopy(row)
        edge_rows.append({'path':k,'old_edges':len(row['edges']),'new_edges':len(now['edges']),'replacement_hunks':len(e['replacements'])})
    else:need(strict(now,row),'OTHER7_WHOLE_ROWS_SAME')
need(len(old['source_sha256'])==96 and len(new['source_sha256'])==101,'96_TO101')
added=set(new['source_sha256'])-set(old['source_sha256'])
need(added==set(proof['added_proof_pins']) and len(added)==5,'EXACT5_NEW_PROOFS')
for p,h in old['source_sha256'].items():need(new['source_sha256'].get(p)==h,'ALL96_OLD_PINS_UNCHANGED')
for p in added:
    need(new['source_sha256'][p]==proof['added_proof_pins'][p] and sha(res(p))==new['source_sha256'][p],'NEW5_CURRENT_SMALL_SHA')
    del restored['source_sha256'][p]
need(strict(restored,old),'WHOLE_EXECUTION_ORDERED_TYPED_INVERSE')
need((json.dumps(restored,ensure_ascii=False,indent=2)+'\n').encode('utf-8')==raw(old_path),'WHOLE_EXECUTION_SERIALIZED_UTF8_INVERSE')

need(scope['target_count']==28 and len(scope['targets'])==28 and scope['counts']=={'GD':14,'JSON':14},'EXACT28_14_14')
targets={x['target']:x for x in scope['targets']};need(len(targets)==28,'UNIQUE_TARGETS')
excluded={'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/city/luoyang_assembled_interiors_20261016g.gd','res://scripts/city/luoyang_district_life_20261016f.gd','res://scripts/city/luoyang_docks_district08_20261019aa.gd','res://scripts/city/luoyang_docks_workyard_20261019ac.gd','res://scripts/autoload/scene_router.gd','res://data/maps/luoyang_estate_courtyard_20261021am/rooms_registry.json'}
need(not set(targets)&excluded and all(p.endswith(('.gd','.json')) for p in targets),'NO_UNINTENDED_RUNTIME_NATIVE_OR_REGISTRY_TARGET')
for p,row in targets.items():
    need(sha(res(row['old_snapshot']))==row['old_sha256'] and sha(res(p))==row['old_sha256'],'CURRENT28_AND_FIXED_OLD_SNAPSHOT_EXACT')
backup_path=ROOT/'integration62/full28_backup_receipt.json';backup=obj(backup_path)
need(sha(backup_path)=='0481ff09ddacea8c78edb97644af365a8560dd69f4e89e00f9d1a63ece43c705','ROOT28_BACKUP_PIN')
need(backup['target_count']==28 and {r['res_path'] for r in backup['targets']}==set(targets),'ROOT_BACKUP_SCOPE_EXACT28')
for row in backup['targets']:
    need(row['old_sha256']==targets[row['res_path']]['old_sha256'] and sha(row['backup_path'])==row['old_sha256'],'ROOT_FULL_OLD_BACKUPS_EXACT')

env=proof['records']['res://scripts/city/luoyang_environment_layer_20261022ap.gd']
envcode=txt(res(env['candidate']['path']))
need(len(env['hunks'])==3 and envcode.count('for p: String in SCHOLAR_SOURCES:')==2,'ENV_SCHOLAR_ONLY2_SCOPED_SOURCE_LOOPS')
need('if id==&"ch4_s3_luoyang_market":\n\t\tout[MARKET_L_SHADER]=true\n\t\tfor p: String in EXAMINER_SOURCES: out[p]=true\n\t\tfor p: String in SCHOLAR_SOURCES: out[p]=true' in envcode,'SCHOLAR_PATHS_ONLY_MARKET')
need('if scene.scene_id==&"ch4_s3_luoyang_market":\n\t\tsource_pins[MARKET_L_SHADER]=MARKET_L_SHADER_SHA\n\t\tfor p: String in EXAMINER_SOURCES: source_pins[p]=EXAMINER_SOURCES[p]\n\t\tfor p: String in SCHOLAR_SOURCES: source_pins[p]=SCHOLAR_SOURCES[p]' in envcode,'SCHOLAR_HASH_BOTH_PASSES_ONLY_MARKET')
for p in (coord,temple):
    c=proof['records'][p];need('_UTF8_CANDIDATE.gd' in c['candidate']['path'],'ONLY_GOOD_UTF8_CANDIDATE')
    need(len(c['hunks'])==1 and len(raw(res(c['parent']['path'])))==len(raw(res(c['candidate']['path']))) if p==coord else True,'COORD_ONLY_EQUAL_LENGTH_LITERAL')

parse_path=ROOT/'integration62/parse_actual/3076_1731/result.json';parse=obj(parse_path)
need(sha(parse_path)=='d81f5d4bfb46cdbdf6913b3eee75873f75090cef2e718d3f57669eb1077c5b5d','ISSUED_PARSE_REPORT')
need(parse['complete'] and parse['checks']==18 and parse['failures']==0 and parse['source_before']==parse['source_after'] and parse['players_before']==parse['players_after'],'PARSE_LIMITED_SOURCES_SAVE15')
need(len(parse['records'])==7 and all(r['parsed'] and r['candidate_methods_executed']==0 and r['instance_created'] is False for r in parse['records']),'ONLY7_PARSED_NO_INSTANCES_METHODS')
stderr=txt(ROOT/'integration62/parse_seven_candidates_actual_stderr.log')
need(stderr.count('WARNING:')==1 and 'ERROR:' not in stderr and 'SCRIPT ERROR' not in stderr,'NONCLEAN_ONE_OBJECTDB_WARNING')
out={'status':'SOURCE100_EXACT28_CODE_DATA_EXECUTION_STATIC_REVIEW_NO_SCOPE_OR_INVERSE_BLOCKER_NOT_STAGE_AUTHORIZED',
 'scope_SHA':sha(scope_path),'execution_SHA':sha(new_path),'whole_proof_SHA':sha(proof_path),
 'counts':{'targets':28,'GD':14,'JSON':14,'owned':10,'old_pins':96,'new_pins':101},
 'whole_UTF8_code_and_data_forward_reverse':audits,'three_new_edges':edge_rows,
 'other7_owned_whole_rows_same':True,'old96pins_whole_values_same':True,'whole_execution_ordered_typed_and_serialized_UTF8_inverse':True,
 'contract_only_Field1value_and_rest_wholetyped_same':True,'temple_merged189_only3values_no_newkeys':True,
 'current28_fixedold_snapshots_and_Root_full_backups_exact':True,
 'ENV_only_helper_path_SHA_and_Market3_media_source_loops':True,
 'preserved':['C/AA/AC/DT/G/Router/execution membership and source-FIRST/FINAL unchanged','No original native scene/layout/packet/walk target or new geometry. Garden helper changes only shader/source list, two exact visual scales and11 local z overrides; originalbody install and37poses stay unchanged.','Root62 7code parse is only syntax/load evidence:18/0/1327ms, retained exit0, oneObjectDBwarning nonclean, not runtime/ART/Field permission.','First bad Coordinator/Temple files retained but not used by records, execution newpins or parse. Exact wholebyte inverse ensures original Chinese text/EOF outside literal replacement is preserved.'],
 'execution_limits':{'Stage':False,'engine_or_parse_by_QA':False,'collector':False,'packet_or_PNG_decode':False,'media_hash':False,'formal_write':False},
 'next_gate':'Final single driver/input/source-class DAG and independent output owner review still required; this review permits preparation only, not Stage or formal deployment.'}
print(json.dumps(out,ensure_ascii=False,indent=2))
