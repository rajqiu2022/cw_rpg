"""Exact ordinary outer layers; preserve every old C2/AA3 and 24c layer."""
from pathlib import Path
import json,hashlib,difflib
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_revision_20261024e_source01/';P='res://build/luoyang_city_revision_20261024c_source01/ordinary_layers02_READY/'
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';AA='res://scripts/city/luoyang_docks_district08_20261019aa.gd';AC='res://scripts/city/luoyang_docks_workyard_20261019ac.gd'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower(),(p,sha(b));assert b'tokens truncated' not in b;return b
def inverse(a,b,ops):
    f,v=a,b
    for r in ops:
        x,y=r['old'].encode(),r['new'].encode();assert f.count(x)==1;f=f.replace(x,y,1)
    for r in reversed(ops):
        x,y=r['old'].encode(),r['new'].encode();assert v.count(y)==1;v=v.replace(y,x,1)
    assert f==b and v==a
def hunks(a,b):
    al,bl=a.decode().splitlines(keepends=True),b.decode().splitlines(keepends=True)
    ops=[]
    for group in difflib.SequenceMatcher(None,al,bl,autojunk=False).get_grouped_opcodes(2):
        x=''.join(al[group[0][1]:group[-1][2]]);y=''.join(bl[group[0][3]:group[-1][4]])
        assert x and y and a.count(x.encode())==b.count(y.encode())==1
        ops.append(dict(old=x,new=y))
    inverse(a,b,ops);assert max(max(len(r['old']),len(r['new'])) for r in ops)<18000
    return ops
