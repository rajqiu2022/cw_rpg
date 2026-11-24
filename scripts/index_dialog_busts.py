"""Build dialogue-only portrait bindings from the painted waist-up cast sheets."""
import json
import re
from pathlib import Path

from PIL import Image

GAME = Path(__file__).resolve().parents[1] / "game"
ART = "res://art/characters/dialog_busts_hd/"
# Each sheet is authored in reading order. The IDs describe the painting, so
# several anonymous speakers can share a profession without sharing a map asset.
SHEETS = {
    "village": ("du", "herbalist", "shen_tea", "granny"),
    "market": ("apprentice", "innkeeper", "porter", "vegetable_vendor"),
    "court": ("magistrate", "scholar", "constable", "guard"),
    "sect": ("taoist", "monk", "swordswoman", "disciple"),
    "fighters": ("assassin", "bandit", "enforcer", "swordsman"),
    "river": ("ferryman", "farmer", "merchant", "woman_clerk"),
    "story": ("hunter", "smith", "instructor", "papermaker"),
    "war": ("flag_captain", "mist_envoy", "archivist", "lieyun_officer"),
    "companions": ("tang", "qinghe", "yue", "duan"),
    "elders": ("zhao", "feng", "huo", "you"),
    "agents": ("su", "xue", "qi", "luo"),
    "women": ("siying", "chu", "wantang", "worried_woman"),
    "road": ("he", "elder_clerk", "peddler", "edict_bearer"),
    "mist": ("scout", "mask_captain", "burner", "poisoner"),
}
CAST = {
    "hero": "冷孤云", "master": "刑樊天", "du": "杜青衫", "smith": "铁匠刘 铁匠师傅",
    "shen_tea": "沈半盏", "tang": "唐行舟", "qinghe": "沈青禾", "yue": "悦无姮",
    "duan": "段长风 游历刀客", "he": "何平 石渡何平", "luo": "罗望 短镖罗望",
    "siying": "赵思颖", "chu": "楚泠", "wantang": "沈晚棠", "qi": "戚云笙",
    "su": "苏雾笙", "xue": "薛影", "feng": "封砚秋", "huo": "霍长空", "zhao": "赵无忌",
    "you": "游天鸿 观瀑老者", "elder_clerk": "府衙老吏 旧渡记档人 棋叟",
    "peddler": "走村货郎 中原行商", "woman_clerk": "诗会执事",
    "apprentice": "药铺学徒 林西送药人 布庄伙计", "farmer": "候见乡民 旧案幸存者",
    "merchant": "范掌柜 神秘商人 铁算盘任敖", "innkeeper": "客栈老板",
    "herbalist": "药师苏伯 沈伯 参农沈伯 外院老药工 药铺掌柜",
    "hunter": "旧猎户", "taoist": "清虚道长 玄真道长", "monk": "岳闻钟",
    "papermaker": "老纸匠", "constable": "捕快韩策", "swordswoman": "凌霜",
    "swordsman": "左明远 寒岭守藏人 白额鹿侯七", "enforcer": "古疆雷 上古魔将 山寨大王 白水截证首领 破封卢循",
    "ferryman": "船夫赵大江 老漕卒 翻舟许五", "bandit": "洛阳地痞 墨手温迟",
    "guard": "机关廊精锐监守 守村人 聚义厅引路人", "scholar": "大会乐师 茶镇经手人",
    "mist_envoy": "茗雾截盟使", "disciple": "薛影手下",
    "archivist": "茗雾内署护档使", "flag_captain": "伪旗统领 负伤的伪旗统领 假烈云盟首领 伪烈云盟首领",
    "edict_bearer": "茗雾假令传使", "mask_captain": "蒙面杀手精英 蒙面头领 蒙面杀手首领",
    "scout": "蒙面杀手甲 茗雾密探", "assassin": "蒙面杀手乙 黑衣人 蒙面人",
    "poisoner": "茗雾销卷使 茗雾点烽手", "burner": "茗雾焚册客 茗雾焚令手",
}
# Match the more specific jobs first. These same rules cover runtime-created NPCs.
RULES = [
    ("granny", "婆|老妪|老奶"), ("vegetable_vendor", "菜贩|卖菜|大婶"),
    ("worried_woman", "妇|大娘|阿嫂"), ("herbalist", "药师|药工|郎中|药商|参农"),
    ("swordswoman", "女侠|女弟子|师姐|师妹"), ("woman_clerk", "女子|姑娘|阿姊"),
    ("monk", "僧|和尚|少林|禅"), ("taoist", "道长|道人|真人"),
    ("flag_captain", "伪旗统领"), ("burner", "焚|销卷"), ("archivist", "护档|封针"),
    ("edict_bearer", "传使"), ("poisoner", "雾阀|药阀|点腕"), ("scout", "暗哨|密探|寻迹|渗透|探子"),
    ("assassin", "蒙面|刺客|杀手|灭口|断卷|茗雾|黑风"), ("lieyun_officer", "烈云|校尉|守备"),
    ("bandit", "山贼|匪|劫|私枭|芦荡私|赤疤|灰手|水鬼|夜鹞|黑狼|飞索|盗印|割囊|矿豺|游盗|断指"),
    ("enforcer", "头目|刀头|统领|突袭|伏杀|封渡队正"),
    ("constable", "巡捕|都头|捕快|巡村老兵|总管|队正"),
    ("guard", "巡|守卫|守山|守望|兵|哨|镖|护卫|护院|追兵|看守|门吏"),
    ("instructor", "教头|教习|考官|考校|练家子|师兄|力士"), ("disciple", "弟子|试炼|剑士"),
    ("swordsman", "刀客|剑客|侠客|五派代表"), ("magistrate", "府尹|县令|知府"),
    ("elder_clerk", "老吏|老账|老先生"), ("scholar", "账|簿|书|录|执笔|官|文|棋|诗|记事|秤|案卷|村塾|驿丞|执事"),
    ("ferryman", "船|渡|漕|水巡"), ("porter", "脚夫|担|搬运|装卸|粮工"),
    ("innkeeper", "客栈|酒楼"), ("peddler", "货郎|行商|行旅"), ("merchant", "商|掌柜|货主"),
    ("apprentice", "学徒|小二|伙计|送药"), ("hunter", "猎|山客"),
    ("papermaker", "老者|老伯|老人"), ("farmer", "民|农|村|茶客|行脚客"),
]
BINDINGS = {name: key for key, names in CAST.items() for name in names.split()}
PATTERNS = [(key, re.compile(pattern)) for key, pattern in RULES]
FIELD = re.compile(r'"?(npc_name|display_name|sprite_path|portrait_path)"?\s*[:=]\s*&?"([^"]+)"')
NO_FACE = {"旁白", "旧船单"}


