"""Read-only SAPI inventory and exact existing-audio reuse for32NPC lines+one hero opening. No speech generation/network/Godot."""
from pathlib import Path
import hashlib,json,subprocess,wave
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
def sha(b):return hashlib.sha256(b).hexdigest()
def new(p,value):
    raw=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
    with p.open('xb') as f:f.write(raw)
    return dict(path=str(p.relative_to(ROOT)).replace('\\','/'),sha256=sha(raw),bytes=len(raw))
tracked={}
def read(p):
    raw=p.read_bytes();st=p.stat();tracked[str(p)]=(raw,st.st_mtime_ns)
    return raw
author_path=ROOT/'game/build/luoyang_city_finish_20261025i_system01/ambient16_lore_text_author01_NOTREADY.json'
author_raw=read(author_path);author=json.loads(author_raw)
assert len(author['rows'])==16 and author['hero_opening']=='劳驾，近来街坊有什么新鲜事？'
requested=[]
for actor in author['rows']:
    assert len(actor['lines'])==2 and actor['new_voice_available'] is False
    for i,txt in enumerate(actor['lines']):
        requested.append(dict(line_id=actor['line_ids'][i],npc_id=actor['npc_id'],scene_id=actor['scene_id'],speaker=actor['npc_name'],text=txt,emotion='normal',dynamic_node_id=['start','reply'][i],dialog_id=actor['dialog_id']))
assert len(requested)==32 and len({r['line_id'] for r in requested})==32
requested.append(dict(line_id='luoyang25i_hero_ambient_opening',npc_id='__hero__',scene_id='ALL16_AMBIENT',speaker='冷孤云',text=author['hero_opening'],emotion='normal',dynamic_node_id='hero',dialog_id='SHARED_HERO_ONE_UNIQUE_AUDIO'))
base=ROOT/'assets/processed/audio/wuxia_voice_sfx_expansion_20261022'
available=[]
for name in ('first74_voice_manifest.json','extended_voice_manifest.json','followup_voice_manifest.json'):
    p=base/name;raw=read(p);doc=json.loads(raw)
    for row in doc['rows']:
        available.append(dict(row,manifest=str(p.relative_to(ROOT)).replace('\\','/'),manifest_sha256=sha(raw)))
assert len(available)==685
for request in requested:
    hits=[r for r in available if r.get('speaker')==request['speaker'] and r.get('text')==request['text']]
    exact=[]
    for hit in hits:
        path=ROOT/hit['source']['path'];raw=read(path)
        assert sha(raw)==hit['source']['sha256'].lower() and len(raw)==hit['source']['bytes'] and len(raw)>128
        exact.append(dict(id=hit['id'],path=hit['source']['path'],sha256=sha(raw),bytes=len(raw),voice=hit['voice'],manifest=hit['manifest'],manifest_sha256=hit['manifest_sha256'],exact_speaker_and_original_text=True,prior_status='CANDIDATE_LISTENING_PENDING_NOT_APPLIED',this_audit_listened=False))
    request['existing_exact_audio_candidates']=exact
    request['proposed_voice_path']='res://art/audio/voices/luoyang25i/'+request['line_id']+'.mp3'
    request['audio_currently_available']=bool(exact)
    request['audio_accepted_for_game']=False
    request['casting_requirement']='same hero voice as existing cold-protagonist casting' if request['npc_id']=='__hero__' else 'ordinary natural male Mandarin, consistent per actual visual identity; older-veteran and younger-soldier must not be claimed independent actors through speed changes'
    request['source_author_sha256']=sha(author_raw)
    request['new_audio_generated']=False
ps="""Add-Type -AssemblyName System.Speech
$voiceReadOnlyProbe=New-Object System.Speech.Synthesis.SpeechSynthesizer
try {@($voiceReadOnlyProbe.GetInstalledVoices() | ForEach-Object {[ordered]@{name=$_.VoiceInfo.Name;culture=$_.VoiceInfo.Culture.Name;gender=$_.VoiceInfo.Gender.ToString();age=$_.VoiceInfo.Age.ToString();enabled=$_.Enabled;id=$_.VoiceInfo.Id}}) | ConvertTo-Json -Depth 4} finally {$voiceReadOnlyProbe.Dispose()}
"""
probe=subprocess.run(['pwsh','-NoProfile','-NonInteractive','-Command',ps],capture_output=True,text=True,encoding='utf-8',check=True)
voices=json.loads(probe.stdout)
zh=[v for v in voices if v['enabled'] and v['culture']=='zh-CN']
assert len([v for v in zh if v['gender']=='Male'])==1
old_trial=ROOT/'assets/processed/luoyang_resident_life_20261019v/voice_trial02_offline'
trial_doc=json.loads(read(old_trial/'result.json').decode('utf-8-sig'));sapi_samples=[]
for old in trial_doc['rows']:
    p=old_trial/(old['id']+'.wav');raw=read(p);meta=json.loads(read(old_trial/(old['id']+'.meta.json')).decode('utf-8-sig'))
    assert sha(raw)==old['sha256'].lower()==meta['audio_sha256'].lower()
    with wave.open(str(p),'rb') as w:
        fmt=dict(channels=w.getnchannels(),sample_rate=w.getframerate(),sample_width=w.getsampwidth(),frames=w.getnframes(),seconds=w.getnframes()/w.getframerate())
    sapi_samples.append(dict(id=old['id'],path=str(p.relative_to(ROOT)).replace('\\','/'),sha256=sha(raw),voice=meta['voice'],rate=meta['rate'],text=meta['text'],audio_format=fmt,listening_status='NOT_LISTENED_BY_THIS_AUDIT; original metadata also NOT_LISTENED_OR_FORMAL'))
