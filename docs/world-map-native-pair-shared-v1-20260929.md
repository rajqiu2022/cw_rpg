# 大地图中心—东岸同源双区试样（2026-09-29）

## 结论

**技术接缝通过，画面不通过；不得接入正式地图或扩为九宫。** 上一轮把两张独立底图拼接造成道路错位和草地风格断层。本轮改为一张 3072×1024 的地形拓扑，生成画面与通行蒙版之后，才在 x=1536 处裁成中心、东岸两块。裁切不重绘，两侧画面来自同一帧。

实现：`game/scripts/dev/build_world_map_native_pair_shared_v1.gd`；专项：`game/tests/test_world_map_native_pair_shared_v1.gd`。输出在本地 `game/build/world_native_pair_shared_v1_*.png`，不被任何正式场景引用，也不替换 v12 或 v13 staging。

## 同源合同与验证

- 海岸线、道路中心线在完整 3072×1024 坐标系计算一次，生成 RGBA 地形拓扑。红通道标陆地，绿通道记录道路覆盖，alpha 存海岸有符号距离。
- 渲染器从该拓扑合成草地、道路、崖岸和水；导航蒙版从相同拓扑的海岸距离生成。离岸线不足 82px 的崖岸缓冲区禁走，水面禁走。
- 两张 1536×1024 区块直接裁自完整渲染。专项按间隔采样对比原图与区块，验证像素一致；检查跨区道路覆盖，陆侧两处可走，崖岸和海面禁走。专项 exit 0，0 失败。
- Godot 4.6.2 OpenGL 渲染脚本 exit 0；退出阶段仍出现资源 RID 清理告警，未把它当成渲染质量通过的证据。headless 使用 dummy renderer，不能抓图。

## 人工画面检查：FAIL

虽然已无两张图相互拼接的硬缝，完整图仍是偏顶视的重复草地材质，缺远近一致的 2.5D 地形体积、道路边坡、植被组合及地点辨识度；海水色彩也明显脱离目前认可的写实场景。上一轮授权巨石物件与自生成底座的接地感问题亦未由本试样解决。这是**导航/渲染共源技术基线**，不是可运行的大地图资源。

下一步应在这张共享拓扑上制作手工布置的可识别地貌和道路边界，并在同一正交镜头、固定角色尺度下混合经过授权核验的岩石/植被与自生成材质；先审中心—东岸实际视口和接缝，再扩成九区。后续还要验证全部入口位置、桥面及旧档迁移，才可考虑替换正式 v12。

## 复现

从仓库根目录运行：

```powershell
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --rendering-driver opengl3 --path game --script res://scripts/dev/build_world_map_native_pair_shared_v1.gd
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path game --script res://tests/test_world_map_native_pair_shared_v1.gd
```
