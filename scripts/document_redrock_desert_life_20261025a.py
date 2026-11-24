"""Review notes and resource checks for the native desert batch; never rewrites PNGs."""
import hashlib
import json
import re
from collections import Counter
from pathlib import Path
from urllib.parse import unquote

import numpy as np
from PIL import Image

from redrock_desert_life_20261025a import BASE, ROOT, STAGE, save, sha

NOTES = {
    "inn": "平顶双层轮廓、赤砂岩与斑驳土抹灰可辨；正面门前有小台阶。上层门只作外观，未设计楼梯/楼内，不能当作可达门户。",
    "repair_shed": "平板木顶与后侧石墙，前方开敞工作湾可辨；车轮与木料收在后墙。柱脚、遮挡和车位净宽尚未实机标定。",
    "cistern": "井口、绞盘、木桶与平顶苇棚可辨；是独立取水小建筑。未绑定饮水/任务交互，井沿与柱脚碰撞待做。",
    "water_jars": "三罐共用低木托，适合水院或驿舍墙边的低矮陈设；不是背包道具图标。前方操作空间尚未布局。",
    "wheelbench": "车轮、轴木、木槌与台架组成一个工作点；适合修车棚内部或侧边。真实地图比例与工具可读性待落地。",
    "dry_tree": "树干扭曲、叶色灰黄；树冠比提示词要求偏密，只适合镇内/蓄水院边少量使用，不当作裸旱峡谷的通用稀疏树。",
    "dry_shrub": "低矮枯黄灰绿灌木，结构与乔木分开；叶团仍偏密。后续按成人膝至大腿高标定，不直接用原画布宽度定比例。",
    "ore_cluster": "赤色层状岩体夹暗灰矿脉，作为野外调查/采集实体候选；没有新增矿物Item ID、奖励、任务或掉落。",
}


