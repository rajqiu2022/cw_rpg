"""Fixed ROOT oracle result -> publisher prior. No image/packet/raster/engine access."""
import hashlib, json, struct
from pathlib import Path

BASE=Path(__file__).resolve().parent
GAME=BASE.parents[1]
ROOT=GAME/'build/luoyang_city_revision_20261024c_root01'
RESULT=BASE/'two_domain_native_oracle_READY/project/output_READY/115620_514329/result.json'
PROCESS=ROOT/'yamen_two_domain_oracle_once_process_receipt.json'
INPUT=BASE/'two_domain_native_oracle_READY/input_READY.json'
OUT=BASE/'two_domain_independent_prior_ROOT_ACTUAL_READY'
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p,expected):
    assert digest(p)==expected,(p,digest(p))
    return json.loads(p.read_text(encoding='utf-8'))
def write(name,value):
    p=OUT/name;assert not p.exists(),p
    p.write_bytes((json.dumps(value,ensure_ascii=True,indent=2)+'\n').encode())
    return dict(path=str(p),sha256=digest(p),bytes=p.stat().st_size)

def main():
    r=read(RESULT,'29d1069b9ef67e596b6cffb2eb0a3c4123c4c0b608648c4932edef2eee269ee3')
    p=read(PROCESS,'c3b7b7a362ba641d09c808b5a278fa25c14e1688bda8d2f5ea32538ea27f7a6f')
    i=read(INPUT,'36d4b3506cb6489ead376b9656113713a3c9c055966e568661a68161dd1ef3ab')
    assert r['complete'] is True and r['checks']==425 and r['failures']==0 and r['errors']==[]
    assert r['elapsed_ms']==430 and r['elapsed_ms']<15000
    assert p['exit_code_from_retained_process_WaitForExit'] is True and p['actual_natural_console_exit_code']==0
    assert p['process_stopped_by_tool'] is False and p['elapsed_wall_ms']==1347
    assert p['script_sha256']==p['script_after_sha256']=='a6da60cb367a74daae1da07bff65f2181c65a36af17ea73e26e8e80f5e8ee3dc'
    stderr=Path(p['stderr_path']);stdout=Path(p['stdout_path'])
    assert digest(stderr)==p['stderr_sha256'] and stderr.read_bytes()==b''
    assert digest(stdout)==p['stdout_sha256'] and str(RESULT).replace('\\','/') in stdout.read_text(encoding='utf-8')
    assert r['source_first']==r['source_final'] and len(r['source_first'])==8
    source_by_path={str(Path(k)).lower():v for k,v in r['source_first'].items()}
    for source,expected in i['source_pins'].items(): assert source_by_path[str(Path(source)).lower()]['sha256']==expected
    assert r['domains_closed']==i['domains_closed']
    assert [x['visited'] for x in r['domain_results']]==[87373,118917]
    assert [x['changed_pixels'] for x in r['domain_results']]==[71743,68726]
    assert all(x['old_parent_differences']==0 for x in r['domain_results'])
    assert r['union_visited_pixels']==206290 and r['changed_pixels']==140469
    assert sum(x['changed_pixels'] for x in r['domain_results'])==r['changed_pixels']
    assert r['old_parent_differences']==0 and r['first_old_differences']==[]
    assert r['full_inverse'] is True and r['outside_domain_unchanged_by_construction'] is True
    assert r['parent_RGBA_sha256']==i['parent_RGBA_sha256']
    assert r['full_RGBA_bytes']==3072*2048*4
    assert r['PNG_decode_count']==2 and r['PNG_output_count']==r['packet_decodes']==r['Scene_instances']==r['Field_instances']==r['collector_calls']==0
    assert r['image_facts']==dict(parent_format=5,parent_mipmaps=False,parent_size=[3072,2048],raw_format=5,raw_mipmaps=False,raw_size=[3072,2048])
    for observed,expected in zip(r['new_source_projection'],i['new_expected_rows']):
        assert observed['id']==expected['id'] and observed['points_px']==expected['points_px']
        payload=struct.pack('<II',35,len(expected['points_px']))+b''.join(struct.pack('<ff',*point) for point in expected['points_px'])
        assert payload.hex()==observed['PackedVector2_bytes_hex']
    assert r['expected_child_RGBA_sha256']=='635fffe3c760155d5db61122d19efd88a1e8e6f0bb903515ff35afbdfecfdc3c'
    OUT.mkdir(exist_ok=True)
    actual=dict(path=str(RESULT),sha256=digest(RESULT))
    process=dict(path=str(PROCESS),sha256=digest(PROCESS))
    prior=dict(status='FROZEN_INDEPENDENT_TWO_DOMAIN_NATIVE_ABI_PRIOR_BEFORE_PUBLISHER',ready=True,
        expected_child_RGBA_sha256=r['expected_child_RGBA_sha256'],parent_RGBA_sha256=r['parent_RGBA_sha256'],
        changed_pixels=r['changed_pixels'],union_visited_pixels=r['union_visited_pixels'],
        domains_closed=r['domains_closed'],domain_results=r['domain_results'],full_RGBA_inverse=True,
        author_sha256=i['source_pins'][i['author_path']],
        native_oracle_actual=actual,native_oracle_process=process,
        source_first=r['source_first'],source_final=r['source_final'],
        scope='Only two local domains. Independent source model + original Geometry2D ABI; not publisher output, ART, Physics, route or current Field acceptance.')
    prior_doc=write('independent_prior_READY.json',prior)
    review=dict(status='INDEPENDENT_NATIVE_ORACLE_ACTUAL_READONLY_REVIEW',passed=True,
        actual=actual,process=process,prior=prior_doc,checks=425,failures=0,elapsed_ms=430,
        true_console_exit_code=0,stderr_bytes=0,source_first_final_exact_count=8,
        source_projection_f32_and_native_PackedVector2_bits_exact=True,old_local_parent_differences=0,
        union_visited_pixels=206290,changed_pixels=140469,domain_changed_pixels=[71743,68726],
        child_RGBA_sha256=r['expected_child_RGBA_sha256'],full_inverse=True,
        retained_old_candidates='Original152D order-rejected helper and original publisher/input remain preserved; only repaired2E779 source-pinned. No publisher executed by QA.',
        protection_limits='Script records eight source facts SHA/bytes/mtime seconds. Root external real-save15 guard not supplied in this oracle receipt; no independent exacttick save claim made here.',
        next_gate='Publisher must independently generate and compare its output against this frozen prior. Runtime/ART/Physics remain pending.',
        operations=dict(engine=0,PNG_decodes_by_QA=0,packet_decodes=0,raster_replays=0,collector=0,production_writes=0))
    print(json.dumps(dict(prior=prior_doc,review=write('oracle_actual_review_READONLY.json',review))))

if __name__=='__main__':main()
