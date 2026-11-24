from pathlib import Path
import hashlib,json
P=Path(__file__).resolve().parent
old=(P/'model_pixel_prior_NOTENGINE.py').read_bytes()
a=b'domains=[[899,0,1323,1482],[650,670,288,94],[1427,587,286,96],[2136,588,740,66]]'
b=b'''# Derive all changed bounding domains from the actual source rectangles; do not
# clip the moved pavilion's highest ground post with a hand-rounded y670 box.
parent_author=json.loads((G/'build/luoyang_city_full_rollout_20261022ap_system01/garden_revision4/shore_landing_retry2/author_READY.json').read_bytes())
domains=[[899,0,1323,1482]]
for source_author,object_id in [(parent_author,'ap_river_pavilion'),(a,'ap_river_pavilion'),(a,'garden_riverside_tea_house_25h')]:
 row=next(x for x in source_author['scenes'][0]['placements'] if x['id']==object_id)
 asset=source_author['assets'][row['asset']]
 bounds=[transform(row,asset,r) for r in asset['solid_rects']]
 low=np.floor(np.min(np.array([r[0] for r in bounds]),axis=0)).astype(int)-1
 high=np.ceil(np.max(np.array([r[2] for r in bounds]),axis=0)).astype(int)+1
 domains.append([int(low[0]),int(low[1]),int(high[0]-low[0]+1),int(high[1]-low[1]+1)])'''
assert old.count(a)==1
new=old.replace(a,b).replace(b"independent_source_pixel_model_PRIOR_PROPOSAL.json",b"independent_source_pixel_model02_PRIOR_PROPOSAL.json")
assert new.replace(b,a).replace(b"independent_source_pixel_model02_PRIOR_PROPOSAL.json",b"independent_source_pixel_model_PRIOR_PROPOSAL.json")==old
dest=P/'model_pixel_prior02_NOTENGINE.py';assert not dest.exists()
with dest.open('xb')as f:f.write(new)
print(json.dumps({'path':str(dest),'sha256':hashlib.sha256(new).hexdigest(),'retained_first_failure':'source_model_first_failure_DIAGNOSTIC.json','reason':'New pavilion fourth post minimum y=760+(1024-1245)*(480/1152) rounded by f32 is667.9167, so manual y670 domain missed32 pixels. Domain now comes from full declared old/new source rectangle extrema, not observed diff bounds.'}))
