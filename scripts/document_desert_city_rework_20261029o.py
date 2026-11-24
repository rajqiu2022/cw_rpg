"""Write final implementation evidence and prepend a milestone without rewriting history."""
from desert_city_rework_20261029o import *
media=json.loads((STAGE/'media.json').read_text('utf-8'))
published=json.loads((STAGE/'publish.json').read_text('utf-8'))
actual_leaves=[p for p in published['new_files'] if p.replace('\\','/').startswith('.godot/imported/')]
save(STAGE/'publish-count-clarification.json',{'original_receipt':'publish.json','original_imported_leaf_count':8,'correct_total_imported_leaves':len(actual_leaves),'ctex':8,'md5':8,'reason':'Windows backslashes in md5 paths were omitted from the initial startswith count. Original receipt and file list remain unchanged.'})
rows=[]
for key,m in media.items():
    role='正式World的完整城市微缩地标，0.46倍' if key.startswith('world_') else ('赤岩北崖及三个接头，0.5/0.9/0.95倍' if key=='redrock_cliff' else '沙漠近景城廓分段')
    rows.append(f"| {m['label']} | {m['raw_size'][0]}×{m['raw_size'][1]} | [{key} 原图](../../{m['raw']}) | [透明留白派生](../../{m['processed']}) | [工程运行图](../../game/{m['path']}) | {role} |")
