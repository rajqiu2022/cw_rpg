$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME';$oldDir='game/build/luoyang_entry_20261029l_qa01';$newDir='game/build/luoyang_gate_lowwalls_20261029m_qa01'
foreach($name in @('freeze_after_deploy.ps1','final_small_guard.ps1')){
 $text=[IO.File]::ReadAllText("$taskRoot/$oldDir/$name").Replace('luoyang_entry_20261029l_qa01','luoyang_gate_lowwalls_20261029m_qa01').Replace('entry_DRAFT.gd','walls_DRAFT.gd').Replace('entry_READY.json','walls_READY.json').Replace("'entry'","'walls'")
 $tokens=$null;$errors=$null;[System.Management.Automation.Language.Parser]::ParseInput($text,[ref]$tokens,[ref]$errors)|Out-Null;if($errors.Count){throw ($errors|Out-String)}
 $bytes=[Text.UTF8Encoding]::new($false).GetBytes($text);$path="$taskRoot/$newDir/$name";$stream=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
 [ordered]@{path=$path;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;mechanical_qa_tool_adaptation=$true;engine_calls=0}|ConvertTo-Json -Compress
}
