"""Mechanical exact candidate/instrumentation derivation; no formal writes/engine."""
from pathlib import Path
import hashlib, json, re

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[2]
OUT=BASE/'keepalive01'
OUT.mkdir(exist_ok=True)
HOME='res://build/loading_20261106_system03/keepalive01/'
sha=lambda b:hashlib.sha256(b).hexdigest()
read=lambda p:(ROOT/('game/'+p[6:])).read_bytes()
prior=json.loads((BASE/'instrumentation_receipt.json').read_text('utf-8'))
scripts=prior['scripts']
helper=scripts[0]['suffix']
router=next(s for s in scripts if s['group']=='router')
raw=read(router['formal_path'])
assert sha(raw)==router['formal_sha256']
old=raw.decode('utf-8')
start=old.index('\t# Exact original Family direct-entry lifecycle.')
end=old.index('\n\n',start)
before=old[start:end]
newline='\r\n' if '\r\n' in before else '\n'
after=before.replace('\tif scene_id in AP_QUARTERS.IDS:', '\tvar direct_quarter_keepalive: SceneScript = null'+newline+'\tif scene_id in AP_QUARTERS.IDS:',1)
after=after.replace('var direct_quarter: SceneScript=', 'direct_quarter_keepalive=')
after=after.replace('direct_quarter==null or not direct_quarter.is_walkable','direct_quarter_keepalive==null or not direct_quarter_keepalive.is_walkable')
after=after.replace('\treturn _go_field_smart_prepared(scene_id,player_spawn,pending_action,spawn_version,local_spawn_version)', '\tvar direct_accepted: bool = _go_field_smart_prepared(scene_id,player_spawn,pending_action,spawn_version,local_spawn_version)'+newline+'\tdirect_quarter_keepalive = null'+newline+'\treturn direct_accepted')
assert before!=after
candidate=old[:start]+after+old[end:]
assert candidate.replace(after,before,1).encode()==raw
(OUT/'router_candidate.gd.txt').write_bytes(candidate.encode())
exact={'formal_path':router['formal_path'],'old_sha256':sha(raw),'candidate_sha256':sha(candidate.encode()),'before':before,'after':after,'whole_byte_inverse':True,'formal_write_set':[]}
(OUT/'optimization_exact_hunk.json').write_text(json.dumps(exact,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

# Preserve the earlier timers, replacing only the candidate body hunk.
for spec in scripts:
    content=read(spec['candidate_path']).decode('utf-8')
    assert sha(content.encode())==spec['candidate_sha256']
    spec['optimization_changes']=[]
    if spec['group']=='router':
        assert content.count(before)==1
        content=content.replace(before,after,1)
        spec['optimization_changes']=[{'before':before,'after':after}]
    target=OUT/(spec['group']+'_instrumented.gd.txt')
    target.write_bytes(content.encode())
    spec['candidate_path']=HOME+target.name
    spec['candidate_sha256']=sha(target.read_bytes())

# Account for the previously uninstrumented real boundary work, unchanged logic.
extra={
 'geometry':('res://build/city_navigation_20261101d_candidate01/navigation_geometry.gd',['live','safe_segment']),
 'region_session':('res://build/luoyang_regions_20261027d_source01/region_session.gd',['revalidate_boundary','content_matches']),
 'region_compiler':('res://build/luoyang_regions_20261027d_source01/region_compiler.gd',['source_pass'])}
for group,(path,names) in extra.items():
    original=read(path); content=original.decode('utf-8'); changes=[]
    for name in names:
        matches=list(re.finditer(r'^(static )?func '+name+r'\(([^\r\n]*)\) -> ([A-Za-z0-9_\[\]]+):\r?$',content,re.M))
        assert len(matches)==1,(group,name)
        m=matches[0]; decl=m.group(0); args=m.group(2); typ=m.group(3)
        argnames=[a.split(':')[0].strip() for a in args.split(',')] if args else []
        assert all(re.fullmatch('[a-zA-Z_][a-zA-Z0-9_]*',a) for a in argnames)
        wrapper=decl.rstrip('\r')+'\n\tvar trace03_token: Array=_trace03_begin()\n'
        wrapper+='\tvar trace03_result: '+typ+'=_trace03_original_'+name+'('+','.join(argnames)+')\n'
        wrapper+='\t_trace03_end(trace03_token,"'+group+'.'+name+'")\n\treturn trace03_result\n\n'
        wrapper+=decl.replace('func '+name+'(','func _trace03_original_'+name+'(',1)
        content=content[:m.start()]+wrapper+content[m.end():]
        changes.append({'before':decl,'after':wrapper})
    content+=helper
    inverse=content[:-len(helper)]
    for c in reversed(changes):inverse=inverse.replace(c['after'],c['before'],1)
    assert inverse.encode()==original
    target=OUT/(group+'_instrumented.gd.txt');target.write_bytes(content.encode())
    scripts.append({'group':group,'formal_path':path,'formal_sha256':sha(original),'candidate_path':HOME+target.name,'candidate_sha256':sha(content.encode()),'changes':changes,'suffix':helper,'optimization_changes':[],'exact_byte_inverse':True})
(OUT/'instrumentation_receipt.json').write_text(json.dumps(prior,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

probe=(BASE/'same_window_probe.gd').read_text('utf-8').replace('const HOME := "res://build/loading_20261106_system03/"','const HOME := "'+HOME+'"')
probe=probe.replace('\t\tvar inverse:=code', '\t\tvar inverse:=code\n\t\tvar opt: Array=spec.get("optimization_changes",[]).duplicate();opt.reverse()\n\t\tfor change: Dictionary in opt: inverse=inverse.replace(change.after,change.before)')
probe=probe.replace('"family._finish25i_ensure"]:', '"family._finish25i_ensure","geometry.live","geometry.safe_segment","region_session.revalidate_boundary","region_compiler.source_pass"]:')
probe=probe.replace('ONE_SAME_WINDOW_MEMORY_INSTRUMENTED_SPACE_PAIR_DIAGNOSTIC_NOT_FORMAL_ADMISSION_OR_FUNCTIONAL_PASS','ONE_MEMORY_KEEPALIVE_CANDIDATE_PAIR_NOT_FORMAL_ADMISSION')
probe=probe.replace('\tresult["trace_dropped"]', '\tresult["optimization_scope"]="Strong reference only inside one go_field_smart synchronous dispatch. No cross-request cache; original FIRST/FINAL fresh reads and mutable comparisons unchanged."\n\tresult["baseline_result"]="res://build/loading_20261106_system03/actual/23720/result.json"\n\tresult["trace_dropped"]')
(OUT/'same_pair_probe.gd').write_text(probe,encoding='utf-8')
protected=json.loads((BASE/'plan.json').read_text('utf-8'))['protected_formal_sha256']
for _,(path,_) in extra.items():protected[path]=sha(read(path))
plan={'status':'READY_FOR_ROOT_NOT_RUN','formal_write_set':[],'candidate_source_change':[router['formal_path']],'protected_formal_sha256':protected,'memory_scripts':len(scripts),'baseline':'actual/23720/result.json','expected_boundary':'Only eliminate repeated cold ensures inside synchronous request; Field later may still rebuild. Approx 0.73 seconds observed repeat work is a hypothesis not a measured saving.','extra_timers':'geometry.live/safe_segment and region_session content/revalidate plus Compiler.source_pass; all exact inverse timers; no boundary validation skipped.','future_admission':'Requires separate formal source closure and true residual travel; memory candidate is not formal acceptance.'}
(OUT/'plan.json').write_text(json.dumps(plan,indent=2)+'\n',encoding='utf-8')
files=[p.name for p in OUT.iterdir() if p.is_file() and p.name!='source_inventory.json']
inventory={'source_paths':list(protected)+[HOME+p for p in files]+['res://build/loading_20261106_system03/prepare_keepalive.py']}
(OUT/'source_inventory.json').write_text(json.dumps(inventory,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'memory_scripts':len(scripts),'candidate_hunks':1,'formal_writes':0,'protected_formal':len(protected)}))
