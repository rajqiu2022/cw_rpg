"""Root-authorized one extra parent decode; diagnostic only, not a new oracle."""
from pathlib import Path
import json
import hashlib

QA=Path(__file__).resolve().parent
ORIGINAL=QA/'prepare_artisan_a2_independent_source_recipe01.py'
OUT=QA/'artisan_a2_parent_local_raster_diagnostic01_NOT_ORACLE.json'
CACHE=QA/'artisan_parent53624_original_RGBA_6e725411_cache.rgba8'
assert not OUT.exists() and not CACHE.exists()
src=ORIGINAL.read_text(encoding='utf-8')
cut="assert np.array_equal(old_local,parent[flat]),'Independent old source raster must match parent in every delta-domain pixel'"
assert src.count(cut)==1
# Reuse the exact frozen independent source expression, not the failing assertion
# nor any System diagnostic/publisher. The original preparation remains untouched.
env={'__file__':str(ORIGINAL),'__name__':'independent_diagnostic_prefix'}
exec(compile(src.split(cut)[0],str(ORIGINAL),'exec'),env)
np=env['np'];parent=env['parent'];flat=env['flat'];expected=env['old_local']
bad=np.flatnonzero(np.any(parent[flat]!=expected,axis=1))
assert len(bad)>0
badflat=flat[bad];xs=badflat%3072;ys=badflat//3072
details=[]
for ordinal in bad[:32]:
    q=int(flat[ordinal]);x=q%3072;y=q//3072
    hits=[]
    for solid in env['oldsolids']:
        values=env['paint_values'](env['old'],[solid],np.array([q]))
        if values[0,0]==0:
            hits.append(solid)
    details.append({'x':x,'y':y,'parentRGBA':parent[q].tolist(),
        'independent_source_expectedRGBA':expected[ordinal].tolist(),
        'source_solid_hits':hits})
bydomain=[]
for d in env['domains']:
    x0,y0,x1,y1=d['integer_guard_closed']
    ids=(xs>=x0)&(xs<=x1)&(ys>=y0)&(ys<=y1)
    bydomain.append({'id':d['id'],'phase':d['phase'],
        'integer_guard_closed':d['integer_guard_closed'],'mismatch_pixels':int(ids.sum())})
raw=parent.tobytes()
assert hashlib.sha256(raw).hexdigest()=='6e72541153449e571516c340838794ff44fdf96dfc8b601b93733b3d4ff4c6da'
CACHE.write_bytes(raw)
r={'status':'PARENT_LOCAL_SOURCE_RASTER_DIAGNOSTIC_NOT_NEW_EXPECTED_OR_GEOMETRY_ADMISSION',
   'old_recipe_first_precise_rejection_preserved':True,
   'independent_prefix_script_sha256':hashlib.sha256(ORIGINAL.read_bytes()).hexdigest(),
   'parent_png':{'path':env['mask_path'],'sha256':env['PINS'][env['mask_path']]},
   'parent_decoded_RGBA_sha256':env['parent_hash'],'domain_union_pixels':int(len(flat)),
   'mismatch_count':int(len(bad)),'mismatch_bounds_inclusive':[int(xs.min()),int(ys.min()),int(xs.max()),int(ys.max())],
   'mismatch_counts_by_domain':bydomain,'first32_mismatch_details':details,
   'cache':{'path':'res://'+CACHE.relative_to(env['GAME']).as_posix(),
       'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw),'format':'Original parent raw RGBA8 row-major3072x2048, no new expected pixels; no encoded image output'},
   'PNG_decode_this_diagnostic':1,'PNG_output':0,'engine_runs':0,'new_oracle':False,'canonical_writes':0}
OUT.write_text(json.dumps(r,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'diagnostic_sha256':hashlib.sha256(OUT.read_bytes()).hexdigest(),
    'mismatches':len(bad),'bounds':r['mismatch_bounds_inclusive'],'details':details[:6],
    'cache_SHA':r['cache']['sha256'],'counts_by_domain':bydomain},ensure_ascii=False))
