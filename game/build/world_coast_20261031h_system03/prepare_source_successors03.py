"""NEW-only exact source-succession candidate author; NEVER applies old files.

--template emits a deny-by-default SourceExpected template, finite old target
list, and an unsealed C candidate. --seal requires Root's SHA of a completed
explicit SourceExpected, including exact Scene03 packaging, unchanged02 geometry, and ART/component assent.
No engine or real-save API is used. No current-disk blanket approval exists.
"""
from __future__ import annotations
import argparse, ast, copy, difflib, hashlib, json, re
from pathlib import Path

OWN=Path(__file__).resolve().parent
REPO=OWN.parents[2]
SYSTEM02='game/build/world_coast_20261031h_system02/'
PRIOR='game/build/luoyang_garden_city_minimap_20261030b_system01/residual04/closure_READY/receipt_READY.json'
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'
ROUTER='res://scripts/autoload/scene_router.gd'
FIELD='res://scripts/field/field_walkable_controller.gd'
REGION='res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
NATIVE='res://build/three_towns_world_20261029j_system01/native_sources.json'
REGISTRY='res://build/three_towns_world_20261029j_system01/town_registry.gd'
EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
EI='res://scripts/city/luoyang_execution_index_20261022ap.gd'
CANONICAL='res://data/scenes/world_map_jianghu.tres'
REFERENCE_LAYOUT='res://data/maps/world_map_jianghu_layout_v15.tres'
REFERENCE_LAYOUT_SHA='aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072'
SNAPSHOT_ROOT='res://build/luoyang_world_coast_20261031h_snapshot03/'
SNAPSHOTS={ROUTER:SNAPSHOT_ROOT+'scene_router.gd',FIELD:SNAPSHOT_ROOT+'field_walkable_controller.gd'}
ARTIFACTS={
 'scene':'res://build/world_coast_20261031h_system01/world_v16_scene03.tres',
 'layout':'res://build/world_coast_20261031h_system01/world_v16_layout02.tres',
 'stream':'res://build/world_coast_20261031h_system01/world_v16_stream02.tres',
 'manifest':'res://art/maps/world_coast_20261031h/candidate02/runtime_contract03.json',
 'dispatcher':'res://build/world_coast_20261031h_system02/world_contract_dispatch03.gd',
 'contract':'res://build/world_coast_20261031h_system02/world_v16_contract03.gd',
}
NEW_CODE=[ARTIFACTS['dispatcher'],ARTIFACTS['contract']]

