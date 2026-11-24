"""Finite raw/preview/catalog checks; gait and runtime admission are separate."""
import argparse,json,re,yaml
from pathlib import Path
from collections import Counter
from urllib.parse import unquote
from PIL import Image
import world_placeables_walk_20261022 as b
ROOT=b.ROOT;BASE=b.BASE;TEMP=ROOT/'tmp/world_placeables_walk_20261022';HTML=ROOT/'docs/equipment-skill-catalog.html'

def audit():
    ledgers=[json.loads((BASE/name).read_text('utf-8')) for name in ['manifest.json','walk-successors.json','walk-frames.json','walk-guided-frames.json']]
    raw=[r for m in ledgers for r in m['assets'] if r.get('sha256')]
    current=[r for r in raw if r['kind'] not in ('npc_walk','npc_walk_frames') or r['id'].endswith('_v4')]
    history=[r for r in raw if r not in current]
    assert len(raw)==72 and len(current)==64 and len(history)==8,(len(raw),len(current),len(history))
    assert Counter(r['kind'] for r in current)=={'scene_props':8,'field_objects':8,'small_buildings':8,'npc_walk_frames':40}
    assert len({r['sha256'] for r in raw})==72
    for m in ledgers:assert all(b.sha(ROOT/p)==digest for p,digest in m['source_sha256'].items())
    for r in raw:
        p=ROOT/r['output'];meta=json.loads(p.with_suffix('.meta.json').read_text('utf-8'))
        assert b.sha(p)==r['sha256']==meta['sha256']==b.sha(Path(r['source_path']))
        assert r['attempts']==1 and b.sha(ROOT/r['prompt_path'])==r['prompt_sha256']
        for key in ['reference_input','pose_reference_input']:
            if r.get(key):assert b.sha(ROOT/r[key]['path'])==r[key]['sha256']
        with Image.open(p) as im:
            im.load();assert im.mode=='RGBA' and im.getchannel('A').getextrema()[0]==0
            assert list(im.getchannel('A').getbbox())==r['metrics']['full_alpha_bbox']
    old=(TEMP/'before-tasks.yaml').read_bytes();assert (ROOT/'prompts/tasks.yaml').read_bytes()[:len(old)]==old
    tasks=yaml.safe_load((ROOT/'prompts/tasks.yaml').read_text('utf-8'))['tasks'];own=[t for t in tasks if t.get('id','').startswith(b.PREFIX)]
    assert len(own)==116 and len({t['id'] for t in own})==116
    assert all(t['skip'] and t['attempt_budget']==1 and t['execution_backend']=='builtin_image_gen' for t in own)
    previous=json.loads((ROOT/'assets/raw/world_expansion_100_20261022/current-candidates.json').read_text('utf-8'))
    assert all(b.sha(ROOT/r['output'])==r['sha256'] for r in previous['assets']+previous['history'])
    families=[]
    for family in sorted({r['family'] for r in current if r['kind']=='npc_walk_frames'}):
        frames=sorted([r for r in current if r.get('family')==family],key=lambda r:r['frame_index'])
        assert [r['frame_index'] for r in frames]==[1,2,3,4]
        for suffix in ['_walk_down.gif','_raw_walk_down.gif']:
            with Image.open(ROOT/'assets/previews/world_placeables_walk_20261022'/(family+suffix)) as im:
                assert im.n_frames==4
                for i in range(4):im.seek(i);im.load();assert im.info['duration']==180
        families.append({'family':family,'idle_path':frames[0]['reference'],'frames':[r['output'] for r in frames], 'aligned_preview':f'assets/previews/world_placeables_walk_20261022/{family}_walk_down.gif','raw_preview':f'assets/previews/world_placeables_walk_20261022/{family}_raw_walk_down.gif','formal_enabled':False})
    report={'status':'RAW_AND_PREVIEW_INTEGRITY_PASS_NOT_RUNTIME_OR_GAIT_ADMISSION','subjects':34,'current_pngs':64,'raw_pngs':72,'retained_rejected_pngs':8,'npc_families':10,'native_walk_frames':40,'placeables':24,'registered_tasks':116,'unexecuted_superseded_tasks':44,'builtin_calls_with_outputs':72,'new_generations':24,'reference_or_edit_calls':48,'initial_design_identity_sources_unchanged':15,'technical_pose_diagram_sources_unchanged':4,'old_tasks_prefix_exact':True,'previous_101_png_sha_unchanged':True,'full_alpha_margin_pass':sum(r['metrics']['margin_10_percent_pass'] for r in current),'full_alpha_margin_fail':sum(not r['metrics']['margin_10_percent_pass'] for r in current),'formal_enabled':False,'families':families,'assets':current,'history':history}
    (BASE/'current-candidates.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n','utf-8')
    (BASE/'integrity-final.json').write_text(json.dumps({k:v for k,v in report.items() if k not in ('assets','history','families')},indent=2)+'\n','utf-8')
    print(json.dumps({k:v for k,v in report.items() if k not in ('assets','history','families')}))

def gallery():
    data=json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',HTML.read_text('utf-8'),re.S).group(1))
    assert {k:v for k,v in data.items() if k!='resources'}==json.loads((TEMP/'before-catalog-core.json').read_text('utf-8'))
    rows=[r for r in data['resources']['records'] if r['diskPath'].startswith('assets/raw/world_placeables_walk_20261022/')]
    assert len(rows)==72 and sum(r['status']=='candidate' for r in rows)==64 and sum(r['status']=='rejected' for r in rows)==8
    assert sum(bool(r.get('animationPreview')) for r in rows)==10
    for r in rows:
        assert r['category']=='candidate' and r['usageCount']==0
        assert (HTML.parent/unquote(r['url'])).resolve()==(ROOT/r['diskPath']).resolve()
        with Image.open(HTML.parent/r['thumbnail']) as im:im.load();assert im.mode=='RGBA'
        if r.get('animationPreview'):assert (HTML.parent/unquote(r['animationPreview'])).is_file() and r['status']=='candidate'
    report={'status':'GALLERY_72_PATHS_THUMBNAILS_AND_10_GIFS_PASS','current_pngs':64,'rejected_pngs':8,'animated_preview_records':10,'original_core_exact':True,'summary':data['resources']['summary'],'browser_interaction_test':False}
    (TEMP/'gallery-final.json').write_text(json.dumps(report,indent=2)+'\n','utf-8');print(json.dumps(report))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['audit','gallery']);a=p.parse_args();audit() if a.action=='audit' else gallery()
