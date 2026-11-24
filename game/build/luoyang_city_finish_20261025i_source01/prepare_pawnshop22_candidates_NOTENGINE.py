"""Approved pawn-only exact22 metadata successor. No Stage/engine/collector/canonical write."""
from pathlib import Path
import json,copy,hashlib,difflib,argparse,base64

N=Path(__file__).resolve().parent;GAME=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'pawnshop_only_repair01/'
OUT=N/'pawnshop_only_repair01/unified22_READY01';PREFIX=P+'unified22_READY01/'
SYS='res://build/luoyang_pawnshop_repair_20261026a_system01/'
G='res://scripts/city/luoyang_assembled_interiors_20261016g.gd'
EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
OLD_RUNTIME='res://build/luoyang_indoor_services_20261025h_system01/runtime_READY02/services_runtime_READY.gd'
AUTH=SYS+'services_author02_CANDIDATE.json'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
def raw(pin):
    b=(GAME/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'],pin
    if 'bytes'in pin:assert len(b)==pin['bytes']
    return b
def load(pin):return json.loads(raw(pin))
def pin(path,h):return dict(path=path,sha256=h)
def exact(b,a,c):
    a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1,(a[:100],b.count(a));return b.replace(a,c,1)
def hunks(a,b):
    aa,bb=a.decode('utf-8').splitlines(keepends=True),b.decode('utf-8').splitlines(keepends=True);hs=[]
    for group in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):
        hs.append(dict(old=''.join(aa[group[0][1]:group[-1][2]]),new=''.join(bb[group[0][3]:group[-1][4]])))
    f,v=a,b
    for h in hs:f=exact(f,h['old'],h['new'])
    for h in reversed(hs):v=exact(v,h['new'],h['old'])
    assert f==b and v==a;return hs
ap=argparse.ArgumentParser();ap.add_argument('--root-approved-mechanical-ready',action='store_true');args=ap.parse_args()
assert args.root_approved_mechanical_ready,'ROOT_MUST_REVIEW_THREE_FUNCTIONAL_CANDIDATES_FIRST'
scopepin=pin(P+'current_47CC_exact22_scope_PREPARATION.json','85d08f7c5f95a14c725abc0ec6d0d008c3b56f6bf17269dd2658f70d8289a026')
scope=load(scopepin);parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256'],bytes=r['old_bytes']) for r in scope['targets']}
assert len(parents)==22
oldpin=pin(S+'Estate_wall_source_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','ccd21474dd1a99ef33b6a965da522190e4ad811f237bed3671430f5007cb7b54')
oldbundle=load(oldpin)
stagepin=pin(S+'outputs/root_Estate_wall_source_exact31_stage01/receipt.json','bcf570aaf4da648b17612a2d8dd889cffafc8962ec0422313b9689972ed53f39')
parentstage=load(stagepin);assert parentstage['source_first']==parentstage['source_final']
backuppin=pin(P+'current_47CC_backup22_ROOT_ACTUAL.json','75637d956c0d040af9b57fb6374d2b78a8b46b334fcc892c1405de57a1652639')
backup=load(backuppin);assert len(backup['new_backups'])==22 and backup['total_backups']==514 and backup['external_save_changes']==[]
function_proof=pin(SYS+'three_files_direct_parent_whole_inverse_BUILD.json','a262558b30f63958d722ffc08303d942c67c07a5cbfb1a7ab820939f783122e5')
fp=load(function_proof)
for r in fp['files']:
    before=(GAME.parent/r['parent']).read_bytes();after=(GAME.parent/r['candidate']).read_bytes()
    assert sha(before)==r['parent_sha256'] and sha(after)==r['candidate_sha256']
    f=before
    for h in reversed(r['hunks']):
        a,b=base64.b64decode(h['before_base64']),base64.b64decode(h['after_base64'])
        assert f[h['old_offset']:h['old_offset']+len(a)]==a
        f=f[:h['old_offset']]+b+f[h['old_offset']+len(a):]
    assert f==after
    b=after
    for h in reversed(r['hunks']):
        a,c=base64.b64decode(h['before_base64']),base64.b64decode(h['after_base64'])
        assert b[h['new_offset']:h['new_offset']+len(c)]==c
        b=b[:h['new_offset']]+a+b[h['new_offset']+len(c):]
    assert b==before
prepared={};records={};refs={};metadata={};indexes={};nodes={};additions={}
def out(name,b):
    assert name not in prepared;prepared[name]=b
    return dict(path=PREFIX+name,sha256=sha(b),bytes=len(b))
