"""Read only the fixed Stage whitelist, permit exactly its32 authorized canonical successors."""
from pathlib import Path
import hashlib,json,datetime,concurrent.futures
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261025g_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):return (GAME/p[6:]).resolve() if p.startswith('res://') else Path(p).resolve()
def load(pin):
    b=res(pin['path']).read_bytes();assert sha(b)==pin['sha256'];return json.loads(b)
def fact(p):
    q=res(p)
    if not q.is_file():return p,dict(exists=False)
    a=q.stat()
    with q.open('rb') as stream:h=hashlib.file_digest(stream,'sha256').hexdigest()
    b=q.stat()
    return p,dict(exists=True,sha256=h,bytes=b.st_size,ticks=str(b.st_mtime_ns//100+621355968000000000),stable=(a.st_size,a.st_mtime_ns)==(b.st_size,b.st_mtime_ns))
start=datetime.datetime.now(datetime.timezone.utc).isoformat()
stagepin=dict(path=S+'outputs/root_market_courtyard45_exact32_stage02/receipt.json',sha256='c972f71442cc6573d8e55a92bf0ce875039879be651dd30e3fd32df585d97396')
deppin=dict(path='res://build/luoyang_city_revision_20261025g_root01/courtyard45_32_deployed_actual.json',sha256='7f2a7be12b86f3021d87dfc0f74294e2961c3ef376e4c8bb533cc59a74870071')
stage=load(stagepin);dep=load(deppin)
assert dep['passed'] is True and dep['target_count']==32 and dep['stage_sha256']==stagepin['sha256']
targets={r['target']:r for r in stage['targets']};declared={r['target']:r for r in dep['targets']}
assert len(targets)==len(declared)==32 and targets.keys()==declared.keys() and stage['source_first']==stage['source_final']
expected=dict(stage['source_first'])
for p,row in targets.items():
    assert expected[p]==row['old_sha256'] and declared[p]['sha256']==row['candidate_sha256'] and row['old_sha256']!=row['candidate_sha256']
    expected[p]=row['candidate_sha256']
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:now=dict(pool.map(fact,expected))
unexpected=[dict(path=p,expected=h,current=now[p]) for p,h in expected.items() if now[p].get('sha256')!=h or not now[p].get('stable',False)]
authorized=[dict(path=p,old_sha256=row['old_sha256'],candidate_sha256=row['candidate_sha256'],current=now[p]) for p,row in targets.items()]
maps=[]
for ident,n in stage['nodes'].items():
    if not ident.startswith('expected_'):continue
    value=load(dict(path=n['path'],sha256=n['sha256']));assert value==n['value']
    maps.append(dict(id=ident,path=n['path'],sha256=n['sha256'],count=len(value['source_sha256']),fixed_map_physical_SHA_typed_value_exact=True))
assert [r['count'] for r in maps]==[982,1364,1858,1900]
out=dict(status='SOURCE25G_POSTDEPLOY32_FIXED_STAGE_SOURCE_WHITELIST_READONLY',passed=not unexpected,stage=stagepin,deployment=deppin,fixed_stage_source_count=len(expected),expected_authorized_canonical_changes=32,authorized_changes=authorized,unexpected_changes=unexpected,all_other_frozen_stage_source_hashes_same=not unexpected,new_expected_maps=maps,baseline_expectations_not_current_fill=True,no_new_paths_collected=True,full2121_save15_148backup_media8_guard='Independent QA final guard remains separate; this tool only reads pinned Stage3284 whitelist and four output maps.',started_utc=start,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),engine_calls=0,collector_calls=0,media_decodes=0,geometry_decodes=0,canonical_writes=0)
raw=(json.dumps(out,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();p=HERE/'deployed32_frozen_stage_sources_READONLY.json'
with p.open('xb') as stream:stream.write(raw)
print(json.dumps(dict(path=S+p.name,sha256=sha(raw),passed=out['passed'],whitelist_sources=len(expected),authorized=32,unexpected=len(unexpected),maps=[r['count'] for r in maps])))
