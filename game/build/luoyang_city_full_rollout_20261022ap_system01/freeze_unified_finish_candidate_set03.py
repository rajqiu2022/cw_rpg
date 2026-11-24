"""Final exact pair memory successor; previous unified sets remain immutable."""
from pathlib import Path
import json
path=Path(__file__).with_name('freeze_unified_finish_candidate_set01.py')
code=path.read_text(encoding='utf-8')
receipt=json.loads((path.parent/'exact_market_artisan_resident_candidate05/handoff_READY.json').read_text(encoding='utf-8'))
for old,new in [
 ('exact_market_artisan_resident_candidate03/Router_exact_market_artisan_resident_READY.gd','exact_market_artisan_resident_candidate05/Router_exact_market_artisan_resident_READY.gd'),
 ('9d80b90198fa4b0a3a78c1f81e44e46d06a8e97503819cb2b39895398aecd1e3',receipt['candidate']['sha256']),
 ("'exact_market_artisan_resident_candidate03/handoff_READY.json',","'exact_market_artisan_resident_candidate03/handoff_READY.json','exact_market_artisan_resident_candidate04_retry1/handoff_READY.json','exact_market_artisan_resident_candidate05/handoff_READY.json',"),
 ("'unified_runtime_visual_finish_candidates_READY.json'","'unified_runtime_visual_finish_candidates_v3_READY.json'"),
]:
 assert code.count(old)==1,(old,code.count(old))
 code=code.replace(old,new)
exec(compile(code,str(path),'exec'),{'__file__':str(path),'__name__':'__main__'})
