# 汴州街坊与装卸院续改 · 2026-10-28b

change-id: bianzhou-streets-courts-20261028b

## 本轮目标与边界

接上一轮6144²八区正式版，先完成两处看得见的街段：中轴西侧铺后街坊、西货街装卸院。复用已导入完整建筑与低货物，不生图、不动旧城门组件，不把门皮/旋转正面楼/灰代理墙当围合。原25楼、22NPC身份与南北门、商人/榜机制保持。

写范围仅汴州专用Author/必要Field后继；正式公共Router、洛阳来源闭包、原Scene、共享Field、存档、UI与赤岩工程不写。新增实体用真实比例并同步碰撞；主要街路与原NPC操作脚区保持。

因新增实体可能占到旧版本28保存脚点，本地布局升29（不改存档schema）：域外原UV保，仅新增实体脚体保护域按逐行登记服务巷锚点显式迁移，未知版本拒；不最近安全搜索。旧World/北返/商店/对白结果继承，检查仅新增迁移、受影响通路与必要一张实机图，详细密度交用户。

## 本轮已合入并通过新增街段/人物显示检查，交用户试玩

最后正式Author `F1CC4BFF` / Field `27E8F4CE`（完整SHA见下），两处街段的2栋完整后楼与14低货已实机。15480的1213新增域检查/589INPUT继承，未重跑。末次91668/100248自然0/46检查0/3800ms/5真实INPUT/1原生图：两工匠原ID脚role、正式4帧和匹配头像路径、112px可见成人高、真实20.16×25.92NPC体通过，32px短步可动；无actor/camera写，无对白或经济操作。Root亲看`game/build/major_cities_20261028_qa03/actual/100248/craftsman_after_short_input.png`，占位小人已消，新增楼与低货比例有限准，不冒全城ART。

最终保护`game/build/major_cities_20261028_qa02/final_guard_visual_ROOT_ACTUAL.json`，SHA `1c11f506d5904f414245f515a2ee9dce45819befcb0da581d6d5f54300d2cf89` PASS：12源仅Author/Field两个精确授权后继、原其余10与显式Entry保持，2全文备/15save精ticks/66媒体事实同，0存档外变/写入/还原，自有游戏均自然退出，editor51856保留。旧7退出纹理/RenderingServer ERROR仍保，非clean。

停止本批引擎/媒体/旧功能复验，玩家普通重运行可进汴州查看西环后街与西市货场。完整东西城墙、余区密度、内景及整城艺术仍待，金陵、襄州仍未施工。下列“待运行/用户游戏”内容是本轮前置历史，不能替代本段当前结论。

### 用户退出游戏后：新增街段实际已通过，人物显示残余正在收口

用户回复“游戏已退出，编辑器保留”后，Root唯一115812/15480实际自然0：1213检查0/13502ms/589真实INPUT/1张原生图，16新增body与sprite真安装、完整脚体路样本、28→29逐行迁移/域外保持/v1及未知负控、原楼/路/门/榜/业务保持均过。同Field/Player/Camera真实走两街段，无actor/camera写，不复原商店/对白/World/北返。明确公开1450,2720 setup，2.882秒不是默认冷启动性能承诺。

原结果`game/build/major_cities_20261028_qa02/actual/15480/result.json`和原生图`two_streets.png`保。Root已亲看图：本批整楼与低货比例可读，但旧修车匠素材仍是debug占位小人，不能把技术通过冒全画面ART。只修两个原句：Author smith路径换既有`npc_duqingshan_v3_idle_down_25d_4f.png`，Field显式同人头像`portrait_duqingshan_steady.png`，匿名ID/位置/role/body/对白及全部路体不改；不新增命名剧情人物。

