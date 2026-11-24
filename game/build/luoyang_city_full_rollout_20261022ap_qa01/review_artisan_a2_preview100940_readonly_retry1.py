"""NEW only fixes the reviewer's mistranscribed Root authority SHA; old retained."""
from pathlib import Path
QA=Path(__file__).resolve().parent
P=QA/'review_artisan_a2_preview100940_readonly.py'
s=P.read_text(encoding='utf-8')
a='eaab96070310ea773dfce3aeac212c2d29bc1f8c48d089623c74488b793e7b14'
b='eaab9607b0d325d9554a1e6d7a92559230fd58779a201f883393d7f649fb8135'
assert s.count(a)==1
s=s.replace(a,b).replace('artisan_a2_preview100940_independent_readonly_review_READY.json','artisan_a2_preview100940_retry1_independent_readonly_review_READY.json')
exec(compile(s,str(P),'exec'),{'__file__':str(P),'__name__':'retry1_readonly'})
