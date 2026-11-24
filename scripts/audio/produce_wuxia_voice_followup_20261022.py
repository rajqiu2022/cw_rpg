"""One bounded local-path retry plus the four residual source nodes."""
from pathlib import Path
import argparse,asyncio,json,sys
import produce_wuxia_npc_voices_20261022 as base

OUT=base.OUT
PLAN=OUT/'voice_followup_plan.json'


def prepare():
 completed=json.loads((OUT/'voices_extended/result.json').read_text(encoding='utf-8'))
 failed=[r for r in completed['rows'] if r['status']=='FAILED']
 if completed['generated']!=603 or len(failed)!=1 or failed[0]['error_type']!='FileNotFoundError':raise ValueError('Only the observed one local path failure is authorized')
 jobs=json.loads((OUT/'voice_residual_plan.json').read_text(encoding='utf-8'))['lines']
 retry=dict(failed[0]['job']);retry['failed_original_job_id']=retry['id'];retry['id']=retry['id'].replace('/','__').replace('\\','__')+'__retry1'
 retry['retry_reason']='Previous nested candidate filename parent missing. Preserve exact proposed runtime path; safe candidate filename only.'
 jobs.append(retry)
 if len(jobs)!=8:raise ValueError('Exactly eight utterances')
 base.write_new(PLAN,{'status':'SOURCE_BOUND_CANDIDATE_NOT_APPLIED','node_count':5,'utterance_count':8,'lines':jobs,
  'extended603_preserved':True,'failed_extended_attempt_preserved':True,'prior_residual_precondition_rejection_preserved':True,
  'purpose':'Four residual nodes (7 utterances) plus one bounded local-path retry (1 utterance); no old or successful file overwritten.',
  'source_plan_sha256':base.sha(OUT/'voice_residual_plan.json'),'source_result_sha256':base.sha(OUT/'voices_extended/result.json')})


if __name__=='__main__':
 if sys.platform=='win32':asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
 p=argparse.ArgumentParser();p.add_argument('--mode',choices=['plan','render'],required=True);args=p.parse_args()
 if args.mode=='plan':prepare()
 else:asyncio.run(base.synthesize(json.loads(PLAN.read_text(encoding='utf-8'))['lines'],'voices_followup'))
