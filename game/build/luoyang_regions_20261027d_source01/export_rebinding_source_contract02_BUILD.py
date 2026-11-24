"""Same Entry union export, using the fixed candidate manifest before deployment."""
from pathlib import Path
N=Path(__file__).resolve().parent
text=(N/'export_final_source_contract_BUILD.py').read_text(encoding='utf8')
old="raw = (G / pin['path'][6:]).read_bytes()"
new="raw = (N / 'source_rebinding02_BUILD/region_runtime_manifest_candidate.json').read_bytes() if pin['path'] == 'res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json' and pin['sha256'] == '77c638a7d229a6dfd2437b9b9374c15af68232899690d2d7dda52e17c44327ff' else (G / pin['path'][6:]).read_bytes()"
assert text.count(old)==1;text=text.replace(old,new,1)
assert text.count('54976bb040827b1dfc4cff9103ef9c5d84841c57eec8790c803de48b3820cae6')==1
text=text.replace('54976bb040827b1dfc4cff9103ef9c5d84841c57eec8790c803de48b3820cae6','77c638a7d229a6dfd2437b9b9374c15af68232899690d2d7dda52e17c44327ff')
text=text.replace("'final_bounded_source_contract_BUILD.json'","'final_bounded_source_contract02_BUILD.json'")
text=text.replace("'counts': {'civic': len(civic_sources), 'temple': len(temple_sources), 'gate': len(gate['source_sha256'])},","'counts': {'civic': len(civic_sources), 'temple': len(temple_sources), 'gate': len(gate['source_sha256'])},\n    'gate_credit': 'Already passed86968, old fixed declaration retained solely as component history; no Gate rerun in residual02',")
exec(compile(text,str(N/'export_final_source_contract_BUILD.py'),'exec'),{'__file__':str(N/'export_final_source_contract_BUILD.py')})
