"""Mechanical thin exact33 driver; frozen8DE0 core and strict original gates."""
from pathlib import Path
import hashlib,json,difflib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261024e_source01/'
parent='res://build/luoyang_city_revision_20261024c_source01/driver_path_residual03/stage_courts_scholar30_residual03_NOTREADY.py'
old=(GAME/parent[6:]).read_bytes();oldsha=hashlib.sha256(old).hexdigest()
assert oldsha=='9b2675b3c04eb416e5fc338baa0118df3ae6d6f6494015b6426003b78641d744'
text=old.decode();edits=[]
def change(a,b):
    global text
    assert text.count(a)==1,(a[:90],text.count(a));i=len(text[:text.index(a)].encode());text=text.replace(a,b,1);edits.append(dict(byte_offset_at_step=i,old=a,new=b))
change('GAME = Path(__file__).resolve().parents[3]','GAME = Path(__file__).resolve().parents[2]')
change("PREFIX = 'res://build/luoyang_city_revision_20261024c_source01/'","PREFIX = 'res://build/luoyang_city_revision_20261024e_source01/'")
a=text.index("        need(backup['status']");b=text.index("        need(backed == self.oldtargets",a)
change(text[a:b],'''        need(backup['status'] == 'EXACT33_FIXED_PARENT_BACKED_UP_NO_CANONICAL_WRITES'
             and backup['count'] == len(backup['targets']) == 33
             and backup['scope_sha256'].lower() == self.inputs[c['scope_input']]['sha256'].lower(), 'ROOT_D09FC_EXACT33_TARGETS_SCHEMA')
        backed = {}
        for row in backup['targets']:
            p, h, bp = row['target'], row['sha256'].lower(), Path(row['backup']).resolve()
            need(p in self.oldtargets and p not in backed and h == self.oldtargets[p]
                 and bp.is_relative_to(res(c['Root_backup_prefix']).resolve()), 'EXACT33_BACKUP_PATH_DOMAIN')
            b = self.read('res://' + bp.relative_to(M.ROOT).as_posix(), h)
            need(b == self.read(p, h) and len(b) == row['bytes'], 'EXACT33_FULL_OLD_BYTES')
            backed[p] = h
''')
a=text.index("            forward, inverse = before.decode('utf8')");b=text.index("        prior =",a)
change(text[a:b],'''            forward, inverse = before.decode('utf8'), after.decode('utf8')
            for h in row['hunks']:
                need(forward.count(h['old']) == 1, 'UNIQUE_WHOLEBYTE_FORWARD_HUNK')
                forward = forward.replace(h['old'], h['new'], 1)
            for h in reversed(row['hunks']):
                need(inverse.count(h['new']) == 1, 'UNIQUE_WHOLEBYTE_INVERSE_HUNK')
                inverse = inverse.replace(h['new'], h['old'], 1)
            need(forward.encode('utf8') == after and inverse.encode('utf8') == before, 'CODE_FULL_FORWARD_AND_INVERSE')
''')
a=text.index("            shortcut_member =");b=text.index("            restored['owned'][p]",a)
change(text[a:b],'''            record, edge = self.codes[p], new['edges'][-1]
            need(len(new['edges']) == len(old['edges']) + 1 and same(new['edges'][:-1], old['edges'])
                 and edge['old_sha256'] == old['current_sha256'] == record['parent']['sha256']
                 and edge['new_sha256'] == new['current_sha256'] == record['candidate']['sha256']
                 and edge['new_snapshot'] == record['candidate']['path'] and same(edge['replacements'], record['hunks']), 'EXACT_EXISTING_MEMBER_APPENDED_BYTE_EDGE')
''')
for a,b in [
 ('len(self.oldtargets) == 30','len(self.oldtargets) == 33'),("sum(p.endswith('.gd') for p in self.oldtargets) == 15","sum(p.endswith('.gd') for p in self.oldtargets) == 18"),('len(self.codes) == 7','len(self.codes) == 10'),('len(changed) == 5','len(changed) == 7'),("len(prior['source_sha256']) == 132 and len(self.authority['source_sha256']) == 139","len(prior['source_sha256']) == 139 and len(self.authority['source_sha256']) == 148"),
 ("len(delta) == 2 and {tuple(d['pointer']) for d in delta} == {('source_sha256','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'),('source_sha256','res://scripts/field/field_walkable_controller.gd')}","len(delta) == 3 and {tuple(d['pointer']) for d in delta} == {('source_sha256','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'),('source_sha256','res://scripts/field/field_walkable_controller.gd'),('source_sha256','res://scripts/autoload/scene_router.gd')}"),
 ("len(expected) == len(self.spec['pass_through_targets']) == 8","len(expected) == len(self.spec['pass_through_targets']) == 11"),('len(self.targets) == 30','len(self.targets) == 33'),('len(copies) == 15 and len(reconstruction) == 30','len(copies) == 15 and len(reconstruction) == 33'),('dict(patch_count=15,copy_count=15,total=30)','dict(patch_count=18,copy_count=15,total=33)'),('targets=30,map_nodes=4','targets=33,map_nodes=4'),("status='YAMEN_COURTS_SCHOLAR_EXACT30_STAGED_NOT_DEPLOYED'","status='MARKET_BLOCKS_PREWARM_EXACT33_STAGED_NOT_DEPLOYED'")]:change(a,b)
