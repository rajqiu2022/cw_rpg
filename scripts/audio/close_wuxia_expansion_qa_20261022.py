"""Final bounded delivery/guard closure; no engine, model or production writes."""
import os
os.environ.setdefault('OPENBLAS_NUM_THREADS', '1')
import json
import time
from pathlib import Path
import numpy as np
from scipy.io import wavfile
from audit_wuxia_expansion_20261022 import ROOT, OUT, record, sha, save, field
from verify_wuxia_audio_trial import inspect_mp3

def read(path):
    return json.loads(path.read_text(encoding='utf-8'))

def checked(row):
    path = ROOT / row['path']
    assert sha(path) == row['sha256']
    if 'size' in row: assert path.stat().st_size == row['size']
    return path

def main():
    started = time.perf_counter()
    base = ROOT / 'assets/processed/audio/wuxia_expansion_20261022'
    selected_path = base / 'selected20_manifest_20261022.json'
    selected = read(selected_path)
    assert selected['selected_count'] == 20 and selected['archive_independent_generations'] == 21
    rows = selected['tracks']; assert len(rows) == 20 and len({x['id'] for x in rows}) == 20
    originals = read(base / 'manifest.json'); alt_path = ROOT / 'assets/processed/audio/wuxia_expansion_investigation_alt_20261022/manifest.json'
    alt = read(alt_path)
    raw_hashes = []
    for manifest in (originals, alt):
        for track in manifest['tracks']:
            raw_hashes.append(sha(checked(track['processing']['source'])))
    assert len(raw_hashes) == len(set(raw_hashes)) == 21
    choices = []
    for row in rows:
        source_manifest_path = checked(row['source_manifest'])
        source = read(source_manifest_path)
        is_alt = source_manifest_path.resolve() == alt_path.resolve()
        assert source_manifest_path.resolve() in (alt_path.resolve(), (base/'manifest.json').resolve())
        source_track = next(x for x in source['tracks'] if x['id'] == row['id'])
        expected_outputs = source_track['processing']['outputs'] + next(x for x in source['loops'] if x['track']['id']==row['id'])['outputs']
        assert row['outputs'] == expected_outputs
        for output in row['outputs']: checked(output)
        assert row['full_audition_wav'] in source_track['processing']['outputs']
        choices.append({'id':row['id'], 'ALT':is_alt})
    assert sum(x['ALT'] for x in choices) == 1
    group_path = base / 'group_audition_manifest_20261022.json'; groups = read(group_path)
    results = []; group_ids = []
    for group in groups['groups']:
        assert group['game_loop'] is False and group['track_prefix_frames']==529200 and group['gap_frames']==35280
        chunks=[]; cursor=0
        for index, item in enumerate(group['timeline']):
            row=next(x for x in rows if x['id']==item['id'])
            assert item['source']==row['full_audition_wav']
            sr,data=wavfile.read(checked(item['source']))
            assert sr==44100 and data.dtype==np.int16 and data.shape[1]==2
            assert item['source_start_frame']==0 and item['source_end_frame_exclusive']==529200
            assert item['destination_start_frame']==cursor and item['destination_end_frame_exclusive']==cursor+529200
            chunks.append(data[:529200]);cursor+=529200;group_ids.append(item['id'])
            if index+1<len(group['timeline']): chunks.append(np.zeros((35280,2),dtype=np.int16));cursor+=35280
        expected=np.concatenate(chunks)
        assert cursor==group['frames'] and cursor/44100==group['seconds']
        outputs=[checked(x) for x in group['outputs']]
        wav=next(p for p in outputs if p.suffix=='.wav'); mp3=next(p for p in outputs if p.suffix=='.mp3')
        sr,data=wavfile.read(wav)
        assert sr==44100 and np.array_equal(data,expected) and np.any(data) and not np.any((data==-32768)|(data==32767))
        decoded=inspect_mp3(mp3);assert decoded['technical_decode_pass'] and decoded['channels']==2 and decoded['sample_rate_hz']==44100
        results.append({'id':group['id'],'seconds':cursor/44100,'PCM_prefix_and_zero_gaps_exact':True,'mp3':decoded})
    assert len(results)==4 and len(group_ids)==20 and set(group_ids)=={x['id'] for x in rows}
    save('bgm_groups_selected_offline.json',{'technical_pass':True,'selected':record(selected_path),'groups_manifest':record(group_path),'selected20':choices,'archive_raw21_distinct_file_hashes':True,'groups':results,'loop_style_ear_review':'PENDING','engine':0,'game_writes':0})
    before=read(OUT/'before.json'); supplement=read(OUT/'before_nested_dialogs_supplement.json')
    after={}; deltas={}
    for key, prior in [(k,before[k]) for k in ('audio_files','audio_sources','skill_dialog_enemy_equipment_data','player_files')]+[('nested63_dialogue_supplement',supplement['files'])]:
        current=[record(Path(x['path'])) for x in prior];after[key]=current;deltas[key]=[]
        for old,new in zip(prior,current):
            changed=[k for k in ('exists','bytes','sha256','mtime_ns','mtime_utc_ticks') if old.get(k)!=new.get(k)]
            if changed:deltas[key].append({'before':old,'after':new,'changed_fields':changed})
    projection=[]
    for row in before['scene_audio_projection_only']:
        path=ROOT/row['path'];text=path.read_text(encoding='utf-8-sig')
        projection.append({'path':row['path'],'scene_id':field(text,'scene_id',path.stem),'bgm_path':field(text,'bgm_path')})
    scene_deltas=[{'before':x,'after':y} for x,y in zip(before['scene_audio_projection_only'],projection) if x!=y]
    guard={'scope':'ORIGINAL_FRESH_AUDIO_DATA_PLAYER_GUARD_NO_CITY_GEOMETRY_CLAIM','before':record(OUT/'before.json'),'nested_supplement':record(OUT/'before_nested_dialogs_supplement.json'),'after_records':after,'deltas':deltas,'scene_audio_projection_deltas':scene_deltas,'unchanged':not any(deltas.values()) and not scene_deltas,'no_rollback_no_rebaseline':True}
    save('after.json',guard)
    reports=['bgm_original20.json','original20_two_mp3_frame_diagnostics.json','bgm_two_residual_contract_review.json','bgm_investigation_alt.json','bgm_groups_selected_offline.json','voice_delivery_offline.json','sfx_delivery_offline.json','after.json']
    voice=read(OUT/'voice_delivery_offline.json');sfx=read(OUT/'sfx_delivery_offline.json')
    assert voice['technical_pass'] and sfx['technical_pass']
    final={'scope':'OFFLINE_LISTENING_CANDIDATES_ONLY_NOT_GAME_ADOPTED','finite_technical_closure':True,'reports':[record(OUT/x) for x in reports], 'bgm':'18 original cases PASS plus two authorized MP3-listening-contract residuals; original strict20 FAIL preserved. All game-carrier loop WAV PCM exact; two listening MP3 decoded +15/+23 frames retained.', 'bgm_selected_count':20,'bgm_archive_takes':21,'voice_clips':685,'voice_known_nodes':682,'voice_provider_ids':7,'voice_speaker_labels':116,'voice_152_empty_context_nodes_excluded':True,'sfx_model_takes':24,'sfx_event_variants':48,'sfx_transparent_signatures':10,'sfx_skill_rows':67,'wolf_rending_bite_semantic_mapping_pending':True,'guard_unchanged':guard['unchanged'],'guard_delta_counts':{k:len(v) for k,v in deltas.items()},'scene_audio_projection_delta_count':len(scene_deltas),'engine_by_qa':0,'game_writes_by_qa':0,'model_by_qa':0,'hearing_style_loop_semantic_approval':'PENDING','elapsed_seconds_this_closure':time.perf_counter()-started}
    save('final.json',final)
    print('FINAL',sha(OUT/'final.json'),'GUARD_UNCHANGED',guard['unchanged'],flush=True)

if __name__=='__main__':main()
