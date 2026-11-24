"""Correct only absent-fact representation in the saved observation; no rescan."""
from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent
def sha(b):return hashlib.sha256(b).hexdigest()
p=HERE/'fresh25i_protection_observation01.json';raw=p.read_bytes()
assert sha(raw)=='2c7902363158392f914e17d9b7e81af25a87ea79ae48825191784169f1634376'
out=json.loads(raw)
parent=HERE.parent/'luoyang_city_revision_20261025h_source01/guard_service_garden28_after_Field_READONLY.json'
oldraw=parent.read_bytes();assert sha(oldraw)==out['parent_guard']['sha256']
old=json.loads(oldraw)
differences={}
for group,rows in out['groups'].items():
    changes=[]
    for expected,observed in zip(old[group],rows):
        assert expected['path']==observed['path']
        if not expected['exists'] and not observed['exists']:continue
        fields={k:{'old':expected.get(k),'observed':observed.get(k)} for k in ['exists','sha256','bytes','ticks'] if expected.get(k)!=observed.get(k)}
        if fields:changes.append({'path':observed['path'],'changes':fields,'action':'KEEP_CURRENT_NO_ROLLBACK; not a gameplay expected value'})
    differences[group]=changes
out['differences_from25h']=differences
out['mechanical_absence_representation_correction']={'original_observation_path':'res://build/luoyang_city_finish_20261025i_source01/'+p.name,'original_sha256':sha(raw),'scope':'Only old exists=false/new exists=false represent the same absent file; no expected/live gameplay normalization','new_file_hash_reads':0,'no_second_observation_or_timestamp_claim':True}
q=HERE/'fresh25i_protection_observation02.json';data=(json.dumps(out,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
with q.open('xb') as stream:stream.write(data)
print(json.dumps({'path':'res://build/luoyang_city_finish_20261025i_source01/'+q.name,'sha256':sha(data),'difference_counts':{k:len(v) for k,v in differences.items()}},ensure_ascii=False))
