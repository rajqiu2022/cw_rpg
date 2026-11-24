"""One exact-pawn local-blocker Field hunk and necessary existing source pins; BUILD only."""
from pathlib import Path
import json,copy,hashlib,difflib
N=Path(__file__).resolve().parent;GAME=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'pawnshop_collision_repair01/'
PREFIX=P+'unified25_READY01/';OUT=N/'pawnshop_collision_repair01/unified25_READY01'
F='res://scripts/field/field_walkable_controller.gd';CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd'
CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
def pin(p,h):return dict(path=p,sha256=h)
def raw(p):
    b=(GAME/p['path'][6:]).read_bytes();assert sha(b)==p['sha256'],p
    if 'bytes'in p:assert len(b)==p['bytes']
    return b
def load(p):return json.loads(raw(p))
def exact(b,a,c):
    a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1,(a[:100],b.count(a));return b.replace(a,c,1)
def hunks(a,b):
    aa,bb=a.decode().splitlines(keepends=True),b.decode().splitlines(keepends=True);hs=[]
    for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
    f,v=a,b
    for h in hs:f=exact(f,h['old'],h['new'])
    for h in reversed(hs):v=exact(v,h['new'],h['old'])
    assert f==b and v==a;return hs
scopepin=pin(P+'current_9C1245_exact25_scope_PREPARATION.json','f1d6bfa254e836a901c3131010009328bf3e77931d7fe1bef53040f55c2b4304')
scope=load(scopepin);parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256'],bytes=r['old_bytes'])for r in scope['targets']}
oldpin=pin(S+'pawnshop_only_repair01/unified22_READY01/pawnshop22_all_candidates_and_inverse_NOT_STAGE.json','aceeb63c1217aa148b547fec737e9e2ae2d6da6ce5fb6993d7a7df028663eb74');oldbundle=load(oldpin)
prior31=load(pin(S+'Estate_wall_source_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','ccd21474dd1a99ef33b6a965da522190e4ad811f237bed3671430f5007cb7b54'))
stagepin=scope['parent_stage'];parentstage=load(stagepin);assert parentstage['source_first']==parentstage['source_final']
backuppin=pin(P+'current_9C1245_backup25_ROOT_ACTUAL.json','50fe87abfd647b11f7dacbc5863bc294ddde389579a2b1099958ca25b3c89bf0');backup=load(backuppin)
assert backup['total_backups']==539 and len(backup['new_backups'])==25 and backup['external_save_changes']==[]
# Preserve and classify the original backup report's stale absolute-path baseline, never overwrite it.
dep=load(scope['parent_deployment']);known={str((GAME/p['target'][6:]).resolve()).casefold():p for p in dep['targets']}
diff=backup['differences'];assert len(diff)==22 and {str(Path(x['path']).resolve()).casefold()for x in diff}==set(known)
classified=[]
for d in diff:
    r=known[str(Path(d['path']).resolve()).casefold()];current=d['current']
    assert current==dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks']),(d['path'],current,r)
    classified.append(dict(path=d['path'],current=current,authorized_target=r['target'],deployment=scope['parent_deployment'],classification='AUTHORIZED_EXACT9C1245_DEPLOYED22_ONLY_NOT_NEW_DRIFT'))
audit=enc(dict(status='FINITE_POST_BACKUP_CLASSIFICATION_ONLY_ORIGINAL_REPORT_PRESERVED',passed=True,backup=backuppin,parent_deployment=scope['parent_deployment'],authorized_differences=classified,authorized_count=22,other2099_no_difference_in_actual_report=True,no_observed_expected_fill=True,engine_calls=0,canonical_writes=0))
auditpath=N/'pawnshop_collision_repair01/backup_authorized22_difference_classification_READONLY.json';assert not auditpath.exists()
with auditpath.open('xb')as f:f.write(audit)
classification=pin(P+auditpath.name,sha(audit))
prepared={};records={};refs={};metadata={};indexes={};nodes={};additions={}
def out(name,b):
    assert name not in prepared;prepared[name]=b;return dict(path=PREFIX+name,sha256=sha(b),bytes=len(b))
def val(p):return prepared[p['path'][len(PREFIX):]]if p['path'].startswith(PREFIX)else raw(p)
def record(p,name,b):
    a=raw(parents[p]);assert b!=a;records[p]=dict(parent=parents[p],candidate=out(name,b),hunks=hunks(a,b),whole_byte_forward_inverse=True);refs[p]=records[p]['candidate']
function_proof=pin('res://build/luoyang_pawnshop_repair_20261026a_system01/Field_bodies01_direct_whole_inverse_BUILD.json','b7cac3e366462f107f954db58147fa89ec975157ef4e95654a63357d885b78f4');load(function_proof)
field=pin('res://build/luoyang_pawnshop_repair_20261026a_system01/Field_bodies01_CANDIDATE.gd','9504c55b9f0b664a35a24e830aeb5278152b3d8e732af42a3f17b8b762ebcde2')
record(F,'Field_READY.gd',raw(field));assert len(records[F]['hunks'])==1
a=raw(parents[CT]);v=json.loads(a);oldhash=v['source_sha256'][F];assert oldhash==parents[F]['sha256'];newhash=refs[F]['sha256'];v['source_sha256'][F]=newhash;b=exact(a,oldhash,newhash);assert json.loads(b)==v
contract=dict(parent=parents[CT],candidate=out('runtime_contract_READY.json',b),changes={F:dict(old=oldhash,new=newhash)},whole_typed_UTF8_inverse=True);refs[CT]=contract['candidate']
record(CO,'Coordinator_READY.gd',exact(raw(parents[CO]),parents[CT]['sha256'],refs[CT]['sha256']))
tbparent=prior31['temple_binding']['candidate'];a=raw(tbparent);v=json.loads(a);b=a;tc={}
for p,h in [(F,newhash),(CT,refs[CT]['sha256']),(CO,refs[CO]['sha256'])]:
    old=v['source_delta'][p];assert old==parents[p]['sha256'];v['source_delta'][p]=h;b=exact(b,json.dumps(p)+': '+json.dumps(old),json.dumps(p)+': '+json.dumps(h));tc[p]=dict(old=old,new=h)
