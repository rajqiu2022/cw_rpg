"""Finite new-body audit only. Immutable source/bin reads; no engine/save APIs."""
from pathlib import Path
import hashlib,json,re,struct,sys,math
N=Path(__file__).resolve().parent;R=N.parents[2]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rect(raw):
 _,_,x,y,w,d,*_=raw
 return [x-w*.43,y-d,x+w*.43,y]
def hit(a,b):return a[0]<=b[2] and a[2]>=b[0] and a[1]<=b[3] and a[3]>=b[1]
def envelope(p,h=(17,15),s=(0,0)):
 return [p[0]-h[0]-s[0],p[1]-h[1]-s[1],p[0]+h[0]+s[0],p[1]+h[1]+s[1]]
def segment_hit(a,b,box,half=(17,12)):
 box=[box[0]-half[0],box[1]-half[1],box[2]+half[0],box[3]+half[1]]
 low,high=0.,1.
 for i in range(2):
  d=b[i]-a[i]
  if not d:
   if a[i]<box[i] or a[i]>box[i+2]:return False
  else:
   u,v=(box[i]-a[i])/d,(box[i+2]-a[i])/d
   low=max(low,min(u,v));high=min(high,max(u,v))
   if low>high:return False
 return True
def stations(text,start,end):
 text=text.split(start,1)[1].split(end,1)[0]
 return [(m[0],(float(m[1]),float(m[2]))) for m in re.findall(r'\["([^"\n]+)",Vector2\(([-\d.]+),([-\d.]+)\)',text)]
data=json.loads((N/'neighborhoods02.json').read_bytes());report={'kind':'FINITE_NEW_BODY_STATIC_NOT_PHYSICS_OR_ART','inputs':{},'cities':{},'conflicts':[]}
for city in ['jinling','xiangzhou']:
 text=(N/(city+'_author_BEFORE.gd')).read_text(encoding='utf-8-sig')
 spec=data['cities'][city];new=[(r[0],rect(r)) for r in spec['replace']+spec['add']]
 if city=='jinling':
  ns=stations(text,'var stations: Array=[','\n\tfor i: int');ns=[(n,p,(32,0) if i in [3,12,27,32] else (0,0)) for i,(n,p) in enumerate(ns)]
  ns=[('water_patrol',(4500,1900),(0,0)),('merchant',(2590,1900),(0,0))]+ns
  doors=[('world',(2816,4000)),('arrival',(2816,3920)),('reed',(440,1980)),('bounty',(4780,1990)),('merchant',(2590,1900))]
 else:
  ns=stations(text,'for p: Array in [','\n\t]:');ns=[(n,p,(28,0) if i+1 in [3,5,15,18] else (0,0)) for i,(n,p) in enumerate(ns)]
  ns=[('original_guard',(2470,1660),(0,0))]+ns
  doors=[('world',(2816,4000)),('arrival',(2816,3960)),('mine',(2816,200)),('bounty',(3170,1700)),('original_guard',(2470,1660))]
 checks=[]
 for name,p,sweep in ns:
  e=envelope(p,s=sweep);collisions=[name2 for name2,b in new if hit(e,b)]
  checks.append({'npc':name,'foot':p,'conservative_half':[17,15],'sweep':sweep,'envelope':e,'hits':collisions})
  for other in collisions:report['conflicts'].append([city,'NPC_FULL_SWEEP',name,other])
 for name,p in doors:
  for other,b in new:
   if hit(envelope(p,(17,12)),b):report['conflicts'].append([city,'BUSINESS_HALF_FOOT',name,other])
 routes=[]
 for route in spec.get('routes',[])+spec.get('replace_routes',[]):
  name,points,width=route;hits=[]
  for a,b in zip(points,points[1:]):
   hits.extend([[other,a,b] for other,box in new if segment_hit(a,b,box)])
  routes.append({'route':name,'half_foot':[17,12],'hits':hits})
  for h in hits:report['conflicts'].append([city,'NEW_ROUTE',name,h])
 if city=='xiangzhou':
  hits=[name for name,b in new if segment_hit((270,650),(270,3070),b)]
  for name in hits:report['conflicts'].append([city,'OLD_WEST_SERVICE',name])
 report['cities'][city]={'version':spec['version'],'old_version':spec['old_version'],'new_bodies':new,'NPC_count':len(ns),'all_original_NPC_full_sweeps':checks,'business_half_feet':doors,'new_route_center_sweeps':routes,'note':'Only new or changed bases audited; unchanged props/old walls/water excluded; NPC half17x15 conservative.'}
