"""31h adaptation of30m isolated importer metadata; never edits source PNGs."""
from pathlib import Path
import hashlib,json,shutil
from PIL import Image
ROOT=Path('F:/Code/RPG_GAME'); GAME=ROOT/'game'; QA=GAME/'build/world_coast_20261031h_qa01'
MANIFEST=GAME/'art/maps/world_coast_20261031h/candidate02/runtime_contract.json'
EXPECTED='f4c592117bfc2a1350674f2b26f79b633e82c6bbc5ee00d42b4d79d06635db89'
ISO=QA/'import_isolated02'
def sha(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for block in iter(lambda:f.read(1024*1024),b''):h.update(block)
    return h.hexdigest()
assert sha(MANIFEST)==EXPECTED
assert not ISO.exists(),'Preserve existing isolated project'
m=json.loads(MANIFEST.read_text(encoding='utf-8-sig'))
assert len(m['changed_cells'])==14
roles={}
for cell in m['changed_cells']:
    roles[cell['visual_path']]='visual';roles[cell['nav_path']]='nav'
roles[m['overview_path']]='overview'
assert len(roles)==29 and list(roles.values()).count('nav')==14 and list(roles.values()).count('visual')==14
params={'compress/mode':0,'compress/high_quality':False,'compress/lossy_quality':0.7,'compress/uastc_level':0,'compress/rdo_quality_loss':0.0,'compress/hdr_compression':1,'compress/normal_map':0,'compress/channel_pack':0,'mipmaps/generate':False,'mipmaps/limit':-1,'roughness/mode':0,'roughness/src_normal':'','process/channel_remap/red':0,'process/channel_remap/green':1,'process/channel_remap/blue':2,'process/channel_remap/alpha':3,'process/fix_alpha_border':False,'process/premult_alpha':False,'process/normal_map_invert_y':False,'process/hdr_as_srgb':False,'process/hdr_clamp_exposure':False,'process/size_limit':0,'detect_3d/compress_to':0}
rows=[]
for uri,role in sorted(roles.items()):
    assert uri.startswith('res://art/maps/world_coast_20261031h/candidate02/') and uri.endswith('.png') and '..' not in uri
    rel=uri[6:];source=GAME/rel;source_sha=sha(source)
    with Image.open(source) as im:
        size=list(im.size);rgba_sha=hashlib.sha256(im.convert('RGBA').tobytes()).hexdigest()
    assert size==([3072,2048] if role=='overview' else [1536,1024]),(uri,size)
    compiled='res://.godot/imported/'+source.name+'-'+hashlib.md5(uri.encode()).hexdigest()+'.ctex'
    assert not Path(str(source)+'.import').exists(),'Current-game importer leaf already exists'
    assert not (GAME/compiled[6:]).exists(),'Current-game compiled leaf already exists'
    rows.append({'path':uri,'role':role,'size':size,'sha256':source_sha,'bytes':source.stat().st_size,'rgba_sha256':rgba_sha,'compiled_path':compiled})
ISO.mkdir()
(ISO/'project.godot').write_text('config_version=5\n\n[application]\nconfig/name="Coast29 isolated import"\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n',encoding='utf-8')
def cfg(v):
    return json.dumps(v,ensure_ascii=False,separators=(',',':'))
for row in rows:
    rel=row['path'][6:];dest=ISO/rel;dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(GAME/rel,dest);assert sha(dest)==row['sha256'] and sha(GAME/rel)==row['sha256']
    sidecar='[remap]\nimporter="texture"\ntype="CompressedTexture2D"\npath='+cfg(row['compiled_path'])+'\nmetadata={"vram_texture":false}\n\n[deps]\nsource_file='+cfg(row['path'])+'\ndest_files=['+cfg(row['compiled_path'])+']\n\n[params]\n'+''.join(k+'='+cfg(v)+'\n' for k,v in params.items())
    Path(str(dest)+'.import').write_text(sidecar,encoding='utf-8')
fixture={'textures':rows,'params':params,'manifest_path':'res://'+MANIFEST.relative_to(GAME).as_posix(),'manifest_sha256':EXPECTED,'only_exact_runtime29_not_land_evidence':True}
fp=ISO/'import_fixture.json';fp.write_text(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
decoder=(QA/'import_decode_TEMPLATE.gd').read_text(encoding='utf-8').replace('__FIXTURE_SHA__',sha(fp));(ISO/'decode.gd').write_text(decoder,encoding='utf-8')
receipt={'status':'ISOLATED29_PREPARED_NOT_IMPORTED','isolated_project':str(ISO),'project_sha256':sha(ISO/'project.godot'),'fixture_sha256':sha(fp),'decoder_sha256':sha(ISO/'decode.gd'),'manifest_sha256':EXPECTED,'rows':rows,'original_PNGs_unchanged':True,'engine_runs':0,'production_writes':0,'source_template_30m':'game/build/world_bridges_20261030m_root01/prepare_import_metadata.py'}
rp=QA/'import29_PREPARED.json'
with rp.open('x',encoding='utf-8') as f:json.dump(receipt,f,ensure_ascii=False,indent=2);f.write('\n')
print(json.dumps({'prepared':str(rp),'sha256':sha(rp),'rows':len(rows),'fixture_sha256':sha(fp),'decoder_sha256':sha(ISO/'decode.gd'),'engine_runs':0}))
