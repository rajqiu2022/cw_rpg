"""Root-approved projection of already freshly read111 facts; no source rehash."""
import copy,hashlib,json
from pathlib import Path
BASE=Path(__file__).resolve().parent
old=BASE/'pre_sample_guard_actual.json'
expected='c730e7210b17cf976c203ecb3c18b9771dc8bc6779ea109b0adee4267d41f2f3'
assert hashlib.sha256(old.read_bytes()).hexdigest()==expected
v=json.loads(old.read_text(encoding='utf-8'));assert v['passed'] is False and len(v['facts'])==111 and len(v['unexpected'])==4
changed={r['path'] for r in v['unexpected']}
assert len(changed)==2 and {Path(p).name for p in changed}=={'save_0.json','save_0.json.bak'}
observed={Path(f['path']).name:f for f in v['facts'] if f['path'] in changed}
assert observed['save_0.json']['sha256']=='a6d8add839c8b0ee941da7342f9fbc751f1c6e404366fd0c13ea5af55a1d879f'
assert observed['save_0.json']['bytes']==5404 and observed['save_0.json']['ticks']=='639284449295214475'
assert observed['save_0.json.bak']['sha256']=='ad19ec60728284dc5ba71f4408600634da4914c9ffb0629bd23f1b9320b10f1d'
assert observed['save_0.json.bak']['bytes']==5273 and observed['save_0.json.bak']['ticks']=='639284448871677337'
new=copy.deepcopy(v)
for fact in new['facts']:
    if fact['path'] in changed:fact['expected_sha256']=fact['sha256']
    else:assert fact.get('sha256','ABSENT')==fact['expected_sha256']
new.update(status='24D_FRESH_PRE_CURRENT_EPOCH_PREEXISTING_SAVE_DELTA_ACKNOWLEDGED',passed=True,unexpected=[],
    original_capture=dict(path=str(old),sha256=expected,passed=False,preserved_unchanged=True),
    prior_epoch_differences=v['unexpected'],
    Root_authority='Root explicitly acknowledges two pre-existing external save changes before this sample epoch; current fresh facts become the baseline. Do not restore saves or claim24c-to-now equality.',
    read_boundary='This document only projects the111 actual SHA/bytes/Exactticks collected in the original fresh pre. No390MB rehash or new sample/engine was run; post must freshly read the exact same111 paths.')
dest=BASE/'pre_sample_guard_current_epoch_READY.json';assert not dest.exists()
dest.write_bytes((json.dumps(new,ensure_ascii=True,indent=2)+'\n').encode())
print(json.dumps(dict(path=str(dest),sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),passed=True,count=len(new['facts']),source_rehash_bytes=0)))
