"""24 actual local Small-SFX takes, each with two honest event variants.

Run only after the BGM author releases the sole Stable CPU queue. NEW output
only; no game writes. Full IEEE-float model audio is retained before crops.
"""
from pathlib import Path
import argparse, hashlib, json, os, subprocess, time, wave
import numpy as np
from scipy.signal import butter, sosfilt
from produce_wuxia_stable_trial import decode, encode_mp3

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/processed/audio/wuxia_voice_sfx_expansion_20261022'
CPU=ROOT/'tools/audio/stable-audio-3/optimized/tflite'
WRAPPER=ROOT/'scripts/audio/run_stable_wuxia_inference.py'
SR=44100
CASES=[
 ('jian_draw','sword',1.3,'One Chinese jian sword drawn from a wooden scabbard, friction scrape ending with a delicate steel ring.'),
 ('jian_light_cut','sword',.70,'One quick light Chinese jian sword slash through air, a narrow sharp airy whip and short sleeve swish.'),
 ('jian_heavy_cut','sword',.95,'One forceful Chinese jian sword downward cut, a weighty air displacement with a crisp steel edge whisper.'),
 ('jian_thrust','sword',.60,'One precise straight jian sword thrust, a short narrow forward air slice with a tiny cloth cuff movement.'),
 ('dao_draw','blade',1.1,'One broad Chinese dao blade pulled firmly from its scabbard, rough scrape and short low metallic rattle.'),
 ('dao_chop','blade',.85,'One heavy broad dao saber chopping downward through the air, weighty low air rush followed by a sharp edge snap.'),
 ('dao_sweep','blade',1.0,'One broad Chinese dao saber horizontal sweeping cut, wide curved rushing air and short coarse cloth movement.'),
 ('spear_thrust','staff',.65,'One long wooden spear thrust through the air, a narrow pointed rush, light wood vibration and brief shaft flex.'),
 ('staff_swing','staff',.95,'One thick wooden martial staff swing, hollow woody air rush, warm shaft vibration, no metal ringing.'),
 ('staff_contact','wood',.75,'One hardwood martial staff striking another wooden staff, a solid dry wooden crack and short hollow resonance.'),
 ('palm_push','body',.75,'One open palm push striking a thick cotton training pad, a soft deep thump with short fabric friction, no bones.'),
 ('fist_contact','body',.55,'One closed fist striking a clothed padded torso, a tight dry dull impact with a compact low thud, no vocalization.'),
 ('kick_contact','body',.80,'One martial arts boot kick against a cloth training bag, a weighty leather slap and deep short padded thud.'),
 ('dart_throw','ranged',.50,'One small metal throwing dart released rapidly through the air, a very short fine bright air flick, no gunshot.'),
 ('dart_wood','wood',.65,'One small steel throwing dart sticking into dry wood, a tiny sharp tick and short grain crack, no explosion.'),
 ('needles_release','ranged',.90,'A single small volley of three tiny throwing needles released from a sleeve, quick delicate air ticks and a cloth flick.'),
 ('qi_gather','qi',1.8,'A restrained martial artist gathering internal breath, a smooth organic inhaling air pressure swell with subtle sleeve tension, no voice.'),
 ('qi_release','qi',1.25,'One fictional martial arts palm force release, a compact organic burst of compressed air and low padded pressure thump, no electronic laser.'),
 ('steel_parry','metal',1.25,'One crisp collision of two steel Chinese sword blades, a sharp compact metallic clang with a short realistic ringing decay.'),
 ('wooden_guard','wood',.85,'One wooden staff catching a broad blade, a firm woody knock and a tiny brief scrape of steel against wood.'),
 ('arm_guard','body',.65,'One forearm martial arts block against a padded cotton sleeve, a firm short soft thump and cloth snap.'),
 ('lightstep_dash','movement',.80,'One very fast martial artist dash, a brief cotton robe swish and quiet leather shoe scuff, dry close microphone.'),
 ('lightstep_land','movement',.70,'One controlled soft martial artist landing on a dry stone floor, two light leather shoe contacts and a short robe settle.'),
 ('sleeve_ready','movement',.95,'One martial artist raising both arms into a ready stance, a single clean cotton sleeve unfurl and short taut fabric snap.'),
]


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rec(p):return {'path':p.relative_to(ROOT).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)}
def put(p,data):
 p.parent.mkdir(parents=True,exist_ok=True)
 p.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')


