"""Read-only evidence for candidate copies. This is not GDScript/engine QA."""
from __future__ import annotations
import ast
import hashlib
import json
import re
from pathlib import Path

OWN=Path(__file__).resolve().parent
REPO=OWN.parents[2]
PREPARED=OWN/'prepared'

def sha(data: bytes) -> str:return hashlib.sha256(data).hexdigest()

def method(text: str,name: str) -> str:
    begin=text.index('func '+name+'(')
    next_function=re.search(r'\n(?:static )?func ',text[begin+1:])
    return text[begin:] if next_function is None else text[begin:begin+1+next_function.start()]

def main():
    ast.parse((OWN/'prepare_integration.py').read_text(encoding='utf-8'))
    receipt=json.loads((PREPARED/'receipt_REVIEW_ONLY.json').read_text(encoding='utf-8'))
    patch=(PREPARED/'integration_REVIEW_ONLY.patch').read_bytes()
    assert sha(patch)==receipt['patch_sha256']
    results=[]
    for row in receipt['targets']:
        original=(REPO/row['path']).read_bytes()
        candidate=(PREPARED/'copies'/row['path']).read_bytes()
        assert sha(original)==row['before_sha256'], 'Stale actual source: '+row['path']
        assert sha(candidate)==row['candidate_sha256']
        assert original.count(b'\r\n')==candidate.count(b'\r\n'), 'CRLF normalization: '+row['path']
        if '/dialogs/' in row['path']:
            old=[line for line in original.splitlines() if line.startswith(b'choices =')]
            new=[line for line in candidate.splitlines() if line.startswith(b'choices =')]
            assert old==new and len(old)==1
        if row['path'].endswith('world_links.gd'):
            before=original.decode('utf-8').replace('\r\n','\n')
            after=candidate.decode('utf-8').replace('\r\n','\n')
            for name in ['portal_rows','_pending_request','_pending_finished','_world_door_safe']:
                assert method(before,name)==method(after,name), '31f safety changed: '+name
        if row['path'].endswith('save_manager.gd'):
            assert b'var private_path: String=SceneRouter.field_scene_resource_path(SceneRouter.WORLD_MAP_V16_SCENE)' in candidate
            assert b'return SceneRouter.WORLD_MAP_V16_SCENE if ResourceLoader.exists(private_path) else &""' in candidate
        results.append({'path':row['path'],'actual_source_still_before':True,'candidate_sha256':sha(candidate)})
    report={'status':'STATIC_CANDIDATE_CHECKS_ONLY_NOT_ENGINE_PARSE','target_count':len(results),'source_closure_approval':False,'engine_runs':0,'real_save_reads':0,'real_save_writes':0,'checks':results}
    print(json.dumps(report,ensure_ascii=False,indent=2))

if __name__=='__main__':main()
