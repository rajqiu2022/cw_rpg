"""Same fixed Entry union; only manifest and RegionField module SHA differ."""
from pathlib import Path
N=Path(__file__).resolve().parent
text=(N/'export_rebinding_source_contract02_BUILD.py').read_text(encoding='utf8')
text=text.replace('77c638a7d229a6dfd2437b9b9374c15af68232899690d2d7dda52e17c44327ff','85c16eb0506e60bb3b0310218bb942beafd90840f447b503d5e231de43be6023').replace('source_rebinding02_BUILD/region_runtime_manifest_candidate.json','phase_lifetime03_BUILD/region_runtime_manifest_candidate.json').replace('final_bounded_source_contract02_BUILD.json','final_bounded_source_contract03_BUILD.json')
exec(compile(text,str(N/'export_rebinding_source_contract02_BUILD.py'),'exec'),{'__file__':str(N/'export_rebinding_source_contract02_BUILD.py')})
