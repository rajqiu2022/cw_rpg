"""Read six existing WAV files and provenance only. No playback/processing/write."""
from pathlib import Path
import array, hashlib, json, math, sys, wave

ROOT=Path('F:/Code/RPG_GAME')
CASES=[
 ('game/art/audio/free/sfx_hit_metal_wuxia_v2.wav','runtime','synthetic_combat_metal_impact','scripts/generate_free_audio.ps1','New-WuxiaImpact .26s,118Hz,.20 metal,seed2102','Only a metal-contact approximation; not recorded/generated pickaxe-on-stone foIey'),
 ('game/art/audio/free/sfx_staff_whoosh_wuxia_v2.wav','runtime','synthetic_staff_air_whoosh','scripts/generate_free_audio.ps1','New-WuxiaWhoosh .28s,82..430Hz,.02 metal,seed1103','Weapon air movement, not leaf/grass plucking'),
 ('game/art/audio/free/sfx_hit_body_wuxia_v2.wav','runtime','synthetic_body_impact','scripts/generate_free_audio.ps1','New-WuxiaImpact .22s,92Hz,no metal,seed2101','Body contact, not plant or rock'),
 ('game/art/audio/free/sfx_ui_confirm_free_v1.wav','runtime','synthetic_UI_confirmation','scripts/generate_free_audio.ps1','New-Tone .12s,660Hz,ui','Explicitly reject as gathering/mining material sound'),
 ('assets/processed/audio/wuxia_voice_sfx_expansion_20261022/sfx/events/steel_parry_standard.wav','candidate_not_game','AI_two_steel_blades_parry','assets/processed/audio/wuxia_voice_sfx_expansion_20261022/sfx/manifest.json','Official installed Stable Audio3 Small-SFX; standard event crop,personal evaluation','Steel sword parry, not pickaxe-stone; not declared game-integrated'),
 ('assets/processed/audio/wuxia_voice_sfx_expansion_20261022/sfx/events/sleeve_ready_standard.wav','candidate_not_game','AI_cotton_sleeve_unfurl','assets/processed/audio/wuxia_voice_sfx_expansion_20261022/sfx/manifest.json','Official installed Stable Audio3 Small-SFX; standard event crop,personal evaluation','Cotton cloth motion, not plant pluck; not declared game-integrated'),
]
rows=[]
for relative,scope,kind,source,method,fit in CASES:
 p=ROOT/relative;b=p.read_bytes()
 with wave.open(str(p),'rb') as stream:
  frames=stream.getnframes();rate=stream.getframerate();channels=stream.getnchannels();width=stream.getsampwidth();pcm=stream.readframes(frames)
  assert width==2 and stream.getcomptype()=='NONE','This audit only expects existing PCM16 WAV'
 values=array.array('h',pcm)
 if sys.byteorder!='little':values.byteswap()
 rows.append({'path':relative,'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b),'seconds':frames/rate,'frames':frames,'sample_rate':rate,'channels':channels,'sample_width_bytes':width,'nonzero_samples':sum(v!=0 for v in values),'peak_PCM16':max(map(abs,values),default=0),'rms_normalized':math.sqrt(sum(v*v for v in values)/max(1,len(values)))/32768,'scope':scope,'declared_kind':kind,'provenance_file':source,'declared_method':method,'material_fit_limit':fit,'listened':False})
print(json.dumps({'status':'READ_ONLY_AUDIO_METADATA_AND_DECLARED_PROVENANCE_NOT_LISTENING_OR_ADOPTION','rows':rows,'dedicated_herb_leaf_pluck_in_runtime_library_found':False,'dedicated_pickaxe_stone_in_runtime_library_found':False,'UI_tone_is_not_mining_foley':True,'candidate_bank_listening_and_integration_pending_per_its_README':True,'engine_calls':0,'audio_playback_calls':0,'audio_processing_or_writes':0,'production_writes':0,'save_access':0},ensure_ascii=False,indent=2))
