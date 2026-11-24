"""Read generated voice receipts, export WAV listening copies and exact copy maps.

Never installs candidates in game. Raw provider MP3s remain byte-for-byte.
"""
from pathlib import Path
import argparse, hashlib, json, wave
import numpy as np
from produce_wuxia_stable_trial import decode, encode_mp3

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/processed/audio/wuxia_voice_sfx_expansion_20261022'
SR=44100
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rec(p):return {'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p),'bytes':p.stat().st_size}
def fresh_json(p,d):
 with p.open('x',encoding='utf-8') as f:json.dump(d,f,ensure_ascii=False,indent=2)
def write_wav(p,y):
 if p.exists():raise FileExistsError('Existing audition preserved')
 if not np.isfinite(y).all():raise ValueError('Nonfinite')
 gain=min(1,.707/max(float(np.abs(y).max()),1e-9));x=y*gain
 pcm=np.rint(x.T*32767).astype('<i2')
 if (np.abs(pcm.astype(np.int32))>=32767).any():raise ValueError('Full scale PCM')
 p.parent.mkdir(parents=True,exist_ok=True)
 with wave.open(str(p),'wb') as f:f.setparams((2,2,SR,0,'NONE','not compressed'));f.writeframes(pcm.tobytes())
 return x,{'gain':gain,'peak':float(np.abs(pcm.astype(np.int32)).max()/32768),'rms':float(np.sqrt(np.mean((pcm.astype(np.float64)/32768)**2))),'frames':len(pcm),'seconds':len(pcm)/SR,'full_scale_pcm_samples':0}


def main():
 ap=argparse.ArgumentParser();ap.add_argument('--batch',choices=['first74','extended','residual','followup'],required=True);ap.add_argument('--allow-recorded-failure',action='store_true');a=ap.parse_args()
 folder={'first74':'voices_edge','extended':'voices_extended','residual':'voices_residual','followup':'voices_followup'}[a.batch]
 results=json.loads((OUT/folder/'result.json').read_text(encoding='utf-8'))
 if (results['failures'] or results['generated']!=results['requested']) and not a.allow_recorded_failure:raise ValueError('Incomplete batch; preserve failures')
 plan=json.loads((OUT/{'first74':'voice_plan.json','extended':'voice_extended_plan.json','residual':'voice_residual_plan.json','followup':'voice_followup_plan.json'}[a.batch]).read_text(encoding='utf-8'))
 copy_rows=[];representatives={};manifest=[]
 for result in results['rows']:
  if not result['status'].startswith('GENERATED'):
   continue
  row=result.get('line',result.get('job'));source=ROOT/result['audio_path']
  if sha(source)!=result['audio_sha256']:raise ValueError('Raw source changed')
  if sha(ROOT/row['dialog_path'])!=row['dialog_sha256']:raise ValueError('Dialogue changed')
  target=row.get('proposed_game_path')
  if not target:
   safe=row['speaker'].replace('/','_').replace('\\','_')
   target=f'game/art/audio/voices/{row["dialog_id"][:3]}/{row["dialog_id"]}/{safe}_{row["node_id"]}.mp3'
  target=Path(target)
  if not target.resolve().is_relative_to(ROOT/'game/art/audio/voices'):raise ValueError('Unsafe proposed target')
  if target.exists():raise FileExistsError('Refuse proposed old clip replacement')
  audio=decode(source).astype(np.float32)
  listen=OUT/'voice_listen'/a.batch/(row['id']+'.wav');y,qc=write_wav(listen,audio)
  manifest.append({'id':row['id'],'speaker':row['speaker'],'voice':row['voice'],'source':rec(source),'listen_wav':rec(listen),'qc':qc,
    'dialog_id':row['dialog_id'],'node_id':row['node_id'],'text':row['text'],'spoken_text':row['spoken_text'],
    'dialog_source':{'path':row['dialog_path'],'sha256':row['dialog_sha256']},'segment_kind':row.get('segment_kind','dialog')})
  copy_rows.append({'id':row['id'],'source':rec(source),'target':target.as_posix(),'resource_path':'res://'+target.relative_to('game').as_posix(),
    'precondition':'TARGET_MUST_NOT_EXIST; recheck authored source SHA and provider MP3 SHA before any future copy','applied':False})
  if row['speaker'] not in representatives or audio.shape[1]>representatives[row['speaker']][1].shape[1]:
   representatives[row['speaker']]=(manifest[-1],audio)
 # First batch: exactly eleven five-second navigation slots with 0.5s gaps.
 # Extended: choose twelve diverse non-main NPCs for a separate one-minute reel.
 samples=list(representatives.values())
 if a.batch=='extended':
  samples=[v for v in samples if v[0]['speaker'] not in ['冷孤云','旁白']][:12]
 slot=5 if a.batch=='first74' else 4.5;gap=.5
 chunks=[];timeline=[];offset=0
 for i,(info,audio) in enumerate(samples):
  frames=round(slot*SR);count=min(frames,audio.shape[1]);piece=np.zeros((2,frames),dtype=np.float32);piece[:,:count]=audio[:,:count]
  chunks.append(piece)
  timeline.append({'speaker':info['speaker'],'voice':info['voice'],'id':info['id'],'text':info['spoken_text'],'source':info['source'],
   'start_seconds':offset/SR,'source_prefix_frames':count,'slot_padding_frames':frames-count,'end_seconds':(offset+frames)/SR})
  offset+=frames
  if i+1<len(samples):chunks.append(np.zeros((2,round(gap*SR)),dtype=np.float32));offset+=round(gap*SR)
 medley=np.concatenate(chunks,axis=1);wav=OUT/(a.batch+'_role_audition.wav');y,qc=write_wav(wav,medley)
 mp3=wav.with_suffix('.mp3')
 if mp3.exists():raise FileExistsError('Existing MP3 preserved')
 encode_mp3(mp3,np.ascontiguousarray(y))
 doc={'status':'GENERATED_CANDIDATE_LISTENING_PENDING_NOT_APPLIED','batch':a.batch,'lines':len(manifest),'speakers':len(representatives),
  'requested_original_batch':results['requested'],'original_batch_failures_preserved':results['failures'],'skipped_failure_jobs':[r.get('job',r.get('line'))['id'] for r in results['rows'] if r['status']=='FAILED'],
  'voice_ids':sorted({r['voice'] for r in manifest}),'shared_voices_not_claimed_as_unique_actors':True,
  'audition':{'wav':rec(wav),'mp3':rec(mp3),'qc':qc,'timeline':timeline,'construction':'Original provider MP3 decoded; attenuation-only WAV/medley; short prefix excerpts with declared navigation gaps/padding. Not full-line coverage listening.'},
  'raw_provider_mp3_retained':True,'rows':manifest,'copy_plan':copy_rows,'game_integration':'NONE','script':rec(Path(__file__))}
 fresh_json(OUT/(a.batch+'_voice_manifest.json'),doc)
 lines=['# 配音候选索引（未接入）','','完整台词音频均保留；串听是开头节选，空白间隔仅用于导航。共享voiceID不冒独立演员。','', '|角色|voiceID|对白ID / 节点|原文|','|---|---|---|---|']
 lines.extend('|'+r['speaker']+'|'+r['voice']+'|'+r['dialog_id']+' / '+r['node_id']+'|'+r['text'].replace('\n',' ').replace('|','/')+'|' for r in manifest)
 with (OUT/(a.batch+'_voice_index.md')).open('x',encoding='utf-8') as f:f.write('\n'.join(lines)+'\n')
 print('VOICE_FINALIZED',a.batch,len(manifest),len(representatives),qc['seconds'],flush=True)


if __name__=='__main__':main()
