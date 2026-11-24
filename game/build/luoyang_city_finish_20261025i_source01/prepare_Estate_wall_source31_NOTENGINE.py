"""Only Root-approved Estate two-hunk helper repair plus Yamen existing texture tuple closure. BUILD only."""
from pathlib import Path
import copy,difflib,hashlib,json,re
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';B=S+'Estate_wall_source_repair01/';O=N/'Estate_wall_source_repair01';P=B+'closure_READY01/'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(pin):
 b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'],pin;return b
def load(pin):return json.loads(read(pin))
def emit(name,b):
 p=O/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 pin=dict(path=B+name,sha256=sha(b),bytes=len(b));print(json.dumps(pin));return pin
def exact(b,a,c,n=1):
 a,c=a.encode(),c.encode();assert a!=c and b.count(a)==n,(a[:120],b.count(a),n);return b.replace(a,c)
def hunks(a,b):
 aa,bb=a.decode().splitlines(True),b.decode().splitlines(True);hs=[]
 for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
 f,v=a,b
 for h in hs:f=exact(f,h['old'],h['new'])
 for h in reversed(hs):v=exact(v,h['new'],h['old'])
 assert f==b and v==a;return hs
E53=dict(path=S+'visible_doors_boundaries33_repair01/visible_doors_boundaries33_deployed_ROOT_ACTUAL.json',sha256='e53e6d557a60dc93e00120ed9541938cb51e54c5effd01383a086866ec8db6b2')
DEP=dict(path=S+'Temple_actor_receipt_repair01/Temple_actor_receipt25_deployed_ROOT_ACTUAL.json',sha256='0860c9038a537bec69bd0d2091d45dfbdf8c5ef52163103aadfa0c19dc814395')
OLD=dict(path=S+'Temple_actor_receipt_repair01/unified25_READY01/unified25_ROOT_BACKUP_FIXED_NOT_STAGE.json',sha256='71b482ffa28debabfe7c3ed39b77d266745cdbda5b24dbdad41de88344c18549')
BACK=dict(path=S+'Temple_actor_receipt_repair01/current_E53E_backup25_ROOT_ACTUAL.json',sha256='6cbdb68683733bc819978936225476bf4bf5ff16b2efb7f01b05a7af23b9e6bf')
edep,dep,old,oldback=load(E53),load(DEP),load(OLD),load(BACK)
parents={r['target']:dict(path=r['candidate_path'],sha256=r['sha256'],bytes=r['bytes'])for r in edep['targets']}
for r in dep['targets']:assert parents[r['target']]['sha256']==r['old_sha256'];parents[r['target']]=dict(path=r['candidate_path'],sha256=r['sha256'],bytes=r['bytes'])
for p in ['res://data/maps/luoyang_full_city_20261022ap/environment.json','res://scripts/city/luoyang_environment_index_20261022ap.gd']:del parents[p]
assert len(parents)==31 and sum(p.endswith('.gd')for p in parents)==17
scope=dict(status='CURRENT0860_NECESSARY_ESTATE_HELPER_YAMEN_SOURCE_EXACT31_PREPARATION',count=31,partition=dict(GD=17,JSON=14),parent_actual=DEP,parent_stage=dep['stage'],parent_descriptor=OLD,old_backups=461,targets=[dict(target=p,immutable_old=r['path'],old_sha256=r['sha256'],old_bytes=r['bytes'])for p,r in parents.items()],no_canonical_writes=True)
scopepin=emit('current_0860_exact31_scope_PREPARATION.json',enc(scope))
frozen={r['path']:{k:v for k,v in r.items()if k!='path'}for r in oldback['frozen2121_current_facts']}
def key(p):return str(G/p[6:]if p.startswith('res://')else Path(p)).replace('\\','/').casefold()
lookup={key(p):p for p in frozen};current={r['target']:copy.deepcopy(r)for r in oldback['current36']}
for r in dep['targets']:
 f=dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks']);p=lookup.get(key(r['target']))
 if p is not None:frozen[p]=f
 current[r['target']]=dict(target=r['target'],sha256=r['sha256'],bytes=r['bytes'],immutable_candidate=r['candidate_path'],current=f)