def review():
    manifest = json.loads((BASE / "manifest.json").read_text("utf-8"))
    rows = manifest["assets"]
    assert len(rows) == 8 and all(r.get("output") and r["calls"] == 1 for r in rows)
    for row in rows:
        row["visual_review"] = NOTES[row["key"]]
        row["review_note"] = row["intended_use"] + "。" + NOTES[row["key"]] + " 当前游戏消费者0，未导入/未绑定碰撞与交互。"
        save((ROOT / row["output"]).with_suffix(".meta.json"), {**row, "backend": "builtin_image_gen", "model": None, "provider": None, "cost": None, "formal_enabled": False, "local_pixel_processing": False})
    manifest["status"] = "EIGHT_NATIVE_ASSETS_SAVED_NOT_RUNTIME_ADMITTED"
    save(BASE / "manifest.json", manifest)
    save(BASE / "resource-pack.json", {"status": manifest["status"], "assets": rows})
    diagnostic = []
    for row in rows:
        path = ROOT / row["output"]
        assert sha(path) == row["sha256"] == sha(Path(row["source_path"]))
        assert sha(ROOT / row["prompt"]) == row["prompt_sha256"]
        with Image.open(path) as im:
            alpha = np.asarray(im.getchannel("A"))
            ys, xs = np.nonzero(alpha > 0)
            bbox = [int(xs.min()), int(ys.min()), int(xs.max()+1), int(ys.max()+1)]
            assert bbox == row["metrics"]["full_alpha_bbox"]
            assert np.any(alpha == 0) and np.any(alpha >= 250)
            # High-alpha box is diagnostic only; never substitutes for A>0 admission.
            ys128, xs128 = np.nonzero(alpha >= 128)
            samples = [{"xy": list(xy), "rgba": list(im.getpixel(xy))} for xy in ((200,150), (im.width//2,70), (200,im.height//2))]
            diagnostic.append({"key": row["key"], "sha256": sha(path), "size": list(im.size), "alpha_min": int(alpha.min()), "alpha_max": int(alpha.max()), "alpha255_pixels": int(np.sum(alpha == 255)), "full_alpha_bbox": bbox, "diagnostic_alpha128_bbox": [int(xs128.min()),int(ys128.min()),int(xs128.max()+1),int(ys128.max()+1)], "alpha_1_to_3_pixels": int(np.sum((alpha > 0) & (alpha < 4))), "samples": samples, "full_alpha_margin_10_percent_pass": row["metrics"]["margin_10_percent_pass"]})
    save(STAGE / "native-verification.json", {"native_saved": 8, "byte_exact_to_tool_sources": True, "real_rgba_transparency": True, "originals_modified": False, "calls_per_asset": 1, "fallback_used": False, "runtime_admitted": 0, "diagnostic_alpha128_not_admission": True, "prior_strict_opaque_assertion_failed": "井棚与工作台原生alpha最大254，首QA误要求必须有255失败；保持原值，不改像素，真实透明检查仅确认存在0和接近不透明主体，非运行准入。", "assets": diagnostic})
    header = """# 赤岩沙漠生活资源 · 2026-10-25a

本批沿已选赤岩总规与现有连体关防材质继续生产，新增 **8 张原生透明PNG：3建筑、3场景实体、2植被**。使用内置 image_gen，每个ID一次，无CLI/fallback/自动重试。全部是独立场景/大世界组件；当前游戏消费者为0，未导入game或改世界入口。

所有原图与内置输出逐字节一致，保留真实RGBA、弱alpha及隐藏RGB，**未裁切、缩放、扩画布或清alpha**。8张完整A>0四边留白均未达10%，原失败保留；主体明显留白和诊断alpha128包围盒均不替代完整检查。旧批次像素处理许可没有扩用到本批。

| 类别 | 组件与原图路径 | 尺寸 | 计划放置（非当前使用） | 当前使用/结论 |
|---|---|---|---|---|
"""
    names = {"building": "地图建筑", "scene_prop": "场景/世界实体", "vegetation": "沙漠植被"}
    lines = [header]
    for r in rows:
        lines.append(f"| {names[r['kind']]} | [{r['label']}](../{r['output']}) | {r['size'][0]}×{r['size'][1]} | {r['intended_use']} | 引用0；候选，完整A1留白FAIL |")
    lines += ["", "## 逐件使用限制", ""]
    lines += [f"- **{r['label']}**：{r['visual_review']}" for r in rows]
    lines += ["", "## 查看与复用", "", "[资源图鉴](equipment-skill-catalog.html#resources)沿用缩略图与点击原图放大，按赤岩建筑/场景与大世界物件/沙漠植被分类。图鉴显示当前引用0、计划用途和待装配状态；本批仅做离线路径/缩略图/条目校验，不宣称浏览器实点。", "", "每张PNG旁有同名`.meta.json`，`resource-pack.json`列原图路径、完整提示词路径、输入参考SHA、输出SHA、尺寸和alpha结论。内置工具未提供准确模型/provider/费用，元数据保持null。", "", "本批提示词与独立队列：[production/prompts/tasks.yaml](../assets/staging/redrock_desert_life_20261025a/production/prompts/tasks.yaml)；模板使用项目真实renderer预检8项通过，仅本进程切换模板目录，未写根`prompts/tasks.yaml`或改生成器源码。", "", "参考：已选[赤岩总体图](../assets/raw/sect_western_map_designs_20261022d/redrock_masterplan_overview_v1.png)（空间/生活用途），[连体关楼原生模块](../assets/raw/redrock_joint_trial_20261023e/building/redrock_joint_20261023e_core_v1.png)（镜头/材质/光照）。没有恢复用户否定的c版布局。", "", "## 后续待办", "", "先做驿舍马院、石作修坊和蓄水院的分区尺寸平面，再按原像素比例标成人门高、脚点、柱脚与遮挡；不得把新增画布整体fit到旧框而缩小主体。建筑/物件不替代既有NPC待机与行走需求。NPC稳定行走、全镇装配、完整关墙五锚、正式世界接线仍待，不因本批8图生成自动完成。", "", "## 核验范围", "", "[native-verification.json](../assets/staging/redrock_desert_life_20261025a/native-verification.json)核原始SHA/真实透明/完整A1；[catalog-verification.json](../assets/staging/redrock_desert_life_20261025a/catalog-verification.json)核图鉴新增、缩略图与放大路径及非resources保持；[protected-after.json](../assets/staging/redrock_desert_life_20261025a/protected-after.json)核根队列、生成器、参考、旧赤岩结构工程和已记录save快照。没有运行Godot/import/旧组件复测或操作用户编辑器。", ""]
    doc = "\n".join(lines)
    (ROOT / "docs/redrock-desert-life-20261025a.md").write_text(doc, "utf-8")
    readme = "# 赤岩沙漠生活原图\n\n8张内置原生RGBA候选，原像素未处理，完整A1留白均FAIL；未接入游戏。\n\n[完整路径/用途/限制清单](../../../docs/redrock-desert-life-20261025a.md)；资源条目见同目录resource-pack.json，各PNG旁meta保存提示词/参考/SHA。\n"
    (BASE / "README.md").write_text(readme, "utf-8")
    print(json.dumps({"native_assets": 8, "kinds": dict(Counter(r["kind"] for r in rows)), "full_a1_pass": sum(r["metrics"]["margin_10_percent_pass"] for r in rows)}, ensure_ascii=False))


def verify_catalog():
    html = (ROOT / "docs/equipment-skill-catalog.html").read_text("utf-8")
    current = json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>', html, re.S).group(1))
    before = json.loads((STAGE / "catalog-before.json").read_text("utf-8"))
    assert {k:v for k,v in current.items() if k != "resources"} == {k:v for k,v in before.items() if k != "resources"}, "Nonresources changed"
    old = {r["diskPath"]: r for r in before["resources"]["records"]}
    new = {r["diskPath"]: r for r in current["resources"]["records"]}
    pack = json.loads((BASE / "resource-pack.json").read_text("utf-8"))
    expected = {r["output"] for r in pack["assets"]}
    assert expected <= new.keys() and not (expected & old.keys())
    for path in expected:
        row = new[path]
        assert row["usageCount"] == 0 and row["usage"] == []
        assert row["statusLabel"] == "沙漠生活组件 · 待装配"
        assert "不足10%" in row["note"]
        for field in ("url", "thumbnail"):
            resolved = (ROOT / "docs" / unquote(row[field])).resolve()
            assert resolved.is_relative_to(ROOT) and resolved.is_file()
        assert (ROOT / "docs" / unquote(row["url"])).resolve() == (ROOT / path).resolve()
    changed = [p for p in old if p in new and old[p] != new[p]]
    report = {"new_batch_rows": 8, "new_batch_game_consumers": 0, "nonresources_exact_equal": True, "thumbnail_and_full_image_paths_exist": True, "browser_click_tested": False, "before_summary": before["resources"]["summary"], "after_summary": current["resources"]["summary"], "other_added": sorted(new.keys()-old.keys()-expected), "removed": sorted(old.keys()-new.keys()), "prior_records_changed": changed}
    save(STAGE / "catalog-verification.json", report)
    print(json.dumps(report, ensure_ascii=False))
    protected = json.loads((STAGE / "protected-before.json").read_text("utf-8"))
    changes = []
    changed_observations = []
    for row in protected:
        p = Path(row["path"])
        if not p.is_file() or sha(p) != row["sha256"] or p.stat().st_size != row["bytes"] or p.stat().st_mtime_ns != row["mtime_ns"]:
            changes.append(row["path"])
            changed_observations.append({"path": row["path"], "before": row, "after": {"sha256": sha(p), "bytes": p.stat().st_size, "mtime_ns": p.stat().st_mtime_ns} if p.is_file() else None})
    save(STAGE / "protected-after.json", {"checked": len(protected), "save_files_checked": sum("app_userdata" in r["path"] for r in protected), "changed": changes, "all_sha_bytes_mtime_equal": not changes, "changed_observations": changed_observations, "interpretation": "本批只写独立queue；根prompts/tasks.yaml在窗口内变化，保留现值不覆盖、不宣称全保护同。其余差异以列表为准。"})
    print(json.dumps({"protected_checked": len(protected), "changed": changes}, ensure_ascii=False))


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "verify": verify_catalog()
    else: review()
