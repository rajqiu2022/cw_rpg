"""Explicit-list fresh pre/post guard. SHA/bytes/Windows .NET Exactticks; no engine.

PRE: fixed input source declarations + 5 world leaves + formal24c targets30 + saves15.
POST: only the exact PRE list; no enumeration/new baseline substitution.
System's still-written input/project/key is provenance, NOT protected canonical.
"""
import argparse,ctypes,hashlib,json,os,time
from ctypes import wintypes
from pathlib import Path
BASE=Path(__file__).resolve().parent;GAME=BASE.parents[1]
ROOT=GAME.parent
INPUT=GAME/'build/world_water_bridge_20261024d_system01/native_sample01/project/input_v1final_NOTREADY.json'
FORMAL=GAME/'build/luoyang_city_revision_20261024c_root01/deployment30_actual.json'
SAVE_BASE=GAME/'build/luoyang_city_revision_20261024c_root01/post_Field30_guard_actual.json'
def digest(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        while block:=f.read(1024*1024):h.update(block)
    return h.hexdigest()
def resolve(value):return GAME/value[6:] if value.startswith('res://') else Path(value)
class FT(ctypes.Structure):_fields_=[('low',wintypes.DWORD),('high',wintypes.DWORD)]
class ATTR(ctypes.Structure):
    _fields_=[('attributes',wintypes.DWORD),('creation',FT),('access',FT),('write',FT),('size_high',wintypes.DWORD),('size_low',wintypes.DWORD)]
GET=ctypes.WinDLL('kernel32',use_last_error=True).GetFileAttributesExW
GET.argtypes=[wintypes.LPCWSTR,ctypes.c_int,ctypes.POINTER(ATTR)];GET.restype=wintypes.BOOL
def stat(p):
    a=ATTR()
    if not GET(str(p),0,ctypes.byref(a)):
        err=ctypes.get_last_error()
        if err in (2,3):return dict(exists=False)
        raise OSError(err,str(p))
    assert not a.attributes&16,('not regular file',str(p))
    return dict(exists=True,bytes=(a.size_high<<32)|a.size_low,
        ticks=str(((a.write.high<<32)|a.write.low)+504911232000000000))
def fact(p):
    before=stat(p)
    if not before['exists']:return dict(path=str(p),**before)
    h=digest(p);after=stat(p)
    assert before==after,('changed during fresh read',str(p),before,after)
    return dict(path=str(p),sha256=h,**after)
def load(p):return json.loads(p.read_text(encoding='utf-8'))
def record_hash(p):return dict(path=str(p),sha256=digest(p))
def write(p,v):
    assert not p.exists(),p
    p.resolve().relative_to(BASE.resolve());p.parent.mkdir(parents=True,exist_ok=True)
    p.write_bytes((json.dumps(v,ensure_ascii=True,indent=2)+'\n').encode())
    print(json.dumps(dict(path=str(p),sha256=digest(p),passed=v['passed'],protected_count=len(v['facts']),unexpected_count=len(v['unexpected']),bytes_hashed=v['bytes_hashed'],elapsed_ms=v['elapsed_ms'])))
def main():
    ap=argparse.ArgumentParser();ap.add_argument('mode',choices=['pre','post']);ap.add_argument('--pre');ap.add_argument('--pre-sha');ap.add_argument('--out',required=True)
    args=ap.parse_args();began=time.perf_counter();out=Path(args.out)
    if args.mode=='pre':
        assert digest(FORMAL)=='bcac9111f4abd016b8eed497aa11ce03e221760870abfeb956839401afe2e291'
        assert digest(SAVE_BASE)=='55e0984464daf622a277192bc2dd5091dadd06ccc66db228d739f6ae3ff7a4b1'
        raw=INPUT.read_bytes();i=json.loads(raw);d=load(FORMAL);g=load(SAVE_BASE)
        assert d['passed'] is True and d['target_count']==30 and len(d['targets'])==30 and g['passed'] is True and len(g['saves'])==15
        paths={};origins={}
        def add(name,expected,origin):
            p=resolve(name).resolve();key=str(p).casefold()
            if key in paths:assert paths[key]['expected']==expected,(name,'conflicting fixed declarations')
            else:paths[key]=dict(path=str(p),expected=expected)
            origins.setdefault(key,[]).append(origin)
        for p,h in i['source_pins'].items():add(p,h,'System input source_pins')
        for role,row in i['new_art'].items():
            if isinstance(row,dict):add(row['path'],row['sha256'],'fixed v1 ART '+role)
        world={
          'res://data/maps/world_map_v15_complete_v9c_source.json':'85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f',
          'res://art/maps/world_map_v15_complete_v9c/art_contract.json':'1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a',
          'res://art/maps/world_map_v15_complete_v9c/entities/bridge_01_deck.png':'7f7160b1ea4eb0708b69a0da6b3ee8bd806f603ecc8e88311f7ead7644d21360',
          'res://art/maps/world_map_v15_complete_v9c/chunks/r1_c2_visual.png':'22390cbb28822f88d6e99d89fa6898d4fa9bff8c74c9d35329adcb29b5c3d636',
          'res://art/maps/world_map_v15_complete_v9c/chunks/r1_c2_walk.png':'aaf895f93d8ebcf04042dec2961ddbe7b6efd12520d6b55278604fe513d8dad0'}
        for p,h in world.items():add(p,h,'formal world exact leaf')
        for row in d['targets']:
            assert row['actual_sha256']==row['candidate_sha256']
            add(row['target'],row['actual_sha256'],'formal24c30 deployment')
        old_save={}
        for row in g['saves']:
            add(row['path'],row.get('sha256','ABSENT'),'save15 latest24c path; must freshly read')
            old_save[str(Path(row['path']).resolve()).casefold()]=row
        # Do not freeze mutable System work files in canonical/source guard.
        mutable=GAME/'build/world_water_bridge_20261024d_system01/native_sample01/project'
        assert not any(Path(row['path']).is_relative_to(mutable.resolve()) for row in paths.values())
        facts=[];unexpected=[];bytes_hashed=0
        for key,row in sorted(paths.items()):
            current=fact(Path(row['path']));current['origins']=origins[key];current['expected_sha256']=row['expected']
            observed=current.get('sha256','ABSENT')
            if observed!=row['expected']:unexpected.append(dict(path=row['path'],reason='declared SHA mismatch',expected=row['expected'],actual=observed))
            if key in old_save:
                prior=old_save[key]
                if any(current.get(k)!=prior.get(k) for k in ['exists','sha256','bytes','ticks']):unexpected.append(dict(path=row['path'],reason='save differs from latest24c guard; not silently authorized',old=prior,current=current))
            facts.append(current);bytes_hashed+=current.get('bytes',0)
        assert raw==INPUT.read_bytes(),'System input changed while deriving explicit list; retain fail/no baseline rewrite'
        report=dict(status='24D_FINITE_FRESH_PRE_GUARD_NO_ENGINE',passed=not unexpected,
            provenance=dict(input=dict(path=str(INPUT),sha256=hashlib.sha256(raw).hexdigest(),bytes=len(raw),protected_as_canonical=False),formal24c=record_hash(FORMAL),save_paths_only_basis=record_hash(SAVE_BASE)),
            declared_counts=dict(input_source_pins=len(i['source_pins']),fixed_new_art=2,formal_world=5,formal24c=30,saves=15),
            facts=facts,unexpected=unexpected,bytes_hashed=bytes_hashed,Exactticks_method='Win32 GetFileAttributesExW FILETIME lastwrite +504911232000000000 as decimal string; stable SHA read bracketed by size/ticks check',
            limitations=['No fullrepo or collector. These111 explicitly requested paths only; no autoload/game/import execution.',
                'No mutable System renderer/shader/project/input key is frozen as canonical. New output PNGs are not part of immutable sources.',
                'No seamless certification of v1; seamFAIL v2 is not included. No actual sample renderer or ART pass yet.'])
    else:
        assert args.pre and args.pre_sha,'post requires exact pre file+SHA'
        pre=Path(args.pre);assert digest(pre)==args.pre_sha.lower()
        previous=load(pre);assert previous['passed'] is True
        facts=[];unexpected=[];bytes_hashed=0
        for before in previous['facts']:
            current=fact(Path(before['path']));current['origins']=before['origins'];current['expected_sha256']=before['expected_sha256']
            if current!=before:unexpected.append(dict(path=before['path'],before=before,after=current))
            facts.append(current);bytes_hashed+=current.get('bytes',0)
        report=dict(status='24D_FINITE_FRESH_POST_GUARD_NO_ENGINE',passed=not unexpected,pre=dict(path=str(pre),sha256=args.pre_sha.lower()),facts=facts,unexpected=unexpected,bytes_hashed=bytes_hashed,Exactticks_method=previous['Exactticks_method'],no_source_list_expansion=True)
    report.update(elapsed_ms=round((time.perf_counter()-began)*1000),engine_calls=0,import_calls=0,collector_calls=0,production_writes=0,save_writes=0)
    write(out,report)

if __name__=='__main__':main()
