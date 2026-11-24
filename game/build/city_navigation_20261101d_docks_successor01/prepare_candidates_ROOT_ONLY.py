"""Offline finite ordinary-source successors. NEW outputs only; no engine/canonical writes."""
from pathlib import Path
import copy,difflib,hashlib,json
GAME=Path(__file__).resolve().parents[2]
TASK=GAME/'build/luoyang_navigation_docks_20261101d_successor02'
PREFIX='res://'+TASK.relative_to(GAME).as_posix()+'/'
AA='res://scripts/city/luoyang_docks_district08_20261019aa.gd'
AC='res://scripts/city/luoyang_docks_workyard_20261019ac.gd'
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'
EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
EI='res://scripts/city/luoyang_execution_index_20261022ap.gd'
ACM='res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json'
def need(v,s):
 if not v:raise ValueError(s)
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p):return (GAME/p.removeprefix('res://')).read_bytes()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def once(b,o,n):
 o=o.encode()if isinstance(o,str)else o;n=n.encode()if isinstance(n,str)else n
 need(b.count(o)==1,('NONUNIQUE',o[:120],b.count(o)));return b.replace(o,n,1)
def hunks(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True);out=[]
 for op,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
  if op!='equal':out.append({'old_offset':len(''.join(aa[:i]).encode()),'new_offset':len(''.join(bb[:k]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:l])})
 x=a
 for h in reversed(out):
  at=h['old_offset'];old=h['old'].encode();need(x[at:at+len(old)]==old,'EXACT_FORWARD_SLICE');x=x[:at]+h['new'].encode()+x[at+len(old):]
 need(x==b,'WHOLE_FORWARD')
 for h in reversed(out):
  at=h['new_offset'];new=h['new'].encode();need(x[at:at+len(new)]==new,'EXACT_INVERSE_SLICE');x=x[:at]+h['old'].encode()+x[at+len(new):]
 need(x==a,'WHOLE_BYTE_INVERSE');return out
scope=json.loads(read('res://build/luoyang_gate_front_walls_20261101c_system01/capture_targets_READY.json'))
paths=['res://'+r['target'].removeprefix('game/')for r in scope['targets']]
need(len(paths)==33 and AA in paths and AC in paths,'EXISTING_FINITE33_DOMAIN')
before={p:read(p)for p in paths};oldsha={p:sha(b)for p,b in before.items()};after={};outputs={}
need(oldsha[C]=='7ec013fe42f6286bfed4bbd9b9256cc944b2fe78117aa9c73dabc2fc777105b7','CURRENT_FORMAL_C')
need(oldsha[AA]=='fe1d8be0a6a6625697d8d5260c4a9821d468cf0780de6f62906b35b4b15c5f40','FIXED_AA_PARENT')
need(sha(before[ACM])=='387cebde15621e37170966ad0284a4f81f2e97ea1ba9aa70e112bf0b10c657ec','ACTUAL_SELECTED_AC_MANIFEST')
def output(name,b):
 need(name not in outputs or outputs[name]==b,('OUTPUT_CONFLICT',name));outputs[name]=b;return PREFIX+name
# Use the immutable fixed29m snapshot, not an inferred single-change baseline.
# Later approved World16/Region source admission remains current production C;
# only historical ordinary-source proof bytes are reconstructed in memory.
c_old=read('res://build/luoyang_gate_short_walls_20261029m_system01/closure_READY01/luoyang_enclosure_v11_candidate_contract.gd')
need(sha(c_old)=='f1c8da74c69bf6660b2d9c9637b54e15d2679dfa7a2d75b1e0ed3f48a25374ab','C_EXACT_FIXED_FINISH_PARENT')
def proof(name,path,parent,child):
 h=hunks(parent,child)
 value={'schema':'CITYNAV_20261101D_FIXED_ORDINARY_WHOLEBYTE_LAYER_V1','path':path,'parent_sha256':sha(parent),'current_sha256':sha(child),'whole_inverse_exact':True,'hunks':h}
 p=output(name,enc(value));return p,sha(outputs[name])
