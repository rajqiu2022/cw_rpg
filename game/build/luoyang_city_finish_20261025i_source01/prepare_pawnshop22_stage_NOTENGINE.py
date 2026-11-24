"""Mechanical specialization of reviewed exact Stage; build only, never instantiate/run Stage."""
from pathlib import Path
import json,hashlib,copy,importlib.util,difflib
N=Path(__file__).resolve().parent;GAME=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'pawnshop_only_repair01/'
O=N/'pawnshop_only_repair01'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
def read(pin):
    b=(GAME/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'];return b
def load(pin):return json.loads(read(pin))
bp=dict(path=P+'unified22_READY01/pawnshop22_all_candidates_and_inverse_NOT_STAGE.json',sha256='aceeb63c1217aa148b547fec737e9e2ae2d6da6ce5fb6993d7a7df028663eb74')
b=load(bp);parentpin=dict(path=S+'stage_Estate_wall_source31_ROOT_ONLY.py',sha256='eb66ddaca52e73871948d3718295291b7e00ac97fa782ca2870bbb73b7ea42b5')
parent=read(parentpin);text=parent.decode('utf-8');hs=[]
def change(a,c):
    global text
    assert text.count(a)==1,(a[:100],text.count(a));text=text.replace(a,c,1);hs.append(dict(old=a,new=c))
changes=[
('Root-only0860 exact31 successor: Estate helper two type/scale hunks and Yamen existing wall texture tuple; Field receipt two lines retained. No engine/canonical writes.','Root-only47CC pawnshop exact22 successor. Only G pawn routing/view and two new service/author leaves; eight indexes and thirteen JSON source-only successors. Other production functions unchanged. No engine/canonical writes.'),
('class EstateWall31(M.Stage):','class Pawn22(M.Stage):'),
("self.scope['count']==len(self.parents)==31 and self.scope['partition']==dict(GD=17,JSON=14)","self.scope['expected_count']==len(self.parents)==22 and self.bundle['partition']==dict(GD=9,JSON=13,total=22)"),
('EXACT31_17GD14JSON_SCOPE','EXACT22_9GD13JSON_SCOPE'),
('ROOT_CURRENT_0860_FULL31_BACKUP_AND_FRESH_OBSERVATION','ROOT_CURRENT47CC_FULL22_BACKUP_AND_FRESH_OBSERVATION'),
("self.backup['total_backups']==492","self.backup['total_backups']==514"),
('ROOT_ACTUAL_0860_BACKUP31','ROOT_ACTUAL47CC_BACKUP22'),
('len(rows)==31','len(rows)==22'),('ROOT_BACKUP31_EXACT_DOMAIN','ROOT_BACKUP22_EXACT_DOMAIN'),
("len(self.backup['current36'])==36","len(self.backup['current37'])==37"),
('CURRENT36_NOOP_G_AUTHORITY_PRESERVED','CURRENT37_OTHER_FUNCTIONS_PRESERVED'),
("self.backup['current36']","self.backup['current37']"),('CURRENT36_IMMUTABLE_PARENT','CURRENT37_IMMUTABLE_PARENT'),
('Estate_wall_source_repair01/root_only_current31_backup/','pawnshop_only_repair01/root_only_current22_backup/'),
('ROOT_BACKUP31_FIXED_NAMESPACE','ROOT_BACKUP22_FIXED_NAMESPACE'),('ROOT_FULL_BACKUP31_WHOLE_CURRENT_IMMUTABLE','ROOT_FULL_BACKUP22_WHOLE_CURRENT_IMMUTABLE'),
("len(prior['source_sha256'])==229 and len(self.authority['source_sha256'])==235","len(prior['source_sha256'])==235 and len(self.authority['source_sha256'])==236"),
('OWNED10_229_PLUS6_EQUALS235','OWNED10_235_PLUS1_EQUALS236'),('len(changed)==4','len(changed)==1'),
('ONLY_FOUR_REAL_OWNED_EDGES','ONLY_G_ONE_REAL_OWNED_EDGE'),('OTHER_SIX_OWNED_IDENTICAL','OTHER_NINE_OWNED_IDENTICAL'),
('len(extra)==6','len(extra)==1'),('ALL_OLD229_FIXED_SIX_NEW','ALL_OLD235_FIXED_ONE_NEW'),
('len(self.targets)==31','len(self.targets)==22'),('EXACT31_NO_NOOP_TARGETS','EXACT22_NO_NOOP_TARGETS'),
('PINNED_CURRENT0860_MAP_PARENT','PINNED_CURRENT47CC_MAP_PARENT'),
('len(copies)==14 and len(reconstruction)==31','len(copies)==13 and len(reconstruction)==22'),
('EXACT17_GD_PATCH14_JSON_COPY','EXACT9_GD_PATCH13_JSON_COPY'),
('ESTATE_WALL_SOURCE_EXACT31_STAGED_NOT_DEPLOYED','PAWNSHOP_ONLY_EXACT22_STAGED_NOT_DEPLOYED'),
('target_count=14','target_count=13'),('dict(patch_count=17,copy_count=14,total=31)','dict(patch_count=9,copy_count=13,total=22)'),
('Pinned0860/773E exact31 successor. All owned10/old229 values and edges retained plus6 proofs=235 and4 real owned edges. Only Estate helper two type/scale hunks and Yamen three existing texture leaves admitted; Field preserves original0860 two receipt lines with pure source pointers. Runtime functions, Router, payloads, masks, geometry and actors unchanged; CT26/Temple196 prospective checks retained.','Pinned47CC/BCF5 pawn-only exact22 successor. All owned10 and old235 proof values/edges retained plus one G successor snapshot=236. Only G pawn exit/effective author view and new pawn service runtime/author implement this request; eight index literals and thirteen JSON source maps follow exactly. C/Field/ENV/Router/Family/finish runtime/BIND/CT/Coord/Temple, all native scenes/layouts/registries, eight exterior payloads/masks and shops/prices remain unchanged. CT26/Temple196 prospective checks retained. Old publication gates preserve ancestor credit only; current Root22 backup and locked input bind this requested scope, not a new Field PASS.'),
('targets=31,map_nodes=4','targets=22,map_nodes=4'),('EstateWall31(spec).run()','Pawn22(spec).run()')]
for a,c in changes:change(a,c)
a="  trial=self.read_json_input('trial');need(trial['admitted']is True and trial['permission_kind']=='TRIAL_PERMISSION_NOT_RESULT'and trial['actual_Field_pass']is False and self.inputs['trial']['path']==PREFIX+'finish8_ROOT_TRIAL_PERMISSION02.json'and self.inputs['trial']['sha256']=='7bcb3165485026f4ff2c15ebb0dfa696c6780ed2cad238933201f715abdca82a','TRIAL_PERMISSION_NOT_RESULT')\n"
c="  need(self.inputs['backup']['sha256']=='75637d956c0d040af9b57fb6374d2b78a8b46b334fcc892c1405de57a1652639' and self.backup['scope']['sha256']==self.inputs['scope']['sha256'],'ROOT_EXACT22_SCOPE_BACKUP_AND_LOCKED_INPUT_NOT_FIELD_PASS')\n"
change(a,c)
start=text.index("  contract=self.bundle['contract'];")
end=text.index("  for p,r in self.bundle['metadata'].items():self.verify_metadata(p,r)",start)
a=text[start:end]
c="""  # These unchanged strict tables have no semantic intersection with G/EX/index changes.
  # Bind them to the previous actual descriptor and prospective fixed maps, not observed values.
  prior_bundle=self.read_json_input('parent_descriptor')
  parent_stage=self.read_json_input('parent_stage');fixed=dict(parent_stage['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256'])
  for p,pin in self.spec['declared_candidates'].items():fixed[p]=pin['sha256']
  contract=prior_bundle['contract']['candidate'];value=json.loads(self.read(contract['path'],contract['sha256']))
  need(len(value['source_sha256'])==26,'CT_EXACT_ALL26_SOURCE_DOMAIN')
  tbpin=prior_bundle['temple_binding']['candidate'];tb=json.loads(self.read(tbpin['path'],tbpin['sha256']))
  tparent=json.loads(self.read(tb['parent_binding_path'],tb['parent_binding_sha256']))
  merged={**tparent['source_sha256'],**tb['source_delta']};need(len(merged)==196,'TEMPLE_EXACT196_MERGED_SOURCE_DOMAIN')
  for table in [value['source_sha256'],merged]:
   need(not(set(table)&set(self.parents)),'CT_TEMPLE_HAVE_NO_REQUIRED_PIN_SUCCESSOR')
   for p,h in table.items():need(fixed.get(p)==h,'UNCHANGED_STRICT_PROSPECTIVE_PIN:'+p);self.verify_leaf(p,h)
"""
change(a,c)
literal_steps=hs
aa=parent.decode('utf-8').splitlines(keepends=True);bb=text.splitlines(keepends=True);hs=[]
for group in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):
    hs.append(dict(old=''.join(aa[group[0][1]:group[-1][2]]),new=''.join(bb[group[0][3]:group[-1][4]])))
