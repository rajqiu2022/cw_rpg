"""Current E370 exact source-only24 and adopted Field EOF snapshot; no runtime algorithm changes."""
from pathlib import Path
import argparse
N=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--backup-sha256',required=True);args=ap.parse_args()
t=(N/'prepare_pawn_collision25_candidates_NOTENGINE.py').read_text(encoding='utf8')
t=t.replace("PREFIX=P+'unified25_READY01/'","PREFIX=P+'unified24_READY01/'")
for a,b in [("P=S+'pawnshop_collision_repair01/'","P=S+'Field_EOF_adoption01/'"),('pawnshop_collision_repair01/unified25_READY01','Field_EOF_adoption01/unified24_READY01'),('current_9C1245_exact25_scope_PREPARATION.json','current_E370_exact24_scope_PREPARATION.json'),('f1d6bfa254e836a901c3131010009328bf3e77931d7fe1bef53040f55c2b4304','e050baa4bb45bd60e264039b8904a171891b63dc885450465e322f05cd036869'),('pawnshop_only_repair01/unified22_READY01/pawnshop22_all_candidates_and_inverse_NOT_STAGE.json','artisan_return_guard_repair01/unified22_READY01/artisan_return22_all_candidates_and_inverse_NOT_STAGE.json'),('aceeb63c1217aa148b547fec737e9e2ae2d6da6ce5fb6993d7a7df028663eb74','f057a8957154f052256d361e1e5bdfd021541b34d812780463c68061b7c0885f'),('Estate_wall_source_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','seven_fields_layout_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),('ccd21474dd1a99ef33b6a965da522190e4ad811f237bed3671430f5007cb7b54','c7ac1d0d213c7db851f93157010aeb3672633b57a87e2335bc5e101e2e69102a'),('current_9C1245_backup25_ROOT_ACTUAL.json','current_E370_backup24plus2_ROOT_ACTUAL.json'),('50fe87abfd647b11f7dacbc5863bc294ddde389579a2b1099958ca25b3c89bf0',args.backup_sha256),("backup['total_backups']==539 and len(backup['new_backups'])==25","backup['total_backups']==674 and len(backup['new_backups'])==24 and len(backup['adoption_backups'])==2"),("len(prior['source_sha256'])==236","len(prior['source_sha256'])==259"),("len(authority['source_sha256'])==241","len(authority['source_sha256'])==264"),('old236_all_values_edges_retained','old259_all_values_edges_retained'),('PAWN_ONLY_LOCAL9BASE_BODY_FIELD_HUNK_AND_NECESSARY_PINS_NOT_STAGE','FIELD_TWO_TERMINAL_LF_ADOPTION_AND_NECESSARY_PINS_NOT_STAGE'),('CURRENT9C1245_PAWN_LOCAL_BODIES_EXACT25_PREPARED_NOT_STAGE','CURRENT_E370_FIELD_SINGLE_LF_ADOPTED_EXACT24_PREPARED_NOT_STAGE'),('pawn_collision25_all_candidates_and_inverse_NOT_STAGE.json','Field_EOF24_all_candidates_and_inverse_NOT_STAGE.json')]:
 assert a in t,a;t=t.replace(a,b)
marker="scope=load(scopepin);parents="
t=t.replace(marker,"scope=load(scopepin);adoption=scope['adopted_Field'];parents=")
marker="oldpin=pin("
pos=t.index(marker);t=t[:pos]+"parents[F]=adoption['parent']\n"+t[pos:]
a=t.index('# Preserve and classify');z=t.index('prepared={}',a)
t=t[:a]+"assert backup['external_save_changes']==[]\nclassification=backuppin\n"+t[z:]
a=t.index('function_proof=pin(');z=t.index("a=raw(parents[CT]);",a)
t=t[:a]+"function_proof=scope['adoption_proof'];load(function_proof)\nfield=adoption['candidate'];assert raw(field)==raw(adoption['parent'])[:-2] and (GAME/F[6:]).read_bytes()==raw(field)\nrecords[F]=adoption;refs[F]=field\n"+t[z:]
t=t.replace("    a=raw(parents[p]);assert b!=a;","    b=b.rstrip(b'\\n')+b'\\n';a=raw(parents[p]);assert b!=a;")
marker="tail=tail.replace(\"and len(records)==9 and len(metadata)==12\",\"and len(records)==11 and len(metadata)==12\")"
assert marker in t;t=t.replace(marker,marker+"\ntail=tail.replace(\"    assert b!=before and b.count(t['enabled_literal'].encode())==1\",\"    b=b.rstrip(bytes([10]))+bytes([10]);assert b!=before and b.count(t['enabled_literal'].encode())==1\")\ntail=tail.replace(\"for p in parents]\",\"for p in parents if p!=F]\")")
t=t.replace('assert len(targets)==25',"assert len(targets)==24;adopted_record=records.pop(F);parents.pop(F)")
t=t.replace("records={p:records[p]for p in [F,CO,T]}","records={p:records[p]for p in [CO,T]},adopted_Field=adopted_record")
t=t.replace("partition=dict(GD=11,JSON=14,total=25)","partition=dict(GD=10,JSON=14,total=24),adopted_Field=adopted_record,Field_current_already_saved_not_written=True")
t=t.replace("backup_authorized22_classification=classification","fresh_backup_baseline=classification")
t=t.replace('current_E370_backup24plus2_ROOT_ACTUAL.json','current_E370_backup24plus2_ROOT_ACTUAL02.json')
exec(compile(t,str(N/'prepare_Field_EOF_adoption24_candidates_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_Field_EOF_adoption24_candidates_DERIVED_NOTENGINE.py')})
