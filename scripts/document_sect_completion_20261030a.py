from sect_completion_20261030a import *
dest=ROOT/'assets/previews'/NAME;dest.mkdir(exist_ok=False)
qa=ROOT/'game/build/town_layout_20261029r_qa'
images={
 'desert_caravan.png':ROOT/'assets/staging/town_layout_20261029r/town_project/review-r/CaravanCourt01.png',
 'desert_gate.png':qa/'desert_gate_formal05.png',
 'redrock_highland.png':qa/'redrock_highland_formal06.png',
 'lingyue.png':qa/'ch2_s4_lingyue_gate_arrow06.png',
 'lieyun.png':qa/'ch7_s1_lieyun_valley_ferry_arrow06.png',
 'mingwu.png':qa/'ch7_s2_mingwu_tea_town_arrow06.png'}
for name,src in images.items():shutil.copy2(src,dest/name)
save(STAGE/'preview-copies.json',[{'source':str(src.relative_to(ROOT)),'output':str((dest/name).relative_to(ROOT)),'sha256':sha(src),'byte_copy':sha(src)==sha(dest/name)} for name,src in images.items()])
brief='''## 2026-10-30a 沙漠院墙、赤岩高台与三门派原入口

沙漠四院后墙穿楼已撤/前院口保，西城界移350并闭合；城门建筑全不透明，仅主角遮挡影像alpha.42。赤岩0/240/330连续高台/三真实阶/分层碰撞与室内返层，过场离场宿主停止写新payload。凌月寒潭竹院与烈云灰岩木寨新装配、茗雾29k茶院接原地点；3原业务/内院及锁保。7native各builtin1次仅RGBA0补白原RGBA同、14隔离叶，原A1失败保。正式赤岩7/0、三门派20/0+17/0、箭头高程残余10/0均自然0，原FAIL与7退出ERROR保/实图已看，不复成功矩阵。registryAD875028/native237DD4AD/sectField967606A9/townFieldF28D97DC；171保护含162save精ticks同/82来源同/editor51856保、自有退。图鉴5203/21新路径42图缩略核/非resources同，索引1847源0缺。仅室外与指定问题，原剧情内院沿用，非全ART；详docs/changes/town-layout-and-sect-entries-20261030a.md。

'''
for rel in ['AGENTS.md','docs/current-progress.md','docs/agents/producer-memory.md']:
 p=ROOT/rel;s=p.read_text('utf-8');assert brief not in s;a=s.index('\n')+1;p.write_text(s[:a]+'\n'+brief+s[a:],'utf-8')
notes={
 'docs/agents/system-memory.md':'2026-10-30a：三城离场Field在LoadingManager过场或currentID不同时禁止写return_spawn，避免旧脚污染新payload。门派专用host复用原业务，三级地面物理坐标与视觉高程分开；ExitZone必须configure_marker持久偏移，不能只改Sprite.position被bob覆盖。3原入口/内院/条件锁已通过；Router/全局Field未写。详30a专题。',
 'docs/agents/art-memory.md':'2026-10-30a：7张凌月竹楼/竹门/棍架及烈云木石建筑内置各1次，仅RGBA0补白、原RGBA保持，原A1失败保。茗雾复用29k；资源包记录7新增+26实际复用，不将未实例化ExtResource声明算使用。沙漠后院墙与楼底必须分开，建筑遮挡保持不透明只画主角影像；赤岩地台有连续坎面而非孤立楼梯。详30a专题。',
 'docs/agents/qa-memory.md':'2026-10-30a：私有三阶/新8阶上下、双桥和水阻挡已过；正式赤岩formal06 7/0、三派sects04 20/0、sects05 17/0、箭头sects06 10/0。05脚坐标对不等于视觉箭头对：需跨bob帧核投影锚。首FAIL保，修后只测残余；正式运行7旧退出ERROR保。保护171对象含162save无差，editor51856未操作。详30a专题。',
 'docs/experience-log.md':'2026-10-30a 场景切换与高程：离场场景的每帧回写会覆盖已开始的新目标出生点，须同时以过场状态及当前sceneID阻止；入口碰撞保持地面坐标，箭头用持久投影锚，否则浮动动画会将一次性Sprite偏移还原。楼梯的上/下可走不等于可见高地，台面/连续立面/阶口/角色投影/分层碰撞必须共用同份高程。详docs/changes/town-layout-and-sect-entries-20261030a.md。'}
for rel,note in notes.items():
 p=ROOT/rel;s=p.read_text('utf-8');a=s.index('\n')+1;p.write_text(s[:a]+'\n'+note+'\n\n'+s[a:],'utf-8')
p=ROOT/'docs/changes/sect-remaining-designs-20261029l.md';s=p.read_text('utf-8');a=s.index('\n')+1;p.write_text(s[:a]+'\n> 2026-10-30a更新：凌月已完成本轮室外模块装配并接原入口；烈云谷同时创建，茗雾已有场景接入原正式地点。原内院业务沿用。详[本轮记录](town-layout-and-sect-entries-20261030a.md)。下文设计阶段状态保留为历史。\n'+s[a:],'utf-8')
print('Copied six original screenshots and updated project memories')
