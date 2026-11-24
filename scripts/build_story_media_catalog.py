"""Render the offline story/media audit from the Godot audit_story_media.gd snapshot."""

import argparse
import hashlib
import json
import re
import unicodedata
from collections import Counter, defaultdict
from html import escape
from pathlib import Path
from urllib.parse import quote

from build_quest_catalog import build as quests
from build_storyline_catalog import ROOT, build as stories

DOC = ROOT / "docs"
GAME = ROOT / "game"
SOURCES = ROOT / "assets/processed/audio/wuxia_voice_sfx_expansion_20261022"


def clip_button(path, label="试听"):
    if not path:
        return ""
    rel = path.removeprefix("res://")
    if not (GAME / rel).is_file():
        raise ValueError(f"Missing audio source {path}")
    return f'<button class="listen" data-src="../game/{quote(rel)}">{escape(label)}</button>'


def source_index():
    index = defaultdict(list)
    for manifest in sorted(SOURCES.glob("*voice_manifest.json")):
        for row in json.loads(manifest.read_bytes())["rows"]:
            index[row["source"]["sha256"]].append(row)
    for path, row in json.loads((GAME / "art/audio/voices/ch1/zhuwei_women_cast_20261113.json").read_bytes()).items():
        dialog = path.split("/")[-2]
        speaker, rest = path.split("/")[-1].split("_", 1)
        node = rest.split("_seg")[0]
        index[row["sha256"]].append(dict(row, speaker=speaker, dialog_id=dialog, node_id=node))
    cast = GAME / "art/audio/voices/altar_and_caravan_cast_20261119.json"
    for row in json.loads(cast.read_bytes()).values():
        index[row["sha256"]].append(row)
    return index


def attribution(dialog, row, index):
    if not row["clips"]:
        return "", ""
    matched = []
    voices = set()
    def words(text):
        return "".join(ch for ch in text if not ch.isspace() and not unicodedata.category(ch).startswith("P"))
    for clip in row["clips"]:
        digest = hashlib.sha256((GAME / clip.removeprefix("res://")).read_bytes()).hexdigest()
        candidates = index.get(digest, [])
        same_node = [c for c in candidates if (c["dialog_id"], c["node_id"], c["speaker"]) ==
                     (dialog, row["id"], row["speaker"])]
        exact = [c for c in same_node if c["text"].strip() == row["text"].strip()]
        if exact:
            matched.append("原文与发言人一致")
            voices.update(c["voice"] for c in exact)
        elif normalized := [c for c in same_node if words(c["text"]) == words(row["text"])]:
            matched.append("仅标点或换行不同")
            voices.update(c["voice"] for c in normalized)
        elif candidates:
            return "录音与来源登记有差异", "登记：" + candidates[0]["speaker"] + " · " + candidates[0]["text"]
        else:
            matched.append(False)
    if all(matched):
        label = "仅标点或换行不同" if "仅标点或换行不同" in matched else "原文与发言人一致"
        return label, " / ".join(sorted(voices))
    return "原文待核", ""


def role_index(chapters):
    roles = {p["name"]: p["role"] for c in chapters for p in c["characters"]}
    for line in (DOC / "audits/npc-voice-identity-20261113.md").read_text(encoding="utf8").splitlines():
        cells = [x.strip() for x in line.strip("|").split("|")]
        if len(cells) == 5 and re.search(r"\d+ / \d+", cells[2]) and "按所列台词" not in cells[1]:
            roles[cells[0]] = cells[1]
    return roles


def played_nodes():
    logs = ROOT / "reports"
    late = logs / "late_campaign_20261119_213549"
    selected = [late / f"{name}.log" for name in
                ("ch5b", "ch6_restart", "ch6_replay3", "pc7", "pc7_identity", "pc7_authorization",
                 "pc8_gate_fix", "pc8_finale", "pc8_returns", "ending_corrected")]
    luoyang = logs / "luoyang_campaign_20261119_202631"
    selected.extend(luoyang / f"campaign{i}.log" for i in (11, 12, 13, 14))
    nodes = set()
    for log in selected:
        if log.is_file():
            nodes.update(re.findall(r"^ROUTE SAY (\S+) (\S+)\s*$", log.read_text(encoding="utf8"), re.M))
    altar = logs / "late_campaign_altar_20261119/full.log"
    if altar.is_file():
        raw = altar.read_bytes()
        log = raw.decode("utf-16" if raw.startswith(b"\xff\xfe") else "utf8")
        nodes.update(("ch8_false_order_prebattle", beat) for beat in re.findall(r"^SHOT full (\w+)", log, re.M))
    return nodes