cp,csha=proof('C_11c_to_fixed_FINISH_C_inverse_READY.json',C,c_old,before[C])
def layer_function(tag,path_constant,current_hash,parent_hash,proof_path,proof_hash):
 return f'''\nconst CITYNAV_{tag}_CURRENT_SHA := "{current_hash}"
const CITYNAV_{tag}_PARENT_SHA := "{parent_hash}"
const CITYNAV_{tag}_PROOF := "{proof_path}"
const CITYNAV_{tag}_PROOF_SHA := "{proof_hash}"
static func _citynav_{tag.lower()}_fixed_parent_bytes() -> PackedByteArray:
\t# Ordinary fixed predecessor only. Original older layers and author checks remain.
\tif FileAccess.get_sha256({path_constant})!=CITYNAV_{tag}_CURRENT_SHA or FileAccess.get_sha256(CITYNAV_{tag}_PROOF)!=CITYNAV_{tag}_PROOF_SHA: return PackedByteArray()
\tvar layer: Variant=JSON.parse_string(FileAccess.get_file_as_string(CITYNAV_{tag}_PROOF))
\tif not layer is Dictionary or layer.get("schema")!="CITYNAV_20261101D_FIXED_ORDINARY_WHOLEBYTE_LAYER_V1" or layer.get("path")!={path_constant} or layer.get("current_sha256")!=CITYNAV_{tag}_CURRENT_SHA or layer.get("parent_sha256")!=CITYNAV_{tag}_PARENT_SHA or layer.get("whole_inverse_exact")!=true or not layer.get("hunks") is Array or layer.hunks.is_empty(): return PackedByteArray()
\tvar bytes: PackedByteArray=FileAccess.get_file_as_bytes({path_constant})
\tif b().bytes_sha(bytes)!=CITYNAV_{tag}_CURRENT_SHA: return PackedByteArray()
\tfor index: int in range(layer.hunks.size()-1,-1,-1):
\t\tvar row: Variant=layer.hunks[index]
\t\tif not row is Dictionary or not row.get("new_offset") is float or not row.get("old") is String or not row.get("new") is String: return PackedByteArray()
\t\tvar start: int=int(row.new_offset)
\t\tvar native_new: PackedByteArray=String(row.new).to_utf8_buffer()
\t\tif start<0 or start+native_new.size()>bytes.size() or bytes.slice(start,start+native_new.size())!=native_new: return PackedByteArray()
\t\tbytes=bytes.slice(0,start)+String(row.old).to_utf8_buffer()+bytes.slice(start+native_new.size())
\treturn bytes if b().bytes_sha(bytes)==CITYNAV_{tag}_PARENT_SHA else PackedByteArray()
'''
aa=before[AA]
need(aa.count(b'FileAccess.get_sha256(ORDINARY_C_PATH)!=FINISH_C_SHA')==4,'AA_FOUR_EXISTING_FIXED_GATES')
aa=aa.replace(b'FileAccess.get_sha256(ORDINARY_C_PATH)!=FINISH_C_SHA',b'b().bytes_sha(_citynav_c_fixed_parent_bytes())!=FINISH_C_SHA')
aa=once(aa,'var bytes: PackedByteArray=FileAccess.get_file_as_bytes(ORDINARY_C_PATH)','var bytes: PackedByteArray=_citynav_c_fixed_parent_bytes()')
aa=once(aa,'var paths: Dictionary={SELF:true,INDEX:true,AUTHOR:true,ORDINARY_C_PROOF:true,ORDINARY_C_CURRENT_PROOF:true,ORDINARY_C_OUTER_PROOF:true,FINISH_C_PROOF:true}',
 'var paths: Dictionary={SELF:true,INDEX:true,AUTHOR:true,ORDINARY_C_PROOF:true,ORDINARY_C_CURRENT_PROOF:true,ORDINARY_C_OUTER_PROOF:true,FINISH_C_PROOF:true,CITYNAV_C_PROOF:true}')
aa+=layer_function('C','ORDINARY_C_PATH',oldsha[C],sha(c_old),cp,csha).encode();after[AA]=aa
ap,asha=proof('AA_11d_to_fixed_FINISH_AA_inverse_READY.json',AA,before[AA],aa)
ac=before[AC]
need(ac.count(b'FileAccess.get_sha256(ORDINARY_AA_PATH)!=FINISH_AA_SHA')==5,'AC_FIVE_EXISTING_FIXED_GATES')
ac=ac.replace(b'FileAccess.get_sha256(ORDINARY_AA_PATH)!=FINISH_AA_SHA',b'b().bytes_sha(_citynav_aa_fixed_parent_bytes())!=FINISH_AA_SHA')
ac=once(ac,'var bytes: PackedByteArray=FileAccess.get_file_as_bytes(ORDINARY_AA_PATH)','var bytes: PackedByteArray=_citynav_aa_fixed_parent_bytes()')
ac=once(ac,'var result: Dictionary={SELF:true,AUTHOR:true,ORDINARY_AA_PROOF:true,ORDINARY_AA_CURRENT_PROOF:true,ORDINARY_AA_OUTER_PROOF:true,FINISH_AA_PROOF:true}',
 'var result: Dictionary={SELF:true,AUTHOR:true,ORDINARY_AA_PROOF:true,ORDINARY_AA_CURRENT_PROOF:true,ORDINARY_AA_OUTER_PROOF:true,FINISH_AA_PROOF:true,CITYNAV_AA_PROOF:true}')
