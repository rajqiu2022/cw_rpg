"""Mechanical Root-only launcher/promotion successors; never execute either."""
from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];ROOT=GAME.parent
S='res://build/luoyang_city_revision_20261024c_source01/'
ISO=ROOT/'assets/staging/luoyang_yamen_courts_mask_20261024c_import'
def sha(b):return hashlib.sha256(b).hexdigest()
def out(name,b):
    with (HERE/name).open('xb') as f:f.write(b)
    return dict(path=S+name,sha256=sha(b),bytes=len(b))
def transform(parent,changes,name):
    old=parent.read_bytes();text=old.decode();edits=[]
    for a,b,count in changes:
        assert text.count(a)==count,(a[:70],text.count(a),count)
        for _ in range(count):
            i=len(text[:text.index(a)].encode());text=text.replace(a,b,1);edits.append(dict(byte_offset_at_step=i,old=a,new=b))
    inv=text.encode()
    for e in reversed(edits):
        i=e['byte_offset_at_step'];a,b=e['old'].encode(),e['new'].encode();assert inv[i:i+len(b)]==b;inv=inv[:i]+a+inv[i+len(b):]
    assert inv==old
    return dict(parent=dict(path=S+parent.name,sha256=sha(old)),candidate=out(name,text.encode()),edits=edits,wholebyte_forward_inverse=True)
prepared=(ISO/'prepared_READY.json').read_bytes();assert sha(prepared)=='7c7140e25a1c0922eebffb7ee53a261ab0e60dc4e1f31be9695d0555fef13006'
verifier=(ISO/'verify_READY.gd').read_bytes();assert sha(verifier)=='fc0cd5abf77ce34288683640264a5c19868e703d47a570117230479e6bd83376'
project=(ISO/'project.godot').read_bytes()
launcher=transform(HERE/'import_scholar_portrait_once_ROOTONLY.ps1',[
 ('luoyang_scholar_portrait_20261024c_import','luoyang_yamen_courts_mask_20261024c_import',1),
 ('scholar_portrait_isolate_import_once','courts_mask_isolate_import_once',1),
 ('6f41021d0ad1718f63c0557cfba382edf7c700b7904ab93c279a279c7820e5d7',sha(prepared),1),
 ('12806b01f2960496993b70d34e348a284633d492b3027ba02885ad354fd986d8',sha(verifier),1),
 ('82ac9e5f0459dfacd007433c4ce000b31515b4fad794196951c03d81b7ffb4f8',sha(project),1),
 ('EXACT_ONE_OPAQUE_SCHOLAR_PORTRAIT_ISOLATED_IMPORT_PREPARED','EXACT_ONE_COURTS_OVERLAY_MASK_ISOLATED_IMPORT_PREPARED',1),
 ('main_three_absent_targets','main_two_absent_targets',4),
 ('$spec.main_two_absent_targets.Count -ne 3','$spec.main_two_absent_targets.Count -ne 2',1),
 ('ONLY_ONE_PORTRAIT_ISOLATE_REQUIRED','ONLY_ONE_OVERLAY_MASK_ISOLATE_REQUIRED',1),
 ('MAIN_THREE_LEAVES_NOT_ABSENT','MAIN_TWO_LEAVES_NOT_ABSENT',1),
 ('ONLY_ONE_NEW_OPAQUE_PORTRAIT_ISOLATED_EDITOR_IMPORT_NOT_NATIVE_VERIFY','ONLY_ONE_PUBLISHED_OVERLAY_MASK_ISOLATED_EDITOR_IMPORT_NOT_NATIVE_VERIFY',1),
 ('main_three_before','main_two_before',1),('main_three_after','main_two_after',1),('main_three_absent','main_two_absent',1)
 ],'import_courts_mask_once_ROOTONLY.ps1')
