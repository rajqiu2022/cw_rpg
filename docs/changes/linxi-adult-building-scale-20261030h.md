# 林西成人、房屋比例与山道视觉收口 · 2026-10-30h

状态：6目标已正式合入，正常局部三图已亲看，停止本批复验交用户游玩。不是全工程、所有城市或全部物理通路终验。

## 实际修改

- 村中、南坊21栋完整房屋按真实层数/成人门高定标：一层可见369.5—414.08px，两层客栈772.68px，门145.7—152.5px。主角首帧128.52px。原六门和返回、19个NPC业务脚保持；屋身占地随真实基脚同步，周边非业务物件作必要避让。
- 三个林西原ID的成人按现有NPCNode校准能力统一120—132px。先生124px、货郎130px、婆婆120px，壮年教头/守卫132px。依真实alpha包围框，而非透明画布宽高；待机、行走、对白帧均使用同一成人基准。原人物、头像、身体碰撞、交互Area、巡路和对白业务不改。
- 山道保留原MainField宿主、intro、四交互、动态道具、五门row/三目标与锁、条件NPC和遭遇。只把33丛青蓝旧竹改13丛自然绿竹，退竹连体退；保留竹的原脚点。基础地表用已存在安静材质，竹根局部林地，洞肩撤灰色岛状铺装。
- 30f师徒院完整房屋/实阶侧墙/后院台地及三类mini主角头像已随30g正式接入，本批原封保留。

## 素材与出处

Root使用imagegen技能内置生成一次自然绿竹，无API脚本或回退。1536×1024 RGBA原图保留，maxA254与原A1留白FAIL照录；仅四边补128px RGBA0，不清点、不缩图、不改原RGBA。

- [原图](../../assets/raw/linxi_scale_polish_20261030h/green_bamboo_v1.png)
- [canonical prompt](../../prompts/linxi_scale_polish_20261030h/green_bamboo_v1.txt)
- [工程素材](../../game/art/modules/linxi_scale_polish_20261030h/green_bamboo.png)：1792×1280，SHA `3975D5BC`。
- [padding收据](../../assets/staging/linxi_scale_polish_20261030h_art01/padding_ACTUAL.json)
- 独立无autoload一次导入、41/0整RGBA源/Texture2D/direct精同，自然0；只有3个新import叶晋升。诊断Image.load_from_file导出警告保留，仅诊断读取，并非生产加载方式。
- 图库5223→5226、3路径3缩略，旧记录/nonresources/cache精同；复用索引仅末尾追加。无全图库扫描。

## 接线、保护与验证预算

闭包 `linxi_adult_scale_20261030h_system01/closure01_READY/`：auth `B0CE6F31`、receipt `60D8DCA3`、hunks `F3522F71`。仅FourField/locations.gd/json/g road_layout/native_sources/town_registry六目标。Root apply_patch后native仅EOL/EOF格式归一（全文语义同），最终所有目标SHA/bytes精同候选。Router保持 `21CAF866`，native `6FE073B4`151→162、旧key全保，registry `AA3FDF3B`；10新运行叶+1真实PNG输入。

fresh保护 `D0B3FD1F`：6目标精备、50保护、171实际save仅双读SHA/bytes/UTCticks稳定，0反序列化/写存档。此前用户明确授权只停139344，核命令/父51856后只停该游戏；编辑器51856保留。

- 静态数值/六门完整脚/原business与returns：130/0。之前三几何失败留档，最终新增阻断原路0；原40处既有树/篱笆阻挡不当作新问题清空。
- 新资源普通autoload解析34/0、10资源，0Field实例；自然0，但原七纹理/RenderingServer退出ERROR保留，不冒clean stderr。
- 首正常图130588的96/1失败保：教头目标132px，QA硬上界132被float32约132.000006误拒；生产helper已有.01容差且物理业务同，生产不改。原报告未保存回执数值，该值是依据已核首alpha139/Vector2倍率静态复算，不冒直接观测。只新QA残余尺寸区间用±.01并保目标误差<.01，再看未截三图；旧成功/11室内/World不重跑。

## 最后正常图与保护结果

仅QA02修浮点oracle，生产0改。进程107736自然0、43/0、0Input，保首130588整段FAIL；真实记录教头132.000006377697、先生124.000000953674、主角128.519999027252px，确认与静态复算一致。只继承首源码/原身体业务前缀，未重跑11门或World。首次进入山道真正推进原intro，不直接设seen flag。

Root已亲看三张1920×1080正常图：南坊zoom.9先生与主角并排体量一致，房屋/门高合理；山道zoom1改用自然绿竹，洞前灰色铺装岛已撤。只准本批尺度和材质收口，不授山道整图密度或全部旧贴图质感终验。

- [南坊人物、房屋与头像小地图](../../game/build/linxi_adult_scale_20261030h_qa01/static_normal_preview/107736/h_south_teacher_hero_adult_house_normal.png)
- [山道自然绿竹](../../game/build/linxi_adult_scale_20261030h_qa01/static_normal_preview/107736/h_main_road_natural_green_bamboo.png)
- [洞口及地面衔接](../../game/build/linxi_adult_scale_20261030h_qa01/static_normal_preview/107736/h_cave_shoulder_ground_blend.png)

实际报告 `89663A23` / console receipt `EBAE18E1`；旧七纹理/RenderingServer退出ERROR及ObjectDB warning仍留，不说空stderr。末guard `79FFEDE1`：6target/6backup/50保护/10新叶/1真实输入/171save精SHA、bytes、UTCticks同，0source/save差，只剩用户编辑器51856。停止本批成功组件复测。

静态SAT与公开near截图不等于真实连续走路、门旅行或整城ART；详细游玩交用户。无需关闭Godot编辑器，重新运行游戏读取现役资源即可。
