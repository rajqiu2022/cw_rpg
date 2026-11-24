"""Mechanical NEW false fixture/header successors from fixed FD58, no engine/current source crawl."""
import copy,difflib,hashlib,json,pathlib
G=pathlib.Path(__file__).resolve().parents[2]
Q='res://build/luoyang_city_full_rollout_20261022ap_qa01/'
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def path(p):return G/p[6:]
def raw(p):return path(p).read_bytes()
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h=None):
    b=raw(p)
    assert not h or sha(b)==h,(p,'FIXED_SMALL_SHA')
    return json.loads(b)
def merge(*tables):
    r={}
    for t in tables:
        for p,h in t.items():assert p not in r or r[p]==h,('FIXED_SOURCE_COLLISION',p);r[p]=h
    return r
def emit(p,b):
    t=path(p);assert not t.exists(),('NEW_ONLY',p)
    t.parent.mkdir(parents=True,exist_ok=True);t.write_bytes(b)
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
op=S+'unified101_actual_owner_READY/owner_source_maps_READY.json'
oh='fd58f7c2dbd3372d6adbb6f9a39ba7c70568125e4f843c11dc546e750fdfd61c'
owner=read(op,oh)
rp=owner['actual_stage_receipt']['path'];rh=owner['actual_stage_receipt']['sha256']
assert rh=='4ce21902185a78f6c441f8ee8d63d30b30a7c31c61f135b5df13322bc266d945'
qr=Q+'unified100_actual_FD58_owner_independent_review_READY.json'
qh='399d1c7d3054204c7856a2b35cf679b7c5176dad62ae8813ca12a543f8870874'
read(qr,qh)
rows={r['id']:r for r in owner['scenes']}
reports=[]
for stem,ident,fh,kh in [
 ('artisan_four_low_props','luoyang_artisan_residential_20261022ap','491aa2dd027629617e5c4b955afa3c46e79d1772ad72e224178272fc6dbfe166','540a21b85d8e0e1039fc2ed473375e65f5dddf9e42ffc2c0d27049f5b08e84d719'),
 ('market_scholar_identity','ch4_s3_luoyang_market','580957cfd9d52ee96062f56310704c139c99ce7c997ac0199023206c6849aa55','175e750a18438e57fae3ea09ff5a996fe7fa86219fa2da35bb856ade1679489e')]:
    oldroot=Q+stem+'_Field_NOTREADY/'
    newroot=Q+stem+'_Field_FD58_NOTREADY/'
    fp=oldroot+'fixture_NOTREADY.json';kp=oldroot+'test_'+stem+'_NOTREADY.gd'
    original=read(fp,fh);kb=raw(kp);assert sha(kb)==kh
    f=copy.deepcopy(original);row=rows[ident]
    f['status']=stem.upper()+'_FIXED_FD58_OWNER_NOTREADY_FORMAL_DEPLOYMENT_PENDING'
    f['blockers']=['Root formal28 deployment receipt/final guard and fresh-run guard absent; keep hardfalse.','No parse/run authorization; no Field or ART credit from publication/source review.']
    f['owner']={'path':op,'sha256':oh}
    f['actual_stage_receipt']={'path':rp,'sha256':rh}
    f['QA_actual_text_review']={'path':qr,'sha256':qh}
    f['formal_deployment']={'path':None,'sha256':None}
    f['formal_final_guard']={'path':None,'sha256':None}
    f['fresh_run_guard']={'path':None,'sha256':None}
    sources=row['source_sha256'];receipt=row['receipt_source_sha256']
    fixed={}
    if stem.startswith('artisan'):
        assert len(sources)==341 and len(receipt)==339
        f['expected_sources']=copy.deepcopy(sources);f['expected_receipt_sources']=copy.deepcopy(receipt)
        f['expected_source_count']=341;f['expected_receipt_count']=339
        for k in ('independent_author','independent_polygon_pixel_prior','publication_actual'):
            v=f[k];fixed[v['path']]=v['sha256']
        for p in f['props']:
            v=p['source_author'];fixed[v['path']]=v['sha256'];fixed[p['texture']]=p['source_png_sha256']
    else:
        assert len(sources)==1741 and sources==receipt
        f['owner_tables_ready']=True
        f['expected_city_sources']=copy.deepcopy(sources);f['expected_city_source_count']=1741
        fixed={r['path']:r['sha256']for r in f['fixed_provenance']}
    f['source_sha256']=merge(owner['core_source_sha256'],sources,fixed,{op:oh,rp:rh,qr:qh})
    if stem.startswith('artisan'):f['guarded_source_count']=len(f['source_sha256'])
    assert f['ready'] is False
    nf=newroot+'fixture_NOTREADY.json';fb=js(f);emit(nf,fb)
    replacements=[(fp,nf),(fh,sha(fb)),(oldroot+'output/',newroot+'output/')]
    nb=kb
    for a,b in replacements:
        assert nb.count(a.encode())==1,(stem,'EXACT_HEADER_LITERAL',a)
        nb=nb.replace(a.encode(),b.encode(),1)
    inverse=nb
    for a,b in reversed(replacements):inverse=inverse.replace(b.encode(),a.encode(),1)
    assert inverse==kb and b'const FIXTURE_READY=false' in nb
    nk=newroot+'test_'+stem+'_NOTREADY.gd';emit(nk,nb)
    delta=[{'field':k,'existed':k in original,'old':original.get(k),'new':v}for k,v in f.items()if k not in original or original[k]!=v]
    rev=copy.deepcopy(f)
    for d in delta:
        if d['existed']:rev[d['field']]=d['old']
        else:del rev[d['field']]
    assert rev==original and js(rev)==js(original)
    kd=''.join(difflib.unified_diff(kb.decode().splitlines(True),nb.decode().splitlines(True),fromfile=kp,tofile=nk)).encode()
    emit(newroot+'complete_key_header_diff.diff',kd)
    report={'status':'FIXED_FD58_TABLES_ONLY_HARDFALSE_NOT_AUTHORIZED_TO_RUN','key':{'path':nk,'sha256':sha(nb)},'fixture':{'path':nf,'sha256':sha(fb)},'parent_key':{'path':kp,'sha256':kh},'parent_fixture':{'path':fp,'sha256':fh},'only_three_key_literals':replacements,'key_whole_byte_inverse':True,'fixture_complete_delta':delta,'fixture_full_typed_serialized_inverse':True,'guard_count':len(f['source_sha256']),'fixed_owner':{'path':op,'sha256':oh},'deployment_and_run_guards_pending':True,'no_observed_expectation_fill':True,'QA_actions':{'engine':False,'parse':False,'collector':False,'decode':False,'production_write':False}}
    hp=newroot+'handoff_NOTREADY.json';emit(hp,js(report))
    reports.append({'kind':stem,'key':report['key'],'fixture':report['fixture'],'handoff':{'path':hp,'sha256':sha(js(report))},'guard_count':len(f['source_sha256'])})
print(json.dumps(reports,indent=2))
