"""Exact NEW fresh-backup authority successor; original1177 tool unchanged."""
import hashlib,importlib.util
from pathlib import Path
BASE=Path(__file__).with_name('stage_finite08_READY.py')
assert hashlib.sha256(BASE.read_bytes()).hexdigest()=='1177be57d7b656f825e695ee8be56e635b7915beaf4ef8b50f44c3422658c11f'
spec=importlib.util.spec_from_file_location('finite08_base',BASE)
B=importlib.util.module_from_spec(spec);spec.loader.exec_module(B)
Original=B.FiniteStage
class FreshScopeStage(Original):
    def check_new_authority(self):
        super().check_new_authority()
        row=self.inputs['root_finite08_actual_backups']
        B.need(row['path']=='res://build/luoyang_city_full_rollout_20261022ap_root01/integration12/root_target_scope_READY.json' and row['sha256']=='44cfe6d81a6aff79431def1a3026199219f0a63083931de636577efa633841a0','ROOT_ACTUAL_FRESH28_BACKUP_RECEIPT_PIN')
        value=self.read_json_input('root_finite08_actual_backups')
        B.need(value.get('approved_by_root') is True and value.get('target_count')==28 and value.get('scope_sha256')=='15f54447d64b4cb4048654aec64e9a1a634c36468358822818b335a634e2b672' and value.get('before_sha256')=='2ce39bbe5a6afba5bc3661107a776fb107c9e1b909cafc50f3f0b1522ba8de47','EXACT_INTEGRATION12_FRESH_BASELINE')
        B.need({r['target']:r['old_sha256'] for r in value['targets']}==self.oldtargets,'BACKUP_EXACT28_OLD_PINS')
        for r in value['targets']:
            p=Path(r['backup_path']).resolve()
            B.need(p.is_relative_to(B.M.ROOT),'ROOT_BACKUP_GAME_PATH_ONLY')
            key='res://'+p.relative_to(B.M.ROOT).as_posix()
            B.need(r['backup_sha256']==r['old_sha256'] and len(self.read(key,r['old_sha256']))==r['old_bytes'],'ROOT_FULL_OLD_BACKUP_SHA_BYTES')
        tool=self.spec['required_generator']
        B.need(B.res(tool['path'])==Path(__file__).resolve(),'PINNED_THIS_EXACT_GENERATOR')
        self.read(tool['path'],tool['sha256'])
B.FiniteStage=FreshScopeStage
if __name__=='__main__':B.main()
