"""City owner has source tables, not native path fields; use fixed89216 path."""
import hashlib
from pathlib import Path
p=Path(__file__).with_name('prepare_yamen_performance03_fixture_READY.py');b=p.read_bytes()
assert hashlib.sha256(b).hexdigest()=='e3a58a7fe6c86ec9fe019070b86196307940e5ed92d42a227101ae6c4b3bcd51'
s=b.decode();needle="fixture={'status'"
assert s.count(needle)==1
root='res://build/luoyang_city_full_rollout_20261022ap_system01/finite_two_domain_publication_epoch05_bound01/output/yamen/'
insertion="native_root="+repr(root)+"\nassert native_root+'scene.res' in row['source_sha256'] and native_root+'layout.res' in row['source_sha256']\n"
s=s.replace(needle,insertion+needle,1)
assert s.count("row['scene_path']")==2 and s.count("row['layout_path']")==2
s=s.replace("row['scene_path']","native_root+'scene.res'").replace("row['layout_path']","native_root+'layout.res'")
exec(compile(s,str(p),'exec'),{'__file__':str(p),'__name__':'__qa_data_retry1__'})