def val(p):return prepared[p['path'][len(PREFIX):]] if p['path'].startswith(PREFIX) else raw(p)
service_parent=pin(SYS+'services02_CANDIDATE.gd','7ce5f198560576f0ef2df35dbd80c00291637b30dde0110bfcb6b6356db0953c')
service_raw=raw(service_parent);service_path=PREFIX+'services_runtime_READY.gd'
service_new=exact(service_raw,'const FORMAL_READY := false','const FORMAL_READY := true')
service_new=exact(service_new,SYS+'services02_CANDIDATE.gd',service_path)
service=out('services_runtime_READY.gd',service_new)
author=pin(AUTH,'44053da474186c16863df81e6c266d21e0815c1af2e6d8d4b1a78d0effe1db1e');raw(author)
g_parent=pin(SYS+'G_pawn03_CANDIDATE.gd','41cb14ddfb7b2e8ad20427faab11b8b79bdf5bb1add0170871dc4ddfbcde713b')
g_new=exact(raw(g_parent),SYS+'services02_CANDIDATE.gd',service_path)
g_new=exact(g_new,service_parent['sha256'],service['sha256']);g=out('G_READY.gd',g_new)
records[G]=dict(parent=parents[G],candidate=g,hunks=hunks(raw(parents[G]),g_new),whole_byte_forward_inverse=True)
refs[G]=g
seal=out('mechanical_service_G_seal_whole_inverse_READY.json',enc(dict(function_proof=function_proof,service_parent=service_parent,service=service,service_hunks=hunks(service_raw,service_new),G_parent=g_parent,G=g,G_hunks=hunks(raw(g_parent),g_new),author=author,functions_unchanged_from_reviewed_candidates=True,only_service_READY_SELF_and_G_path_SHA=True,canonical_writes=0,engine_calls=0)))
prior=json.loads(raw(parents[EX]));authority=copy.deepcopy(prior)
assert len(prior['owned'])==10 and len(prior['source_sha256'])==235
row=authority['owned'][G];assert row['current_sha256']==parents[G]['sha256']
edge=dict(path=G,old_sha256=row['current_sha256'],new_sha256=g['sha256'],old_snapshot=parents[G]['path'],new_snapshot=g['path'],whole_inverse=True,replacements=records[G]['hunks'])
row['current_sha256']=g['sha256'];row['edges'].append(edge)
extra={g['path']:g['sha256']};assert g['path']not in authority['source_sha256'];authority['source_sha256'].update(extra)
back=copy.deepcopy(authority);back['owned'][G]=copy.deepcopy(prior['owned'][G]);back['source_sha256']=copy.deepcopy(prior['source_sha256']);assert back==prior and enc(back)==raw(parents[EX])
ex=out('execution_successor_READY.json',enc(authority));refs[EX]=ex
execution=dict(parent=parents[EX],candidate=ex,changed_existing_owned=[G],extra=extra,old235_all_values_edges_preserved=True,whole_typed_UTF8_inverse=True)
services={service['path']:service['sha256'],author['path']:author['sha256']}
def at(v,ptr):
    for k in ptr:v=v[k]
    return v
def setvalue(v,ptr,value,changes):
    d=at(v,ptr[:-1]);k=ptr[-1];exists=k in d;old=copy.deepcopy(d.get(k))
    if exists and old==value:return
    changes.append(dict(pointer=ptr,existed=exists,old=old,new=value));d[k]=value
def restore(v,changes):
    b=copy.deepcopy(v)
    for c in reversed(changes):
        d=at(b,c['pointer'][:-1]);k=c['pointer'][-1]
        if c['existed']:d[k]=c['old']
        else:del d[k]
    return b
byid={v['id']:(p,v) for p,v in oldbundle['metadata'].items()}
def meta(ident):
    p,t=byid[ident];before=raw(parents[p]);old=json.loads(before);assert enc(old)==before
    v=copy.deepcopy(old);changes=[];fields=t['source_fields'];flat={k:h for f in fields for k,h in at(v,f).items()}
    assert len(flat)==sum(len(at(v,f))for f in fields)
    for f in fields:
        for k,h in list(at(v,f).items()):
            if k in refs:
                assert h==parents[k]['sha256'],(ident,k,h,parents[k]['sha256'])
                setvalue(v,f+[k],refs[k]['sha256'],changes)
    added={}
    if EX in flat:added.update(extra)
    if OLD_RUNTIME in flat:added.update(services)
    default=t['source_bundle'].get('default_destination',fields[0]) if t.get('source_bundle') else fields[0]
    for k,h in added.items():
        assert k not in flat and k not in t.get('forbidden_sources',[])
        setvalue(v,default+[k],h,changes)
    for f in t['protected_pointers']:assert at(v,f)==at(old,f)
    assert restore(v,changes)==old and enc(restore(v,changes))==before
    candidate=out('metadata/'+ident+'.json',enc(v));assert candidate['sha256']!=parents[p]['sha256']
    refs[p]=candidate;nodes[ident]=candidate;additions[ident]=added
    metadata[p]=dict(id=ident,parent=parents[p],candidate=candidate,changes=changes,source_fields=fields,source_bundle=t.get('source_bundle'),protected_pointers=t['protected_pointers'],forbidden_sources=t['forbidden_sources'],explicit_new_ordinary=added,whole_typed_UTF8_inverse=True)