def voice_panel(data, roles, counts):
    manifest = source_index()
    shown = played_nodes()
    rendered = []
    for dialog in data["dialogs"]:
        for r in dialog["rows"]:
            status = r["status"]
            counts[status] += 1
            played = (dialog["id"], r["id"]) in shown
            if played:
                counts["试玩显示"] += 1
                counts["试玩缺音"] += status == "未找到录音"
            identity, detail = attribution(dialog["id"], r, manifest)
            if identity:
                counts[identity] += 1
            clips = "".join(clip_button(p, "试听" if len(r["clips"]) == 1 else f"第 {i} 段")
                            for i, p in enumerate(r["clips"], 1))
            if not r["speaker"]:
                options = r.get("candidates", []) + [r["narration"]]
                clips = "".join(f'<small>{escape(opt["speaker"])} · {opt["status"]}</small>' +
                                "".join(clip_button(p) for p in opt["clips"]) for opt in options)
            label = r["speaker"] or "随交互对象"
            metadata = f'{dialog["id"]} / {r["id"]}'
            role = roles.get(label, "")
            note = " · ".join(x for x in (status, identity, detail, "试玩日志已显示" if played else "") if x)
            rendered.append(f'<article class="line" data-played="{int(played)}" data-status="{escape(status)}" data-proof="{escape(identity)}">'
                            f'<div><b>{escape(label)}</b><small>{escape(role)}</small></div>'
                            f'<div><p>{escape(r["text"])}</p><code>{escape(metadata)}</code>'
                            f'<small>{escape(note)}</small>{clips}</div></article>')
    return "\n".join(rendered)


def chapter_panel(chapters, by_id):
    def quest_link(qid):
        q = by_id[qid]
        return f'<a href="quest-catalog.html#{escape(qid)}">{escape(q["title"])}</a>'
    rows = []
    for c in chapters:
        main = " › ".join(quest_link(q) for q in c["mainQuestIds"])
        side = " · ".join(quest_link(q) for q in c["sideQuestIds"])
        branches = " · ".join(quest_link(q) for q in c.get("branchQuestIds", []))
        choices = "、".join(x["title"] for x in c["choices"])
        rows.append(f'<details class="chapter"><summary><span>第 {c["number"]} 章</span>'
                    f'<strong>{escape(c["title"])}</strong><small>{len(c["mainQuestIds"])} 主线 · {len(c["sideQuestIds"])} 支线</small></summary>'
                    f'<p>{escape(c["objective"])}</p><div><b>主线顺序</b><p>{main}</p></div>'
                    f'<div><b>章内支线</b><p>{side}</p></div>'
                    + (f'<div><b>门派分路</b><p>{branches}</p></div>' if branches else "")
                    + (f'<p>关键选择　{escape(choices)}</p>' if choices else "")
                    + '</details>')
    return "\n".join(rows)


def track(path):
    return escape(Path(path).stem)


