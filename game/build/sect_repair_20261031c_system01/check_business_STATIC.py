"""Only new door enclosure and business anchors, no old slope matrix/engine."""
from pathlib import Path
import json,math,hashlib
HERE=Path(__file__).resolve().parent
data=json.loads((HERE/'adoption_data.json').read_text(encoding='utf8'))
def inside(p,poly):
 yes=False
 for i,a in enumerate(poly):
  b=poly[i-1]
  if (a[1]>p[1])!=(b[1]>p[1]) and p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]:yes=not yes
 return yes
def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
def collide(a,b):return any(inside(p,b) for p in a) or any(inside(p,a) for p in b) or any(cross(a[i-1],p,b[j-1])*cross(a[i-1],p,q)<0 and cross(b[j-1],q,a[i-1])*cross(b[j-1],q,p)<0 for i,p in enumerate(a) for j,q in enumerate(b))
def level(row,p):return max([0]+[r['level'] for r in row['terrain']['platforms'] if inside(p,r['polygon'])])
def hits(row,p,old=False):
 body=[[p[0]-17.5,p[1]-12.5],[p[0]+17.5,p[1]-12.5],[p[0]+17.5,p[1]+12.5],[p[0]-17.5,p[1]+12.5]];mask=8|(16<<level(row,p))
 return [r['path'] for r in row['solids'] if int(r['layer'])&mask and (not old or not r['path'].startswith('Town/GateClosure')) and collide(body,r['polygon'])]
checks=[]
for id,row in data['towns'].items():
 for label,p in [('arrival',row['arrival']),('inner_return',row['inner_return'])]+list(row['portal_feet'].items())+([('wall_safe_entry',row['gate_wall_safe_entry'])] if 'gate_wall_safe_entry' in row else []):
  check={'id':id,'anchor':label,'ground':p,'level':level(row,p),'hits':hits(row,p)};checks.append(check);assert not check['hits'],check
w=data['towns']['openworld_wudang_gate'];fail=[]
for y in range(3890,3689,-5):
 h=hits(w,[1680,y])
 if h:fail.append({'foot':[1680,y],'hits':h})
assert not fail,fail
negative=[]
for x in [800,2600]:
 start=[x,3890];blocked=[x,3790]
 record={'start':start,'start_hits':hits(w,start),'new_covered':blocked,'old_hits':hits(w,blocked,True),'current_hits':hits(w,blocked)}
 negative.append(record);assert not record['start_hits'] and not record['old_hits'] and record['current_hits'],record
intervals=[[r['polygon'][0][0],r['polygon'][1][0]] for r in w['new_gate_walls']]+[[1329.5798,1619.6358],[1739.3837,2070.4202]]
intervals.sort();merged=[]
for start,end in intervals:
 if merged and start<=merged[-1][1]:merged[-1][1]=max(merged[-1][1],end)
 else:merged.append([start,end])
assert len(merged)==2 and merged[0][0]<=110 and merged[1][1]>=5090 and abs(merged[0][1]-1619.6358)<.01 and abs(merged[1][0]-1739.3837)<.01,merged
report={'status':'LOCAL_STATIC_ONLY_NOT_ENGINE_OR_PHYSICS','foot':[35,25],'anchors':checks,'gate_cross':{'x':1680,'y_start':3890,'y_end':3690,'step':5,'samples':41,'failures':fail},'wall_negative_and_legacy_samples':negative,'wall_and_pier_merged_intervals_at_y3790':merged,'only_gap_world_x':[1619.6358,1739.3837],'opaque_architecture':'derived controllers reset original fade_enabled to0 each frame; ghost only live actoralpha.42','old_slope_physics':'not changed; no repeated old matrix','engine_runs':0,'save_access':False}
b=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode();p=HERE/'business_STATIC_READY_01.json';assert not p.exists()
with p.open('xb') as f:f.write(b)
print(hashlib.sha256(b).hexdigest());print(json.dumps(report,ensure_ascii=False))
