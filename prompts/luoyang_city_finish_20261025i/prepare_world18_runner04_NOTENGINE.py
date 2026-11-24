"""NEW exact-parent external runner text. Does not run/copy/import media."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01/world24d_heads01/world18_ingress04'
OLD=ROOT/'game/build/luoyang_city_finish_20261025i_art01/ten_media_import_logs_ROOT_ONLY/run_external_isolate_once.ps1'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def new(p,b):
    assert not p.exists(),p;p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as h:h.write(b)
def main():
    assert sha(OLD)=='7be4934a8f30add6ac08e8b9560df5a73b06bb0d409d9829c7a34ef2a04580b3'
    iso=OUT/'isolate_ROOT_PREPARED'
    pins={'preparation_receipt.json':'6c64c0fe44b6ce75d9ef457f9a8dd1f1ce7be6609a6dae16f124a2b27fd96d79','prepared_READY.json':'24a0f378fcd5a900c3724b9845fd6f7c83022481e0751afee11b0a3e97c3c5b6','verify_READY.gd':'3fac8446eebbbeefa19d84f8e268c4bcaee4fc0e3301bd4f361b9c8594124160'}
    for k,v in pins.items():assert sha(iso/k)==v
    before=OLD.read_text(encoding='utf-8');text=before
    swaps=[("$isolate='F:/Code/RPG_GAME/game/build/luoyang_city_finish_20261025i_art01/ten_media_isolate_ROOT_PREPARED'","$isolate='"+iso.as_posix()+"'"),
      ("$taskRoot='F:/Code/RPG_GAME/game/build/luoyang_city_finish_20261025i_art01/ten_media_import_logs_ROOT_ONLY'","$taskRoot='"+(OUT/'logs').as_posix()+"'"),
      ('e9fdaad7bebb41f90d3d42f511a8adadddd26a75f0a7ea3d58b390a4f1040a7a',pins['preparation_receipt.json']),
      ('061081ea928e7d195cd2196b589f1bf974f91a3bae46c30b5f0123600a55f960',pins['prepared_READY.json']),
      ('7963ca8a9fa725d60d7d44cdb85b2896a55d1506a66b148db57fee3ddffeee95',pins['verify_READY.gd'])]
    helper='''function SaveFactsMatch($facts){
 foreach($p in $facts.Keys){
  $v=$facts[$p];$present=Test-Path -LiteralPath $p
  if($present -ne $v.exists){return $false}
  if($present){$s=Get-Item -LiteralPath $p;if((Sha $p) -cne $v.sha256 -or $s.Length -ne $v.bytes -or [string]$s.LastWriteTimeUtc.Ticks -cne $v.ticks){return $false}}
 }
 return $true
}
'''
    anchor='function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}\n'
    swaps.append((anchor,anchor+helper))
    anchor='$spec=Get-Content -Raw -LiteralPath "$isolate/prepared_READY.json"|ConvertFrom-Json -AsHashtable\n'
    swaps.append((anchor,anchor+"if($spec.all15_save_facts.Count -ne 15 -or !(SaveFactsMatch $spec.all15_save_facts)){throw 'ALL_FIFTEEN_SAVE_EXISTS_SHA_BYTES_EXACTTICKS_BEFORE_REQUIRED'}\nforeach($p in $spec.protected_absent_sources){if(Test-Path -LiteralPath $p){throw 'ABSENT_SAVE_MUST_REMAIN_ABSENT_BEFORE'}}\n"))
    anchor='$process.WaitForExit();$timer.Stop();$code=$process.ExitCode\n'
    swaps.append((anchor,anchor+"$savesAfter=SaveFactsMatch $spec.all15_save_facts\n$absentAfter=$true;foreach($p in $spec.protected_absent_sources){if(Test-Path -LiteralPath $p){$absentAfter=$false}}\n"))
    anchor='$f=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew);'
    swaps.append((anchor,"$record.all15_save_exists_SHA_bytes_exactticks_unchanged=$savesAfter\n$record.original_absent_saves_still_absent_after=$absentAfter\n"+anchor))
    swaps.append(('exit $code\n',"if(!$savesAfter -or !$absentAfter){exit 1}\nexit $code\n"))
    for a,b in swaps:assert text.count(a)==1,a;text=text.replace(a,b)
    restored=text
    for a,b in reversed(swaps):assert restored.count(b)==1;restored=restored.replace(b,a)
    assert restored.encode()==OLD.read_bytes()
    runner=OUT/'logs/run_external_isolate_once.ps1';new(runner,text.encode())
    receipt={'status':'EXACT_PARENT_NEW_WORLD18_EXTERNAL_RUNNER_NOT_EXECUTED','old_path':str(OLD),'old_sha256':sha(OLD),'runner_path':str(runner),'runner_sha256':sha(runner),'fixed_isolate_files':pins,'swaps':[{'old':a,'new':b} for a,b in swaps],'whole_parent_byte_inverse':True,'restored_sha256':hashlib.sha256(restored.encode()).hexdigest(),'Hidden_retained_WaitForExit_natural_exit_preserved':True,'oldlogs_and_partial03_preserved':True,'user_editor51856_not_stopped':True,'canonical_copy':0,'engine_calls':0}
    new(OUT/'world18_runner04_exact_inverse.json',(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n').encode())
    print(json.dumps({'runner':str(runner),'runner_sha256':sha(runner),'inverse_sha256':sha(OUT/'world18_runner04_exact_inverse.json'),'engine':0}))
if __name__=='__main__':main()
