"""Exact new small source layers; original C2/AA3 historical inverse gates retained."""
from pathlib import Path
import json,hashlib
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_revision_20261024c_source01/';Y='res://build/luoyang_yamen_courts_20261024c_system01/runtime02/';D='res://build/luoyang_docks_ordinary_space_20261024b_system01/READY05/'
OUT=HERE/'ordinary_layers02_READY';OUT.mkdir(exist_ok=False);PREFIX=S+'ordinary_layers02_READY/'
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';AA='res://scripts/city/luoyang_docks_district08_20261019aa.gd';AC='res://scripts/city/luoyang_docks_workyard_20261019ac.gd'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h and b'tokens truncated' not in b,(p,sha(b));return b
def output(name,b):
    with (OUT/name).open('xb') as f:f.write(b)
    assert (OUT/name).read_bytes()==b
    return dict(path=PREFIX+name,sha256=sha(b),bytes=len(b))
def full_inverse(after,before,hunks):
    forward=before.decode();back=after.decode()
    for r in hunks:assert forward.count(r['old'])==1;forward=forward.replace(r['old'],r['new'],1)
    for r in reversed(hunks):assert back.count(r['new'])==1;back=back.replace(r['new'],r['old'],1)
    assert forward.encode()==after and back.encode()==before
sysproof=json.loads(read(Y+'whole_byte_inverse_NOTREADY.json','7421707e7a78ea98bafc3da6ba74931461be6a18be3f978651f9bb65e8cb77c3'))
cr=sysproof['candidates']['C']
cr['candidate_path']='res://build/luoyang_yamen_courts_20261024c_system01/runtime04_READY/C_READY.gd'
cr['candidate_sha256']='f389b2e12e839d9005c3ac7643b69921ea31d9b7cc66d9194be0ab18c0d8b5d1'
for row in cr['replacements']:
    row['new']=row['new'].replace('res://build/luoyang_yamen_courts_20261024c_system01/runtime02/courts_session_NOTREADY.gd','res://build/luoyang_yamen_courts_20261024c_system01/runtime04_READY/courts_session_READY.gd').replace('ab031d7c6f9630a91f2e2c8ba705d1eb753d3c5df04f7c421d8fcbd0ee70ed49','791ae73e97623e71c0a0445f7a60cd14b6bf8f17453e7fa77dd9d0a89a873c4a')
cbytes=read(cr['candidate_path'],cr['candidate_sha256']);cparent=read('res://build/luoyang_city_space_20261024b_source01/C_finite_packed_polygon_CANDIDATE.gd',cr['parent_sha256']);assert len(cr['replacements'])==3
full_inverse(cbytes,cparent,cr['replacements'])
cp=output('C_current_three_hunk_to_B9B_proof_NOTREADY.json',enc(dict(schema_version=1,status='EXACT_C_CURRENT_TO_FIXED_B9B_SOURCE_LAYER',path=C,old_sha256=cr['parent_sha256'],new_sha256=cr['candidate_sha256'],whole_inverse_exact=True,replacements=cr['replacements'])))
def layer_block(label,path_const,parent_const,current_sha,proof,status,count):
    return f'''const ORDINARY_{label}_CURRENT_SHA="{current_sha}"
const ORDINARY_{label}_CURRENT_PROOF="{proof['path']}"
const ORDINARY_{label}_CURRENT_PROOF_SHA="{proof['sha256']}"
static func _ordinary_{label.lower()}_current_parent_bytes() -> PackedByteArray:
\t# One exact pre-layer. Existing historical inverse length/rows remain unchanged.
\tif FileAccess.get_sha256({path_const})!=ORDINARY_{label}_CURRENT_SHA or FileAccess.get_sha256(ORDINARY_{label}_CURRENT_PROOF)!=ORDINARY_{label}_CURRENT_PROOF_SHA: return PackedByteArray()
\tvar layer: Variant=JSON.parse_string(FileAccess.get_file_as_string(ORDINARY_{label}_CURRENT_PROOF))
\tif not layer is Dictionary or layer.get("schema_version")!=1 or layer.get("status")!="{status}" or layer.get("path")!={path_const} or layer.get("old_sha256")!={parent_const} or layer.get("new_sha256")!=ORDINARY_{label}_CURRENT_SHA or layer.get("whole_inverse_exact")!=true or not layer.get("replacements") is Array or layer.replacements.size()!={count}: return PackedByteArray()
\tvar current_bytes: PackedByteArray=FileAccess.get_file_as_bytes({path_const})
\tvar parent_text: String=current_bytes.get_string_from_utf8()
\tif parent_text.to_utf8_buffer()!=current_bytes or b().bytes_sha(current_bytes)!=ORDINARY_{label}_CURRENT_SHA: return PackedByteArray()
\tfor index: int in range(layer.replacements.size()-1,-1,-1):
\t\tvar row: Variant=layer.replacements[index]
\t\tif not row is Dictionary or row.size()!=2 or not row.get("old") is String or not row.get("new") is String or row.old.is_empty() or row.new.is_empty() or row.old==row.new or parent_text.count(row.new)!=1: return PackedByteArray()
\t\tparent_text=parent_text.replace(row.new,row.old)
\treturn parent_text.to_utf8_buffer() if b().bytes_sha(parent_text.to_utf8_buffer())=={parent_const} else PackedByteArray()
'''
def patch_text(before,items):
    text=before.decode();hunks=[]
    for a,b in items:
        assert text.count(a)==1,(a,text.count(a));text=text.replace(a,b,1);hunks.append(dict(old=a,new=b))
    full_inverse(text.encode(),before,hunks);return text.encode(),hunks
