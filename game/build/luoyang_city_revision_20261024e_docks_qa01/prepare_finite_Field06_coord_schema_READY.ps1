$ErrorActionPreference='Stop'
$parent=Join-Path $PSScriptRoot 'finite_Field05_EXACT31_READY/test_READY.gd'
$out=Join-Path $PSScriptRoot 'finite_Field06_COORD_SCHEMA_READY'
if((Get-FileHash -LiteralPath $parent).Hash-cne'D806D72812997A3C83011C321B12E01A41F4FF1536F7FF1589585A94F679DD17'){throw 'frozen05 changed'}
if(Test-Path -LiteralPath $out){throw 'NEW only'}
$oldCondition='fixture.paths.approaches.size()==3 and fixture.inspection_starts==[[600,1610],[1860,748],[638,670]] and fixture.Root_authorized_inspection_position_writes==3'
$newCondition='fixture.paths.approaches.size()==3 and fixture.inspection_starts is Array and fixture.inspection_starts.size()==3 and fixture.Root_authorized_inspection_position_writes==3'
$anchor="`tfor path: String in fixture.source_sha256:"
$coords=@'
	# JSON coordinates are TYPE_FLOAT; normalize through the exact same Vector2
	# source schema as the body/Field. No raw int-Array wire equality or epsilon.
	var fixed_starts: Array=[Vector2(600,1610),Vector2(1860,748),Vector2(638,670)]
	for i: int in range(3):
		var raw_start: Variant=fixture.inspection_starts[i]
		if not check(raw_start is Array and raw_start.size()==2 and typeof(raw_start[0]) in [TYPE_INT,TYPE_FLOAT] and typeof(raw_start[1]) in [TYPE_INT,TYPE_FLOAT],"Inspection source coordinate schema "+str(i)): return false
		if not check(_v(raw_start)==fixed_starts[i],"Exact source Vector2 inspection foot, no epsilon "+str(i)): return false
'@
$coords=$coords.Replace('\t',"`t").Replace("`r`n","`n")
$reps=@(@{old=$oldCondition;new=$newCondition},@{old=$anchor;new=($coords+"`n"+$anchor)},@{old='finite_Field04_output/';new='finite_Field06_output/'})
$old=[IO.File]::ReadAllText($parent);$new=$old
foreach($r in $reps){if(([regex]::Matches($new,[regex]::Escape($r.old))).Count-ne1){throw 'unique hunk'};$new=$new.Replace($r.old,$r.new)}
$back=$new;for($i=$reps.Count-1;$i-ge0;$i--){$back=$back.Replace($reps[$i].new,$reps[$i].old)};if($back-cne$old){throw 'whole inverse'}
$null=New-Item -ItemType Directory -Path $out
[IO.File]::WriteAllText((Join-Path $out 'test_READY.gd'),$new,[Text.UTF8Encoding]::new($false))
$sha=(Get-FileHash -LiteralPath (Join-Path $out 'test_READY.gd')).Hash
$prior=Join-Path $PSScriptRoot 'finite_Field04_output/108936_2897/result.json'
$proof=@{status='NEW_QA_COORDINATE_SCHEMA_ONLY_OLD05_FAIL_PRESERVED';parent_sha256='d806d72812997a3c83011c321b12e01a41f4ff1536f7ff1589585a94f679dd17';candidate_sha256=$sha;fixture_unchanged_path='res://build/luoyang_city_revision_20261024e_docks_qa01/finite_Field05_EXACT31_READY/fixture_READY.json';fixture_unchanged_sha256='d149d1c364ab8cbe13eed12dc05768bfcabf4a09a064fac3bcb4fea8a0ca88d2';old_whole_FAIL=@{path='res://build/luoyang_city_revision_20261024e_docks_qa01/finite_Field04_output/108936_2897/result.json';sha256=(Get-FileHash -LiteralPath $prior).Hash;checks=7;failures=2;Field_entered=$false};hunks=$reps;whole_forward_inverse=$true;EOF_preserved=$true;whole_ms=60000;entry_ms=20000;inspection_setups=3;endpoint_tolerance_unchanged=.3;coordinate_epsilon_added=0;production_or_Source_changes=0;engine=0;finish_scope_cascade='base finish only requires complete && Time<deadline; no extra fixture domain missing'}
[IO.File]::WriteAllText((Join-Path $out 'whole_byte_delta_READY.json'),($proof|ConvertTo-Json -Depth 35),[Text.UTF8Encoding]::new($false))
@{script_sha256=$sha;proof_sha256=(Get-FileHash -LiteralPath (Join-Path $out 'whole_byte_delta_READY.json')).Hash}|ConvertTo-Json -Compress
