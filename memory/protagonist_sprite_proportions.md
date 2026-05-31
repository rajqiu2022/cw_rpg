---
name: protagonist-sprite-proportions
description: 主角 sprite 帧尺寸和比例规范，用于 NPC sprite 生成参考
metadata:
  type: reference
---

# 主角 Sprite 帧比例规范

## 当前帧尺寸（已缩小到 2/3）

| 方向 | idle 平均 | walk 平均 |
|------|----------|----------|
| down | 65x152 | 64x152 |
| left | 63x138 | 63x138 |
| right | 63x140 | 68x138 |
| up | 64x142 | 65x142 |

## 组装后 strip 尺寸
- idle strip: 4帧，约 270x150（单帧约 67x150）
- walk strip: 9帧，约 650x150（单帧约 72x150）

## 关键比例
- 宽高比约 1:2.2（瘦高角色）
- 帧高度因方向不同在 138-152 之间
- 归一化后统一画布约 74x143（walk right）、68x144（idle right）

## NPC 生成规范
- 使用相同的帧切分方式（4方向 idle，每方向 4 帧）
- 整体先缩小到 2/3 再组装 strip
- 主角基准高度 ~145px（归一化后），NPC 可 ±15% 浮动
- 铁匠等壮汉可以略宽（宽高比到 1:1.8），书生可以更瘦（1:2.5）
- 使用 `scripts/assemble_hero_strips.py` 同样的组装逻辑
