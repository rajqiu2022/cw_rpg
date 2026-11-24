"""Source handoff after54 NEW media promotion. No canonical writes or engine.

Default freezes PENDING only. Root's explicit trial permission can prepare a
BUILD-only approved manifest + ready module for Source's separate stage. This
is permission to test after staging, never a claimed result or canonical copy.
"""
from pathlib import Path
import argparse,hashlib,json
ROOT=Path(__file__).resolve().parents[2];SELF=Path(__file__).resolve()
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01/world24d_heads01/world18_ingress04'
BASE=OUT.parent
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def new(p,b):
    assert not p.exists(),p;p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as h:h.write(b)
def res(p):return 'res://'+p.relative_to(ROOT/'game').as_posix()
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--root-trial-reviewed-builder-sha256');args=ap.parse_args();approved=bool(args.root_trial_reviewed_builder_sha256)
    if approved:assert args.root_trial_reviewed_builder_sha256.lower()==sha(SELF)
    pins={'world18_media54_promotion_ROOT_EXECUTED.json':'c7e9baddb6c94a1b7cd0742041c147f29eb320902eae4e0fa2ea6f4fa191a2f3','world18_media54_promotion_plan_CANDIDATE.json':'bbb7589c1629865de785feacc55df78527b2852832518e12bb7ea225844c9262','actual_joint_export_compact_receipt.json':'6afe7ad022eda99286ed76d1c687c1d9a3cd2ad45b33deec26eec02c4cdc1ffd','actual_joint18_import_compact_proof.json':'b224c4d6c2cd95e9ddef9b4807f456968b4c5b1739f06b809557ff89f491fbfc','approved_visual_manifest_CANDIDATE.json':'59ebaca9077d6a867964b5741f834bc66fde857093856388e2b08af92311799a','world_bridge_shore_visual_override03_NOTREADY.gd':'701fc79e9d11e15a6c98d99c870a3ba9c1fdbe716685e4e75945d72a56381a60'}
    for p,pin in pins.items():assert sha(OUT/p)==pin,p
    promo=read(OUT/'world18_media54_promotion_ROOT_EXECUTED.json');plan=read(OUT/'world18_media54_promotion_plan_CANDIDATE.json')
    assert promo['passed'] is True and len(promo['written'])==54 and promo['all_protected_SHA_bytes_exactticks_unchanged'] is True and promo['functional_GD_JSON_active_index_changed'] is False
    media=[]
    for r in plan['leaves']:
        p=Path(r['target']);assert sha(p)==r['sha256'] and p.stat().st_size==r['bytes']
        media.append({'path':res(p),'sha256':r['sha256'],'bytes':r['bytes'],'kind':r['kind'],'status':'ACTUALLY_CANONICAL_NEW_MEDIA_PRESENT_NOT_RUNTIME_BOUND'})
    assert len(media)==54
    interface=read(OUT/'consumer03_source_interface_NOTREADY.json')
    for r in interface['candidate_hunks']:
        assert sha(ROOT/r['production_target'])==r['old_sha256'] and sha(ROOT/r['candidate'])==r['candidate_sha256']
    sourcepins={'res://data/maps/world_map_v15_complete_v9c_source.json':'85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f','res://data/maps/world_map_jianghu_layout_v15.tres':'aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072','res://data/background_sets/world_map_jianghu_v15_streamed.tres':'3536182ec4eba967e8cd6b5da6b8ca6bb44072022f342d190eb807995a772400','res://scripts/world/world_farmland_visual_patch_resolver_20261015.gd':'4980866c5147eb173959dca506f84d9a7bc860a85ed4c7c41c5ba5abe6eba6de'}
    for p,pin in sourcepins.items():assert sha(ROOT/('game/'+p[6:]))==pin,p
    canonical_module='res://scripts/world/world_bridge_shore_visual_override_20261025i.gd';canonical_approval='res://art/maps/world_bridge_shore_20261025i/approved_visual_manifest.json'
    assert not (ROOT/('game/'+canonical_module[6:])).exists() and not (ROOT/('game/'+canonical_approval[6:])).exists()
    source=read(ROOT/'game/data/maps/world_map_v15_complete_v9c_source.json');walks=[]
    for c in source['chunks']:
        p=c['walk_path'];pin=source['asset_sha256'][p];assert sha(ROOT/('game/'+p[6:]))==pin;walks.append({'path':p,'sha256':pin})
    record={'status':'TRIAL_PERMISSION_NOT_RESULT_BUILD_CANDIDATE_NOT_STAGED' if approved else 'MEDIA54_PROMOTED_SOURCE_ACTIVATION_PENDING_ROOT_APPROVAL','builder_sha256':sha(SELF),'approved':approved,'canonical_writes':0,'engine_calls':0,'54_actual_media':media,'fixed_actual_artifact_sources':[{'path':res(OUT/p),'sha256':pin} for p,pin in pins.items()],'canonical_module':canonical_module,'canonical_approval':canonical_approval,'two_hook_exact_parents_and_candidates':interface['candidate_hunks'],'unchanged_source_pins':sourcepins,'unchanged64walks':walks,'world_stage_scope':'separate World ordinary-source closure only; do not mix city maps or expand OWNED/execution/finite whitelist','new_functional_files':'2 exact hook changes +1 NEW module +1 NEW approved manifest only. Existing54media are already present and unchanged.','ordinary_source_closure_required':'Current World own source contract must bind module/approval/compact import and export proof/their two actual reports/54media with exact identities. Source chooses existing ordinary-source mechanism; do not declare as city runtime_authority or permit source shortcuts.','Web':'all old17 plus oldchunk together','runtime_validation_scope':'one actual World Field context screenshot after final Stage only:18 actual texture bindings and original camera/foot-sort/old12farmland order; zeroINPUT/no17physical or64walk re-test, no loading-performance claim'}
    if approved:
        manifest=read(OUT/'approved_visual_manifest_CANDIDATE.json');assert manifest['approved'] is False and manifest['approved_by'] is None
        manifest['approved']=True;manifest['approved_by']='root';manifest['root_activation_pending']=True
        manifest['permission_status']='TRIAL_PERMISSION_NOT_RESULT'
        manifest['trial_permission_scope']='Only Source unified Stage review; later Root-only deployment and one actual World context screenshot. No canonical write or runtime-result claim from this builder.'
        manifestpath=OUT/'approved_visual_manifest_ROOT_TRIAL_BUILD_ONLY.json';new(manifestpath,enc(manifest));pin=sha(manifestpath)
        original=(OUT/'world_bridge_shore_visual_override03_NOTREADY.gd').read_text(encoding='utf-8');code=original
        pairs=[('const READY: bool=false','const READY: bool=true'),('const APPROVAL_SHA: String=""','const APPROVAL_SHA: String="'+pin+'"')]
        for a,b in pairs:assert code.count(a)==1;code=code.replace(a,b)
        restored=code
        for a,b in reversed(pairs):assert restored.count(b)==1;restored=restored.replace(b,a)
        assert restored==original
        modulepath=OUT/'world_bridge_shore_visual_override_ROOT_TRIAL_BUILD_ONLY.gd';new(modulepath,code.encode())
        record['Root_ready_BUILD_outputs']=[{'source':res(manifestpath),'canonical_target':canonical_approval,'sha256':pin},{'source':res(modulepath),'canonical_target':canonical_module,'sha256':sha(modulepath)}]
        record['exact_module_text_inverse']={'parent_sha256':pins['world_bridge_shore_visual_override03_NOTREADY.gd'],'swaps':[{'old':a,'new':b} for a,b in pairs],'whole_parent_byte_inverse':True}
    target=OUT/('world18_ROOT_TRIAL_source_handoff01.json' if approved else 'world18_promoted_source_PENDING01.json')
    new(target,enc(record));print(json.dumps({'status':record['status'],'handoff_sha256':sha(target),'builder_sha256':sha(SELF),'approved':approved,'actual_media54':54,'canonical_write':0,'engine':0}))
if __name__=='__main__':main()
