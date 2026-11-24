# 中心—东岸独立地标路线 v7 · 2026-10-01

状态：开发可玩样段；正式 v12 与 v13 staging 不切换。只制作共享 3072×1024 的两区路线，不代表九区世界或全部16个入口完成。

## 本批内容

- 共用 `world_native_pair_landmark_contract_v7.gd` 定义河道、主路、城门支路、渡口支路、桥面、地标摆放及脚底阻挡；渲染脚本、开发 Field 和测试读取同一份几何。地形原帧裁成中心／东岸两个1536×1024区域，视觉、天然陆地和导航分别同相机导出。
- 现有自生成透明洛阳城、石桥、白鹿渡候选独立摆放，不再让城市/船体烘焙进可走底座。CC0 Poly Haven 草地、道路与巨石仍沿用已核验来源；自生成建筑和其技术派生蒙版**不属于 CC0**。
- 石桥拆为脚下桥面和像素对齐前栏：前栏保持1784×896原画布，仅提取原图下方实体alpha，再以同一位置/尺寸叠回。前后栏各有独立阻挡，不能把整个桥图作为前景覆盖角色。
- 河面半宽64px，额外20px脚底安全边界；只允许明确的 `Rect2(1418,348,484,35)` 桥面提供结构支撑。天然陆地蒙版仍把桥下河水判为水，不将桥面冒充天然陆地。
- 城池脚底(900,360)、城外入口(900,390)；渡口视觉脚底(2420,725)、安全入口(2395,735)。城市整体、候船亭和船体禁走，岸边入口保留完整脚底。

## 运行隔离

`run_world_native_pair_landmark_v7.gd` 在真实 Field 控制器上构建临时 SceneScript，可移动、空格或近距点击入口。洛阳南门／白鹿渡接驳只载入既有目标的运行副本并清除NPC、对话、任务触发、随机战与物件交互；返回精确源入口。

预览不注册正式 SceneRouter 当前场景，不允许存档菜单或GM面板；关闭/退出恢复原导航状态。没有修改正式 `.tres`、主线、奖励、存档迁移，也未重新导出 Web／微信包。

## 本轮失败与修复

首轮965项有50失败：主路穿过候船亭，渡口入口中心在陆地但完整脚底越过海岸缓冲。保留失败断言，将道路绕到亭前、入口收回陆侧。

第二轮1034项仍有16失败：急弯使用纵向道路宽度且导航沿用旧v2路带，导致13个完整脚底负例；另有真实空格入口链的3个断言失败。道路宽度按曲线导数换算横断面，导航从同源道路核心补白，仅允许天然陆地且仍由海岸／河道否决；不是用道路图把水面重新涂白。

后续真实输入测试暴露异步输入/物理帧等待及headless窗口尺寸问题，修正测试时序和开发窗口后实际Space／鼠标接驳通过；未用直接函数调用代替用户输入。新急弯还与继承灌木底座冲突，仅v7把该灌木视觉、底面、排序线成对移到(2280,810)，不改v6源布局。

主控与独立审查读取GPU实机图后又发现 `grove_middle_b` 根部(1740,800)确实在新河中：距river_x(800)约52.4px，小于64px河半宽。已仅v7把视觉、底面和排序线成对移到干岸(1860,810)，并给全部13个继承物件新增完整碰撞矩形底面的天然陆地支撑检查（每4px并包含边界，无桥面豁免）。旧地理合同通过不代表改变河道后仍正确。

最终 headless 1055项0失败（主控独立复跑同结果），GPU 1062项0失败，均exit0；900个连续主路完整脚底探针、两条入口支路、桥栏/水/陡坡负例、13物件底面陆地支撑、实际双向移动、Space／鼠标入口、源锚点返回通过。五个槽位及备份SHA、剧情flag前后不变，开发存档/平台checkpoint拒绝与导航状态恢复通过。旧v6同源地形专项仍exit0，最终严格导入exit0。

七张1920×1080实机截图：

- `game/build/world_native_pair_landmark_v7_city.png`
- `game/build/world_native_pair_landmark_v7_bridge.png`
- `game/build/world_native_pair_landmark_v7_bridge_front.png`
- `game/build/world_native_pair_landmark_v7_bridge_back.png`
- `game/build/world_native_pair_landmark_v7_ferry.png`
- `game/build/world_native_pair_landmark_v7_city_arrival.png`
- `game/build/world_native_pair_landmark_v7_ferry_arrival.png`

桥前/桥后图使用完整脚底可达的y376／355；桥面仅y348..383，不能为了截图扩大可走带。两图并不与前栏alpha重叠，不能当作局部遮腿的视觉证明。主控目检并与独立代码/画面审查一致：地理错误已修，整体视觉仍FAIL，不晋级。

## 素材派生

`render_polyhaven_shrub_v7.gd` 从已核验 Shrub 03 的四株并排glTF中隔离 `shrub_03_a`，按相同正交方向渲染单株229×338透明候选，脚底UV约(0.484716,0.944495)。这是小型地被，不当作乔木；本路线尚未摆入，未获正式视觉采用。

## 仍待完成

草地地毯感、山肩、河岸与城市/桥/渡口接地仍需整图美术返工，不能因技术测试通过就晋级正式运行。后续先改善本两区视觉和地标比例/接驳，再扩全图；全场景49个遮挡候选仍待逐图处理。

## 复现

在工程根目录使用现有 Godot 4.6.2 console，以下参数分别用于生成、导入、验收和独立试玩：

```text
--path game --audio-driver Dummy --rendering-driver opengl3 --script res://scripts/dev/build_world_map_native_pair_ortho_v7.gd
--headless --path game --editor --import --quit
--path game --audio-driver Dummy --rendering-driver opengl3 --script res://tests/test_world_native_pair_landmark_v7.gd
--path game --audio-driver Dummy --rendering-driver opengl3 --script res://scripts/dev/run_world_native_pair_landmark_v7.gd
```

生成及导入 exit0。OpenGL生成退出仍有既有 Texture RID／RenderingServer 清理告警，不能宣称无告警；使用Dummy音频仅为规避本机设备不可用，本批不进行背景音乐听感验收。
