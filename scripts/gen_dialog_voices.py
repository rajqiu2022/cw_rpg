"""
gen_dialog_voices.py — Edge TTS 情感化对话语音生成

输出: game/art/audio/voices/ch{1-8}/{dialog_id}/{speaker}_{node_id}_e{emotion}.mp3
emotion: normal / concerned / solemn / weary / fear / happy / sad / angry / threat
"""
import argparse, asyncio, re, sys
from pathlib import Path

try: import edge_tts
except ImportError: print("pip install edge-tts"); sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
DIALOG_DIR = ROOT / "game" / "data" / "dialogs"
VOICE_DIR = ROOT / "game" / "art" / "audio" / "voices"

VOICE_MAP = {
    # 旁白 — 中性新闻播报（与所有角色区分）
    "旁白": "zh-CN-YunyangNeural",
    # 主角 — 年轻男声
    "冷孤云": "zh-CN-YunxiNeural",
    "店小二": "zh-CN-YunxiNeural",
    "被绑男子": "zh-CN-YunxiNeural",
    "唐行舟": "zh-CN-YunxiNeural",
    "货郎": "zh-CN-YunxiNeural",
    "走货郎": "zh-CN-YunxiNeural",
    "走村货郎": "zh-CN-YunxiNeural",
    # 师父/反派/长者 — 成熟男声；角色参数负责区分年龄与气质
    "刑樊天": "zh-CN-YunjianNeural",
    "蒙面杀手首领": "zh-CN-YunjianNeural",
    "客栈老板": "zh-CN-YunjianNeural",
    "神秘商人": "zh-CN-YunjianNeural",
    # 打铁/粗犷/男性角色 — 豪迈男声（Yunjian，与旁白Yunyang区分）
    "杜青衫": "zh-CN-YunjianNeural",
    "铁匠刘": "zh-CN-YunjianNeural",
    "沈半盏": "zh-CN-YunjianNeural",
    "护商镖师": "zh-CN-YunjianNeural",
    "守门村民": "zh-CN-YunjianNeural",
    "武馆教头": "zh-CN-YunjianNeural",
    "守城兵丁": "zh-CN-YunjianNeural",
    "赵无忌": "zh-CN-YunjianNeural",
    "蒙面杀手甲": "zh-CN-YunjianNeural",
    "蒙面杀手乙": "zh-CN-YunjianNeural",
    "江湖散兵": "zh-CN-YunjianNeural",
    "药师苏伯": "zh-CN-YunjianNeural",
    "留守山贼": "zh-CN-YunjianNeural",
    "苏雾笙": "zh-CN-YunjianNeural",
    # 女性
    "悦无姮": "zh-CN-XiaoxiaoNeural",
    "凌霜": "zh-CN-XiaoxiaoNeural",
    "沈青禾": "zh-CN-XiaoxiaoNeural",
    "沈晚棠": "zh-CN-XiaoxiaoNeural",
    "楚泠": "zh-CN-XiaoxiaoNeural",
    "赵思颖": "zh-CN-XiaoxiaoNeural",
    "采买妇人": "zh-CN-XiaoxiaoNeural",
    "戚云笙": "zh-TW-HsiaoChenNeural",
    "大会乐师": "zh-CN-XiaoxiaoNeural",
    "晒药婆婆": "zh-CN-XiaoyiNeural",
    "采药村妇": "zh-CN-XiaoyiNeural",
    "卖菜大婶": "zh-CN-XiaoxiaoNeural",
    "焦急妇人": "zh-CN-XiaoyiNeural",
    "哭泣女子": "zh-CN-XiaoyiNeural",
}
# 情感 → rate/pitch/volume 参数 (edge-tts Communicate 支持)
EMOTION_PARAMS = {
    "normal": {"rate": "+0%", "pitch": "+0Hz", "volume": "+0%"},
    "concerned": {"rate": "-14%", "pitch": "-4Hz", "volume": "-3%"},
    "solemn": {"rate": "-20%", "pitch": "-7Hz", "volume": "+1%"},
    "weary":  {"rate": "-18%", "pitch": "-9Hz", "volume": "-5%"},
    "fear":   {"rate": "+25%", "pitch": "+6Hz", "volume": "+10%"},
    "happy":  {"rate": "+15%", "pitch": "+8Hz", "volume": "+10%"},
    "sad":    {"rate": "-20%", "pitch": "-5Hz", "volume": "-10%"},
    "angry":  {"rate": "+8%", "pitch": "-7Hz", "volume": "+12%"},
    "threat": {"rate": "-12%", "pitch": "-8Hz", "volume": "+5%"},
}

