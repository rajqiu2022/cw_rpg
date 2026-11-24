"""Four remaining source nodes, seven real utterances; preserve old empty files."""
from pathlib import Path
import argparse,asyncio,json,re,sys
import produce_wuxia_npc_voices_20261022 as base
from produce_wuxia_npc_extended_20261022 import runtime_segments

ROOT,OUT=base.ROOT,base.OUT
PLAN=OUT/'voice_residual_plan.json'


def plan():
 source=ROOT/'assets/processed/audio/wuxia_expansion_qa_20261022/missing_explicit_speaker_nodes.json'
 missing=json.loads(source.read_text(encoding='utf-8'))['nodes']
 keys={('ch1_s2_inn_keeper','c'),('ch1_tutorial_xingfantian','n6_choice'),('ch1_s3_ruin_boss','start')}
 wanted=[n for n in missing if (n['dialog_id'],n['node_id']) in keys]
 invalid=ROOT/'assets/processed/audio/wuxia_expansion_qa_20261022/invalid_existing_voice_sources.json'
 wanted+=json.loads(invalid.read_text(encoding='utf-8'))['affected_explicit_static_nodes']
 if len(wanted)!=4:raise ValueError('Exactly four source nodes required')
 jobs=[]
 for old in wanted:
  p=ROOT/old['file'];n=next(n for n in base.nodes(p) if n['node_id']==old['node_id'])
  if n['text']!=old['text'] or n['speaker']!=old['speaker']:raise ValueError('QA source drift')
  if n['speaker']=='江湖散兵':
   segments=runtime_segments(n['text'],n['speaker'])
   if len(segments)!=4:raise ValueError('Expected four real ordered fragments')
   for i,(segment,target) in enumerate(zip(segments,old['expected_segments']),1):
    jobs.append({**n,'id':f'{n["dialog_id"]}__{n["node_id"]}__res{i:02d}_{segment["kind"]}',
      'spoken_text':segment['text'],'voice':'zh-CN-YunyangNeural' if segment['kind']=='narr' else 'zh-CN-YunjianNeural',
      'segment_kind':segment['kind'],'proposed_game_path':Path(target).as_posix(),
      'rendering_policy':'Four real narration/dialogue fragments in authored order; preserve raw zero-byte fallback and old threat clip.'})
  else:
   spoken=re.sub(r'\[/?[^\]]+\]','',n['text']).strip().strip('（）() ')
   jobs.append({**n,'id':f'{n["dialog_id"]}__{n["node_id"]}__res_primary',
     'spoken_text':spoken,'voice':'zh-CN-YunxiNeural' if n['speaker']=='冷孤云' else 'zh-CN-YunjianNeural',
     'segment_kind':'dialog','proposed_game_path':Path(old['expected_primary']).as_posix(),
     'rendering_policy':'Real character inner thought/current speech via valid primary emotion fallback; no empty markup segment files created.'})
 for j in jobs:
  j.update(rate='+0%',pitch='+0Hz',volume='+0%',runtime_emotion='normal')
  if (ROOT/j['proposed_game_path']).exists():raise FileExistsError('Target must remain absent')
 base.write_new(PLAN,{'status':'SOURCE_BOUND_CANDIDATE_NOT_APPLIED','node_count':4,'utterance_count':len(jobs),
  'qa_sources':[{'path':p.relative_to(ROOT).as_posix(),'sha256':base.sha(p)} for p in [source,invalid]],
  'lines':jobs,'old14_zero_mp3_preserved':True,'game_integration':'NONE'})
 print('RESIDUAL_PLAN',4,'nodes',len(jobs),'utterances',flush=True)


if __name__=='__main__':
 if sys.platform=='win32':asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
 a=argparse.ArgumentParser();a.add_argument('--mode',choices=['plan','render'],required=True);args=a.parse_args()
 if args.mode=='plan':plan()
 else:
  completed=json.loads((OUT/'voices_extended/result.json').read_text(encoding='utf-8'))
  if completed['generated']!=604 or completed['failures']:raise ValueError('Wait for sealed604 natural completion')
  jobs=json.loads(PLAN.read_text(encoding='utf-8'))['lines'];asyncio.run(base.synthesize(jobs,'voices_residual'))