forward=parent.decode('utf-8')
for h in hs:assert forward.count(h['old'])==1;forward=forward.replace(h['old'],h['new'],1)
assert forward==text
back=text
for h in reversed(hs):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
assert back.encode('utf-8')==parent;compile(text,'stage_pawnshop_exact22_ROOT_ONLY.py','exec')
driverpath=S+'stage_pawnshop_exact22_ROOT_ONLY.py';driverraw=text.encode('utf-8')
def emit(path,raw):
    p=GAME/path[6:];assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb')as f:f.write(raw)
    return dict(path=path,sha256=sha(raw),bytes=len(raw))
driverpin=emit(driverpath,driverraw)
proof=emit(P+'Stage22_driver_whole_inverse_NOT_STAGE.json',enc(dict(parent=parentpin,candidate=driverpin,hunks=hs,whole_UTF8_inverse=True,original_authority_F120_full_edge_validation_and_finite_walk_unchanged=True,original_five_gate_IDs_preserved=True,only_root_target_scope_gate_uses_current_actual_backup_not_old_trial02=True,CT26_Temple196_unchanged_prospective_all_values=True,Stage_calls=0,engine_calls=0,canonical_writes=0)))
pins=[dict(id='driver',**driverpin),dict(id='candidates',**bp),dict(id='scope',**b['scope']),dict(id='backup',**b['root_backup']),dict(id='execution',**b['execution']['candidate']),dict(id='authority_helper',**b['authority_helper']),dict(id='publication',**b['publication']),dict(id='parent_stage',**b['parent_stage']),dict(id='parent_descriptor',**b['parent_descriptor']),dict(id='functional_whole_inverse',**b['function_proof']),dict(id='mechanical_seal',**b['seal'])]
for i,p in enumerate(b['ordinary']):pins.append(dict(id='ordinary'+str(i),**p))
gates=[]
for i,g in enumerate(b['old_required_gates']):
    ident='gate_'+str(i);pins.append(dict(id=ident,**g['pin']));gates.append(dict(id=g['id'],input=ident,pointer=g['pointer'],equals=g['equals']))