aaparent=read(D+'AA_ordinary_C_READY_CANDIDATE.gd','0fa220574ada95916f7e89cd0bb4a725c07810d4a5b50d35b2069363cb24e612')
aalayer=layer_block('C','ORDINARY_C_PATH','ORDINARY_C_NEW_SHA',cr['candidate_sha256'],cp,'EXACT_C_CURRENT_TO_FIXED_B9B_SOURCE_LAYER',3)
aabytes,aahunks=patch_text(aaparent,[
 ('static func ordinary_c_source_admitted(path: String,expected: String) -> bool:\n',aalayer+'static func ordinary_c_source_admitted(path: String,expected: String) -> bool:\n'),
 ('or FileAccess.get_sha256(ORDINARY_C_PATH)!=ORDINARY_C_NEW_SHA or FileAccess.get_sha256(ORDINARY_C_PROOF)', 'or FileAccess.get_sha256(ORDINARY_C_PATH)!=ORDINARY_C_CURRENT_SHA or FileAccess.get_sha256(ORDINARY_C_PROOF)'),
 ('var bytes: PackedByteArray=FileAccess.get_file_as_bytes(ORDINARY_C_PATH)','var bytes: PackedByteArray=_ordinary_c_current_parent_bytes()'),
 ('{SELF:true,INDEX:true,AUTHOR:true,ORDINARY_C_PROOF:true}','{SELF:true,INDEX:true,AUTHOR:true,ORDINARY_C_PROOF:true,ORDINARY_C_CURRENT_PROOF:true}')])