# 情感关键词检测（从台词文本推断）
EMOTION_KEYWORDS = {
    "concerned": ["不太平", "全死了", "江湖传言", "出事", "小心", "别逞强"],
    "solemn": ["长叹", "是时候了", "一字一顿", "记住", "永远"],
    "weary": ["累了", "罢了", "不想再", "多年"],
    "fear":   ["别过来", "别……", "救命", "求求", "害怕", "完了", "别杀", "放过", "不要杀", "饶命", "不敢了"],
    "happy":  ["哈哈", "哈哈哈", "太好了", "好日子", "开心", "痛快", "好酒", "爽快", "终于"],
    "sad":    ["对不起", "师父", "永别", "哭", "泪", "舍不得", "难过", "悲伤", "痛心", "惋惜", "对不起你"],
    "threat": ["把东西留下", "下场", "杀你", "砍", "剁", "老实点", "别动", "跪下", "识相", "交出", "受死"],
    "angry":  ["住手", "混账", "该死", "放肆"],
}

def detect_emotion(text: str) -> str:
    for emotion, kws in EMOTION_KEYWORDS.items():
        for kw in kws:
            if kw in text:
                return emotion
    return "normal"

# 角色级音色微调 (在情感参数基础上叠加)
# pitch: Hz 负值=更低沉, rate: 负值=更慢。
# 不要同时大幅降调和减速，Edge TTS 会明显产生老年播报腔与机器感。
CHARACTER_PARAMS = {
    "刑樊天": {"pitch": "+3Hz", "rate": "+10%", "volume": "+1%"},  # 稳重中年，避免过老过沉
    "杜青衫": {"pitch": "-34Hz", "rate": "-7%", "volume": "+7%"},   # 沙哑、浑厚
    "铁匠刘": {"pitch": "-38Hz", "rate": "-9%", "volume": "+8%"},   # 粗粝、低沉
    "蒙面杀手首领": {"pitch": "-30Hz", "rate": "-10%"},  # 低沉威胁
    "悦无姮": {"pitch": "-10Hz", "rate": "-5%"},      # 清冷
    "凌霜": {"pitch": "-16Hz", "rate": "-8%"},      # 沉稳中年掌门
    "药师苏伯": {"pitch": "-8Hz", "rate": "-6%"},   # 年长、温和
    "沈青禾": {"pitch": "+1Hz", "rate": "+7%", "volume": "+3%"},  # 青梅竹马，利落、嘴硬、带一点蛮横
    "唐行舟": {"pitch": "+5Hz", "rate": "+7%"},       # 爽朗年轻男声
    "晒药婆婆": {"pitch": "-12Hz", "rate": "-10%"},    # 年长女声
    "卖菜大婶": {"pitch": "-31Hz", "rate": "-12%"},
    "焦急妇人": {"pitch": "-22Hz", "rate": "-6%"},
}

# Final delivery settings for Zhuwei's two NPCs, shared by full-line and segmented takes.
ZHUWEI_VOICE_RATES = {
    ("vegetable_vendor", "start"): "-15%",
    ("vegetable_vendor", "accept"): "-12%",
    ("vegetable_vendor_waiting", "start"): "-13%",
    ("vegetable_vendor_turnin", "start"): "-8%",
    ("vegetable_vendor_done", "start"): "-13%",
    ("crying_woman", "start"): "-4%",
    ("crying_woman_waiting", "start"): "-11%",
    ("crying_woman_turnin", "start"): "-6%",
    ("crying_woman_done", "start"): "-9%",
}


def delivery_params(line: dict) -> tuple[str, dict | None]:
    speaker = line["speaker"]
    params = CHARACTER_PARAMS.get(speaker)
    key = (line["file"].removeprefix("ch1_s2_"), line["node"])
    if speaker in {"卖菜大婶", "焦急妇人"} and key in ZHUWEI_VOICE_RATES:
        return "normal", {**params, "rate": ZHUWEI_VOICE_RATES[key]}
    return line["emotion"], params


