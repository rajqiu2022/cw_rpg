"""One final frozen set; preserve prior E544 and add Root-approved actual-foot guard."""
from pathlib import Path
path=Path(__file__).with_name('freeze_unified_finish_candidate_set01.py')
code=path.read_text(encoding='utf-8')
changes=[
 ('exact_market_artisan_resident_candidate03/Router_exact_market_artisan_resident_READY.gd','exact_market_artisan_resident_candidate04/Router_exact_market_artisan_resident_READY.gd'),
 ('9d80b90198fa4b0a3a78c1f81e44e46d06a8e97503819cb2b39895398aecd1e3','ROUTER_FINAL_SHA'),
 ("'exact_market_artisan_resident_candidate03/handoff_READY.json',","'exact_market_artisan_resident_candidate03/handoff_READY.json','exact_market_artisan_resident_candidate04/handoff_READY.json',"),
 ("'unified_runtime_visual_finish_candidates_READY.json'","'unified_runtime_visual_finish_candidates_v2_READY.json'"),
]
import json
receipt=json.loads((path.parent/'exact_market_artisan_resident_candidate04/handoff_READY.json').read_text(encoding='utf-8'))
for old,new in changes:
 assert code.count(old)==1,(old,code.count(old))
 code=code.replace(old,new.replace('ROUTER_FINAL_SHA',receipt['candidate']['sha256']))
exec(compile(code,str(path),'exec'),{'__file__':str(path),'__name__':'__main__'})
