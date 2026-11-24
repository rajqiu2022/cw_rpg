"""Independent actual text/patch/owner recipe audit, no producer re-execution."""
import copy,hashlib,json,pathlib
G=pathlib.Path(__file__).resolve().parents[2]
P='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
R='res://build/luoyang_city_full_rollout_20261022ap_root01/'
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
ART='luoyang_artisan_residential_20261022ap';GAR='luoyang_riverside_garden_20261022ap';MAR='ch4_s3_luoyang_market'
def path(p):return G/p[6:]
def raw(p):return path(p).read_bytes()
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h=None):
    b=raw(p)
    if h:need(sha(b)==h,'FIXED_SMALL_FILE_SHA:'+p)
    return json.loads(b)
def need(v,msg):
    if not v:raise AssertionError(msg)
def same(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
def ptr(v,keys):
    for k in keys:v=v[k]
    return v
def restore(v,changes):
    for d in reversed(changes):
        holder=ptr(v,d['pointer'][:-1]);k=d['pointer'][-1]
        if d['existed']:holder[k]=copy.deepcopy(d['old'])
        else:del holder[k]
def merge(*tables):
    out={}
    for t in tables:
        for p,h in t.items():need(p not in out or out[p]==h,'SOURCE_COLLISION:'+p);out[p]=h
    return out
rp=P+'outputs/root_unified_life_garden_scholar28_stage01/receipt.json'
actual=read(rp,'4ce21902185a78f6c441f8ee8d63d30b30a7c31c61f135b5df13322bc266d945')
plan=read(R+'integration62/source_input100_READY.json','f432b6fc25a06e8be2b510b9ef2523972aaf6da2ef5e824b987a3aa8ca257fcc')
old=read(P+'performance95_Docks_ordinary21_actual_independent_review/owner_source_maps_READY.json','c3b7c23523fd8d913cb21a57e72e3c07340a7d948017b67139e31d6088ba60cb')
ownerpath=P+'unified101_actual_owner_READY/owner_source_maps_READY.json'
owner=read(ownerpath,'fd58f7c2dbd3372d6adbb6f9a39ba7c70568125e4f843c11dc546e750fdfd61c')
review=read(P+'unified101_actual_owner_READY/source_stage_review_READY.json','8ecb5747496fd76ced0ab494b5ecb62873e467fecea9be1eaa0f27d63815cb76')
pins={r['id']:r for r in plan['pinned_inputs']};c=plan['life_contract']
def inp(i):return read(pins[i]['path'],pins[i]['sha256'])
scope=inp(c['scope_input']);backup=inp(c['backup_input']);binding=inp(c['binding_input'])
need(actual['source_first']==actual['source_final'] and len(actual['source_first'])==3083,'DECLARED3083_FIRST_FINAL_NO_REHASH')
need(actual['source_first'][R+'integration62/source_input100_READY.json']==sha(raw(R+'integration62/source_input100_READY.json')),'READY_INPUT_IN_ACTUAL_FIRST_FINAL')
need(actual['target_partition']=={'patch_count':14,'copy_count':14,'total':28,'intersection_empty':True,'union_exact_targets':True},'EXACT14PATCH14COPY')
targets={r['target']:r for r in actual['targets']};saved={r['res_path']:r for r in backup['targets']}
need(len(targets)==28 and set(targets)==set(saved)==set(plan['root_target_allowlist'])=={r['target']for r in scope['targets']},'EXACT28_SCOPE_SET')
before={};after={}
for p,t in targets.items():
    need(t['old_sha256']==saved[p]['old_sha256']==old['core_source_sha256'][p] and t['old_sha256']!=t['candidate_sha256'],'OLD28_FROM_OWNER95_AND_BACKUP')
    before[p]=pathlib.Path(saved[p]['backup_path']).read_bytes();after[p]=raw(t['candidate_path'])
    need(sha(before[p])==t['old_sha256'] and sha(after[p])==t['candidate_sha256'],'SMALL_TARGET_BYTES')
    need(sha(raw(p))==t['old_sha256'],'CURRENT_FORMAL_STILL_ORIGINAL_BEFORE_DEPLOY')
nodes=actual['nodes'];typed=[];indexes=[];maps={}
for n in plan['nodes']:
    ident=n['id'];kind=n['kind'];node=nodes[ident]
    if kind in ('metadata','life_quarter','life_contract'):
        v=copy.deepcopy(node['value']);restore(v,actual['proofs'][ident].get('exact_life_declaration_delta',[]));restore(v,actual['proofs'][ident]['source_delta'])
        need(same(v,inp(n['base_input'])),'COMPLETE_METADATA_TYPED_INVERSE:'+ident)
        need(same(read(node['path'],node['sha256']),node['value']),'METADATA_ACTUAL_FILE_VALUE:'+ident)
        typed.append(ident)
    elif kind=='index':
        b=raw(pins[n['base_input']]['path']);disabled=b.decode('utf-8');changes=[]
        for h in n['replacements']:
            new=h['new']
            if isinstance(new,dict):new=nodes[new['$sha']]['sha256']if'$sha'in new else pins[new['$pin']]['sha256']
            need(disabled.count(h['old'])==1,'INDEX_SINGLE_LITERAL');disabled=disabled.replace(h['old'],new,1);changes.append((h['old'],new))
        need(sha(disabled.encode())==actual['proofs'][ident]['disabled_sha256'],'INDEX_DISABLED_SHA')
        need(disabled.count(n['disabled_literal'])==1 and disabled.replace(n['disabled_literal'],n['enabled_literal'],1).encode()==raw(node['path']),'INDEX_FULL_ENABLED_CANDIDATE_BYTES')
        inverse=disabled
        for a,z in reversed(changes):need(inverse.count(z)==1,'INDEX_REVERSE_SINGLE');inverse=inverse.replace(z,a,1)
        need(inverse.encode()==b,'INDEX_FULL_BYTE_INVERSE');indexes.append(ident)
    elif kind=='map':maps[n['scene_id']]=read(node['path'],node['sha256'])['source_sha256']
    elif kind in ('life_frozen','life_fixed_code'):
        need(node['sha256']==pins[n['base_input']]['sha256']and'target'not in n,'FROZEN_NODE_NO_EXTRA_TARGET')
need(len(typed)==13 and len(indexes)==8 and len(maps)==4,'13METADATA8INDEX4MAP')

# Literal-context patch reconstruction independent of the producer patch utility.
patch=raw(actual['patch_path']);need(sha(patch)==actual['patch_sha256'],'ACTUAL_PATCH_SHA')
sections={};current=None;oldlines=[];newlines=[]
def flush():
    if oldlines or newlines:
        sections[current].append((''.join(oldlines),''.join(newlines)));oldlines.clear();newlines.clear()
for line in patch.decode('utf-8').splitlines(True):
    if line.startswith('*** Update File: '):
        flush();absolute=pathlib.Path(line[len('*** Update File: '):].strip()).resolve();current='res://'+absolute.relative_to(G).as_posix();need(current not in sections,'PATCH_UNIQUE_PATH');sections[current]=[]
    elif line.startswith('@@'):flush()
    elif line.startswith(('*** Begin Patch','*** End Patch')):flush()
    elif line.startswith('***'):raise AssertionError('UNEXPECTED_PATCH_DIRECTIVE')
    elif line[:1]in(' ','+','-'):
        if line[0]!='+':oldlines.append(line[1:])
        if line[0]!='-':newlines.append(line[1:])
    else:raise AssertionError('PATCH_LINE')
flush()
def replay(b,chunks,reverse=False):
    v=b.decode('utf-8')
    for a,z in ([(z,a)for a,z in reversed(chunks)]if reverse else chunks):
        need(v.count(a)==1,'UNIQUE_LITERAL_PATCH_CONTEXT');v=v.replace(a,z,1)
    return v.encode('utf-8')
need(set(sections)=={p for p in targets if p.endswith('.gd')}and len(sections)==14,'ONLY14_GD_PATCHES')
for p,chunks in sections.items():need(replay(before[p],chunks)==after[p] and replay(after[p],chunks,True)==before[p],'PATCH_COMPLETE_FORWARD_INVERSE:'+p)
copyplan=read(actual['byte_copy_plan']['path'],actual['byte_copy_plan']['sha256'])
need(len(copyplan['rows'])==14 and{r['target']for r in copyplan['rows']}=={p for p in targets if p.endswith('.json')},'EXACT14_JSON_COPY_DISJOINT')
for r in copyplan['rows']:need(r['candidate_path']==targets[r['target']]['candidate_path']and r['candidate_sha256']==sha(after[r['target']])and r['candidate_bytes']==len(after[r['target']]),'COPY_EXACT_WHOLE_BYTES')

authority=inp(plan['authority_input']);parent=inp(c['parent_execution_input'])
extra={p:s for p,s in authority['source_sha256'].items()if p not in parent['source_sha256']}
need(extra==c['proof_extra'] and len(extra)==5 and len(authority['source_sha256'])==101 and after[EXE]==raw(pins[plan['authority_input']]['path']),'ACTUAL_AUTHORITY101_EXACT_PREVIOUS_STATIC_REVIEW')
def migrate(table):
    v=copy.deepcopy(table)
    for p,t in targets.items():
        if p in v:need(v[p]==t['old_sha256'],'INDEPENDENT_PRIOR_OLD_VALUE');v[p]=t['candidate_sha256']
    return v
expected=copy.deepcopy(old)
expected['actual_stage_receipt']={'path':rp,'sha256':sha(raw(rp))};expected['fixed_prior_owner_sha256']=sha(raw(P+'performance95_Docks_ordinary21_actual_independent_review/owner_source_maps_READY.json'))
counts={}
for family in ('scenes','rooms'):
    need(len(old[family])==len(owner[family])==(8 if family=='scenes'else 5),'FULL8SCENE5ROOM')
    for row,prior in zip(expected[family],old[family]):
        for f in ('source_sha256','receipt_source_sha256'):
            added=extra if EXE in prior[f]else{}
            if row['id']in(ART,GAR,MAR):added=merge(added,c['life_sources'],c['garden_sources'])
            if row['id']==MAR:added=merge(added,c['scholar_sources'])
            row[f]=merge(migrate(prior[f]),added)
        if row['id']in maps:need(row['source_sha256']==row['receipt_source_sha256']==maps[row['id']],'FOURMAP_FULL_INDEPENDENT_EXPECTED')
        if row['id']==ART:
            row['scene_path']=binding['child']['scene.res']['path'];row['layout_path']=binding['child']['layout.res']['path']
        if family=='rooms':need(row['receipt_source_sha256']==prior['receipt_source_sha256']and len(row['source_sha256'])==573,'FIVE_RECEIPTS_UNCHANGED_G573')
        else:counts[row['id']]={'collector':len(row['source_sha256']),'receipt':len(row['receipt_source_sha256'])}
expected['core_source_sha256']=migrate(old['core_source_sha256'])
expected['metadata_fields_not_invented']='Fixed owner95+exact28 candidate values; execution API consumers add only five fixed proof keys; shared Quarter/Market additionally inherit fixed life binding source leaves and Garden shader; scholar three leaves Market-only. Artisan scene/layout paths move to fixed Root59 published child; old A2/Garden/other native history and all five room receipt dictionaries unchanged. No collector/current fill.'
need(same(expected,owner),'ENTIRE_FD58_OWNER8SCENE5ROOM_CORE_EXACT_FIXED_RECIPE')
quarter=nodes['quarter_final']['value'];prior_quarter=inp(next(n for n in plan['nodes']if n['id']=='quarter_final')['base_input'])
need(quarter['scenes'][GAR]==prior_quarter['scenes'][GAR] and quarter['a2_artisan_successor']==prior_quarter['a2_artisan_successor'],'GARDEN_NATIVE_AND_A2_DECLARATION_PRESERVED')
for field,suffix in [('scene_path','scene.res'),('layout_path','layout.res'),('packet_path','packet.bin')]:need(quarter['scenes'][ART][field]==binding['child'][suffix]['path'],'ARTISAN_ONLY_CHILD3_PATHS')
for suffix,leaf in binding['child'].items():need(quarter['source_sha256'][leaf['path']]==leaf['sha256'],'ALL4_CHILD_DECLARED_WITH_NEW_MASK')
for p,s in c['scholar_sources'].items():
    need(quarter['source_sha256'].get(p)is None,'SCHOLAR_NOT_IN_QUARTER_SHARED_DOMAIN')
    for row in owner['scenes']:
        if p in row['source_sha256']:need(row['id']==MAR and row['source_sha256'][p]==s,'SCHOLAR_MEDIA_MARKET_ONLY')
oldunion=merge(*(r[f]for r in old['scenes']+old['rooms']for f in('source_sha256','receipt_source_sha256')))
union=merge(*(r[f]for r in owner['scenes']+owner['rooms']for f in('source_sha256','receipt_source_sha256')))
need(set(union)==set(oldunion)|set(extra)|set(c['life_sources'])|set(c['garden_sources'])|set(c['scholar_sources']),'EXACT_UNION_DECLARATION_KEYS')
classes={'target':0,'actual_stage_declaration':0,'fixed95_inherited_not_rehashed':0}
for p,s in union.items():
    if p in targets:need(s==targets[p]['candidate_sha256'],'UNION_TARGET_VALUE');classes['target']+=1
    elif p in actual['source_first']:need(s==actual['source_first'][p],'UNION_STAGE_DECLARATION');classes['actual_stage_declaration']+=1
    else:need(s==oldunion[p],'UNION_FIXED95_INHERITED');classes['fixed95_inherited_not_rehashed']+=1
out={'status':'INDEPENDENT_ACTUAL100_AND_FD58_COMPLETE_OWNER_TEXT_REVIEW_NO_DEPLOYMENT_BLOCKER_NOT_RUNTIME_PASS',
 'actual_stage_SHA':sha(raw(rp)),'owner_SHA':sha(raw(ownerpath)),'Source_review_SHA':sha(raw(P+'unified101_actual_owner_READY/source_stage_review_READY.json')),
 'target_partition':actual['target_partition'],'13metadata_whole_typed_inverse':typed,'8indices_whole_byte_inverse':indexes,'14GD_patch_whole_forward_reverse':True,'14JSON_exact_copy_partition':True,
 '3083_source_FIRST_FINAL_declarations_same_no_rehash':True,'28_current_formal_text_targets_still_fixed_old_SHA':True,
 'entire_owner_8scenes5rooms_core_fixed95_plus_approved_delta':True,'core_count':len(owner['core_source_sha256']),'scene_counts':counts,
 'G_full_source_count':573,'all_five_room_receipt_dictionaries_whole_same':True,'execution101_three_new_edges_only_inherited_static':True,
 'Artisan_13631_new_child4_and_mask_declared_Garden_native_row_and_A2_preserved':True,'scholar3_only_Market1741_sharedQuarter341339':True,
 'union':{'old_count':len(oldunion),'new_count':len(union),**classes},
 'unchanged':'Registry/DT/G/C/AA/AC/Router and original native artifacts are not targets. No old3016/3083 files rehashed, no native decode or collector. Stage permission does not prove Field/ghost/ART or clean loading.',
 'QA_actions':{'Stage':False,'owner_builder_rerun':False,'engine':False,'collector':False,'packet_PNG_decode':False,'media_hash':False,'formal_write':False}}
print(json.dumps(out,ensure_ascii=False,indent=2))

