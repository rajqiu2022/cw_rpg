"""Read-only author scout, not Godot/Physics or publication credit."""
import json, math, struct, pathlib
from PIL import Image
ROOT=pathlib.Path(__file__).resolve().parents[3]
AUTHOR=ROOT/'game/data/maps/luoyang_district_life_20261016f/author.json'
a=json.loads(AUTHOR.read_text(encoding='utf-8'))
def res(p): return ROOT/'game'/p.removeprefix('res://')
def f(x): return struct.unpack('f',struct.pack('f',x))[0]
def cross(a,b,p): return (b[0]-a[0])*(p[1]-a[1])-(b[1]-a[1])*(p[0]-a[0])
def on(a,b,p): return cross(a,b,p)==0 and min(a[0],b[0])<=p[0]<=max(a[0],b[0]) and min(a[1],b[1])<=p[1]<=max(a[1],b[1])
def touch(a,b,c,d): return cross(a,b,c)*cross(a,b,d)<0 and cross(c,d,a)*cross(c,d,b)<0 or any((on(a,b,c),on(a,b,d),on(c,d,a),on(c,d,b)))
def inside(p,poly):
    yes=False
    for aa,bb in zip(poly,poly[1:]+poly[:1]):
        if on(aa,bb,p): return True
        if (aa[1]>p[1])!=(bb[1]>p[1]) and p[0]<(bb[0]-aa[0])*(p[1]-aa[1])/(bb[1]-aa[1])+aa[0]: yes=not yes
    return yes
def hit(foot,half,solid):
    x,y=foot; w,h=half
    if x+w<min(p[0] for p in solid) or x-w>max(p[0] for p in solid) or y+h<min(p[1] for p in solid) or y-h>max(p[1] for p in solid): return False
    body=[[x-w,y-h],[x+w,y-h],[x+w,y+h],[x-w,y+h]]
    return any(inside(p,solid) for p in body) or any(inside(p,body) for p in solid) or any(touch(aa,bb,cc,dd) for aa,bb in zip(body,body[1:]+body[:1]) for cc,dd in zip(solid,solid[1:]+solid[:1]))
def old_solids(r):
    out=[]
    for o in r['objects']:
        if not o.get('blocking'): continue
        for poly in o.get('solid_polygons_px',[]): out.append((o['id'],poly))
        size=o.get('collision_size_px',[0,0]); c=o.get('physical_center_px',[0,0])
        if size[0]>0: out.append((o['id'],[[c[0]+x*size[0],c[1]+y*size[1]] for x,y in [(-.5,-.5),(.5,-.5),(.5,.5),(-.5,.5)]]))
    return out
def delta(s):
    out=[]
    for p in s['placements']:
        asset=a['assets'][p['asset_id']]; anchor=asset['source_ground_anchor_px']
        for poly in asset['ground_solid_polygons_px']:
            out.append((p['id'],[[f(f(p['foot_px'][i])+f(f(f(v[i])-f(anchor[i]))*f(p['scale']))) for i in range(2)] for v in poly]))
    return out
rows=[]
for city,s in a['districts'].items():
    r=json.loads(res(s['parent_manifest']['path']).read_text(encoding='utf-8'))['record']
    mask=Image.open(res(s['parent_walk']['path'])).convert('RGBA'); pix=mask.load()
    extra=delta(s); solids=old_solids(r)+extra; bad=[]; samples=0
    def clear(p,half=(17,12),check_mask=True):
        for ident,poly in solids:
            if hit(p,half,poly): return 'solid:'+ident
        if check_mask:
            x,y=p
            bounds=[math.floor(x-half[0]+.5),math.floor(y-half[1]+.5),math.floor(x+half[0]+.5),math.floor(y+half[1]+.5)]
            if bounds[0]<0 or bounds[1]<0 or bounds[2]>=3072 or bounds[3]>=2048: return 'outside'
            if min(mask.crop((bounds[0],bounds[1],bounds[2]+1,bounds[3]+1)).getextrema()[0])<128: return 'mask'
        return ''
    routes=list(r['routes'])+s['required_routes']
    for p in s['crowd']:
        x,y=p['foot_px']; d=p['distance_px']; routes.append({'id':p['id'],'points_px':[[x-d,y],[x+d,y]],'npc':True})
    if city.endswith('gate') or city.endswith('docks'):
        # Exact old native spec is independently validated by G.audit in Godot.
        old=([[750,1600,70],[1120,1720,70],[2010,1700,70],[2440,1640,60],[2370,1870,110],[680,1880,120],[1020,1480,0],[1940,1450,0],[2400,1450,0],[1840,1600,0]] if city.endswith('gate') else [[1400,880,60],[1670,900,70],[1570,1430,60],[1570,1740,70],[590,1240,100],[900,1930,140],[1050,970,0],[2000,1430,0],[1050,1410,0],[2010,1900,0]])
        for i,(x,y,d) in enumerate(old): routes.append({'id':'old_crowd_'+str(i),'points_px':[[x-d,y],[x+d,y]],'npc':True})
    for route in routes:
        for aa,bb in zip(route['points_px'],route['points_px'][1:]):
            n=max(1,math.ceil(math.dist(aa,bb)/4))
            for i in range(n+1):
                p=[f(aa[j]+(bb[j]-aa[j])*i/n) for j in range(2)]
                reason=clear(p,(17,15) if route.get('npc') else (17,12));samples+=1
                if reason: bad.append({'route':route['id'],'point':p,'why':reason});break
    for typ in ['npcs','interactions','portals']:
        for slot in r['gameplay_slots'].get(typ,[]):
            p=slot.get('stand_px',slot.get('foot_px'))
            for ident,poly in extra:
                if hit(p,(17,15),poly):bad.append({'anchor':slot.get('source_id'),'point':p,'why':'newsolid:'+ident})
    boxes=[]
    prot=[slot.get('stand_px',slot.get('foot_px')) for typ in ['npcs','interactions','portals'] for slot in r['gameplay_slots'].get(typ,[])]+s['protected_feet']
    for p in s['crowd']:
        x,y=p['foot_px'];d=p['distance_px'];b=(x-d-34,y-30,x+d+34,y+30)
        for ident,o in boxes:
            if b[0]<=o[2] and o[0]<=b[2] and b[1]<=o[3] and o[1]<=b[3]:bad.append({'npc':p['id'],'why':'othernpc:'+ident})
        for pp in prot:
            if b[0]-34<=pp[0]<=b[2]+34 and b[1]-34<=pp[1]<=b[3]+34:bad.append({'npc':p['id'],'why':'protected:'+str(pp)})
        boxes.append((p['id'],b))
    rows.append({'city':city,'samples':samples,'failures':bad})
print(json.dumps({'scope':'READ_ONLY_SCOUT_NOT_ENGINE_OR_PHYSICS','rows':rows},ensure_ascii=False,indent=2))
