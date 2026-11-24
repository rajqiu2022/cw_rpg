"""Run official Stable Audio 3 Small-SFX CPU and trim one measurable event.

Use the isolated runtime Python. Raw model audio is preserved. Trims are
algorithm-selected audition candidates; semantic and aesthetic approval is pending.
"""
from pathlib import Path
import argparse, hashlib, json, os, subprocess, time
import numpy as np
import soundfile as sf
import lameenc

ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT/'tools/audio/stable-audio-3'
CPU = RUNTIME/'optimized/tflite'
OUTPUT = ROOT/'assets/raw/audio/wuxia_sfx_ai_trial_20261009'
CASES = [
 ('sword_draw', 1009401, 'Close-up dry foley of a steel Chinese jian sword being drawn once from a wooden scabbard. Brief scraping metal friction, a crisp clear final metallic ring. One isolated realistic action in a quiet recording studio. No music, speech, background noise or reverb.',1.6),
 ('sword_swing',1009402,'Close-up dry foley of a light Chinese jian sword cutting rapidly through the air, one short sharp airy whoosh with a small cloth sleeve swish. Isolated single realistic sword swing, quiet recording studio. No impact, no electronic sounds, no music, no voice, no ambience, no reverberation.',1.0),
 ('weapon_parry',1009403,'One crisp collision between two steel Chinese jian sword blades, a sharp metallic clang with a short natural ringing decay. Close-up dry realistic martial arts foley, isolated hit in a quiet recording studio. No explosions, no electronic sounds, no music or voice, no reverberation.',1.6),
 ('cloth_palm_hit',1009404,'One realistic open palm strike on a clothed torso, a short firm dull body thud and light cotton fabric rustle. Close-up dry martial arts foley, isolated action in a quiet studio. No cracking bones, no blood, no shouting, no music, no ambience, no electronic sounds, no reverberation.',1.0),
]

def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  while b:=f.read(1024*1024): h.update(b)
 return h.hexdigest()

def run(case):
 name,seed,prompt,_=case
 raw=OUTPUT/'raw'/f'{name}_seed{seed}_6s.wav'
 if raw.exists(): return raw
 python=CPU/'.venv/Scripts/python.exe'
 cmd=[str(python),str(ROOT/'scripts/audio/run_stable_wuxia_inference.py'),'--dit','sm-sfx','--decoder','same-s','--seconds','6','--steps','8','--threads','4','--seed',str(seed),'--prompt',prompt,'--out',str(raw)]
 env=os.environ.copy()
 env.update({'HF_HUB_OFFLINE':'1','HF_HUB_DISABLE_IMPLICIT_TOKEN':'1','OMP_NUM_THREADS':'4','MKL_NUM_THREADS':'4','OPENBLAS_NUM_THREADS':'4','PYTHONIOENCODING':'utf-8'})
 start=time.monotonic()
 with (OUTPUT/'logs'/f'{name}.stdout.log').open('w',encoding='utf-8') as out,(OUTPUT/'logs'/f'{name}.stderr.log').open('w',encoding='utf-8') as err:
  result=subprocess.run(cmd,cwd=CPU,env=env,stdout=out,stderr=err)
 (OUTPUT/'logs'/f'{name}.invocation.json').write_text(json.dumps({'argv':cmd,'exit_code':result.returncode,'elapsed_seconds':time.monotonic()-start},indent=2),encoding='utf-8')
 if result.returncode!=0 or not raw.exists(): raise RuntimeError(f'{name} model inference failed; raw logs retained')
 return raw

