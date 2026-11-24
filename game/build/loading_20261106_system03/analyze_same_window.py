"""Read a completed diagnostic result; only compute clipped interval unions.
No engine, no source edits, no save paths. Pass explicit result.json.
"""
import json, sys
from pathlib import Path
from collections import defaultdict

result=json.loads(Path(sys.argv[1]).read_text('utf-8'))
if result.get('diagnostic_completed') is not True:
    raise SystemExit('Refusing incomplete diagnostic: '+str(result.get('errors')))
frames=result['frames']
eligible=[i for i,f in enumerate(frames) if f['screen'] and i>0]
if not eligible:
    raise SystemExit('No complete Loading draw interval was recorded')
index=max(eligible,key=lambda i:frames[i]['gap_ms'])
lo,hi=frames[index-1]['usec'],frames[index]['usec']
def union(intervals):
    total=0; a=b=None
    for x,y in sorted(intervals):
        x=max(x,lo);y=min(y,hi)
        if x>=y:continue
        if b is None:a,b=x,y
        elif x<=b:b=max(b,y)
        else:total+=b-a;a,b=x,y
    return total+(b-a if b is not None else 0)
spans=result.get('absolute_spans',[])
groups=defaultdict(list)
for s in spans:groups[s['name']].append((s['start_us'],s['end_us']))
rows=[]
for name,intervals in groups.items():
    overlap=union(intervals)
    if overlap:rows.append({'name':name,'window_union_ms':overlap/1000,'calls_intersecting':sum(a<hi and b>lo for a,b in intervals)})
rows.sort(key=lambda r:-r['window_union_ms'])
ensure=[]
for call in result.get('same_pair_ensure_calls',[]):
    if call['start_us']>=hi or call['end_us']<=lo:continue
    ensure.append({'start_us':call['start_us'],'end_us':call['end_us'],'overlap_ms':union([(call['start_us'],call['end_us'])])/1000,
       'segments':[{'phase':s['phase'],'window_ms':union([(s['start_us'],s['end_us'])])/1000} for s in call['segments'] if s['start_us']<hi and s['end_us']>lo]})
outer=[(s['start_us'],s['end_us']) for s in spans if s.get('depth')==0]
print(json.dumps({'diagnostic_completed':result.get('diagnostic_completed'),
 'errors':result.get('errors'),'draw_window_us':[lo,hi],'draw_gap_ms':(hi-lo)/1000,
 'top_level_covered_ms':union(outer)/1000,'unattributed_outside_top_level_ms':(hi-lo-union(outer))/1000,
 'nested_spans_do_not_add':rows,'finish_ensure_same_window':ensure,
 'total_operable_ms':result.get('target_operable_ms'),'limits':'Single instrumented same-clock window; overlapping nested rows are not additive. No baseline causal speedup claim.'},indent=2))
