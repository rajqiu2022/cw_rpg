param(
    [switch]$ExecuteRootReviewed,
    [string]$ExpectedManifestSHA256 = '',
    [string]$ExpectedProducerSHA256 = ''
)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$manifestPath = Join-Path $projectRoot 'game/build/luoyang_city_finish_20261025i_art01/sapi_two_representative_probe01_FROZEN.json'
$manifest = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
$manifestSHA = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
$producerSHA = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($manifest.status -ne 'TWO_SOURCE_BOUND_LOCAL_SAPI_AUDITIONS_FROZEN_ROOT_REVIEW_PENDING_NOT_GENERATED' -or @($manifest.lines).Count -ne 2) { throw 'Exact two-line frozen manifest required' }
if ($manifest.voice -cne 'Microsoft Kangkang' -or $manifest.voice_token_id -cne 'MSTTS_V110_zhCN_KangkangM' -or $manifest.rate -ne 0 -or $manifest.volume -ne 90 -or $manifest.format -cne '24000Hz_PCM16_MONO_WAV') { throw 'Explicit fixed shared local SAPI profile changed' }
if ($ExecuteRootReviewed) {
    if ($ExpectedManifestSHA256 -cne $manifestSHA -or $ExpectedProducerSHA256 -cne $producerSHA) { throw 'Root-reviewed manifest and exact producer SHA required before synthesis' }
}
$sourcePath = Join-Path $projectRoot $manifest.source_author
$sourceRaw = [IO.File]::ReadAllBytes($sourcePath)
$sourceSHA = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($sourceSHA -cne $manifest.source_author_sha256) { throw 'Source authored text changed; no speech synthesis' }
$source = [Text.Encoding]::UTF8.GetString($sourceRaw) | ConvertFrom-Json
$destination = [IO.Path]::GetFullPath((Join-Path $projectRoot $manifest.output_directory))
$exactDirectory = [IO.Path]::GetFullPath((Join-Path $projectRoot 'assets/processed/luoyang_city_finish_20261025i_audio/sapi_two_probe01'))
if ($destination -cne $exactDirectory) { throw 'Output outside exact NEW candidate directory' }
if (Test-Path -LiteralPath $destination) { throw 'Existing directory preserved; do not rerun over existing candidates' }
$seen = @{}
foreach ($line in $manifest.lines) {
    if ($line.id -notmatch '^[a-z0-9_]{1,100}$' -or $seen.ContainsKey($line.id) -or $line.output_filename -cne ($line.id + '.wav')) { throw 'Invalid fixed output identity' }
    $seen[$line.id] = $true
    if ($line.id -eq 'hero_ambient_opening_kangkang_rate0') {
        if ($line.text -cne $source.hero_opening -or $line.speaker -cne '冷孤云' -or $line.node_id -cne 'hero') { throw 'Hero opening differs from exact author' }
    } elseif ($line.id -eq 'veteran_quay_daily01_kangkang_rate0') {
        $matches = @($source.rows | Where-Object { $_.npc_id -ceq 'harbour_life_docks_quay_patrol' })
        if ($matches.Count -ne 1 -or $line.text -cne $matches[0].lines[0] -or $line.speaker -cne $matches[0].npc_name -or $line.node_id -cne 'start') { throw 'Older patrol line differs from author' }
    } else { throw 'An unapproved third identity is not allowed' }
}
Add-Type -AssemblyName System.Speech
$voiceReadOnlyProbe = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
    $matchingVoices = @($voiceReadOnlyProbe.GetInstalledVoices() | Where-Object { $_.Enabled -and $_.VoiceInfo.Name -ceq $manifest.voice -and $_.VoiceInfo.Id -ceq $manifest.voice_token_id -and $_.VoiceInfo.Culture.Name -ceq 'zh-CN' })
    if ($matchingVoices.Count -ne 1) { throw 'Required exact local male voice unavailable' }
} finally { $voiceReadOnlyProbe.Dispose() }
if (-not $ExecuteRootReviewed) {
    [ordered]@{status='OFFLINE_DRYRUN_PASS_NO_SYNTHESIS_NO_SPEAKER_PLAYBACK';manifest_sha256=$manifestSHA;producer_sha256=$producerSHA;source_author_sha256=$sourceSHA;voice=$manifest.voice;rate=0;volume=90;lines=2;planned_directory=$destination;exact_lines=$manifest.lines;network_calls=0;generated_audio=0} | ConvertTo-Json -Depth 8
    return
}
# SetOutputToWaveFile before Speak: never route trial audio to the user's loudspeakers.
New-Item -ItemType Directory -Path $destination | Out-Null
$outputs = @()
foreach ($line in $manifest.lines) {
    if ((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $sourceSHA) { throw 'Source changed during batch; stop and retain partial evidence' }
    $wav = Join-Path $destination $line.output_filename
    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    try {
        $synth.SelectVoice($manifest.voice)
        $synth.Rate = 0
        $synth.Volume = 90
        $format = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(24000,[System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen,[System.Speech.AudioFormat.AudioChannel]::Mono)
        $synth.SetOutputToWaveFile($wav,$format)
        $synth.Speak([string]$line.text)
    } finally { $synth.Dispose() }
    $file = Get-Item -LiteralPath $wav
    if ($file.Length -lt 128) { throw 'Incomplete candidate retained; no automatic retry' }
    $audioSHA = (Get-FileHash -LiteralPath $wav -Algorithm SHA256).Hash.ToLowerInvariant()
    $metadata = [ordered]@{status='LOCAL_SAPI_TWO_AUDITION_NOT_LISTENED_NOT_FORMAL';provider='Windows System.Speech SAPI';voice=$manifest.voice;voice_token_id=$manifest.voice_token_id;rate=0;volume=90;format=$manifest.format;speaker=$line.speaker;text=$line.text;node_id=$line.node_id;npc_id=$line.npc_id;emotion='normal';source_author=$manifest.source_author;source_author_sha256=$sourceSHA;input_manifest_sha256=$manifestSHA;producer_sha256=$producerSHA;audio_sha256=$audioSHA;bytes=$file.Length;shared_single_male_voice=$true;independent_actor_claim=$false;speaker_playback=$false;network_calls=0;automatic_retries=0;listening='PENDING_ROOT_LISTENING';game_integration='NONE'}
    [IO.File]::WriteAllText((Join-Path $destination ($line.id + '.meta.json')),($metadata | ConvertTo-Json -Depth 7) + "`n",[Text.UTF8Encoding]::new($false))
    $outputs += [ordered]@{id=$line.id;path=$wav;sha256=$audioSHA;bytes=$file.Length}
}
$result = [ordered]@{status='TWO_LOCAL_SAPI_WAV_GENERATED_NOT_LISTENED_NOT_APPLIED';outputs=$outputs;distinct_male_voice_names=1;voice='Microsoft Kangkang';rate=0;speaker_playback=$false;network_calls=0;Godot_calls=0;no_original_audio_edits=$true;automatic_retries=0;listening='PENDING_ROOT_LISTENING';source_author_sha256=$sourceSHA;manifest_sha256=$manifestSHA;producer_sha256=$producerSHA}
[IO.File]::WriteAllText((Join-Path $destination 'result.json'),($result | ConvertTo-Json -Depth 8) + "`n",[Text.UTF8Encoding]::new($false))
$result | ConvertTo-Json -Depth 8
