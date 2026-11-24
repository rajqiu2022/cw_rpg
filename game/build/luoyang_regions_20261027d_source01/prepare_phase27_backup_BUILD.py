"""27 current targets, same mature Root-only fresh backup contract."""
from pathlib import Path
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01'
text=(N/'prepare_rebinding26_backup_BUILD.py').read_text(encoding='utf8')
def change(a,b):
 global text
 assert text.count(a)==1,a[:100];text=text.replace(a,b,1)
change("P=S/'region_integration_20261027d01';O=S/'region_source_rebind_repair02'","P=S/'region_source_rebind_repair02';O=S/'region_phase_lifetime_repair03'")
change("source_rebinding02_BUILD/closure26/current_D9A8_exact26_scope_PREPARATION.json","phase_lifetime03_BUILD/closure27/current_5FCE_exact27_scope_PREPARATION.json")
change('10c5ec0d991dd351f0f9510815be4d36286992afffb71adaa42e019f55cdc58f','4b23d7d1f2403029a431f5f83933fbe2b0face47e7d3ab19aabd63a2e1be8ada')
change("dep_path=P/'region_integration32_deployed_ROOT_ACTUAL.json'","dep_path=P/'region_source_rebind26_deployed_ROOT_ACTUAL.json'")
change('d9a8a9b7ac8752f31e8d3a59d7d4d8bddbcbaa261711bef05c6c608f54e7967f','5fcebce700aeff7f4646a4a81983665c3c0abf888330b1b5a8720485b132c361')
change("P/'current_01656_backup32_ROOT_ACTUAL.json'","P/'current_D9A8_backup26_ROOT_ACTUAL.json'")
change('5d406f8866427ace84600088b30748ec8bd3d30d8ed5bcd1b170316c11b882c1','35a5b2269ddc6897d1e7689506bf353ca7988a9eed5a6b1f7142bbd637769048')
change("back['old737_backup_facts']","back['old769_backup_facts']")
change('assert len(oldbacks)==769','assert len(oldbacks)==795')
change("parent=P/'backup_current_01656_32_ROOT_ONLY.py'","parent=S/'region_integration_20261027d01/backup_current_01656_32_ROOT_ONLY.py'")
text=text.replace('current_D9A8_backup26_ROOT_PLAN','current_5FCE_backup27_ROOT_PLAN').replace('root_only_current26_backup','root_only_current27_backup').replace('len(rows)==26','len(rows)==27').replace('current26=rows','current27=rows').replace('old769_backup_facts=oldbacks','old795_backup_facts=oldbacks').replace('expected_old_backup_total=769','expected_old_backup_total=795').replace('expected_after_backup_total=795','expected_after_backup_total=822').replace('CURRENT_D9A8_CREATE_NEW26','CURRENT_5FCE_CREATE_NEW27')
text=text.replace("region_source_rebind_repair02/current_5FCE_backup27_ROOT_PLAN.json","region_phase_lifetime_repair03/current_5FCE_backup27_ROOT_PLAN.json")
text=text.replace('CreateNew26','CreateNew27').replace('root-authorized-backup26','root-authorized-backup27').replace('root_authorized_backup26','root_authorized_backup27').replace("plan['current26']","plan['current27']").replace("'current26=plan'","'current27=plan'").replace("'old769_backup_facts'","'old795_backup_facts'").replace("'769+len(rows)'","'795+len(rows)'").replace('CURRENT_D9A8_FULL26','CURRENT_5FCE_FULL27').replace('CURRENT_D9A8_FRESH','CURRENT_5FCE_FRESH').replace('NEW26_BACKUP','NEW27_BACKUP').replace('backup_current_D9A8_26_ROOT_ONLY.py','backup_current_5FCE_27_ROOT_ONLY.py').replace('backup26_transport_inverse','backup27_transport_inverse')
text=text.replace("back['old795_backup_facts']","back['old769_backup_facts']")
text=text.replace('assert not O.exists();O.mkdir();prefix=', 'assert not O.exists() or not any(O.iterdir());O.mkdir(exist_ok=True);prefix=')
compile(text,'phase27_backup_DERIVED_BUILD.py','exec');exec(compile(text,str(N/'phase27_backup_DERIVED_BUILD.py'),'exec'),{'__file__':str(N/'phase27_backup_DERIVED_BUILD.py')})
