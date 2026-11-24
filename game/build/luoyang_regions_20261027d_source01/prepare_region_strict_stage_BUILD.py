"""One specialization of the already reviewed Stage32; never runs Stage."""
from pathlib import Path
import argparse, copy, hashlib, json
N = Path(__file__).resolve().parent
G = N.parents[1]
S = G / 'build/luoyang_city_finish_20261025i_source01'
O = S / 'region_integration_20261027d01'
P = 'res://build/luoyang_city_finish_20261025i_source01/region_integration_20261027d01/'
ap = argparse.ArgumentParser(); ap.add_argument('--region-declarations', required=True); ap.add_argument('--region-declarations-sha256', required=True); args = ap.parse_args()
sha = lambda raw: hashlib.sha256(raw).hexdigest()
enc = lambda value: (json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False) + '\n').encode()
def res(path): return 'res://' + path.relative_to(G).as_posix()
def pin(path):
    raw = path.read_bytes(); return {'path': res(path), 'sha256': sha(raw), 'bytes': len(raw)}
def emit(path, raw):
    assert not path.exists(), str(path); path.write_bytes(raw); return pin(path)
parent_driver = S / 'stage_garden_estate32_ROOT_ONLY02.py'
bundle_path = O / 'unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'
bundle = json.loads(bundle_path.read_bytes())
router_pin = next(row['candidate'] for row in bundle['targets'] if row['target'] == 'res://scripts/autoload/scene_router.gd')
text = parent_driver.read_text(encoding='utf8')
def change(before, after):
    global text
    assert text.count(before) == 1, before[:100]
    text = text.replace(before, after, 1)
