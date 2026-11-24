"""Root selected Perf03 recipe-only start; original merge checks remain exact."""
from pathlib import Path
import hashlib,importlib.util
HERE=Path(__file__).resolve().parent
BASE=HERE/'merge_layout_perf_NOTRUN.py'
assert hashlib.sha256(BASE.read_bytes()).hexdigest()=='7f583dfd7b50601d120431d6b87c6c8ddae976deb7785bbb68fec1824052b2a2'
spec=importlib.util.spec_from_file_location('fixed_merge01',BASE)
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
module.PERF=module.GAME/'build/luoyang_loading_20261024e_perf01/candidate03/whole_byte_delta_NOTRUN.json'
module.PERF_SHA='e04908d6b0b1f9a077724f0352009d0305e5f7ee19c9c68582ef78489ca5d84b'
if __name__=='__main__':module.main()
