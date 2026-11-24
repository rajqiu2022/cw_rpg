"""Read only the two action pairs/config/WAVs. No playback, image writes or engine."""
from pathlib import Path
from PIL import Image
import hashlib, json, math, struct, wave

ROOT=Path('F:/Code/RPG_GAME')
REPORT=ROOT/'game/build/gather_actions_20261030l_root01/assets_prepared_ACTUAL.json'
CONFIG=ROOT/'game/scripts/life_skills/gathering_actions_20261030l.json'
sha=lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
uri=lambda path: ROOT/'game'/path.removeprefix('res://')
facts=json.loads(REPORT.read_text(encoding='utf-8-sig'))
config=json.loads(CONFIG.read_text(encoding='utf-8-sig'))
errors=[]; checks=[]; rows=[]
def need(ok,label):
    checks.append({'label':label,'ok':bool(ok)})
    if not ok: errors.append(label)
need(config['schema_version']==1 and set(config['actions'])=={'herb','ore'},'TWO_EXACT_PROFILES')
for kind,name in [('herb','gather_herb_right_4f'),('ore','mine_ore_right_4f')]:
    row=config['actions'][kind]
    proof=next(r for r in facts['sheets'] if r['name']==name)
    raw_path=ROOT/'assets/raw/gather_actions_20261030l'/f'{name}.png'
    processed_path=uri(row['sheet'])
    raw=Image.open(raw_path); image=Image.open(processed_path)
    need(raw.mode=='RGBA' and image.mode=='RGBA' and raw.size==(2172,724) and image.size==(2428,788),kind+':ACTUAL_RGBA_FOUR_CELLS_AND32_PADDING')
    need(sha(raw_path)==proof['raw_sha256'] and sha(processed_path)==proof['processed_sha256'],kind+':ROOT_RECORDED_RAW_AND_PROCESSED_SHA')
    need(row['duration']==(1.2 if kind=='herb' else 1.5) and row['left_is_runtime_mirror'] is True,kind+':DURATION_AND_MIRROR')
    need(len(row['frames'])==4 and len(row['cues'])==1,kind+':FOUR_FRAMES_ONE_CUE')
    removed=0; frame_rows=[]
    for index,frame in enumerate(row['frames']):
        need(frame['rect']==[index*607,0,607,788],f'{kind}:{index}:EXACT_REGION_NO_CROP_OR_OVERLAP')
        cell=image.crop((index*607,0,(index+1)*607,788))
        source=raw.crop((index*543,0,(index+1)*543,724))
        restored=cell.crop((32,32,575,756))
        need(source.convert('RGB').tobytes()==restored.convert('RGB').tobytes(),f'{kind}:{index}:EVERY_ORIGINAL_RGB_BYTE_SAME')
        box=source.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
        protect=(max(0,box[0]-32),max(0,box[1]-32),min(543,box[2]+32),min(724,box[3]+32))
        need(source.crop(protect).tobytes()==restored.crop(protect).tobytes(),f'{kind}:{index}:EVERY_PROTECTED_RGBA_BYTE_SAME')
        allowed=True; original=source.tobytes(); target=restored.tobytes(); changed=0
        for pixel in range(543*724):
            offset=pixel*4
            if original[offset:offset+4]==target[offset:offset+4]:continue
            x=pixel%543;y=pixel//543
            valid=original[offset+3]==1 and target[offset+3]==0 and not(protect[0]<=x<protect[2] and protect[1]<=y<protect[3])
            allowed=allowed and valid;changed+=1
        need(allowed,f'{kind}:{index}:ONLY_AUTHORIZED_OUTSIDE_ALPHA1_TO0')
        removed+=changed
        borders=[cell.crop((0,0,607,32)),cell.crop((0,756,607,788)),cell.crop((0,32,32,756)),cell.crop((575,32,607,756))]
        need(all(not any(border.tobytes()) for border in borders),f'{kind}:{index}:ALL32PX_NEW_PADDING_RGBA_ZERO')
        foot=frame['source_foot'];scale=frame['scale']
        need(len(foot)==2 and 32<=foot[0]<575 and foot[1]==box[3]+32 and math.isfinite(scale) and 0<scale<=1,f'{kind}:{index}:CONFIG_FOOT_AT_ACTUAL_CORE_BASE_AND_NONENLARGING_SCALE')
        frame_rows.append({'index':index,'actual_core128_bbox':box,'protected_bbox':protect,'alpha1_changes':changed,'source_foot':foot,'native_scale':scale,'core_height_after_scale':(box[3]-box[1])*scale,'source_RGBA_sha256':hashlib.sha256(original).hexdigest(),'processed_inner_RGBA_sha256':hashlib.sha256(target).hexdigest()})
    need(removed==proof['removed_outside_alpha1_only'],kind+':EXACT_ALPHA1_CHANGE_COUNT')
    cue=row['cues'][0];audio_path=uri(cue['path'])
    recorded=next(r for r in facts['audio'] if Path(r['path']).name==audio_path.name)
    with wave.open(str(audio_path),'rb') as wav:
        rate=wav.getframerate();channels=wav.getnchannels();width=wav.getsampwidth();count=wav.getnframes();data=wav.readframes(count)
    samples=struct.unpack('<'+'h'*(len(data)//2),data)
    need(rate==48000 and channels==1 and width==2 and count==round(rate*(.52 if kind=='herb' else .55)),kind+':REAL_PCM16_MONO48000_LENGTH')
    need(any(samples) and sha(audio_path)==recorded['sha256'],kind+':NONZERO_PCM_AND_RECORDED_SHA')
    need(recorded['source']=='deterministic offline procedural sound design; not recorded or AI-generated',kind+':EXPLICIT_SYNTHETIC_NOT_FOLEY_OR_AI_PROVENANCE')
    need(cue['frame']==2 and cue['volume_db']==-3 and row['duration']*.5+count/rate<row['duration'],kind+':ONE_FRAME2_CUE_FINISHES_WITHIN_ACTION')
    rows.append({'kind':kind,'raw_path':str(raw_path),'raw_sha256':sha(raw_path),'processed_path':str(processed_path),'processed_sha256':sha(processed_path),'frames':frame_rows,'WAV':{'path':str(audio_path),'sha256':sha(audio_path),'frames':count,'rate':rate,'channels':channels,'sample_width':width,'seconds':count/rate,'PCM_nonzero':True,'peak_pcm16':max(abs(s) for s in samples),'listened':False,'actual_engine_playback_observed':False,'source':recorded['source']}})
print(json.dumps({'passed':not errors,'checks':len(checks),'errors':errors,'rows':rows,'details':checks,'config_sha256':sha(CONFIG),'Root_material_proof_sha256':sha(REPORT),'static_source_pixels_only_not_import_or_audio_acceptance':True,'engine_calls':0,'production_or_PNG_writes':0,'save_access':0},indent=2))