ac+=layer_function('AA','ORDINARY_AA_PATH',sha(aa),oldsha[AA],ap,asha).encode();after[AC]=ac
ac_snapshot=output('luoyang_docks_workyard_CANDIDATE.gd',ac)
extra={cp:csha,ap:asha,ac_snapshot:sha(ac)}
# Existing AC owner only. Never expand OWNED or mutate any Router approved edge.
ex=json.loads(before[EX]);ex_old=copy.deepcopy(ex);owned=ex['owned'][AC]
need(owned['current_sha256']==oldsha[AC],'CURRENT_AC_OWNED_EDGE')
old_snapshot=next(e['new_snapshot']for e in reversed(owned['edges'])if e['new_sha256']==oldsha[AC])
need(sha(read(old_snapshot))==oldsha[AC],'FIXED_AC_PREDECESSOR_SNAPSHOT')
line_hunks=[]
left=before[AC].decode().splitlines(keepends=True);right=ac.decode().splitlines(keepends=True)
for op,i,j,k,l in difflib.SequenceMatcher(None,left,right,autojunk=False).get_opcodes():
 if op=='equal':continue
 start=max(0,i-1);end=min(len(left),j+1)
 line_hunks.append({'old':''.join(left[start:end]),'new':''.join(left[start:i])+''.join(right[k:l])+''.join(left[j:end])})
# Existing EX inverse uses unique text replacements; prove those too.
replay=before[AC]
for h in line_hunks:replay=once(replay,h['old'],h['new'])
need(replay==ac,'EX_AC_UNIQUE_REPLACEMENTS_WHOLE_FORWARD')
inverse=ac
for h in line_hunks:inverse=once(inverse,h['new'],h['old'])
need(inverse==before[AC],'EX_AC_UNIQUE_REPLACEMENTS_WHOLE_INVERSE')
owned['current_sha256']=sha(ac);owned['edges'].append({'path':AC,'old_sha256':oldsha[AC],'new_sha256':sha(ac),'old_snapshot':old_snapshot,'new_snapshot':ac_snapshot,'whole_inverse':True,'replacements':line_hunks})
need(set(ex['owned'])==set(ex_old['owned']) and ex['owned']['res://scripts/autoload/scene_router.gd']==ex_old['owned']['res://scripts/autoload/scene_router.gd'],'OWNED_KEYS_AND_ROUTER_CHAIN_EXACT')
def replace_json_value(raw,key,value):
 text=raw.decode();marker='    '+json.dumps(key)+': ';start=text.index(marker);at=start+len(marker);_,count=json.JSONDecoder().raw_decode(text[at:])
 lines=json.dumps(value,ensure_ascii=False,indent=2).splitlines();new=marker+lines[0]+'\n'+'\n'.join('    '+line for line in lines[1:])
 return (text[:start]+new+text[at+count:]).encode()
def edit_top_map(raw,key,edit):
 text=raw.decode();marker='  '+json.dumps(key)+': ';at=text.index(marker)+len(marker);value,count=json.JSONDecoder().raw_decode(text[at:])
 need(isinstance(value,dict),('TOP_MAP',key));old=text[at:at+count];new=edit(old,value)
 return (text[:at]+new+text[at+count:]).encode()
after[EX]=replace_json_value(before[EX],AC,owned)
# Complete selected AC expected source hashes are repaired only at four proven
# stale literal edges. No unrelated historical bundle/layout fields are changed.
acm=json.loads(before[ACM]);raw=before[ACM];mismatch=[]
for p,h in acm['legacy_source_sha256'].items():
 actual=sha(read(p))
 if h!=actual:
  mismatch.append({'path':p,'old':h,'new':actual})
  raw=edit_top_map(raw,'legacy_source_sha256',lambda text,value,p=p,h=h,actual=actual:once(text.encode(),'"'+p+'": "'+h+'"','"'+p+'": "'+actual+'"').decode())
need({r['path']for r in mismatch}=={'res://data/maps/linxi_farmer_cottage_layout_v1.tres','res://build/luoyang_regions_20261027d_source01/region_field.gd','res://build/luoyang_regions_20261027d_source01/region_entry.gd','res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'},'EXACT_FOUR_SELECTED_AC_STALE_SOURCE_EDGES')
after[ACM]=raw
def map_update(raw,known,add=False):
 value=json.loads(raw)
 addition_key='legacy_source_sha256'if'legacy_source_sha256'in value else'source_sha256'
 for key in ('source_sha256','legacy_source_sha256','runtime_authority_sha256'):
  if not isinstance(value.get(key),dict):continue
  def edit(text,m):
   for p,h in m.items():
    if p in known and p in oldsha and h==oldsha[p] and h!=known[p]:text=once(text.encode(),'"'+p+'": "'+h+'"','"'+p+'": "'+known[p]+'"').decode()
   if add and key==addition_key:
    end=text.rfind('\n  }');need(end>=0,'TOP_MAP_CLOSING_INDENT')
    text=text[:end]+''.join(',\n    '+json.dumps(p)+': '+json.dumps(h)for p,h in extra.items()if p not in m)+text[end:]
   return text
  raw=edit_top_map(raw,key,edit)
 return raw
