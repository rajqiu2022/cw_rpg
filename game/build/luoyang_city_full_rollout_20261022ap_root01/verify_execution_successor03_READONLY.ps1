$ErrorActionPreference='Stop'
$GameRoot='F:\Code\RPG_GAME\game'
function Res([string]$p){Join-Path $GameRoot $p.Substring(6)}
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Wire($value){ConvertTo-Json -InputObject $value -Depth 100 -Compress}
function ExactInverse($row){
 $inverse=[IO.File]::ReadAllText((Res $row.candidate.path))
 if((Sha (Res $row.candidate.path)) -cne $row.candidate.sha256 -or (Sha (Res $row.parent_path)) -cne $row.parent_sha256){throw 'Dependency SHA'}
 foreach($replacement in $row.replacements){
  if($inverse.Split([string[]]@($replacement.new),[StringSplitOptions]::None).Count -ne 2){throw 'Unique dependency replacement'}
  $inverse=$inverse.Replace($replacement.new,$replacement.old)
 }
 if([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($inverse)) -cne [Convert]::ToBase64String([IO.File]::ReadAllBytes((Res $row.parent_path)))){throw 'Entire dependency byte inverse'}
}
$Directory='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/unified06_dependencies03/'
$HandoffPath=Res ($Directory+'handoff_READY.json')
if((Sha $HandoffPath) -cne 'b2e73b62b7b0347c3ce9acc25a792a7e7adc8e026d92574a60e4fc22a8cad9d0'){throw 'Exact successor03 handoff'}
$Handoff=Get-Content -LiteralPath $HandoffPath -Raw|ConvertFrom-Json -AsHashtable
if($Handoff.execution_parent.sha256 -cne '0d06352a55047d6e39559e6f605976086b71149f195fa29017d9e5870a011dbb' -or $Handoff.execution_proposal.sha256 -cne 'a3880503360b0aa8ef745928e3f5f0effc452fc28cba773e3001122e30315a75'){throw 'Root exact0D06 toA388 only'}
if((Sha (Res $Handoff.execution_parent.path)) -cne $Handoff.execution_parent.sha256 -or (Sha (Res $Handoff.execution_proposal.path)) -cne $Handoff.execution_proposal.sha256){throw 'Frozen execution bytes'}
$Prior=Get-Content -LiteralPath (Res $Handoff.execution_parent.path) -Raw|ConvertFrom-Json -AsHashtable
$Next=Get-Content -LiteralPath (Res $Handoff.execution_proposal.path) -Raw|ConvertFrom-Json -AsHashtable
$Expected=@{
 'res://scripts/autoload/scene_router.gd'='60cf6de154dbf07546e0a59e941af392a442b71178af59eb7cdca5da1eeab0eb'
 'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'='71beb2e1181d8e9fe337dcd50571628c289304f3a38e7d054973eaee4e812a87'
 'res://scripts/city/luoyang_temple_assembly_20261016.gd'='8e8f8e3c2b1c3f8715c7d7ddaf48f3b14e5c5abcf5b8818ecdb7ee29c1958ff8'
}
if($Handoff.owned_changed_exactly3.Count -ne 3 -or $Prior.owned.Count -ne 10 -or $Next.owned.Count -ne 10 -or $Prior.source_sha256.Count -ne 44 -or $Next.source_sha256.Count -ne 50){throw 'Exact domains'}
foreach($Entry in $Handoff.owned_changed_exactly3){
 $Path=$Entry.target;$OldRow=$Prior.owned[$Path];$NewRow=$Next.owned[$Path]
 if(-not $Expected.ContainsKey($Path) -or $Expected[$Path] -cne $Entry.candidate.sha256 -or $NewRow.current_sha256 -cne $Entry.candidate.sha256 -or $NewRow.edges.Count -ne ($OldRow.edges.Count+1)){throw 'Root precise appended edge'}
 $Edge=$NewRow.edges[-1]
 if((Wire $Edge) -cne (Wire $Entry.edge)){throw 'Edge declaration identity'}
 if((Sha (Res $Edge.old_snapshot)) -cne $Edge.old_sha256 -or (Sha (Res $Edge.new_snapshot)) -cne $Edge.new_sha256){throw 'Both immutable edge snapshots'}
 $Inverse=[IO.File]::ReadAllText((Res $Edge.new_snapshot))
 foreach($Replacement in $Edge.replacements){
  if($Inverse.Split([string[]]@($Replacement.new),[StringSplitOptions]::None).Count -ne 2){throw 'Unique runtime String replacement'}
  $Inverse=$Inverse.Replace($Replacement.new,$Replacement.old)
 }
 if([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Inverse)) -cne [Convert]::ToBase64String([IO.File]::ReadAllBytes((Res $Edge.old_snapshot)))){throw 'Entire runtime byte inverse'}
 $NewRow.current_sha256=$OldRow.current_sha256;$NewRow.edges=@($NewRow.edges|Select-Object -First $OldRow.edges.Count)
}
foreach($Path in $Prior.source_sha256.Keys){if($Next.source_sha256[$Path] -cne $Prior.source_sha256[$Path]){throw 'Old44 proof preserved'}}
foreach($Path in @($Next.source_sha256.Keys)){if(-not $Prior.source_sha256.Contains($Path)){$Next.source_sha256.Remove($Path)}}
if((Wire $Next) -cne (Wire $Prior)){throw 'Entire executable succession inverse'}
if((Sha (Res $Handoff.dependency_proof.path)) -cne $Handoff.dependency_proof.sha256){throw 'Dependency proof pin'}
$Proof=Get-Content -LiteralPath (Res $Handoff.dependency_proof.path) -Raw|ConvertFrom-Json
foreach($Name in @('contract','coordinator','temple_binding','temple')){ExactInverse $Proof.$Name}
@{passed=$true;exact_owned_appended=3;original_owned_rows_restored=10;old_proof_pins_preserved=44;new_proof_pins=6;dependency_byte_inverses=4;proposal_sha256=$Handoff.execution_proposal.sha256;canonical_written=$false}|ConvertTo-Json