def table(heads, rows):
    head = "".join(f"<th scope='col'>{h}</th>" for h in heads)
    body = "\n".join("<tr>" + "".join(f"<td>{v}</td>" for v in row) + "</tr>" for row in rows)
    return f'<div class="scroll"><table><thead><tr>{head}</tr></thead><tbody>{body}</tbody></table></div>'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("snapshot", type=Path)
    args = parser.parse_args()
    data = json.loads(args.snapshot.read_bytes())
    chapters = stories()
    by_id = {q["id"]: q for q in quests()}
    counts = Counter()
    voice = voice_panel(data, role_index(chapters), counts)
    scene_rows = ([escape(name), f'<code>{escape(sid)}</code>', track(path), mode or ("通用回退" if fallback else "按场景解析"),
                   escape(intro) or "—", clip_button(path) if seconds else "加载失败"]
                  for sid, name, path, seconds, fallback, intro, mode in sorted(data["scenes"]))
    music = table(["场景", "场景 ID", "进场曲目", "选曲", "配置的进场对白", "音频"], scene_rows)
    def audio_table(entries):
        return table(["触发项", "音频", "时长", "试听"], ([escape(k), track(p), f"{n:.2f} 秒", clip_button(p) if n else "加载失败"]
                                                    for k, p, n in entries))
    effect_summary = []
    for kind, label in [("skills", "招式"), ("enemies", "敌人")]:
        members = [r for r in data["effects"] if r[0] == kind]
        for field in members[0][2]:
            values = [r[2][field] for r in members]
            effect_summary.append([label, field, len(values), sum(bool(p) and sec > 0 for p, sec in values),
                                   sum(not p for p, _ in values), sum(bool(p) and sec == 0 for p, sec in values)])
    samples = table(["实际对白", "进场底乐", "对白开始后", "引擎内播放", "实际人声"],
                    ([escape(k), track(base), track(now), "播放中" if active else "未播放",
                      clip_button(clip) if clip else "该采样时刻无人声"] for k, base, now, active, clip in data["samples"]))
    total = sum(len(d["rows"]) for d in data["dialogs"])
    stats = [
        ("主线任务", sum(len(c["mainQuestIds"]) for c in chapters)),
        ("章内支线", sum(len(c["sideQuestIds"]) for c in chapters)),
        ("已标明发言人 · 有配音", counts["有整句录音"] + counts["分段齐备"]),
        ("已标明发言人 · 缺配音", counts["未找到录音"]),
    ]
    other = f'{counts["部分分段"]} 条部分分段，{counts["仅有旁述"]} 条仅有旁述。' if counts["部分分段"] or counts["仅有旁述"] else ""
    summary = (f'本次读取 {len(data["dialogs"])} 份对白定义、{total} 个非空文本节点，包含主角、旁白、兼容和候选资源。'
               f'明确发言人的节点中，{counts["分段齐备"]} 条分段齐备，{counts["有整句录音"]} 条可加载整句，'
               f'{counts["未找到录音"]} 条未找到角色录音。{other}另有 {counts["交互时确定说话人"]} 条随交互对象确定，单列已知场景人选和旁白回退。')
    proof = (f'对实际选中的 MP3 核对录音字节、生成台本、节点和发言人，{counts["原文与发言人一致"]} 条一致，'
             f'{counts["仅标点或换行不同"]} 条仅标点或换行不同，'
             f'{counts["录音与来源登记有差异"]} 条与来源登记有差异，{counts["原文待核"]} 条缺完整来源证据。'
             '角色设定与已有录音来源可追溯。年龄听感、语气和实际念词仍需结合试听逐句判断。')
    if counts["试玩显示"]:
        proof += (f'对照本地保留的洛阳调查与第五至八章试玩日志，有 {counts["试玩显示"]} 个不同节点确实显示过，'
                  f'其中 {counts["试玩缺音"]} 个显名节点缺录音。可勾选下方筛选框优先排查。')
    else:
        proof += '当前构建未读到对应的试玩节点记录。'
    scenes = data["scenes"]
    scene_summary = (f'从场景资源及路由解析出 {len(scenes)} 个独立场景 ID，'
                     f'{sum(r[3] > 0 for r in scenes)} 个进场选曲可加载，其中 {sum(r[4] for r in scenes)} 个使用通用回退。'
                     '表中保留可解析的候选定义。动态生成区域、天气覆盖和各地图实际听感需进场核对。')
    cue_summary = (f'有 {sum(":" not in r[0] for r in data["cues"])} 处整段对白换曲，'
                   f'{sum(":" in r[0] for r in data["cues"])} 处节点换曲。其余对白通常延续场景音乐。')
    replacements = {
        "CHAPTERS": chapter_panel(chapters, by_id), "VOICE": voice, "VOICE_SCOPE": summary, "PROOF": proof,
        "STATS": "".join(f'<div><b>{v}</b><span>{k}</span></div>' for k,v in stats),
        "SCENES": music, "SCENE_SCOPE": scene_summary, "CUE_SCOPE": cue_summary, "CUES": audio_table(data["cues"]),
        "BATTLE": audio_table(data["battle"]), "SAMPLES": samples,
        "EFFECTS": table(["对象", "声音字段", "定义数", "显式可加载", "未单配", "配置失效"], effect_summary),
        "HOOKS": table(["对白", "节点", "调用的现场演出"], ([escape(v) for v in row] for row in data["hooks"])),
    }
    template = (DOC / "story-media-catalog.template.html").read_text(encoding="utf8")
    output = re.sub(r"__([A-Z_]+)__", lambda match: replacements[match[1]], template)
    (DOC / "story-media-catalog.html").write_text(output, encoding="utf8", newline="\n")
    print(summary, proof, scene_summary, cue_summary, sep="\n")


if __name__ == "__main__":
    main()