source=(R/'game/build/luoyang_city_finish_20261025i_source01/audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf-8-sig');scope={'struct':struct}
exec(source[source.index('class FrozenVariant:'):source.index('binding_pin=')],scope)
old=R/'game/build/luoyang_yihongyuan_20261029n_system01/visual03/output/60160/luoyang_civic_market_region_27d.bin'
assert sha(old)=='c0a84079257b5bb2e5f8001144b5fbdf1067b2463c705eb0d4d8badfcb67d4a4'
raw=old.read_bytes();decoder=scope['FrozenVariant'](raw);compiled=decoder.value();assert decoder.p==len(raw)
spec=json.loads((N/'luoyang_courts02.json').read_bytes());bases=[(r['id'],rect([r['id'],r['kind'],*r['foot'],r['width'],r['depth']]))for r in spec['buildings']]
ns=[]
for n in compiled['npcs']:
 p=n['foot'];off=n.get('body_offset_px',(0,0));p=(p[0]+off[0],p[1]+off[1]);half=n.get('half_body',(17,15));d=n['data'];sweep=(0,0)
 if d.get('movement_mode')=='patrol':
  axis=d.get('patrol_axis',(1,0));length=math.hypot(*axis);distance=abs(d.get('patrol_distance',70));sweep=tuple(abs(x)/length*distance for x in axis) if length else (0,0)
 e=envelope(p,half,sweep);hits=[name for name,b in bases if hit(e,b)]
 ns.append({'npc':d.get('npc_id',n.get('slot_key')),'world_foot':p,'half_body':half,'sweep':sweep,'envelope':e,'hits':hits})
 for other in hits:report['conflicts'].append(['luoyang','NPC_FULL_SWEEP',ns[-1]['npc'],other])
points=[]
for field in ['portals','interactions']:
 for item in compiled[field]:
  for key in ['foot','return_foot']:
   if key not in item:continue
   p=item[key];hits=[name for name,b in bases if hit(envelope(p,(17,12)),b)]
   points.append({'kind':field,'id':item.get('key',item.get('id')),'field':key,'world_foot':p,'hits':hits})
   for other in hits:report['conflicts'].append(['luoyang','ORIGINAL_PORTAL_TASK_HALF_FOOT',points[-1]['id'],key,other])
for p in [(2730,3890),(2730,3930)]:
 assert not any(hit(envelope(p,(17,12)),b) for _,b in bases),('XUANTONG',p)
routes=[]
for route in spec['protected_routes']:
 hits=[]
 for a,b in zip(route,route[1:]):hits.extend([[name,a,b]for name,box in bases if segment_hit(a,b,box)])
 routes.append({'points':route,'hits':hits})
 for h in hits:report['conflicts'].append(['luoyang','ORIGINAL_PROTECTED_ROUTE',h])
report['cities']['luoyang']={'old_parent_sha256':sha(old),'new_bodies':bases,'NPC_count':len(ns),'all_original_NPC_full_sweeps':ns,'all_original_portal_return_task_half_feet':points,'original_protected_routes_new_body_test':routes,'scope':'New4 full bases only, world foot not legacy foot_px; no old-source geometry repeat.'}
for name in ['neighborhoods02.json','neighborhoods.gd','luoyang_courts02.json']:report['inputs'][name]=sha(N/name)
output=N/'audit_final_scope_READONLY.json';assert not output.exists();output.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'report':str(output),'sha256':sha(output),'NPC_counts':{k:v['NPC_count']for k,v in report['cities'].items()},'conflicts':report['conflicts']},ensure_ascii=False))
