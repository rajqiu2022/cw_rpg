"""Preserve first reader FAIL; distinguish column exit from old desk/screen hits."""
from pathlib import Path
import hashlib
p=Path(__file__).with_name('review_ActorLayer_suffix98132_actual_readonly.py')
assert hashlib.sha256(p.read_bytes()).hexdigest()=='ab59461dac7d2a45b8380404562e2482396730a6870f7b28c609aff660930797'
source=p.read_text(encoding='utf-8')
old="assert all(not r['active'] and not r['ghost_visible'] and not r['ghost_material'] for r in summary[1:])"
new="""assert summary[1]['all_prop_hits']=={'official_hall_document_desk':276,'official_hall_rear_screen':64}
assert summary[1]['active'] and summary[1]['ghost_visible'] and summary[1]['ghost_material']
assert summary[2]['all_prop_hits']=={} and not summary[2]['active'] and not summary[2]['ghost_visible'] and not summary[2]['ghost_material']"""
assert source.count(old)==1
source=source.replace(old,new,1)
needle=" 'preserved_failures':['91184_2821 wholeFAIL RGB helper precondition','124716_2789 wholeFAIL wrong QA camera predicate plus invalid production shared-parent snapshot'],"
replacement=needle+"\n 'first_readonly_reader_FAIL_preserved':'Original readerAB5946 incorrectly assumed both column-clear endpoints must have globalghostfalse; it emitted no review. This wrapper only distinguishes actual right endpoint olddesk276/screen64 ghost from column0 exit, and left endpoint fullyclear. Actual/key/fixture/production unchanged.',"
assert source.count(needle)==1
source=source.replace(needle,replacement,1)
exec(compile(source,str(p)+'::retry1_exact2replacements','exec'))
