param([ValidateSet('freeze','apply')][string]$Mode='freeze',[string]$PlanSHA='')
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME';$gameRoot="$taskRoot/game";$qaRoot="$gameRoot/build/luoyang_yihongyuan_20261029n_qa01";$systemRoot=$qaRoot;$isolate="$qaRoot/art_import_ROOT"
$prepared=Get-Content -LiteralPath "$qaRoot/art_import_prepared_READY.json" -Raw|ConvertFrom-Json;$png=$prepared.source_png.Substring(6);$compiled=$prepared.compiled.Substring(6);$md5=$prepared.md5.Substring(6)
$expectedPng=$prepared.png_sha256;$rgba=$prepared.RGBA_sha256;$verifier=$prepared.verifier_sha256
function Fact([string]$p){if(-not[IO.File]::Exists($p)){return [ordered]@{exists=$false}};$f=Get-Item -LiteralPath $p;return [ordered]@{exists=$true;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=$f.Length;utc_ticks=$f.LastWriteTimeUtc.Ticks.ToString()}}
function Same($a,$b){return $a.exists-eq$b.exists-and(-not$a.exists-or($a.sha256-ceq$b.sha256-and$a.bytes-eq$b.bytes-and$a.utc_ticks-ceq$b.utc_ticks))}
function NewBytes([string]$p,[byte[]]$b){[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null;$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($b,0,$b.Length)}finally{$s.Dispose()}}
function NormalValue([string]$s){if($s-match'^-?\d+(\.\d+)?$'){return ([double]::Parse($s,[Globalization.CultureInfo]::InvariantCulture)).ToString('R',[Globalization.CultureInfo]::InvariantCulture)};return $s}
function Params([string]$p){$t=[IO.File]::ReadAllText($p);$pos=$t.IndexOf('[params]');if($pos-lt0){throw 'No texture params'};$rows=[ordered]@{};foreach($line in $t.Substring($pos+8).Split("`n")){$parts=$line.Trim().Split('=',2);if($parts.Count-eq2){if($rows.Contains($parts[0])){throw 'Repeated param'};$rows[$parts[0]]=NormalValue $parts[1]}};return $rows}
$planPath="$qaRoot/art_promotion_PLAN_READY.json"
if($Mode-eq'freeze'){
 $receiptPath="$systemRoot/art_verify01_actual_process_receipt.json";$receipt=Get-Content -LiteralPath $receiptPath -Raw|ConvertFrom-Json
 if($receipt.actual_natural_console_exit_code-ne0-or$receipt.script_sha256-cne$verifier-or$receipt.script_after_sha256-cne$verifier-or$receipt.process_stopped_by_tool-ne$false-or$receipt.exit_code_from_retained_process_WaitForExit-ne$true){throw 'Exact natural successful Root verifier required'}
 if((Fact "$isolate/verify_READY.gd").sha256-cne$verifier-or(Fact $receipt.stdout_path).sha256-cne$receipt.stdout_sha256){throw 'Verifier/actual stdout changed'}
 $stdout=[IO.File]::ReadAllText($receipt.stdout_path);if(@([regex]::Matches($stdout,'ART_IMPORT_LOSSLESS_RGBA '+$rgba+' size=1441x1206 old_art_changes=0')).Count-ne1){throw 'Actual RGBA must equal exact published published image, not merely self-equal'}
 if((Fact "$gameRoot/$png").sha256-cne$expectedPng-or(Fact "$isolate/$png").sha256-cne$expectedPng){throw 'Original published PNG changed'}
 $profile="$gameRoot/art/maps/luoyang_city_rebuild_20261027d/spring_house_complete_v1_padded.png.import";if((Fact $profile).sha256-cne'39618fab9bd5c7007fc2eb0f8442d3bdab09ccb69e2e0d1dc352f3aeee21a284'){throw 'Original lossless profile changed'}
 $expected=Params $profile;$actual=Params "$isolate/$png.import";if($expected.Count-ne23-or$actual.Count-ne23){throw 'Exactly23 original lossless params only'};foreach($key in $expected.Keys){if(-not$actual.Contains($key)-or$actual[$key]-cne$expected[$key]){throw "Import param differs: $key"}}
 $sidecar=[IO.File]::ReadAllText("$isolate/$png.import");if(-not$sidecar.Contains('source_file="res://'+$png+'"')-or-not$sidecar.Contains('path="res://'+$compiled+'"')-or-not$sidecar.Contains('dest_files=["res://'+$compiled+'"]')){throw 'Exact source/destination import URI required'}
 $leaves=@();foreach($relative in @(($png+'.import'),$compiled,$md5)){$source="$isolate/$relative";$target="$gameRoot/$relative";$sourceFact=Fact $source;if(-not$sourceFact.exists-or(Fact $target).exists){throw "Must be three valid isolated leaves and absent main targets: $relative"};$leaves+=@{source=$source;target=$target;source_fact=$sourceFact;target_before=(Fact $target)}}
 $plan=[ordered]@{status='ROOT_ONLY_EXACT_THREE_ART_IMPORT_LEAVES';verified_RGBA=$rgba;publication_png_sha256=$expectedPng;verifier_sha256=$verifier;verify_receipt_sha256=(Fact $receiptPath).sha256;leaves=$leaves;PNG_writes=0;engine_calls=0;promotions=0}
 NewBytes $planPath ([Text.UTF8Encoding]::new($false).GetBytes(($plan|ConvertTo-Json -Depth 12)+"`n"));[ordered]@{plan=$planPath;plan_sha256=(Fact $planPath).sha256;leaves=$leaves;engine_calls=0}|ConvertTo-Json -Depth 12;exit
}
if($PlanSHA-cnotmatch'^[a-fA-F0-9]{64}$'-or(Fact $planPath).sha256-cne$PlanSHA.ToLowerInvariant()){throw 'Root reviewed immutable plan SHA required'}
$plan=Get-Content -LiteralPath $planPath -Raw|ConvertFrom-Json
if($plan.status-cne'ROOT_ONLY_EXACT_THREE_ART_IMPORT_LEAVES'-or@($plan.leaves).Count-ne3-or$plan.verified_RGBA-cne$rgba-or(Fact "$gameRoot/$png").sha256-cne$expectedPng){throw 'Invalid reviewed3leaf plan'}
foreach($leaf in $plan.leaves){if(-not(Same (Fact $leaf.source) $leaf.source_fact)-or(Fact $leaf.target).exists){throw 'Source leaf changed or target no longer absent'}}
$promoted=@();foreach($leaf in $plan.leaves){NewBytes $leaf.target ([IO.File]::ReadAllBytes($leaf.source));[IO.File]::SetLastWriteTimeUtc($leaf.target,[DateTime]::new([long]$leaf.source_fact.utc_ticks,[DateTimeKind]::Utc));$now=Fact $leaf.target;if(-not(Same $now $leaf.source_fact)){throw 'Promoted leaf differs'};$promoted+=@{path=$leaf.target;fact=$now}}
$receipt=[ordered]@{status='ROOT_EXACT_THREE_ART_IMPORT_LEAVES_PROMOTED';plan_sha256=$PlanSHA.ToLowerInvariant();promoted=$promoted;PNG_writes=0;engine_calls=0;save_writes=0}
$out="$qaRoot/art_promotion_ROOT_ACTUAL.json";NewBytes $out ([Text.UTF8Encoding]::new($false).GetBytes(($receipt|ConvertTo-Json -Depth 12)+"`n"));[ordered]@{path=$out;sha256=(Fact $out).sha256;promoted=$promoted.Count;engine_calls=0}|ConvertTo-Json -Compress
