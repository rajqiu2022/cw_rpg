# 大地图水面与木桥材质改造（2026-10-24d）

状态：首轮艺术拒绝；唯一集中后继已出局部GPU样例，正式世界资源未改。承接用户截图反馈，不能把24c府衙局部通过当作本任务通过。

## 本轮目标

保持北河木桥的类型、走向与可通行桥面，使木材、水纹及岸线过渡匹配现有人物和环境材质。先做一个局部原相机样例，不重做整张大地图，不扩大到任务/门户/存档。

1. System只读定位与最小材质消费者方案。
2. Art先审库存，再生成限定的旧木纹和细河水纹两张材质PNG；保原图，不做未授权本地去背景。
3. Root审新材质、同相机局部样例后决定接线；验证视觉与原物理分离。

## 已定位的原因

- 高可信对应`bridge_01`，不是横向`bridge_00`；北河/northern_pass_road，原deck225×418，轴斜率约.21718。只依据源与截图对应，未读取玩家当时位置。
- 正式绘制为v9c烘焙PNG；桥是原生Mesh木板/Box柱栏杆经离线相机导出，水和河岸烘在`r1_c2_visual.png`。不是Field临时fallback，也没有证据指向有损压缩。
- 原木板细条与sin木纹过于规则，水材质主要是两色深度混合/静态波法线；贴图即已呈现扁平板和模糊河带。
- 库中v13石拱桥与现桥透视/形体不合；旧海水材质偏亮蓝且粗波，拒直接套换。现有材质可作颗粒/磨耗参照，不冒作已接入。

## 读写与验收边界

正式`world_map_v15_complete_v9c_source.json`85CED93C及`art_contract.json`1E183BEF、64walk、17桥ID的原物理字段/支撑/门户与24c全部正式源保持。新候选独立目录，不能覆盖旧PNG/作者/发布凭据。新材料必须经实际查看；局部样例须由原landMesh受光重出旧桥影范围，不在旧地面PNG上简单叠新桥。

验收：木材纹理有颗粒与磨耗而不发黑，水纹细且低对比、不呈亮蓝粗浪；河岸读得出浅水/湿土/草边层次；桥面与两岸落脚匹配，人物和前后栏杆遮挡保留。若只有局部候选，明确标为未正式合入，不把样例当实际Field。

只读定位报告：`game/build/world_water_bridge_20261024d_system01/source_and_visual_physics_READONLY.json`（B2E470E4）。编辑器51856保留；正式资源尚无修改。

## 材质候选与失败保留

`assets/raw/world_water_bridge_20261024d/`保存两张1254² RGB原生素材，项目副本与工具原生输出逐字节相同：旧木纹v1 `076C8FD0`、河水细纹v1 `54718C63`。均只授局部材质试样，未获无缝认证，未正式导入。完整提示词、独立任务、dry-run和元数据在其`production/`中；工具未披露模型/provider/cost，留空，不伪造正式模型证明。

每图另一次唯一接缝编辑均未改善，v2明确FAIL保留，不替代v1：木材左右/上下边差由16.58/12.43变17.94/12.63，水由6.68/5.83变10.08/7.51；模型亦轻微重绘中央，不冒“只改边”。停止继续生图，不做未授权本地改像素。样例固定v1单片钳制UV、不重复平铺；木纤维V跨桥宽，柱栏沿原构件长轴。材质样例不等于桥结构已自然，也不认证未来整河无缝铺设。

两状态将共用原17桥Mesh、land/RF、原45°相机与光照，只改材质。旧状态须标“程序材质参考（同几何重投影，非正式旧PNG逐像素复现）”：合并deck原局部sin相位不再可精确重建，不为此追加旧几何重建或更多出图。新状态标“PNG材质候选”，最多两张原生GPU图；没有角色或Physics，不能授桥通行实走。

## 首轮实际：技术通过不等于艺术通过

Root唯一`sample_ROOT_READY.gd`（45386F06）在独立0autoload项目运行：actual106820/launcher118324自然OS0，内部8292ms/234检查0，retained WaitForExit10353ms/空stderr，编辑器51856保留。真实两图在`game/build/world_water_bridge_20261024d_system01/native_sample01/project/output/106820_1070953/`：程序参考C2796E34、新材质候选25D5AAAA。不是正式Field，也没有角色或物理实走。

