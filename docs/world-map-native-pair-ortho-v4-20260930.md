# 新版大地图：中心—东岸正交地形 v4（隔离候选）

## 本轮完成

- 在原 3072×1024 双区共享拓扑之上增加固定正交相机和连续起伏地形，整张画面一次渲染后裁出中心／东岸两区。首轮实时自阴影出现规则斜纹，确认由大尺度地形阴影贴图引起；关闭地形自阴影后斜纹消失。独立物件继续由 Field 的脚底接触阴影负责，不把阴影烘进地表。
- 同一地形网格、同一相机分别输出画面、投影后的陆地轮廓、可行走蒙版；三者均从整帧原像素裁出中心／东岸区域图。海岸 5 个采样行的陆地／可走边界相隔约 83px；每 4px 网格检查未发现可走像素越过投影后陆地。各区画面／导航／陆地裁切与母图像素相同，跨区行走点保持连通。
- Poly Haven CC0 Boulder 01 增加无内置地影的 `boulder_01_cc0_southwest_v2.png` 派生图。v1 保留作历史候选；v2 仅用于双区试验的独立物件合同，阴影由 Field 运行时在脚底生成。四物件的脚底阻挡、侧边绕行和角色前后遮挡均在真实 Field 控制器通过。
- 新增 `game/tests/test_world_map_native_pair_ortho_v4.gd` 与 `game/tests/test_world_native_pair_field_props_v4.gd`。正交渲染、严格资源导入、两项专项均 exit 0；OpenGL 退出仍有已有的纹理 RID 清理告警，不计为画面验收。

## 视觉审查与边界

试验图在 `game/build/world_native_pair_ortho_v4_visual.png`，真实 Field 截图在 `game/build/world_native_pair_field_props_v4_behind.png`、`..._front.png`。新版本不再有规律条纹，地表坡向较 v2/v3 更清楚；但草地仍大面积重复、地形高差弱、道路和水面缺少足够的地貌/岸坡过渡，石块与灌木仍略显贴图拼合。**视觉门禁未通过；正式 v12 与 v13 staging 均未替换。** 目前只做了中心—东岸两区，并未补齐九区、城市与桥梁，因此不能视为新版大地图完成。

下一步先在同一正交几何上完善岸坡、道路材质过渡和稀疏物件布局，再校验入口与跨区道路；每个场景仍须保留底图／导航／独立物件三层合同。不得用当前两区重复铺成九宫。

## 复现

```powershell
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --rendering-driver opengl3 --path game --script res://scripts/dev/build_world_map_native_pair_ortho_v4.gd
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path game --editor --quit
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path game --script res://tests/test_world_map_native_pair_ortho_v4.gd
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --rendering-driver opengl3 --path game --script res://tests/test_world_native_pair_field_props_v4.gd
```