def clean_text(t: str, with_narr: bool = True) -> dict:
    """拆分台词和（旁白）。
    返回 {'spoken': 角色台词, 'narr': 旁白文本}
    """
    t = re.sub(r'\[/?[ibcu]\]', '', t)
    t = re.sub(r'\[color=[^\]]*\]', '', t)
    t = re.sub(r'\[/color\]', '', t)
    t = t.replace('\\n', '。')

    # 提取所有（...）旁白
    narr_parts = []
    def grab(m):
        inner = m.group(1).strip('。，,、 ')
        if inner and len(inner) > 1:
            narr_parts.append(inner)
        return ''
    spoken = re.sub(r'[（(](.*?)[）)]', grab, t)
    spoken = re.sub(r'\s+', '', spoken).strip()
    # Removing a parenthetical narration can leave the newline separator and
    # sentence punctuation together ("。。" / "。。。"), which makes TTS pause
    # unnaturally and sound mechanical.
    spoken = re.sub(r'。{2,}', '。', spoken)
    spoken = re.sub(r'，。', '。', spoken)
    spoken = spoken.lstrip('。，、 ')
    spoken = spoken.replace('——。', '——')

    narr = ''
    if with_narr and narr_parts:
        narr = ''.join(narr_parts).strip('。，,、 ')
    return {"spoken": spoken, "narr": narr}


def split_speech_segments(t: str, speaker: str) -> list[dict]:
    """按原文顺序拆分动作旁白与角色台词，避免把多段旁白合并到一起。"""
    t = re.sub(r'\[/?[ibcu]\]', '', t)
    t = re.sub(r'\[color=[^\]]*\]', '', t)
    t = re.sub(r'\[/color\]', '', t)
    t = t.replace('\\n', '\n')
    if speaker == "旁白":
        plain = re.sub(r'^[（(]|[）)]$', '', t.strip()).strip('。，,、 \n')
        return [{"kind": "narr", "text": plain}] if plain else []

    segments: list[dict] = []
    cursor = 0
    for match in re.finditer(r'[（(](.*?)[）)]', t, re.S):
        dialog = re.sub(r'\s+', '', t[cursor:match.start()]).strip('。，,、 ')
        if dialog:
            segments.append({"kind": "dialog", "text": dialog})
        narration = re.sub(r'\s+', '', match.group(1)).strip('。，,、 ')
        if narration:
            segments.append({"kind": "narr", "text": narration})
        cursor = match.end()
    tail = re.sub(r'\s+', '', t[cursor:]).strip('。，,、 ')
    if tail:
        segments.append({"kind": "dialog", "text": tail})
    return segments

def build_ssml(text: str, emotion: str) -> str:
    return text  # 不再用 SSML 标签，改用 Communicate 的 rate/pitch 参数

def load_lines(files: list[str]) -> list[dict]:
    lines = []
    for fn in files:
        path = DIALOG_DIR / fn
        if not path.exists(): continue
        c = path.read_text(encoding="utf-8")
        blocks = re.findall(r'\[sub_resource[^\]]*\](.*?)(?=\n\[sub_resource|\n\[resource\])', c, re.S)
        for block in blocks:
            m_sp = re.search(r'^speaker\s*=\s*"([^"]*)"', block, re.M)
            m_ni = re.search(r'^node_id\s*=\s*&"([^"]*)"', block, re.M)
            # Godot 资源里仍有少量历史台词包含未转义中文引号，按整行首尾引号读取更稳妥。
            m_tx = re.search(r'^text\s*=\s*"(.*)"\s*$', block, re.M)
            m_em = re.search(r'^voice_emotion\s*=\s*"([^"]*)"', block, re.M)
            if not m_ni or not m_tx:
                continue
            speaker = m_sp.group(1).strip() if m_sp else ""
            raw = speaker if speaker else "旁白"
            text = m_tx.group(1).replace('\\"', '"')
            parts = clean_text(text)
            segments = split_speech_segments(text, raw)
            # 纯旁白节点通常整句都写在括号内；不要因角色台词为空而跳过。
            if raw == "旁白" and not parts["spoken"] and parts["narr"]:
                parts["spoken"] = parts["narr"]
                parts["narr"] = ""
            if parts["spoken"] and len(parts["spoken"]) > 3:
                explicit_emotion = m_em.group(1) if m_em else "auto"
                emotion = explicit_emotion if explicit_emotion not in ("", "auto") else detect_emotion(parts["spoken"])
                lines.append({
                    "file": fn.replace(".tres", ""),
                    "node": m_ni.group(1), "speaker": raw,
                    "text": parts["spoken"], "emotion": emotion,
                    "narr": parts["narr"],
                    "segments": segments,
                })
    return lines


def _combine_param(base: str, extra: str, suffix: str) -> str:
    base_value = int(base.removesuffix(suffix))
    extra_value = int(extra.removesuffix(suffix))
    value = base_value + extra_value
    return f"{value:+d}{suffix}"

