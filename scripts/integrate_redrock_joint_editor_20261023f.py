"""Exact approved padding verification and new-file-only editor scene integration."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
import re
import shutil
from pathlib import Path
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
ESTAGE=ROOT/"assets/staging/redrock_joint_trial_20261023e"
STAGE=ROOT/"assets/staging/redrock_joint_editor_20261023f"
PROJECT=STAGE/"validation_project"
NAME="redrock_joint_editor_20261023f"
SCENE=f"scenes/drafts/{NAME}/redrock_joint.tscn"
SCRIPT=f"scripts/drafts/{NAME}/joint_preview.gd"
ART=f"art/modules/{NAME}"


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,v):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")


def protected_snapshot():
    paths=[ROOT/"game/project.godot",ROOT/"prompts/tasks.yaml"]
    paths+=list((ROOT/"game/scripts/autoload").glob("*.gd"))+list((ROOT/"game/scripts/field").glob("*.gd"))
    paths+=list((ROOT/"assets/raw/redrock_joint_trial_20261023e").rglob("*.png"))
    pub=json.loads((ROOT/"assets/staging/redrock_editor_gate_20261023c/publication.json").read_text(encoding="utf-8"))
    paths+=[ROOT/r["path"] for r in pub["files"]]
    paths+=[p for p in (Path(os.environ["APPDATA"])/"Godot/app_userdata/云影侠传").rglob("save*") if p.is_file()]
    return [{"path":str(p),"sha256":sha(p),"bytes":p.stat().st_size,"mtime_ns":p.stat().st_mtime_ns} for p in sorted(set(paths))]


def authorize():
    p=ESTAGE/"padding-proposal.json"
    assert not (ESTAGE/"padding-authorization.json").exists()
    save(STAGE/"protected-before.json",protected_snapshot())
    save(ESTAGE/"padding-authorization.json",{"date":"2026-10-23","user_answer":"允许，仅增加透明留白","question_scope":"本批3张，核心1774×887→2282×1141、两翼1536×1024→1976×1318；保留原PNG/全部原RGBA，不裁切缩放清alpha","explicit_local_padding_only":True,"proposal_sha256":sha(p),"processor_sha256":sha(ROOT/"scripts/pad_redrock_joint_trial_20261023e.py")})


def verify_padding():
    plan=json.loads((ESTAGE/"padding-proposal.json").read_text(encoding="utf-8"))
    report=json.loads((ROOT/"assets/processed/redrock_joint_trial_20261023e/processing-report.json").read_text(encoding="utf-8"))
    checks={}; rows=[]
    for r in plan["items"]:
        a=np.array(Image.open(ROOT/r["source"]).convert("RGBA"));b=np.array(Image.open(ROOT/r["output"]).convert("RGBA"))
        x,y=r["offset"];w,h=r["old_size"]
        checks[r["key"]+"_source_SHA"]=sha(ROOT/r["source"])==r["source_sha256"]
        checks[r["key"]+"_all_original_RGBA"]=bool(np.array_equal(a,b[y:y+h,x:x+w]))
        border=b.copy();border[y:y+h,x:x+w]=0
        checks[r["key"]+"_all_new_RGBA_zero"]=not bool(np.any(border))
        checks[r["key"]+"_new_size"]=list(b.shape[1::-1])==r["new_size"]
        mask=b[:,:,3]>0;yy,xx=np.where(mask)
        margins=[int(xx.min())/b.shape[1],int(yy.min())/b.shape[0],(b.shape[1]-int(xx.max())-1)/b.shape[1],(b.shape[0]-int(yy.max())-1)/b.shape[0]]
        checks[r["key"]+"_full_A1_margin"]=min(margins)>=.1
        rows.append({"key":r["key"],"margins":margins,"output_sha256":sha(ROOT/r["output"]),"source_pixel_changes":int(np.count_nonzero(a!=b[y:y+h,x:x+w]))})
    checks["three_only"]=len(plan["items"])==len(report["items"])==3
    save(STAGE/"independent-padding-verification.json",{"passed":all(checks.values()),"checks":checks,"items":rows,"alpha_cleanup_pixels":0})
    assert all(checks.values()),checks
    print(json.dumps({"passed":True,"checks":len(checks),"minimum_margin":min(min(r["margins"]) for r in rows)}))


def build():
    assert not PROJECT.exists()
    assert json.loads((STAGE/"independent-padding-verification.json").read_text(encoding="utf-8"))["passed"]
    interfaces=json.loads((ESTAGE/"interfaces.json").read_text(encoding="utf-8"))
    processed=json.loads((ROOT/"assets/processed/redrock_joint_trial_20261023e/processing-report.json").read_text(encoding="utf-8"))
    offsets={r["key"]:r for r in processed["items"]}
    media=[]
    for p in interfaces["pieces"]:
        r=offsets[p["key"]];s=p["pixel_scale"]
        origin=[p["origin"][i]-r["offset"][i]*s for i in range(2)]
        media.append({"key":p["key"],"source":r["output"],"destination":f"{ART}/{p['key']}.png","sha256":r["sha256"],"pixel_scale":s,"original_origin":p["origin"],"origin":origin,"source_offset":r["offset"]})
    for key,source in {"guard":"assets/processed/redrock_gate_20261023b/guard_idle/redrock_20261023a_guard_idle_v1_padded.png","earth":"assets/raw/redrock_ground_resources_20261023b/ground/redrock_20261023b_earth_v1.png"}.items():
        media.append({"key":key,"source":source,"destination":f"{ART}/{key}.png","sha256":sha(ROOT/source)})
    for r in media:
        dest=PROJECT/r["destination"];dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/r["source"],dest)
    (PROJECT/"project.godot").write_text('config_version=5\n[application]\nconfig/name="赤岩关防编辑场景核验"\nrun/main_scene="res://'+SCENE+'"\nconfig/features=PackedStringArray("4.6", "GL Compatibility")\n[display]\nwindow/size/viewport_width=1920\nwindow/size/viewport_height=1080\nwindow/stretch/mode="canvas_items"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n',encoding="utf-8")
    old_scene=(ESTAGE/"trial_project/trial.tscn").read_text(encoding="utf-8")
    lines=['[gd_scene load_steps=10 format=3]',f'[ext_resource type="Script" path="res://{SCRIPT}" id="1"]']
    lines += [f'[ext_resource type="Texture2D" path="res://{r["destination"]}" id="{r["key"]}"]' for r in media]
    old_scene=old_scene[old_scene.index('[sub_resource'):]
    old_scene=old_scene.replace('metadata/status = "三块原图接口试拼，不是完整城市；未正式导入"','metadata/status = "已接入工程的独立结构草案；未接世界路由"')
    # Keep native scene nodes, not @tool dynamic image loading or absolute paths.
    old_scene=old_scene.replace('[node name="Ground" type="Polygon2D" parent="."]','[node name="Ground" type="Polygon2D" parent="."]\nvisible = false\nz_index = -10\ntexture = ExtResource("earth")')
    node_names={"left":"LeftWing","right":"RightWing","core":"Core"}
    for r in media[:3]:
        marker=f'[node name="{node_names[r["key"]]}" type="Sprite2D" parent="Structure"]'
        old_scene=old_scene.replace(marker,marker+f'\nposition = Vector2({r["origin"][0]}, {r["origin"][1]})\nscale = Vector2({r["pixel_scale"]}, {r["pixel_scale"]})\ntexture = ExtResource("{r["key"]}")')
    # Preserve the tested foreground wing order in the serialized editor scene.
    start=old_scene.index('[node name="RightWing"');end=old_scene.index('[node name="Collision"')
    block=old_scene[start:end];split=block.index('[node name="Core"')
    old_scene=old_scene[:start]+block[split:]+block[:split]+old_scene[end:]
    old_scene=old_scene.replace('position = Vector2(2650, 1930)','position = Vector2(2650, 1550)')
    s=112/958
    old_scene=old_scene.replace('[node name="Art" type="Sprite2D" parent="SurveyActor"]','[node name="Art" type="Sprite2D" parent="SurveyActor"]'+f'\ntexture = ExtResource("guard")\nposition = Vector2({-805.5*s}, {-1290*s})\nscale = Vector2({s}, {s})')
    lines += [old_scene]
    # Add native, editable collision polygons using frozen original-pixel footprints.
    footprints={"CoreWest":("core",[(80,595),(380,560),(730,610),(845,650),(845,690),(735,702),(375,676),(67,642)]),"CoreEast":("core",[(1145,660),(1430,697),(1725,690),(1725,735),(1430,735),(1145,708)]),"LeftWall":("left",[(650,710),(1398,780),(1398,840),(1332,877),(660,790)]),"LeftRock":("left",[(140,730),(660,820),(690,700),(520,320),(250,230)]),"RightWall":("right",[(78,665),(995,778),(1245,652),(1245,704),(995,827),(78,714)]),"RightRock":("right",[(1200,680),(1465,750),(1450,250),(1320,180),(1160,390)])}
    piece_map={r["key"]:r for r in interfaces["pieces"]}
    world_polygons={}
    for name,(key,points) in footprints.items():
        r=piece_map[key];pts=[[x*r["pixel_scale"]+r["origin"][0],y*r["pixel_scale"]+r["origin"][1]] for x,y in points]
        world_polygons[name]=pts
        lines += [f'[node name="{name}" type="CollisionPolygon2D" parent="Collision"]','polygon = PackedVector2Array('+', '.join(f'{x}, {y}' for x,y in pts)+')']
    ground=[(400,1270),(680,1140),(1500,1180),(1850,1010),(2290,1010),(2460,980),(3000,760),(4400,400),(4950,560),(5060,1450),(4700,1670),(3620,1630),(2970,1510),(2770,1710),(3070,2180),(2760,2380),(2250,2320),(1930,1950),(2110,1630),(1550,1470),(800,1490),(480,1410)]
    points=', '.join(f'{x}, {y}' for x,y in ground)
    ground_props='\npolygon = PackedVector2Array('+points+')\nuv = PackedVector2Array('+', '.join(f'{x*.92}, {y*.92}' for x,y in ground)+')\ncolor = Color(0.96, 0.90, 0.80, 1)'
    lines=[part.replace('texture = ExtResource("earth")','texture = ExtResource("earth")'+ground_props) for part in lines]
    lines += ['[node name="GroundBoundary" type="CollisionPolygon2D" parent="Collision"]','build_mode = 1','polygon = PackedVector2Array('+points+')']
    # Scene-local background avoids changing the project's clear colour.
    lines += ['[node name="Background" type="CanvasLayer" parent="."]','layer = -20','[node name="Fill" type="ColorRect" parent="Background"]','anchors_preset = 15','anchor_right = 1.0','anchor_bottom = 1.0','grow_horizontal = 2','grow_vertical = 2','mouse_filter = 2','color = Color(0.13, 0.15, 0.16, 1)']
    scene_path=PROJECT/SCENE;scene_path.parent.mkdir(parents=True,exist_ok=True);scene_path.write_text('\n\n'.join(lines)+'\n',encoding="utf-8")
    save(STAGE/"integration.json",{"scene":SCENE,"script":SCRIPT,"media":media,"world_polygons":world_polygons,"ground":ground,"same_world_geometry_as_raw_trial":True,"formal_world_entry":False,"default_actor":[2650,1550]})


def configure_imports():
    changes=[]
    for p in (PROJECT/ART).glob("*.png.import"):
        old=p.read_text(encoding="utf-8")
        new=old.replace('process/fix_alpha_border=true','process/fix_alpha_border=false').replace('detect_3d/compress_to=1','detect_3d/compress_to=0')
        p.write_text(new,encoding="utf-8");changes.append({"path":str(p.relative_to(PROJECT)),"before":old,"after":new})
    assert len(changes)==5
    save(STAGE/"import-settings.json",changes)


def publish():
    assert not (STAGE/"publication.json").exists()
    proof=json.loads((PROJECT/"artifacts/verification.json").read_text(encoding="utf-8"));assert proof["passed"]
    config=json.loads((STAGE/"integration.json").read_text(encoding="utf-8"))
    files=[]
    for r in config["media"]:
        meta=Path(r["destination"]+'.import');txt=(PROJECT/meta).read_text(encoding="utf-8")
        ctex=re.search(r'(?m)^path="res://([^"]+\.ctex)"',txt)[1]
        files += [ctex,ctex[:-5]+'.md5',meta.as_posix()]
    files += [SCRIPT,SCRIPT+'.uid']+[r["destination"] for r in config["media"]]+[SCENE]
    for rel in files:
        assert (PROJECT/rel).is_file() and not (ROOT/"game"/rel).exists(),rel
    rows=[]
    for rel in files:
        out=ROOT/"game"/rel;out.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(PROJECT/rel,out)
        rows.append({"path":'game/'+rel,"sha256":sha(out),"validated_copy_exact":sha(out)==sha(PROJECT/rel)})
    save(STAGE/"publication.json",{"status":"NEW_EDITOR_STRUCTURE_SCENE_ONLY","files":rows,"scene":SCENE,"new_import_leaves":15,"production_import_invoked":False,"world_route_added":False,"editor_UI_controlled":False})
    print(json.dumps({"published_files":len(rows),"scene":SCENE}))


def protect_after():
    before=json.loads((STAGE/"protected-before.json").read_text(encoding="utf-8"));after={r["path"]:r for r in protected_snapshot()}
    changes=[{"before":r,"after":after.get(r["path"])} for r in before if after.get(r["path"])!=r]
    save(STAGE/"protected-after.json",{"checked":len(before),"changes":changes,"passed":not changes})
    print(json.dumps({"checked":len(before),"changes":len(changes)}))


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument('action',choices=('authorize','verify-padding','build','configure-imports','publish','protect-after'));a=p.parse_args()
    {'authorize':authorize,'verify-padding':verify_padding,'build':build,'configure-imports':configure_imports,'publish':publish,'protect-after':protect_after}[a.action]()