text = text.replace('GardenEstate32', 'RegionIntegration32')
text = text.replace('ROOT_CURRENT_CE38_FULL32_BACKUP_AND_FRESH_OBSERVATION', 'ROOT_CURRENT_01656_FULL32_BACKUP_AND_FRESH_OBSERVATION')
text = text.replace("self.backup['total_backups']==737", "self.backup['total_backups']==769")
text = text.replace("PREFIX+'garden_estate_exit_repair_20261027c01/root_only_current32_backup/'", "PREFIX+'region_integration_20261027d01/root_only_current32_backup/'")
text = text.replace("len(prior['source_sha256'])==270 and len(self.authority['source_sha256'])==277", "len(prior['source_sha256'])==277 and len(self.authority['source_sha256'])==284")
text = text.replace('OWNED10_270_PLUS7_EQUALS277', 'OWNED10_277_PLUS7_EQUALS284').replace('ALL_OLD270_FIXED_SEVEN_NEW', 'ALL_OLD277_FIXED_SEVEN_NEW')
change("M.EXACT_EOL_CANDIDATES={'res://scripts/autoload/scene_router.gd':('2687a0d72d6bf34654894905b9caf2082c3fdf97e7db4633e518996569d2650c',13)}", "M.EXACT_EOL_CANDIDATES={'res://scripts/autoload/scene_router.gd':(" + repr(router_pin['sha256']) + ",13)}")
text = text.replace('# Router is an exact unchanged parent this epoch; no EOL transport is needed.', '# Router has the explicit Region dispatch successor; preserve its original thirteen CRLF bytes after patch transport.')
change("trial=self.read_json_input('trial');need(trial['admitted']is True and trial['permission_kind']=='TRIAL_PERMISSION_NOT_RESULT'and trial['actual_Field_pass']is False and self.inputs['trial']['path']==PREFIX+'finish8_ROOT_TRIAL_PERMISSION07.json'and self.inputs['trial']['sha256']=='439d2df41ab8767b19a76ae3d7a426e66b751f131d1df2783ac3bcb774d25b88','TRIAL_PERMISSION_NOT_RESULT')", "trial=self.read_json_input('trial');need(trial['root_authorized']is True and trial['actual_field_pass']is False and self.inputs['trial']['path']=='res://build/luoyang_regions_20261027d_source01/root_integration_scope08_AUTHORIZED.json'and self.inputs['trial']['sha256']=='9d064035022286b8337c430e635f72528e3975cce91e914f53a351ac5bd71919','ROOT08_SCOPE_IS_PERMISSION_NOT_RESULT')")
start = text.index("  finite=self.read_json_input('local_publication')"); end = text.index("  for p,r in self.bundle['records'].items():", start)
text = text[:start] + '''  finite=self.read_json_input('local_publication');need(finite['passed']is True and not finite['errors']and finite['whole_payload_inverse']is True and finite['whole_RGBA_inverse']is True and finite['owner_id']=='finish_i_gate_east_supply'and finite['source_first']==finite['source_final'],'EXACT_GATE_REAR_ACTUAL')
  id='ch4_s0_luoyang_gate';row=binding['scenes'][id];need(row['trial']['path']==self.inputs['trial']['path']and row['trial']['sha256']==self.inputs['trial']['sha256']and row['required_source_sha256'].get(self.inputs['trial']['path'])==self.inputs['trial']['sha256']and row['payload']==finite['payload']and row['fingerprints']==finite['fingerprints'],'ROOT08_AND_GATE_PAYLOAD_BOUND')
  need(all(binding['scenes'][key]==prior_binding['scenes'][key]for key in binding['scenes']if key!=id),'OTHER_SEVEN_BIND_ROWS_IDENTICAL')
  manifest=self.read_json_input('region_manifest');need(manifest.get('adoption_enabled')is True and manifest.get('schema')=='REGION27D_RUNTIME_MANIFEST_V1'and len(manifest['compiled_bindings'])==9,'EXACT_REGION_MANIFEST')
  for p,h in manifest['runtime_modules'].items():need(p not in self.parents,'NO_REGION_MANIFEST_CANONICAL_TARGET_HASH_CYCLE');self.verify_leaf(p,h)
  for item in manifest['compiled_bindings'].values():need(len(self.read(item['path'],item['sha256']))==item['bytes'],'EXACT_REGION_COMPILED_BINDING')
  self.read(manifest['author']['path'],manifest['author']['sha256'])
  for p,h in self.read_json_input('region_declarations')['source_sha256'].items():self.verify_leaf(p,h)
''' + text[end:]
text = text.replace("'CONTRACT_TYPED_RAW_TWO_LITERAL_FULL_INVERSE'", "'CONTRACT_TYPED_RAW_THREE_LITERAL_FULL_INVERSE'")
start = text.index("  receipt=dict(status="); end = text.index("\n  self.output('receipt.json'", start)
old = text[start:end]
base_start = old.index("source_baseline='"); base_end = old.index("',no_engine", base_start)
new_baseline = "Current01656 Root08 successor. All old277 proof values and ten owned domains retained, plus7=284 with exactly five real owned successors. Gate supply rear/opaque child is the only legacy payload change. New continuous Civic, Estate/Temple and six rooms consume independent immutable bins and fixed logical business contexts. CT26/Temple196 prospective pins stay exact. Router template seal and Field Gate hunk are implementation candidates, not Field/art/performance acceptance. No old geometry or import repeated."
old = old[:base_start] + "source_baseline='" + new_baseline + old[base_end:]
text = text[:start] + old + text[end:]
text = text.replace("status='GARDEN_ESTATE_SOURCE_EXACT32_STAGED_NOT_DEPLOYED'", "status='ROOT08_REGION_GATE_EXACT32_STAGED_NOT_DEPLOYED'")
text = text.replace('PINNED_CURRENT_CE38_MAP_PARENT', 'PINNED_CURRENT_01656_MAP_PARENT')
text = text.replace('ROOT_ACTUAL_CE38_BACKUP32', 'ROOT_ACTUAL_01656_BACKUP32')
first_line, rest = text.split('\n', 1)
text = '"""Root-only current01656 exact32 Region/Gate integration. Mature strict source gates, no engine/import/canonical writes."""\n' + rest
compile(text, 'stage_region_integration32_ROOT_ONLY.py', 'exec')
driver = emit(S / 'stage_region_integration32_ROOT_ONLY.py', text.encode())
old_input_path = S / 'garden_estate_exit_repair_20261027c01/source_input_garden_estate32_ROOT_REVIEW02.json'
spec = json.loads(old_input_path.read_bytes())
bundle_path = O / 'unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'
bundle = json.loads(bundle_path.read_bytes())
code = json.loads((G / bundle['code_proof']['path'][6:]).read_bytes())
seal = json.loads((G / bundle['seal']['path'][6:]).read_bytes())
replace_inputs = {'driver': driver, 'candidates': pin(bundle_path), 'scope': pin(O / 'current_01656_exact32_scope_PREPARATION.json'), 'backup': pin(O / 'current_01656_backup32_ROOT_ACTUAL.json'), 'code': bundle['code_proof'], 'execution': code['execution']['candidate'], 'trial': seal['Root_trial'], 'parent_stage': bundle['parent_stage'], 'seal': bundle['seal'], 'local_publication': seal['Gate_rear_publication']}
for row in spec['pinned_inputs']:
    if row['id'] in replace_inputs: row.update(replace_inputs[row['id']])
spec['pinned_inputs'] += [{'id': 'region_manifest', **seal['region_manifest']}, {'id': 'region_declarations', 'path': args.region_declarations, 'sha256': args.region_declarations_sha256}]
spec['declared_candidates'] = {r['target']: r['candidate'] for r in bundle['targets']}
for gate in spec['required_gates']:
    if gate['id'] == 'root_target_preauthorization': gate['pointer'] = ['root_authorized']
spec['output_root'] = 'res://build/luoyang_city_finish_20261025i_source01/outputs/root_region_integration_exact32_stage01/'
spec['blockers'] = []
inp = emit(O / 'source_input_region32_ROOT_REVIEW.json', enc(spec))
print(json.dumps({'driver': driver, 'input': inp, 'Stage_executed': False, 'canonical_writes': 0}))
