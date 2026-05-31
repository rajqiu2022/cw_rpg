"""
渲染 NPC sprite prompt，输出到文本文件供手动粘贴。
读取 prompts/templates/npc_batch_ch1.yaml 中的角色描述，
使用 sprite_npc_idle_4f_v1 模板渲染。
"""
import os
import yaml

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def load_shared():
    with open(os.path.join(PROJECT, 'prompts/templates/_shared.yaml'), encoding='utf-8') as f:
        return yaml.safe_load(f)

def load_batch():
    with open(os.path.join(PROJECT, 'prompts/templates/npc_batch_ch1.yaml'), encoding='utf-8') as f:
        return yaml.safe_load(f)

def render_idle_prompt(npc, direction, shared):
    """渲染 NPC idle 4帧 prompt"""
    style = shared['style_anchor']
    negative = shared['negative']
    name = npc['character_name']
    appearance = npc['character_appearance']
    dir_label = direction['label']

    prompt = f"""{style.strip()}

生成一个游戏NPC的4帧站立idle精灵图。严格按照以下要求：

【角色】{name}，金庸武侠风格。{appearance}
该角色朝向画幅{dir_label}。4帧中角色的长相、发型、服装完全一致。

【动作】
4帧为一个站立idle循环。双脚始终站立不动。
仅衣服下摆和头发有轻微飘动（幅度极小，自然微风感）。
上半身和头部完全稳定，不晃动。
第4帧结束后可无缝回到第1帧。

【布局】
画布横向宽幅，4个等宽竖条从左到右水平排列。
每个竖条宽度固定为256px，总画布宽度1024px，高度256px。
从左到右依次为第1至第4帧。
竖条之间无分隔线。

【每帧内角色】
角色头顶到脚底的高度占画布高度的60%（约154px）。
角色宽度约50-55px，人体宽高比约1:3。
角色水平居中于本竖条内，即角色中心x坐标 = 竖条中心x坐标。
4帧角色脚底严格落在相同的y坐标上（画布底部上移20px处）。

【背景颜色】
整个画布底色为全透明。
每帧严格限制在各自的256px竖条内，不跨越边界。

【禁止】
{negative.strip()}
角色变形、位置偏移、脚底不齐。
残影、白色像素、水印、编号、文字标记。
不同帧之间角色外观不一致。
行走动作、大幅度移动。"""
    return prompt.strip()

def main():
    shared = load_shared()
    batch = load_batch()

    out_dir = os.path.join(PROJECT, 'output')
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, 'npc_prompts_ch1.txt')

    lines = []
    lines.append("=" * 60)
    lines.append("第一章 NPC Sprite 生成 Prompts")
    lines.append("模板: sprite_npc_idle_4f_v1 (4帧 idle strip)")
    lines.append("处理: python scripts/process_sprite_strip.py --mode 4f --direction X --npc-id Y output.png")
    lines.append("=" * 60)
    lines.append("")

    for npc in batch['npcs']:
        npc_id = npc['npc_id']
        name = npc['character_name']
        height_note = npc.get('height_offset', 0)
        height_hint = ""
        if height_note < -5:
            height_hint = f" [体型: 比主角矮, 高度约135px]"
        elif height_note > 3:
            height_hint = f" [体型: 比主角高, 高度约155px]"
        elif height_note < -2:
            height_hint = f" [体型: 比主角略矮, 高度约140px]"

        lines.append(f"\n{'─' * 60}")
        lines.append(f"NPC: {name} ({npc_id}){height_hint}")
        lines.append(f"{'─' * 60}")

        for d in npc['directions']:
            lines.append(f"\n--- {name} - {d['label']} ({d['dir']}) ---")
            prompt_text = render_idle_prompt(npc, d, shared)
            lines.append(prompt_text)
            lines.append(f"\n[处理命令] python scripts/process_sprite_strip.py output.png --mode 4f --direction {d['dir']} --npc-id {npc_id}")

        if 'extra' in npc:
            lines.append(f"\n--- {name} - 打铁动作 ---")
            smith = batch.get('smith_special', {})
            if smith:
                style = shared['style_anchor']
                negative = shared['negative']
                lines.append(f"""{style.strip()}

{smith['prompt'].strip()}

【禁止】
{negative.strip()}
角色变形、位置偏移、脚底不齐。
残影、白色像素、水印、编号、文字标记。""")

    # 写入文件
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))

    print(f"Generated {out_path}")
    print(f"Total NPCs: {len(batch['npcs'])}")
    total_prompts = sum(len(npc['directions']) for npc in batch['npcs'])
    print(f"Total prompts: {total_prompts} (idle) + 1 (smith) = {total_prompts + 1}")

if __name__ == '__main__':
    main()
