"""Archive four image-edit metadata and freeze a two-line audio candidate. No generation/network."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
def sha(b):return hashlib.sha256(b).hexdigest()
def new(path,value):
    raw=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
    with path.open('xb') as f:f.write(raw)
    return dict(path=str(path.relative_to(ROOT)).replace('\\','/'),sha256=sha(raw),bytes=len(raw))
audit_path=OUT/'four_identity_edits_actual_READONLY.json';audit_raw=audit_path.read_bytes();audit=json.loads(audit_raw)
meta_dir=OUT/'four_identity_meta_ARCHIVE';meta_dir.mkdir(exist_ok=False)
metas=[]
for row in audit['source_rows']:
    raw=ROOT/row['raw_path'];assert sha(raw.read_bytes())==row['raw_sha256']
    meta=dict(status='BUILTIN_RAW_IDENTITY_EDIT_FINITE_VISUAL_AUDIT_NOT_IMPORTED_NOT_FORMAL',task_id=row['task_id'],generation_tool='builtin_image_gen',intent='identity-preserving image edit of actual walking soldier into portrait or true neutral idle',model=None,provider=None,cost=None,original_builtin_output_path=None,original_builtin_output_path_note='Not supplied to this art subagent; Root may append a separate provenance record, do not invent it.',raw_path=row['raw_path'],raw_sha256=row['raw_sha256'],raw_bytes=row['raw_bytes'],raw_size=row['raw_size'],raw_RGBA_sha256=row['raw_RGBA_sha256'],alpha_extrema=row['alpha_extrema'],prompt=row['prompt'],identity_reference=row['identity_reference'],builtin_referenced_image_paths_only=True,builtin_num_last_images_to_include_omitted=True,actual_call_count_Root_reported=1,reference_role='EDIT TARGET and same-person identity/costume anchor, not unrelated brand-new text-only image',visual_and_pixel_audit=dict(path=str(audit_path.relative_to(ROOT)).replace('\\','/'),sha256=sha(audit_raw)),review=row['review'],image_local_edits=0,game_source_edits=0,Godot_calls=0,imported=False,formal_enabled=False)
    metas.append(new(meta_dir/(row['id']+'.meta.json'),meta))
candidate_path=OUT/'sapi_two_representative_probe01_CANDIDATE.json';candidate_raw=candidate_path.read_bytes();plan=json.loads(candidate_raw)
source_path=ROOT/plan['source_author'];source_raw=source_path.read_bytes();source=json.loads(source_raw)
assert source['hero_opening']==plan['lines'][0]['text']
actor=[r for r in source['rows'] if r['npc_id']=='harbour_life_docks_quay_patrol'];assert len(actor)==1 and actor[0]['lines'][0]==plan['lines'][1]['text'] and actor[0]['npc_name']==plan['lines'][1]['speaker']
plan['status']='TWO_SOURCE_BOUND_LOCAL_SAPI_AUDITIONS_FROZEN_ROOT_REVIEW_PENDING_NOT_GENERATED';plan['source_author_sha256']=sha(source_raw)
frozen=new(OUT/'sapi_two_representative_probe01_FROZEN.json',plan)
script=ROOT/'prompts/luoyang_city_finish_20261025i/sapi_two_probe01_ROOT_REVIEW_ONLY.ps1'
receipt=new(OUT/'sapi_two_probe01_and_four_meta_freeze_READONLY.json',dict(status='FOUR_META_ARCHIVED_TWO_AUDIO_PLAN_FROZEN_NO_AUDIO_GENERATION',metadata_archives=metas,metadata_not_copied_to_raw_directory=True,original4raw_unchanged=True,audio_plan=frozen,audio_source=dict(path=plan['source_author'],sha256=sha(source_raw)),producer=dict(path=str(script.relative_to(ROOT)).replace('\\','/'),sha256=sha(script.read_bytes())),preview_lines=[dict(speaker=r['speaker'],text=r['text'],characters=len(r['text']),filename=r['output_filename']) for r in plan['lines']],no_network=True,no_speaker_playback=True,no_Godot=True,new_audio_files=0))
print(json.dumps(dict(receipt=receipt,plan=frozen,producer_sha256=sha(script.read_bytes()),metadata_count=len(metas)),ensure_ascii=False))
