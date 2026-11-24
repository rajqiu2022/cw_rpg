"""Root-authorized fixed-cache local read, no PNG decode/PIP/875/engine."""
import hashlib,json,pathlib,struct
G=pathlib.Path(__file__).resolve().parents[2];Q=G/'build/luoyang_city_full_rollout_20261022ap_qa01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p,h):assert sha(p)==h,p;return json.loads(p.read_bytes())
prior=read(Q/'artisan_a2_independent_native_ABI_prior_and_whole_source_inverse_READY.json','d0d544ed24996bf3bc4569ae9b4fd4fc3c6edba85f264075e8e67c336675ce3e')
new=read(Q/'artisan_life_independent_four_polygon_pixel_prior_READY_NOT_RUNTIME.json','3eb82257dc87d92fa354ac3340d99b5d41dd82d77b60fecb2bac92c85b1cc48e')
def f(v):return struct.unpack('<f',struct.pack('<f',v))[0]
def box(r):
    if 'polygon_px'in r:ps=r['polygon_px'];return[min(p[0]for p in ps),min(p[1]for p in ps),max(p[0]for p in ps),max(p[1]for p in ps)]
    x,y,w,h=r['rect_px'];return[x,y,f(x+w),f(y+h)]
def touch(a,b):return a[0]<=b[2]and b[0]<=a[2]and a[1]<=b[3]and b[1]<=a[3]
print(json.dumps({'newpolygon_first_schema':list(new['polygons'][0]),'old27schema':list(prior['expected27_source_solids'][0]),'npcschema':list(prior['exact_4_people_and_approaches'][0]),'candidate_sweep':[1243,1164,1277,1212],'old27_AABB_contacts':[r['id']for r in prior['expected27_source_solids']if touch([1243,1164,1277,1212],box(r))]},indent=2))
