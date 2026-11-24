"""Source-only text expansion of fixed Market media leaves, no media hashes."""
from pathlib import Path
import json,re,hashlib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
p=GAME/'build/luoyang_city_revision_20261024e_source01/outputs/root_market_blocks_prewarm_exact33_stage03/receipt.json';raw=p.read_bytes();assert hashlib.sha256(raw).hexdigest()=='ea657a57c4a884cd3f645b6de7f8fb2010c8920b737b2ab6b9f3c998288c2abc';s=json.loads(raw);m=s['nodes']['expected_ch4_s3_luoyang_market_true']['value']['source_sha256'];expanded=set(m);sidecars=[];missing={}
for path in m:
    if Path(path).suffix.lower() not in ['.png','.jpg','.jpeg','.webp','.wav','.ogg']:continue
    ip=path+'.import';physical=GAME/ip[6:]
    if not physical.is_file():continue
    text=physical.read_text(encoding='utf8');paths=set(re.findall(r'^path(?:\.[A-Za-z0-9_]+)?="(res://[^"\r\n]+)"\r?$',text,re.M));expanded.add(ip);expanded.update(paths);sidecars.append(ip)
    for key in [ip]+sorted(paths):
        if key not in m:missing[key]=dict(parent_media=path,sidecar=ip,compiled_paths=sorted(paths))
for key in missing:
    found=[]
    for id,node in s['nodes'].items():
        if id.startswith('expected_') and key in node['value']['source_sha256']:found.append(dict(node=id,sha256=node['value']['source_sha256'][key]))
    missing[key]['already_frozen_map_sources']=found
report=dict(status='READONLY_FIXED_MARKET_IMPORT_TEXT_EXPANSION_NO_MEDIA_HASHES',declared_count=len(m),source_expanded_count=len(expanded),sidecars_text_read=len(sidecars),missing=missing,engine_calls=0,collector_calls=0,media_hashes=0,PNG_decodes=0)
out=HERE/'Market_declared_import_expansion_READONLY.json';assert not out.exists();r=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode()
with out.open('xb') as f:f.write(r)
print(json.dumps(dict(path=out.as_posix(),sha256=hashlib.sha256(r).hexdigest(),**report)))
