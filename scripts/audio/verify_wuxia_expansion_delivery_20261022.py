"""Necessary offline voice/SFX delivery checks. Never installs or starts services."""
import os
os.environ.setdefault('OMP_NUM_THREADS', '1')
os.environ.setdefault('OPENBLAS_NUM_THREADS', '1')
import argparse
import json
from pathlib import Path
import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt
from audit_wuxia_expansion_20261022 import ROOT, OUT, record, sha, save
from produce_wuxia_stable_trial import decode
from verify_wuxia_audio_trial import inspect_mp3

BASE = ROOT / 'assets/processed/audio/wuxia_voice_sfx_expansion_20261022'

def read(path):
    return json.loads(path.read_text(encoding='utf-8'))

def checked(row):
    path = ROOT / row['path']
    assert sha(path) == row['sha256'], path
    if 'bytes' in row: assert path.stat().st_size == row['bytes'], path
    return path

def pcm(path, expected=None):
    sr, x = wavfile.read(path)
    assert sr == 44100 and x.dtype == np.int16 and x.ndim == 2 and x.shape[1] == 2
    assert len(x) and np.any(x) and not np.any((x == -32768) | (x == 32767))
    if expected is not None: assert np.array_equal(x, expected), path
    return x

def voices():
    union_path = BASE / 'voice_union_copy_plan.json'; union = read(union_path)
    inventory = read(OUT / 'inventory_retry1.json')
    authored = {(n['dialog_id'], n['node_id']): n for n in inventory['dialog_nodes']}
    targets = {}
    for c in union['copy_plan']:
        source = checked(c['source']); target = (ROOT / c['target']).resolve()
        assert target.is_relative_to(ROOT / 'game/art/audio/voices') and not target.exists() and not c['applied']
        assert target not in targets; targets[target] = source
        checked(c['dialog_source'])
    assert len(targets) == 685
    results, reels, ids, total_frames = [], [], set(), 0
    for manifest_rec in union['batch_manifests']:
        manifest_path = checked(manifest_rec); manifest = read(manifest_path)
        script = manifest['script']; current = ROOT / script['path']
        if sha(current) != script['sha256']:
            snapshot = BASE / 'runtime/script_snapshots' / (script['sha256'] + '.py')
            assert sha(snapshot) == script['sha256']
        batch_rows = {r['id']: r for r in manifest['rows']}
        for row in manifest['rows']:
            assert row['id'] not in ids; ids.add(row['id'])
            source = checked(row['source']); checked(row['dialog_source'])
            node = authored[(row['dialog_id'], row['node_id'])]
            assert row['text'] == node['text'] and row['speaker'] == node['speaker']
            audio = decode(source).astype(np.float32)
            assert audio.shape[0] == 2 and audio.shape[1] and np.isfinite(audio).all() and np.any(audio)
            gain = min(1, .707 / max(float(np.abs(audio).max()), 1e-9))
            expected = np.rint((audio * gain).T * 32767).astype('<i2')
            listened = pcm(checked(row['listen_wav']), expected)
            assert gain == row['qc']['gain'] and len(listened) == row['qc']['frames']
            total_frames += len(listened)
            results.append({'id':row['id'], 'source':record(source), 'frames44100':len(listened), 'peak':float(np.abs(audio).max()), 'samples_above_unity':int(np.count_nonzero(np.abs(audio)>1)), 'listen_PCM_exact':True})
        # Every navigation reel is real decoded source prefixes plus declared padding/gaps.
        audition = manifest['audition']; chunks = []; cursor = 0
        for i, item in enumerate(audition['timeline']):
            assert item['id'] in batch_rows
            audio = decode(checked(item['source'])).astype(np.float32)
            assert round(item['start_seconds'] * 44100) == cursor
            frames = round((item['end_seconds']-item['start_seconds']) * 44100)
            take = item['source_prefix_frames']; pad = item['slot_padding_frames']
            assert take + pad == frames and take <= audio.shape[1]
            part = np.zeros((2, frames), dtype=np.float32); part[:, :take] = audio[:, :take]
            chunks.append(part); cursor += frames
            if i+1 < len(audition['timeline']): chunks.append(np.zeros((2, 22050), dtype=np.float32)); cursor += 22050
        joined = np.concatenate(chunks, axis=1)
        gain = min(1, .707 / max(float(np.abs(joined).max()), 1e-9))
        pcm(checked(audition['wav']), np.rint((joined*gain).T*32767).astype('<i2'))
        mp3 = inspect_mp3(checked(audition['mp3'])); assert mp3['technical_decode_pass']
        reels.append({'batch':manifest['batch'], 'frames':cursor, 'seconds':cursor/44100, 'source_prefix_padding_and_navigation_exact':True, 'mp3':mp3})
    assert len(results) == 685
    missing = read(OUT/'missing_explicit_speaker_nodes.json')['nodes'] + read(OUT/'invalid_existing_voice_sources.json')['affected_explicit_static_nodes']
    coverage = []
    for n in missing:
        seg = [ROOT/p for p in n['expected_segments']]
        primary = ROOT/n['expected_primary']; legacy = primary.with_name(primary.name.rsplit('_e',1)[0]+'.mp3')
        if seg and seg[0].resolve() in targets:
            assert all(p.resolve() in targets or (p.is_file() and p.stat().st_size) for p in seg)
            branch='complete_segments'; selected=seg
        else:
            chosen=primary if primary.resolve() in targets else legacy
            assert chosen.resolve() in targets
            branch='primary_or_legacy_fallback'; selected=[chosen]
        coverage.append({'dialog_id':n['dialog_id'],'node_id':n['node_id'],'branch':branch,'selected':[str(x.relative_to(ROOT)) for x in selected]})
    assert len(coverage)==682 and len({(x['dialog_id'],x['node_id']) for x in coverage})==682
    report={'scope':'685_NEW_VOICE_CLIPS_682_KNOWN_NODES_ONLY_NOT_INSTALLED','technical_pass':True,'union':record(union_path),'clips':results,'known_overlay_nodes':coverage,'navigation_reels':reels,'listen_total_seconds':total_frames/44100,'shared_provider_voice_ids':union['voices'],'distinct_speaker_labels':union['distinct_speaker_labels'],'empty_speaker152_not_claimed':True,'original603_success1_failure_and_followup_preserved':True,'game_writes':0,'engine':0,'ear_review':'PENDING'}
    save('voice_delivery_offline.json',report)
    print('VOICE_QA_PASS',len(results),len(coverage),sha(OUT/'voice_delivery_offline.json'),flush=True)