def plan():
 p=OUT/'sfx_plan.json'
 if p.exists():raise FileExistsError('Existing plan preserved')
 rows=[]
 for i,(name,family,crop,prompt) in enumerate(CASES):
  rows.append({'id':name,'family':family,'seed':20261022001+i,'seconds':6,'max_event_seconds':crop,
    'prompt':prompt+' Isolated close-up dry clean game foley, one concise action in a quiet studio. No music, speech, singing, screams, reverberation, environmental ambience, electronic sounds, explosions or science fiction weapons.'})
 put(p,{'status':'AUTHORIZED_CANDIDATE_NOT_INFERRED','method':'actual installed official Stable Audio 3 Small-SFX CPU; not sampled from old clips',
  'model_revision':'a0109036e3009e47ba7dcb8a2fec7ee6ac0d1ef8','runtime_revision':'3a82c807b69cf4b7c5c05270011a5d5e47abac18',
  'steps':8,'threads':4,'raw_takes':24,'derived_variants':48,'variant_policy':'standard = selected original event; textured = same event with a quiet original physical/noise layer, explicitly derived, not another independent model take',
  'queue':'Only after explicit sole-CPU queue release by BGM author. No parallel Stable instances.',
  'purpose':'PERSONAL_NONCOMMERCIAL_EVALUATION','game_integration':'NONE','cases':rows})


def preflight():
 prepared=ROOT/'tools/audio/stable-audio-3/trial_runtime_manifest.json'
 manifest=json.loads(prepared.read_text(encoding='utf-8'))
 required={'tflite/sa3-sm-sfx/dit_fp32.tflite','tflite/t5gemma/encoder_fp16.tflite','tflite/same-s/dec_w8a8.tflite'}
 if manifest['weights_revision']!='a0109036e3009e47ba7dcb8a2fec7ee6ac0d1ef8':raise ValueError('Pinned model mismatch')
 checked=[]
 for r in manifest['files']:
  if r['file'] in required:
   p=Path(r['path'])
   if sha(p)!=r['sha256'] or p.stat().st_size!=r['size']:raise ValueError('Weight integrity mismatch')
   checked.append(rec(p))
 if len(checked)!=3:raise ValueError('Incomplete Small-SFX set')
 revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=CPU,text=True).strip()
 if revision!='3a82c807b69cf4b7c5c05270011a5d5e47abac18':raise ValueError('Runtime revision mismatch')
 if sha(WRAPPER)!='b1ed1f40e5ced8a63f07a6a29de236d56461429272ffa6fcbf2a19bcd725372c':raise ValueError('Frozen float wrapper mismatch')
 return {'runtime_preparation':rec(prepared),'model_files':checked,'float_wrapper':rec(WRAPPER),'runtime_revision':revision}


def infer(case,identity):
 raw=OUT/'sfx/raw'/(case['id']+'_raw.wav'); meta=raw.with_suffix('.invocation.json'); log=raw.with_suffix('.log')
 if any(p.exists() for p in [raw,meta,log]):raise FileExistsError('Prior model attempt preserved: '+case['id'])
 raw.parent.mkdir(parents=True,exist_ok=True)
 command=[str(CPU/'.venv/Scripts/python.exe'),str(WRAPPER),'--dit','sm-sfx','--decoder','same-s','--dit-precision','fp32','--decoder-precision','w8a8',
  '--prompt',case['prompt'],'--seconds','6','--steps','8','--threads','4','--seed',str(case['seed']),'--out',str(raw)]
 m={'status':'RUNNING','case':case,'identity':identity,'command':command,'script':rec(Path(__file__)),'automatic_retry':False}
 put(meta,m);start=time.monotonic()
 with log.open('x',encoding='utf-8') as f:
  result=subprocess.run(command,cwd=CPU,stdout=f,stderr=subprocess.STDOUT,env={**os.environ,'HF_HUB_OFFLINE':'1','HF_HUB_DISABLE_IMPLICIT_TOKEN':'1','OMP_NUM_THREADS':'4','MKL_NUM_THREADS':'4','OPENBLAS_NUM_THREADS':'4'})
 m.update(status='COMPLETE' if result.returncode==0 else 'FAILED',exit_code=result.returncode,elapsed_seconds=time.monotonic()-start,log=rec(log));put(meta,m)
 if result.returncode or not raw.exists():raise RuntimeError('Failed take retained; no automatic retry')
 return raw


def layer(family,n,seed):
 rng=np.random.default_rng(seed); t=np.arange(n)/SR; noise=rng.standard_normal(n)
 def band(lo,hi):return sosfilt(butter(2,[lo,hi],btype='bandpass',fs=SR,output='sos'),noise)
 if family in ['sword','blade','metal']:
  frequencies=[1380,2174,3610] if family!='blade' else [430,811,1534]
  x=sum(np.sin(2*np.pi*f*t)*np.exp(-t*(15+i*7)) for i,f in enumerate(frequencies))*.12+band(2600,7800)*np.exp(-t*35)
 elif family in ['staff','wood']:
  x=band(150,1400)*np.exp(-t*35)+.2*np.sin(2*np.pi*220*t)*np.exp(-t*42)
 elif family=='body':
  x=np.sin(2*np.pi*(115*t-22*t*t))*np.exp(-t*45)+.25*band(700,4200)*np.exp(-t*60)
 elif family=='qi':
  x=band(180,1800)*np.sin(np.pi*np.minimum(t/max(t[-1],.01),1))**2
 elif family=='ranged':
  x=band(2900,9000)*np.exp(-t*75)
 else:
  x=band(350,3400)*np.exp(-t*24)+.18*band(150,750)*np.exp(-t*45)
 return x/max(np.sqrt(np.mean(x*x)),1e-9)


