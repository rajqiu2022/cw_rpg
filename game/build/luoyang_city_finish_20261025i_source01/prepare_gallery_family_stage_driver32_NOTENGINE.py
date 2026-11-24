"""Mechanical thin driver adaptation only; never Stage.run."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/'
parent=(N/'stage_gate_portal_repair31_ROOT_ONLY.py').read_bytes();t=parent.decode();changes=[]
def change(a,b):
 global t
 assert t.count(a)==1,(a[:80],t.count(a));t=t.replace(a,b,1);changes.append(dict(old=a,new=b))
change('class Repair31(M.Stage):','class GalleryFamily32(M.Stage):')
change('need,same,sha,enc,res=M.need,M.same,M.digest,M.encode,M.res',"M.AUTHORITY_SHA='f120512a771d7e3e482b5befac0f39d44fb0abf794be0805fcd0fe4e638bb5bc'\nM.EXACT_EOL_CANDIDATES={'res://scripts/autoload/scene_router.gd':('e983a3b2b8c3cc031262100755c1f9e2f37c03a618d1a0a4cf268f8c6ccd3745',13)}\nneed,same,sha,enc,res=M.need,M.same,M.digest,M.encode,M.res")
start=t.index("  need(self.scope['count']==len(self.parents)==31");end=t.index('  prior=json.loads',start)
change(t[start:end],"""  need(self.scope['count']==len(self.parents)==32 and self.scope['partition']==dict(GD=18,JSON=14),'EXACT32_18GD14JSON_SCOPE')
  need(self.backup['status']=='ROOT_CURRENT_AUTHORITY20_FULL32_BACKUP_AND_FRESH_OBSERVATION'and self.backup['passed']is True and self.backup['total_backups']==317 and self.backup['external_save_changes']==[]and self.backup['canonical_writes']==0 and self.backup['scope']['sha256']==self.inputs['scope']['sha256'],'ROOT_ACTUAL_CURRENT_AUTHORITY20_BACKUP32')
  rows=self.backup['new_backups'];need(len(rows)==32 and {r['target']for r in rows}==set(self.parents),'ROOT_BACKUP32_EXACT_DOMAIN')
  need(len(self.backup['current33'])==33,'CURRENT33_NOOP_G_AUTHORITY_PRESERVED')
  for r in self.backup['current33']:need(len(self.read(r['target'],r['sha256']))==r['bytes'],'CURRENT33_IMMUTABLE_PARENT')
  for r in rows:
   p=r['target'];parent=self.parents[p];need(r['backup'].startswith(PREFIX+'docks_gallery_family_repair01/root_only_current32_backup/'),'ROOT_BACKUP32_FIXED_NAMESPACE')
   need(self.read(r['backup'],r['sha256'])==self.read(parent['immutable_old'],parent['old_sha256'])==self.read(p,parent['old_sha256']) and r['sha256']==parent['old_sha256'] and r['bytes']==parent['old_bytes'],'ROOT_FULL_BACKUP32_WHOLE_CURRENT_IMMUTABLE')
""")
change(' def checked_candidate(self,p,r):',""" def approved(self,path,historical):
  # Exact finite F120 traversal, not old range16. Core already validated every edge.
  row=self.authority.get('owned',{}).get(path)
  if row is None:return False
  current=row['current_sha256']
  if current==historical:return True
  frontier,visited=[current],set()
  for _ in range(len(row['edges'])):
   if not frontier:return False
   following=[]
   for h in frontier:
    if h in visited:continue
    visited.add(h)
    for edge in row['edges']:
     if edge['new_sha256']!=h:continue
     if edge['old_sha256']==historical:return True
     following.append(edge['old_sha256'])
   frontier=following
  return False
 def checked_candidate(self,p,r):""")
for a,b in [
 ("len(prior['source_sha256'])==183 and len(self.authority['source_sha256'])==189,'OWNED10_183_PLUS6'","len(prior['source_sha256'])==195 and len(self.authority['source_sha256'])==202,'OWNED10_195_PLUS7'"),
 ("len(changed)==4,'ONLY_FOUR_REAL_OWNED_EDGES'","len(changed)==5,'ONLY_FIVE_REAL_OWNED_EDGES'"),
 ("'OTHER_SIX_OWNED_IDENTICAL'","'OTHER_FIVE_OWNED_IDENTICAL'"),
 ('len(extra)==6 and all','len(extra)==7 and all'),("'ALL_OLD183_FIXED_SIX_NEW'","'ALL_OLD195_FIXED_SEVEN_NEW'"),
 ("len(self.targets)==31,'EXACT31_NO_NOOP_TARGETS'","len(self.targets)==32,'EXACT32_NO_NOOP_TARGETS'"),
 ("'PINNED_CURRENT4160_MAP_PARENT'","'PINNED_CURRENT_AUTHORITY20_MAP_PARENT'"),
 ('M._strict_lf_build_file_patch(res(p).as_posix(),before,after)','M.build_file_patch(res(p).as_posix(),before,after)'),
 ("len(reconstruction)==31,'EXACT17_GD_PATCH14_JSON_COPY'","len(reconstruction)==32,'EXACT18_GD_PATCH14_JSON_COPY'"),
 ("status='GATE_TEXTURE_MARKET_PORTAL_EXACT31_STAGED_NOT_DEPLOYED'","status='GALLERY_FAMILY_ROUTER_EXACT32_STAGED_NOT_DEPLOYED'"),
 ('dict(patch_count=17,copy_count=14,total=31)','dict(patch_count=18,copy_count=14,total=32)'),
 ('Pinned current4160/37D7 exact increment. Old OWNED10/proof183 retained+6, depth16, no shortcut. No old AO repromotion. Geometry/masks unchanged.','Pinned authority20/1BC99 increment. All OWNED10/old195 proof values and edges preserved+7. F120 bounded registered edges/visited. No shortcut. Only gallery/four posts local delta, ferry contract, exact3 Router and strict Family cold abort.'),
 ('targets=31,map_nodes=4','targets=32,map_nodes=4'),('Repair31(spec).run()','GalleryFamily32(spec).run()')]:change(a,b)
reverse=t
for h in reversed(changes):assert reverse.count(h['new'])==1;reverse=reverse.replace(h['new'],h['old'],1)
assert reverse.encode()==parent;compile(t,'stage_gallery_family32_ROOT_ONLY.py','exec')
def sha(b):return hashlib.sha256(b).hexdigest()
child=t.encode();proof=dict(status='THIN_DRIVER_EXACT32_AUTHORITY20_REGISTERED_EDGE_BOUND_AND_ROUTER_TRANSPORT_SUCCESSOR',parent_sha256=sha(parent),candidate_sha256=sha(child),hunks=changes,whole_byte_inverse=True,core_sha256='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28',all_original_edge_byte_validation_and_five_gates=True,authority_F120_bound_not_raised_constant=True,Router_only_exact_E983_13CRLF_transport=True,Stage_calls=0,engine_calls=0,canonical_writes=0)
for file,b in [('stage_gallery_family32_ROOT_ONLY.py',child),('docks_gallery_family_repair01/Stage32_driver_full_inverse_NOT_STAGE.json',(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode())]:
 p=N/file;assert not p.exists()
 with p.open('xb')as f:f.write(b)
 print(file,sha(b),len(b))
