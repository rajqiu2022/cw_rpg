"""Root authorized residual: explicit integer Rect2i touch test only. No run."""
from pathlib import Path
import copy,hashlib,json
B=Path(__file__).resolve().parent;OLD=B/'market_prior01_READY';NEW=B/'market_prior02_READY'
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(name,h):
    b=(OLD/name).read_bytes();assert sha(b)==h;return b
def put(name,b):
    p=NEW/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b)
    return dict(path=p.as_posix(),sha256=sha(b),bytes=len(b))
oldf=fixed('fixture_READY.json','9f64c0f76f14ba10ceb6aaed6be37316ef937f34715ca10e63160e75a8a56179')
f=json.loads(oldf);previous=copy.deepcopy(f)
f['output_path']=(NEW/'output/result.json').as_posix()
fb=(json.dumps(f,ensure_ascii=True,indent=2)+'\n').encode('ascii');fixture=put('fixture_READY.json',fb)
inverse=copy.deepcopy(f);inverse['output_path']=previous['output_path']
assert (json.dumps(inverse,ensure_ascii=True,indent=2)+'\n').encode('ascii')==oldf
old=fixed('oracle_READY.gd','2872dd849fa2fe41e600d9659313ff5b25d2dbb9204ba713179f375c92659b3d')
ops=[
 (b'if current.intersects(merged[i],true): current=current.merge(merged[i]);merged.remove_at(i);again=true;break',
  b'if current.position.x<=merged[i].end.x and merged[i].position.x<=current.end.x and current.position.y<=merged[i].end.y and merged[i].position.y<=current.end.y: current=current.merge(merged[i]);merged.remove_at(i);again=true;break'),
 ((OLD/'fixture_READY.json').as_posix().encode(),fixture['path'].encode()),
 (sha(oldf).encode(),fixture['sha256'].encode())]
key=old
for before,after in ops:assert key.count(before)==1;key=key.replace(before,after,1)
back=key
for before,after in reversed(ops):assert back.count(after)==1;back=back.replace(after,before,1)
assert back==old
k=put('oracle_READY.gd',key);project=put('project.godot',(OLD/'project.godot').read_bytes())
# Independent integer model originally used this same four-axis touch predicate.
model=json.loads((B/'market_prior01_NOTREADY/independent_f32_model_NOT_PIP.json').read_bytes())
merged=[]
for box in model['raw_half_open_domains']:
    box=[max(0,box[0]),max(0,box[1]),min(3072,box[2]),min(2048,box[3])]
    again=True
    while again:
        again=False
        for i,r in enumerate(merged):
            if box[0]<=r[2] and r[0]<=box[2] and box[1]<=r[3] and r[1]<=box[3]:
                box=[min(box[0],r[0]),min(box[1],r[1]),max(box[2],r[2]),max(box[3],r[3])]
                merged.pop(i);again=True;break
    merged.append(box)
assert merged==model['merged_half_open_domains'] and len(merged)==27
assert sum((r[2]-r[0])*(r[3]-r[1]) for r in merged)==1000516
proof=put('residual_whole_inverse_NOT_RUN.json',(json.dumps(dict(status='ROOT_AUTHORIZED_RECT2I_TOUCH_RESIDUAL_NOT_RUN',key=k,fixture=fixture,project=project,
 wholebyte_inverse=True,key_replacements=[dict(before=a.decode(),after=b.decode()) for a,b in ops],fixture_only_output_path=True,
 preserved='prior01 parseFAIL retained; no PNG decode/output by that failure; all original source/model/27domains/1000516 unchanged',
 mathematical_predicate='Closed bounding-box overlap/touch on each integer axis: a.lo<=b.hi and b.lo<=a.hi. Rect2i half-open raster bounds unchanged; touch rule only merges conservative domains.',
 integer_model_recomputed_exact=True,model_or_expected_hash_fill=False,engine_calls=0),ensure_ascii=True,indent=2)+'\n').encode('ascii'))
print(json.dumps(dict(key=k,fixture=fixture,project=project,proof=proof)))
