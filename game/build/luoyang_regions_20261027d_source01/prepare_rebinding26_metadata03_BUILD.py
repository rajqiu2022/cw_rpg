"""Only reorder independent execution-index publication before Family metadata."""
from pathlib import Path
import copy,difflib,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01';U=N/'source_rebinding02_BUILD/closure26_META03'
sha=lambda b:hashlib.sha256(b).hexdigest();enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();res=lambda p:'res://'+p.relative_to(G).as_posix()
def read(pin):
 b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'];return b
def load(pin):return json.loads(read(pin))
def pin(path):b=path.read_bytes();return dict(path=res(path),sha256=sha(b),bytes=len(b))
def emit(name,raw):
 p=U/name;p.parent.mkdir(parents=True,exist_ok=True);assert not p.exists();p.write_bytes(raw);return dict(path=res(p),sha256=sha(raw),bytes=len(raw))
currentpin=dict(path='res://build/luoyang_regions_20261027d_source01/source_rebinding02_BUILD/closure26/source_rebind26_all_candidates_NOT_STAGE.json',sha256='5b9cabaa211abcf1c1cf1b5a2ddc1115dcb02eb5764983dadfbc74ac7ed0a77e');current=load(currentpin)
oldpin=current['parent_descriptor'];old=load(oldpin);stagepin=current['parent_stage'];stage=load(stagepin);rebindpin=current['rebind'];rebind=load(rebindpin)
assert not U.exists();U.mkdir()
parents={r['target']:r['parent']for r in current['targets']};metadata={};indexes={};records={p:r for p,r in current['records'].items()if p not in current['index_proofs']};refs={r['target']:r['candidate']for r in current['targets']if r['target']not in current['metadata']and r['target']not in current['index_proofs']};data={p['path']:read(p)for p in refs.values()};ordinary=current['source_additions'];contract=current['contract'];temple_binding=current['temple_binding'];execution=current['execution']
def exact(raw,a,b):
 a=a.encode();b=b.encode();assert a!=b and raw.count(a)==1;return raw.replace(a,b,1)
def hunks(a,b):
 rows=[];aa=a.decode().splitlines(True);bb=b.decode().splitlines(True)
 for group in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(12):rows.append(dict(old=''.join(aa[group[0][1]:group[-1][2]]),new=''.join(bb[group[0][3]:group[-1][4]])))
 f=a;back=b
 for row in rows:f=exact(f,row['old'],row['new'])
 for row in reversed(rows):back=exact(back,row['new'],row['old'])
 assert f==b and back==a;return rows
def record(target,name,raw):
 before=read(parents[target]);assert before!=raw;p=emit(name,raw);refs[target]=p;data[p['path']]=raw;records[target]=dict(parent=parents[target],candidate=p,hunks=hunks(before,raw),whole_byte_forward_inverse=True);return p
source=(N/'prepare_rebinding26_BUILD.py').read_text(encoding='utf8')
start=source.index('def at(value,ptr):');end=source.index("meta('estate_final');meta('quarter_final')",start)
exec(compile(source[start:end],str(N/'prepare_rebinding26_BUILD.py'),'exec'))
meta('estate_final');index('ap_execution_index');meta('quarter_final')
for id in ['legacy_manifest_2','legacy_manifest_3','legacy_manifest_4','legacy_manifest_5','legacy_manifest_6','legacy_manifest_7','legacy_manifest_8']:meta(id)
for id in ['legacy_index_0','legacy_index_1','legacy_index_2','legacy_index_3','legacy_index_4','ap_quarter_index']:index(id)
meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')
tail_start=source.index('assert len(records)==11');tail_end=source.index("scope=dict(status=",tail_start)
tail=source[tail_start:tail_end]
# This descriptor preserves every non-metadata candidate from the failed parent.
exec(compile(tail,str(N/'prepare_rebinding26_BUILD.py'),'exec'))
descriptor=load(out)
for id,fp in descriptor['expected_family_maps'].items():
 value=load(fp)
 for path,h in value['source_sha256'].items():
  if path in refs:assert h==refs[path]['sha256'],(id,path)
assert all(descriptor[k]==current[k]for k in ['contract','temple_binding','execution','rebind'])
print(json.dumps({'descriptor':out,'scope_unchanged':True,'backup_unchanged':True,'runtime_code_candidates_unchanged':True,'family_all_prospective_exact':True,'maps':{k:v['count']for k,v in maps.items()}}))