def sha(data):return hashlib.sha256(data).hexdigest()
def disk(path):return REPO/('game/'+path[6:] if path.startswith('res://') else path)
def read(path):return disk(path).read_bytes()
def encode(value):return (json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
def resource(path):return 'res://'+path[5:] if path.startswith('game/') else path
def write_new(directory,name,data):
    target=directory/name;target.parent.mkdir(parents=True,exist_ok=True)
    if target.exists():
        if target.read_bytes()!=data:raise RuntimeError('PRESERVE_PREVIOUS_OUTPUT: '+str(target))
    else:target.write_bytes(data)

# Reuse only the previously accepted pure inverse helpers, never its historical
# top-level authoring action or a hardcoded predecessor command.
namespace={'hashlib':hashlib,'difflib':difflib,'json':json,'REPO':REPO}
tree=ast.parse(read('game/build/city_visual_diversity_20261031c/prepare_source_closure.py').decode('utf-8-sig'))
for node in tree.body:
    if isinstance(node,ast.FunctionDef) and node.name in ['sha','once','edit','hunks']:
        exec(compile(ast.Module(body=[node],type_ignores=[]),'<accepted pure whole-inverse helpers>','exec'),namespace)
edit=namespace['edit'];hunks=namespace['hunks']

def old_targets():
    old23=[resource(row['target']) for row in json.loads(read(PRIOR))['targets']]
    integration=json.loads(read(SYSTEM02+'prepared/receipt_REVIEW_ONLY.json'))
    old12=[resource(row['path']) for row in integration['targets']]
    targets=list(dict.fromkeys(old12+old23+[C,NATIVE,CANONICAL]))
    assert len(old12)==12 and len(old23)==23 and len(targets)==37
    return targets

def c_candidate(pins):
    original=read(C)
    template=(OWN/'C_v16_source_branch03.gd.in').read_text(encoding='utf-8')
    dictionary=json.dumps(pins,ensure_ascii=False,indent=1)
    helper=template.replace('__ROOT_APPROVED_PIN_DICTIONARY__',dictionary)
    eol='\r\n' if original.count(b'\r\n')==original.count(b'\n') else '\n'
    helper=helper.replace('\n',eol)
    marker='static func _fresh_source_portal_matches(source: StringName, target: StringName, normalized: Vector2, route: Dictionary) -> bool:'
    text=original.decode('utf-8')
    assert text.count(marker)==1
    # Two additions: one explicit original route alias and one exact source
    # branch. No local-version impersonation and no legacy-guard relaxation.
    route='\t"world_map_jianghu->ch4_s0_luoyang_gate": {"portal":"luoyang","uv":Vector2(.5,.9),"slot":"return_world","foot":Vector2(1536,1860),"reverse":false},'
    assert text.count(route)==1
    alias=route.replace('world_map_jianghu->','world_map_jianghu_v16->')
    text=text.replace(route,route+eol+alias,1)
    branch=(marker+eol+'\tif source==&"world_map_jianghu_v16" or (source==&"world_map_jianghu" and FileAccess.get_sha256(FRESH_WORLD_V16_CANONICAL)==FRESH_WORLD_V16_PINS.get(FRESH_WORLD_V16_CANONICAL,"")):'+eol+'\t\treturn _fresh_world_v16_portal_matches(source,target,normalized,route)')
    text=text.replace(marker,helper+eol+branch,1)
    # Closed, explicitly approved proof keys join C's existing complete first /
    # final map. The bundle manifest candidates append these exact same keys.
    collector='static func _transition_sources(scene: SceneScript, hash_files: bool = true) -> Dictionary:'
    start=text.index(collector);needle='\tvar paths: Dictionary = {}'
    at=text.index(needle,start)
    addition=needle+eol+'\tif FileAccess.get_sha256(FRESH_WORLD_V16_CANONICAL)==FRESH_WORLD_V16_PINS.get(FRESH_WORLD_V16_CANONICAL,""):'+eol+'\t\tvar world16_proofs: Dictionary=_world_v16_source_paths()'+eol+'\t\tif world16_proofs.is_empty():return {}'+eol+'\t\tpaths.merge(world16_proofs)'
    text=text[:at]+text[at:].replace(needle,addition,1)
    result=text.encode('utf-8')
    assert namespace['edit'](original,[(x['old'],x['new']) for x in hunks(original,result)])==result
    return result

def template():
    out=OWN/'template03'
    targets=old_targets()
    before={p:sha(read(p)) for p in targets}
    artifact_pins={path:None for path in ARTIFACTS.values()}
    expected={
      'status':'ROOT_APPROVAL_REQUIRED_NOT_READY','approved_by':None,
      'scope':'WORLD_COAST_20261031H_EXACT_V16_SOURCE_SUCCESSION',
      'art02_approved':False,'full_resolution_component02_passed':False,
      'integration_receipt':SYSTEM02+'prepared03/receipt_REVIEW_ONLY.json',
      'integration_receipt_sha256':None,'old_sources':before,
      'new_artifact_sha256':artifact_pins,'canonical_candidate_sha256':None,
      'approved_new_code_keys':NEW_CODE,
      'snapshot_paths':SNAPSHOTS,
      'notes':['Only Root may fill actual reviewed SHA values and mark ready.','No actual collector result is implied by this source-candidate generator.','All actual old source bytes must still match this exact finite list before seal.']}
    write_new(out,'SourceExpected_TEMPLATE.json',encode(expected))
    write_new(out,'finite_old_targets.json',encode({'count':len(targets),'paths':targets,'formal_apply_authorized':False}))
    deny={p:'ROOT_APPROVAL_REQUIRED' for p in list(ARTIFACTS.values())+[CANONICAL]}
    write_new(out,'C_template_REVIEW_ONLY03.gd',c_candidate(deny))
    print(json.dumps({'status':'TEMPLATE_ONLY_DENY_PINS','old_target_count':len(targets),'out':str(out)}))

def active_map(raw,field):
    # Locate a TOP-LEVEL member by JSON token boundaries, never a same-named
    # historical map embedded in parent_publication or an inverse-hunk string.
    text=raw.decode('utf-8');decoder=json.JSONDecoder();at=text.index('{')+1
    while True:
        while text[at].isspace() or text[at]==',':at+=1
        if text[at]=='}':return None
        key,used=decoder.raw_decode(text[at:]);at+=used
        while text[at].isspace():at+=1
        assert text[at]==':';at+=1
        while text[at].isspace():at+=1
        start=at;current,used=decoder.raw_decode(text[at:]);at+=used
        if key==field:
            assert isinstance(current,dict)
            return text,start,at,current

def map_update(raw,field,known,old_sha,additions=None):
    part=active_map(raw,field)
    if part is None:return raw
    text,start,end,current=part;segment=text[start:end];expected=copy.deepcopy(current)
    for path,new_sha in known.items():
        if path not in current or current[path]==new_sha:continue
        if current[path]!=old_sha.get(path):continue # Immutable older headers stay older.
        old=json.dumps(path)+': '+json.dumps(current[path]);new=json.dumps(path)+': '+json.dumps(new_sha)
        assert segment.count(old)==1,(field,path)
        segment=segment.replace(old,new,1);expected[path]=new_sha
    for path,digest in sorted((additions or {}).items()):
        if path in expected:
            assert expected[path]==digest,(field,'CONFLICTING_EXISTING_KEY',path)
            continue
        trimmed=segment[:-1].rstrip()
        segment=trimmed+(',' if expected else '')+'\n    '+json.dumps(path)+': '+json.dumps(digest)+'\n  }'
        expected[path]=digest
    result=(text[:start]+segment+text[end:]).encode('utf-8')
    parsed=json.loads(result)
    assert parsed[field]==expected
    assert {k:v for k,v in parsed.items() if k!=field}=={k:v for k,v in json.loads(raw).items() if k!=field}
    return result

def whole_diff(before,after,path):
    rows=list(difflib.unified_diff(before.decode().splitlines(),after.decode().splitlines(),n=3,lineterm=''))
    return '*** Update File: game/'+path[6:]+'\n'+''.join(('@@' if x.startswith('@@') else x)+'\n' for x in rows[2:])

def seal(path,approval_sha):
    source=Path(path).resolve();assert source.is_relative_to(OWN)
    raw=source.read_bytes();assert len(approval_sha)==64 and sha(raw)==approval_sha
    expected=json.loads(raw)
    assert expected['status']=='ROOT_APPROVED_EXACT_CANDIDATE_INPUTS' and expected['approved_by']=='root'
    assert expected['art02_approved'] is True and expected['full_resolution_component02_passed'] is True
    targets=old_targets();assert set(expected['old_sources'])==set(targets)
    before={p:read(p) for p in targets};old_sha={p:sha(b) for p,b in before.items()}
    assert old_sha==expected['old_sources']
    assert expected['approved_new_code_keys']==NEW_CODE and expected['snapshot_paths']==SNAPSHOTS
    assert set(expected['new_artifact_sha256'])==set(ARTIFACTS.values())
    new_pins=expected['new_artifact_sha256']
    for p,h in new_pins.items():assert isinstance(h,str) and len(h)==64 and sha(read(p))==h
    assert sha(read(REFERENCE_LAYOUT))==REFERENCE_LAYOUT_SHA
    contract_text=read(ARTIFACTS['contract']).decode('utf-8')
    sealed_manifest=re.search(r'^const MANIFEST_SHA := "([a-f0-9]{64})"$',contract_text,re.MULTILINE)
    assert sealed_manifest and sealed_manifest.group(1)==new_pins[ARTIFACTS['manifest']],'ACTUAL03_PACKAGING_MANIFEST_MUST_BE_ROOT_PINNED_FIRST'
    assert 'system02/world_v16_contract03.gd' in read(ARTIFACTS['dispatcher']).decode('utf-8')
    integration_path=expected['integration_receipt']
    assert integration_path==SYSTEM02+'prepared03/receipt_REVIEW_ONLY.json'
    assert sha(read(integration_path))==expected['integration_receipt_sha256']
    integration=json.loads(read(integration_path));assert len(integration['targets'])==12
    after={}
    for row in integration['targets']:
        p=resource(row['path']);assert p in before and row['before_sha256']==old_sha[p]
        data=read(SYSTEM02+'prepared03/copies/'+row['path'])
        assert sha(data)==row['candidate_sha256'];after[p]=data
    scene=read(ARTIFACTS['scene'])
    source_id=b'scene_id = &"world_map_jianghu_v16"';target_id=b'scene_id = &"world_map_jianghu"'
    assert scene.count(source_id)==1
    canonical=scene.replace(source_id,target_id,1)
    assert sha(canonical)==expected['canonical_candidate_sha256']
    after[CANONICAL]=canonical
    world_pins=dict(new_pins);world_pins[CANONICAL]=sha(canonical)
    after[C]=c_candidate(world_pins)
    native=json.loads(before[NATIVE]);assert len(native['sources'])==226
    native_changes=[FIELD,'res://build/sect_repair_20261031c_system01/adoption_contract.gd','res://build/sect_repair_20261031c_system01/router_entry.gd']
    for p in native_changes:assert native['sources'].get(p)==old_sha[p]
    after[NATIVE]=map_update(before[NATIVE],'sources',{p:sha(after[p]) for p in native_changes},old_sha,{p:new_pins[p] for p in NEW_CODE})
    old_native_sha=old_sha[NATIVE]
    assert after[REGISTRY].count(old_native_sha.encode())==1
    after[REGISTRY]=after[REGISTRY].replace(old_native_sha.encode(),sha(after[NATIVE]).encode(),1)
    region=json.loads(before[REGION]);assert len(region['runtime_modules'])==567
    region_changes=['res://scripts/autoload/save_manager.gd','res://scripts/ui/world_map_panel.gd','res://scripts/ui/world_travel_minimap.gd']
    after[REGION]=map_update(before[REGION],'runtime_modules',{p:sha(after[p]) for p in region_changes},old_sha,{p:new_pins[p] for p in NEW_CODE})
    header=b'const REGION27D_AUTHOR_SHA := "'+old_sha[REGION].encode()+b'"'
    assert after[ROUTER].count(header)==1
    after[ROUTER]=after[ROUTER].replace(header,b'const REGION27D_AUTHOR_SHA := "'+sha(after[REGION]).encode()+b'"',1)
    ex=json.loads(before[EX]);next_ex=copy.deepcopy(ex)
    snapshot_pins={}
    for p in [ROUTER,FIELD]:
        row=next_ex['owned'][p];assert row['current_sha256']==old_sha[p]
        previous=row['edges'][-1]['new_snapshot'];assert read(previous)==before[p]
        snapshot=SNAPSHOTS[p];assert snapshot not in ex['source_sha256'] and not disk(snapshot).exists()
        row['current_sha256']=sha(after[p])
        replacements=hunks(before[p],after[p])
        inverse=after[p].decode('utf-8')
        for replacement in replacements:
            assert inverse.count(replacement['new'])==1
            inverse=inverse.replace(replacement['new'],replacement['old'],1)
        assert inverse.encode('utf-8')==before[p],'AUTHORITY_ORDERED_WHOLE_INVERSE'
        row['edges'].append({'path':p,'old_sha256':old_sha[p],'new_sha256':sha(after[p]),'old_snapshot':previous,'new_snapshot':snapshot,'whole_inverse':True,'replacements':replacements})
        assert row['edges'][:-1]==ex['owned'][p]['edges']
        snapshot_pins[snapshot]=sha(after[p])
    # Preserve EX JSON bytes outside the two exact owned rows and its source map.
    ex_bytes=before[EX]
    text=ex_bytes.decode('utf-8')
    for p in [ROUTER,FIELD]:
        marker='    '+json.dumps(p)+': ';start=text.index(marker)+len(marker)
        _,used=json.JSONDecoder().raw_decode(text[start:])
        row_text=json.dumps(next_ex['owned'][p],ensure_ascii=False,indent=2).replace('\n','\n    ')
        text=text[:start]+row_text+text[start+used:]
    after[EX]=map_update(text.encode(),'source_sha256',{},old_sha,{**snapshot_pins,**{p:new_pins[p] for p in NEW_CODE}})
    assert json.loads(after[EX])['owned']==next_ex['owned']
    assert before[EI].count(old_sha[EX].encode())==1
    after[EI]=before[EI].replace(old_sha[EX].encode(),sha(after[EX]).encode(),1)
    known={p:sha(b) for p,b in after.items()}
    pending=[p for p in targets if p not in after]
    for _ in targets:
        progress=False
        for p in list(pending):
            dependencies={q for q,h in old_sha.items() if q!=p and h.encode() in before[p]}
            if dependencies.intersection(pending):continue
            data=before[p]
            if p.endswith('.json'):
                for field in ['source_sha256','legacy_source_sha256']:
                    additions=world_pins|snapshot_pins|{REFERENCE_LAYOUT:REFERENCE_LAYOUT_SHA} if field=='legacy_source_sha256' and active_map(data,field) is not None else None
                    data=map_update(data,field,known,old_sha,additions)
            else:
                pairs=[(old_sha[q],known[q]) for q in known if q in old_sha and known[q]!=old_sha[q] and old_sha[q].encode() in data]
                data=edit(data,pairs)
            assert data!=before[p],('UNNECESSARY_OR_UNRESOLVED_TARGET',p)
            after[p]=data;known[p]=sha(data);pending.remove(p);progress=True
        if not pending:break
        assert progress,('SOURCE_PIN_CYCLE_OR_MISSING_ORDER',pending)
    assert not pending and set(after)==set(targets)
    out=OWN/'sealed_candidate03'
    assert not out.exists(),'NO_OVERWRITE_SEALED_CANDIDATE'
    records=[]
    for p in targets:
        candidate='copies/game/'+p[6:]
        write_new(out,candidate,after[p]);write_new(out,'before/game/'+p[6:],before[p])
        records.append({'path':'game/'+p[6:],'before_sha256':old_sha[p],'candidate_sha256':sha(after[p]),'before_bytes':len(before[p]),'candidate_bytes':len(after[p])})
    for p,snapshot in SNAPSHOTS.items():write_new(out,'new_snapshots/game/'+snapshot[6:],after[p])
    forward='*** Begin Patch\n'+''.join(whole_diff(before[p],after[p],p) for p in targets)+'*** End Patch\n'
    write_new(out,'SOURCE_SUCCESSORS_REVIEW_ONLY.patch',forward.encode())
    record={'status':'ROOT_REVIEW_ONLY_NOT_APPLIED_NOT_ACTUAL_COLLECTOR','source_expected_sha256':approval_sha,'target_count':len(records),'targets':records,'new_snapshot_pins':snapshot_pins,'new_code_pins':{p:new_pins[p] for p in NEW_CODE},'explicit_world_proof_pins':world_pins,'native_sources_before':226,'native_sources_after':len(json.loads(after[NATIVE])['sources']),'region_modules_before':567,'region_modules_after':len(json.loads(after[REGION])['runtime_modules']),'EX_old_keys_preserved':True,'EX_old_edges_preserved':True,'EX_new_edges':2,'patch_sha256':sha(forward.encode()),'actual_C_collector_B_describe_pending':True,'engine_runs':0,'canonical_writes':0,'real_save_API_calls':0}
    write_new(out,'receipt_REVIEW_ONLY.json',encode(record))
    print(json.dumps({'status':record['status'],'target_count':len(records),'out':str(out),'patch_sha256':sha(forward.encode())}))

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--template',action='store_true')
    group.add_argument('--seal',metavar='ROOT_SOURCE_EXPECTED_JSON')
    parser.add_argument('--approved-expectation-sha',default='')
    args=parser.parse_args()
    if args.template:template()
    else:seal(args.seal,args.approved_expectation_sha)

