"""Fixed-parent metadata-only closure of an already-admitted Yamen import tuple."""
from pathlib import Path
import json, hashlib, copy, difflib, re

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261024e_source01/'
OUT=HERE/'wall_tuple3_candidate01'
def sha(b): return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=(GAME/p[6:]).read_bytes(); assert sha(b)==h.lower(),p
    return b
def enc(v): return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def put(name,b):
    p=OUT/name
    with p.open('xb') as f:f.write(b)
    return dict(path=S+'wall_tuple3_candidate01/'+name,sha256=sha(b),bytes=len(b))
def patch(a,b):
    aa=a.decode('utf8').splitlines(keepends=True);bb=b.decode('utf8').splitlines(keepends=True);ds=[]
    for tag,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
        if tag!='equal':ds.append(dict(old_offset=len(''.join(aa[:i]).encode()),new_offset=len(''.join(bb[:k]).encode()),old=''.join(aa[i:j]),new=''.join(bb[k:l])))
    forward=a;inverse=b
    for d in reversed(ds):
        i=d['old_offset'];x,y=d['old'].encode(),d['new'].encode();assert forward[i:i+len(x)]==x;forward=forward[:i]+y+forward[i+len(x):]
        i=d['new_offset'];assert inverse[i:i+len(y)]==y;inverse=inverse[:i]+x+inverse[i+len(y):]
    assert forward==b and inverse==a
    return ds

stagepath=S+'outputs/root_market_blocks_prewarm_exact33_stage03/receipt.json'
stagesha='ea657a57c4a884cd3f645b6de7f8fb2010c8920b737b2ab6b9f3c998288c2abc'
stage=json.loads(read(stagepath,stagesha))
parentpath='res://build/luoyang_city_revision_20261024c_source01/outputs/root_courts_scholar_exact30_stage03/receipt.json'
parentsha='99a719091627f5b6cbc015aa7c4281d42f01b1786a5a9f4cafe3becc55cc51ce'
parent=json.loads(read(parentpath,parentsha))
ip='res://art/maps/luoyang_enclosure_v11/ch4_s1_luoyang_yamen/entities/v11_yamen_west_north_940.png.import'
ct='res://.godot/imported/v11_yamen_west_north_940.png-996d166b20dd3bd294a4dd3b4367f828.ctex'
leaves={ip:'d35c5b4d70abfb077df058a71a8013e93b6105d1aed3d221ed519c22ee23fcb8',ct:'c8ccbf33c1d222bf07a24c914a6a1291bb59db460cc7af3ca88bd07a5b6c6eaf'}
for source in [stage,parent]:
    y=source['nodes']['expected_ch4_s1_luoyang_yamen_true']['value']['source_sha256']
    assert all(y.get(p)==h for p,h in leaves.items())
assert not OUT.exists();OUT.mkdir()
bytarget={r['candidate_path']:r for r in stage['targets']}
records={}; header_replacements={}
for ident,name in [('market_final','APMarket_manifest_CANDIDATE.json'),('finite08_market','finiteMarket_manifest_CANDIDATE.json')]:
    node=stage['nodes'][ident];old=read(node['path'],node['sha256']);v=json.loads(old);assert enc(v)==old
    for p in leaves: assert p not in v['legacy_source_sha256'] and p not in v['runtime_authority_sha256']
    new=copy.deepcopy(v);new['legacy_source_sha256'].update(leaves)
    inverse=copy.deepcopy(new)
    for p in leaves:del inverse['legacy_source_sha256'][p]
    assert inverse==v and enc(inverse)==old
    raw=enc(new);c=put(name,raw);row=bytarget[node['path']]
    records[ident]=dict(target=row['target'],parent=dict(path=node['path'],sha256=node['sha256'],bytes=len(old)),candidate=c,byte_patch=patch(old,raw),whole_typed_inverse=True,whole_ordered_UTF8_inverse=True,sole_pointer=['legacy_source_sha256'],exact_added_source_sha256=leaves)
    header_replacements[row['target']]=c['sha256']
