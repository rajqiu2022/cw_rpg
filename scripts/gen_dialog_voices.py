"""
gen_dialog_voices.py — Edge TTS 情感化对话语音生成

输出: game/art/audio/voices/ch{1-8}/{dialog_id}/{speaker}_{node_id}_e{emotion}.mp3
emotion: normal / fear / happy / sad / threat
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
    # 师父/反派/长者 — 深沉有感情男声
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
    # 女性
    "悦无姮": "zh-CN-XiaoxiaoNeural",
    "卖菜大婶": "zh-CN-XiaoxiaoNeural",
    "哭泣女子": "zh-CN-XiaoxiaoNeural",
    "走货郎": "zh-CN-XiaoyiNeural",
}
DEFAULT_VOICE = "zh-CN-YunjianNeural"

# 情感 → rate/pitch/volume 参数 (edge-tts Communicate 支持)
EMOTION_PARAMS = {
    "normal": {"rate": "+0%", "pitch": "+0Hz", "volume": "+0%"},
    "fear":   {"rate": "+25%", "pitch": "+6Hz", "volume": "+10%"},
    "happy":  {"rate": "+15%", "pitch": "+8Hz", "volume": "+10%"},
    "sad":    {"rate": "-20%", "pitch": "-5Hz", "volume": "-10%"},
    "threat": {"rate": "-12%", "pitch": "-8Hz", "volume": "+5%"},
}

# 情感关键词检测（从台词文本推断）
EMOTION_KEYWORDS = {
    "fear":   ["别过来", "别……", "救命", "求求", "害怕", "完了", "别杀", "放过", "不要杀", "饶命", "不敢了"],
    "happy":  ["哈哈", "哈哈哈", "太好了", "好日子", "开心", "痛快", "好酒", "爽快", "终于"],
    "sad":    ["对不起", "师父", "永别", "哭", "泪", "舍不得", "难过", "悲伤", "痛心", "惋惜", "对不起你"],
    "threat": ["把东西留下", "下场", "杀你", "砍", "剁", "老实点", "别动", "跪下", "识相", "交出", "受死"],
}

def detect_emotion(text: str) -> str:
    for emotion, kws in EMOTION_KEYWORDS.items():
        for kw in kws:
            if kw in text:
                return emotion
    return "normal"

# 角色级音色微调 (在情感参数基础上叠加)
# pitch: Hz 负值=更低沉, rate: 负值=更慢
CHARACTER_PARAMS = {
    "刑樊天": {"pitch": "-40Hz", "rate": "-15%"},     # 浑厚、沧桑
    "蒙面杀手首领": {"pitch": "-30Hz", "rate": "-10%"},  # 低沉威胁
    "悦无姮": {"pitch": "-10Hz", "rate": "-5%"},      # 清冷
}

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

    narr = ''
    if with_narr and narr_parts:
        narr = ''.join(narr_parts).strip('。，,、 ')
    return {"spoken": spoken, "narr": narr}

def build_ssml(text: str, emotion: str) -> str:
    return text  # 不再用 SSML 标签，改用 Communicate 的 rate/pitch 参数

def load_lines(files: list[str]) -> list[dict]:
    lines = []
    for fn in files:
        path = DIALOG_DIR / fn
        if not path.exists(): continue
        c = path.read_text(encoding="utf-8")
        speaker, node_id = "", ""
        for raw_line in c.split("\n"):
            sl = raw_line.strip()
            m_sp = re.match(r'speaker\s*=\s*"([^"]*)"', sl)
            if m_sp:
                speaker = m_sp.group(1).strip()
                continue
            m_ni = re.match(r'node_id\s*=\s*&"([^"]*)"', sl)
            if m_ni:
                node_id = m_ni.group(1)
                continue
            m_tx = re.match(r'text\s*=\s*"([^"]*)"', sl)
            if m_tx:
                raw = speaker if speaker else "旁白"
                parts = clean_text(m_tx.group(1))
                if parts["spoken"] and len(parts["spoken"]) > 3:
                    emotion = detect_emotion(parts["spoken"])
                    lines.append({
                        "file": fn.replace(".tres", ""),
                        "node": node_id, "speaker": raw,
                        "text": parts["spoken"], "emotion": emotion,
                        "narr": parts["narr"],
                    })
    return lines

async def gen_voice(voice: str, text: str, emotion: str, out: Path, char_params: dict | None = None) -> bool:
    p = EMOTION_PARAMS.get(emotion, EMOTION_PARAMS["normal"]).copy()
    if char_params:
        for k, v in char_params.items():
            p[k] = v
    comm = edge_tts.Communicate(text, voice, rate=p["rate"], pitch=p["pitch"], volume=p["volume"])
    await comm.save(str(out))
    return out.exists()

async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--chapter", type=str)
    parser.add_argument("--speaker", type=str)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    all_files = sorted(p.name for p in DIALOG_DIR.glob("*.tres"))
    files = all_files
    if args.chapter:
        pfx = args.chapter if args.chapter.startswith("ch") else f"ch{args.chapter}"
        files = [f for f in all_files if f.startswith(f"{pfx}_")]

    lines = load_lines(files)
    if args.speaker:
        lines = [l for l in lines if args.speaker in l["speaker"]]

    # 统计
    emo_counts = {}
    for l in lines: emo_counts[l["emotion"]] = emo_counts.get(l["emotion"], 0) + 1
    spk_counts = {}
    for l in lines: spk_counts[l["speaker"]] = spk_counts.get(l["speaker"], 0) + 1

    print(f"\n{len(lines)} lines | 情感分布: {emo_counts} | 角色: {len(spk_counts)}")
    if args.dry_run:
        print("[dry-run] done.")
        return

    print(f"\nGenerating...")
    ok = 0
    for i, l in enumerate(lines):
        voice = VOICE_MAP.get(l["speaker"], DEFAULT_VOICE)
        ch = l["file"][:3]
        safe_spk = l["speaker"].replace("/", "_").replace("\\", "_")
        out = VOICE_DIR / ch / l["file"] / f"{safe_spk}_{l['node']}_e{l['emotion']}.mp3"
        out.parent.mkdir(parents=True, exist_ok=True)
        preview = l["text"][:40] + "..." if len(l["text"]) > 40 else l["text"]
        print(f"  [{i+1}/{len(lines)}] ({l['emotion']}) {l['speaker']}: {preview}")
        try:
            await gen_voice(voice, l["text"], l["emotion"], out, CHARACTER_PARAMS.get(l["speaker"]))
            ok += 1
        except Exception as e:
            print(f"    [ERR] {e}")
        # 旁白：单独生成 (旁白声线)，文件名加 _narr
        if l.get("narr"):
            narr_path = VOICE_DIR / ch / l["file"] / f"{safe_spk}_{l['node']}_narr.mp3"
            try:
                await gen_voice(VOICE_MAP.get("旁白", DEFAULT_VOICE), l["narr"], "normal", narr_path)
                print(f"      [narr] {l['narr'][:30]}")
            except Exception as e:
                print(f"      [narr ERR] {e}")
        await asyncio.sleep(0.3)
    print(f"\nDone: {ok}/{len(lines)} -> {VOICE_DIR}")

if __name__ == "__main__":
    asyncio.run(main())
