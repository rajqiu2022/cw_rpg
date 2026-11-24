"""Root-only read-only bounded final guard. No engine, saves, broad collector or writes.
Prints one JSON result to stdout; Root may capture stdout in its evidence folder.
"""
from pathlib import Path
import json,hashlib,difflib
TASK=Path(__file__).resolve().parent;GAME=TASK.parents[1];REPO=GAME.parent
ROOT=GAME/'build/scene_quality_20261102c_root01'
checks=[];errors=[]
def need(v,s):
 checks.append(str(s))
 if not v:errors.append(str(s))
 return bool(v)
def sha(b):return hashlib.sha256(b).hexdigest()
def path(p):
 if p.startswith('res://'):return GAME/p[6:]
 if p.startswith('game/'):return REPO/p
 raise ValueError('Explicit resource/repository path required: '+p)
def read(p):return path(p).read_bytes()
def decode(p):return json.loads(read(p))
def inv(child,hunks):
 b=child
 for h in reversed(hunks):
  at=int(h['new_offset']);new=h['new'].encode();old=h['old'].encode()
  if not need(b[at:at+len(new)]==new,'EXACT_INVERSE_SLICE:'+str(at)):return b''
  b=b[:at]+old+b[at+len(new):]
 return b
def literal_inverse(old,new,changes,label):
 inverse=new
 for a,b in reversed(changes):
  if not need(inverse.count(b.encode())==1,label+':ONE_LITERAL'):return
  inverse=inverse.replace(b.encode(),a.encode(),1)
 need(inverse==old,label+':WHOLE_INVERSE')
def compute_hunks(old,new):
 aa=old.decode().splitlines(keepends=True);bb=new.decode().splitlines(keepends=True);out=[]
 for op,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
  if op!='equal':out.append({'new_offset':len(''.join(bb[:k]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:l])})
 return out
latest={};stage_counts={};stage_chain=[]
def accept_stage(label,receipt_path,before_fn,hunk_fn):
 r=decode(receipt_path);rows=r['targets'];stage_counts[label]=len(rows)
 for t in rows:
  target=t['target'];target='res://'+target[5:]if target.startswith('game/')else target
  old=before_fn(t);new=read(t['candidate']);hs=hunk_fn(t)
  need(sha(old)==t['old_sha256'],label+':EXACT_BEFORE:'+target)
  need(sha(new)==t['new_sha256'],label+':EXACT_CANDIDATE:'+target)
  need(inv(new,hs)==old,label+':WHOLE_BYTES_INVERSE:'+target)
  if target in latest:need(latest[target]['sha256']==sha(old),label+':PREVIOUS_ADOPTED_STAGE_LINK:'+target)
  latest[target]={'sha256':sha(new),'bytes':len(new),'stage':label}
 stage_chain.append({'stage':label,'receipt':receipt_path,'receipt_sha256':sha(read(receipt_path))})
