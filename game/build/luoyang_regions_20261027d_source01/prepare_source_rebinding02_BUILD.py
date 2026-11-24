"""Rebind only two immutable Family source keys; never compile geometry or run Godot."""
from pathlib import Path
import copy, hashlib, json, struct
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01';O=N/'source_rebinding02_BUILD'
sha=lambda b:hashlib.sha256(b).hexdigest()
res=lambda p:'res://'+p.relative_to(G).as_posix()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
decoder_source=(S/'audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf8');scope={'struct':struct}
exec(decoder_source[decoder_source.index('class FrozenVariant:'):decoder_source.index('binding_pin=')],scope)
def decode(raw):
    d=scope['FrozenVariant'](raw);v=d.value();assert d.p==len(raw);return v
def pin(path,raw=None):
    raw=path.read_bytes() if raw is None else raw
    return {'path':res(path),'sha256':sha(raw),'bytes':len(raw)}
def fixed(p):
    raw=(G/p['path'][6:]).read_bytes();assert sha(raw)==p['sha256'];return raw
def string_atom(value):
    raw=value.encode();return struct.pack('<II',4,len(raw))+raw+b'\0'*((-len(raw))%4)
manifest_path=N/'region_runtime_manifest_BUILD.json';manifest_raw=manifest_path.read_bytes()
assert sha(manifest_raw)=='54976bb040827b1dfc4cff9103ef9c5d84841c57eec8790c803de48b3820cae6'
manifest=json.loads(manifest_raw);author_raw=fixed(manifest['author']);author=json.loads(author_raw)
assert not O.exists();O.mkdir()
bindings=[
    {'old':'res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json','new':'res://build/luoyang_city_finish_20261025i_source01/garden_estate_exit_repair_20261027c01/unified32_READY01/metadata/estate_final.json','sha256':'0857b25b28aede38410d4c952d169dfea5cac70efc16f36a12c9bba589da64bb','bytes':149115},
    {'old':'res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json','new':'res://build/luoyang_city_finish_20261025i_source01/garden_estate_exit_repair_20261027c01/unified32_READY01/metadata/quarter_final.json','sha256':'58cd5af08cec55d6d98a261d23269cf220b013c2be39c53d862bbf508b3b6117','bytes':127181},
]
for row in bindings:
    raw=fixed({'path':row['new'],'sha256':row['sha256']});assert len(raw)==row['bytes']
proofs=[]
def rebind(id,parent,kind):
    before=fixed(parent);value=decode(before);after=before;changes=[]
    for row in bindings:
        if row['old'] not in value['sources']:
            assert row['old'].encode() not in before
            continue
        assert value['sources'][row['old']]==row['sha256'] and row['new'] not in value['sources']
        a=string_atom(row['old']);b=string_atom(row['new'])
        assert after.count(a)==1 and row['new'].encode() not in after
        after=after.replace(a,b,1);changes.append({'old':row['old'],'new':row['new'],'sha256_unchanged':row['sha256'],'old_atom_hex':a.hex(),'new_atom_hex':b.hex()})
    if not changes:return parent
    result=decode(after);back=copy.deepcopy(result)
    for row in changes:assert back['sources'].pop(row['new'])==row['sha256_unchanged'];back['sources'][row['old']]=row['sha256_unchanged']
    assert back==value
    inverse=after
    for row in reversed(changes):
        a=bytes.fromhex(row['old_atom_hex']);b=bytes.fromhex(row['new_atom_hex']);assert inverse.count(b)==1;inverse=inverse.replace(b,a,1)
    assert inverse==before
    path=O/(id+('_terminal.bin' if kind=='terminal' else '.bin'));path.write_bytes(after)
    candidate=pin(path,after);proofs.append({'id':id,'kind':kind,'parent':parent,'candidate':candidate,'changes':changes,'only_sources_dictionary_keys_changed':True,'all_other_typed_fields_equal':True,'all_unmodified_binary_segments_verbatim':True,'whole_binary_inverse':True})
    return candidate
newauthor=copy.deepcopy(author)
for id,parent in author['terminal_bindings'].items():newauthor['terminal_bindings'][id]=rebind(id,parent,'terminal')
assert sum(newauthor['terminal_bindings'][id]!=parent for id,parent in author['terminal_bindings'].items())==2
author_path=O/'regions_author07_immutable_sources_BUILD.json';author_path.write_bytes(enc(newauthor));author_pin=pin(author_path)
newmanifest=copy.deepcopy(manifest);newmanifest['author']=author_pin
for id,parent in manifest['compiled_bindings'].items():newmanifest['compiled_bindings'][id]=rebind(id,parent,'compiled')
assert len([p for p in proofs if p['kind']=='compiled'])==9
manifest_candidate=O/'region_runtime_manifest_candidate.json';manifest_candidate.write_bytes(enc(newmanifest));manifest_pin=pin(manifest_candidate)
router_parent=S/'region_integration_20261027d01/closure_READY01/Router_READY.gd';router_raw=router_parent.read_bytes()
assert sha(router_raw)=='eddb274e6c09d573879234ba7b303b490ffccd33dff2c91d329e46e0c52840f4'
oldsha=sha(manifest_raw).encode();newsha=manifest_pin['sha256'].encode();assert router_raw.count(oldsha)==1
router_new=router_raw.replace(oldsha,newsha,1);assert router_new.replace(newsha,oldsha,1)==router_raw and router_new.count(b'\r\n')==13
router_path=O/'Router_manifest_source_rebind_CANDIDATE.gd';router_path.write_bytes(router_new)
result={'status':'ROOT_APPROVED_TWO_IMMUTABLE_SOURCE_KEY_REBIND_NOT_STAGE_OR_FIELD','parent_manifest':pin(manifest_path,manifest_raw),'manifest_candidate':manifest_pin,'manifest_target':res(manifest_path),'author_parent':manifest['author'],'author_candidate':author_pin,'immutable_source_bindings':bindings,'changed_terminals':2,'unchanged_terminals':2,'compiled_source_only_successors':9,'proofs':proofs,'Router':{'parent':pin(router_parent,router_raw),'candidate':pin(router_path,router_new),'old_manifest_sha256':oldsha.decode(),'new_manifest_sha256':newsha.decode(),'only_one_SHA_literal_changed':True,'whole_UTF8_inverse':True,'crlf13_preserved':True},'geometry_compile_calls':0,'engine_calls':0,'canonical_writes':0,'old_failure_preserved':86968}
out=O/'source_rebinding_whole_binary_inverse_BUILD.json';out.write_bytes(enc(result))
print(json.dumps({'descriptor':pin(out),'manifest':manifest_pin,'manifest_target':res(manifest_path),'author':author_pin,'Router':result['Router']['candidate'],'binary_proofs':len(proofs)}))