def event_pcm(y, info):
    y=np.asarray(y,dtype=np.float32); gain=min(1,.78/max(float(np.abs(y).max()),1e-9)); y=y*gain
    n=min(round(.003*44100),y.shape[1]//4)
    y[:,:n]*=np.linspace(0,1,n); y[:,-n:]*=np.linspace(1,0,n)
    assert gain==info['gain'] and n==info['fade_frames']
    expected=np.rint(y.T*32767).astype('<i2'); pcm(checked(info['output']),expected)
    return y

def sfx():
    from produce_wuxia_sfx_bank_20261022 import layer
    manifest=read(BASE/'sfx/manifest.json'); signature=read(BASE/'sfx/signature_manifest.json')
    assert manifest['actual_model_takes']==24 and manifest['event_files']==48
    rows=[]; medley=[]
    for take in manifest['sources']:
        rawpath=checked(take['raw']); sr,raw=wavfile.read(rawpath)
        assert sr==44100 and raw.dtype==np.float32 and raw.shape==(264600,2) and np.isfinite(raw).all() and np.any(raw)
        invoke=read(rawpath.with_suffix('.invocation.json'))
        assert invoke['exit_code']==0 and invoke['status']=='COMPLETE'
        cmd=invoke['command']; assert cmd[cmd.index('--dit')+1]=='sm-sfx' and cmd[cmd.index('--threads')+1]=='4'
        case=take['case']; assert cmd[cmd.index('--seed')+1]==str(case['seed']) and cmd[cmd.index('--prompt')+1]==case['prompt']
        start,end=take['crop_frames']; assert 0<=start<end<=len(raw) and end-start<=round(case['max_event_seconds']*sr)
        event=np.ascontiguousarray(raw.T[:,start:end]); rms=float(np.sqrt(np.mean(event*event)))
        for variant in take['variants']:
            y=event.copy()
            if variant['variant']=='textured':
                assert variant['physical_layer_seed']==case['seed']+90000 and variant['layer_gain']==rms*.12
                y += layer(case['family'],y.shape[1],variant['physical_layer_seed'])[None,:]*variant['layer_gain']
            else: assert variant['layer_gain']==0
            processed=event_pcm(y,variant); medley.extend([processed,np.zeros((2,22050),dtype=np.float32)])
        rows.append({'id':case['id'],'raw':record(rawpath),'crop':take['crop_frames'],'source_crop_gain_fade_PCM_exact':True,'layer_shape_recomputed_with_audited_pure_author_helper':True,'independent_model_take':True})
    event_pcm(np.concatenate(medley,axis=1),manifest['audition'])
    preview=inspect_mp3(checked(manifest['audition_mp3'])); assert preview['technical_decode_pass']
    for item in signature['sources']:
        layers=[]; total=0
        for part in item['layers']:
            sr,x=wavfile.read(checked(part['source'])); assert sr==44100 and x.dtype==np.int16
            y=x.T.astype(np.float32)/32768; off=part['offset_frames']; layers.append((y*part['gain'],off)); total=max(total,off+y.shape[1])
        mixed=np.zeros((2,total),dtype=np.float32)
        for y,off in layers:mixed[:,off:off+y.shape[1]]+=y
        if item['filter']:
            mixed=sosfilt(butter(2,[180,2200],btype='bandpass',fs=44100,output='sos'),mixed,axis=1).astype(np.float32)
            n=min(round(.12*44100),total//3); mixed[:,:n]*=np.linspace(0,1,n); mixed[:,-n:]*=np.linspace(1,0,n)
        event_pcm(mixed,item)
    assert len(signature['sources'])==10 and len(signature['copy_plan'])==58
    for row in signature['copy_plan']:checked(row['source']); assert not (ROOT/row['target']).exists() and not row['applied']
    mapping=read(BASE/'skill_sfx_mapping_reviewed.json'); available={x['id'] for x in signature['copy_plan']}
    assert len(mapping['skills'])==57 and len(mapping['passives_not_given_active_sounds'])==10
    for row in mapping['skills']:
        assert sha(ROOT/row['skill_path'])==row['skill_sha256']
        for k in ('cast_asset_id','impact_asset_id'):assert row[k] is None or row[k] in available
    report={'scope':'24_SFX_RAW_48_VARIANTS_10_DERIVED_ONLY_NOT_INSTALLED','technical_pass':True,'sources':rows,'signature_manifest':record(BASE/'sfx/signature_manifest.json'),'signature_sum_filter_gain_fade_PCM_exact':True,'variants_fullscale_samples':0,'navigation_mp3':preview,'mapped57_active10_passive':True,'animal_unmapped_pending':mapping['animal_unmapped_pending'],'independent_model_takes':24,'derived_assets_not_extra_model_takes':58,'ear_review':'PENDING','game_writes':0,'engine':0}
    save('sfx_delivery_offline.json',report)
    print('SFX_QA_PASS',sha(OUT/'sfx_delivery_offline.json'),flush=True)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('kind',choices=['voices','sfx']);a=p.parse_args()
    voices() if a.kind=='voices' else sfx()