def trim(case,raw):
 name,seed,prompt,max_seconds=case
 x,sr=sf.read(raw,always_2d=True,dtype='float32')
 if not np.isfinite(x).all(): raise RuntimeError('nonfinite audio')
 hop=max(1,round(sr*.005)); win=max(1,round(sr*.02))
 energy=np.mean(x*x,axis=1)
 rms=np.sqrt(np.convolve(energy,np.ones(win)/win,mode='same')[::hop])
 peak_index=int(rms.argmax()); peak_rms=float(rms[peak_index])
 if peak_rms<1e-5: raise RuntimeError('silent raw model output')
 threshold=peak_rms*.045
 left=peak_index
 while left>0 and rms[left-1]>threshold: left-=1
 right=peak_index
 while right<len(rms)-1 and rms[right+1]>threshold: right+=1
 start=max(0,left*hop-round(.015*sr)); end=min(len(x),(right+1)*hop+round(.08*sr),start+round(max_seconds*sr))
 if end<=peak_index*hop: start=max(0,peak_index*hop-round(.12*sr)); end=min(len(x),start+round(max_seconds*sr))
 y=x[start:end].copy()
 fade=min(round(.002*sr),len(y)//4)
 if fade:
  y[:fade]*=np.linspace(0,1,fade)[:,None]
  y[-fade:]*=np.linspace(1,0,fade)[:,None]
 gain=min(1,.82/max(float(np.abs(y).max()),1e-9)); y*=gain
 trimfile=OUTPUT/'trim'/f'{name}_trial.wav'
 sf.write(trimfile,y,sr,subtype='PCM_16')
 reread,_=sf.read(trimfile,always_2d=True)
 clip=int((np.abs(reread)>=.999).sum())
 return {'id':name,'model':'Stable Audio 3 Small-SFX optimized CPU','seed':seed,'prompt':prompt,'raw_path':str(raw.relative_to(ROOT)),'raw_sha256':sha(raw),'raw_format':'IEEE float32 preserved decoder; values above unity are not clipping','raw_samples_above_unity':int((np.abs(x)>1).sum()),'trim_path':str(trimfile.relative_to(ROOT)),'trim_sha256':sha(trimfile),'sample_rate':sr,'channels':x.shape[1],'source_frames':len(x),'crop_frames':[start,end],'trim_frames':len(y),'fade_frames':fade,'raw_duration_seconds':len(x)/sr,'source_range_seconds':[start/sr,end/sr],'trim_duration_seconds':len(y)/sr,'selection':'highest RMS event, 20ms RMS, threshold4.5% peak,15ms pre-roll/80ms tail; bounded per case; raw may contain multiple actions','postprocess':'2ms linear edge fades; attenuation only, no pitch/spectral editing','gain':gain,'clipped_samples':clip,'peak':float(np.abs(reread).max()),'rms':float(np.sqrt(np.mean(reread*reread))),'technical_non_silent':bool(np.max(np.abs(reread))>.0001),'semantic_listening':'PENDING','wuxia_listening':'PENDING'},y,sr

def main():
 ap=argparse.ArgumentParser(); ap.add_argument('--process-only',action='store_true'); ap.add_argument('--limit',type=int,default=4); args=ap.parse_args()
 for folder in ['raw','trim','logs','licenses']: (OUTPUT/folder).mkdir(parents=True,exist_ok=True)
 runtime=json.loads((RUNTIME/'trial_runtime_manifest.json').read_text())
 needed=['tflite/sa3-sm-sfx/dit_fp32.tflite','tflite/t5gemma/encoder_fp16.tflite','tflite/same-s/dec_w8a8.tflite']
 runtime['files']=[f for f in runtime['files'] if f['file'] in needed or f['file'].startswith('LICENSE')]
 actual={f['file']:f for f in runtime['files']}
 for filename in needed:
  if filename not in actual or sha(Path(actual[filename]['path']))!=actual[filename]['sha256']:
   raise RuntimeError('Pinned model missing or byte hash changed: '+filename)
 for name in ['LICENSE.md','LICENSE_GEMMA.md']:
  (OUTPUT/'licenses'/name).write_bytes((RUNTIME/'trial-licenses'/name).read_bytes())
 (OUTPUT/'runtime-requirements.txt').write_bytes((RUNTIME/'trial-requirements.txt').read_bytes())
 records=[]; pieces=[]; sr=44100
 for case in CASES[:args.limit]:
  raw=OUTPUT/'raw'/f'{case[0]}_seed{case[1]}_6s.wav' if args.process_only else run(case)
  record,y,sr=trim(case,raw); records.append(record)
  pieces.extend([y,np.zeros((int(.65*sr),y.shape[1]),dtype='float32'),y,np.zeros((int(1.1*sr),y.shape[1]),dtype='float32')])
  print(case[0],record['trim_duration_seconds'],'seconds',flush=True)
 audition=OUTPUT/'wuxia_sfx_ai_audition.wav'; sf.write(audition,np.concatenate(pieces),sr,subtype='PCM_16')
 pcm,_=sf.read(audition,dtype='int16',always_2d=True)
 encoder=lameenc.Encoder(); encoder.set_bit_rate(192); encoder.set_in_sample_rate(sr); encoder.set_channels(pcm.shape[1]); encoder.set_quality(2)
 mp3=audition.with_suffix('.mp3'); mp3.write_bytes(encoder.encode(pcm.tobytes())+encoder.flush())
 manifest={'status':'ISOLATED_AI_SFX_AUDITION_PENDING','commercial_adoption':'NOT_APPROVED; Stable community registration required before commercial use','creation':'actual official model inference; no existing audio source; event crop retains full raw','runtime':runtime,'threads':4,'steps':8,'duration_requested_seconds':6,'cases':records,'audition':{'path':str(audition.relative_to(ROOT)),'sha256':sha(audition),'mp3_path':str(mp3.relative_to(ROOT)),'mp3_sha256':sha(mp3),'mp3_encoding':'lameenc1.8.4,192kbps,quality2,44.1k stereo','order':[c['id'] for c in records],'sequence':'each event twice with650ms gap,1100ms between categories'},'game_integration':'none'}
 manifest['reproduction']={'script':str(Path(__file__).relative_to(ROOT)),'script_sha256':sha(Path(__file__)),'float_export_wrapper':'scripts/audio/run_stable_wuxia_inference.py','wrapper_sha256':sha(ROOT/'scripts/audio/run_stable_wuxia_inference.py'),'runtime_requirements_sha256':sha(OUTPUT/'runtime-requirements.txt')}
 (OUTPUT/'manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
 print('Saved',audition,flush=True)

if __name__=='__main__': main()
