"""Recursive missing-node TTS extension. Immutable authored text, explicit casting.

Uses QA's actual DialogPlayer lookup inventory, including nested city dialogues.
Existing valid clips and the sealed first74 batch are never regenerated here.
"""
from pathlib import Path
import argparse, asyncio, importlib.util, json, re, sys, time
import produce_wuxia_npc_voices_20261022 as base
import edge_tts

ROOT,OUT=base.ROOT,base.OUT
PLAN=OUT/'voice_extended_plan.json'
QA=ROOT/'assets/processed/audio/wuxia_expansion_qa_20261022/missing_explicit_speaker_nodes.json'


def runtime_segments(text,speaker):
    def plain(t):return re.sub(r'\[/?[^\]]+\]','',t).strip()
    if speaker=='旁白':return [{'kind':'narr','text':plain(text).strip('（）() ')}]
    result=[];cursor=0
    while cursor<len(text):
        opens=[i for i in [text.find('（',cursor),text.find('(',cursor)] if i>=0]
        if not opens:
            if text[cursor:].strip():result.append({'kind':'dialog','text':plain(text[cursor:])})
            break
        op=min(opens)
        if text[cursor:op].strip():result.append({'kind':'dialog','text':plain(text[cursor:op])})
        closes=[i for i in [text.find('）',op+1),text.find(')',op+1)] if i>=0]
        if not closes:result.append({'kind':'dialog','text':plain(text[op:])});break
        cl=min(closes);result.append({'kind':'narr','text':plain(text[op+1:cl])});cursor=cl+1
    return result


def prepare():
    spec=importlib.util.spec_from_file_location('existing_voice_map_readonly',ROOT/'scripts/gen_dialog_voices.py')
    old=importlib.util.module_from_spec(spec);spec.loader.exec_module(old)
    first=json.loads((OUT/'voice_plan.json').read_text(encoding='utf-8'))
    sealed={(r['dialog_id'],r['node_id']) for r in first['lines']}
    profiles={k:{'voice':v[0],'gender':v[1],'age':v[2],'basis':'sealed first74 profile'} for k,v in base.PROFILES.items()}
    rows=json.loads(QA.read_text(encoding='utf-8'))['nodes']
    old_actors=set()
    for p in (ROOT/'game/art/audio/voices').rglob('*.mp3'):
        old_actors.add(p.name.split('_')[0])
    for speaker in sorted({n['speaker'] for n in rows}):
        if speaker in profiles:continue
        if speaker in old.VOICE_MAP:
            voice=old.VOICE_MAP[speaker];basis='existing VOICE_MAP'
        elif speaker in old_actors:
            voice=old.DEFAULT_VOICE;basis='existing actor clips; preserve old generator default'
        elif speaker=='旁白':voice='zh-CN-YunyangNeural';basis='existing narration voice'
        elif speaker=='戚云笙':voice='zh-TW-HsiaoChenNeural';basis='new female protagonist casting; Mandarin Taiwan voice, accent disclosed'
        elif speaker in ['封砚秋','左明远','南市书生','村塾先生','论剑执笔人']:
            voice='zh-TW-YunJheNeural';basis='new adult male scholarly casting; Mandarin Taiwan voice, accent disclosed'
        elif any(s in speaker for s in ['妇','婆','女子','大婶','师太']):
            voice='zh-CN-XiaoyiNeural';basis='new explicitly female occupational role'
        elif any(s in speaker for s in ['伙计','脚夫','弟子','学徒','货郎']):
            voice='zh-CN-YunxiNeural';basis='new young-adult occupational casting'
        elif any(s in speaker for s in ['吏','录事','总录','掌柜','执事','书办']):
            voice='zh-CN-YunyangNeural';basis='new adult occupational casting'
        else:voice='zh-CN-YunjianNeural';basis='new mature male casting intent, not an authored gender/age assertion'
        gender='female' if voice in ['zh-CN-XiaoyiNeural','zh-CN-XiaoxiaoNeural','zh-TW-HsiaoChenNeural'] else 'male'
        profiles[speaker]={'voice':voice,'gender':gender,'age':'adult casting intent; exact authored age not inferred','basis':basis}
    available={x['ShortName'] for x in json.loads((OUT/'runtime/available_voices.json').read_text(encoding='utf-8'))}
    if any(p['voice'] not in available for p in profiles.values()):raise ValueError('Unsupported fixed casting')
    jobs=[];node_rows=[];excluded=[];dest_seen=set()
    for node in rows:
        key=(node['dialog_id'],node['node_id'])
        if key in sealed:continue
        if not node['generation_required']:
            excluded.append({'dialog_id':key[0],'node_id':key[1],'reason':'Other-emotion legacy candidate needs same-text provenance; not blindly reused.'});continue
        source=ROOT/Path(node['file']);matches=[n for n in base.nodes(source) if n['node_id']==node['node_id']]
        if len(matches)!=1:raise ValueError('Ambiguous source node')
        n=matches[0]
        if n['speaker']!=node['speaker'] or n['text']!=node['text']:raise ValueError('QA source drift')
        segments=runtime_segments(n['text'],n['speaker']);paths=node['expected_segments']
        if len(segments)!=len(paths) or any(not s['text'] for s in segments):
            excluded.append({'dialog_id':key[0],'node_id':key[1],'reason':'Runtime segment/empty-markup edge needs explicit review'});continue
        nr={**n,'runtime_emotion':node['runtime_emotion'],'casting':profiles[n['speaker']],'segments':[]}
        for index,(segment,target) in enumerate(zip(segments,paths),1):
            target=Path(target);expected=ROOT/target
            if not target.name.endswith('_seg%02d_%s.mp3'%(index,segment['kind'])):raise ValueError('Segment filename mismatch')
            if expected.exists():
                nr['segments'].append({'existing_preserved':base.sha(expected),'target':target.as_posix()});continue
            if target.as_posix() in dest_seen:raise ValueError('Duplicate target')
            dest_seen.add(target.as_posix())
            job={**n,'id':f'{n["dialog_id"]}__{n["node_id"]}__{index:02d}_{segment["kind"]}',
                 'segment_index':index,'segment_kind':segment['kind'],'spoken_text':segment['text'],
                 'voice':'zh-CN-YunyangNeural' if segment['kind']=='narr' else profiles[n['speaker']]['voice'],
                 'rate':'+0%','pitch':'+0Hz','volume':'+0%','proposed_game_path':target.as_posix(),
                 'runtime_emotion':node['runtime_emotion']}
            jobs.append(job);nr['segments'].append({'job_id':job['id'],'target':target.as_posix()})
        node_rows.append(nr)
    doc={'status':'SOURCE_BOUND_CANDIDATE_NOT_APPLIED','node_count':len(node_rows),'utterance_count':len(jobs),'qa_inventory':{'path':QA.relative_to(ROOT).as_posix(),'sha256':base.sha(QA)},
         'sealed_first74_plan_sha256':base.sha(OUT/'voice_plan.json'),'casting':profiles,'nodes':node_rows,'jobs':jobs,'excluded':excluded,
         'base_voice_ids':sorted({j['voice'] for j in jobs}),'shared_voice_ids_do_not_mean_unique_actors':True,
         'taiwan_mandarin_accents_disclosed':True,'concurrency':2,'automatic_retries':0,'game_writes':'NONE'}
    base.write_new(PLAN,doc)
    print(json.dumps({'nodes':len(node_rows),'utterances':len(jobs),'voices':doc['base_voice_ids'],'speakers':len({n['speaker'] for n in node_rows}),'excluded':len(excluded)}),flush=True)


