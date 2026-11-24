"""Fixed EE47 parent, approved revision02 material source preparation only."""
from pathlib import Path
import json,hashlib,difflib,ast
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261025f_source01/'
S24='res://build/luoyang_city_revision_20261024e_source01/';E='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
N='res://build/luoyang_street_materials_20261025f_system01/material_revision02/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
    raw=(GAME/p[6:]).read_bytes();assert sha(raw)==h.lower(),p;assert b'tokens truncated' not in raw;return raw
def load(p,h):return json.loads(read(p,h))
def hunks(a,b):
    aa,bb=a.decode().splitlines(keepends=True),b.decode().splitlines(keepends=True);ops=[]
    for g in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):ops.append(dict(old=''.join(aa[g[0][1]:g[-1][2]]),new=''.join(bb[g[0][3]:g[-1][4]])))
    f,v=a,b
    for r in ops:
        x,y=r['old'].encode(),r['new'].encode();assert f.count(x)==1;f=f.replace(x,y,1)
    for r in reversed(ops):
        x,y=r['old'].encode(),r['new'].encode();assert v.count(y)==1;v=v.replace(y,x,1)
    assert f==b and v==a;return ops
scopepin=dict(path=S+'street_materials18_scope_PREPARATION.json',sha256='c6920eb563c899186b3091cf2acb69cc70d592ec394e7603c49585671ef4428b');scope=load(scopepin['path'],scopepin['sha256']);old=next(r for r in scope['targets'] if r['target']==E)
pin=dict(path=N+'ENV_materials_BUILD.gd',sha256='c07b747d289d78db70b8e0ff92114182c2dbe48446f6ee2e658dbe69850e49c1');before=read(old['immutable_old'],old['old_sha256']);after=read(pin['path'],pin['sha256']);pin['bytes']=len(after)
ops=hunks(before,after);assert len(ops)==1 and all(line.startswith('const MARKET_USE_') for text in [ops[0]['old'],ops[0]['new']] for line in text.splitlines() if line and not line.startswith('const MARKET_SPACE_') and not line.startswith('static var ') and not line.startswith('static func '))
ordinary={N+'market_purpose_layer_BUILD.gd':'ece43ee0e3cf777d834cd580b0fb66a8c8ddae29ebcfb138fa566bc5971687e6',N+'market_five_use_spec_BUILD.json':'2d6e7bc644328ecf80d26f101662a60d757deebb45415c9e33a6a131a17cf9f3',N+'market_use_materials_BUILD.gdshader':'84befe183f06894ee45c608c1ff49367b22d14cd2ddef38d84f81bdd58c7bbb0'}
for p,h in ordinary.items():read(p,h)
proof=dict(status='STREET25F_ENV_ONE_EXACT_LITERAL_SUCCESSOR_NOT_STAGE',scope=scopepin,records={E:dict(parent=dict(path=old['immutable_old'],sha256=old['old_sha256'],bytes=old['old_bytes']),candidate=pin,hunks=ops,whole_byte_forward_inverse=True)},new_Market_only_ordinary3=ordinary,System_full_inverse=dict(path=N+'alley_material_only_complete_inverse_hashfix02_BUILD.json',sha256='188f797423c7e3e3988bc77efd59f03b06cf774c47eb1843dba1e14a05dccdec'),execution_frozen=dict(path=S24+'docks31_candidates01/execution_successor_docks_PREPARATION.json',sha256='cf1cd7376c59e8ab11c21947eaba5b10ea3a8ffe7d03182a0fbe64337d5615c6'),OWNED10_proof162_depth16_unchanged=True,ENV_nonowned=True,no_new_media_or_geometry=True,engine_calls=0,Stage_calls=0,collector_calls=0)
load(proof['System_full_inverse']['path'],proof['System_full_inverse']['sha256'])
pp=HERE/'ENV_materials18_whole_inverse_NOT_STAGE.json';assert not pp.exists();pr=enc(proof);pp.write_bytes(pr)
parentpath=S24+'stage_docks_frontages31_residual03_NOTREADY.py';parent=read(parentpath,'2abfa7b51959c52cc7dafd840c6e22049de2e13ace72e68cd45e56b89822ceb6');text=parent.decode()
for x,y in [('Root-only exact31 Docks','Root-only exact18 street materials'),("PREFIX='res://build/luoyang_city_revision_20261024e_source01/'","PREFIX='res://build/luoyang_city_revision_20261025f_source01/'"),('fixed_docks31_core','fixed_materials18_core'),('DocksFrontageStage','StreetMaterialsStage'),("c=spec['docks_contract']","c=spec['materials_contract']"),('ROOT31_EXACT_LOCK_REQUIRED','ROOT18_EXACT_LOCK_REQUIRED'),('len(self.oldtargets)==31','len(self.oldtargets)==18'),("sum(p.endswith('.gd') for p in self.oldtargets)==16","sum(p.endswith('.gd') for p in self.oldtargets)==7"),('EXACT31_16GD15JSON_DOMAIN','EXACT18_7GD11JSON_DOMAIN'),('EXACT31_CURRENT_FE154_PARENT_BACKED_UP_NO_CANONICAL_WRITES','EXACT18_CURRENT_EE47_PARENT_BACKED_UP_NO_CANONICAL_WRITES'),("==len(backup['targets'])==31","==len(backup['targets'])==18"),('ROOT_745E_ACTUAL_SCHEMA','ROOT_8D205_ACTUAL_SCHEMA'),('EXACT31_BACKUP_TARGET_AND_PREFIX','EXACT18_BACKUP_TARGET_AND_PREFIX'),('EXACT31_FULL_OLD_BYTES','EXACT18_FULL_OLD_BYTES'),('EXACT31_FULL_BACKUP_COVERAGE','EXACT18_FULL_BACKUP_COVERAGE'),('len(self.codes)==8','len(self.codes)==1'),('EXACT8_APPROVED_FUNCTIONAL_AND_LITERAL_SUCCESSORS','EXACT1_NONOWNED_ENV_LITERAL_SUCCESSOR'),("len(self.parent_maps['expected_ch4_s3_luoyang_market_true'])==1862","len(self.parent_maps['expected_ch4_s3_luoyang_market_true'])==1874"),('FIXED_FE154_FOUR_PARENT_MAPS','FIXED_EE47_FOUR_PARENT_MAPS'),('ORIGINAL_AO_BASELINE_LITERAL_UNCHANGED','ORIGINAL_AO_BASELINE_LITERAL_UNCHANGED'),('FE154','EE47'),("len(self.targets)==31","len(self.targets)==18"),('EXACT31_TARGET_SET','EXACT18_TARGET_SET'),('len(copies)==15 and len(reconstruction)==31','len(copies)==11 and len(reconstruction)==18'),('STRICT16_GD_PATCH_EXACT15_JSON_COPY','STRICT7_GD_PATCH_EXACT11_JSON_COPY'),('DOCKS_FRONTAGES_EXACT31_STAGED_NOT_DEPLOYED','STREET_MATERIALS_EXACT18_STAGED_NOT_DEPLOYED'),('target_count=15','target_count=11'),('patch_count=16,copy_count=15,total=31','patch_count=7,copy_count=11,total=18'),('targets=31,map_nodes=4','targets=18,map_nodes=4')]:
    if x==y:continue
    assert x in text,x;text=text.replace(x,y)