def index(ident):
    p,t=next((p,t)for p,t in oldbundle['index_proofs'].items()if t['id']==ident)
    before=raw(parents[p]);b=before;changes=[]
    for target,candidate in refs.items():
        old=parents[target]['sha256'];new=candidate['sha256']
        if old.encode()in b:
            b=exact(b,old,new);changes.append(dict(old=old,new=new,target=target))
    assert b!=before and b.count(t['enabled_literal'].encode())==1 and t['disabled_literal'].encode()not in b
    off=out('indexes/'+ident+'_disabled.gd',exact(b,t['enabled_literal'],t['disabled_literal']))
    candidate=out('indexes/'+ident+'.gd',b);refs[p]=candidate;nodes[ident]=candidate
    records[p]=dict(parent=parents[p],candidate=candidate,hunks=hunks(before,b),whole_byte_forward_inverse=True)
    indexes[p]=dict(id=ident,disabled=off,disabled_literal=t['disabled_literal'],enabled_literal=t['enabled_literal'],replacements=changes,only_disabled_bool_transition=True)
meta('estate_final')
for i in range(2,9):meta('legacy_manifest_'+str(i))
for ident in ['legacy_index_0','legacy_index_1','legacy_index_2','legacy_index_3','legacy_index_4','ap_execution_index']:index(ident)
meta('quarter_final');index('ap_quarter_index')
for ident in ['market_final','finite08_market','finite08_yamen']:meta(ident)
index('ap_city_index')
assert set(refs)==set(parents) and len(records)==9 and len(metadata)==12
maps={}
for ident,r in parentstage['nodes'].items():
    if not ident.startswith('expected_ch4_'):continue
    old=load({k:r[k]for k in ['path','sha256']});assert old==r['value'];v=copy.deepcopy(old);ss=v['source_sha256'];added={}
    for p,c in refs.items():
        if p in ss:assert ss[p]==parents[p]['sha256'];ss[p]=c['sha256']
    if EX in ss:added.update(extra)
    if OLD_RUNTIME in ss:added.update(services)
    for p,h in added.items():assert p not in ss;ss[p]=h
    c=out('maps/'+v['scene_id']+'_true.json',enc(v));maps[ident]=dict(parent={k:r[k]for k in ['path','sha256']},candidate=c,count=len(ss),value=v,explicit_additions=added)
family={}
for name,ident in [('expected_Family_sources','quarter_final'),('expected_Estate_sources','estate_final')]:
    family[name]=out('maps/'+name+'.json',enc(dict(status='SOURCE_DERIVED_CURRENT_FAMILY_MAP_NOT_OBSERVATION',source_sha256=json.loads(val(nodes[ident]))['source_sha256'])))
targets=[dict(target=p,parent=parents[p],candidate=refs[p],kind='GD'if p.endswith('.gd')else'JSON')for p in parents]
descriptor=dict(status='PAWNSHOP_ONLY_EXACT22_PREPARED_NOT_STAGE',scope=scopepin,parent_stage=stagepin,parent_descriptor=oldpin,function_proof=function_proof,seal=seal,execution=execution,records=records,metadata=metadata,index_proofs=indexes,targets=targets,maps=maps,expected_family_maps=family,source_additions_by_metadata=additions,service_flat2=services,ordinary=[service,author],old_required_gates=oldbundle['old_required_gates'],authority_helper=oldbundle['authority_helper'],root_backup=backuppin,publication=oldbundle['publication'],partition=dict(GD=9,JSON=13,total=22),CT_Coord_Temple_C_Field_ENV_Router_Family_runtime_BIND_payloads_masks_media_unchanged=True,old_classification_all_source_keys_preserved=True,engine_calls=0,collector_calls=0,Stage_calls=0,canonical_writes=0)
dp=out('pawnshop22_all_candidates_and_inverse_NOT_STAGE.json',enc(descriptor))
assert not OUT.exists();OUT.mkdir(parents=True)
for name,b in prepared.items():
    dest=OUT/name;dest.parent.mkdir(parents=True,exist_ok=True)
    with dest.open('xb')as f:f.write(b)
print(json.dumps(dict(descriptor=dp,service=service,G=g,seal=seal,map_counts={k:r['count']for k,r in maps.items()},new_by_metadata={k:len(v)for k,v in additions.items()},canonical_writes=0,Stage_calls=0)))