async def gen_voice(voice: str, text: str, emotion: str, out: Path, char_params: dict | None = None) -> bool:
    p = EMOTION_PARAMS.get(emotion, EMOTION_PARAMS["normal"]).copy()
    if char_params:
        for k, v in char_params.items():
            suffix = "%" if k in ("rate", "volume") else "Hz"
            p[k] = _combine_param(p[k], v, suffix)
    comm = edge_tts.Communicate(text, voice, rate=p["rate"], pitch=p["pitch"], volume=p["volume"])
    await comm.save(str(out))
    return out.exists()

async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--chapter", type=str)
    parser.add_argument("--speaker", type=str)
    parser.add_argument("--dialog", type=str)
    parser.add_argument("--node", type=str)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    all_files = sorted(p.name for p in DIALOG_DIR.glob("*.tres"))
    files = all_files
    if args.chapter:
        pfx = args.chapter if args.chapter.startswith("ch") else f"ch{args.chapter}"
        files = [f for f in all_files if f.startswith(f"{pfx}_")]
    if args.dialog:
        dialog_file = args.dialog if args.dialog.endswith(".tres") else f"{args.dialog}.tres"
        files = [f for f in files if f == dialog_file]

    lines = load_lines(files)
    if args.speaker:
        lines = [l for l in lines if args.speaker in l["speaker"]]
    if args.node:
        lines = [l for l in lines if l["node"] == args.node]

    # 统计
    emo_counts = {}
    for l in lines: emo_counts[l["emotion"]] = emo_counts.get(l["emotion"], 0) + 1
    spk_counts = {}
    for l in lines: spk_counts[l["speaker"]] = spk_counts.get(l["speaker"], 0) + 1

    print(f"\n{len(lines)} lines | 情感分布: {emo_counts} | 角色: {len(spk_counts)}")
    if args.dry_run:
        unmapped = sorted({l["speaker"] for l in lines if l["speaker"] not in VOICE_MAP})
        if unmapped:
            print(f"[unmapped] {'、'.join(unmapped)}")
        print("[dry-run] done.")
        return

    print(f"\nGenerating...")
    ok = 0
    for i, l in enumerate(lines):
        voice = VOICE_MAP.get(l["speaker"])
        if voice is None:
            print(f"  [SKIP] {l['speaker']} 尚未登记音色 ({l['file']}/{l['node']})")
            continue
        delivery_emotion, char_params = delivery_params(l)
        ch = l["file"][:3]
        safe_spk = l["speaker"].replace("/", "_").replace("\\", "_")
        out = VOICE_DIR / ch / l["file"] / f"{safe_spk}_{l['node']}_e{l['emotion']}.mp3"
        out.parent.mkdir(parents=True, exist_ok=True)
        preview = l["text"][:40] + "..." if len(l["text"]) > 40 else l["text"]
        print(f"  [{i+1}/{len(lines)}] ({l['emotion']}) {l['speaker']}: {preview}")
        try:
            await gen_voice(voice, l["text"], delivery_emotion, out, char_params)
            ok += 1
        except Exception as e:
            print(f"    [ERR] {e}")
        # 旁白：单独生成 (旁白声线)，文件名加 _narr
        if l.get("narr"):
            narr_path = VOICE_DIR / ch / l["file"] / f"{safe_spk}_{l['node']}_narr.mp3"
            try:
                await gen_voice(VOICE_MAP["旁白"], l["narr"], "normal", narr_path)
                print(f"      [narr] {l['narr'][:30]}")
            except Exception as e:
                print(f"      [narr ERR] {e}")
        for segment_index, segment in enumerate(l.get("segments", []), start=1):
            kind = segment["kind"]
            segment_path = VOICE_DIR / ch / l["file"] / f"{safe_spk}_{l['node']}_seg{segment_index:02d}_{kind}.mp3"
            segment_voice = VOICE_MAP["旁白"] if kind == "narr" else voice
            segment_emotion = "normal" if kind == "narr" else delivery_emotion
            segment_params = None if kind == "narr" else char_params
            try:
                await gen_voice(segment_voice, segment["text"], segment_emotion, segment_path, segment_params)
                print(f"      [seg {segment_index:02d} {kind}] {segment['text'][:30]}")
            except Exception as e:
                print(f"      [seg ERR] {e}")
        await asyncio.sleep(0.3)
    print(f"\nDone: {ok}/{len(lines)} -> {VOICE_DIR}")

if __name__ == "__main__":
    asyncio.run(main())
