from pathlib import Path
import copy,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1]
raw=(N/'author_adjacent_four_fields03_actual_courts_NPC_NOTREADY.json').read_bytes();assert hashlib.sha256(raw).hexdigest()=='d4366c6dbbc40f1e0cd4db82dd47883a90f68b02043049e6e7bfa2c5f6fdcb93'
old=json.loads(raw);new=copy.deepcopy(old)
script=(G/'scripts/city/luoyang_district_life_crowd_20261016f.gd').read_text(encoding='utf8')
assert 'var id: String="district_life_"+String(row.get("id",""))' in script
row=new['scenes'][0]['npc_migrations'][0];assert row['npc_id']=='market_traveller'
row['npc_id']='district_life_market_traveller'
row['original_DG_author_id']='market_traveller'
row['actual_id_source_expression']='CROWD.project: district_life_ + source row.id; no new identity or dialogue'
out=N/'author_adjacent_four_fields04_actual_actor_id_NOTREADY.json';b=(json.dumps(new,ensure_ascii=False,indent=2)+'\n').encode()
with out.open('xb') as stream:stream.write(b)
back=copy.deepcopy(new);r=back['scenes'][0]['npc_migrations'][0];r['npc_id']='market_traveller';del r['original_DG_author_id'];del r['actual_id_source_expression'];assert back==old
print(json.dumps({'path':'res://build/luoyang_city_finish_20261025i_source01/'+out.name,'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b),'whole_typed_inverse':True,'only_true_last_consumer_id_not_position_or_geometry_change':True}))