needle="        self.binding = self.read_json_input(c['space_binding_input'])"
change(needle,'''        self.blocks_binding = self.read_json_input(c['blocks_binding_input'])
        need(self.blocks_binding['ready'] is True and self.blocks_binding['status'] == 'MARKET24E_SOURCE_BOUND_BLOCK_OVERLAY_READY'
             and len(self.blocks_binding['required_source_sha256']) == 27
             and self.blocks_binding['local_art']['scope'] == 'SOURCE_ASSET_AND_AUTHORED_LAYOUT_FIELD_TRIAL_ONLY'
             and self.blocks_binding['local_art']['actual_Field_ART_pending'] is True, 'EXACT_BLOCKS27_LIMITED_TRIAL_SOURCE_CONTRACT')
        self.binding = self.read_json_input(c['space_binding_input'])''')
needle="                part, proof = M._strict_lf_build_file_patch(res(target['target']).as_posix(),before,candidate)"
change(needle,'''                if target['target'] == 'res://scripts/autoload/scene_router.gd':
                    transport = self.contract['Router_exact_EOL_transport']
                    need(target['old_sha256'] == transport['old_sha256'] and target['candidate_sha256'] == transport['candidate_sha256']
                         and before.count(b'\\r') == candidate.count(b'\\r') == 13
                         and before.count(b'\\r\\n') == candidate.count(b'\\r\\n') == 13, 'SOLE_FIXED_ROUTER_RAW_EOL_DOMAIN')
                    before_shadow, after_shadow = before.replace(b'\\r\\n',b'\\n'), candidate.replace(b'\\r\\n',b'\\n')
                    need(sha(after_shadow) == transport['LF_shadow_sha256'] and len(after_shadow) == transport['LF_shadow_bytes'], 'EXACT_ROUTER_LF_SHADOW')
                    part, proof = M._strict_lf_build_file_patch(res(target['target']).as_posix(),before_shadow,after_shadow)
                    proof = dict(kind='ExactRouterLFShadowAndApprovedRawEOLRestore',strict_shadow_proof=proof,
                                 old_raw_sha256=sha(before),candidate_raw_sha256=sha(candidate),candidate_raw_bytes=len(candidate),
                                 LF_shadow_sha256=sha(after_shadow),LF_shadow_bytes=len(after_shadow),
                                 mechanical_restoration='Only after normalizeLF(actual)==normalizeLF(approvedCandidate), restore exact approved raw candidate EOL. No semantic or source normalization authority.')
                else:
                    part, proof = M._strict_lf_build_file_patch(res(target['target']).as_posix(),before,candidate)''')
compile(text,'stage_market_blocks33_NOTREADY.py','exec')
back=text.encode()
for e in reversed(edits):
    i=e['byte_offset_at_step'];a,b=e['old'].encode(),e['new'].encode();assert back[i:i+len(b)]==b;back=back[:i]+a+back[i+len(b):]
assert back==old
core=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py';assert core.is_file() and hashlib.sha256(core.read_bytes()).hexdigest()=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
out=HERE/'stage_market_blocks33_NOTREADY.py';assert not out.exists();raw=text.encode()
with out.open('xb') as f:f.write(raw)
proof=dict(status='EXACT33_DRIVER_MECHANICAL_BYTE_INVERSE_NOT_RUN',parent=dict(path=parent,sha256=oldsha),candidate=dict(path=S+out.name,sha256=hashlib.sha256(raw).hexdigest()),edits=edits,wholebyte_forward_inverse=True,core_resolved=core.as_posix(),unchanged_core_sha256=hashlib.sha256(core.read_bytes()).hexdigest(),engine_calls=0,Stage_calls=0,canonical_writes=0)
rawproof=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();pp=HERE/'stage33_driver_inverse_BUILD.json'
with pp.open('xb') as f:f.write(rawproof)
print(json.dumps(dict(driver=proof['candidate'],proof_path=S+pp.name,proof_sha256=hashlib.sha256(rawproof).hexdigest())))
