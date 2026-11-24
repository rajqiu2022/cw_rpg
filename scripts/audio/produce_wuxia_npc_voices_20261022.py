"""Source-bound NEW voice candidates; isolated Edge 7.3.1 or honest SAPI fallback.

No game writes, no old clips replaced. Probe first; two failed requests stop a
route. Source text is preserved; markup/parenthetical directions are omitted
only from the spoken rendering, with both strings recorded.
"""
from pathlib import Path
import argparse, asyncio, hashlib, importlib.util, json, re, sys, time
import numpy as np
import av

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/processed/audio/wuxia_voice_sfx_expansion_20261022"
RUNTIME = OUT / "runtime/edge_tts_731"
sys.path.insert(0, str(RUNTIME))
import edge_tts


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def write_new(p, value):
    p.parent.mkdir(parents=True, exist_ok=True)
    with p.open("x", encoding="utf-8") as f:
        json.dump(value, f, ensure_ascii=False, indent=2)


def nodes(p):
    text = p.read_text(encoding="utf-8")
    did = re.search(r'^dialog_id\s*=\s*&?("(?:[^"\\]|\\.)*")', text, re.M)
    if not did:
        return []
    result = []
    for block in re.findall(r'\[sub_resource[^\]]*\](.*?)(?=\n\[sub_resource|\n\[resource\])', text, re.S):
        fields = {}
        for key in ("node_id", "speaker", "text", "voice_emotion"):
            m = re.search(r'^' + key + r'\s*=\s*&?("(?:[^"\\]|\\.)*")\s*$', block, re.M)
            if m:
                fields[key] = json.loads(m.group(1))
        if all(k in fields for k in ("node_id", "speaker", "text")):
            fields.update(dialog_id=json.loads(did.group(1)), dialog_path=p.relative_to(ROOT).as_posix(), dialog_sha256=sha(p))
            result.append(fields)
    return result


def spoken(text):
    clean = re.sub(r'\[/?[^\]]+\]', '', text)
    clean = re.sub(r'[（(][^）)]*[）)]', '', clean)
    return re.sub(r'\s+', '', clean).strip('。，、 ')


# These are persistent provider voice IDs, never pitch-shifted actor claims.
PROFILES = {
    "老纸匠": ("zh-CN-YunjianNeural", "male", "older adult"),
    "采买妇人": ("zh-CN-XiaoxiaoNeural", "female", "adult"),
    "装卸伙计": ("zh-CN-YunxiNeural", "male", "young adult"),
    "货担主人": ("zh-CN-YunyangNeural", "male", "adult"),
    "冷孤云": ("zh-CN-YunxiNeural", "male", "young adult"),
    "刑樊天": ("zh-CN-YunjianNeural", "male", "older adult"),
    "杜青衫": ("zh-CN-YunjianNeural", "male", "adult"),
    "沈半盏": ("zh-CN-YunjianNeural", "male", "older adult"),
    "唐行舟": ("zh-CN-YunxiNeural", "male", "young adult"),
    "悦无姮": ("zh-CN-XiaoxiaoNeural", "female", "young adult"),
    "赵思颖": ("zh-CN-XiaoxiaoNeural", "female", "young adult"),
    "沈青禾": ("zh-CN-XiaoyiNeural", "female", "young adult"),
    "晒药婆婆": ("zh-CN-XiaoyiNeural", "female", "older adult"),
    "采药村妇": ("zh-CN-XiaoyiNeural", "female", "adult"),
    "卖菜大婶": ("zh-CN-XiaoyiNeural", "female", "adult"),
    "诗会执事": ("zh-CN-YunyangNeural", "male", "adult"),
    "护商镖师": ("zh-CN-YunjianNeural", "male", "adult"),
    "赵无忌": ("zh-CN-YunjianNeural", "male", "adult"),
    "店小二": ("zh-CN-YunxiNeural", "male", "young adult"),
    "客栈老板": ("zh-CN-YunjianNeural", "male", "adult"),
}


def bound(row):
    p = ROOT / row["dialog_path"]
    if sha(p) != row["dialog_sha256"]:
        raise ValueError("Authored source changed")
    matches = [n for n in nodes(p) if n["node_id"] == row["node_id"]]
    if len(matches) != 1 or any(matches[0][k] != row[k] for k in ("speaker", "text", "dialog_id")):
        raise ValueError("Authored line mismatch")