# Propagate only real exact dependencies within the already-declared33 domain.
# Already-frozen base Region sources and the ten bins are never targets.
metadata=[p for p in paths if p.endswith('.json')]
need(not any(p in after for p in ['res://scripts/field/field_walkable_controller.gd',C]),'C_AND_FIELD_IMMUTABLE')
after[EX]=map_update(after[EX],{p:sha(b)for p,b in after.items()},True)
after[EI]=once(before[EI],oldsha[EX],sha(after[EX]))
known={p:sha(b)for p,b in after.items()}
pending=[p for p in paths if p not in (AA,AC,EX,EI)]
def deps(p):return {q for q,h in oldsha.items()if p!=q and h.encode()in before[p]}
for _ in range(33):
 progress=False
 for p in list(pending):
  if any(q in pending for q in deps(p)):continue
  raw=after.get(p,before[p])
  if p.endswith('.json'):
   obj=json.loads(raw);top=obj.get('legacy_source_sha256',obj.get('source_sha256',{}))
   raw=map_update(raw,known,AA in top or AC in top or EX in top)
  else:
   for q,h in known.items():
    if oldsha[q]!=h and oldsha[q].encode()in raw:raw=once(raw,oldsha[q],h)
  if raw!=before[p]:after[p]=raw;known[p]=sha(raw)
  pending.remove(p);progress=True
 if not pending:break
 need(progress,('BOUNDED_DEPENDENCY_CYCLE',pending))
need(not pending,'BOUNDED_CLOSURE_COMPLETE')
# Exact finite control membership; no fresh capture or save-metadata scan here.
pins96=json.loads(read('res://build/city_navigation_20261101d_candidate01/source_pins_READY.json'))['source_pins']
capture=json.loads(read('res://build/city_navigation_20261101d_guard01/capture_before_ACTUAL.json'))
base113=set(capture['before_facts'])
rows=[];all_hunks=[]
for p,b in after.items():
 name=p.removeprefix('res://').replace('/','__');candidate=output(name,b)
 rows.append({'path':'game/'+p[6:],'res_path':p,'candidate':candidate,'before_sha256':oldsha[p],'before_bytes':len(before[p]),'after_sha256':sha(b),'after_bytes':len(b),'in_frozen96':p in pins96,'in_original113':p in base113,'reason':'ordinary fixed-parent byte-inverse layer'if p in(AA,AC)else('append one existing AC owned edge; Router row/OWNED keys unchanged'if p==EX else('selected AC exact four stale pins + mechanical source successor'if p==ACM else'precise existing-source-map/index successor only'))})
 all_hunks.append({'target':'game/'+p[6:],'whole_byte_inverse':True,'hunks':hunks(before[p],b)})
need(not set(after)&set(pins96),'NO_96_FROZEN_SOURCE_CHANGED')
for p in before:need(read(p)==before[p],('CANONICAL_FINAL_UNCHANGED',p))
report={'schema':'CITYNAV_DOCKS_20261101D_OFFLINE_CANDIDATE_CLOSURE_V1','canonical_writes':0,'engine_runs':0,'save_metadata_reads':0,'finite_potential_domain_count':33,'actual_targets':rows,'new_runtime_sources':extra,'C_fixed_parent_sha256':sha(c_old),'C_current_sha256':oldsha[C],'selected_AC_original_stale_edges':mismatch,'AA_old_author_JSON_and_all_old_proofs_unchanged':True,'AC_old_author_JSON_and_all_old_proofs_unchanged':True,'OWNED_key_set_and_full_Router_row_identical':True,'frozen96_unchanged':True,'original113_membership_from_existing_capture_only':True,'actual_C_collector_after_patch_not_executed':True,'requires_Root_review_fresh_capture_and_only_then_apply':True}
output('candidate_closure_READY.json',enc(report));output('all_source_hunks_READY.json',enc(all_hunks))
need(all(not(TASK/name).exists()for name in outputs),'EXCLUSIVE_NEW_OUTPUTS')
for name,b in outputs.items():
 with(TASK/name).open('xb')as f:f.write(b)
print(json.dumps({'targets':len(rows),'new_runtime_sources':len(extra),'frozen96_overlap':[],'in113':[r['path']for r in rows if r['in_original113']],'report_sha256':sha(outputs['candidate_closure_READY.json'])},indent=2))