start=text.index("        prior=self.read_json_input(c['parent_execution_input']);")
end=text.index('        self.parent_maps=',start)
text=text[:start]+"        need(self.input_bytes[c['parent_execution_input']]==self.input_bytes[spec['authority_input']] and len(self.authority['owned'])==10 and len(self.authority['source_sha256'])==162,'EXECUTION_ALL_BYTES_OWNED10_PROOF162_FROZEN')\n"+text[end:]
start=text.index("        if kind=='space_contract':");end=text.index("        if kind=='docks_incremental_map':",start);text=text[:start]+text[end:]
start=text.index("        if ident=='registry_final':");end=text.index("        if kind=='map':",start);text=text[:start]+text[end:]
oldline="        expected={p:{k:r['candidate'][k] for k in ['path','sha256']} for p,r in self.codes.items()};expected[EXEC]={k:self.inputs[self.spec['authority_input']][k] for k in ['path','sha256']}"
newline="        expected={p:{k:r['candidate'][k] for k in ['path','sha256']} for p,r in self.codes.items()}"
assert oldline in text;text=text.replace(oldline,newline)
text=text.replace("len(self.spec['pass_through_targets'])==9","len(self.spec['pass_through_targets'])==1").replace('EXACT8_CODE_PLUS_EXEC_PASSTHROUGH','EXACT1_NONOWNED_ENV_PASSTHROUGH')
assert text.count("len(self.spec['pass_through_targets'])==1")==1
ast.parse(text);driver=HERE/'stage_street_materials18_ROOT_ONLY.py';assert not driver.exists();driverraw=text.encode();driver.write_bytes(driverraw)
dp=dict(status='STREET25F_THIN18_DRIVER_PARENT_BYTE_DIFF_NOT_EXECUTED',parent_driver=dict(path=parentpath,sha256=sha(parent)),driver=dict(path=S+driver.name,sha256=sha(driverraw)),whole_byte_hunks=hunks(parent,driverraw),whole_byte_forward_inverse=True,authority_unchanged=True,one_ENV_code_only=True,exact18_scope_only=True,Root_backup_schema='count18/targets{target,backup,sha256,bytes,source_ticks,backup_sha256,backup_ticks}',four_maps_fixed8EA2_incremental_and_original_AO_model_equality=True,all_five_gates_retained=True,core8DE0_unchanged=True,Stage_imports=0,Stage_calls=0)
raw=enc(dp);out=HERE/'materials18_driver_whole_inverse_NOT_EXECUTED.json';assert not out.exists();out.write_bytes(raw)
print(json.dumps(dict(code_proof=dict(path=S+pp.name,sha256=sha(pr)),driver=dp['driver'],driver_inverse=dict(path=S+out.name,sha256=sha(raw)))))
