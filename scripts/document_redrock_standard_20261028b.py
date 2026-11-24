"""Catalog/data integrity and concise handoff for the Luoyang-standard Redrock slice."""
import json
import re
import shutil
from urllib.parse import unquote

from redrock_luoyang_standard_20261028b import ROOT,RAW,STAGE,PROJECT,ART,SCENE,save,sha
from build_redrock_standard_20261028b import ROOM

def main():
    proofpath=PROJECT/'artifacts/verification.json';proof=json.loads(proofpath.read_text('utf-8'))
    if proof.get('true_space_actions')==4:
        original=PROJECT/'artifacts/verification-original-metadata.json';assert not original.exists();shutil.copyfile(proofpath,original)
        proof['true_space_actions']=3
        proof['metadata_correction']='原头计数4误把Esc算作Space，实际3Space+1Esc；79检查/运动样本及原报告完整保存，不重跑成功项。'
        save(proofpath,proof)
    current=json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8'),re.S)[1])
    before=json.loads((STAGE/'catalog-before.json').read_text('utf-8'))
    assert {k:v for k,v in current.items() if k!='resources'}=={k:v for k,v in before.items() if k!='resources'}
    pack=json.loads((ROOT/'game'/ART/'resource-pack.json').read_text('utf-8'));raw=json.loads((RAW/'resource-pack.json').read_text('utf-8'))
    records={r['diskPath']:r for r in current['resources']['records']}
    targets={r['output'] for r in pack['assets']+raw['assets']};assert len(targets)==32
    for path in targets:
        row=records[path];assert row['status']=='candidate' and row['usageCount']>=1
        for key in ('url','thumbnail'):assert (ROOT/'docs'/unquote(row[key])).is_file()
    portrait=records['game/'+ART+'/keeper_portrait.png'];assert portrait['category']=='portrait'
    publication=json.loads((STAGE/'publication.json').read_text('utf-8'))
    differences=[r['path'] for r in publication['files'] if sha(ROOT/r['path'])!=r['sha256']];assert not differences,differences
    protection=json.loads((STAGE/'protected-after.json').read_text('utf-8'))
    summary=current['resources']['summary']
    save(STAGE/'catalog-verification.json',{'rows':32,'raw':4,'editor_images':28,'portrait_category_correct':True,'thumbnail_and_original_paths_exist':True,'nonresources_exact_equal':True,'all_published_SHA_still_equal':True,'browser_click_tested':False,'summary':summary})
    lines=['# 赤岩生活街段与驿舍前厅 · 2026-10-28b','',f'Godot打开[当前redrock_town.tscn](../game/{SCENE})，按 **F6**。进入关门后到驿舍门前按空格，进入一处[独立前厅](../game/{ROOM})；前厅入口按空格原脚返回。WASD移动、Shift快走、Tab全景/跟随、1—6观察分区、Esc关闭说明。','', '本轮按[洛阳规范](luoyang-city-masterplan-20261019z.md)先完成生活街段：主街/次街/院巷分级，驿舍与牲口棚各有院门，修坊和水院有真院界。人物112px标尺与35×25脚体保持；房体、院墙与家具均有实际阻挡。赤砂岩平顶/木棚地域风格保持，不搬中原瓦檐。','', '![驿舍前厅原生渲染](../assets/staging/redrock_luoyang_standard_20261028b/town_project/artifacts/inn-hall-final.png)','', '## 本轮完成','', '- 四处院界使用同一完整原PNG的三个原生region视图分层，按后墙/侧墙/前墙落脚排序；未输出裁切PNG、未改alpha，三视图覆盖全原画布。', '- 重排驿舍、牲口棚和货物/饮水槽，撤除挡院口的一处民居，移动三处岩台；主街320、次街200、院巷144为材质目标宽。新关键腿和主街左右肩已用完整35×25脚体实测；不把中心线通过冒称全域宽带净空。', '- 驿舍一主门对应一处缓存前厅。同一角色进返，原位返回；室外地面、房屋、院墙与前厅实例保持。没有为了说明面板重建静态场景。', '- 前厅柜台、桌、凳、酒茶架分别是独立原生节点/碰撞，木家具复用洛阳已入库原PNG，原像素保持；柜台/桌按成人尺缩小后，碰撞同步等比收缩，不留旧大体。', '- 普通中年女掌柜新增地图待机与同人肖像；本地说明面板只做布局查看，非新正式NPC、剧情对白、付费服务或商店经济。仍无行走序列。','', '## 路径与使用状态','', '|资源|工程路径|原始PNG|当前消费者|','|---|---|---|---|']
    for r in pack['assets']:lines.append(f'|{r["label"]}|[{r["key"]}.png](../{r["output"]})|[来源](../{r["source"]})|`{r["scene"]}`；编辑草案|')
    lines += ['', '[图鉴](equipment-skill-catalog.html#resources)新增32记录（4原图、28工程图），分类缩略/原图入口可查；多份有效草案引用的同一原图合并消费者，不覆盖旧28a消费者。', '', '新4原图为内置image_gen各1次/无fallback/CLI；[独立完整提示词](../assets/staging/redrock_luoyang_standard_20261028b/production/prompts/tasks.yaml)。肖像派发前加地图待机为身份锚并再次真实renderer预检。4张完整A>0边距均FAIL保，原PNG未本地处理，不借其它批许可；装配进草案不等于正式美术准入。', '', '## 验证与保护','', '独立GPU自然退出0，79检查0失败/3094运动采样：28贴图导入全RGBA精确，院墙分层/真阻挡、5条新路线往返及主街双肩，真实Space进厅/掌柜查看/返街与Esc恢复，同角色/原脚、静态节点和缓存前厅保持。QA路线用明确定位起点，不冒连续世界旅行。首报告头误写4Space（实际3Space+1Esc），仅纠正元数据，原报告另存，79检查原值保持。', '', '最后只修桌台尺与观察镜头提示：2新家具负控+2张原图通过/空stderr，不重79检查或旧洛阳/关防矩阵。首隔离project颜色字面量缺前导0造成配置失败及导入叶不存在断言，原记录保留；修配置后导入/实机才为当前信用。', '', f'本批发布119新增文件，含28PNG/84专用导入叶、控制GD/UID、shader/UID和两Scene/清单。{protection["checked"]}保护项（含{protection["save_files_checked"]}save/备份）SHA/bytes/mtime首末同={protection["all_equal"]}；旧28a、公共Router/Field/project/根tasks与用户编辑器不由本批改动。图鉴总{summary["total"]}项/{summary["images"]}图/{summary["audio"]}音；非resources精同。', '', '证据：[79检查](../assets/staging/redrock_luoyang_standard_20261028b/town_project/artifacts/verification.json)、[最后比例/提示](../assets/staging/redrock_luoyang_standard_20261028b/town_project/artifacts/verification-final.json)、[发布](../assets/staging/redrock_luoyang_standard_20261028b/publication.json)、[保护](../assets/staging/redrock_luoyang_standard_20261028b/protected-after.json)。', '', '## 后续边界','', '当前为局部生活街段与一处前厅的编辑草案。民巷/完整外峡壁与台地收口、其他独立室内、正式世界接线、任务/经济与稳定NPC行走仍待；不能把本轮79项授为全城美术或全域通行终验。其他城市在各自目录施工，公共接线待统一串行整合。','']
    (ROOT/'docs/redrock-luoyang-standard-20261028b.md').write_text('\n'.join(lines),'utf-8')
    (RAW/'README.md').write_text('# 赤岩生活街段补图\n\n院界/空前厅/女掌柜待机/同人肖像4原图，原RGBA未处理、A1留白失败保留。字节相同工程副本用于局部编辑草案。\n\n[路径、用途、当前Scene与提示词](../../../docs/redrock-luoyang-standard-20261028b.md)。\n','utf-8')
    print(json.dumps({'records':32,'published_exact':len(publication['files']),'summary':summary},ensure_ascii=False))

if __name__=='__main__':main()
