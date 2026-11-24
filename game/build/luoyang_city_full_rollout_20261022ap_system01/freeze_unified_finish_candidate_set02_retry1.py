"""V2 fixed set reads the exact CRLF-preserving04 retry, preserves failed wrapper."""
from pathlib import Path
path=Path(__file__).with_name('freeze_unified_finish_candidate_set02.py')
code=path.read_text(encoding='utf-8')
assert code.count('exact_market_artisan_resident_candidate04')==3
code=code.replace('exact_market_artisan_resident_candidate04','exact_market_artisan_resident_candidate04_retry1')
exec(compile(code,str(path),'exec'),{'__file__':str(path),'__name__':'__main__'})
