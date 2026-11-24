"""Collect every remaining independent parse error; never break on a bad script."""
from pathlib import Path
import json,hashlib,argparse
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261024e_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--runtime-path',required=True);ap.add_argument('--runtime-sha',required=True);args=ap.parse_args()
    raw=(HERE/'parse14_ROOTONLY/input_ROOT_REVIEW.json').read_bytes();assert sha(raw)=='f73f66c9f961149ea298093b86dc088a3a3dc8547c290588677bbb8fe67d6b59';spec=json.loads(raw)
    actualpath=S+'parse_residual10_ROOTONLY/output/11904/result.json';actualraw=(GAME/actualpath[6:]).read_bytes();actual=json.loads(actualraw)
    assert len(actual['rows'])==7 and sum(r['can_instantiate'] is True for r in actual['rows'])==6 and actual['rows'][-1]['can_instantiate'] is False
    rest=[dict(path=args.runtime_path,sha256=args.runtime_sha.lower())]+spec['scripts'][-3:]
    assert len(rest)==len({r['path'] for r in rest})==4
    for r in rest:assert sha((GAME/r['path'][6:]).read_bytes())==r['sha256']
    out=HERE/'parse_collect_remaining4_ROOTONLY';assert not out.exists();prefix=S+'parse_collect_remaining4_ROOTONLY/';inp=prefix+'input_ROOT_REVIEW.json'
    spec.update(scripts=rest,output_prefix=prefix+'output/',status='REMAINING_FOUR_INDEPENDENT_COLLECT_ALL_PARSE_ERRORS_NOT_RUN',inherited_source_actual=dict(path=actualpath,sha256=sha(actualraw),passed_rows=[r for r in actual['rows'] if r['can_instantiate'] is True]))
    raw=(json.dumps(spec,ensure_ascii=False,indent=2)+'\n').encode();template=(HERE/'parse_all_changed_template_NOTREADY.gd').read_bytes();assert sha(template)=='987352e63aba56751bce6c644753ea3ffe2be07437149a40acc3776df2fd3f9d';text=template.decode();ops=[]
    changes=[('const READY=false','const READY=true'),('PENDING_FINAL_PARSE_INPUT_SHA',sha(raw)),('PENDING_FINAL_PARSE_INPUT',inp),('if not check(before[row.path].get("sha256")==row.sha256,"Candidate exact SHA before load:"+row.path): break','if not check(before[row.path].get("sha256")==row.sha256,"Candidate exact SHA before load:"+row.path): continue'),('if not check(load_ok and instantiable,"Load and can_instantiate only:"+row.path): break','check(load_ok and instantiable,"Load and can_instantiate only:"+row.path)')]
    for a,b in changes:assert text.count(a)==1;text=text.replace(a,b,1);ops.append(dict(old=a,new=b))
    key=text.encode();v=text
    for r in reversed(ops):assert v.count(r['new'])==1;v=v.replace(r['new'],r['old'],1)
    assert v.encode()==template and b': break' not in key
    out.mkdir()
    for name,b in [('input_ROOT_REVIEW.json',raw),('parse_ROOT_REVIEW.gd',key)]:
        with (out/name).open('xb') as stream:stream.write(b)
    report=dict(status='COLLECT_REMAINING_FOUR_PARSE_ROOT_ONLY_NOT_RUN',input=dict(path=inp,sha256=sha(raw)),key=dict(path=prefix+'parse_ROOT_REVIEW.gd',sha256=sha(key)),template_sha256=sha(template),replacements=ops,wholebyte_inverse=True,no_parse_success_invented=True,engine_calls=0,all_prior_FAIL_preserved=True)
    b=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode()
    with (out/'handoff_NOTRUN.json').open('xb') as stream:stream.write(b)
    print(json.dumps(dict(handoff=prefix+'handoff_NOTRUN.json',sha256=sha(b),input=report['input'],key=report['key'])))
if __name__=='__main__':main()