def pcm(p,y):
 if p.exists():raise FileExistsError('Existing event preserved')
 y=np.asarray(y,dtype=np.float32);peak=float(np.max(np.abs(y)))
 gain=min(1,.78/max(peak,1e-9));y=y*gain
 ramp=min(round(.003*SR),y.shape[1]//4)
 y[:,:ramp]*=np.linspace(0,1,ramp);y[:,-ramp:]*=np.linspace(1,0,ramp)
 samples=np.rint(y.T*32767).astype('<i2')
 p.parent.mkdir(parents=True,exist_ok=True)
 with wave.open(str(p),'wb') as f:f.setparams((2,2,SR,0,'NONE','not compressed'));f.writeframes(samples.tobytes())
 if not np.isfinite(y).all() or (np.abs(samples.astype(np.int32))>=32767).any():raise ValueError('Invalid PCM')
 return {'output':rec(p),'frames':len(samples),'seconds':len(samples)/SR,'gain':gain,'fade_frames':ramp,'peak':float(np.abs(samples.astype(np.int32)).max()/32768),'rms':float(np.sqrt(np.mean((samples.astype(np.float64)/32768)**2))),'full_scale_pcm_samples':0},y


def process(cases):
 records=[];pieces=[]
 for c in cases:
  raw=OUT/'sfx/raw'/(c['id']+'_raw.wav');x=decode(raw).astype(np.float32)
  if not np.isfinite(x).all() or np.max(np.abs(x))<1e-4:raise ValueError('Invalid raw take')
  # 20ms mean energy; explicit highest-event crop, not a claim of one action.
  energy=np.mean(x*x,axis=0); win=882
  smooth=np.convolve(energy,np.ones(win)/win,mode='same');center=int(smooth.argmax())
  threshold=float(smooth[center])*.008;left=center;right=center
  while left>0 and smooth[left-1]>threshold:left-=1
  while right<len(smooth)-1 and smooth[right+1]>threshold:right+=1
  start=max(0,left-441);end=min(len(energy),right+3528,start+round(c['max_event_seconds']*SR))
  if end<=center:start=max(0,center-round(.12*SR));end=min(len(energy),start+round(c['max_event_seconds']*SR))
  event=x[:,start:end].copy();rms=float(np.sqrt(np.mean(event*event)))
  if rms<1e-5:raise ValueError('Silent event')
  variants=[]
  for variant in ['standard','textured']:
   y=event.copy();mix=0
   if variant=='textured':
    physical=layer(c['family'],y.shape[1],c['seed']+90000);mix=rms*.12;y+=physical[None,:]*mix
   info,audio=pcm(OUT/'sfx/events'/(c['id']+'_'+variant+'.wav'),y)
   info.update(id=c['id']+'_'+variant,base_id=c['id'],variant=variant,physical_layer_family=c['family'] if mix else None,physical_layer_seed=c['seed']+90000 if mix else None,layer_gain=mix,layer_rms_relative_to_event=.12 if mix else 0)
   variants.append(info);pieces.extend([audio,np.zeros((2,round(.5*SR)),dtype=np.float32)])
  records.append({'case':c,'raw':rec(raw),'raw_frames':x.shape[1],'raw_samples_above_unity':int((np.abs(x)>1).sum()),'raw_above_unity_is_not_float_clipping':True,'crop_frames':[start,end],'selection':'highest 20ms mean-energy event,0.8% energy threshold,10ms preroll/80ms tail; raw may contain multiple events','variants':variants,'listening':'PENDING'})
 preview=np.concatenate(pieces,axis=1);p=OUT/'sfx/sfx_all_48_audition.wav';audition,y=pcm(p,preview)
 mp3=p.with_suffix('.mp3')
 if mp3.exists():raise FileExistsError('Existing audition preserved')
 encode_mp3(mp3,np.ascontiguousarray(y))
 put(OUT/'sfx/manifest.json',{'status':'CANDIDATE_LISTENING_PENDING','actual_model_takes':len(records),'event_files':sum(len(r['variants']) for r in records),'sources':records,'audition':audition,'audition_mp3':rec(mp3),'order':[r['id'] for b in records for r in b['variants']],'game_integration':'NONE','script':rec(Path(__file__))})


def main():
 a=argparse.ArgumentParser();a.add_argument('--mode',choices=['plan','generate','process'],required=True);a.add_argument('--case',default='all');args=a.parse_args()
 if args.mode=='plan':plan();return
 doc=json.loads((OUT/'sfx_plan.json').read_text(encoding='utf-8'));cases=doc['cases']
 if args.case!='all':cases=[c for c in cases if c['id']==args.case]
 if not cases:raise ValueError('Unknown case')
 if args.mode=='generate':
  identity=preflight()
  for c in cases:
   infer(c,identity);print('SFX_TAKE_COMPLETE',c['id'],flush=True)
 else:process(cases)


if __name__=='__main__':main()
