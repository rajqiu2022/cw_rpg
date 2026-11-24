"""Root approved Perf02 can_process residual; all original merge gates reused."""
from pathlib import Path
import hashlib,importlib.util
HERE=Path(__file__).resolve().parent
BASE=HERE/'merge_layout_perf_NOTRUN.py'
assert hashlib.sha256(BASE.read_bytes()).hexdigest()=='7f583dfd7b50601d120431d6b87c6c8ddae976deb7785bbb68fec1824052b2a2'
spec=importlib.util.spec_from_file_location('fixed_merge01',BASE)
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
module.PERF=module.GAME/'build/luoyang_loading_20261024e_perf01/candidate02/whole_byte_delta_NOTRUN.json'
module.PERF_SHA='7eb7dad1f5fc7e60736594fc1677a9ea9a453157c3f2aaddd62f047ebacf399b'
if __name__=='__main__':module.main()