上述“body不改”精确指Author中的34×24玩家保护域/楼货物体与player定义，不是NPCNode自动体逐值不变：旧debug图192×256被共享逻辑估为24.192×41.472，正式图640×160/4帧后实际按160帧自动收为20.16×25.92。保留正常正式帧体，不精保占位图造成的过大无形体，也不改共享NPCNode；残余如实核新体，不能假称原NPC物理数值完全保持。

最后正式Author `f1cc4bff9401b1f8ba52b461f64fa178d49aa1f4bf57d24e24ceda985cf1821f`、Field `27e8f4ce2e1669ff4ef1816a1e39134e710f5eee18210f32e4f4095f01fa8831`，精同system03两个候选；Entry/Router仍不写。原1213组件继承，下一仅工匠显示/匹配头像路径及一张残余图，不重旧矩阵。

街段实际后保护`post_streets_ROOT_ACTUAL.json` SHA `cf3d63651f14874e3b0e6444be8c1aaf9094a582cc34452f158ba725b32c7477` PASS：15save精ticks/2备/48+12媒体同，Root自有115812/15480均自然退出，editor51856保。7既有退出纹理/RenderingServer ERROR保，非clean。以下为前置施工/等待历史，不覆盖本条实际结果。

Root仅通过`apply_patch`替换正式Author，SHA `e73afc79a79d085bf387faa59eecb6d0e80037310ca18d40edd08189421076c1`，与system02冻结候选逐字节同；Field仍`2c79f8ed`、Entry`71ae33ca`、Router`6c154897`，均未写。普通街楼21→23，另主门/岗棚4保持（上轮“25完整建筑”含此4项）；NPC22、原路、门、榜和商人保持。

两栋真朝向后排楼脚分别1850,2940与1850,4130，宽540；北楼原3020方案已北移80，避开旧檐口。新增14组低货物按真实源脚/原native比例，粮、布、手车和货箱分别复用已有已导入资源，无新生图或本地处理。碰撞按源基bounds与同一比例变换，不居中猜尺寸；手车保完整车把（源bounds139,306,1259,512），铺后车移2240,4310，退开南街与粮组。

ART只读规格：`game/build/bianzhou_streets_20261028b_art01/streets-reuse-spec.md`；System候选：`game/build/bianzhou_city_20261028_system02/`，其中candidate Field仅用于预览，不部署其candidate preload路径。

QA小基线`game/build/major_cities_20261028_qa02/baseline_before_ACTUAL.json`，SHA `848cb8bfc1129059cae3b6d5bd09136fa672012376fd913615c37bb773e34c77`：12源、2全文备、15注册save及48媒体事实。旧结果仅继承原组件，不能算新29迁移或新通路已验证。

当前用户编辑器子游戏96824正在运行赤岩draft，Root不停止它，编辑器51856保持。已请求仅退出游戏；新批Godot解析、迁移/通路探针和原生街景尚未运行，不能称新街段实机或ART通过。金陵、襄州仍未施工，不授其他大城全部完成。

最后只读保护收据`game/build/major_cities_20261028_qa02/final_guard_ROOT_ACTUAL.json`，SHA `4b089ef062ded4e111d7b6a4de4da170c4f3ffd7a8f306f3bfb3f944fcac362a`，PASS：12源唯一Author授权差，其余11精SHA/bytes/UTC ticks同；2全文备、15save精ticks、48既有媒体及12新复用goods媒体事实保持。0存档写/还原，0媒体写/导入，0引擎调用，用户两进程均保。此PASS仅文件保护，不替代解析/新通路或艺术验收。

唯一后续检查包`game/build/major_cities_20261028_qa02/two_streets_READY.gd`（SHA `3be0ecf82d3b9f4363a4e7656d4b50b934406c38b01dc7254f13693c94f53cf5`）及同名JSON（`d12933d0d55543a8fe3713dba5f0a513f7047a8712b5701bd0bc200114368a61`）。上限60秒/1图，从公开1450,2720 setup后真实两街段INPUT，不复旧World/商店/对白。仍未执行，不能沿用先前actual PASS冒本批完成。