target='res://build/luoyang_yamen_courts_20261024c_system01/publication02/output/54592/walk_overlay.png'
compiled='res://.godot/imported/walk_overlay.png-53da40f2b4702ac38ad0636f09873742.ctex'
promotion=transform(HERE/'promote_scholar_portrait_three_NOTRUN.ps1',[
 ('luoyang_scholar_portrait_20261024c_import','luoyang_yamen_courts_mask_20261024c_import',1),
 ('res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png',target,1),
 ('res://.godot/imported/paper_scholar_v1.png-a84b0a85bc8e14dc620e75dc75b57eda.ctex',compiled,1),
 ('ROOT_APPROVED_SCHOLAR_PORTRAIT_EXACT_THREE_MEDIA_PROMOTION','ROOT_APPROVED_COURTS_OVERLAY_EXACT_TWO_IMPORT_MEDIA_PROMOTION',1),
 ('EXPLICIT_ROOT_THREE_MEDIA_AUTH_REQUIRED','EXPLICIT_ROOT_TWO_MEDIA_AUTH_REQUIRED',1),
 ('ONLY_ONE_OPAQUE_SCHOLAR_PORTRAIT_ISOLATED_FULL_RGBA_NOT_RUNTIME','ONLY_ONE_PUBLISHED_COURTS_OVERLAY_MASK_ISOLATED_FULL_RGBA_NOT_RUNTIME',1),
 ('EXACT_ONE_PORTRAIT_NATIVE_FULL_RGBA_PASS_REQUIRED','EXACT_ONE_OVERLAY_NATIVE_FULL_RGBA_PASS_REQUIRED',1),
 ("'paper_scholar_portrait'","'courts_overlay'",1),
 (' -or !$row.opaque_full_RGBA','',1),
 ('ebd60b64edbcc061401a0fc1219d1f120a4f5d4e98db1ab1d129c81f845c2a74','56fb2f381fe129ed8f9b5292dfc49c765a4f3e5fba144da3e84d979d1cae1b5b',1),
 ('3b2f42c9e5fe7afe3ac43ae1894e7fcea4d8584a158da829311f8f80306b1261','635fffe3c760155d5db61122d19efd88a1e8e6f0bb903515ff35afbdfecfdc3c',1),
 ('$row.size[0] -ne 1254 -or $row.size[1] -ne 1254','$row.size[0] -ne 3072 -or $row.size[1] -ne 2048',1),
 ('FIXED_UNEDITED_OPAQUE_PORTRAIT_ONLY','FIXED_PUBLISHED_UNEDITED_OVERLAY_MASK_ONLY',1),
 ("$leaves=@()","$existingPng=Join-Path $game $png.Substring(6)\nif((Sha $existingPng) -cne $row.png_sha256){throw 'PUBLISHED_MAIN_PNG_CHANGED'}\n$leaves=@()",1),
 ("@('sidecar','compiled','png')","@('sidecar','compiled')",1),
 ('NEW_EXACT_THREE_MAIN_LEAVES_ABSENT_REQUIRED','NEW_EXACT_TWO_MAIN_LEAVES_ABSENT_REQUIRED',1),
 ('$leaves.Count -ne 3','$leaves.Count -ne 2',1),
 ('Unique).Count -ne 3','Unique).Count -ne 2',1),
 ('$auth.ordered_targets.Count -ne 3','$auth.ordered_targets.Count -ne 2',1),
 ('EXACT_THREE_AND_NEW_RECEIPT','EXACT_TWO_AND_NEW_RECEIPT',1),
 ('$i -lt 3','$i -lt 2',1),
 ('EXACT_THREE_SCHOLAR_PORTRAIT_NEW_MEDIA_PROMOTED_NOT_RUNTIME','EXACT_TWO_COURTS_OVERLAY_IMPORT_MEDIA_PROMOTED_NOT_RUNTIME',1),
 ('$receipt=@{',"if((Sha $existingPng) -cne $row.png_sha256){throw 'PUBLISHED_MAIN_PNG_CHANGED_AFTER_PROMOTION'}\n$receipt=@{",1),
 ('new_leaves=3','new_leaves=2',1)
 ],'promote_courts_mask_two_NOTRUN.ps1')
proof=out('courts_mask_root_wrappers_inverse_BUILD.json',(json.dumps(dict(status='ROOT_ONLY_MASK_LAUNCHER_AND_EXACT_TWO_IMPORT_LEAF_PROMOTION_NOT_RUN',launcher=launcher,promotion=promotion,prepared_sha256=sha(prepared),verifier_sha256=sha(verifier),project_sha256=sha(project),engine_calls=0,media_promotions=0,PNG_writes=0),ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(dict(launcher=launcher['candidate'],promotion=promotion['candidate'],proof=proof)))