Root、Art、独立QA均实际看两原图：细水纹改善，但新桥浅米色、板条斜向编织纹重复、薄格栅与长直等宽晕岸仍明显，**最终ART与部署拒绝**。不因234技术检查过而把本版合入。

独立QA收口3EEE04F7，post111 `3DA93989`：111条路径390267507B/317ms，本次前后源和15save的SHA/bytes/exactticks全同。两save在本次pre前相对24c已有外部变化，原C730 pre FAIL保留，Root明确以fresh epoch 1E8D5811的当前值为基准；不回滚、不冒24c以来始终零差。

## 唯一集中视觉后继的明确授权

只准另一个candidate PNG、同相机光照，不重reference、不扩全地图/正式导入。原author的source lateral经PPX/ZPPM异比变换后与物理along不正交，首轮正交dot UV不适合真正单板。进一步追源发现`actual_world_draw_geometry.res`是逐index展开的证据Mesh，只保存VERTEX，原NORMAL/INDEX/UV未保存；首轮“原Mesh数组同”不代表完整原renderMesh或光照法线复现，浅色观感不能全归PNG。该限制保留，不洗首轮记录。

后继按冻结次序识别原28组×6个deindexed top三角顶点，核每组q0,q1,q2,q1,q3,q2和Y0；逐板真实skew basis inverse供UV，原top/两underbeam顶点及三角顺序保持，不重复加梁。top的UP由原author恢复；原Box柱栏若无NORMAL，只准按原三角与中心外向验证恢复flat法线，必须明确新增法线属性，不冒旧normal/index同。仅新deck可视副本加向下0.06m侧/底封口；所有原17物理字段/原支撑/Y0/净宽/端点、land/water/RF不改，不能继承首轮“19mesh全同”的几何信用。

原木PNG统一(.58,.50,.42)暖深褐乘色，侧面再.88；旧干岸brown_mud03最大.38、RF高.005～.10且由既有泥纹调变化，少量rock01 scan肩≤.06；水纹.08保持。桥面Y0而水-.025，仅2.5cm露边是现源限制，不靠暗改高程承诺高桥净空。后继尚待实际与独立查看，正式世界仍旧版。

## 唯一集中后继实际

Root代码审查先拦下材质参数名不对应的问题：shader是`warm_tint vec3`，原主稿却set `timber_tint Color`；最终NEW03只正确Vector3绑定与逐member实际回读断言，静态草稿保留，不靠shader默认值冒绑定成功。最终key42B05721/fixture2362787B/helper7A661766/shader0F8AEC3B，完整文本逆DCA48B70、独立静审768CE966。

第二次、也是本轮最后一次GPU：actual112220/launcher113368自然OS0，内部5585ms/1688检查0，retained7426ms/空stderr，编辑器51856保留。唯一图`game/build/world_water_bridge_20261024d_system01/native_sample01/project/candidate02_output/112220_965201/PNG_material_candidate02.png`，SHA599E6CE2，原RGBA87C5228B。28板168个顶点/两旧梁72个顶点及16柱栏原顶点三角序列精同；新增NORMAL/UV及840向下侧底可视顶点另列，没有改原物理源或假授19mesh全数组同。

Root实际看：板向编织纹已消失，旧木色与板厚读得出，水面细波可作为局部材质改进；但长直岸线、统一河道截面及桥台/净空仍显简化，不授正式整图艺术完成。本轮到此停止生图和GPU循环；剩余是原生河岸形态/桥头结构整体设计与正式独立来源接线，不应直接覆盖旧v9c PNG或用素材叠旧阴影。

Art实看只有限准`LIMITED_LOCAL_MATERIAL_BASELINE`，不再调这组木/水参数；QA独立4DD87140同样只准BUILD局部基线，不准完整桥型/河岸/全图或部署。最终post111 `66558685`：111路径390267507B/365ms，原source/24c目标/两v1原图与15save本轮SHA/bytes/exactticks保持；中间3DA939和原pre失败C730全保。两次own GPU均自然退出、未停用户/editor，0正式导入/0正式写。下一独立原子仅两桥头灰褐土石护脚与暗木端梁收口、干岸断续2～3组湿土碎石肩；若真改桥下净空须另做同源水位/支撑设计。不得重开本轮素材/参考图/重复样例循环。