dn=ROOT/'game/scripts/domain/dialog_node.gd';dp=ROOT/'game/scripts/autoload/dialog_player.gd';am=ROOT/'game/scripts/autoload/audio_manager.gd';helper=ROOT/'game/build/luoyang_city_finish_20261025i_system01/ambient16_runtime03_NOTREADY.gd'
src={str(p.relative_to(ROOT)).replace('\\','/'):dict(sha256=sha(read(p)),bytes=p.stat().st_size) for p in (dn,dp,am,helper)}
assert '@export var voice_path' not in tracked[str(dn)][0].decode()
assert '"_session_"' in tracked[str(helper)][0].decode()
summary=dict(npc_utterances=32,shared_hero_utterances=1,unique_text_jobs=33,existing685_neural_candidate_bank=True,strict_exact_reuse_lines=sum(bool(r['existing_exact_audio_candidates']) for r in requested),strict_missing_lines=sum(not r['existing_exact_audio_candidates'] for r in requested),new_generation=0,all_generated_or_voice_complete=False,installed_SAPI_enabled_zh_names=[v['name'] for v in zh],installed_SAPI_distinct_male_names=[v['name'] for v in zh if v['gender']=='Male'],independent_male_actor_count=1,all16_NPC_new_lines_male_labels=True)
plan=dict(status='READONLY_AUDIO_AVAILABILITY_AND_MINIMAL_INTERFACE_PROPOSAL_NOT_GENERATED_NOT_APPLIED',summary=summary,author=dict(path=str(author_path.relative_to(ROOT)).replace('\\','/'),sha256=sha(author_raw)),installed_voices=voices,installed_voice_probe_mode='System.Speech.GetInstalledVoices only; no Speak/output/audio-device call',existing_SAPI_trials=sapi_samples,current_code_sources=src,interface_facts=['DialogNode currently has NO voice_path field. Do not claim such an existing exported API.','DialogPlayer dynamically derives MP3 paths from current_script.dialog_id/speaker/node_id and emotion;16ambient helper adds_session_serial, so generated fixed-line audio is not currently selected.','AudioManager.play_dialog_voice(path) exists and normal DialogPlayer.advance/choose/end cancels its voice channel.','DialogPlayer.text_displayed signal is emitted after current node/automatic fallback voice selection, with exact current node/script available.'],recommended_minimum_new_helper_only_interface=['Keep dynamic session dialogue IDs/lease ownership/cancel logic unchanged; do not edit DialogNode/DP/AudioManager merely for these16ambient rows.','After audio is actually approved, add a source-bound voice manifest with stable line_id,exact text,speaker,emotion,voice_path,media SHA. The proposed voice_path fields live in that new manifest, NOT an invented DialogNode export.','Ambient helper may connect to existing DialogPlayer.text_displayed and, ONLY when current_script is its exact live leased graph and current node_id/speaker/text match hero/start/reply receipt and _owned is true, call existing AudioManager.play_dialog_voice(voice_path) once.','Keep source-bound33 audio inputs in complete source FIRST/FINAL; no repeated per-frame hashing. Connect once during attach, disconnect during detach, no global voice hook.','Preserve original same-script/actor/owner invalidation; normal DP.advance/choose/end already stops the channel. Abort only the owned graph, never unrelated audio.','Reuse one shared hero audio file across16sessions; canonical speaker is cold protagonist even if user customizes display_name; match displayed text and actual hero-node identity, not false multiple actors.','Until approved clips/normal Mandarin listening exist, keep new_voice_available=false/no_new_audio=true and do not claim NPC voice completion.'],alternative_not_recommended='A new DialogNode.voice_path export+DP explicit branch would touch shared public contract and require separate source successor/prewarm/cancel checks. Not needed for the limited ambient-helper solution.',voice_quality_boundary=['SAPI availability is proven, naturalness/acting is not. Installed male Mandarin is only Kangkang, unsuitable to claim multiple independent youthful/older/merchant actors by Rate changes.','Huihui Desktop and Huihui are separate installed names of the Huihui family, not automatically independent performers; Yaoyao female also cannot supply male-role diversity.','Existing685 local candidates use7 real neural voice IDs and prior source-bound text, but remain listening pending/not formal. Exact-text reuse does not grant pronunciation,prosody,age,regional accent or in-game balance approval.','Do not reuse audio with different dialogue text, borrow unrelated hero lines or synthesize new Edge/SAPI audio during this read-only audit.','Full33utterance listening (dialect/rare syllables/neutral ordinary delivery), actor casting consistency, volume balance, clipping/decode/import and actual in-game cancellation/fast advance remain required.'],network_calls=0,new_audio_files=0,Godot_calls=0,game_source_edits=0,all_input_files_preserved=True)
for path,(raw,ticks) in tracked.items():
    p=Path(path);assert p.read_bytes()==raw and p.stat().st_mtime_ns==ticks
plan['requested_utterances']=requested
plan['report_history']='Original READONLY.json keeps the inventory/interface summary; this02 adds the explicit33source-bound utterance rows without overwriting that report or changing audio.'
receipt=new(OUT/'audio33_availability_and_interface_READONLY02.json',plan)
print(json.dumps(dict(report=receipt,summary=summary),ensure_ascii=False))
