"""Preserve first offset guard failure; exact return branch uses CRLF."""
from pathlib import Path
path=Path(__file__).with_name('finalize_resident_reverse_actual04.py')
code=path.read_text(encoding='utf-8')
for old,new in [
 ("OUT=ROOT/'exact_market_artisan_resident_candidate04'","OUT=ROOT/'exact_market_artisan_resident_candidate04_retry1'"),
 ('assert old.count(before)==1','before=before.replace(b"\\n",b"\\r\\n")\nafter=after.replace(b"\\n",b"\\r\\n")\nassert old.count(before)==1'),
]:
 assert code.count(old)==1
 code=code.replace(old,new)
exec(compile(code,str(path),'exec'),{'__file__':str(path),'__name__':'__main__'})
