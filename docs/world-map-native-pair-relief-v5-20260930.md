# 新版大地图：中心—东岸地貌与授权材质 v5（隔离候选）

## 本轮完成

- 修正 v4 地形偏平的原因：拓扑 alpha 中的海岸距离只能表示 ±128px，不能用于 245px 以上的内陆高度过渡。v5 改为实际海岸距离和独立地貌高度函数，加入西侧山肩、中部低丘与东岸坡面；仍使用固定 45° 正交镜头、同一地形网格生成画面／陆地／导航。
- 已核验 CC0 的 Poly Haven Aerial Grass Rock、Rock Path 工作副本纳入 `game/art/external/polyhaven/terrain/`，与自生成的大形态、碎岩、水面材质混合。道路增加不规则草肩过渡和轻车辙；岸边有裸岩坡面。授权范围及哈希仍见 `docs/licensed-world-assets-polyhaven-20260929.md`，不把生成材质归为 CC0。
- 地形陡坡同步进入脚底禁走蒙版，主道路保留通行。画面、陆地、导航从同一母帧原像素裁成两个 1536×1024 区块；没有用重复小样铺满九宫。
- Boulder 01 新增与地形同镜头的透明 v3 派生图，使用模型底面中心的投影作为脚底，而非 PNG 画布下边；元数据 `foot_uv=(0.5,0.642471)`。独立物件的画面、接触阴影、脚底碰撞和 Y 排序仍共用一份合同。东岸灌木移至 `(2260,650)`，避开新增陡坡，恢复双侧绕行。

## 验证结果

- `test_world_map_native_pair_ortho_v5.gd`：同相机区块裁切、跨缝路面、海岸缓冲、可走像素属于陆地、96 个投影路面点及其 10px 净空、陡坡负例，通过（exit 0）。高度回归验证防止海岸距离饱和再次压平内陆。
- `test_world_native_pair_field_props_v5.gd`：真实 Field 控制器中四物件的脚底阻挡、双侧绕行、角色前后遮挡通过；沿投影主道路加密至 760 个连续脚底检查点，陡坡／海面负例也通过（exit 0）。这是位置通行检查，**不是自动驾驶真人完整路线测试**。
- 保存五张 1920×1080 实机截图：物件前／后、西侧道路、跨缝道路、东岸道路，路径前缀 `game/build/world_native_pair_field_props_v5_`。
- 严格 Godot 资源导入 exit 0。OpenGL 退出仍有已有三张纹理 RID 清理告警，headless 专项仍有 ObjectDB 退出告警；不将 exit 0 宣称为无告警或视觉通过。

## 视觉结论及下一步

**视觉仍未通过，正式 v12 和 v13 staging 均未替换。** 新图能区分裸岩坡面与路面，道路边缘比 v4 柔和，但草地重复、山肩形状单调、场景偏空旷，石块仍有拼贴/接地不自然。当前只有中心—东岸两区，没有完整城市、桥梁、其余地区及 16 个正式入口。

下一步先做有明确构图的地貌与植被群落，减少草地纹理地毯感，统一授权物件与地面的色调/接触光影；再布置独立城池、渡口与桥，并逐个登记碰撞、排序线和入口站位。两区整图视觉通过后才扩其他区，不因技术专项全绿提前合入正式图。此前全场景的 49 个待核对层级候选也未在本轮批量修复。

## 复现

先生成共享双区 v2 拓扑（前置流程见 v4 文档），然后执行：

```powershell
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --path game --rendering-driver opengl3 --script res://scripts/dev/render_polyhaven_boulder_v3.gd
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --path game --rendering-driver opengl3 --script res://scripts/dev/build_world_map_native_pair_ortho_v5.gd
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path game --editor --quit
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path game --script res://tests/test_world_map_native_pair_ortho_v5.gd
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --path game --rendering-driver opengl3 --script res://tests/test_world_native_pair_field_props_v5.gd
```

候选底图／导航／截图保存在本地 `game/build/`，不是正式场景资源；独立测试在运行时搭建 SceneScript，不修改正式 scene/layout。
