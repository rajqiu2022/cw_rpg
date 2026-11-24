param(
 [string]$Manifest='F:/Code/RPG_GAME/assets/specs/luoyang_resident_voice_trial_20261019v.json',
 [string]$OutputDirectory='F:/Code/RPG_GAME/assets/processed/luoyang_resident_life_20261019v/voice_trial02_offline'
)
$ErrorActionPreference='Stop'
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$assetRoot=[IO.Path]::GetFullPath((Join-Path $projectRoot 'assets'))+[IO.Path]::DirectorySeparatorChar
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(-not $destination.StartsWith($assetRoot,[StringComparison]::OrdinalIgnoreCase)){throw 'Offline candidates must remain below project assets'}
$inputData=Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json
if($inputData.status -ne 'CANDIDATE' -or $inputData.lines.Count -ne 8){throw 'Expected exact eight-line candidate trial'}
$profiles=@{
 '老纸匠'=@{name='Microsoft Kangkang';rate=-2}
 '采买妇人'=@{name='Microsoft Huihui';rate=0}
 '装卸伙计'=@{name='Microsoft Kangkang';rate=1}
 '货担主人'=@{name='Microsoft Kangkang';rate=-1}
}
Add-Type -AssemblyName System.Speech
$probe=New-Object System.Speech.Synthesis.SpeechSynthesizer
try{$voices=@($probe.GetInstalledVoices() | Where-Object {$_.Enabled -and $_.VoiceInfo.Culture.Name -eq 'zh-CN'} | ForEach-Object {$_.VoiceInfo.Name})}finally{$probe.Dispose()}
$seen=@{}
# Validate the entire source-bound, no-overwrite batch before synthesizing.
foreach($line in $inputData.lines){
 if($line.id -notmatch '^[a-z0-9_]{1,100}$' -or $seen.ContainsKey($line.id)){throw 'Unsafe or duplicate line ID'}
 $seen[$line.id]=$true
 if(-not $profiles.ContainsKey($line.speaker) -or $profiles[$line.speaker].name -notin $voices){throw 'Required explicit offline voice unavailable'}
 $sourcePath=[IO.Path]::GetFullPath((Join-Path $projectRoot $line.dialog_path))
 $dialogRoot=[IO.Path]::GetFullPath((Join-Path $projectRoot 'game/data/dialogs'))+[IO.Path]::DirectorySeparatorChar
 if(-not $sourcePath.StartsWith($dialogRoot,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetExtension($sourcePath) -ne '.tres'){throw 'Dialogue source path outside scope'}
 $text=[IO.File]::ReadAllText($sourcePath)
 $found=@([regex]::Matches($text,'(?s)\[sub_resource[^\]]*\](.*?)(?=\n\[sub_resource|\n\[resource\])') | Where-Object {$_.Groups[1].Value -match ('(?m)^node_id\s*=\s*&?"'+[regex]::Escape($line.node_id)+'"\s*$')})
 if($found.Count -ne 1){throw 'Missing or ambiguous authored node'}
 $block=$found[0].Groups[1].Value
 foreach($field in @('speaker','text')){
  $match=[regex]::Match($block,('(?m)^'+$field+'\s*=\s*("(?:[^"\\]|\\.)*")\s*$'))
  if(-not $match.Success -or ($match.Groups[1].Value | ConvertFrom-Json) -cne $line.$field){throw 'Speech differs from authored dialogue'}
 }
 foreach($suffix in @('.wav','.meta.json')){if(Test-Path -LiteralPath (Join-Path $destination ($line.id+$suffix))){throw 'Existing output preserved; choose a new versioned directory'}}
}
New-Item -ItemType Directory -Force -Path $destination | Out-Null
$rows=@()
foreach($line in $inputData.lines){
 $profile=$profiles[$line.speaker]
 $wav=Join-Path $destination ($line.id+'.wav')
 $synth=New-Object System.Speech.Synthesis.SpeechSynthesizer
 try{
  $synth.SelectVoice($profile.name)
  $synth.Rate=$profile.rate
  $synth.Volume=90
  $format=New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(24000,[System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen,[System.Speech.AudioFormat.AudioChannel]::Mono)
  $synth.SetOutputToWaveFile($wav,$format)
  $synth.Speak($line.text)
 }finally{$synth.Dispose()}
 $bytes=(Get-Item -LiteralPath $wav).Length
 if($bytes -lt 128){throw 'Incomplete generated WAV preserved'}
 $sourcePath=Join-Path $projectRoot $line.dialog_path
 $meta=[ordered]@{status='OFFLINE_SYNTHETIC_AUDITION_NOT_LISTENED_OR_FORMAL';provider='Windows System.Speech SAPI';voice=$profile.name;rate=$profile.rate;sample_rate=24000;format='PCM_16_MONO_WAV';speaker=$line.speaker;text=$line.text;dialog_path=$line.dialog_path;node_id=$line.node_id;dialog_sha256=(Get-FileHash -LiteralPath $sourcePath).Hash;input_manifest_sha256=(Get-FileHash -LiteralPath $Manifest).Hash;producer_sha256=(Get-FileHash -LiteralPath $PSCommandPath).Hash;audio_sha256=(Get-FileHash -LiteralPath $wav).Hash;bytes=$bytes;online_neural_voice=$false;preserves_online_failure=$true;not_mp3_runtime_path=$true}
 $meta | ConvertTo-Json -Depth 6 | Out-File -LiteralPath (Join-Path $destination ($line.id+'.meta.json')) -Encoding utf8
 $rows+=[ordered]@{id=$line.id;path=$wav;bytes=$bytes;sha256=$meta.audio_sha256}
}
$result=[ordered]@{complete=$true;scope='OFFLINE_AUDITION_ONLY_NOT_FORMAL';lines=$rows.Count;rows=$rows;automatic_retries=0;distinct_installed_voice_names=2;male_roles_share_voice_with_rate_variation=$true;audio_quality_reviewed=$false}
$result | ConvertTo-Json -Depth 6 | Out-File -LiteralPath (Join-Path $destination 'result.json') -Encoding utf8
$result | ConvertTo-Json -Depth 6