async def render():
    plan=json.loads(PLAN.read_text(encoding='utf-8'));dest=OUT/'voices_extended';dest.mkdir(parents=True,exist_ok=True)
    sem=asyncio.Semaphore(2);failures=0
    for job in plan['jobs']:
        for suffix in ['.mp3','.json']:
            if (dest/(job['id']+suffix)).exists():raise FileExistsError('Prior attempt preserved')
    async def one(job):
        nonlocal failures
        async with sem:
            if failures>=2:return {'id':job['id'],'status':'NOT_STARTED_ROUTE_STOPPED'}
            base.bound(job);target=dest/(job['id']+'.mp3');start=time.monotonic()
            result={'job':job,'status':'RUNNING','provider':'edge_tts','version':edge_tts.__version__,'script_sha256':base.sha(Path(__file__)),'attempts':1}
            try:
                comm=edge_tts.Communicate(job['spoken_text'],job['voice'],rate=job['rate'],pitch=job['pitch'],volume=job['volume'],connect_timeout=10,receive_timeout=18)
                await asyncio.wait_for(comm.save(str(target)),timeout=35)
                info=base.decode(target)
                if not info['finite'] or info['rms']<.0001 or info['seconds']<.1:raise ValueError('Invalid audio')
                result.update(status='GENERATED_LISTENING_PENDING',audio_path=target.relative_to(ROOT).as_posix(),audio_sha256=base.sha(target),decode=info)
            except Exception as e:
                result.update(status='FAILED',error_type=type(e).__name__,http_status=getattr(e,'status',None));failures+=1
            result['elapsed_seconds']=time.monotonic()-start;base.write_new(dest/(job['id']+'.json'),result)
            print(json.dumps({'id':job['id'],'status':result['status'],'voice':job['voice']},ensure_ascii=True),flush=True)
            await asyncio.sleep(.15)
            return result
    rows=await asyncio.gather(*(one(j) for j in plan['jobs']))
    base.write_new(dest/'result.json',{'generated':sum(r['status'].startswith('GENERATED') for r in rows),'requested':len(rows),'failures':failures,'rows':rows,'plan_sha256':base.sha(PLAN),'concurrency':2,'automatic_retries':0})


if __name__=='__main__':
    if sys.platform=='win32':asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    ap=argparse.ArgumentParser();ap.add_argument('--mode',choices=['plan','render'],required=True);a=ap.parse_args()
    if a.mode=='plan':prepare()
    else:asyncio.run(render())
