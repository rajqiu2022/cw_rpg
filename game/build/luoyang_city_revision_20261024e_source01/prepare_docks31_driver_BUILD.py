"""Mechanical thin31 compiler construction; no compiler import or execution."""
from pathlib import Path
import hashlib,json,ast,difflib
HERE=Path(__file__).resolve().parent;S='res://build/luoyang_city_revision_20261024e_source01/'
parent=HERE/'stage_prewarm_profile29_NOTREADY.py';a=parent.read_bytes();assert hashlib.sha256(a).hexdigest()=='b0b6ad4fd5e6db7120c77446a8f9e72af44b7ecac48096cca7f51c269bd40761'
s=a.decode()
repls=[
 ('Root-only exact29 SOURCE_ONLY compiler','Root-only exact31 Docks SOURCE_ONLY compiler'),
 ('fixed_prewarm_profile29_core','fixed_docks31_core'),('PrewarmProfileStage','DocksFrontageStage'),
 ("c=spec['prewarm_contract']","c=spec['docks_contract']"),('ROOT29_EXACT_LOCK_REQUIRED','ROOT31_EXACT_LOCK_REQUIRED'),
 ("len(self.oldtargets)==29","len(self.oldtargets)==31"),("sum(p.endswith('.gd') for p in self.oldtargets)==15","sum(p.endswith('.gd') for p in self.oldtargets)==16"),('EXACT29_15GD14JSON_DOMAIN','EXACT31_16GD15JSON_DOMAIN'),
 ('EXACT29_CURRENT_D596_PARENT_BACKED_UP_NO_CANONICAL_WRITES','EXACT31_CURRENT_FE154_PARENT_BACKED_UP_NO_CANONICAL_WRITES'),("==len(backup['targets'])==29","==len(backup['targets'])==31"),('ROOT_A235_ACTUAL_SCHEMA','ROOT_745E_ACTUAL_SCHEMA'),
 ('EXACT29_BACKUP_TARGET_AND_PREFIX','EXACT31_BACKUP_TARGET_AND_PREFIX'),('EXACT29_FULL_OLD_BYTES','EXACT31_FULL_OLD_BYTES'),('EXACT29_FULL_BACKUP_COVERAGE','EXACT31_FULL_BACKUP_COVERAGE'),
 ("len(self.codes)==7","len(self.codes)==8"),('EXACT7_APPROVED_LITERAL_CODE_SUCCESSORS','EXACT8_APPROVED_FUNCTIONAL_AND_LITERAL_SUCCESSORS'),
 ("len(changed)==4","len(changed)==6"),('ONLY4_EXISTING_OWNED_MEMBERS_CHANGE','ONLY6_EXISTING_OWNED_MEMBERS_CHANGE'),('OTHER6_OWNED_ROWS_WHOLE_TYPED_SAME','OTHER4_OWNED_ROWS_WHOLE_TYPED_SAME'),
 ("len(prior['source_sha256'])==148 and len(self.authority['source_sha256'])==154 and len(extra)==6","len(prior['source_sha256'])==154 and len(self.authority['source_sha256'])==162 and len(extra)==8"),('OLD148_EXACT6_NEW_PROOF_LEAVES','OLD154_EXACT8_NEW_PROOF_LEAVES'),
 ("len(self.parent_maps['expected_ch4_s3_luoyang_market_true'])==1853","len(self.parent_maps['expected_ch4_s3_luoyang_market_true'])==1862"),('FIXED_D596_FOUR_PARENT_MAPS','FIXED_FE154_FOUR_PARENT_MAPS'),
 ('FIXED_D596_MAP_OLD_VALUE','FIXED_FE154_MAP_OLD_VALUE'),('INDEPENDENT_D596_PLUS_EXACT_DECLARED_DELTAS','INDEPENDENT_FE154_PLUS_EXACT_DECLARED_DELTAS'),
 ("len(self.spec['pass_through_targets'])==8","len(self.spec['pass_through_targets'])==9"),('EXACT7_CODE_PLUS_EXEC_PASSTHROUGH','EXACT8_CODE_PLUS_EXEC_PASSTHROUGH'),
 ("len(self.targets)==29","len(self.targets)==31"),('EXACT29_TARGET_SET','EXACT31_TARGET_SET'),
 ("len(copies)==14 and len(reconstruction)==29","len(copies)==15 and len(reconstruction)==31"),('STRICT15_GD_PATCH_EXACT14_JSON_COPY','STRICT16_GD_PATCH_EXACT15_JSON_COPY'),
 ('PREWARM8_PROFILE04_EXACT29_STAGED_NOT_DEPLOYED','DOCKS_FRONTAGES_EXACT31_STAGED_NOT_DEPLOYED'),
 ('target_count=14','target_count=15'),('patch_count=15,copy_count=14,total=29','patch_count=16,copy_count=15,total=31'),('targets=29,map_nodes=4','targets=31,map_nodes=4')]
