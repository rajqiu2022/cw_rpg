"""Only fixed deployed Stage516C target declarations; no canonical source fill."""
from pathlib import Path
import json
import hashlib
HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
S='res://build/luoyang_city_space_20261024b_source01/'
path=S+'outputs/root_market_dialogue_exact36_stage02/receipt.json'
raw=(GAME/path[6:]).read_bytes()
assert hashlib.sha256(raw).hexdigest()=='516c535b908d5fb22d8620311431e2c1e8a13d01b4f0289d7d81732f4aeefd8c'
stage=json.loads(raw)
rows=[dict(target=r['target'],old_sha256=r['candidate_sha256'],old_declaration_path=path,old_declaration_pointer=['targets',i,'candidate_sha256'])
      for i,r in enumerate(stage['targets']) if r['target']!='res://scripts/ui/dialog_box.gd']
assert len(rows)==35 and sum(r['target'].endswith('.gd') for r in rows)==20
out=dict(status='EXACT35_WORKER_ARTIFACT_FACTS_PREPARATION_NOT_STAGE',ready=False,
         parent_stage=dict(path=path,sha256=hashlib.sha256(raw).hexdigest()),target_count=35,targets=rows,
         partition=dict(strict_apply_patch_GD=20,exact_copy_JSON=15),
         only_function_change='runtime.effective_domain adds the four exact binding.artifacts rows to same-token expected source facts; no inverse bypass',
         unchanged=['UI FE816','binding003EC','all native artifacts and raw authors','walk/media bytes','DP/dialogue/task behavior','Family','portal'],
         dependent_literal_only=['adapter self/runtime pin','B/C/DT/Fade adapter and direct runtime pins','G/Field/ENV/ground runtime pin','ordinary AA/AC exact byte proofs','culture C/Field SHA','Coordinator contract SHA','Temple binding four values'],
         active_owned_members=10,changed_existing_owned=7,prior_proof_sources=118,new_proof_sources=127,
         source_collector_calls=0,engine_calls=0,canonical_writes=0)
data=(json.dumps(out,ensure_ascii=False,indent=2)+'\n').encode('utf8')
dest=HERE/'worker_facts35_scope_PREPARATION_NOT_STAGE.json'
with dest.open('xb') as stream:stream.write(data)
print(json.dumps(dict(path=S+dest.name,sha256=hashlib.sha256(data).hexdigest(),bytes=len(data),targets=35,GD=20,JSON=15)))