assert len(aahunks)==4 and 'proof.replacements.size()!=2' in aabytes.decode()
aa=output('AA_layered_C_CANDIDATE.gd',aabytes)
aap=output('AA_current_four_hunk_to_0FA_proof_NOTREADY.json',enc(dict(schema_version=1,status='EXACT_AA_CURRENT_TO_FIXED_0FA_SOURCE_LAYER',path=AA,old_sha256=sha(aaparent),new_sha256=aa['sha256'],whole_inverse_exact=True,replacements=aahunks)))
acparent=read(D+'AC_ordinary_AA_READY_CANDIDATE.gd','9b99cddf16b108c20cd487d77d00f07fe5c72398a776642f3eaaab65442f421e')
aclayer=layer_block('AA','ORDINARY_AA_PATH','ORDINARY_AA_NEW_SHA',aa['sha256'],aap,'EXACT_AA_CURRENT_TO_FIXED_0FA_SOURCE_LAYER',4)
acbytes,achunks=patch_text(acparent,[
 ('static func _ordinary_source_successor(path: String,expected: String) -> bool:\n',aclayer+'static func _ordinary_source_successor(path: String,expected: String) -> bool:\n'),
 ('if FileAccess.get_sha256(ORDINARY_AA_PATH)!=ORDINARY_AA_NEW_SHA or FileAccess.get_sha256(ORDINARY_AA_PROOF)', 'if FileAccess.get_sha256(ORDINARY_AA_PATH)!=ORDINARY_AA_CURRENT_SHA or FileAccess.get_sha256(ORDINARY_AA_PROOF)'),
 ('var bytes: PackedByteArray=FileAccess.get_file_as_bytes(ORDINARY_AA_PATH)','var bytes: PackedByteArray=_ordinary_aa_current_parent_bytes()'),
 ('{SELF:true,AUTHOR:true,ORDINARY_AA_PROOF:true}','{SELF:true,AUTHOR:true,ORDINARY_AA_PROOF:true,ORDINARY_AA_CURRENT_PROOF:true}'),
 ('if FileAccess.get_sha256(ORDINARY_AA_PATH)!=ORDINARY_AA_NEW_SHA: return {}','if FileAccess.get_sha256(ORDINARY_AA_PATH)!=ORDINARY_AA_CURRENT_SHA: return {}')])
assert len(achunks)==5 and 'proof.replacements.size()!=3' in acbytes.decode()
ac=output('AC_layered_AA_CANDIDATE.gd',acbytes)
# Independently replay the unchanged historical two/three gates from their old snapshots.
oldcp_path=D+'C_ordinary_source_wholebyte_proof_READY.json';oldcp_sha='213fdb1fec3078970c24b14c004ac47cad5347664a1fd15d271f8a54eda05029';oldcp=json.loads(read(oldcp_path,oldcp_sha))
oldaa_path=D+'AA_ordinary_source_wholebyte_proof_READY.json';oldaa_sha='6df87e86f81f96a695aa0b9b4ce31d185bc0a65b4182fc27825460fe134605f3';oldaa=json.loads(read(oldaa_path,oldaa_sha))
assert len(oldcp['replacements'])==2 and len(oldaa['replacements'])==3
for raw,pr in [(cparent,oldcp),(aaparent,oldaa)]:
    text=raw.decode()
    assert sha(raw)==pr['new_sha256']
    for r in reversed(pr['replacements']):assert text.count(r['new'])==1;text=text.replace(r['new'],r['old'],1)
    assert sha(text.encode())==pr['old_sha256']
report=dict(status='EXACT_LAYERED_ORDINARY_SOURCE_CONTRACT_BUILD_NOTREADY',ready=False,C=dict(target=C,parent_sha256=cr['parent_sha256'],candidate=dict(path=cr['candidate_path'],sha256=cr['candidate_sha256']),new_layer=cp,new_hunks=3,existing_historical_proof=dict(path=oldcp_path,sha256=oldcp_sha,exact_rows=2)),AA=dict(target=AA,parent=dict(path=D+'AA_ordinary_C_READY_CANDIDATE.gd',sha256=sha(aaparent)),candidate=aa,hunks=aahunks,new_layer=aap,new_hunks=4,existing_historical_proof=dict(path=oldaa_path,sha256=oldaa_sha,exact_rows=3)),AC=dict(target=AC,parent=dict(path=D+'AC_ordinary_AA_READY_CANDIDATE.gd',sha256=sha(acparent)),candidate=ac,hunks=achunks),whole_byte_forward_inverse=True,old_C2_and_AA3_historical_gates_retained=True,source_new_ordinary_leaves={cp['path']:cp['sha256'],aap['path']:aap['sha256']},source_domain='Docks only, via AA/AC source_paths; not authority or new ownership.',author_and_geometry_unchanged=True,C_AA_nonowned=True,AC_existing_owned_edge_required=True,final_runtime_READY_SHA_propagation_pending=False,engine_calls=0,Stage_calls=0,canonical_writes=0)
pr=output('layered_ordinary_whole_byte_inverse_NOTREADY.json',enc(report))
print(json.dumps(dict(AA=aa,AC=ac,C_layer=cp,AA_layer=aap,proof=pr)))
