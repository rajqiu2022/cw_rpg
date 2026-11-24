"""Narrow gallery/usage/protection documentation for the published Redrock draft."""
import json
import re
import sys
from pathlib import Path
from urllib.parse import unquote

from build_redrock_town_20261028a import ROOT,STAGE,RAW,PROJECT,SCENE,ART,save,sha


def catalog():
    html=(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8')
    return json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',html,re.S)[1])


def before():
    assert not (STAGE/'catalog-before.json').exists()
    save(STAGE/'catalog-before.json',catalog())


def document():
    layout=json.loads((STAGE/'layout.json').read_text('utf-8'))
    publication=json.loads((STAGE/'publication.json').read_text('utf-8'))
    protected=json.loads((STAGE/'protected-after.json').read_text('utf-8'))
    pack=json.loads((ROOT/'game'/ART/'resource-pack.json').read_text('utf-8'))
    lines=['# 赤岩关镇六区编辑布局 · 2026-10-28a','',f'已写入主工程：[{SCENE}](../game/{SCENE})，Godot打开后按 **F6**。这是原生节点的六区可走动布局草案；已确认的总规继续作为美术目标，当前外边岩壁/街沿围合仍需深化。未加入正式世界入口。','', 'WASD/方向键移动，Shift快走，Tab全景/跟随，1—6分区镜头，R回关外，空格查看邻近物件，Esc关闭本地说明。镜头定位不传送人物；查看员沿旧匿名112px待机图移动，不宣称行走动画已完成。','', '![独立Godot原生全景](../assets/staging/redrock_town_20261028a/town_project/artifacts/overview-editor.png)','', '## 已落地内容','', '六区：峡口关门、阶街民巷、驿舍马院、石作修坊、蓄水小院、高台望关。连体关防相对变换/碰撞继承，仅整体平移；新增低矮岩台和折返主路、开放棚湾、十一处民居、井院与低物件，共40个实例，另有独立关防和查看角色。所有几何与碰撞都是Scene内可编辑原生节点。','', '[技术平面](../assets/staging/redrock_town_20261028a/layout-plan.svg)只用于节点与动线定位，不冒充新AI总规或可玩背景。地面使用原生土/岩纹理的世界坐标材质混合，道路软边，未将概念图铺成背景。','', '## 资源路径与当前使用','', '|资源|工程PNG|原始来源|当前使用|','|---|---|---|---|']
    for r in pack['assets']:
        lines.append(f'|{r["label"]}|[{Path(r["output"]).name}](../{r["output"]})|[{Path(r["source"]).name}](../{r["source"]})|六区编辑草案；未接正式世界|')
    lines += ['', '新增生图3张（平顶民居、牲口棚、层台岩坎）各内置1次、无fallback/CLI，原PNG和工具输出字节同。[完整提示词/独立队列](../assets/staging/redrock_town_20261028a/production/prompts/tasks.yaml)。20工程贴图均字节原样复制，没有新本地裁切、补白、缩图或清alpha；新3与25a旧8的完整A1留白失败仍保留，只在草案看布局，不获得正式美术准入。既有许可没有扩用。', '', '## 验证结果与限制','', '首独立GPU实际54检查/2失败/5332运动采样：20导入全RGBA、关门/主路与其它支路、4阻挡负控、W输入、Tab/分区镜头、空格说明/关闭/重置通过；民巷前岩台整段放大过高阻路，原整次FAIL及图片/日志保存在initial-failed-run。没有删碰撞来掩盖。', '', '修订为两段较短等比岩台并补六侧巷房后，仅运行残余：14检查0失败/2438运动采样，自然退出0，继承原52成功组件，不重导入/旧输入矩阵。独立最后3镜头标题/3原生图片检查0失败，stderr空。没有把QA显式定位称连续玩家旅行，也没有重跑洛阳组件。', '', f'只发布{len(publication["files"])+1}新增文件：20 PNG、60独立导入叶、GD/UID、shader/UID、Scene及资源清单。没有复制全局UID数据库、运行生产全import或操作用户编辑器。{protected["checked"]}观察项首末SHA/bytes/mtime保持={protected["all_equal"]}，其中save/备份文件{protected["save_files_checked"]}；保护范围是本次列出的共享脚本/项目与旧赤岩及save，不冒称全工程未变。', '', '仍待：原图留白准入、外部峡壁/台地连续收口、街沿/院落围合与精细密度、生活NPC稳定行走和同人立绘、室内/任务服务、正式世界接线。四十节点的局部验证不等于完整设计艺术终验或完整NPC系统。', '', '## 与另一城市并行','', '两对话分别持有各自城市的场景/脚本/素材目录，使用独立project与user-data目录验证。公共Router/Field/autoload、project.godot、根prompts/tasks及用户编辑器不由本批改动。共享接线需要在城市草案稳定后串行整合；本批已落地的文件不依赖另一个城市修改。没有以用户同意并行为由向另一个对话自动发送消息。', '', '证据：[初次FAIL](../assets/staging/redrock_town_20261028a/initial-failed-run/verification.json)、[残余通过](../assets/staging/redrock_town_20261028a/town_project/artifacts/verification-remaining.json)、[最终视觉](../assets/staging/redrock_town_20261028a/town_project/artifacts/final-visual.json)、[发布清单](../assets/staging/redrock_town_20261028a/publication.json)、[保护末检](../assets/staging/redrock_town_20261028a/protected-after.json)。','']
    (ROOT/'docs/redrock-town-20261028a.md').write_text('\n'.join(lines),'utf-8')
    (RAW/'README.md').write_text('# 赤岩六区装配补图\n\n3内置原生透明候选：民居/牲口棚/岩台。原PNG保留，完整A1留白失败不清除。字节相同副本已供六区编辑场景，不是正式世界准入。\n\n[工程、路径、验证与使用限制](../../../docs/redrock-town-20261028a.md)。\n','utf-8')
    save(ROOT/'assets/raw/redrock_desert_life_20261025a/usage-update-20261028a.json',{'status':'RAW_UNCHANGED_COPIES_IN_EDITOR_LAYOUT','scene':'res://'+SCENE,'assets':[r for r in pack['assets'] if r['source'].startswith('assets/raw/redrock_desert_life_20261025a/')],'formal_admission':False})


def verify():
    current=catalog();old=json.loads((STAGE/'catalog-before.json').read_text('utf-8'))
    assert {k:v for k,v in current.items() if k!='resources'}=={k:v for k,v in old.items() if k!='resources'}
    bypath={r['diskPath']:r for r in current['resources']['records']}
    pack=json.loads((ROOT/'game'/ART/'resource-pack.json').read_text('utf-8'))
    native=json.loads((RAW/'resource-pack.json').read_text('utf-8'))
    targets={r['output'] for r in pack['assets']+native['assets']}
    assert len(targets)==23 and targets<=bypath.keys()
    for p in targets:
        row=bypath[p]
        assert row['usageCount']>=1 and row['status']=='candidate'
        for f in ('thumbnail','url'):assert (ROOT/'docs'/unquote(row[f])).is_file()
    for r in pack['assets']:
        assert sha(ROOT/r['source'])==r['sha256']==sha(ROOT/r['output'])
    publication=json.loads((STAGE/'publication.json').read_text('utf-8'))
    pubdiff=[r['path'] for r in publication['files'] if sha(ROOT/r['path'])!=r['sha256']]
    assert not pubdiff,pubdiff
    save(STAGE/'catalog-verification.json',{'new_batch_records':23,'native_candidates':3,'editor_copies':20,'thumbnail_full_paths_exist':True,'nonresources_exact_same':True,'all_85_published_files_still_SHA_same':True,'images_modified':False,'browser_click_tested':False,'summary':current['resources']['summary']})
    print(json.dumps({'records_checked':23,'publication_files_checked':len(publication['files']),'summary':current['resources']['summary']},ensure_ascii=False))


if __name__=='__main__':
    {'before':before,'document':document,'verify':verify}[sys.argv[1]]()
