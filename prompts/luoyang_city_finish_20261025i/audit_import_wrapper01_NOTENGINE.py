"""Exact byte/text inverse of NEW wrapper versus old61; parser only, never execute."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[2]
OLD=ROOT/'game/build/luoyang_city_full_rollout_20261022ap_root01/integration61/run_external_isolate_once.ps1'
NEW=ROOT/'game/build/luoyang_city_finish_20261025i_art01/ten_media_import_logs_ROOT_ONLY/run_external_isolate_once.ps1'
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
def sha(b):return hashlib.sha256(b).hexdigest()
swaps=[
 ['F:/Code/RPG_GAME/assets/staging/luoyang_life_scholar_isolated_import_20261024ap98','F:/Code/RPG_GAME/game/build/luoyang_city_finish_20261025i_art01/ten_media_isolate_ROOT_PREPARED'],
 ['F:/Code/RPG_GAME/game/build/luoyang_city_full_rollout_20261022ap_root01/integration61','F:/Code/RPG_GAME/game/build/luoyang_city_finish_20261025i_art01/ten_media_import_logs_ROOT_ONLY'],
 ['preparation_receipt_READY.json','preparation_receipt.json'],
 ['c075f0004ca6c9b9452919e0a57943b8507288c74ca02633148f68d383afb14e','e9fdaad7bebb41f90d3d42f511a8adadddd26a75f0a7ea3d58b390a4f1040a7a'],
 ['1ff1c4f67643183cfa379a8040316a8dd0cdcbf4f0fd89574893f89c0b851188','061081ea928e7d195cd2196b589f1bf974f91a3bae46c30b5f0123600a55f960'],
 ['c6612deb3623e533b9070731e2e3848541f326f9bb3b31253a72268001cd7c87','7963ca8a9fa725d60d7d44cdb85b2896a55d1506a66b148db57fee3ddffeee95'],
 ['main_five_absent_targets','main_two_absent_targets']]
old=OLD.read_bytes();new=NEW.read_bytes();ot=old.decode();nt=new.decode()
expected=ot
for a,b in swaps:assert expected.count(a)==1;expected=expected.replace(a,b)
# apply_patch emits LF; preserve old trailing newline semantics explicitly in inverse.
assert expected.replace('\r\n','\n')==nt.replace('\r\n','\n')
inverse=nt
for a,b in reversed(swaps):assert inverse.count(b)==1;inverse=inverse.replace(b,a)
assert inverse.replace('\r\n','\n')==ot.replace('\r\n','\n')
restored=inverse.replace('\r\n','\n').replace('\n','\r\n').encode() if b'\r\n' in old else inverse.encode()
assert restored==old
spec=json.loads((OUT/'ten_media_isolate_ROOT_PREPARED/prepared_READY.json').read_bytes())
assert len(spec['main_two_absent_targets'])==30 and all(not Path(p).exists() for p in spec['main_two_absent_targets'])
for p in ['external_import_actual_stdout.log','external_import_actual_stderr.log','external_import_actual_process_receipt.json','external_verify_actual_stdout.log','external_verify_actual_stderr.log','external_verify_actual_process_receipt.json']:assert not (NEW.parent/p).exists()
import difflib
diff=''.join(difflib.unified_diff(ot.splitlines(keepends=True),nt.splitlines(keepends=True),fromfile=OLD.relative_to(ROOT).as_posix(),tofile=NEW.relative_to(ROOT).as_posix()))
newreport={'status':'NEW_MECHANICAL_WRAPPER_SOURCE_INVERSE_PASS_NOT_EXECUTED','old_path':OLD.relative_to(ROOT).as_posix(),'old_sha256':sha(old),'new_path':NEW.relative_to(ROOT).as_posix(),'new_sha256':sha(new),'swaps':swaps,'old_line_ending':'CRLF' if b'\r\n' in old else 'LF','new_line_ending':'CRLF' if b'\r\n' in new else 'LF','inverse_exact_old_bytes':True,'inverse_original_SHA256':sha(restored),'all_other_body_text_identical':True,'30_main_targets_ABSENT':True,'six_new_logs_ABSENT':True,'preserved_guards':['protected_main_sources SHA','new targets ABSENT','otherGodot excludesonlyeditor51856, neverstop','oldlog preservation','two phases;verify requirespriornaturalimportexit0','Start-Process Hidden','retainedProcess.WaitForExit actual natural exit','no main promotion'],'engine_calls':0,'wrapper_executions':0}
for path,b in [(OUT/'ten_media_import_wrapper01_exact_inverse.json',(json.dumps(newreport,indent=2)+'\n').encode()),(OUT/'ten_media_import_wrapper01_exact.diff',diff.encode())]:
    assert not path.exists()
    with path.open('xb') as f:f.write(b)
print(json.dumps(newreport))