def make_plan():
    # Start with actual resident everyday dialogue, then city/main plot and
    # existing named villagers. Missing voice clips get priority over old audio.
    paths = sorted((ROOT / 'game/data/dialogs').glob('ch4_resident_v_*.tres'))
    paths += sorted((ROOT / 'game/data/dialogs').glob('ch4_*.tres'))
    paths += sorted((ROOT / 'game/data/dialogs').glob('linxi_*.tres'))
    paths += sorted((ROOT / 'game/data/dialogs').glob('ch6_*.tres'))
    paths += sorted((ROOT / 'game/data/dialogs').glob('ch2_*.tres'))
    paths += sorted((ROOT / 'game/data/dialogs').glob('ch1_*.tres'))
    rows, seen = [], set()
    for p in dict.fromkeys(paths):
        for n in nodes(p):
            key = (n['dialog_id'], n['node_id'])
            txt = spoken(n['text'])
            if key in seen or n['speaker'] not in PROFILES or not 4 <= len(txt) <= 160:
                continue
            seen.add(key)
            voice, gender, age = PROFILES[n['speaker']]
            safe = n['speaker'].replace('/', '_').replace('\\', '_')
            folder = ROOT/'game/art/audio/voices'/n['dialog_id'][:3]/n['dialog_id']
            covered = any(folder.glob(f'{safe}_{n["node_id"]}*.mp3'))
            n.update(spoken_text=txt, voice=voice, character_gender=gender, character_age=age,
                     age_note='Character casting intent; provider voices are not claimed to be age-specific actors.',
                     rate='+0%', pitch='+0Hz', volume='+0%', existing_clip_present=covered,
                     id=f'{n["dialog_id"]}__{n["node_id"]}')
            rows.append(n)
    missing = [n for n in rows if not n['existing_clip_present']]
    # Bound the workload; retain all resident lines then balance named actors.
    chosen, counts = [], {}
    for n in missing:
        if counts.get(n['speaker'], 0) >= 14:
            continue
        chosen.append(n); counts[n['speaker']] = counts.get(n['speaker'], 0) + 1
        if len(chosen) == 96:
            break
    if len(chosen) < 60:
        raise ValueError('Insufficient source-bound missing lines')
    doc = {'status':'CANDIDATE_NOT_APPLIED', 'provider':'edge_tts_7.3.1',
           'source_text_policy':'Original TRES speaker/text immutable; markup and parenthetical stage directions excluded only from spoken_text.',
           'existing_voice_mp3_files':len(list((ROOT/'game/art/audio/voices').rglob('*.mp3'))),
           'eligible_missing_lines':len(missing), 'line_count':len(chosen), 'speakers':counts,
           'distinct_base_voice_ids':sorted(set(n['voice'] for n in chosen)),
           'voices_shared_by_characters_honestly':True, 'character_profiles':PROFILES,
           'game_integration':'NONE', 'lines':chosen}
    write_new(OUT/'voice_plan.json',doc)
    return doc


def decode(p):
    resampler = av.AudioResampler(format='fltp', layout='mono', rate=24000)
    chunks=[]
    with av.open(str(p)) as container:
        for frame in container.decode(audio=0):
            for out in resampler.resample(frame): chunks.append(out.to_ndarray()[0])
        for out in resampler.resample(None): chunks.append(out.to_ndarray()[0])
    x=np.concatenate(chunks)
    return {'sample_rate':24000, 'decoded_frames':len(x), 'seconds':len(x)/24000,
            'peak':float(np.abs(x).max()),'rms':float(np.sqrt(np.mean(x*x))),
            'finite':bool(np.isfinite(x).all()), 'decoded_samples_above_unity':int((np.abs(x)>1).sum())}


async def synthesize(rows, label):
    destination=OUT/label; destination.mkdir(parents=True,exist_ok=True)
    results=[]; failures=0
    for row in rows:
        bound(row)
        target=destination/(row['id']+'.mp3')
        meta=destination/(row['id']+'.json')
        if target.exists() or meta.exists(): raise FileExistsError('Prior attempt preserved')
        start=time.monotonic()
        result={'line':row,'provider':'edge_tts','version':edge_tts.__version__,
                'module_path':str(Path(edge_tts.__file__).relative_to(ROOT)),
                'status':'RUNNING','automatic_application':'NONE','attempts':1,
                'script_sha256':sha(Path(__file__))}
        try:
            comm=edge_tts.Communicate(row['spoken_text'],row['voice'],rate=row['rate'],pitch=row['pitch'],volume=row['volume'],connect_timeout=10,receive_timeout=18)
            await asyncio.wait_for(comm.save(str(target)),timeout=30)
            info=decode(target)
            if not info['finite'] or info['seconds']<0.3 or info['rms']<0.0001:
                raise ValueError('Empty or silent synthesis')
            result.update(status='GENERATED_LISTENING_PENDING',audio_path=target.relative_to(ROOT).as_posix(),audio_sha256=sha(target),decode=info)
        except Exception as e:
            # Never print a handshake URL: it can contain service tokens.
            result.update(status='FAILED',error_type=type(e).__name__,http_status=getattr(e,'status',None))
            failures+=1
        result['elapsed_seconds']=time.monotonic()-start
        write_new(meta,result); results.append(result)
        print(json.dumps({'id':row['id'],'status':result['status'],'error':result.get('error_type'),'seconds':result.get('decode',{}).get('seconds')},ensure_ascii=True),flush=True)
        if failures>=2: break
    write_new(destination/'result.json',{'rows':results,'requested':len(rows),'generated':sum(r['status'].startswith('GENERATED') for r in results),'failures':failures,'route_stopped_after_two_failures':failures>=2})


def main():
    ap=argparse.ArgumentParser();ap.add_argument('--mode',choices=['plan','probe','batch'],required=True);a=ap.parse_args()
    if a.mode=='plan': make_plan();return
    plan=json.loads((OUT/'voice_plan.json').read_text(encoding='utf-8'))
    if a.mode=='probe':
        selected=[]
        for name in ['采买妇人','装卸伙计','老纸匠']:
            selected.append(next(n for n in plan['lines'] if n['speaker']==name))
        asyncio.run(synthesize(selected,'edge_probe'))
    else:
        probe=json.loads((OUT/'edge_probe/result.json').read_text(encoding='utf-8'))
        if probe['generated']!=3 or probe['failures']:raise ValueError('First validate three real distinct provider voice samples')
        asyncio.run(synthesize(plan['lines'],'voices_edge'))


if __name__=='__main__':
    if sys.platform == 'win32':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    main()
