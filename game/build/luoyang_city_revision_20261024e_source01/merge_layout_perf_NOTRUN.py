"""NOTRUN merger: Source owns final C/Field composition, never canonical writes.

Run only after Root has approved immutable System functional parents. Arguments
are explicit candidate path/SHA (not observed canonical hashes). Output must be a
NEW BUILD directory; final Stage is still separate Root authority.
"""
import argparse,hashlib,json
from pathlib import Path

GAME=Path(__file__).resolve().parents[2]
BASE=Path(__file__).resolve().parent
PERF=GAME/'build/luoyang_loading_20261024e_perf01/candidate01/whole_byte_delta_NOTRUN.json'
PERF_SHA='aeade5251bd64167779f1e925ef2f4f0b7805d68231800ee7e6df028819767ea'
def sha(data):return hashlib.sha256(data).hexdigest()
def read(path,h):
    data=path.read_bytes();assert sha(data)==h,(path,'FIXED_SNAPSHOT_REQUIRED');return data
def func(data,name):
    text=data.decode('utf8');lines=text.splitlines(keepends=True)
    start=next(i for i,line in enumerate(lines) if line.startswith('static func '+name+'('))
    end=next((i for i in range(start+1,len(lines)) if lines[i].startswith('static func ')),len(lines))
    return ''.join(lines[start:end]).encode('utf8')
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--C-path',required=True,type=Path);parser.add_argument('--C-sha',required=True)
    parser.add_argument('--Field-path',required=True,type=Path);parser.add_argument('--Field-sha',required=True)
    parser.add_argument('--output-name',required=True)
    args=parser.parse_args()
    assert args.output_name.isascii() and args.output_name.replace('_','').isalnum()
    out=BASE/args.output_name;assert not out.exists(),'PRESERVE_ALL_OLD_CANDIDATES'
    proof=json.loads(read(PERF,PERF_SHA));prepared=[]
    for short,entry,p,h in zip(['C','Field'],proof['entries'],[args.C_path,args.Field_path],[args.C_sha,args.Field_sha]):
        # Current formal is checked as an already declared fixed parent, never
        # used to supply unknown expected hashes or to overwrite production.
        original=read(Path(entry['parent']),entry['parent_sha256'])
        functional=read(p,h);assert b'tokens truncated' not in functional
        merged=functional
        for op in entry['operations']:
            before=op['old'].encode('utf8');after=op['new'].encode('utf8')
            assert merged.count(before)==1,(short,op['label'],'ANCHOR_CONFLICT_NEEDS_EXPLICIT_MERGE')
            merged=merged.replace(before,after,1)
        inverse=merged
        for op in reversed(entry['operations']):
            before=op['old'].encode('utf8');after=op['new'].encode('utf8')
            assert inverse.count(after)==1,(short,op['label'],'INVERSE_ANCHOR_AMBIGUITY')
            inverse=inverse.replace(after,before,1)
        assert inverse==functional
        if short=='C':
            for name in proof['original_final_fresh_functions_whole_text_same']:
                assert func(original,name)==func(functional,name)==func(merged,name),(name,'FINAL_FUNCTION_MUST_REMAIN_WHOLE_BYTE_SAME')
        assert merged.endswith(b'\n')==functional.endswith(b'\n')
        prepared.append((short,merged,dict(target=entry['target'],functional_parent=dict(path=p.as_posix(),sha256=h),formal_parent_sha256=entry['parent_sha256'],candidate_sha256=sha(merged),bytes=len(merged),perf_operations=entry['operations'],whole_inverse_to_functional_parent=True)))
    # Only once every check has passed may the NEW build directory be created.
    out.mkdir()
    rows=[]
    for short,data,row in prepared:
        p=out/(short+'_layout_perf_CANDIDATE.gd');p.write_bytes(data)
        row['candidate_path']=p.as_posix();rows.append(row)
    result=dict(status='MERGED_CANDIDATE_NOT_PARSED_NOT_RUN_NOT_DEPLOYED',entries=rows,
        perf_source=dict(path=PERF.as_posix(),sha256=PERF_SHA),new_helper=proof['new_helper'],
        final_functions_whole_unchanged=proof['original_final_fresh_functions_whole_text_same'],
        source_classification='prewarm helper ordinary legacy only; no OWNED/runtime_authority expansion',
        functional_scope='No new layout implementation; only seven approved independent Perf C4/Field3 exact hunks applied to fixed System candidates.',
        engine_runs=0,collector_calls=0,canonical_writes=0)
    p=out/'merge_whole_inverse_NOTRUN.json';p.write_bytes((json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode('utf8'))
    print(json.dumps(dict(path=p.as_posix(),sha256=sha(p.read_bytes()),candidates=[dict(path=r['candidate_path'],sha256=r['candidate_sha256']) for r in rows])))
if __name__=='__main__':main()
