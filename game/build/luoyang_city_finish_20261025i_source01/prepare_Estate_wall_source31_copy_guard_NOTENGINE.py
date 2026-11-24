"""Mechanical variants of the reviewed exact JSON transport/readonly guard, not executed."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/';B=S+'Estate_wall_source_repair01/';proof=[]
sha=lambda b:hashlib.sha256(b).hexdigest()
for oldname,newname in [('copy_Temple_actor_receipt25_JSON14_after_GD11_ROOT_ONLY.py','copy_Estate_wall_source31_JSON14_after_GD17_ROOT_ONLY.py'),('guard_Temple_actor_receipt25_current2121_ROOT_ONLY.py','guard_Estate_wall_source31_current2121_ROOT_ONLY.py')]:
 parent=(N/oldname).read_bytes();t=parent.decode();changes=[]
 common=[('Temple_actor_receipt_repair01/current_E53E_exact25_scope_PREPARATION.json','Estate_wall_source_repair01/current_0860_exact31_scope_PREPARATION.json'),('f3736e4206935a35f5055bf0d7518f2ef1941e554329e7e6e828a29ba676e974','3282faaa05a467ddf11315b78001c84705a036d9eb015802488882fd720ea957'),('Temple_actor_receipt_repair01/current_E53E_backup25_ROOT_ACTUAL.json','Estate_wall_source_repair01/current_0860_backup31_ROOT_ACTUAL.json'),('6cbdb68683733bc819978936225476bf4bf5ff16b2efb7f01b05a7af23b9e6bf','ad48454d8798b51b1076fe1482f842373ed78cd2b96a29a7053caaa90c6a631e'),('TEMPLE_ACTOR_RECEIPT_EXACT25_STAGED_NOT_DEPLOYED','ESTATE_WALL_SOURCE_EXACT31_STAGED_NOT_DEPLOYED'),('ROOT_TEMPLE_ACTOR_RECEIPT25','ROOT_ESTATE_WALL_SOURCE31'),('dict(patch_count=11,copy_count=14,total=25)','dict(patch_count=17,copy_count=14,total=31)'),('old436','old461'),('GD11','GD17'),('target_count=25','target_count=31'),('targets=25','targets=31'),('len(targets)==25','len(targets)==31'),('len(st)==25','len(st)==31'),('new25_backups','new31_backups'),('exact25','exact31'),('backups_total=461','backups_total=492'),('authorized_targets=25','authorized_targets=31')]
 if oldname.startswith('copy'):common.extend([('current E53E immutable parent; only Temple receipt bridge logic plus source pins','current0860 immutable parent; Estate type/scale repair and Yamen existing tuple only'),("backup['total_backups']==461","backup['total_backups']==492"),('backup_count=461','backup_count=492'),('current_E53E_backup_sha256','current_0860_backup_sha256')])
 else:common.extend([('Temple_actor_receipt_repair01/unified25_READY01/unified25_ROOT_BACKUP_FIXED_NOT_STAGE.json','Estate_wall_source_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),('71b482ffa28debabfe7c3ed39b77d266745cdbda5b24dbdad41de88344c18549','ccd21474dd1a99ef33b6a965da522190e4ad811f237bed3671430f5007cb7b54')])
 for a,b in common:
  if a in t:t=t.replace(a,b);changes.append(dict(old=a,new=b))
 back=t
 for h in reversed(changes):back=back.replace(h['new'],h['old'])
 assert back.encode()==parent;compile(t,newname,'exec');dest=N/newname;assert not dest.exists();raw=t.encode()
 with dest.open('xb')as f:f.write(raw)
 pin=dict(path=S+newname,sha256=sha(raw),bytes=len(raw));proof.append(dict(parent=dict(path=S+oldname,sha256=sha(parent)),candidate=pin,changes=changes,whole_byte_inverse=True));print(json.dumps(pin))
raw=(json.dumps(dict(status='ROOT_ONLY_JSON14_TRANSPORT_AND_GUARD_NOT_EXECUTED',proofs=proof,copy_calls=0,guard_calls=0,Stage_calls=0,engine_calls=0,canonical_writes=0),ensure_ascii=False,indent=2)+'\n').encode();p=N/'Estate_wall_source_repair01/copy_guard_mechanical_inverse_NOT_EXECUTED.json';assert not p.exists()
with p.open('xb')as f:f.write(raw)
print(json.dumps(dict(path=B+p.name,sha256=sha(raw))))
