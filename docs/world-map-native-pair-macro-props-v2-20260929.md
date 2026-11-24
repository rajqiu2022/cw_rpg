# 中心—东岸同源双区 v2：地表大形态与独立物件预览

**结论：导航合同通过，视觉仍 FAIL；正式 v12、v13 staging 均未切换。** 本轮只改上轮 3072×1024 同源双区试样的地表色彩层，并做授权石块＋自生成灌木的隔离物件预览。它不是已经进入游戏的场景，也没有任何门户、桥或完整九宫验收。

## 本轮内容

- `game/scripts/dev/build_world_map_native_pair_shared_v2.gd` 继承 v1 的海岸、道路与通行拓扑，在草地材质上叠加一张低频地表大形态候选，并把过亮海水色值收暗。道路、岸线和导航仍由同一拓扑决定；图像仅影响地表视觉，不能凭生图移动水陆边界。
- `game/art/modules/world_map_v13/terrain_macro_ground_v2_candidate.png`：内置生图生成，SHA-256 `C2F045162603ADBCF7AA796407B60013312C597C9AA87E4A293F6D55777F5534`。内容仅是草地/土壤颜色与低频起伏，未含道路、海岸、树木和建筑。
- `game/art/modules/world_map_v13/shrub_cluster_generated_v1_candidate.png`：内置生图生成的透明灌木，SHA-256 `464568BEF5E835EA7969B6C8433386DC6C3DE445E06F3AFE49940967A107964F`。与此前核验过 Poly Haven CC0 的 Boulder 01 透明石块，仅在 `game/scripts/dev/render_world_native_pair_prop_preview_v2.gd` 中试摆。试渲 Poly Haven Shrub 03 只有稀疏枝条和过重黑影，已否决并移除本轮派生文件；并非该授权资产不允许使用。
- 预览中的四件物件按脚底 Y 排序；其独立脚底矩形在五个采样位置检查没有占住道路、海水和崖岸，三个角色展示脚底不在占地内。**此为隔离预览合同，不等于正式 Field 的物理碰撞实机通过。** 首轮预览曾把角色摆到石块轮廓上，看起来像站在石头上；复核后将石块与展示脚底移开，并加上述占地验证。

## 验证与视觉审查

- Godot OpenGL 双区 v2 渲染 exit 0，中心/东岸区块与母图像素一致；v2 与 v1 的拓扑、通行蒙版 SHA-256 完全一致。道路跨区连续、陆侧可走、水面和岸边缓冲禁走专项 exit 0。
- 四物件、三角色脚底的隔离预览验证通过，输出 `game/build/world_native_pair_prop_preview_v2.png`；完整画面为 `game/build/world_native_pair_shared_v2_visual.png`。这些 build 输出是本地可重建产物，不被正式场景引用。
- 人工审查：草地比 v1 少一些方块重复，但画面仍像平面地表；授权巨石与地面的光照/材质仍有拼贴感，地貌体积、地标、真实 2.5D 正交镜头不足。**视觉 FAIL，不得把本图写进正式地图或批量复制到九宫。** Godot 退出仍有既有资源 RID 清理告警，exit 0 不代表视觉通过。

后续优先事项是固定正交镜头下的原生地形起伏、道路边坡及授权物件接地光照；再把独立物件的脚底阻挡与 Y 深度合同真正接到隔离 Field 场景，并实测角色前后、侧边绕行与门户返回。单张地表生图不能取代这些结构。

## 生成说明

两张新图均使用 Codex 内置 ImageGen，并复制到上述项目路径。最终提示词为：

```text
Use case: stylized-concept
Asset type: candidate low-frequency ground albedo for a Chinese wuxia 2.5D game world-map terrain, to be blended beneath sharp procedural grass detail
Primary request: a broad natural temperate central-China grassland ground surface with irregular olive, straw, dark earth and muted green patches, subtle rolling landform shading and believable soil variation across one continuous wide area
Style/medium: restrained realistic hand-painted terrain material, close to photorealistic game environment, not cartoon, not oil painting, not satellite photography
Composition/framing: wide continuous orthographic ground-only surface seen at one fixed scale; no horizon or distance perspective; no focal point; variation spread across the full canvas
Lighting/mood: soft daylight from upper left, coherent across the canvas; gentle relief only
Constraints: ground coloration and subtle texture only; no roads, tracks, paths, rivers, sea, cliff edge, buildings, towns, props, isolated boulders, trees, bushes, characters, text, labels, symbols, border, frame, watermark. This is not a complete scene and must not invent navigation features.
```

```text
Use case: stylized-concept
Asset type: separate transparent foreground prop for a fixed-scale 2.5D Chinese wuxia game world map
Primary request: one compact natural low shrub cluster, several dense irregular olive-green bushes growing together, believable leaves and twigs, broad enough to form a useful low roadside obstruction
Style/medium: realistic game environment asset, subtly hand-finished photoreal textures, not cartoon, not oil painting
Composition/framing: isolated single prop, view from a fixed orthographic three-quarter angle looking gently down from the southwest; entire bush including lowest contact leaves visible; centered with clear padding
Lighting/mood: soft neutral daylight from upper left, controlled shadows within foliage
Background: genuinely transparent alpha background, not white or checkerboard
Constraints: no ground plane, no terrain patch, no cast shadow outside the prop, no rocks, no trees, no buildings, no characters, no text, no border, no watermark; clean alpha edge without colored halo. Intended to be placed independently over a game terrain layer.
```

复现命令（从仓库根目录）：

```powershell
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --rendering-driver opengl3 --path game --script res://scripts/dev/build_world_map_native_pair_shared_v1.gd
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --rendering-driver opengl3 --path game --script res://scripts/dev/build_world_map_native_pair_shared_v2.gd
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path game --script res://tests/test_world_map_native_pair_shared_v2.gd
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --rendering-driver opengl3 --path game --script res://scripts/dev/render_world_native_pair_prop_preview_v2.gd
```
