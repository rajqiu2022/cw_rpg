from pathlib import Path
import json,re,hashlib
G=Path(__file__).resolve().parents[2]
S=G/'build/luoyang_city_revision_20261025g_source01/outputs/root_market_courtyard45_exact32_stage02/receipt.json'
raw=S.read_bytes()
assert hashlib.sha256(raw).hexdigest()=='c972f71442cc6573d8e55a92bf0ce875039879be651dd30e3fd32df585d97396'
s=json.loads(raw)
fixed=s['source_first']
shopdir=G/'build/luoyang_indoor_services_20261025h_system01/shops'
skus=[]
for shop in shopdir.glob('*.tres'):
 stock=next(x for x in shop.read_text(encoding='utf-8').splitlines() if x.startswith('stock ='))
 for sku in re.findall(r'&"([^"]+)"',stock):
  candidates=[G/'data/items'/f'{sku}.tres',G/'data/equipment'/f'{sku}.tres']
  found=[p for p in candidates if p.exists()]
  assert len(found)==1,(sku,found)
  p=found[0];r='res://'+p.relative_to(G).as_posix()
  b=p.read_bytes();h=hashlib.sha256(b).hexdigest()
  skus.append({'shop':shop.stem,'sku':sku,'path':r,'in_fixed_25g_source_union':r in fixed,
   'fixed_sha256':fixed.get(r),'current_sha256_observation':h,
   'equals_fixed':fixed.get(r)==h,
   'prices':[x for x in b.decode('utf-8').splitlines() if x.startswith(('buy_price','sell_price'))]})
direct={
 'res://scenes/shop.tscn','res://scripts/ui/shop_ui.gd',
 'res://scripts/autoload/inventory.gd','res://scripts/domain/shop_def.gd',
 'res://scripts/domain/item.gd','res://scripts/domain/equipment.gd'}
links={}
for r in sorted(direct|{x['path'] for x in skus}):
 p=G/r[6:]; b=p.read_bytes()
 refs=sorted(set(re.findall(r'"(res://[^"\r\n]+)"',b.decode('utf-8'))))
 # Directory-only and dynamic format paths are not made-up concrete leaves.
 links[r]=[x for x in refs if '%' not in x and not x.endswith('/')]
dependency={}
for r in sorted(direct|{x for refs in links.values() for x in refs}):
 p=G/r[6:]
 if not p.is_file():
  dependency[r]={'exists':False,'not_admitted':True};continue
 b=p.read_bytes();h=hashlib.sha256(b).hexdigest()
 dependency[r]={'exists':True,'sha256_observation':h,'bytes':len(b),'fixed_25g_sha256':fixed.get(r),'equals_fixed':fixed.get(r)==h,'new_ordinary_admission_required':r not in fixed}
value={'status':'SERVICE_STOCK_AND_DIRECT_SHOP_CONSUMERS_READONLY_PROPOSAL_NOT_ADMITTED',
 'parent_stage':{'path':'res://'+S.relative_to(G).as_posix(),'sha256':hashlib.sha256(raw).hexdigest()},
 'SKU_count':len(skus),'missing_fixed_union':sum(not x['in_fixed_25g_source_union'] for x in skus),'rows':skus,
 'direct_textual_consumer_and_icon_refs':links,'bounded_dependency_observations':dependency,
 'scope':'Stock exact35 definitions plus immediate literal references and six explicit behavior consumers; not a recursive project collector. Root approval required for every newly declared ordinary leaf. No item/UI/price changes.',
 'engine':0,'canonical_writes':0}
dest=Path(__file__).with_name('service_item_shop_sources_PROPOSAL_NOT_ADMITTED.json')
assert not dest.exists()
blob=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
with dest.open('xb') as f:f.write(blob)
print(json.dumps({'path':'res://'+dest.relative_to(G).as_posix(),'sha256':hashlib.sha256(blob).hexdigest(),'bytes':len(blob),'SKU_count':len(skus),'dependency_observations':len(dependency)}))
