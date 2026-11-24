# 新版大地图双区 v6：路边群落与低伏授权石块（仍未正式替换）

## change-id / 范围

`world-native-pair-groves-v6`。在 v5 同源地形上完善地表色调、山肩条带与路边物件构图，不修改正式 v12／v13 staging 的地图资源、入口或玩家存档。读取 v4/v5 渲染、物件合同与实际 Field 接口；仅修改 dev 渲染／合同、专项测试及美术登记。

## 本轮产出

- 3072×1024 中心—东岸正交地形 v6：压低过黄草地、降低高频表面强度，增加离路山肩的非规则起伏／裸岩条带。道路和海岸逻辑源保持原双区拓扑，画面／陆地／可走蒙版通过同一相机输出，再裁为两个 1536×1024 区块。
- Poly Haven CC0 Boulder 01 两张低伏派生图 `boulder_01_cc0_ortho_v4.png`、`...v4b.png`。同一相机／光源下，模型 Y 缩放 0.60、方位分别 35°／-55°，降低偏亮石色，不在2D里旋转贴图伪造不同视角。元数据分别记录变换、色乘、像素尺寸与重新计算的模型底面投影脚底。仍只有这一个外部模型的两个派生视角，不是取得了两种外部素材。
- 独立物件从 4 增到 13：5 块石、8 丛灌木，按路边群落手工布置；每条记录包含透明图、视觉中心、投影脚底、阻挡与 Y 排序、独立接触阴影。灌木来自已入库自生成资产，不属于 CC0。
- 中部新增石块首放 `(1530,865)` 一侧被南坡禁走层挡住；调整为 `(1540,645)` 后双侧绕行通过，没有删除失败断言。

## 实机与技术验证

- `test_world_map_native_pair_ortho_v6.gd` exit 0：同相机原像素裁切、可走属于陆地、海岸安全带、接缝道路、96 个路面脚底及净空、陡坡负例。
- `test_world_native_pair_field_props_v6.gd` exit 0：13 个实体、13 个接触阴影、13 个脚底阻挡；各物件两侧绕行、角色在前／后排序通过。沿主路 760 个连续位置探针通过（不是完整真实输入驾驶测试）。五张实机截图位于 `game/build/world_native_pair_field_props_v6_{behind,front,western_road,seam_road,eastern_road}.png`。
- Godot 严格导入 exit 0；旧 v5 同源地形专项也通过。通用测试仅新增可覆盖的物件数量、道路文件路径钩子，默认旧样板行为保持。
- 使用 `--audio-driver Dummy` 隔离本机 WASAPI 打开失败对画面测试的干扰；仍有既有 OpenGL 纹理 RID、ObjectDB／资源退出清理告警，不宣称“无错误日志”。

## 视觉状态 / 下一步

**视觉仍 FAIL，正式地图不切换。** 石块轮廓不再过高，物件群落比四物件小样丰富，但整块草地仍显重复、山肩仍单调；同一灌木轮廓与石块贴图重复，接地和整体氛围还没有达到本项目写实 2.5D 目标。物件13项齐备不代表全部场景层级修完；原 49 个待逐图核对候选未在这批批量处理。

下一步应完善地貌结构与真正有差异的植被/岩块资产，统一接触光影，再做独立城池／渡口／桥的路面接驳与入口站位；不能复制双区铺满九宫，也不能将此小样当作完整新世界。

## 复现

已有 v2 拓扑及 v5 工作素材作为前置；用本机 Godot 控制台执行：

```powershell
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --path game --audio-driver Dummy --rendering-driver opengl3 --script res://scripts/dev/render_polyhaven_boulder_v4.gd
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --path game --audio-driver Dummy --rendering-driver opengl3 --script res://scripts/dev/render_polyhaven_boulder_v4b.gd
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --path game --audio-driver Dummy --rendering-driver opengl3 --script res://scripts/dev/build_world_map_native_pair_ortho_v6.gd
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path game --editor --quit
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path game --script res://tests/test_world_map_native_pair_ortho_v6.gd
& 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --path game --audio-driver Dummy --rendering-driver opengl3 --script res://tests/test_world_native_pair_field_props_v6.gd
```
