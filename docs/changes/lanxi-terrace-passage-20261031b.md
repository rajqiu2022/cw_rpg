# 2026-10-31b 岚溪寨梯田与田埂通路

状态：已合入正式岚溪寨。四块梯田内收至同一台地，截图这块田内横向通路可连续往左走并原路返回；原石岸、高差、四处台阶及31a木桥阻挡保留。唯一局部实机已完成，停止追加验证，布局细节交用户验收。

## 原因与改动

原Paddy1—4图片跨过L1东侧台地边界，Paddy4被NativeBank68—72前景石岸压住。石岸Sprite本身无碰撞；真正挡路的是原Cliff实体。不能只把石头移走而留着隐藏墙，也不能删除整个高差来假装通路贯通。

本轮移动原完整稻田组件，等比调整原图、脚锚、visual_rect与底部田埂实体，均保持L1/高120：

|节点|新物理落脚|完整原图等比scale|
|---|---|---|
|Paddy1|6600,1380|0.45|
|Paddy2|6750,1820|0.45|
|Paddy3|6750,2220|0.45|
|Paddy4|6500,2820|0.55|

四图各564110个alpha≥8源像素的局部静核均落同一L1、与166段NativeBank采样支持0重叠；新田体不压邻房树。P4田内通路为物理(6890,2700)→(6100,2700)，画面脚点Y2580；同层接西侧村巷，不是从L0穿崖上L1。原田图三小级是同一组件画面，不冒新增三层物理地形。静证见 [proposal_STATIC_01.json](../../game/build/lanxi_paddy_passage_20261031b_system01/proposal_STATIC_01.json)，SHA `A83F00B52F6E515863EF1DC055D716BEF793F8CDF9605656348EEC9DC2015D9B`。

新控制器继承31a，旧合法且仅被搬后田体覆盖的脚点，核对旧四田实体与其余真实障碍后，才迁至对应预设田埂净空点；同层、无nearest、不读写真实存档。其余脚不泛迁。局部正例旧(6300,2790)→(6500,2880)。

## 合入与边界

Root通过apply_patch定点合入3个旧文件，当前SHA：

- Scene `game/scenes/drafts/miao_terrain_20261029i/miao_town.tscn`：`80D0A6207197012B800A0894A3BF8E60DE38C223C98FC7A029E7F0747B6C6206`。
- native manifest：`C38BFC9C52D5F12419AADEFFBBF18A574C9B7109FC7C86F3B8A2DDF78340D654`，原201键除Scene后继外保持，新增helper至202。
- registry：`9DA1CF4F403E9F5BE9848DA6FEAC8F89BFAD78D618A94E85EDB5F328B545BF79`，仅manifest头更新，16入口ID不改。
- 新 `game/build/lanxi_paddy_passage_20261031b_system01/paddy_controller.gd`：`B1D0667EADAF38BFA0ED4C07C0E98DBC158F7E125A1E5CCF86BEFF6CD79003DC`。

[候选/整逆收据](../../game/build/lanxi_paddy_passage_20261031b_system01/replacement_receipt_READY.json) SHA `EC969D124BDEAB29019E4400092784DCB9E7035D5D6ADA18335D84F7556B1594`；3文件正逆实际内存应用逐字验证在4FA77268静证。所有非Paddy节点保持，含原三级地形、Cliff、四阶、三桥、31a两木街碰撞、NPC与房屋。0PNG写、0生图、0World五桥/武当华山/Router/Player/project/任务改动。

## 唯一实机

冻结脚本66914E73，Root launcher137908/engine84652，20960ms自然退出0，37检查0失败、6输入。实际结果 [result.json](../../game/build/lanxi_terrace_banks_20261031b_qa01/actual/84652/result.json) SHA `81D6305A9394EC0FC38CCA65E870920CAA2980B6CA87D64604D347199D3A7D43`。

- 新源/Scene/helper可加载；实际四田落脚、scale、脚锚及Body与候选核对。
- 公开近场设置后，同一native实例真A从6890,2700走至6103.5,2700，再真D回6890,2700，中间无重设/瞬移，全帧L1/高120/Y2700/ramp−1。
- 邻原Cliff7真实接触，斜壁允许沿边滑但整34×24脚未越坎，未删除高差碰撞。
- 旧合法新田体覆盖脚精迁到预设点。
- 一张 [paddy4_normal.png](../../game/build/lanxi_terrace_banks_20261031b_qa01/actual/84652/paddy4_normal.png) SHA `EAA37CB5B3D4016C73A42ACB5699E5E4FD7156DEF042FDF1DEA4B260F9BEA56D` Root亲看，稻田与石岸分离。前景树仍为原布局，不冒全城ART。

公开近场不是从World全程徒步到田，未重复旧桥/四阶/门派矩阵。既有7条纹理/RID/RenderingServer退出ERROR及ObjectDB警告保留，不能称stderr clean。

## 保护

fresh基线0FD676CE核986源/171存档/9合法absent，0历史差；末 [final_guard_ACTUAL.json](../../game/build/lanxi_terrace_banks_20261031b_qa01/final_guard_ACTUAL.json) SHA `38429886E3A20ED4582484D0D212D8CED65C636803C4DA0A7E32C4486EE87EA9`：恰3授权源变化、其余0外差，171存档SHA/bytes/UTCticks精同、9absent保持，202依赖精核。仅编辑器51856保留；未操作用户进程、未读存档内容、未写或恢复真实存档。
