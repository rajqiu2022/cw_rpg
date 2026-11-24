"""Preserve original finite static failure; separate retry only adds 10px bench gap."""
from pathlib import Path
import hashlib

root = Path(__file__).resolve().parent
original = root / 'build_yamen_waiting_cluster_epoch01.py'
before = original.read_bytes()
text = before.decode('utf-8')
changes = [
    ("OUT = ROOT / 'yamen_waiting_cluster_epoch01'", "OUT = ROOT / 'yamen_waiting_cluster_epoch01_retry1'"),
    ("bench,[1140,1170],.12", "bench,[1140,1160],.12"),
    ("留出120px排距", "留出130px排距"),
    ("helper=OUT/'pure_yamen_author_delta_candidate.gd'", "helper=ROOT/'yamen_waiting_cluster_epoch01/pure_yamen_author_delta_candidate.gd'"),
]
for old,new in changes:
    assert text.count(old)==1, old
    text=text.replace(old,new)
(root/'yamen_waiting_cluster_epoch01_retry1').mkdir(exist_ok=False)
exec(compile(text, str(original), 'exec'), {'__file__':str(original), '__name__':'__main__'})
assert original.read_bytes()==before