node=stage['nodes']['ap_city_index'];old=read(node['path'],node['sha256']);raw=old
for ident in ['market_final','finite08_market']:
    before=records[ident]['parent']['sha256'].encode();after=records[ident]['candidate']['sha256'].encode()
    assert raw.count(before)==1;raw=raw.replace(before,after)
c=put('APCityIndex_CANDIDATE.gd',raw);row=bytarget[node['path']]
records['ap_city_index']=dict(target=row['target'],parent=dict(path=node['path'],sha256=node['sha256'],bytes=len(old)),candidate=c,byte_patch=patch(old,raw),whole_byte_inverse=True,sole_two_manifest_SHA_literals=True)
header_replacements[row['target']]=c['sha256']
maps={}
for ident,node in stage['nodes'].items():
    if not ident.startswith('expected_'):continue
    old=node['value'];new=copy.deepcopy(old);sources=new['source_sha256'];before=copy.deepcopy(sources)
    changed={}
    for p,h in header_replacements.items():
        if p in sources:changed[p]=dict(old=sources[p],new=h);sources[p]=h
    added={}
    if ident=='expected_ch4_s3_luoyang_market_true':
        assert len(before)==1851 and all(p not in sources for p in leaves);sources.update(leaves);added=leaves
    inverse=copy.deepcopy(new)
    for p in added:del inverse['source_sha256'][p]
    for p,d in changed.items():inverse['source_sha256'][p]=d['old']
    assert inverse==old and enc(inverse)==enc(old)
    record=put(ident+'.json',enc(new));maps[ident]=dict(**record,count=len(sources),changed_existing_headers=changed,added_source_sha256=added,all_other_key_values_unchanged=True,whole_typed_ordered_UTF8_inverse=True)
# Exact C import expansion has no extension filter. Read only tiny sidecar text.
market=json.loads(read(maps['expected_ch4_s3_luoyang_market_true']['path'],maps['expected_ch4_s3_luoyang_market_true']['sha256']))['source_sha256']
expanded=set(market);sidecars=0
for p in list(market):
    physical=GAME/(p[6:]+'.import')
    if not physical.is_file():continue
    sidecars+=1;expanded.add(p+'.import')
    expanded.update(re.findall(r'^path(?:\.[A-Za-z0-9_]+)?="(res://[^"\r\n]+)"\r?$',physical.read_text(encoding='utf8'),re.M))
assert expanded==set(market), sorted(expanded-set(market))
scope=dict(status='FIXED_PARENT_EXACT3_WALL_TUPLE_METADATA_CANDIDATES_NOT_STAGE',parent_stage=dict(path=stagepath,sha256=stagesha),parent_deployment=dict(path='res://build/luoyang_city_revision_20261024e_root01/deployment33_actual.json',sha256='d5aa84d441ff733332d77cc702631c776bf4863b3b9aa6f601f4fdb46e83f087'),tuple_prior=dict(path=parentpath,sha256=parentsha,node='expected_ch4_s1_luoyang_yamen_true',leaves=leaves),target_count=3,partition=dict(GD_literal_patch=1,JSON_exact_copy=2),targets=[dict(target=r['target'],old_sha256=r['parent']['sha256'],old_bytes=r['parent']['bytes'],candidate=r['candidate']) for r in records.values()],no_code_function_changes=True,no_owned_proof_changes=True,no_native_media_changes=True)
scopepin=put('scope_exact3_NOT_STAGE.json',enc(scope))
proof=dict(status='EXACT3_FIXED_TUPLE_FULL_INVERSE_NOT_STAGE',scope=scopepin,records=records,maps=maps,Market_import_expansion=dict(exact_key_closure=True,count=len(market),sidecar_text_reads=sidecars),engine_calls=0,collector_calls=0,media_hashes=0,canonical_writes=0,all_original_failure_documents_preserved=True)
proofpin=put('whole_inverse_and_expected_maps_NOT_STAGE.json',enc(proof))
print(json.dumps(dict(scope=scopepin,proof=proofpin,targets=scope['targets'],maps={k:dict(path=v['path'],sha256=v['sha256'],count=v['count'],changed_header_count=len(v['changed_existing_headers'])) for k,v in maps.items()}),ensure_ascii=False))