def identity(name):
    for part in map(str.strip, name.split("·")):
        if part in BINDINGS:
            return BINDINGS[part]
    return next((key for key, pattern in PATTERNS if pattern.search(name)), "farmer")


def enumerate_bindings():
    names = dict(BINDINGS)
    paths = {}
    for folder in ("companions", "scenes", "npcs", "enemies"):
        for file in sorted((GAME / "data" / folder).glob("*.tres")):
            source = file.read_text("utf8")
            blocks = source.split('"npc_id"')[1:] if folder == "scenes" else re.split(r"\[(?:sub_resource|resource)\b", source)
            for block in blocks:
                fields = dict(FIELD.findall(block))
                name = fields.get("npc_name") or fields.get("display_name")
                if not name or (folder == "enemies" and re.search("狼|野狗|雪熊|苍鹰|沙狐|斑虎|雄狮|巨蟒|凶兽", name) and name != "黑狼韩魁"):
                    continue
                key = identity(name)
                names[name] = key
                for field in ("portrait_path", "sprite_path"):
                    if fields.get(field):
                        paths.setdefault(fields[field], set()).add(key)
    for file in (GAME / "data/dialogs").rglob("*.tres"):
        for who in re.findall(r'^speaker\s*=\s*"([^"]+)"', file.read_text("utf8"), re.M):
            if who not in NO_FACE:
                names[who] = identity(who)
    # A shared generic icon is insufficient evidence to override the speaker's job.
    return names, {path: next(iter(keys)) for path, keys in paths.items() if len(keys) == 1}


def main():
    hero = ["res://art/characters/protagonist_bust.tres"]
    regions = {"hero": hero}
    for sheet, keys in {"xing_fantian": ("master",), **SHEETS}.items():
        uri = ART + sheet + ".png"
        with Image.open(GAME / uri[6:]) as image:
            if image.mode != "RGBA":
                raise ValueError(f"Missing alpha in {uri}")
            width, height = image.size
            if len(keys) == 1:
                regions[keys[0]] = [uri, 0, 0, width, height]
                continue
            for i, key in enumerate(keys):
                col, row = i % 2, i // 2
                # Exclude sheet dividers and antialiasing at adjacent waistlines.
                left, top = col * width // 2 + 6, row * height // 2 + 8
                w, h = width // 2 - 12, height // 2 - 16
                if min(w, h) < 500:
                    raise ValueError(f"Dialogue bust too small: {uri}")
                regions[key] = [uri, left, top, w, h]
    names, paths = enumerate_bindings()
    ids = {key: i for i, key in enumerate(regions)}
    index = {
        "regions": list(regions.values()),
        "names": {name: ids[key] for name, key in sorted(names.items())},
        "paths": {path: ids[key] for path, key in sorted(paths.items())},
        "rules": [[pattern, ids[key]] for key, pattern in RULES],
        "fallback": ids["farmer"],
    }
    (GAME / "data/config/dialog_busts.json").write_text(json.dumps(index, ensure_ascii=False, indent=1) + "\n", encoding="utf8")
    print(f"{len(names)} speaker names; {len(regions)-1} native NPC dialogue busts")


if __name__ == "__main__":
    main()