assert json.loads(b)==v
tb=dict(parent=tbparent,candidate=out('Temple_binding_READY.json',b),changes=tc,whole_typed_UTF8_inverse=True)
b=exact(raw(parents[T]),tbparent['path'],tb['candidate']['path']);b=exact(b,tbparent['sha256'],tb['candidate']['sha256']);record(T,'Temple_READY.gd',b)
prior=load(parents[EX]);assert len(prior['owned'])==10 and len(prior['source_sha256'])==236;authority=copy.deepcopy(prior)
for p in [F,CO,T]:
    r=records[p];owner=authority['owned'][p];assert owner['current_sha256']==parents[p]['sha256']
    snap=next(e['new_snapshot']for e in reversed(owner['edges'])if e['new_sha256']==owner['current_sha256']);assert raw(pin(snap,owner['current_sha256']))==raw(parents[p])
    owner['edges'].append(dict(path=p,old_sha256=owner['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snap,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']));owner['current_sha256']=r['candidate']['sha256'];authority['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for p in [contract['candidate'],tb['candidate']]:authority['source_sha256'][p['path']]=p['sha256']
extra={p:h for p,h in authority['source_sha256'].items()if p not in prior['source_sha256']};assert len(extra)==5 and len(authority['source_sha256'])==241 and all(authority['source_sha256'][p]==h for p,h in prior['source_sha256'].items())
back=copy.deepcopy(authority)
for p in [F,CO,T]:back['owned'][p]=copy.deepcopy(prior['owned'][p])
back['source_sha256']=copy.deepcopy(prior['source_sha256']);assert enc(back)==raw(parents[EX])
refs[EX]=out('execution_successor_READY.json',enc(authority));execution=dict(parent=parents[EX],candidate=refs[EX],changed_existing_owned=[F,CO,T],extra=extra,old236_all_values_edges_retained=True,whole_typed_UTF8_inverse=True)
# Reuse the immediately reviewed exact22 metadata/index expression; only initial source additions differ.
source=(N/'prepare_pawnshop22_candidates_NOTENGINE.py').read_text(encoding='utf-8');start=source.index('def at(v,ptr):');end=source.index('descriptor=dict(',start);tail=source[start:end]
tail=tail.replace("    if EX in flat:added.update(extra)\n    if OLD_RUNTIME in flat:added.update(services)","    added.update(extra)")
tail=tail.replace("and len(records)==9 and len(metadata)==12","and len(records)==11 and len(metadata)==12")
tail=tail.replace("    if EX in ss:added.update(extra)\n    if OLD_RUNTIME in ss:added.update(services)","    added.update(extra)")
exec(compile(tail,'reviewed_pawn22_metadata_expression_with_Field_only_five_proofs','exec'),globals())
assert len(targets)==25
code=out('code_execution_all_whole_inverse_NOT_STAGE.json',enc(dict(status='PAWN_ONLY_LOCAL9BASE_BODY_FIELD_HUNK_AND_NECESSARY_PINS_NOT_STAGE',records={p:records[p]for p in [F,CO,T]},execution=execution,contract=contract,temple_binding=tb,Field_source_proof=function_proof,G_service_author_and_other_runtime_functions_unchanged=True,engine_calls=0,Stage_calls=0)))
descriptor=dict(status='CURRENT9C1245_PAWN_LOCAL_BODIES_EXACT25_PREPARED_NOT_STAGE',scope=scopepin,parent_stage=stagepin,parent_descriptor=oldpin,strict_parent_descriptor=pin(S+'Estate_wall_source_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','ccd21474dd1a99ef33b6a965da522190e4ad811f237bed3671430f5007cb7b54'),function_proof=function_proof,code_proof=code,execution=execution,contract=contract,temple_binding=tb,records=records,metadata=metadata,index_proofs=indexes,targets=targets,maps=maps,expected_family_maps=family,source_additions_by_metadata=additions,old_required_gates=oldbundle['old_required_gates'],authority_helper=oldbundle['authority_helper'],root_backup=backuppin,backup_authorized22_classification=classification,publication=oldbundle['publication'],partition=dict(GD=11,JSON=14,total=25),G_service_author_C_ENV_Router_Family_runtime_BIND_payloads_masks_media_unchanged=True,old_classification_all_source_keys_preserved=True,engine_calls=0,collector_calls=0,Stage_calls=0,canonical_writes=0)
dp=out('pawn_collision25_all_candidates_and_inverse_NOT_STAGE.json',enc(descriptor))
assert not OUT.exists();OUT.mkdir(parents=True)
for name,b in prepared.items():
    p=OUT/name;p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb')as f:f.write(b)
print(json.dumps(dict(descriptor=dp,Field=refs[F],Coordinator=refs[CO],Temple=refs[T],CT=refs[CT],Temple_binding=tb['candidate'],classification=classification,map_counts={k:r['count']for k,r in maps.items()},canonical_writes=0,Stage_calls=0)))