backs=copy.deepcopy(oldback['old436_backup_facts'])+[dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in oldback['new_backups']];assert len(backs)==461 and len(current)==36 and len(frozen)==2121
plan=dict(status='ROOT_ONLY_0860_CREATE_NEW31_PLAN_NOT_EXECUTED',scope=scopepin,parent_deployment=DEP,current31=[dict(**r,backup=B+'root_only_current31_backup/'+r['target'][6:])for r in scope['targets']],current36=list(current.values()),frozen2121_expected=frozen,save15_expected=oldback['save15'],old461_backup_facts=backs,media125=oldback['media_facts'],ui=oldback['ui'],Root_only_backup_prefix=B+'root_only_current31_backup/',expected_old_backup_total=461,expected_after_backup_total=492,canonical_writes=0,engine_calls=0)
planpin=emit('current_0860_backup31_ROOT_PLAN.json',enc(plan))
parenttool=read(dict(path=S+'Temple_actor_receipt_repair01/backup_current_E53E_25_ROOT_ONLY.py',sha256='148b3d5d2afb5666da547a5b9e5f8cc916acebc7121b46497b4e4a74ac2f2435'));tool=parenttool.decode();changes=[]
for a,b in [('CreateNew25','CreateNew31'),('Temple_actor_receipt_repair01/current_E53E_backup25_ROOT_PLAN.json','Estate_wall_source_repair01/current_0860_backup31_ROOT_PLAN.json'),('--root-authorized-backup25','--root-authorized-backup31'),('root_authorized_backup25','root_authorized_backup31'),('current25','current31'),('old436','old461'),('NEW25_BACKUP_MUST_BE_ABSENT','NEW31_BACKUP_MUST_BE_ABSENT'),('ROOT_CURRENT_E53E_FULL25_BACKUP_AND_FRESH_OBSERVATION','ROOT_CURRENT_0860_FULL31_BACKUP_AND_FRESH_OBSERVATION'),('ROOT_CURRENT_E53E_FRESH_OBSERVATION_ONLY','ROOT_CURRENT_0860_FRESH_OBSERVATION_ONLY'),('436+len(rows)','461+len(rows)')]:assert a in tool,a;tool=tool.replace(a,b);changes.append(dict(old=a,new=b))
back=tool
for h in reversed(changes):back=back.replace(h['new'],h['old'])
assert back.encode()==parenttool;compile(tool,'backup_current_0860_31_ROOT_ONLY.py','exec')
toolpin=emit('backup_current_0860_31_ROOT_ONLY.py',tool.encode());emit('backup31_tool_whole_inverse_NOT_EXECUTED.json',enc(dict(parent_sha256=sha(parenttool),candidate=toolpin,changes=changes,whole_byte_inverse=True,backup_calls=0,canonical_writes=0)))
# The missing two-row texture is resolved only through the fixed current Market map, never observed-current expectation filling.
marketpin=old['maps']['expected_ch4_s3_luoyang_market_true']['candidate'];market=load(marketpin)['source_sha256'];ypin=old['maps']['expected_ch4_s1_luoyang_yamen_true']['candidate'];yamen=load(ypin)['source_sha256'];seal=load(old['seal']);binding=load(seal['binding']);yr=binding['scenes']['ch4_s1_luoyang_yamen']
png='res://art/maps/luoyang_enclosure_v11/ch4_s3_luoyang_market/entities/v13_market_west_plot_wall.png';side=png+'.import';assert market[png]=='664cc0734eb126d8a0a0f591a276d0790d7382de18d18cc310e82e6f9dbb5bd0';sidebytes=read(dict(path=side,sha256=market[side]));remap=re.findall(r'^path="([^"\r\n]+)"\r?$',sidebytes.decode(),re.M);assert len(remap)==1;ctex=remap[0];tuple3={p:market[p]for p in [png,side,ctex]}
for p,h in tuple3.items():read(dict(path=p,sha256=h))
assert png not in yamen and png not in yr['required_source_sha256']
emit('Yamen_existing_wall_tuple_source_proposal_READONLY.json',enc(dict(status='ROOT_APPROVED_EXISTING_MARKET_TEXTURE_TUPLE_FOR_TWO_NEW_YAMEN_WALLS',authority=marketpin,parent_Yamen_map=ypin,parent_binding=seal['binding'],Yamen_new_ids=['edge05_yamen_west_archive_back_boundary','edge05_yamen_east_outer_service_boundary'],required_ordinary=tuple3,expected_gap='runtime.ensure captured or original.source_first must contain texture; both currently absent',existing_physical_bytes_match_fixed_authority=True,old_texture_identity_and_params_unchanged=True,no_reimport_or_pixel_or_geometry_or_NAV_changes=True,engine_calls=0,canonical_writes=0)))
print(json.dumps(dict(scope=scopepin,backup_plan=planpin,backup_tool=toolpin,tuple3=tuple3,build_only=True)))