gates.append(dict(id='root_target_preauthorization',input='backup',pointer=['passed'],equals=True))
spec=dict(schema_version=1,status='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT',blockers=[],output_root=S+'outputs/root_pawnshop_only_exact22_stage01/',pinned_inputs=pins,authority_input='execution',authority_helper_input='authority_helper',prospective_targets=[dict(target=r['target'],candidate_path=r['candidate']['path'],sha256=r['candidate']['sha256'],bytes=r['candidate']['bytes'])for r in b['targets']],declared_candidates={r['target']:r['candidate']for r in b['targets']},five_owned_targets=b['execution']['changed_existing_owned'],required_gates=gates,source_groups=[],nodes=[])
# Data-only old strict preflight and native patch formatter; never construct/run Stage.
core=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py';assert sha(core.read_bytes())=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
sp=importlib.util.spec_from_file_location('fixed_patch_formatter_pawn_only',core);M=importlib.util.module_from_spec(sp);sp.loader.exec_module(M)
patchproof={}
for r in b['targets']:
    old,new=read(r['parent']),read(r['candidate']);assert old!=new and (GAME/r['target'][6:]).read_bytes()==old
    if r['target'].endswith('.gd'):_,p=M._strict_lf_build_file_patch((GAME/r['target'][6:]).resolve().as_posix(),old,new);patchproof[r['target']]=p
assert len(patchproof)==9
def at(v,keys):
    for k in keys:v=v[k]
    return v
for p,r in b['metadata'].items():
    old,new=load(r['parent']),load(r['candidate']);v=copy.deepcopy(old);flat={};newflat={}
    for ptr in r['source_fields']:
        for k,h in at(old,ptr).items():assert k not in flat;flat[k]=h
        for k,h in at(new,ptr).items():assert k not in newflat;newflat[k]=h
        assert set(at(old,ptr))<=set(at(new,ptr))
    assert {k:h for k,h in newflat.items()if k not in flat}==r['explicit_new_ordinary']
    for h in r['changes']:
        holder=at(v,h['pointer'][:-1]);key=h['pointer'][-1];assert(key in holder)==h['existed'] and (not h['existed']or holder[key]==h['old']);holder[key]=h['new']
    assert v==new
    for h in reversed(r['changes']):
        holder=at(v,h['pointer'][:-1]);key=h['pointer'][-1]
        if h['existed']:holder[key]=h['old']
        else:del holder[key]
    assert enc(v)==read(r['parent'])
specpin=emit(P+'source_input_pawnshop22_ROOT_REVIEW.json',enc(spec))
audit=emit(P+'finite_preStage22_inverse_READONLY.json',enc(dict(status='PAWN_ONLY_DATA_PREFLIGHT_NOT_STAGE',passed=True,count=22,partition=b['partition'],all12_metadata_classification_and_raw_inverse=True,all9_GD_patch_format=patchproof,old235_proofs_preserved=True,only_G_owned_edge=True,functions_scope='G + two NEW service/author leaves only',source_map_counts={k:r['count']for k,r in b['maps'].items()},Stage_calls=0,engine_calls=0,canonical_writes=0)))
print(json.dumps(dict(driver=driverpin,proof=proof,input=specpin,audit=audit)))
