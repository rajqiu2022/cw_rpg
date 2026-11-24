"""Pure current-Civic source geometry, no engine/network/save/image/file writes."""
from pathlib import Path
import struct, hashlib, json

R = Path(__file__).resolve().parents[3]
decoder_path = R / 'game/build/luoyang_city_finish_20261025i_source01/audit_finish8_render_texture_domains_READONLY.py'
source = decoder_path.read_text(encoding='utf-8-sig')
scope = {'struct':struct}
exec(source[source.index('class FrozenVariant:'):source.index('binding_pin=')], scope)
path = R / 'game/build/city_neighborhoods_20261031d/luoyang_output/117136/luoyang_civic_market_region_27d.bin'
raw = path.read_bytes()
digest = hashlib.sha256(raw).hexdigest()
assert digest == 'e197c636d7a0ff5c151dfc83834dd40f7ab3613b7d6347b591442666ad7be130'
reader = scope['FrozenVariant'](raw)
d = reader.value()
assert reader.p == len(raw) and d['id'] == 'luoyang_civic_market_region_27d'

def clipped(poly,b):
    out=list(poly)
    for axis,v,sign in [(0,b[0],1),(0,b[2],-1),(1,b[1],1),(1,b[3],-1)]:
        old,out=out,[]
        for a,c in zip(old,old[1:]+old[:1]):
            ai=(a[axis]-v)*sign>=0;ci=(c[axis]-v)*sign>=0
            if ai:out.append(a)
            if ai!=ci:
                t=(v-a[axis])/(c[axis]-a[axis]);out.append(tuple(a[j]+t*(c[j]-a[j]) for j in range(2)))
    return out

def legal(p):
    b=[p[0]-17,p[1]-12,p[0]+17,p[1]+12]
    cuts=sorted(set([b[1],b[3]]+[y for x,y,w,h in d['floor_rects'] if b[1]<y<b[3]]+[y+h for x,y,w,h in d['floor_rects'] if b[1]<y+h<b[3]]))
    covered=True
    for low,high in zip(cuts,cuts[1:]):
        y=(low+high)*.5;at=b[0]
        for x,end in sorted((x,x+w) for x,top,w,h in d['floor_rects'] if top<=y<=top+h):
            if x>at:break
            at=max(at,end)
        if at<b[2]:covered=False
    solids=[i for i,poly in enumerate(d['solids']) if clipped(poly,b)]
    npcs=[]
    for n in d['npcs']:
        off=n.get('body_offset_px',(0,0));a=[n['foot'][i]+off[i] for i in range(2)]
        half=n.get('half_body',(17,15));axis=n['data'].get('patrol_axis',(1,0))
        dist=n['data'].get('patrol_distance',0) if n['data'].get('movement_mode','idle')=='patrol' else 0
        bounds=[a[0]-abs(axis[0]*dist)-half[0]-17,a[1]-abs(axis[1]*dist)-half[1]-12,a[0]+abs(axis[0]*dist)+half[0]+17,a[1]+abs(axis[1]*dist)+half[1]+12]
        if bounds[0]<=p[0]<bounds[2] and bounds[1]<=p[1]<bounds[3]:npcs.append(n['data'].get('npc_id',n.get('slot_key')))
    inside=b[0]>=0 and b[1]>=0 and b[2]<=d['size'][0] and b[3]<=d['size'][1]
    return {'foot':p,'full34x24_floor_union':covered,'solid_hits':solids,'NPC_full_route_hits':npcs,'inside':inside,'safe_static_equivalent':inside and covered and not solids and not npcs}

blade=[n for n in d['npcs'] if n['data'].get('npc_id')=='spar_luoyang_blademaster']
assert len(blade)==1
candidates=[(2800,4360),(2920,4240),(2800,4100),(2660,4240),(2940,4240)]
results=[legal(p) for p in candidates]
chosen=next(x for x in results if x['foot']==(2920,4240))
assert chosen['safe_static_equivalent']
print(json.dumps({'kind':'PURE_FROZEN_CURRENT_CIVIC_FOOT_GEOMETRY_NOT_ENGINE_OR_ART','compiled_sha256':digest,'decoder_helper':str(decoder_path),'decoder_helper_sha256':hashlib.sha256(decoder_path.read_bytes()).hexdigest(),'blademaster_compiled_foot':blade[0]['foot'],'selected_fixed_near':[2920,4240],'selected':chosen,'candidate_facts':results,'production_writes':0,'engine_runs':0,'save_reads_writes':0},ensure_ascii=False,indent=2))
