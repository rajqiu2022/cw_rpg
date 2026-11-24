"""Freeze import/verify retained-process launchers; never run them here."""
from pathlib import Path
import hashlib,json
B=Path(__file__).resolve().parent;G=B.parents[1];OLD=G/'build/luoyang_city_revision_20261024c_source01'
N=B/'market_mask_import01';I=G.parent/'assets/staging/luoyang_market_blocks_mask_20261024e_import01'
R=G/'build/luoyang_city_revision_20261024e_root01'
def sha(b):return hashlib.sha256(b).hexdigest()
def put(name,raw):
    p=N/name;assert not p.exists();p.write_bytes(raw);return dict(path=p.as_posix(),sha256=sha(raw),bytes=len(raw))
raw=(OLD/'import_courts_mask_once_ROOTONLY.ps1').read_bytes();text=raw.decode('utf8')
ops=[('F:/Code/RPG_GAME/assets/staging/luoyang_yamen_courts_mask_20261024c_import',I.as_posix()),
 ('F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024c_root01/courts_mask_isolate_import_once',(R/'market_mask_import01_once').as_posix()),
 ('7c7140e25a1c0922eebffb7ee53a261ab0e60dc4e1f31be9695d0555fef13006',sha((I/'prepared_READY.json').read_bytes())),
 ('fc0cd5abf77ce34288683640264a5c19868e703d47a570117230479e6bd83376',sha((I/'verify_READY.gd').read_bytes())),
 ('f4dd4753edbb5183686a20dc084adb5ff3a2e159d07cafa92c86340204902051',sha((I/'project.godot').read_bytes())),
 ('EXACT_ONE_COURTS_OVERLAY_MASK_ISOLATED_IMPORT_PREPARED','EXACT_ONE_MARKET_BLOCK_OVERLAY_MASK_ISOLATED_IMPORT_PREPARED'),
 ('18eee16cb341f01a984acd1f260dd1511e0e543e0d61b90789cef3f960d5712a','63c08eb5de773549676d6352de5772f56201c6061fe9320c4de1ef08ee312a85'),
 ('@($spec.protected_main_sources.Keys)){$protected[$p]=Fact $p}', '@($spec.protected_main_sources.Keys)+@($spec.save_paths)){$protected[$p]=Fact $p}')]
for a,b in ops:assert text.count(a)==1,(a,text.count(a));text=text.replace(a,b,1)
back=text
for a,b in reversed(ops):assert back.count(b)==1;back=back.replace(b,a,1)
assert back.encode('utf8')==raw
imp=put('import_once_ROOTONLY.ps1',text.encode('utf8'))
verify=text.replace((R/'market_mask_import01_once').as_posix(),(R/'market_mask_verify01_once').as_posix(),1)
a="@('--headless','--editor','--import','--path',$project,'--quit')";b="@('--headless','--path',$project,'--script','res://verify_READY.gd')"
assert verify.count(a)==1;verify=verify.replace(a,b,1)
assert verify.count('ONLY_ONE_PUBLISHED_OVERLAY_MASK_ISOLATED_EDITOR_IMPORT_NOT_NATIVE_VERIFY')==1
verify=verify.replace('ONLY_ONE_PUBLISHED_OVERLAY_MASK_ISOLATED_EDITOR_IMPORT_NOT_NATIVE_VERIFY','ONLY_ONE_PUBLISHED_OVERLAY_MASK_ISOLATED_NATIVE_VERIFY_NOT_IMPORT',1)
ver=put('verify_once_ROOTONLY.ps1',verify.encode('utf8'))
prepared=json.loads((I/'prepared_READY.json').read_bytes());texture=prepared['textures'][0]
proof=put('root_launcher_inverse_NOTRUN.json',(json.dumps(dict(status='ROOT_RETAINED_LAUNCHERS_PREPARED_NOT_RUN',import_launcher=imp,verify_launcher=ver,
 parent_import_launcher_sha256=sha(raw),import_replacements=[dict(old=a,new=b) for a,b in ops],import_wholebyte_inverse=True,
 verifier_only_command_and_unique_logstem_successor=True,prepared_sha256=sha((I/'prepared_READY.json').read_bytes()),verifier_sha256=sha((I/'verify_READY.gd').read_bytes()),
 isolate=I.as_posix(),two_main_targets_absent=prepared['main_two_absent_targets'],optional_isolate_md5=texture['compiled'][:-5]+'.md5',
 optional_md5_not_runtime_source=True,CreateNew_promotion='Not authorized by these launchers; Root will separately admit actual2 oroptional3 leaves.',
 guard='Actual current15saves + source docs/mainPNG/seed profile + prepared/key/project/launcher SHA bytes exactticks. No user process kill; only editor51856 permitted; retained own WaitForExit and natural ExitCode.',
 engine_calls_by_Source=0,formal_writes=0),ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(dict(import_launcher=imp,verify_launcher=ver,proof=proof)))
