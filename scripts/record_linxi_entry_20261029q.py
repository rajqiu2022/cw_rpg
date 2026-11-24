from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
summary='''## 2026-10-29q 林西村民房入口已修复

正式 RouterC0EDAB77/EXE959A8F9、室MapADC0AFC3/村Scene68B2CAD1：旧墙内落点限定本室回门、进返同箭头、墙面退可走与筐篓阻挡、沈青禾移开门口。133864原NPC截Space失败保，61900复现旧nearest落右墙；41340自然0/22检查0实际进返及旧缓存/旧脚恢复过，原图发现筐篓后仅117784自然0/6检查0真D停地板与A离开，五原图亲看。九必要来源完整18边/旧keys保，Field/project/PNG未改，旧七退出ERROR保。177基线173精同+2授权差+2外部save更新，后两现值保/原整体guardFAIL不洗，editor51856未操作、自有全退。仅本室入口修复，停止成功组件复测；详docs/changes/linxi-cottage-entry-20261029q.md。

'''
def insert(path,body):
    p=ROOT/path;raw=p.read_bytes();mark=body.splitlines()[0].encode('utf-8')
    assert mark not in raw,path
    split=raw.index(b'\n')+1
    p.write_bytes(raw[:split]+b'\n'+body.encode('utf-8')+raw[split:])
for path in ['AGENTS.md','docs/current-progress.md','docs/agents/producer-memory.md']:
    insert(path,summary)
insert('docs/agents/system-memory.md','''2026-10-29q林西民房：旧坐标被最近安全搜索移到仍在旧宽多边形内的右墙，不能只验证候选被拒；本室 helper 校验地板/家具与足缘，无效旧脚回明确门前，合法室内脚保，门户配对覆盖旧缓存并从对应外门读返脚。Router两窄hunk+9必要来源后继17→18完整边，现C0EDAB77/EXE959A8F9；全局Field保持。沈青禾距箭头原小于118px会截Space，移位而不改互动优先级；筐篓补真实阻挡。仅此室，详docs/changes/linxi-cottage-entry-20261029q.md。

''')
insert('docs/agents/qa-memory.md','''2026-10-29q林西入口实际：首133864被NPC截Space自然1；61900复现旧脚(.835,.60)经nearest至右墙(.837883,.646675)。修后41340自然0/22检查0，真Space入/S+Space返、旧缓存/错误脚恢复、合法脚保及严格来源过；虽墙限数值过，图中仍站筐篓，后仅117784残余6/0真D碰/A离开且原图接受。旧7退出ERROR保。177基线173同/2授权/2save外变在自有测试之间，原guardFAIL留而非洗全PASS；不恢复save，现值稳定。详docs/changes/linxi-cottage-entry-20261029q.md。

''')
insert('docs/experience-log.md','''2026-10-29q：入口正常默认点不代表旧坐标恢复正常；候选被拒后，nearest搜索仍可能选到错误大可走区里的墙。门户往返应由对应箭头确定，室内合法续玩位置与入门位置分开处理。要在箭头处真按Space检查邻近NPC是否截获；数值停止在墙前仍可能踩到画内筐篓，需看原图补局部阻挡。继承成功路径，仅检新残余；中途外部保存应记录并保留现值，不能回滚或声称原基线零差。

''')
print('Recorded Linxi scoped repair and retained prior histories')
