# 主角战斗动作与敌方专属招式

盘点 `game/data/skills/` 的 68 项技能资源，包括 45 项攻击、1 项减益、21 项增益及 1 项治疗。[逐招动作路由](../../game/build/combat_forms_20261112/skill-audit.csv)记录兵器类别、目标范围、出手方式及主角使用该招时的动作族。它也列出敌方和队友持有的招式资源。

| 主角武器 | 单体出手 | 群体出手 |
| --- | --- | --- |
| 剑 | 直进出剑，孤云九式独有翻跃接剑 | 转身运剑，抬臂横扫 |
| 刀 | 举刀后向前下劈 | 身体反向蓄力，拧腰横斩 |
| 棍 | 双手送棍近打 | 双手抡棍扫阵，独立手点校正 |
| 掌 | 单掌前推，普攻拳式分开 | 双掌聚劲再推掌，盘龙十七式释放四帧金龙气劲 |
| 暗器 | 原地捏镖、单手弹指 | 原地转腰散射，隐影夺命带两道幻影 |

敌方专属动作按敌人和技能 ID 匹配。赵无忌「黑风卷地」用四帧双手刀横扫，茗雾销卷使「隐影夺命」用四帧抽镖散射，雪岭劫道首领「开山十八刀·伏虎」用四帧抬刀重劈。三者沿用各自已配置的招式和 AI。换动作不会额外发出打击事件，技能消耗、伤害与目标仍由战斗控制器结算。

- 主角实机图 [太极剑法](../../game/build/combat_forms_20261112/wudang_taiji_sword-2.png) · [裂地横斩](../../game/build/combat_forms_20261112/gufeng_liedi-1.png) · [擎天镇岳棍](../../game/build/combat_forms_20261112/heaven_pillar_staff-2.png) · [盘龙十七式](../../game/build/combat_forms_20261112/dragon-wave.png) · [隐影夺命](../../game/build/combat_forms_20261112/hidden-echo.png)
- 敌方实机图 [赵无忌](../../game/build/combat_forms_20261112/boss_zhao_wuji.png) · [茗雾销卷使](../../game/build/combat_forms_20261112/ch6_archive_reclaimer.png) · [雪岭劫道首领](../../game/build/combat_forms_20261112/wild_elite_snow.png)
- 正式图集共 9 张，含 5 张主角动作、3 张敌方动作和 1 张金龙特效。使用内置 ImageGen，原图与正式 PNG 字节一致。[正式资源目录](../../game/art/characters/combat_forms_20261112/) · [生图提示词](../../assets/raw/combat_forms_20261112/prompts.json)

桌面 1920×1080 隔离运行中实测主角五种武器的单体与群体共十招、三名敌方招式，核对独立帧、单次打击和角色归位，157 项通过。敌方用原 AI 回合，在临时内存中限定可选招式以稳定取样。补测剑与暗器普攻、两招幻影共 29 项，群伤、减益、回气回归 110 项。其余技能按动作族复用，未逐个在战斗中施放。手机与发布包未测。[桌面日志](../../game/build/combat_forms_20261112/verify.log) · [普攻和幻影](../../game/build/combat_forms_20261112/verify-echo-basic.log) · [群攻回归](../../game/build/combat_forms_20261112/verify-group.log)
