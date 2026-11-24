"""Mechanical current6C01 successor of the same reviewed Field-only25 expression."""
from pathlib import Path
import argparse
N=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--backup-sha256',required=True);args=ap.parse_args()
assert len(args.backup_sha256)==64 and all(c in '0123456789abcdef'for c in args.backup_sha256)
t=(N/'prepare_pawn_collision25_candidates_NOTENGINE.py').read_text(encoding='utf-8')
changes=[
('One exact-pawn local-blocker Field hunk and necessary existing source pins; BUILD only.','Only two exact-pawn Field G receiver fixes and necessary existing source pins; current6C01 BUILD only.'),
("P=S+'pawnshop_collision_repair01/'","P=S+'pawnshop_collision_Gbinding_repair01/'"),
('pawnshop_collision_repair01/unified25_READY01','pawnshop_collision_Gbinding_repair01/unified25_READY01'),
('current_9C1245_exact25_scope_PREPARATION.json','current_6C01_exact25_scope_PREPARATION.json'),
('f1d6bfa254e836a901c3131010009328bf3e77931d7fe1bef53040f55c2b4304','c5655ce1412103a570ff8f45bb91b8d7b4d64d8005dc2c03c0db5edb78b1277e'),
("oldpin=pin(S+'pawnshop_only_repair01/unified22_READY01/pawnshop22_all_candidates_and_inverse_NOT_STAGE.json','aceeb63c1217aa148b547fec737e9e2ae2d6da6ce5fb6993d7a7df028663eb74')","oldpin=pin(S+'pawnshop_collision_repair01/unified25_READY01/pawn_collision25_all_candidates_and_inverse_NOT_STAGE.json','4d850a9d16b675af9262b345140643cfa3dcb28e3abe8f9b81c9ae405dc87df9')"),
('current_9C1245_backup25_ROOT_ACTUAL.json','current_6C01_backup25_ROOT_ACTUAL.json'),
('50fe87abfd647b11f7dacbc5863bc294ddde389579a2b1099958ca25b3c89bf0',args.backup_sha256),
("backup['total_backups']==539","backup['total_backups']==564"),
('Field_bodies01_direct_whole_inverse_BUILD.json','Field_bodies02_Gbinding_direct_inverse_BUILD.json'),
('b7cac3e366462f107f954db58147fa89ec975157ef4e95654a63357d885b78f4','83dcd43506cec3dcf2d5673f7c00732b3ef5c48e789a8df92606f0ccc1b8514c'),
('Field_bodies01_CANDIDATE.gd','Field_bodies02_Gbinding_CANDIDATE.gd'),
('9504c55b9f0b664a35a24e830aeb5278152b3d8e732af42a3f17b8b762ebcde2','3f4ce463ec8aeeff06500040e6ca4d1526c1357ba3393def55e84cffb4c82193'),
("tbparent=prior31['temple_binding']['candidate']","tbparent=oldbundle['temple_binding']['candidate']"),
("len(prior['source_sha256'])==236","len(prior['source_sha256'])==241"),
("len(authority['source_sha256'])==241","len(authority['source_sha256'])==246"),
('old236_all_values_edges_retained','old241_all_values_edges_retained'),
('PAWN_ONLY_LOCAL9BASE_BODY_FIELD_HUNK_AND_NECESSARY_PINS_NOT_STAGE','PAWN_ONLY_TWO_G_RECEIVER_BINDINGS_FIELD_HUNK_AND_NECESSARY_PINS_NOT_STAGE'),
('CURRENT9C1245_PAWN_LOCAL_BODIES_EXACT25_PREPARED_NOT_STAGE','CURRENT6C01_PAWN_G_RECEIVER_BINDINGS_EXACT25_PREPARED_NOT_STAGE'),
("dp=out('pawn_collision25_all_candidates_and_inverse_NOT_STAGE.json'","dp=out('pawn_Gbinding25_all_candidates_and_inverse_NOT_STAGE.json'")]
for a,b in changes:assert a in t,a;t=t.replace(a,b)
start=t.index('# Preserve and classify the original backup report')
end=t.index('prepared={};records={};refs={};metadata={};indexes={};nodes={};additions={}',start)
old=t[start:end]
new="""assert backup['differences']==[],'CURRENT6C01_BACKUP_HAS_UNCLASSIFIED_DIFFERENCE_KEEP_CURRENT_STOP'
audit=enc(dict(status='CURRENT6C01_BACKUP_ZERO_DIFFERENCES_READONLY_NOT_GUARD_REPLAY',passed=True,backup=backuppin,authorized_differences=[],authorized_count=0,all2121_no_difference_in_actual_report=True,engine_calls=0,canonical_writes=0))
auditpath=N/'pawnshop_collision_Gbinding_repair01/backup_zero_difference_READONLY.json';assert not auditpath.exists()
with auditpath.open('xb')as f:f.write(audit)
classification=pin(P+auditpath.name,sha(audit))
"""
t=t.replace(old,new)
exec(compile(t,str(N/'prepare_pawn_Gbinding25_candidates_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_pawn_Gbinding25_candidates_DERIVED_NOTENGINE.py')})
