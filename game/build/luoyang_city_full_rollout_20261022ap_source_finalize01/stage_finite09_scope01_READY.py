"""Exact NEW fresh-backup authority successor; original1177 tool unchanged."""
import hashlib,importlib.util
from pathlib import Path
BASE=Path(__file__).with_name('stage_finite09_READY.py')
assert hashlib.sha256(BASE.read_bytes()).hexdigest()=='b8d88ade54c74554cd76e8a3aa2e0a1ce72b8fb55519c526bf4d15d33f393b52'
spec=importlib.util.spec_from_file_location('finite08_base',BASE)
B=importlib.util.module_from_spec(spec);spec.loader.exec_module(B)
Original=B.FiniteStage
class FreshScopeStage(Original):
    def check_new_authority(self):
        super().check_new_authority()
        row=self.inputs['root_finite08_actual_backups']
        B.need(row['path']=='res://build/luoyang_city_full_rollout_20261022ap_root01/integration12/root_target_scope29_READY.json' and row['sha256']=='3e4ba399141dabddd35952064ddb46c540f52a57313f9332ec2306f1683a765a','ROOT_ACTUAL_FRESH29_BACKUP_RECEIPT_PIN')
        value=self.read_json_input('root_finite08_actual_backups')
        B.need(value.get('approved_by_root') is True and value.get('target_count')==29 and value.get('scope_sha256')=='1eade019a011914021f4dae7c0aaa426b0b647ac19cd5564d72bf8828cb4a8d0' and value.get('before_sha256')=='2ce39bbe5a6afba5bc3661107a776fb107c9e1b909cafc50f3f0b1522ba8de47','EXACT_INTEGRATION12_FRESH_BASELINE')
        B.need({r['target']:r['old_sha256'] for r in value['targets']}==self.oldtargets,'BACKUP_EXACT29_OLD_PINS')
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
