from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/'
old=(N/'guard_repair31_current2121_ROOT_ONLY.py').read_bytes();text=old.decode();changes=[]
for a,b in [('gate_texture_repair01/current4160_backup32_ROOT_ACTUAL.json','market_ground_texture_repair02/current5D6C_backup25_ROOT_ACTUAL.json'),('392b00f8fb19e36d58c7f2207ba6ad34f31c7f4f04991d7c05f295e39e962431','c0a57be99104c703df9ef876a7168821497a448242c2acc86457acae4c32169a'),('repair31_READY03','market_ground25_READY01'),('319fc714cb589608c9dc200d47d7e517abc534fc2e540073eee9f3f3b9044a98','c699076933993a1fbdc89981b2d606260318dc764b543b85a45ea9c56dc395a4'),('GATE_TEXTURE_MARKET_PORTAL_EXACT31_STAGED_NOT_DEPLOYED','MARKET_AE_TEXTURE_EXACT25_STAGED_NOT_DEPLOYED'),('dict(patch_count=17,copy_count=14,total=31)','dict(patch_count=11,copy_count=14,total=25)'),('ROOT_REPAIR31_DEPLOYED_GD17_PATCH_JSON14_EXACTCOPY','ROOT_MARKET_AE25_DEPLOYED_GD11_PATCH_JSON14_EXACTCOPY'),('len(st)==31','len(st)==25'),("'exact31'","'exact25'"),('old208_backup_facts','old240_backup_facts'),("'old208_backups_exactticks'","'old240_backups_exactticks'"),("'new32_backups_exactticks'","'new25_backups_exactticks'"),('ROOT_REPAIR31_POST_CURRENT2121_READONLY_GUARD','ROOT_MARKET_AE25_POST_CURRENT2121_READONLY_GUARD'),('backups_total=240','backups_total=265'),('authorized_targets=31','authorized_targets=25')]:
 assert a in text,a;text=text.replace(a,b);changes.append(dict(old=a,new=b))
back=text
for h in reversed(changes):back=back.replace(h['new'],h['old'])
assert back.encode()==old;compile(text,'guard_Market_ground25_current2121_ROOT_ONLY.py','exec');raw=text.encode();p=N/'guard_Market_ground25_current2121_ROOT_ONLY.py'
with p.open('xb')as f:f.write(raw)
print(json.dumps(dict(path=S+p.name,sha256=hashlib.sha256(raw).hexdigest(),bytes=len(raw),whole_parent_byte_inverse=True,engine_calls=0)))
