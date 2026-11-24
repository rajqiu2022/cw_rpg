from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
P=NS+'parse12_ROOT_READY/';OUT=N/'parse12_ROOT_READY'
def sha(b):return hashlib.sha256(b).hexdigest()
oldinput=json.loads((G/'build/luoyang_market_courtyard_links_20261025g_system01/parse11_ROOT_READY/input_ROOT_READY.json').read_text(encoding='utf-8'))
proofpath=NS+'runtime_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json'
proofbytes=(N/'runtime_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json').read_bytes();proof=json.loads(proofbytes)
pins=[proof[k] for k in ['runtime','ambient','Field']]+[row['candidate'] for row in proof['records'].values()]
for name in ['original_owner_receipts03_family_weak_snapshot_NOTREADY.gd','artisan_existing_rooms_return_projection01_NOTREADY.gd','city_purpose_surface04_explicit_repeat_NOTREADY.gd']:
    b=(N/name).read_bytes();pins.append(dict(path=NS+name,sha256=sha(b),bytes=len(b)))
assert len(pins)==12 and len({p['path'] for p in pins})==12
scope=json.loads((N/'finish8_existing_target_scope32_PREPARATION.json').read_text(encoding='utf-8'))
spec=dict(status='ROOT_ONLY_EXACT12_FUNCTIONAL_GD_PARSE_NO_BUSINESS',ready=True,scripts=pins,save_paths=oldinput['save_paths'],
    source_proof=dict(path=proofpath,sha256=sha(proofbytes)),base_paths=[r['target'] for r in scope['targets']],output_prefix=P+'output/')
ib=(json.dumps(spec,ensure_ascii=False,indent=2)+'\n').encode('utf-8')
parent=(G/'build/luoyang_market_courtyard_links_20261025g_system01/parse11_ROOT_READY/parse_ROOT_READY.gd').read_bytes()
assert sha(parent)=='eabbac2a6080aa3632ec3986a69ec1b16c1ec06f10bf5a73e00357feee966cfb'
t=parent.decode('utf-8');changes=[]
def change(a,b):
    global t
    assert t.count(a)==1,(a,t.count(a));t=t.replace(a,b);changes.append(dict(old=a,new=b))
change('res://build/luoyang_market_courtyard_links_20261025g_system01/parse11_ROOT_READY/input_ROOT_READY.json',P+'input_ROOT_READY.json')
change('306e6796a4d96a23a8f27eb30a97b58e5679aaa40e1e1e490a434fcc40c2a62d',sha(ib))
change('raw.get("scripts",[]).size()==11','raw.get("scripts",[]).size()==12')
change('"EXACT_ELEVEN_SCRIPTS_FIFTEEN_SAVE_FACTS"','"EXACT_TWELVE_SCRIPTS_FIFTEEN_SAVE_FACTS"')
change('# Deliberately continue after any load/parse error; collect all11 results.','# Deliberately continue after any load/parse error; collect all12 results.')
change('check(rows.size()==11,"ALL_ELEVEN_RESULTS_WITHOUT_EARLY_BREAK")','check(rows.size()==12,"ALL_TWELVE_RESULTS_WITHOUT_EARLY_BREAK")')
back=t
for row in reversed(changes):back=back.replace(row['new'],row['old'])
assert back.encode('utf-8')==parent
kb=t.encode('utf-8');receipt=dict(status='MECHANICAL_ROOT_ONLY_PARSE12_NO_ENGINE_EXECUTED',input=dict(path=P+'input_ROOT_READY.json',sha256=sha(ib)),key=dict(path=P+'parse_ROOT_READY.gd',sha256=sha(kb)),parent_key_sha256=sha(parent),hunks=changes,whole_byte_inverse=True,scope='12 functional GD only. No candidate instances/business, no Field/PNG/geometry/collector. Temple binding pointer and later AA/AC/Coordinator-only code get their own necessary residual parse if changed.',engine_calls=0,canonical_writes=0)
assert not OUT.exists();OUT.mkdir()
for name,b in [('input_ROOT_READY.json',ib),('parse_ROOT_READY.gd',kb),('mechanical_full_inverse_ROOT_READY.json',(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))]:
    with (OUT/name).open('xb') as f:f.write(b)
print(json.dumps(receipt)[:700])
