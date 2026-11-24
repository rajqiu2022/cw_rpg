"""Root-only JSON transport and independent static Temple source-expression recipe."""
from pathlib import Path
import argparse,json,hashlib
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'docks_gallery_family_repair01/'
ap=argparse.ArgumentParser();ap.add_argument('--descriptor-sha256',required=True);a=ap.parse_args()
bp=P+'unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'
raw=(G/bp[6:]).read_bytes();assert hashlib.sha256(raw).hexdigest()==a.descriptor_sha256;b=json.loads(raw)
t=(N/'prepare_repair31_Temple_natural_source_expectation_NOTENGINE.py').read_text(encoding='utf-8')
for x,y in [('repair31_READY03/unified32_all_candidates_and_inverse_NOT_STAGE.json','docks_gallery_family_repair01/unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),('319fc714cb589608c9dc200d47d7e517abc534fc2e540073eee9f3f3b9044a98',a.descriptor_sha256),('repair31_Temple_natural_session_sources_READONLY.json','docks_gallery_family_repair01/expected_Temple_natural_sources_READONLY.json')]:
 assert x in t,x;t=t.replace(x,y)
exec(compile(t,str(N/'prepare_gallery_Temple_EXPECTATION_DERIVED.py'),'exec'),{'__file__':str(N/'prepare_gallery_Temple_EXPECTATION_DERIVED.py')})
# JSON-only deployment remains separate from GD patch/Router formatting. Existing exact
# copy guard is reused after fixed Stage output arrives; this freezes its recipe now.
recipe=dict(status='ROOT_DEPLOYMENT_TRANSPORT_RECIPE_NOT_EXECUTED',descriptor=dict(path=bp,sha256=a.descriptor_sha256),partition=dict(GD=18,JSON=14,total=32),GD='Root apply_patch only',Router='restore_Router13CRLF_after_apply_patch_ROOT_ONLY.py requires full normalized LF equality and exact E983 final SHA',JSON='Root exact14 byte-copy after all18 GD hashes equal candidates, old14 JSON exact immutable parents, all32 backup unchanged',native_registry_geometry='No canonical native/geometry/PNG changes; new local payload and imported mask ordinary sources only',canonical_writes=0,Stage_calls=0,engine_calls=0)
p=N/'docks_gallery_family_repair01/deployment_transport_recipe_NOT_EXECUTED.json';assert not p.exists()
with p.open('xb')as f:f.write((json.dumps(recipe,indent=2)+'\n').encode())
