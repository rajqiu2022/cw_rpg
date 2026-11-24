"""Build the un-applied exact voice copy union and account for all known gaps."""
from pathlib import Path
import hashlib,json

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/processed/audio/wuxia_voice_sfx_expansion_20261022'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rec(p):return {'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p),'bytes':p.stat().st_size}


def main():
 docs=[]
 for batch in ['first74','extended','followup']:
  p=OUT/(batch+'_voice_manifest.json');docs.append((rec(p),json.loads(p.read_text(encoding='utf-8'))))
 targets={};nodes={};voices=set();speakers=set();seconds=0;fullscale=0
 for receipt,d in docs:
  for r,c in zip(d['rows'],d['copy_plan']):
   target=c['target'];src=ROOT/c['source']['path']
   if target in targets or (ROOT/target).exists():raise ValueError('Duplicate/existing target')
   if sha(src)!=c['source']['sha256'] or sha(ROOT/r['dialog_source']['path'])!=r['dialog_source']['sha256']:raise ValueError('Frozen source changed')
   targets[target]={**c,'batch_manifest':receipt,'speaker':r['speaker'],'voice':r['voice'],'dialog_source':r['dialog_source'],'dialog_id':r['dialog_id'],'node_id':r['node_id']}
   nodes[(r['dialog_source']['path'],r['dialog_id'],r['node_id'])]=True
   voices.add(r['voice']);speakers.add(r['speaker']);seconds+=r['qc']['seconds'];fullscale+=r['qc']['full_scale_pcm_samples']
 missing_path=ROOT/'assets/processed/audio/wuxia_expansion_qa_20261022/missing_explicit_speaker_nodes.json'
 invalid_path=ROOT/'assets/processed/audio/wuxia_expansion_qa_20261022/invalid_existing_voice_sources.json'
 missing=json.loads(missing_path.read_text(encoding='utf-8'))['nodes']
 invalid=json.loads(invalid_path.read_text(encoding='utf-8'))['affected_explicit_static_nodes']
 def available(path):
  p=Path(path);rel=p.as_posix()
  return rel in targets or (p.is_file() and p.stat().st_size>128)
 coverage=[]
 for n in missing+invalid:
  segments=n['expected_segments'];selected=[];branch='missing'
  if segments and available(segments[0]):
   if all(available(p) for p in segments):branch='complete_segments';selected=segments
  elif available(n['expected_primary']):branch='complete_emotion_primary';selected=[n['expected_primary']]
  elif available(n.get('recommended_candidate_fallback_path','')):
   branch='complete_legacy';selected=[n['recommended_candidate_fallback_path']]
  coverage.append({'source':n['file'],'dialog_id':n['dialog_id'],'node_id':n['node_id'],'speaker':n['speaker'],'overlay_branch':branch,'selected_paths':[Path(p).as_posix() for p in selected]})
 unresolved=[r for r in coverage if r['overlay_branch']=='missing']
 if len(targets)!=685 or len(nodes)!=682 or unresolved:raise ValueError('Expected all682 known node gaps covered by685 clips: '+str(unresolved[:2]))
 report={'status':'AUDIO_GENERATED_SOURCE_BOUND_CANDIDATE_OVERLAY_NOT_APPLIED','new_provider_mp3_clips':len(targets),'known_nodes_covered':len(nodes),
  'first_batch_nodes':74,'extended_original_result':'603 successes,1 local FileNotFound failure preserved,only that one job retried in followup',
  'followup_nodes':5,'followup_utterances':8,'original_missing_nodes':681,'additional_invalid_zero_source_nodes':1,
  'voices':sorted(voices),'distinct_speaker_labels':len(speakers),'same_voice_shared_by_speakers_not_unique_actors':True,
  'taiwan_mandarin_voice_ids':['zh-TW-HsiaoChenNeural','zh-TW-YunJheNeural'],'dialect_claim':'Mandarin variants; not Luoyang dialect',
  'total_listen_seconds':seconds,'listen_full_scale_pcm_samples':fullscale,'copy_plan':list(targets.values()),'overlay_node_coverage':coverage,
  'unresolved_known_explicit_nodes':unresolved,'excluded_empty_speaker_context_dependent_nodes':152,
  'sources':[rec(missing_path),rec(invalid_path)],'batch_manifests':[r for r,d in docs],'script':rec(Path(__file__)),
  'limitations':['No game files copied, imported or played in Godot. This is a candidate file overlay, not runtime acceptance.',
   'Pure italic parenthetical inner thoughts use valid emotion-primary fallback; no silent markup-only segments were generated.',
   'Four actual narration/dialogue fragments replace the selected zero-byte legacy gap via segment priority; original14zero files stay untouched.',
   '152 empty speakers need runtime NPC/default-speaker context and are not falsely counted covered.',
   'All685 known source clips are technically decoded, but complete human listening/character acting approval remains pending.']}
 with (OUT/'voice_union_copy_plan.json').open('x',encoding='utf-8') as f:json.dump(report,f,ensure_ascii=False,indent=2)
 print('VOICE_UNION',len(targets),'clips',len(nodes),'nodes',len(speakers),'speakers',len(voices),'voices',round(seconds,3),'seconds',flush=True)


if __name__=='__main__':main()
