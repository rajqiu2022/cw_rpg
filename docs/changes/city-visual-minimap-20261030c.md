# 城内实景缩略地图

状态：已正式合入，宅园实景缩略图已亲看；其它城镇适配沿用原接口，本轮未逐城实机。

用户拒绝30b的小地图色块示意，要求能看出地形和建筑缩略图。本轮替换底图表现为现有场景真实纹理：屋顶、地面、树、池塘等，不再以碰撞轮廓或道路色块代替。

既有玩家方向、门户坐标、鼠标穿透和GM避让保持。真实静态画面按场景比例生成一次缓存，正常移动只刷新标记；不复制NPC/HUD/脚本/碰撞，不重建游戏场景，不修改花园路面或任何任务/出入口/存档。Region缩略必须包含compiled完整render，不能只截当前已加载的视觉chunk。

沿用项目角色协作：System准备候选/必要已存在来源pin后继，QA最短单图检查，Root唯一正式部署和引擎运行。不新增生成图片、素材处理或全城旅行测试。

## 实现

- 旧30b标记/布局脚本以原841B8DC8字节精确冻结为 `legacy_marker_layout_snapshot.gd`；现役小地图仅替换底图生成。抽象road/building色块清空，真实纹理在原位置/比例绘制，门户和玩家标记保持。
- `visual_cache.gd` 建独立World2D和最长1024px、严格随场景长宽比的SubViewport。只创建无脚本Sprite2D/Polygon2D，复制真实纹理、UV、transform与材质；不复制人物、碰撞、Camera、HUD或Exit。StaticBody仅遍历其纯visual子树，不复制Body。
- Region所有compiled.render均按原脚锚/比例/centered/纹理尺寸重建，不依赖当前chunk；地面与新园路取常驻真实Polygon。native Node2D居民按已知角色/容器排除，而非只猜文件名。
- 首次UPDATE_ONCE后保持UPDATE_DISABLED，移动时只旧Marker刷新。缓存ready前不展示旧抽象底图。无新PNG/生图/素材处理/全工程导入；三Field、CT、花园、十个bin、NAV、门户和任务业务不动。
- 正式Router `DFBD8DCD` / Region manifest `09E6E032` / canonical CityMinimap `C125B513` / visual cache `E700D251`。现存小地图SHA pins仅做必要纯头传播；2个新模块只绑定Region.runtime_modules，没有再向旧metadata扩无关key。Router旧完整逆边保留，当前23边。

## 实际检查

1. 必要两新模块编译自然退出0，ObjectDB退出warning保留，不称空stderr。
2. **15988**自然退出0，346检查0失败，D4真实32px移动，一张正常宅园图。完整compiled rows、远处祖祠/厨房、纹理尺寸与脚锚、独立纯绘制树、单次渲染且移动后缓存RID/requests不变均通过；Root亲看灰屋顶、池树与完整院落可辨。但stderr新增 `viewport_set_canvas_transform` 初始化错误，故不以数值通过冒充整次clean。
3. 仅将canvas_transform赋值移至viewport和绘制根入树之后，**125868**自然退出0，94检查0失败、0INPUT、一张同位置残余图；新canvas_map/viewport_set_canvas_transform错误不再出现。原346成功继承，不重跑纹理/移动或全城矩阵。旧七条退出Texture/RenderingServer ERROR与ObjectDB warning保留。
4. 末 `visual03_final_guard_ROOT_ACTUAL.json` SHA `DC93EABA`：80个本地源、35份完整备份、171份最新存档SHA/bytes/UTC ticks一致，四并发外源从开始record-only；用户编辑器51856保留，自有进程自然退出。补丁均apply_patch，混合CRLF仅在忽略CR全文相等断言后机械恢复，最终目标SHA与冻结候选一致。

![实景小地图收尾画面](../../game/build/luoyang_city_visual_minimap_20261030c_qa01/actual/125868/real_minimap_init_order_residual.png)

本轮只交付实景缩略表现，不宣称逐城/逐室美术与性能全部验收。停止本批成功组件复测；重新运行游戏生效，编辑器不用关。