try:
 navpath='res://build/city_navigation_20261101d_candidate01/source_pins_READY.json'
 artpath='res://build/luoyang_quality_20261101b_runtime01/source_pins_READY.json'
 navraw=read(navpath);artraw=read(artpath);nav=json.loads(navraw);art=json.loads(artraw)
 need(sha(navraw)=='b5a685ad8a50553e2458a5e766abe75df1988d01cbe43259db4151df9e5edd29','FINAL_NAV_B5A685AD')
 need(sha(artraw)=='2860ddeacbe2966bf3c1b39beb58d8e8c1fdf725b13844fe4e5f46ccc6531d26','FINAL_ART2860')
 need(len(nav['source_pins'])==102 and len(art['source_pins'])==60,'EXACT_102_AND60')
 union=dict(nav['source_pins'])
 for p,h in art['source_pins'].items():
  need(p not in union or union[p]==h,'SHARED_PIN_EQUAL:'+p);union[p]=h
 need(len(union)==146,'FINITE_UNIQUE146_WITH_PROJECT')
 first={p:sha(read(p))for p in sorted(union)if p!='res://project.godot'}
 need(len(first)==145,'FINITE_UNIQUE145_NONPROJECT')
 for p,h in first.items():need(h==union[p],'EXACT_RUNTIME_PIN:'+p)
 for p,h in nav['source_pins'].items():need(nav['source_facts'].get(p)=={'sha256':h,'bytes':len(read(p))},'NAV_EXACT_SOURCE_FACT:'+p)
 project=read('res://project.godot');baseline=(ROOT/'project.before.godot').read_bytes()
 owned=[b'MapIconRuntime="*res://build/minimap_icons_20261102c_runtime01/map_icon_runtime.gd"',b'PCSpriteViewRuntime="*res://build/pc_sprite_view_20261102c_runtime01/pc_sprite_view_runtime.gd"']
 lines=project.splitlines(keepends=True)
 for line in owned:need(sum(x.rstrip(b'\r\n')==line for x in lines)==1,'EXACT_SINGLE_AUTOLOAD:'+line.decode())
 inverse=b''.join(x for x in lines if x.rstrip(b'\r\n')not in owned)
 need(inverse==baseline,'PROJECT_EXACT_TWO_AUTOLOAD_LINES_WHOLE_INVERSE')
 # Initial39 uses the exact Root before tree and its generated positional hunks.
 initial='res://build/scene_cleanup_20261102c_system01/closure_READY01/receipt_READY.json'
 hm=decode('res://build/scene_cleanup_20261102c_system01/closure_READY01/all_source_hunks_READY.json')
 hmap={r['target']:r['byte_offset_hunks']for r in hm}
 accept_stage('cleanup39',initial,lambda t:(ROOT/'before'/t['target']).read_bytes(),lambda t:hmap[t['target']])
 for label,folder in [('legal_prefix21','luoyang_scene_cleanup_20261102c_source01'),('material23','luoyang_scene_cleanup_20261102c_material02')]:
  receipt='res://build/'+folder+'/receipt_READY.json'
  accept_stage(label,receipt,lambda t,folder=folder:read('res://build/'+folder+'/before/'+t['target'][5:].replace('/','__')),lambda t:t['hunks'])
 ground=decode('res://build/scene_cleanup_20261102c_system01/ground_count_successor_READY.json')
 gp='res://'+ground['target'][5:];gnew=read('res://'+ground['candidate'][5:]);gold=(ROOT/'before/ground_visual.gd').read_bytes()
 need(sha(gold)==ground['old_sha256']and sha(gnew)==ground['new_sha256'],'GROUND_EXACT_OLD_NEW')
 literal_inverse(gold,gnew,[(ground['old'],ground['new'])],'GROUND_STRICT21_TO22');latest[gp]={'sha256':sha(gnew),'bytes':len(gnew),'stage':'ground1'};stage_counts['ground1']=1
 accept_stage('Art_freeze3','res://build/scene_cleanup_20261102c_system01/freeze_after_READY01/receipt.json',lambda t:read(t['archive']),lambda t:t['hunks'])
 # Performance source freeze successors each preserve the102 key set and only
 # the explicitly reviewed Screen/Runtime values and byte facts change.
 perf=GAME/'build/transition_latency_20261102c_candidate01'
 stages=[('hide',perf/'hide_barrier_successor_receipt.json',ROOT/'source_pins_D7BA_before.json',perf/'source_pins_hide_barrier_READY.json'),('trace',perf/'trace_successor_receipt.json',ROOT/'source_pins_D282_before.json',perf/'source_pins_TRACE_READY.json'),('install',perf/'install_successor_receipt.json',perf/'before_install/source_pins_C709403F.json.txt',perf/'source_pins_INSTALL_READY.json')]
 for label,rp,op,np in stages:
  r=json.loads(rp.read_bytes());old=op.read_bytes();new=np.read_bytes()
  need(sha(old)==r['parent_manifest_sha256']and sha(new)==r['candidate_manifest_sha256'],'PERF_'+label+':EXACT_MANIFEST_CHAIN')
  a=json.loads(old);b=json.loads(new);changed={p for p in a['source_pins']if a['source_pins'][p]!=b['source_pins'].get(p)}
  expected={e['target']for e in r['changed_leaves']}if 'changed_leaves'in r else {r.get('changed_leaf',r.get('target_leaf'))}
  need(set(a['source_pins'])==set(b['source_pins'])and changed==expected,'PERF_'+label+':EXACT_DECLARED_PIN_SET')
  undo=json.loads(new);undo['source_pins']=a['source_pins'];undo['source_facts']=a['source_facts'];need(undo==a,'PERF_'+label+':OTHER_FIELDS_TYPED_IDENTICAL')
  need(inv(new,compute_hunks(old,new))==old,'PERF_'+label+':WHOLE_MANIFEST_INVERSE')
  need(latest[navpath]['sha256']==sha(old),'PERF_'+label+':LATEST_NAV_LINK');latest[navpath]={'sha256':sha(new),'bytes':len(new),'stage':'perf_'+label}
 # Both intermediate Screen revisions are still exact immutable failure history.
 for label,rp,op,np in [('hide',perf/'hide_barrier_successor_receipt.json',ROOT/'loading_screen_8335_before.gd.txt',ROOT/'loading_screen_82D6_before.gd.txt'),('trace',perf/'trace_successor_receipt.json',ROOT/'loading_screen_82D6_before.gd.txt',perf/'loading_screen_barrier_TRACE_READY.gd')]:
  r=json.loads(rp.read_bytes());old=op.read_bytes();new=np.read_bytes()
  need(sha(old)==r['old_sha256']and sha(new)==r['new_sha256'],'PERF_'+label+':EXACT_SCREEN_HISTORY')
  need(inv(new,compute_hunks(old,new))==old,'PERF_'+label+':WHOLE_SCREEN_INVERSE')
 old_runtime=(ROOT/'before/city_navigation_runtime.gd').read_bytes();first_runtime=(perf/'city_navigation_runtime_READY.gd').read_bytes()
 need(sha(first_runtime)=='c8f5bb8ad51de0fbcdb6377ace99889c090eb3d87fcda7474560bf9dd3695a49','FIRST_REVIEWED_C8F5_RUNTIME')
 need(inv(first_runtime,compute_hunks(old_runtime,first_runtime))==old_runtime,'ORIGINAL_RUNTIME_TO_C8F5_WHOLE_INVERSE')
 # Exact final executable candidates and their fully archived parents.
 install=json.loads((perf/'install_successor_receipt.json').read_bytes())
 for e in install['changed_leaves']:
  oldname='city_navigation_runtime_C8F5BB8A.gd.txt'if 'city_navigation_runtime' in e['target']else 'loading_screen_barrier_45525845.gd.txt'
  old=(perf/'before_install'/oldname).read_bytes();new=(perf/e['candidate']).read_bytes()
  need(sha(old)==e['old_sha256']and sha(new)==e['new_sha256'],'PERF_INSTALL_EXACT_EXECUTABLE:'+e['target'])
  need(inv(new,compute_hunks(old,new))==old,'PERF_INSTALL_WHOLE_EXECUTABLE_INVERSE:'+e['target'])
  latest[e['target']]={'sha256':sha(new),'bytes':len(new),'stage':'perf_install'}
 for p,r in latest.items():need(sha(read(p))==r['sha256']and len(read(p))==r['bytes'],'LATEST_ADOPTED_TARGET:'+p)
 publication=decode('res://build/scene_cleanup_20261102c_system01/output/140404/result.json')
 owners=[o for r in publication['records'].values()for o in r['retired_owners']]
 solid_count=sum(len(o['solid_indices'])for o in owners)
 need(publication['passed']and len(publication['records'])==6 and len(owners)==28 and solid_count==27,'ACTUAL_SIX_BUNDLE_28VISUAL27SOLIDS')
 need(all(r['whole_typed_inverse']for r in publication['records'].values()),'ACTUAL_SIX_FULL_TYPED_INVERSES')
 need(all(r.get('whole_RGBA_inverse')is True for r in publication['records'].values()if r['kind']=='LEGACY'),'ACTUAL_THREE_WHOLE_RGBA_INVERSES')
 for sid,r in publication['records'].items():
  need(sha(read(r['payload']['path']))==r['payload']['sha256'],'ACTUAL_IMMUTABLE_PAYLOAD:'+sid)
  if r['kind']=='LEGACY':need(sha(read(r['mask']['path']))==r['mask']['sha256'],'ACTUAL_IMMUTABLE_NAV:'+sid)
 last={p:sha(read(p))for p in first};need(first==last,'FINITE145_SOURCE_FIRST_FINAL')
 need(read('res://project.godot')==project,'PROJECT_FIRST_FINAL')
 print(json.dumps({'passed':not errors,'checks':len(checks),'errors':errors,'scope':'Finite current102+60 source pins and exact staged successors only; no broad collector/save/engine','unique_pin_count':146,'unique_nonproject_files':145,'stage_target_counts':stage_counts,'latest_unique_targets':len(latest),'project_two_line_whole_inverse':inverse==baseline,'deleted_visual_owners':len(owners),'deleted_solids':solid_count,'whole_typed_bundle_count':6,'whole_RGBA_mask_count':3,'current_nav_manifest_sha256':sha(navraw),'current_art_manifest_sha256':sha(artraw),'finite_first_final':first==last,'engine_runs':0,'save_content_reads':0,'save_writes':0,'canonical_writes':0},ensure_ascii=False))
except Exception as e:
 print(json.dumps({'passed':False,'checks':len(checks),'errors':errors+[type(e).__name__+': '+str(e)],'engine_runs':0,'save_content_reads':0,'canonical_writes':0},ensure_ascii=False))
 raise
