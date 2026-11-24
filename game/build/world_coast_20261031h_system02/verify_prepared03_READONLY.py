"""Read-only Scene03 packaging differential; not engine parse or admission QA."""
from __future__ import annotations
import importlib.util,json
from pathlib import Path

OWN=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('prepared01_readonly_helpers',OWN/'verify_prepared.py')
base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)

def main():
    old=OWN/'prepared02';new=OWN/'prepared03'
    receipt=json.loads((new/'receipt_REVIEW_ONLY.json').read_bytes())
    old_receipt=json.loads((old/'receipt_REVIEW_ONLY.json').read_bytes())
    assert base.sha((new/'integration_REVIEW_ONLY.patch').read_bytes())==receipt['patch_sha256']
    assert [r['path'] for r in receipt['targets']]==[r['path'] for r in old_receipt['targets']]
    assert len(receipt['targets'])==12
    changed=[]
    for row in receipt['targets']:
        path=row['path'];original=(base.REPO/path).read_bytes()
        previous=(old/'copies'/path).read_bytes();candidate=(new/'copies'/path).read_bytes()
        assert base.sha(original)==row['before_sha256'],'STALE_ORIGINAL_SOURCE: '+path
        assert base.sha(candidate)==row['candidate_sha256'],'CANDIDATE_SHA: '+path
        assert previous.replace(b'world_contract_dispatch02.gd',b'world_contract_dispatch03.gd')==candidate,'NON_PACKAGING_DIFFERENCE: '+path
        assert previous.count(b'\r\n')==candidate.count(b'\r\n') and previous.count(b'\n')==candidate.count(b'\n'),'PACKAGING_EOL_DRIFT: '+path
        if previous!=candidate:changed.append(path)
        if '/dialogs/' in path:
            choices=lambda b:[line for line in b.splitlines() if line.startswith(b'choices =')]
            assert choices(original)==choices(candidate) and len(choices(original))==1
        if path.endswith('world_links.gd'):
            before=original.decode().replace('\r\n','\n');after=candidate.decode().replace('\r\n','\n')
            for name in ['portal_rows','_pending_request','_pending_finished','_world_door_safe']:
                assert base.method(before,name)==base.method(after,name),'31F_METHOD_CHANGED: '+name
        if path.endswith('save_manager.gd'):
            assert b'var private_path: String=SceneRouter.field_scene_resource_path(SceneRouter.WORLD_MAP_V16_SCENE)' in candidate
            assert b'return SceneRouter.WORLD_MAP_V16_SCENE if ResourceLoader.exists(private_path) else &""' in candidate
    assert len(changed)==5
    print(json.dumps({'status':'READONLY03_PACKAGING_DIFFERENTIAL_ONLY_NOT_ENGINE_QA','targets':12,'dispatch_path_only_changes':changed,'other_copy_bytes_exact':7,'dialog_choices_original_exact':True,'adventure31f_guard_methods_original_exact':True,'old_source_writes':0,'engine_runs':0,'real_save_API_calls':0},ensure_ascii=False,indent=2))

if __name__=='__main__':main()
