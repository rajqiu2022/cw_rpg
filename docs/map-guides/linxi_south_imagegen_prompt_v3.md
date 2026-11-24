# 林西村南坊 V3 场景生成说明

## 输入图职责

- `linxi_south_walkability_layout_v3_full.png`：结构硬参考。道路拓扑、广场、建筑岛、门前落脚区和出口必须遵循此图。
- `bg_linxi_village_scrollmap_2x2_25d_v2_optimized.png`：仅参考手绘武侠 2.5D 画风、材质和色彩，不继承其密集布局。

## 最终 Prompt

Use case: stylized-concept

Asset type: production-ready 2.5D game environment background for a scrollable Chinese wuxia RPG village map

Primary request: Create a new Linxi Village South District environment background. Follow Image 1's road topology, plaza positions, building-island positions, and open space proportions as strictly as possible. Reinterpret the simple blueprint as a richly painted ancient Chinese rural village.

Scene/backdrop: bamboo-covered mountain village with eight separated building clusters, vegetable and herb gardens, low fences, rocks and vegetation only inside the green non-walkable islands. Buildings are modest Song/Ming-inspired timber and tiled or thatched rural structures, with one slightly larger apothecary building.

Style/medium: match Image 2's hand-painted 2.5D wuxia RPG environment, crisp painterly realism, coherent three-quarter isometric camera, warm earthy stone roads, dark timber, mossy greens.

Composition/framing: very wide landscape around 2.1:1. Preserve Image 1 exactly at macro level: one broad uninterrupted east-west main road, three large open conversation plazas, broad north and south branches, top and side exits, and generous clear walking widths. Every building footprint must remain fully outside roads and plazas. Every doorway must face a road and have visible steps or a short stone approach pad.

Constraints: no characters, NPCs, animals, arrows, diamonds, colored markers, labels, UI, text, or watermark. No house, roof, rock, fence, garden, tree trunk, stall, well, basket or prop may intrude into any road or plaza. Roads must be visually continuous with no grass seams, bottlenecks, dead ends, or ambiguous walkable patches. Keep all roofs and courtyards visually distinct from the ground. Full-scene sharpness suitable for gameplay.

Avoid: photographic depth of field, fog blur, Unreal-engine look, cinematic blur, cluttered building placement, roads hidden behind roofs, isolated walkable-looking rooftops, disconnected stone patches, duplicate buildings, modern objects.

## 输出

- Built-in 原图：1817×866 RGB。
- 运行时版本：LANCZOS 统一缩放至 3388×1614 RGB，保持与现有南坊地图和相机配置兼容。
