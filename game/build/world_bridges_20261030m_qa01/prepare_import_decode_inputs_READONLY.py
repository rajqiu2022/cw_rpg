from pathlib import Path
import hashlib,json
root=Path('F:/Code/RPG_GAME')
art=root/'game/build/world_bridges_20261030m_art01/selected_five_V4_SOURCE_READY.json'
receipt=root/'game/build/world_bridges_20261030m_root01/asset_promote01_ACTUAL.json'
selected=json.loads(art.read_text(encoding='utf-8-sig'))
promoted=json.loads(receipt.read_text(encoding='utf-8-sig'))
scripts=['game/build/world_bridges_20261030m_system01/bridge_visual_patch.gd','game/build/world_bridges_20261030m_system01/world_v15_visible_stream_20261018r_CANDIDATE.gd','game/build/world_bridges_20261030m_system01/world_v15_stream_overlap_20261018r_CANDIDATE.gd']
uri=lambda p:'res://'+p.relative_to(root/'game').as_posix()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
pins={};rows=[]
for row in selected['selected']:
    path=root/row['runtime_input']['path']
    compiled=next(line.split(chr(34))[1] for line in Path(str(path)+'.import').read_text().splitlines() if line.startswith('path='))
    rows.append({'id':row['id'],'path':uri(path),'version':row['version'],'size':row['size'],'rgba_sha256':row['rgba_sha256'],'compiled_path':compiled})
    pins[uri(path)]=row['runtime_input']['sha256']
for fact in promoted['facts']:pins[uri(Path(fact['path']))]=fact['sha256'].lower()
for relative in scripts+['game/build/world_bridges_20261030m_qa01/import_decode_ROOT_ONLY.gd','game/build/world_bridges_20261030m_system01/bridge_partition.gdshader','game/build/world_bridges_20261030m_art01/selected_five_V4_SOURCE_READY.json','game/build/world_bridges_20261030m_root01/asset_promote01_ACTUAL.json']:
    pins[uri(root/relative)]=sha(root/relative)
print(json.dumps({'textures':rows,'parse_scripts':[uri(root/path) for path in scripts],'pins':pins},separators=(',',':')))