table='\n'.join(rows)
doc=f'''# 赤岩镇、沙漠城：原生像素返工已实施（2026-10-29o）

用户明确“直接修改”，本轮已修改当前正式消费者，不再停留在29n审计或私有候选。赤岩场景由B92D7F02更新到**7A2C4FC1**，沙漠场景由C37F2B1C更新到**BB7F127A**；世界两城的入口与ID保留，完整微缩城市已替换。

## 目标与边界

- 依据：[29n逐节点审计与洛阳返工规格](desert-city-pixel-rework-20261029n.md)、当前三城入口合同、洛阳完整compound消费者。
- 已写：两个原生场景，三城目录的world_spec/native_sources/town_registry共3文件，8张新工程图与独立导入叶，资源包、图鉴与索引。
- 保留：原PNG、旧失败记录、原生角色/楼梯/室内控制器、岚溪寨、洛阳与Router/项目配置/任务数据。原文件完整备份在本批staging/backup。
- 本次修正近景像素密度和世界城市地标；**不把这个结果称为两城的街坊密度、所有建筑投影或设计稿完全还原终验**。

## 实际改动

### 赤岩

五处外围崖原2.22～2.63倍用法全部撤掉。北崖用新原生短崖连续搭接；东西侧与关外侧崖复用原有纵向图，在0.95倍下分段重复，保留内侧通路，外围碰撞随真实宽度收窄。关门组件整体围绕原门脚等比缩回，核心1.2→1.0，右翼也不超过1。

关门东端与北部两角新增短崖连接体，旧西南接头移近。首轮全景发现缩小关门后东侧接头有空隙，已补接后重新核对该局部；原三处阶街逻辑及楼梯显示修复未改。

### 沙漠

原整圈城廓5倍显示已停用，改成独立城门、正墙、东西侧墙和四个圆堡。门0.8、正墙0.88、圆堡0.43倍，侧墙两轴均小于1；侧墙源投影与现城界角度不同，采用两轴收缩适配，**不是等比源投影完全还原**。连续墙脚有真实碰撞，城门保留可走中央开口。

五个院墙子树按原比例整体缩回1倍，相关位置、碰撞和视觉范围同步；六处远沙丘改0.9倍分段，不再拉宽成2400～4000px。沙丘仍重复既有形态，本轮没有宣称沙丘形态多样化完成。东墙初稿过近民居，最后整体外移400px，院屋旁留出通道。

### 大地图

赤岩旧单关门、沙漠旧圈墙加两栋大屋组合，均换成各一张专用完整微缩城市。包含完整围合、主门、主楼与次级屋群，两图都用0.46等比倍率。原生1536×1024内容约706.56×471.04逻辑px，对照洛阳原生1536×1024→720×480；透明留白不计主体像素预算。

入口脚仍为赤岩(2000,1050)、沙漠(650,1050)，新实体轮廓分开前门通道；未改原16个世界门户，岚溪寨world_spec整行相同。native_sources更新两scene/world_spec及8个PNG，town_registry只更新严格来源SHA和对应说明，未绕过校验。

## 新资源路径与使用

| 资源 | 原生尺寸 | 原PNG | 派生PNG | 工程PNG | 当前使用 |
| --- | --- | --- | --- | --- | --- |
{table}

8张各1次内置生成；完整prompt及SHA见[生产目录](../../assets/staging/desert_city_rework_20261029o/production)，实际model/provider/cost未返回，保持未知。无CLI fallback。8张只增加RGBA0透明留白，原RGBA逐像素相同，未裁切、缩放、清alpha或补绘；RAW原A1失败仍保留。运行导入8张RGBA与工程PNG完全一致。

来源、派生、运行图共24条路径已加入[资源图鉴](../equipment-skill-catalog.html#resources)，有分类缩略图及点击放大。当前5181条/2874图/2307音；本批24图与24缩略均解码成功，图鉴非resources数据保持一致。旧enclosure_v2明确标为停用，残留ext_resource声明不当作显示节点。复用索引1836文本来源、显式路径0缺失。

## 检查与失败保留

1. 私有首轮import01虽然进程返回0，但有资源头顺序解析错误，不算通过。capture01的自有PID130464因此被停止；原run收据错误写NATURAL_EXIT，已另存更正说明，原收据/日志保留。修正ext_resource在sub_resource之后的错误顺序。
2. 私有capture02 PID128660自然0/空stderr：257检查0失败，含静态倍率、出生点、门柱实体、正式主角真实W输入穿沙漠城门，9张原生图。
3. 局部residual03 PID47596自然0/空stderr：25检查0失败；8图RGBA导入、3新崖接头、赤岩门真实穿越、5院真实进返和新墙实体。4图已亲看。旧全矩阵未重跑。
4. 东墙外移后east04 PID98244自然0/空stderr：仅新墙阻挡和屋侧净空2检查0失败，局部与全景2图已亲看；不复先前5院/两门矩阵。
5. 正式World首轮86896因为QA继承旧脚本提前编译FieldPrimaryHud，GameState autoload符号尚未注册，31检查1失败/0图，原证据保留。只改QA消除提前类型依赖，运行源码无改动。
6. 正式后继129984自然退出0，**57检查0失败、两城真实Space进城再返回**；新整城地标贴图、实际门前可进入、正式入城新模块、原16门户、同一会话状态/返回脚/首末来源与存档均通过。4张正式原生图已亲看，0 QA角色/相机位置赋值。依旧有既有7条退出纹理/RenderingServer ERROR，不冒称空stderr或全局退出缺陷修复。
7. [修改后像素审计](../../assets/staging/desert_city_rework_20261029o/native-density-after.json)：赤岩142、沙漠111个直接静态Sprite，共253个，逻辑放大0、1920×1080/跟随0.9镜头放大0。未覆盖继承实例/动画/shader UV，不把静态审计称全游戏验收。

发布5个旧工程目标，新增8 PNG＋8import描述＋16缓存叶＋1资源包；初始publish收据因Windows反斜杠漏数md5而写8叶，另存更正为16叶，不改原清单证据。最终245保护对象含171个存档路径，SHA/bytes/mtime_ns全部同；5发布目标与严格来源manifest保持有效。编辑器51856保留，本批自有进程已退，未控制其他会话。

## 实机画面

正常近景的赤岩北崖（原生短段）：

![赤岩北崖](F:/Code/RPG_GAME/assets/staging/desert_city_rework_20261029o/town_project/review/redrock_north03.png)

正式沙漠入城的新独立城门：

![沙漠新门墙](F:/Code/RPG_GAME/game/build/desert_city_rework_20261029o_qa/actual/129984/desert_native_town.png)

正式大地图两张完整城市地标：

![赤岩大地图地标](F:/Code/RPG_GAME/game/build/desert_city_rework_20261029o_qa/actual/129984/redrock_native_world.png)

![沙漠大地图地标](F:/Code/RPG_GAME/game/build/desert_city_rework_20261029o_qa/actual/129984/desert_native_world.png)

## 当前使用

原场景路径直接F6即可加载更新版，也已接正式世界。当前运行进程若已缓存旧场景，退出该游戏后重开才会使用新版本；无需关闭编辑器。停止本批已通过组件复测，将画面交用户细看。后续若继续做街坊密度/侧墙投影/沙丘变化，必须作为新的明确工作记录，不能把本批清晰度修正冒充这些项目已完成。
'''
target=ROOT/'docs/changes/desert-city-native-rework-20261029o.md'
assert not target.exists();target.write_text(doc,'utf-8')
summary='''## 2026-10-29o 赤岩、沙漠原生像素返工已正式

用户“直接修改”已执行：赤岩7A2C4FC1/沙漠BB7F127A，外围崖短段搭接及0.95原生侧崖、门组缩回；沙漠5倍整圈图退，独立门/正侧墙/圆堡、5院整体原生与沙丘0.9分段，东墙外移400。8新native各builtin1次/只RGBA0补白原RGBA同，World两专用完整微缩城0.46且原脚保；3来源合同后继、0Router写。静态253节点0放大；私有257/0→新域25/0→东墙2/0，正式129984自然0/57检查0/两城真Space进返4图亲看，旧7退出ERROR保。早期资源头和QA提前HUD编译FAIL保。245保护含171save精ticks同/editor51856保；图鉴5181/24新路径48图缩略核/非resources同，索引1836源0缺。侧墙两轴收缩、沙丘重复/街坊密度非设计全ART，停止本批成功复测。详docs/changes/desert-city-native-rework-20261029o.md。

'''
for rel in ['AGENTS.md','docs/current-progress.md','docs/agents/producer-memory.md','docs/experience-log.md']:
    p=ROOT/rel;old=p.read_bytes();assert summary.encode() not in old
    end=old.index(b'\n')+1
    assert p.read_bytes()==old
    p.write_bytes(old[:end]+b'\n'+summary.encode('utf-8')+old[end:])
print('Document and four milestone entries written')
