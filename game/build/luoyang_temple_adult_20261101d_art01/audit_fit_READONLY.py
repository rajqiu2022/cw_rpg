"""Finite exact temple floor/solid sweep audit. No engine/source writes."""
from pathlib import Path
import ast,hashlib,json,struct
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
source=(ROOT/'game/build/luoyang_city_finish_20261025i_source01/audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf-8-sig')
scope={'struct':struct}
exec(source[source.index('class FrozenVariant:'):source.index('binding_pin=')],scope)
raw=(ROOT/'game/build/luoyang_regions_20261027d_source01/visual_finish04_BUILD/output/67124/luoyang_temple_region_27d.bin').read_bytes()
assert hashlib.sha256(raw).hexdigest()=='70b37efd015a4b3f297036aabc20fae9ed4c1c9db7641e4417ed32f7cf2f4948'
decoder=scope['FrozenVariant'](raw);d=decoder.value();assert decoder.p==len(raw)
s=(ROOT/'game/build/city_neighborhoods_20261031d/verify_ly_cases_READONLY.py').read_text()
exec(compile(ast.Module(body=[n for n in ast.parse(s).body if isinstance(n,ast.FunctionDef) and n.name=='clipped'],type_ignores=[]),'existing_clipped','exec'))
RATIO=950/1499
POS=(2220-(768+64)*RATIO,2850-(754+64)*RATIO)
LEFT=2220+(104-768)*RATIO
RIGHT=2220+(1433-768)*RATIO
FRONT=2850+(866-754)*RATIO
RECTS=[(LEFT,2790,RIGHT,2820),(LEFT,2820,2170.087646484375,FRONT),(2269.91259765625,2820,RIGHT,FRONT)]

def sweep(a,b,extra=True):
    box=[min(a[0],b[0])-17,min(a[1],b[1])-12,max(a[0],b[0])+17,max(a[1],b[1])+12]
    ys=sorted(set([box[1],box[3]]+[y for x,y,w,h in d['floor_rects'] if box[1]<y<box[3]]+[y+h for x,y,w,h in d['floor_rects'] if box[1]<y+h<box[3]]))
    ground=True
    for lo,hi in zip(ys,ys[1:]):
        y=(lo+hi)/2;at=box[0]
        for x,end in sorted((x,x+w) for x,top,w,h in d['floor_rects'] if top<=y<=top+h):
            if x>at:break
            at=max(at,end)
        if at<box[2]:ground=False
    old_hits=[i for i,p in enumerate(d['solids']) if clipped(p,box)]
    new_hits=[i for i,(x0,y0,x1,y1) in enumerate(RECTS) if min(box[2],x1)>max(box[0],x0) and min(box[3],y1)>max(box[1],y0)] if extra else []
    return {'full_ground':ground,'old_solid_hits':old_hits,'overlay_hits':new_hits,'safe':ground and not old_hits and not new_hits}

routes={
 'west1720_rejected':[(1720,3100),(1720,2210)],
 'west1740_rejected':[(1740,3100),(1740,2210)],
 'old1840_now_wall':[(1840,3100),(1840,2210)],
 'west_bypass1640':[(1536,3100),(1640,3100),(1640,2450),(1800,2450),(1800,2210)],
 'original_door':[(2220,3100),(2220,2990),(2220,2914)],
 'original_bell':[(2220,3100),(2744,3100),(2744,2455),(2450,2455)],
 'original_paper':[(1536,3180),(1536,3100),(2000,3100),(2000,3200)]
}
checks={k:[{'a':a,'b':b,**sweep(a,b)} for a,b in zip(v,v[1:])] for k,v in routes.items()}
assert not checks['west1720_rejected'][0]['full_ground'] and not checks['west1740_rejected'][0]['full_ground']
for name in ('west_bypass1640','original_door','original_bell','original_paper'):
    assert all(r['safe'] for r in checks[name]),(name,checks[name])
for i in (23,24):
    for x,y in d['solids'][i]:
        assert any(x0<=x<=x1 and y0<=y<=y1 for x0,y0,x1,y1 in RECTS)
report={'status':'STATIC_FINITE_FIT_PASS_NOT_RUNTIME_OR_ART','compiled_sha256':hashlib.sha256(raw).hexdigest(),'uniform_scale':RATIO,'quad_position_px':POS,'visible_core_world_bbox':[2220+(18-768)*RATIO,2850+(116-754)*RATIO,950,768*RATIO],'door_pixel_estimate_raw':[690,526,846,754],'door_world_clear_estimate':[156*RATIO,228*RATIO],'stairs_front_world_px':[2220,2850+(884-754)*RATIO],'plinth_source_landmarks_raw':[104,1433,866],'overlay_rects_ltrb':RECTS,'routes':checks,'old_solids23_24_contained_not_removed':True,'floor_edits':0,'old_source_writes':0,'engine_runs':0,'landmarks_note':'Art manual native-pixel landmarks; +/-2px visual estimate, not a semantic segmentation claim. Alpha bboxes are exact; full runtime collision/normal screenshot remains Root QA.'}
path=HERE/'fit_audit_ACTUAL.json'
with path.open('x',encoding='utf-8',newline='\n') as stream:stream.write(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(report,ensure_ascii=False,indent=2))
