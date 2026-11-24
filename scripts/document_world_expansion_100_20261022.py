"""Rebuild this batch's human-readable inventory after integrity and visual review."""
import json
from collections import Counter
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/"assets/raw/world_expansion_100_20261022"
TEMP=ROOT/"tmp/world_expansion_100_20261022"
NAMES={"maps":"地图建筑模块","quest_props":"任务道具","npc_sprites":"NPC静态精灵","portraits":"NPC同人立绘","animals":"动物敌人","human_enemies":"人形敌人","story_bosses":"剧情Boss"}
TIERS={"normal":"普通怪","elite":"野外高品质精英怪","story_boss":"剧情Boss"}


def main():
    data=json.loads((BASE/"current-candidates.json").read_text("utf-8"))
    integrity=json.loads((BASE/"integrity_100.json").read_text("utf-8"))
    gallery=json.loads((TEMP/"gallery_100.json").read_text("utf-8"))
    visual=json.loads((BASE/"visual-review.json").read_text("utf-8"))
    assert data["subjects"]==100 and integrity["generated"]==100 and visual["current_subjects_reviewed"]==100
    rows=data["assets"];summary=gallery["summary"]
    lines=["# 百图扩充素材库 · 2026-10-22", "", "已完成100个当前主体候选：24建筑、24道具、10NPC静态精灵、10同人立绘、20动物、6人形敌人、6已有剧情Boss。另保留1张薛影持剑弃用初稿，共101份独立原PNG。上一批22张不计入本批。", "",
           "[分类缩略图 / 点击放大](../../../docs/equipment-skill-catalog.html#resources) · [资源复用索引](../../../docs/resource-reuse-index.md) · [制作方案](../../../docs/world-expansion-100-20261022.md)", "",
           "## 当前使用情况", "", "全部未导入、未接入game。当前选择看 [current-candidates.json](current-candidates.json)；首轮与书册后继收据看 [manifest.json](manifest.json)，修正版单独看 [corrections.json](corrections.json)。薛影持剑初稿已弃用，当前清单只选空手修正版。", "",
           f"100个当前候选完整A>0四边留白：{data['alpha_margin_pass']}通过、{data['alpha_margin_fail']}未达10%。原失败保留；未做本地清背景、删弱alpha、透明扩画布或原PNG缩放。缩略图和联系表只是查看用派生图。静态角色不代表行走、攻击、受击或倒地动画完成。", "",
           "普通怪13、精英13、剧情Boss6。老虎、狮子、野狗、狐狸、狗熊各2普通＋2野外精英；动物并未新增遭遇、数值、掉落或剧情Boss。6Boss核对现有is_chapter_boss=true，未修改剧情定义。", "",
           "## 分类路径清单", "", "下表列出全部当前候选；PNG同目录的同名.meta.json保存原始来源、提示词、身份参考、SHA、尺寸和留白结果。设计依据是制作来源，不是已接入消费者。", ""]
    for kind,title in NAMES.items():
        items=[r for r in rows if r["kind"]==kind]
        lines += [f"### {title} · {len(items)}张", "", "| 名称 | 城镇 / 分级 | 原图路径 | 当前状态 |", "|---|---|---|---|"]
        for r in items:
            p=Path(r["output"]).relative_to(BASE.relative_to(ROOT)).as_posix()
            lines.append(f"| {r['label']} | {TIERS.get(r['tier'],r['city'])} | [{r['output']}]({p}) | 未接入；完整alpha留白待处理 |")
        lines.append("")
    lines += ["## 有限视觉复核与待办", ""] + ["- "+s for s in visual["limitations"]]
    lines += ["", "## 可追溯性与保留失败", "",
              "内置imagegen共102调用：84成功新生成＋17成功参考/编辑＋1无图片拒绝，每登记任务1次。青冥剑录初版被工具以violence理由拒绝、没有输出，保留原错误与request ID；另登记仅静置书册的安全后继，不重试原ID。模型/provider/费用未披露，meta留空；未使用CLI fallback。101原PNG与内置原始文件SHA一致，50设计/身份来源SHA保持、上一批22PNG保持、旧tasks原前缀逐字节保持。此证明只覆盖本批所核文件，不声称并行AP工作区无变化。", "",
              "首6次路径解析失败后按独特视觉规格人工对应原文件，保留 [initial_path_receipt_failure.json](initial_path_receipt_failure.json)，不能称原始逐call路径收据完整。后续先存hint再解析。一次vendor提示词编辑与登记并发丢失Jinling条目，按已有meta/原图收据加锁恢复，已有portrait仅补登记、无重生成；见portrait_record_failure.json与reconcile_01.json。最初女性vendor草稿在生图前已纠为既有男行商身份，旧草稿和49源预检均保留，后继50源单列。", "",
              "原100件收据不覆盖修改；薛影武器不符初稿保留，另登记一次限定去剑编辑，经实看采用为空手当前候选，原稿在图鉴标为弃用。查 [visual-review.json](visual-review.json)、[integrity_100.json](integrity_100.json) 和 [xueying_correction_review.json](xueying_correction_review.json)。", "",
              "## 重建与复核", "", "```powershell", "python scripts/verify_world_expansion_100_20261022.py audit --expected 100", "python scripts/verify_world_expansion_100_20261022.py selection", "python scripts/verify_world_expansion_100_20261022.py previews", "python scripts/build_arsenal_catalog.py --sync-resources-only", "python scripts/verify_world_expansion_100_20261022.py gallery --expected 100", "python scripts/build_resource_reuse_index.py", "python scripts/document_world_expansion_100_20261022.py", "```", "",
              "重建命令不生成新图、不导入Godot；prepare和record仅用于首次生产，不应重跑来替换已存收据。"]
    (BASE/"README.md").write_text("\n".join(lines)+"\n","utf-8")
    change=["# 百图扩充完成记录 · 2026-10-22", "", "change-id: world-expansion-100-20261022", "", "用户要求的100个主体已出图并归档，100当前候选＋1弃用初稿＝101原PNG；上一批22张未重复计数。", "",
            "| 类别 | 当前张数 |", "|---|---:|"] + [f"| {NAMES[k]} | {v} |" for k,v in data["kinds"].items()]
    change += ["", "普通13/野外高品质精英13/现有剧情Boss6。五种指定动物各2普通＋2精英；10组NPC精灵与立绘逐人参考，原男vendor身份保留；5位Boss沿用既有图参考，洛阳捕快头为候选视觉。6位现有Boss标记已核。无新动物剧情Boss、遭遇、奖励、数值或游戏绑定。", "",
               f"图鉴已同步：{summary['total']}文件 / {summary['images']}图片 / {summary['audio']}音频。本批100当前候选＋1弃用原稿按类别、城镇、物种、普通/精英/剧情Boss分组，均有缩略图与原图路径，沿用点击放大/复制路径/检索；弃用稿独立红色状态筛选。原124装备、67技能、126任务、8剧情及非resources JSON逐值完全相同；101缩略图解码与原图路径核验通过。此次未新增浏览器实交互/音频/390px测试证明。", "",
               "主清单100份成功PNG收据和薛影修正版分账核验：101原文件独立SHA、逐meta/内置原始输出一致；50制作来源SHA、原22PNG和旧tasks前缀保持，102独立skip任务，实际102调用、101成功图片、1工具拒绝无图片；青冥剑录另登记静置书册后继。保留首6路径解析人工映射例外、vendor并发登记恢复、工具拒绝和持剑错误初稿，不冒执行全程无错误。", "",
               f"有限质量：当前100中{data['alpha_margin_fail']}完整alpha留白未达10%，不得直接晋升运行图。真实alpha联系表已分组实看；隐藏RGB查看器的雾不能作真实背景结论。" ]
    change += ["", "- "+"\n- ".join(visual["limitations"]), "", "无本地alpha清理/扩画布、无Godot导入/运行、无游戏脚本/场景/配置/存档写入、无用户进程操作。并行AP状态以current-progress独立记录为准。", "",
               "入口：[完整分类清单](../../assets/raw/world_expansion_100_20261022/README.md)、[当前选择](../../assets/raw/world_expansion_100_20261022/current-candidates.json)、[资源图鉴](../equipment-skill-catalog.html#resources)、[复用索引](../resource-reuse-index.md)。"]
    (ROOT/"docs/changes/world-expansion-100-20261022.md").write_text("\n".join(change)+"\n","utf-8")
    print(json.dumps({"documented_subjects":100,"raw_versions":101,"gallery":summary},ensure_ascii=True))


if __name__=="__main__": main()
