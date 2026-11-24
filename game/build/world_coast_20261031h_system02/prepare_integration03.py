"""NEW Scene03 packaging integration copies; preserves all01/02 candidates."""
from __future__ import annotations
import hashlib,importlib.util,json
from pathlib import Path

OWN=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('coast_integration02_functions',OWN/'prepare_integration02.py')
parent=importlib.util.module_from_spec(spec);spec.loader.exec_module(parent)
module=parent.module
module.OUT=OWN/'prepared03'
module.DISPATCH='res://build/world_coast_20261031h_system02/world_contract_dispatch03.gd'

def preserved():
    roots=[OWN/'prepared',OWN/'prepared02']
    paths=[p for root in roots for p in root.rglob('*') if p.is_file()]
    paths.extend([OWN/'world_v16_contract02.gd',OWN/'world_contract_dispatch02.gd'])
    return {str(p.relative_to(OWN)):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}

if __name__=='__main__':
    before=preserved()
    module.prepare()
    assert preserved()==before,'PRESERVED01_OR02_BYTES_CHANGED'
    print(json.dumps({'status':'PREPARED03_ONLY_NOT_ADOPTED','preserved01_02_files':len(before),'manifest03_root_pin':'EMPTY_DENY_UNTIL_ROOT_REVIEWS_THIN_SCENE'}))

