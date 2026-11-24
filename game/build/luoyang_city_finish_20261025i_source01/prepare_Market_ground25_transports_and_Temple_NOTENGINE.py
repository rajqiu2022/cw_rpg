from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def write(name,b):
 p=N/name
 with p.open('xb')as f:f.write(b)
 return dict(path=S+name,sha256=sha(b),bytes=len(b))
text=(N/'copy_repair31_JSON14_after_GD17_ROOT_ONLY.py').read_text()
changes=[('GD17','GD11'),('GATE_TEXTURE_MARKET_PORTAL_EXACT31_STAGED_NOT_DEPLOYED','MARKET_AE_TEXTURE_EXACT25_STAGED_NOT_DEPLOYED'),('dict(patch_count=17,copy_count=14,total=31)','dict(patch_count=11,copy_count=14,total=25)'),
('gate_texture_repair01/closure_READY01/current4160_repair31_scope_PREPARATION.json','market_ground_texture_repair02/current5D6C_exact25_scope_PREPARATION.json'),('227681de2bf6c156427f147b992e8945b18648c12c57f2eaf1041bc32d86644b','a0f69caeec43fc22c0edf9af4898375aa2404b7c945873783bad201ba3624fa5'),('gate_texture_repair01/current4160_backup32_ROOT_ACTUAL.json','market_ground_texture_repair02/current5D6C_backup25_ROOT_ACTUAL.json'),('392b00f8fb19e36d58c7f2207ba6ad34f31c7f4f04991d7c05f295e39e962431','c0a57be99104c703df9ef876a7168821497a448242c2acc86457acae4c32169a'),
("backup['unexpected32_code_drift']==[]and backup['external_save_changes']==[]and backup['total_backups']==240","backup['external_save_changes']==[]and backup['total_backups']==265"),
("len(targets)==31 and set(targets)=={r['target']for r in scope['targets']}and set(old)-set(targets)=={scope['excluded_noop_G']}","len(targets)==25 and set(targets)==set(old)=={r['target']for r in scope['targets']}"),
('old208_backup_facts','old240_backup_facts'),('ROOT_REPAIR31_DEPLOYED_GD11_PATCH_JSON14_EXACTCOPY','ROOT_MARKET_AE25_DEPLOYED_GD11_PATCH_JSON14_EXACTCOPY'),('ROOT_REPAIR_GD11_NEW_JSON14_OLD_PREFLIGHT_ONLY','ROOT_MARKET_AE25_GD11_NEW_JSON14_OLD_PREFLIGHT_ONLY'),('target_count=31','target_count=25'),('backup_count=240','backup_count=265'),('current4160_backup_sha256','current5D6C_backup_sha256'),('targets=31','targets=25')]
for a,b in changes:assert a in text,a;text=text.replace(a,b)
compile(text,'copy_Market_ground25_JSON14_after_GD11_ROOT_ONLY.py','exec');cp=write('copy_Market_ground25_JSON14_after_GD11_ROOT_ONLY.py',text.encode())
text=(N/'prepare_repair31_Temple_natural_source_expectation_NOTENGINE.py').read_text()
for a,b in [('repair31_READY03','market_ground25_READY01'),('319fc714cb589608c9dc200d47d7e517abc534fc2e540073eee9f3f3b9044a98','c699076933993a1fbdc89981b2d606260318dc764b543b85a45ea9c56dc395a4'),('repair31_Temple_natural_session_sources_READONLY.json','Market_ground25_Temple_natural_session_sources_READONLY.json')]:assert a in text,a;text=text.replace(a,b)
exec(compile(text,str(N/'prepare_Market_ground25_Temple_DERIVED.py'),'exec'),{'__file__':str(N/'prepare_Market_ground25_Temple_DERIVED.py')})
print('COPY',json.dumps(cp))