def outer(label,current_sha,proof,status,count):
    lower=label.lower()
    return f'''const ORDINARY_{label}_OUTER_SHA="{current_sha}"
const ORDINARY_{label}_OUTER_PROOF="{proof['path']}"
const ORDINARY_{label}_OUTER_PROOF_SHA="{proof['sha256']}"
static func _ordinary_{lower}_outer_parent_bytes() -> PackedByteArray:
\t# Exact outer layer only; all pre-existing inner proof gates remain unchanged.
\tif FileAccess.get_sha256(ORDINARY_{label}_PATH)!=ORDINARY_{label}_OUTER_SHA or FileAccess.get_sha256(ORDINARY_{label}_OUTER_PROOF)!=ORDINARY_{label}_OUTER_PROOF_SHA: return PackedByteArray()
\tvar layer: Variant=JSON.parse_string(FileAccess.get_file_as_string(ORDINARY_{label}_OUTER_PROOF))
\tif not layer is Dictionary or layer.get("schema_version")!=1 or layer.get("status")!="{status}" or layer.get("path")!=ORDINARY_{label}_PATH or layer.get("old_sha256")!=ORDINARY_{label}_CURRENT_SHA or layer.get("new_sha256")!=ORDINARY_{label}_OUTER_SHA or layer.get("whole_inverse_exact")!=true or not layer.get("replacements") is Array or layer.replacements.size()!={count}: return PackedByteArray()
\tvar bytes: PackedByteArray=FileAccess.get_file_as_bytes(ORDINARY_{label}_PATH)
\tvar text: String=bytes.get_string_from_utf8()
\tif text.to_utf8_buffer()!=bytes or b().bytes_sha(bytes)!=ORDINARY_{label}_OUTER_SHA: return PackedByteArray()
\tfor index: int in range(layer.replacements.size()-1,-1,-1):
\t\tvar row: Variant=layer.replacements[index]
\t\tif not row is Dictionary or row.size()!=2 or not row.get("old") is String or not row.get("new") is String or row.old.is_empty() or row.new.is_empty() or row.old==row.new or text.count(row.new)!=1: return PackedByteArray()
\t\ttext=text.replace(row.new,row.old)
\treturn text.to_utf8_buffer() if b().bytes_sha(text.to_utf8_buffer())==ORDINARY_{label}_CURRENT_SHA else PackedByteArray()
'''
def main():
    freeze=HERE/'runtime_ready03/mechanical_ready_whole_inverse_NOT_STAGE.json';assert sha(freeze.read_bytes())=='d22b25c6fc5501ee6a6839a693ee427f2faa9d4b63b97fc67090d9fc49669a71';f=json.loads(freeze.read_bytes())
    crow=next(r for r in f['codes'] if r['kind']=='C');cb=read(crow['candidate']['path'],crow['candidate']['sha256'])
    oldc=read('res://build/luoyang_yamen_courts_20261024c_system01/runtime04_READY/C_READY.gd','f389b2e12e839d9005c3ac7643b69921ea31d9b7cc66d9194be0ab18c0d8b5d1')
    out=HERE/'ordinary_outer03_READY';assert not out.exists();prefix=S+'ordinary_outer03_READY/';prepared=[]
    def output(name,b):
        prepared.append((name,b));return dict(path=prefix+name,sha256=sha(b),bytes=len(b))
    c_ops=hunks(oldc,cb);cp=output('C_to_fixed24c_proof_READY.json',enc(dict(schema_version=1,status='EXACT_24E_C_TO_FIXED24C_ORDINARY_LAYER',path=C,old_sha256=sha(oldc),new_sha256=sha(cb),whole_inverse_exact=True,replacements=c_ops)))
    rows={}
    for label,target,parent_name,parent_sha,newhash,proof,status,count,anchor in [
        ('C',AA,'AA_layered_C_CANDIDATE.gd','29fdc7764fe69507dd5e14135f0dc8aef5c42dcbe51c02bd3cb61441de1c4662',sha(cb),cp,'EXACT_24E_C_TO_FIXED24C_ORDINARY_LAYER',len(c_ops),'static func ordinary_c_source_admitted(path: String,expected: String) -> bool:\n'),
        ('AA',AC,'AC_layered_AA_CANDIDATE.gd','5d95bd4d48aa64db4fdce2241ecfdae2543aa2ac63e32bba404218cb3bcee3a8',None,None,None,None,'static func _ordinary_source_successor(path: String,expected: String) -> bool:\n')]:
        if label=='AA':newhash=aa['sha256'];proof=aap;status='EXACT_24E_AA_TO_FIXED24C_ORDINARY_LAYER';count=len(aa_ops)
        before=read(P+parent_name,parent_sha);text=before.decode();ops=[]
        def change(x,y):
            nonlocal text
            assert text.count(x)==1,(label,x,text.count(x));text=text.replace(x,y,1);ops.append(dict(old=x,new=y))
        change(anchor,outer(label,newhash,proof,status,count)+anchor)
        # Only raw on-disk comparisons become outer SHA. Inner CURRENT_SHA
        # validation still receives the exact restored old24c bytes.
        x=f'FileAccess.get_sha256(ORDINARY_{label}_PATH)!=ORDINARY_{label}_CURRENT_SHA'
        expected=2 if label=='C' else 3
        assert text.count(x)==expected
        text=text.replace(x,f'FileAccess.get_sha256(ORDINARY_{label}_PATH)!=ORDINARY_{label}_OUTER_SHA')
        # Record the repeated identical replacement as its containing lines,
        # so every inverse row is still unique and exactly two-key shaped.
        for line in before.decode().splitlines(keepends=True):
            if x in line:
                assert before.decode().count(line)==1
                ops.append(dict(old=line,new=line.replace(x,f'FileAccess.get_sha256(ORDINARY_{label}_PATH)!=ORDINARY_{label}_OUTER_SHA')))
        change(f'var current_bytes: PackedByteArray=FileAccess.get_file_as_bytes(ORDINARY_{label}_PATH)',f'var current_bytes: PackedByteArray=_ordinary_{label.lower()}_outer_parent_bytes()')
        oldset='ORDINARY_'+label+'_CURRENT_PROOF:true}'
        change(oldset,'ORDINARY_'+label+'_CURRENT_PROOF:true,ORDINARY_'+label+'_OUTER_PROOF:true}')
        after=text.encode();inverse(before,after,ops)
        row=output(('AA' if label=='C' else 'AC')+'_outer_CANDIDATE.gd',after)
        rows[target]=dict(parent=dict(path=P+parent_name,sha256=parent_sha),candidate=row,hunks=ops,wholebyte_forward_inverse=True)
        if label=='C':
            aa=row;aa_ops=hunks(before,after);aap=output('AA_to_fixed24c_proof_READY.json',enc(dict(schema_version=1,status='EXACT_24E_AA_TO_FIXED24C_ORDINARY_LAYER',path=AA,old_sha256=parent_sha,new_sha256=sha(after),whole_inverse_exact=True,replacements=aa_ops)))
    result=dict(status='EXACT_OUTER_ORDINARY_LAYERS_NOT_PARSED_NOT_STAGED',records=rows,C_layer=cp,AA_layer=aap,C_small_hunks=len(c_ops),AA_small_hunks=len(aa_ops),old_C2_AA3_and_current24c_layers_byte_preserved=True,old_ordinary_source_keys_preserved=True,source_additions={cp['path']:cp['sha256'],aap['path']:aap['sha256']},C_AA_not_owned=True,engine_calls=0,Stage_calls=0,canonical_writes=0)
    pr=output('whole_inverse_NOT_STAGE.json',enc(result));out.mkdir()
    for name,b in prepared:
        with (out/name).open('xb') as stream:stream.write(b)
        assert (out/name).read_bytes()==b
    print(json.dumps(pr))
if __name__=='__main__':main()
