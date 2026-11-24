# 洛阳宅园铺装与空间衔接 · 2026-10-21al

状态：铺装比例与三门透草修复已完成候选实图，整体院落仍NOTREADY，未正式替换；正式仍ae。

用户要求继续。目标是北院铺装、门内暗部、短墙与低花坛收边，不再增加房屋。优先复用现有原生素材，不修改三类建筑PNG；不泛化此前三组件抠图授权到其他素材。

ART先给可用素材与边界，System制作新visual-only子包，Root运行一次新候选出版与真实Sprite图，QA核继承范围。AK已验证20实体／mask／门位／2710新采样与661继承点不整批重跑。新增实体若确有必要必须另报有限差量；不能把可碰撞墙体作为无碰撞装饰直接塞进已验证路线。

不改正式Router／Field／NPC任务／存档／加载链。编辑器、Ollama服务保留。未经实际图审不称完整宅园或正式上线。

## 实际结果

当前保护已实际采集：before `362CFA26EA02EF909BCF7D92B27E3191FEB80AD5E67CB7B35ED8BF905BF67414`，2094现有路径、15存档、tasks零授权差。只继承AK路径集合，重新读取当前值，不复制旧快照数值。

Root已实际查看规则青石平面 `ancient_temple_assembled_20261016/courtyard_floor_v1.png` 及 `luoyang_assembled_interiors_20261016g/shell_formal_hall_v1.png`、`shell_residential_v1.png`。优先以原生AtlasTexture组件复用，不改PNG、不生图。门洞由AK已校准的开口与建筑scale映射，深度层置于门脸之后，用真实墙脚／地板纹理而非黑色Rect。短墙和花坛若无安全物件与实体差量，本批先不伪装成无碰撞装饰。

ART最小资产清单18474669含3现成PNG及其区域，原清单保留；System明确继承并把偏小的门内补片建议改为AK真实开口grow3源像素，仍同比原建筑缩放、层级在门脸后一层，避免透草缝。首作者D5686A95、脚本127D66B3，check-only自然0。

首实际console113320自然退出0，渲染PID111448，2273ms，报告 `4F66E4CB67F80851F3A57B6FA0E559B1E3F73B459E77DC332F395491BBBBA3A3`；23真Sprite＝16原非地面构件＋4铺地＋3门内材质层。原46粗石行撤除，20rect／mask／门户／路线完整typed逆和native／packet读回通过，没有重跑几何。首图 `4C84F1EDCB2E2E6C01C049DA52660B4D89C70536A76A6DD731D0AEE1149C8812` Root／ART实看3门不再透草，但native1:1青石块过大、近成人或超过门高，整体艺术拒绝；原源码、报告、图全部保留，不能把执行成功当艺术完成。

唯一revision2定向修正仅四段铺装：scale1→0.25，1×1→4×4，四段整体footprint精确保持，门内层及16原构件不变，不改PNG或物理／NAV。待实际后补。

revision2作者 `1D6167F31E1A6BBD7227E3EA21D0F6C07236C3D1E85582B25E48F77BAF930EA1`，脚本 `6ADA8A1D3BDF2E9D1BF6CB746C004518430BC2F23C3CD5CE922343F90A597597`。新增固定首作者／实际报告／3native／图及完整来源绑定，12个grid字段整逆、四块footprint逐Vector2全等。NEW check-only自然0，无更改首版源或六Atlas。

修正唯一实际console120940自然退出0，渲染PID16096／2676ms／83真Sprite＝16原构件＋64同比铺装块＋3门内材质。报告 `C4A66219FB29E784F3C3BF4A8E3185627765853E9943E6F7DFC70B70A361A20D`，73来源首末相同、native／packet完整逆及读回通过，20碰撞矩形／walk bytes／门户／路线不变，geometry_rerun=false，未复旧2710／661或AI2226。console码不补造独立render子OS码。两个实际过程都保留7次旧型退出Texture／RenderingServer ERROR，0 SCRIPT，非clean。

修正版图片 `9224A3EAC5DBBA6626798B8613572D769BB7F1BE3BCCB86689A574EF5DCD2C0D`：

`game/build/luoyang_estate_courtyard_20261021al_system01/revision2/actual/16096/estate_paving_depth_native_sprites.png`

Root／ART实看青石与成人门洞比例可接受、三门不再透草，有限准PAVING_SCALE_AND_DOOR_GRASS_FIXED_CANDIDATE。整体仍拒完成：草石硬直边、回廊孤立、门内偏平、短墙／花坛／收边缺。下一是短墙与低花坛素材及有实体的围合差量，不继续加楼或反复铺地；真实墙体不能冒无碰撞装饰。未导入新媒体、未接正式Field／Router／室内往返，不授加载速度或全城完成。

最终保护 `6221BEF68D5232E7C234D3CEFE4A8E621954263313CC27EFBF9962740C7BA16E` 自然0，2094当前保护路径全SHA／bytes／exactticks同，含15存档与tasks。NEW Atlas／两版候选native／实际图另列来源，不冒全workspace零变；原建筑PNG、原AK源和产物不改。自己检查进程自然退，编辑器51856、Ollama API100140保留。

QA实际后只读薄审 `0F7B860D08FA2EE42F52F898FF1BF8B2D7CC1072A2D0F333CD5FC01A1C26E8F0` 独立确认恰12个作者参数变化、四footprint与origin精确保持、73源和新产物当前SHA同，并看同一张图，无引擎／像素／采样复测。最终检查点 `3241A8B1510B01C34650D895E95C42C26521FAE166CE5AA4AB8977DC5365C62D` 明确本次只完成铺装比例和门内层次候选，不授整院或正式场景。
