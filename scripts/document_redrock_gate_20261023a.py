"""Archive scoped resource selection and review-only previews; never changes native PNGs."""
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'assets/raw/redrock_gate_resources_20261023a'
PREVIEW=ROOT/'assets/previews/redrock_gate_resources_20261023a'


def main():
    manifest=json.loads((BASE/'manifest.json').read_text('utf-8'))
    assert len(manifest['assets'])==13 and all(a.get('output') for a in manifest['assets'])
    notes={
      'gate':'门洞首稿不符合320净宽，保留历史，不作为当前关门。',
      'gate_opening':'加宽修正版；六条真alpha0截面约314–353世界像素，门底一截仍不足320；声明矩形内352个非零alpha像素，未授完整门洞通过。',
      'tower':'平顶岗楼外形候选；成人门尺度/拟定240脚印适配未认证，不直接当可入建筑。',
      'front_wall':'独立正面墙，左右端缝、砌块尺度与关门地脚接口待装配核对。',
      'side_wall':'独立纵深侧墙，非旋转正面墙；斜向地脚/转角接缝尚未匹配平面。',
      'cargo':'可放置在场景和大世界的货包实体；非背包图标，未绑定任务、奖励或拾取。',
      'trough':'场景石制饮水槽实体；非背包图标，未绑定交互或碰撞。',
      'guard_idle':'匿名关卒地图待机，不是立绘；服饰/腰包侧沿实际源图，未创建正式NPC_ID。',
      'guard_portrait':'引用新关卒待机的同人全身立绘；身份形制可辨，不计为地图动作。',
    }
    for key in ['walk_f01','walk_f02','walk_f03','walk_f04']:
        notes[key]='下行四相原生帧候选；左右脚接触可辨、经过相位偏弱，衣摆/脚底漂移；四帧显著轮廓高度差26、基线差27原像素，非合格运行atlas/四向动画。'
    rows=[]
    for a in manifest['assets']:
        src=ROOT/a['output'];assert hashlib.sha256(src.read_bytes()).hexdigest()==a['sha256']
        row={**a,'review_note':notes[a['key']],'rejected':a['key']=='gate'}
        if a['key']=='walk_f01':row['animation_preview']='assets/previews/redrock_gate_resources_20261023a/guard_walk_down_original.gif'
        rows.append(row)
    pack={'status':'FIRST_RESOURCE_BATCH_CANDIDATES_NOT_RUNTIME_READY','native_originals':13,'current_candidates':12,
          'retained_superseded':1,'builtin_calls':13,'formal_enabled':False,'assets':rows}
    (BASE/'resource-pack.json').write_text(json.dumps(pack,ensure_ascii=False,indent=2)+'\n','utf-8')
    manifest['status']=pack['status']
    (BASE/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n','utf-8')
    # Current module contact sheet keeps the old one containing the first gate intact.
    font=ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',22);sheet=Image.new('RGBA',(1500,800),'#253139')
    bykey={r['key']:r for r in rows}
    for i,key in enumerate(['gate_opening','tower','front_wall','side_wall','cargo','trough']):
        a=bykey[key];im=Image.open(ROOT/a['output']).convert('RGBA');im.thumbnail((476,344),Image.Resampling.LANCZOS)
        x=(i%3)*500;y=(i//3)*400;sheet.alpha_composite(im,(x+(500-im.width)//2,y+48+(344-im.height)//2))
        ImageDraw.Draw(sheet).text((x+12,y+10),a['label'],font=font,fill='#e4d5bd')
    sheet.convert('RGB').save(PREVIEW/'current-modules-alpha-contact.jpg',quality=93)
    lines=['# 赤岩关镇 · 峡口关门首批资源','',
      '状态：13张内置原生PNG，12当前候选＋1门洞不足首稿保留；均未导入或接入游戏。用户已选赤岩整体图开始制作，不改变其他三套设计的审批状态。',
      '', '按类别存放：`building/`建筑墙体、`scene_prop/`场景与大世界实体、`npc_sprite/`地图待机、`npc_walk/`下行逐帧、`portrait/`同人立绘。',
      '', '[完整制作文档](../../../docs/redrock-gate-resources-20261023a.md) · [当前选择与复核](resource-pack.json) · [分区技术平面](../../staging/redrock_gate_20261023a/revision2/district-footprint-plan.png)',
      '', '| 素材 | 原图路径（相对本目录） | 当前使用情况 |','|---|---|---|']
    for a in rows:
        local=Path(a['output']).relative_to(BASE.relative_to(ROOT)).as_posix()
        lines.append(f"| {a['label']} | [{local}]({local}) | {a['review_note']} |")
    lines.extend(['','13张完整A>0四边10%留白均未通过，原图/alpha未本地修改；查看器可能显示隐藏RGB晕色，以真正alpha合成为准，不能因此当背景已去净或完整alpha已过。',
      '原始行走GIF仅统一缩小整画布查看，无逐帧归一化/平移，保留实际漂移。具体模型/provider/cost未披露均为null，使用内置工具，无CLI或自动fallback，各ID一次调用。',
      '0引擎/导入/game写/用户进程控制；门洞、成人门尺度、接缝、导航、精灵动画与正式绑定仍待，不冒分区完成。',''])
    (BASE/'README.md').write_text('\n'.join(lines),'utf-8')
    print(json.dumps({'native_originals':13,'current_candidates':12,'history':1,'categories':5}))


if __name__=='__main__':main()
