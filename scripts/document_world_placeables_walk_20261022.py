"""Publish paths, actual use state and sprite/placeable distinction from finite receipts."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'assets/raw/world_placeables_walk_20261022'

def main():
    data=json.loads((BASE/'current-candidates.json').read_text('utf-8'))
    gallery=json.loads((ROOT/'tmp/world_placeables_walk_20261022/gallery-final.json').read_text('utf-8'))
    review=json.loads((BASE/'walk-review.json').read_text('utf-8'))
    assert len(review['families'])==10
    names={'scene_props':'场景生活摆件','field_objects':'野外互动与采集外观','small_buildings':'小建筑组件'}
    link=lambda p:'['+p+']('+str(Path(p).relative_to(BASE.relative_to(ROOT))).replace('\\','/')+')'
    preview=lambda p:'['+Path(p).name+'](../../previews/world_placeables_walk_20261022/'+Path(p).name+')'
    lines=['# 地图精灵与可放置物件补充 · 2026-10-22','','本批明确区分地图精灵、对话立绘、背包物件外观和地图实体组件。新增24件场景/大世界物件与小建筑，以及10名既有NPC每人4张独立原生下行行走帧，共64张当前候选PNG；配套10张静态待机沿用上一批。另保留8张相位失败稿，实际72原PNG。','','[分类图鉴 / 点击放大](../../../docs/equipment-skill-catalog.html#resources) · [当前引用清单](current-candidates.json) · [原图核验](integrity-final.json) · [行走有限复核](walk-review.json)','','## 当前使用状态','','全部未导入、未绑定game。行走仅下行，不是四向；未输出合格运行atlas。原图仍有身高/脚位漂移，动画分原始播放与对齐查看两版，对齐查看只是按诊断可见范围缩放/平移适配，未改变原PNG或alpha，也不替代完整A>0检查。GIF不是实际游戏角色验收。', '',f"当前64PNG完整A>0四边10%留白：{data['full_alpha_margin_pass']}通过，{data['full_alpha_margin_fail']}失败。原失败保留。物件只有可放置的美术形制，碰撞、交互、采集奖励和任务绑定未做。",'','## 24件可放置组件','']
    for kind,title in names.items():
        lines += ['### '+title,'','| 组件 | 原图完整路径 | 用途 / 当前状态 |','|---|---|---|']
        for r in data['assets']:
            if r['kind']==kind:lines.append('| '+r['label']+' | '+link(r['output'])+' | '+r['intended_use']+'；未接入 |')
        lines.append('')
    lines += ['## 10套地图待机＋下行4帧','','下面的待机是地图全身精灵，另行保存的对话立绘不计作行走帧。四张原图都是单独的内置输出，不由重复站姿或程序插帧凑成。相位意图为着地A→经过A→着地B→经过B；实际有限结论见walk-review，不能凭文件不同自动判通过。','']
    for f in data['families']:
        lines += ['### '+f['family'],'','待机：['+f['idle_path']+'](../../../'+f['idle_path']+')','', ' | '.join(['[对齐查看动画](../../previews/world_placeables_walk_20261022/'+Path(f['aligned_preview']).name+')','[原始播放](../../previews/world_placeables_walk_20261022/'+Path(f['raw_preview']).name+')']),'']
        lines += [str(i)+'. '+link(p) for i,p in enumerate(f['frames'],1)]+['']
    lines += ['## 保留失败与制作来源','','2张原整sheet与2张相位修正版仍重复两种着地姿势；首人4张纯文本逐帧仍同脚在前，8张全部留作弃用追溯。其余8张原整sheet任务和36张原逐帧任务未调用，不能计作出图。改用逐帧身份参考＋独立技术腿部姿态图后另登记40帧。姿态图由程序绘制简单诊断关节示意，不是正式游戏视觉，也不取代原生图片。','','| 失败原稿 | 原图路径 |','|---|---|']
    lines += ['| '+r['label']+' | '+link(r['output'])+' |' for r in data['history']]
    lines += ['','内置imagegen实际72调用＝24新物件＋48参考/编辑输出（40当前行走帧＋8失败稿）。116个唯一skip任务中44个被后继替代、未执行；每个已执行ID仅1次，无CLI fallback。工具未披露model/provider/cost，meta留空。逐PNG与原始工具输出/meta/prompt SHA一致，15初始设计/身份来源和4技术姿态图SHA保持，原百图101PNG保持，旧tasks前缀字节保持。','','提示词集：[prompts/world_placeables_walk_20261022](../../../prompts/world_placeables_walk_20261022/)。原图分类的3张真实alpha联系表在同名previews目录。未本地清背景/删alpha/扩画布、无engine/import/game写入或用户进程操作，AP另线状态不在本批验收范围。','','## 后续使用前待办','']+['- '+s for s in review['limitations']]
    (BASE/'README.md').write_text('\n'.join(lines)+'\n','utf-8')
    summary=gallery['summary']
    change=['# 地图精灵与可放置物件补充记录','','change-id: world-placeables-walk-20261022','','用户确认优先地图待机＋行走序列，并明确道具包含场景/大世界摆件、小建筑。新增24件物件（生活摆件8、野外物件8、小建筑8）与10NPC×4独立下行帧；沿用10待机，当前64PNG，另留8失败稿，共72原PNG。没有把立绘或背包外观计成地图行走。','','整sheet两轮与首人文本逐帧未通过相位检查，失败全保；加技术腿部姿态参照后完成40逐帧候选。参考是旧NPC身份＋程序技术关节示意，最终图像均内置原生输出。原图有尺度/脚位漂移，保原始和对齐查看GIF共20份，无合格运行atlas/四向/Field信用。', '',f"图鉴现{summary['total']}文件/{summary['images']}图片/{summary['audio']}音频。新增72记录：64候选、8弃用，10条行走卡带对齐查看动画，可放大和另开原图。72缩略图/原图路径与10GIF链接有限核验通过，旧四类及非resources JSON完全相同；复用索引同步24物件和10套待机/4帧/双预览完整路径。浏览器实交互信用另列，不把逻辑检查当鼠标实测。",'',f"实际72调用，116新登记/44未执行，不以任务数凑图片数。72PNG逐源/meta SHA同、15设计身份来源＋4技术参考同、旧百图101PNG与旧tasks前缀保持。当前64完整alpha留白{data['full_alpha_margin_fail']}失败，原限制保留，无本地alpha处理或game/引擎操作。",'']
    change += ['- '+s for s in review['limitations']]
    change += ['','[完整路径与当前状态](../../assets/raw/world_placeables_walk_20261022/README.md) · [当前引用清单](../../assets/raw/world_placeables_walk_20261022/current-candidates.json) · [资源图鉴](../equipment-skill-catalog.html#resources)']
    (ROOT/'docs/changes/world-placeables-walk-20261022.md').write_text('\n'.join(change)+'\n','utf-8')
    print(json.dumps({'subjects':34,'current_pngs':64,'raw_pngs':72,'npc_walk_families':10,'placeables':24,'gallery':summary}))

if __name__=='__main__':main()
