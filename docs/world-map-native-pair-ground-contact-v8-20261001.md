# 中心—东岸地表与接地 v8 · 2026-10-01

状态：两区开发候选，技术合同通过，整体视觉仍 FAIL。正式 v12、v13 staging 不切换；不是九区世界、16入口或全部场景遮挡修复完成。

## 本轮实施

- 新增 `build_world_map_native_pair_ortho_v8.gd`，继承 v7 的道路、河道、海岸、桥面与入口布局。3072×1024 地形、天然陆地与导航仍由同一正交相机导出，再逐像素裁成两张1536×1024区块。
- 高度采用宽山肩、椭圆过渡及物件完整底面压平，消除矩形地基切山造成的竖崖。急弯附近地形压平改用附近折线的实际线段距离，不把导航的局部法线宽度近似外推到200px外制造竖岩针。
- 从已登记 Poly Haven CC0 草地 diffuse 提取细节，减去低频航拍旋纹；混合草土、干土和坡面碎石，河岸材质宽度加入变化。未新增下载或生图调用，也没有新增费用。
- 根据13个独立物件的脚底和城池／候船亭两处地基，生成15处地面接触土。实体仍独立摆放，不烘焙到地表；碰撞及Y深度沿用 v7。土斑本身不代表正确光影或视觉接地已验收。
- 新增 v8 开发合同、运行入口和测试；复用 v7 的隔离 Field 子类。v8最终渲染不再写旧v7桥栏图，独立前栏继续复用已存在的同画布alpha加工件。

## 失败记录与语义校准

首轮 headless 1034项／2失败，仅为沿用的旧陡坡点(530,180)、(2070,180)。本轮实际几何降低山肩，两个源点梯度分别0.597421、0.303637，均低于既有陡坡阈值0.72。没有为了旧断言补假阻挡。

最终测试保留这两处为天然陆地、完整脚底可走正例；另以 `art.json` 中12个实际梯度超过0.78的源点及其同相机投影坐标，验证天然陆地存在、导航禁走、真实Field判定拒走。水域、海岸、桥栏、道路与入口断言均保留。

两版道路各有148点、x步长16。v7主路未沿全线压平，投影折线长2666.436px；v8路中心压平后回到作者道路曲线，投影长2564.442px，最大垂直差80.738px在x2000。每段继续按 `ceil(length/4)` 包含两端检查完整脚底，因此连续主路探针由900变为876，不是删路或降低采样密度。天然陆地蒙版4px格点相对v7新增6、减少1；不能宣称新旧导航哈希相同。

## 验证

- 最终 headless **1063项0失败**，主控独立复跑同结果；GPU **1077项0失败**，均exit0。
- 876连续主路完整脚底、两入口支路、13独立物件完整碰撞底面天然陆地支撑、桥栏／海岸负例通过。
- 视觉／陆地／导航三组母图与左右区块全像素裁切相等；河道每4px纵向、五条横向共1280个见证均为天然水，仅明确的结构桥面可跨河。没有把道路涂白覆盖水域否决。
- 实际双向移动过桥、Space进城、鼠标点渡口、精确原入口返回通过。目标场景仅使用无剧情／NPC／任务奖励／随机战的运行副本。
- 五槽存档及备份SHA、剧情flag不变；开发预览拒绝存档菜单及平台checkpoint，退出恢复SceneRouter状态。
- 旧v7回归1055项0失败。主控核对v7渲染脚本／地理合同／visual-land-walk、正式v12／v13 staging场景和project.godot共8个文件，本轮前后SHA全部一致。
- 严格资源导入exit0。生成／GPU退出仍有已有Texture RID、RenderingServer、ObjectDB清理告警，不宣称日志无告警。Dummy音频没有听感验收；本轮不重做BGM或导出Web／微信包。

七张GPU截图均硬断言物理1920×1080：

- `game/build/world_native_pair_landmark_v8_city.png`
- `game/build/world_native_pair_landmark_v8_bridge.png`
- `game/build/world_native_pair_landmark_v8_bridge_front.png`
- `game/build/world_native_pair_landmark_v8_bridge_back.png`
- `game/build/world_native_pair_landmark_v8_ferry.png`
- `game/build/world_native_pair_landmark_v8_city_arrival.png`
- `game/build/world_native_pair_landmark_v8_ferry_arrival.png`

## 视觉门禁与下一步

主控、QA与独立审查仍不批准正式替换。相较v7，方块悬崖和大旋纹明显减弱；但地表低对比、偏软，城池孤立，植被重复，石块与锐利建筑像贴片，压土斑过于圆整，长河道仍像规整直带。本轮只解决了部分地形问题，不能写“写实风格达标”或“接地根治”。

独立审查查看全部七张实机图：两处arrival均在公开铺地，未见屋顶／桌面出生；渡口角色在陆侧、船主要在水中，但栈桥大部分仍像铺在陆地，尚无真实水岸栈桥的视觉批准。审查未发现新增可复现代码缺陷；这不代替视觉放行。

桥前／后截图继续使用完整脚底可达站位，不与前栏alpha重叠，不能当作局部遮腿视觉证明。物件合同通过也不等于全库49个遮挡候选已修。

下一轮应做有明确地貌分区的人工构图、河岸与建筑基础衔接、物件接触光影和群落差异；不再仅叠噪声或重复草图扩九区。地理若改变，必须同步导航、完整脚底与物件支撑合同，再整图实机审查。

## 复现

在工程根目录使用既有Godot 4.6.2 console：

```text
--path game --audio-driver Dummy --rendering-driver opengl3 --script res://scripts/dev/build_world_map_native_pair_ortho_v8.gd
--headless --path game --editor --import --quit
--headless --path game --audio-driver Dummy --script res://tests/test_world_native_pair_landmark_v8.gd
--path game --audio-driver Dummy --rendering-driver opengl3 --script res://tests/test_world_native_pair_landmark_v8.gd
--path game --audio-driver Dummy --rendering-driver opengl3 --script res://scripts/dev/run_world_native_pair_landmark_v8.gd
```

来源仍按 `docs/licensed-world-assets-polyhaven-20260929.md` 逐项登记。城池、渡口、桥和自生成岩土材质不因与CC0草地混合而自动变为CC0。
