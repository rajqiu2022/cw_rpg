"""Apply exact candidate diffs in memory both ways and check only local31b fixtures."""
from pathlib import Path
import hashlib,json,re
HERE=Path(__file__).resolve().parent
def sha(b):return hashlib.sha256(b).hexdigest()
def patch(original,delta):
 source=original.decode().splitlines(True);lines=delta.decode().splitlines(True);result=[];cursor=0;i=0
 while i<len(lines):
  if not lines[i].startswith('@@ '):i+=1;continue
  match=re.match(r'@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@',lines[i]);assert match,lines[i]
  start=int(match[1])-1;assert start>=cursor
  result.extend(source[cursor:start]);cursor=start;i+=1
  while i<len(lines) and not lines[i].startswith('@@ '):
   line=lines[i];i+=1
   if line.startswith(('--- ','+++ ')):continue
   tag=line[:1];body=line[1:]
   if tag in [' ','-']:assert source[cursor]==body,(cursor,repr(source[cursor]),repr(body));cursor+=1
   if tag in [' ','+']:result.append(body)
 result.extend(source[cursor:]);return ''.join(result).encode()
records=[]
for name in ['miao_town.tscn','native_sources.json','town_registry.gd']:
 before=(HERE/(name+'.BEFORE')).read_bytes();after=(HERE/(name+'.READY')).read_bytes()
 forward=patch(before,(HERE/(name+'.forward.diff')).read_bytes());inverse=patch(after,(HERE/(name+'.inverse.diff')).read_bytes())
 assert forward==after and inverse==before
 records.append({'name':name,'forward_byte_exact':True,'inverse_byte_exact':True,'before_sha256':sha(before),'after_sha256':sha(after)})
scope={'__file__':str(HERE/'seal_candidates.py')}
script=(HERE/'seal_candidates.py').read_text(encoding='utf8')
exec(script.split("checks=[")[0],scope)
hits=scope['hits'];current=scope['current'];foot=scope['foot'];nodes=scope['nodes']
assert hits([7150,2700],current)==[]
cliff=next(v for v in nodes.values() if v['parent']=='Terrain/Cliff7');values=[float(v) for v in re.search(r'polygon = PackedVector2Array\(([^)]+)\)',cliff['raw'])[1].split(',')]
poly=[[values[i]+cliff['position'][0],values[i+1]+cliff['position'][1]] for i in range(0,len(values),2)]
assert scope['collide'](foot([7250,2700]),poly)
out={'status':'IN_MEMORY_EXACT_DIFF_AND_LOCAL_STATIC_ONLY','records':records,'neighbor_cliff':{'start_ground':[7150,2700],'input':'D','toward':[7320,2700],'boundary_center_x_at_y2700':7249.565217391304,'expect_stop_ground_x_less_than':7250,'body_suffix':'/Terrain/Cliff7','layer':48,'actor_mask':40,'height':120,'start_hits':[],'blocked_sample_foot':[7250,2700],'conservative_foot':[35,25]},'engine_runs':0,'formal_writes':0,'save_access':False}
p=HERE/'inverse_and_neighbor_STATIC_READY.json';assert not p.exists()
with p.open('xb') as f:f.write((json.dumps(out,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(out,ensure_ascii=False));print(sha(p.read_bytes()))