for x,y in repls:
    assert x in s,x;s=s.replace(x,y)
start=s.index("        if kind=='prewarm_estate_one':")
end=s.index('        super().build_node(row)',s.index("del self.inputs[temp];del self.input_bytes[temp];return",start))
s=s[:start]+s[end:]
needle="        if kind=='map':\n"
assert s.count(needle)==1
s=s.replace(needle,"""        if ident=='registry_final':
            dt='res://scripts/city/luoyang_district_life_20261016f.gd'
            ops=row['operations'];base=self.read_json_input(row['base_input'])
            need(len(ops)==5 and len({tuple(op['pointer']) for op in ops})==5 and all(op['op']=='set' and op['existed'] is True and len(op['pointer'])==4 and op['pointer'][0]=='rooms' and op['pointer'][2:]==['source_sha256',dt] and op['old']==self.oldtargets[dt] and self.value(op['new'])==self.codes[dt]['candidate']['sha256'] for op in ops),'REGISTRY_EXACT_FIVE_EXISTING_DT_VALUES_ONLY')
            need(len(base['rooms'])==len(self.nodes[ident]['value']['rooms'])==12,'REGISTRY_TWELVE_ROWS_UNCHANGED')
        if ident=='estate_final':
            base=self.read_json_input(row['base_input']);value=self.nodes[ident]['value']
            need(row['kind']=='metadata' and row['source_policy']=='estate_legacy' and row['protected_pointers']==[['registry_path'],['geometry_receipt'],['publication_receipt']],'ESTATE_ONLY_FIXED_REGISTRY_SHA_NOT_PROTECTED')
            need(set(value['source_sha256'])==set(base['source_sha256']) and value['registry_path']==REGISTRY and value['registry_sha256']==value['source_sha256'][REGISTRY]==self.nodes['registry_final']['sha256'],'ESTATE_FIXED_KEYS_AND_THREE_EQUAL_NEW_REGISTRY')
        if kind=='map':
""")
b=s.encode();ast.parse(s);assert 'prewarm_estate_one' not in s
dest=HERE/'stage_docks_frontages31_NOTREADY.py';assert not dest.exists();dest.write_bytes(b)
patch=[];al=a.decode().splitlines(keepends=True);bl=s.splitlines(keepends=True)
for tag,i,j,k,l in difflib.SequenceMatcher(None,al,bl,autojunk=False).get_opcodes():
    if tag!='equal':patch.append(dict(old_offset=len(''.join(al[:i]).encode()),new_offset=len(''.join(bl[:k]).encode()),old=''.join(al[i:j]),new=''.join(bl[k:l])))
f,v=a,b
for r in reversed(patch):
    x,y=r['old'].encode(),r['new'].encode();i,j=r['old_offset'],r['new_offset'];assert f[i:i+len(x)]==x and v[j:j+len(y)]==y;f=f[:i]+y+f[i+len(x):];v=v[:j]+x+v[j+len(y):]
assert f==b and v==a
pr=dict(status='DOCKS31_THIN_DRIVER_WHOLE_BYTE_INVERSE_NOT_EXECUTED',parent=dict(path=S+parent.name,sha256=hashlib.sha256(a).hexdigest()),driver=dict(path=S+dest.name,sha256=hashlib.sha256(b).hexdigest()),offset_byte_patch=patch,full_forward_inverse=True,Python_AST_only=True,Stage_imports=0,Stage_executions=0,canonical_writes=0)
raw=(json.dumps(pr,ensure_ascii=False,indent=2)+'\n').encode();out=HERE/'docks31_driver_whole_inverse_NOT_EXECUTED.json';assert not out.exists();out.write_bytes(raw)
print(json.dumps(dict(driver=pr['driver'],proof=dict(path=S+out.name,sha256=hashlib.sha256(raw).hexdigest()))))
