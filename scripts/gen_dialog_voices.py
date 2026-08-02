"""
gen_dialog_voices.py — 用 Microsoft Edge TTS 批量生成对话语音

输出: game/art/audio/voices/ch{1-8}/{dialog_id}/{speaker}_{node_id}.mp3
"""
import argparse, asyncio, re, sys
from pathlib import Path

try: import edge_tts
except ImportError: print("pip install edge-tts"); sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
DIALOG_DIR = ROOT / "game" / "data" / "dialogs"
VOICE_DIR = ROOT / "game" / "art" / "audio" / "voices"

VOICE_MAP = {
    # 主角 — 年轻男声，活泼阳光
    "冷孤云": "zh-CN-YunxiNeural",
    # 师父/长辈 — 中年男声，充满感情
    "刑樊天": "zh-CN-YunjianNeural",
    # 女主 — 温暖女声
    "悦无姮": "zh-CN-XiaoxiaoNeural",
    # 铁匠/酒馆/朴实型 — 专业可靠男声
    "杜青衫": "zh-CN-YunyangNeural",
    "铁匠刘": "zh-CN-YunyangNeural",
    "沈半盏": "zh-CN-YunyangNeural",
    "护商镖师": "zh-CN-YunyangNeural",
    "守门村民": "zh-CN-YunyangNeural",
    # 武夫/反派/粗犷型 — 专业坚定男声
    "武馆教头": "zh-CN-YunyangNeural",
    "守城兵丁": "zh-CN-YunyangNeural",
    "赵无忌": "zh-CN-YunyangNeural",
    "蒙面杀手甲": "zh-CN-YunyangNeural",
    "蒙面杀手乙": "zh-CN-YunyangNeural",
    "蒙面杀手首领": "zh-CN-YunjianNeural",
    "江湖散兵": "zh-CN-YunyangNeural",
    "被绑男子": "zh-CN-YunxiNeural",
    # 商贩/健谈型 — 活泼女声
    "走货郎": "zh-CN-XiaoyiNeural",
    "客栈老板": "zh-CN-YunjianNeural",
    "神秘商人": "zh-CN-YunjianNeural",
    "店小二": "zh-CN-YunxiNeural",
    # 女性NPC — 温暖女声
    "卖菜大婶": "zh-CN-XiaoxiaoNeural",
    "哭泣女子": "zh-CN-XiaoxiaoNeural",
    # 旁白 — 说书人
    "旁白": "zh-CN-YunjianNeural",
}
DEFAULT_VOICE = "zh-CN-YunyangNeural"


def clean_text(t: str) -> str:
    t = re.sub(r'\[/?[ibcu]\]', '', t)
    t = re.sub(r'\[color=[^\]]*\]', '', t)
    t = re.sub(r'\[/color\]', '', t)
    t = t.replace('\\n', '。')
    t = re.sub(r'[（(].*?[）)]', '', t)
    t = re.sub(r'\s+', '', t)
    return t.strip()


def load_lines(files: list[str]) -> list[dict]:
    lines = []
    for fn in files:
        path = DIALOG_DIR / fn
        if not path.exists(): continue
        c = path.read_text(encoding="utf-8")
        speaker = ""
        node_id = ""
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
                t = clean_text(m_tx.group(1))
                if t and len(t) > 3:
                    lines.append({
                        "file": fn.replace(".tres", ""),
                        "node": node_id,
                        "speaker": raw,
                        "text": t,
                    })
    return lines


async def gen_voice(voice: str, text: str, out: Path) -> bool:
    comm = edge_tts.Communicate(text, voice)
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

    counts = {}
    for l in lines: counts[l["speaker"]] = counts.get(l["speaker"], 0) + 1

    print(f"\n{len(lines)} lines, {len(counts)} speakers:")
    for s, c in sorted(counts.items(), key=lambda x: -x[1]):
        print(f"  {s}: {c} -> {VOICE_MAP.get(s, DEFAULT_VOICE)}")

    if args.dry_run:
        print("\n[dry-run] done.")
        return

    print(f"\nGenerating...")
    ok = 0
    for i, l in enumerate(lines):
        voice = VOICE_MAP.get(l["speaker"], DEFAULT_VOICE)
        ch = l["file"][:3]
        safe_speaker = re.sub(r'[\\/:*?"<>|]', '_', l["speaker"])
        out = VOICE_DIR / ch / l["file"] / f"{safe_speaker}_{l['node']}.mp3"
        out.parent.mkdir(parents=True, exist_ok=True)
        preview = l["text"][:50] + "..." if len(l["text"]) > 50 else l["text"]
        print(f"  [{i+1}/{len(lines)}] {l['speaker']}: {preview}")
        try:
            await gen_voice(voice, l["text"], out)
            ok += 1
        except Exception as e:
            print(f"    [ERR] {e}")
        await asyncio.sleep(0.3)
    print(f"\nDone: {ok}/{len(lines)} -> {VOICE_DIR}")


if __name__ == "__main__":
    asyncio.run(main())
