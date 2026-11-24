# Battle Memory

## 2026-11-18 · 第五章伪旗统领与突袭手比例

- 统领比例 1.30，突袭手采用其原设 0.74，绕开三对三 0.96 的显示下限。两资源分别补血条高度。正式三对三截图及 24/0，待机有效高度统领 255.59、突袭手约 190.12、主角 209.93（逻辑像素），旗令各帧均高过突袭手待机，预警离开头部。测试直接使用原战斗指令，隔离档与最后击败用测试前置。

## 2026-11-17 · 八章剧情 Boss 的蓄势与变招

- 正式队伍战接入十个 Boss 和剧情领队。气血降至 55% 后启用不同轮换并缩短重招间隔。标志招耗一回合前摇，显示单体目标或全体。单体锁定按战斗单位 ID，目标倒下时取消，眩晕、冻结或封脉可打断。仅施放时扣内力。
- 四种新招使用已有 BattleActor 分帧。狼王实际腾跃，蒙面头领穿阵时在接触点播放刀击帧，刺客残影换位时播放原攻击帧，考官扫过全队。第 5 至 8 章采用各自原招并重排出招。武林考官的普通切磋仍使用原招式池。
- 资源与状态机 107/0，十场正式战斗按各末次结果 73/0，第五章三对三 16/0 并有桌面图。赵无忌战前对白、真实普攻击败、结果返回后原轻功演出 11/0，测试定点进入并降低最后一击前气血。上述测试均用隔离档，未全章节通关或逐场手动平衡。
- 第一章压测夹具补齐视觉覆写，16 随机种子回归 17488/0，群体并行与第八章终局任务旧测试均通过。启动仍有三条既有地图来源校验提示。

## 2026-10-11 · 已批准武侠 BGM 五family替换（仅音乐常量）

- root授权system顺序切换battle角色，先读本记忆。只将 BattleController `BATTLE_ARENA_BGM` 11arena对应五family值和 `BATTLE_BOSS_BGM` 换为 `res://art/audio/bgm/wuxia_20261011/battle_{spar,river,village,mountain,boss}.wav`；arena keys、spar优先/章末boss覆盖、所有战斗参数/行动/胜负结算均保持。未知arena仍取AudioManager.DEFAULT_BATTLE_BGM，现为已认可早期战斗loop `battle_default.wav`。
- 修改依据QA actual before snapshot而非dirty Git基线；当前Battle SHA `BAD948D8…`，独立limited SOURCE_REVIEW_PASS，不授实际战斗/音频runtime批准。本角色未engine、没改SFX/技能/敌人/存档，root与QA串行实际WASAPI验证另记。

## 2026-09-13 · 通缉战与反复历练编队

- 通缉战使用作者化`enemy_ids`并继承普通队伍人数适配；2～13级八名犯人的阵容从独犯逐步提升到首领＋两名同党，榜面提前披露建议等级。
- 三个新历练区都提供1/2/3敌编队，权重3/5/2；双敌是主体，单敌用于喘息，三敌提供低概率压力。敌人掉落铁矿、药材、木料、粗布与行粮，服务练武和门派建设。
- 通缉战败不结算普通死亡叙事：目标迁移到另一候选地点；胜利除敌人基础战利品外，另给全队榜单经验、历练、声望与稀有奖励。

## 2026-09-11 · 唐行舟切磋强敌中档方案

- 仅 `companion_tang_xingzhou_spar.tres` 调整：HP104→280、MP18→45、ATK16→46、DEF6→10、SPD9→14、aggression0.72→0.75；保留普通攻击/行舟扫叶并加入已有破门一棍。共享唐氏招式、玩家队友 `companions/tang_xingzhou.tres`、全局公式及赵无忌均不改。
- 原切磋模板授艺后通常两次命中结束，攻击低于主角防御，普通/扫叶非暴击中值约4/5，18内力只够一次扫叶。新定位为第一章可选强敌：初见可败，授艺和成长后可打，招式比纯普攻明显有效；不做等级跟随，也不要求饮酒或用药。
- 正式资源落地后两次执行 `test_tang_spar_runtime_20260911.gd -- --seeds=64`，未传任何数值/技能 override。均为17222 checks / 0 failed；6组胜局与此前280候选精确一致：Lv1未授艺普攻4/64、用招32/64；Lv2授艺普攻42/64、用招62/64；Lv3授艺普攻59/64、用招64/64。
- 实测策略对比：Lv2普攻/用招平均8.27/5.41回合、最低气血均值26.73/102.64；Lv3为8.27/5.23回合、69.08/136.94。使用实际单人切磋入口、有限内力、真实AI/行动/结算；起始铁剑衣鞋、无酒无药。它们是固定种子机器人策略抽样，不是真人胜率或全八章平衡结论。
- 切磋首败/再败/首胜/复胜/胜后败仍为4/0/18/0/0阅历；正式结算恢复全队战前HP/MP快照、不发普通金币/击杀事件、保留胜利后招募对白。Godot严格编辑器解析exit0，无SCRIPT ERROR；第一次headless退出仍有既有ObjectDB warning，编辑器提示忽略嵌套build/wechat_stage项目，未将其冒称已修复。

## 2026-09-10 · 数值第一轮候选落地

- `BattleFormula` 仍采用减法防御，但实际吸收上限为 `floor(暴击后本击威力 × 0.8)`；不按角色等级缩放。`DamageBreakdown` 新增 `defense_absorption/max_defense_absorption/defense_absorption_capped`，GM显示实际吸收与封顶。
- 取消全局低血量输出惩罚，保留显式虚弱和既有修正分区；旧 trace 的 `low_hp_multiplier` 固定1以兼容消费者。旧 `test_damage_breakdown_batch_20260824.gd` 两条依赖0.45低血倍率的断言已失效，需QA按新合同更新，不能把旧规则偷偷恢复。
- 林西一式4MP、二式8MP；一式归linxi，二式要求剑。另开山一刀/华山一剑/点星棍/扫风/揽雀尾分别4/4/4/6/5MP；七个此前0MP且引用这些武功的敌人补三次施放池。
- 早期陪练/高阶/山贼/凶兽/普通狼/废宅守卫使用首轮候选参数；头狼Boss和高阶武器不盲目增加。完整表见 `docs/combat-balance-implementation-v1-20260910.md`，还需真实有限MP编队验收，不宣称最终平衡。
- Legacy敌人改共用可支付技能AI、扣MP并使用招式命中率；未命中不得触发防御保底伤害、反伤、重定向或附加异常。封招只放行明确的basic_attack/defend，不能放行任意0MP攻击。
- `_team_apply_action_end_status(unit)` 是运行和QA唯一行动结束状态衰减入口；burst/damage_boost/internal_lock衰减顺序原样保留。
- `tests/test_battle_balance_v1_20260910.gd` 121项通过，含真实legacy敌人动作；fixture需在autoload注册后动态加载，且使用完整battle.tscn子节点，避免SceneTree根脚本提前继承控制器导致autoload编译失败。

## 2026-09-10 · 动作方向与受击来源

- 所有战斗姿态经 `BattleSpriteFacing` 逐源图决定真实朝向；不能仅以敌我阵营推断。`dojo_senior` hit四帧和`dojo_disciple` hit首帧属于反向源图。
- `BattleActor.play_hit/start_hit_reaction` 新增末尾可选 `source: Control`；单体/群体/反伤需传来源。击退远离实际来源，不能使用屏幕中线判断；持续伤害无来源时才使用idle方向兜底。
- 主角剑与刀使用内置生图重做的 `weapon_variants_v4/lengguyun`，统一右手持械；其余三系仍为v3。审计与验证记录见 `docs/battle-direction-audit-20260910.md`。

> Role: `battle` / 战斗与数值 agent.
> Scope: battle controller behavior, enemy and skill data, equipment values, combat feel, status effects.
> Canonical docs: `docs/design-mvp-chapter1.md`, `docs/acceptance-checklists/battle.md`.

## Current Combat Shape

- MVP combat is 1v1 turn-based.
- Current battle flow is data-driven from `.tres` resources.
- Enemy defeat should feed `EventBus` so `QuestManager` can progress objectives.
- Equipment bonuses stack into player stats.
- Loot comes from `EnemyDef.drop_*`.

## Owned Files

- `game/scripts/battle/battle_controller.gd`
- `game/data/skills/*.tres`
- `game/data/enemies/*.tres`
- combat-facing value fields in `game/data/equipment/*.tres`

## Shared Boundaries

- Equipment names and descriptions: `lore`.
- Equipment slot schema and UI: `system`.
- Combat tests and repro: `qa`.
- Visual effects or sprite prompts: `art`.

## Tuning Rules

- Any value change must include:
  - adjustment reason
  - expected player experience
  - measured comparison against previous version when possible
- First chapter regular fights should stay short enough for MVP pacing.
- Boss fights may be longer, but must communicate risk and recovery clearly.
- Avoid hidden mechanics that the current UI cannot explain.

## Status Effects

Team battles now use the following runtime status contract:

- status id
- display name
- duration rule
- stack rule
- per-turn effect
- remove condition
- UI text / icon placeholder
- save persistence rule

Implemented ids are `poison`, `weaken`, `stun`, and `freeze`. Poison resolves at
the start of the unit's action for 5% max HP (minimum 4); weaken reduces attack
to 75%; stun and freeze skip one action. Status durations decrement at action
start and are shown above each formation member. New statuses must preserve this
same contract and add a display label before being used by battle data.

## Known Risks

- Battle changes can silently break quest progression if `enemy_defeated:<id>` changes.
- Reward tuning can break economy if shop prices are not considered.
- Adding a new equipment slot belongs to `system`, not `battle`.

## 2026-07-26 Attack Presentation Contract

- `BattleActor.configure()` now accepts optional `attack_frames`; `play_attack()` plays those frames before the existing lunge.
- The main player's normal attack uses the three-frame generated sword-slash sequence. Skill attacks remain on the VFX-driven path so skill-specific VFX and audio cues stay authoritative.
- Enemy actors and party members without configured frames keep the existing programmatic animation. New action frames must be visually reviewed and anchored before assignment.
- The masked killer leader now has a 3-frame normal attack set. It is loaded only for `masked_killer_leader`; other enemy IDs intentionally fall back to the programmatic lunge until their own action frames pass review.

## 2026-08-01 Skill selector and combat presentation

- Use a centered `PopupPanel` with a scrollable skill list instead of a small `PopupMenu`; each row carries name, MP cost and description.
- Attack facing follows source-to-target direction, not idle flip. Contact distance must discount transparent sprite padding so the strike happens beside the target.
- Units without reviewed action frames use the compact lunge/strike/recover fallback until their own sequence is generated.
- Battle VFX receives both source and target. Impacts offset toward the incoming side; projectile effects have a short texture flight before impact.

## 2026-08-01 Formal battle UI and enemy action coverage

- Battle command buttons and the skill popup now use generated `StyleBoxTexture` assets in `game/art/ui/battle/candidates/`; keep program text on top but do not reintroduce flat procedural frames.
- The protagonist attack sequence is `lengguyun_sword_attack_v3_f01..f03`, authored facing right. The actor's existing source-to-target flip contract remains the authority for both normal attacks and skills.
- Enemy definitions with reviewed custom frames still take precedence. Missing enemy attack lists resolve by id to generated sword, staff, palm, or beast archetype sequences in `battle_controller.gd`, ensuring every enemy has a visible authored attack sequence.

_Last updated: 2026-08-01_

## 2026-08-05 One-versus-Many Runtime Contract

- Team runtime must initialize when either side has more than one combatant. Checking ally count alone makes a 1v2 or 1v3 encounter resolve as an immediate victory.
- Story encounters use `battle_group:` and random encounters use weighted `SceneScript.encounter_groups`; the release range for current chapters is 1-3 enemies.
- Victory settlement iterates every enemy and emits each enemy's defeated flag/event while aggregating gold, experience and item drops.
- Missing legacy enemy frame sets use a visible formal fallback at runtime, but named bosses and important enemies still require their own ready, move, attack, hit and defeat art before visual release approval.

_Last updated: 2026-08-05_

## 2026-08-12 Fixed-Damage Martial-Arts Contract

- Damaging skills use `fixed_damage + round(effective_attack * attack_scaling / 100)`; defense is subtracted once inside `BattleFormula`, and `CharacterStats.take_damage()` accepts final damage only.
- Equipment `atk_bonus` is a literal final-attack bonus. It must not be folded into strength and multiplied by two. The same effective-attack calculation applies in 1v1 and team combat.
- Skill quality is authored data (`COMMON` through `LEGENDARY`) and affects rarity/presentation only, never an automatic damage multiplier.
- Current 42-skill quality distribution is white 2 / green 8 / blue 13 / purple 12 / orange 7 after adding the cross-chapter hidden art `canglong_three_turns`.
- Mastery, school equipment, and complement bonuses add attack-scaling percentage points. Healing uses `effect_value` and does not reuse attack fields.
- Baseline anchors: at 31 attack versus 4 defense, Linxi first form deals 37 median damage and second form 50. Chapter-one Zhao Wuji projects 7 player turns at the authored level/equipment baseline.

_Last updated: 2026-08-12_

## 2026-08-19 Weapon taxonomy, dual damage and hit contract

- Runtime weapon taxonomy is `sword/blade/staff/palm/hidden`. Dagger and short-blade equipment normalize to sword; axes normalize to blade. Martial UI grouping is independent, so dagger/needle techniques may be authored as hidden while their held weapon remains sword-compatible.
- External damage uses strength only; internal damage uses inner power only. Literal equipment attack is a final bonus shared by both. Do not reintroduce the old mixed strength-plus-inner formula in controller paths.
- Basic attacks author at least 80% base accuracy (currently 85%); named skills author at least 90%. Equipment accuracy is rare and clamps total accuracy to 100%.
- Critical chance starts at 5% and clamps at 70%, including burst states. This cap must live in `BattleFormula`, not merely in catalogue values.
- Weapon proc data is generic (`poison/armor_break/damage_boost/guard/heal`). A miss must never consume defense/redirect state, apply a status, or be converted to one point of damage.

## 2026-08-19 Status and action-commit contract

- Internal-damage skills build `internal_injury`; reaching 100 resets the gauge and applies a two-turn `internal_lock`. A locked combatant may still use the basic attack, but cannot select named skills.
- Bleed is a turn-start damage-over-time status, parallel to poison but independently authored and displayed. Status definitions own icon and tooltip data; formation UI must show remaining turns and expose a clickable explanation.
- Skill status delivery is data-driven through `inflicted_status`, `status_chance`, `status_duration`, and `internal_injury_gain`. Do not hard-code individual skill IDs in the controller.
- Opening the battle inventory is an action commitment. Item use, equipment change, or closing without a change each consumes the active unit's action and closes the panel.
- Every weapon family must maintain common-through-legendary skill coverage. Sword emphasizes accurate single-target burst, blade balances single/AOE with bleed, staff emphasizes AOE/weakness, palm builds internal injury, and hidden weapons deliver poison/bleed.

## 2026-08-20 Weapon-proc quality contract

- Every normalized family (`sword/blade/staff/palm/hidden`) must have at least one legendary proc weapon; epic proc weapons are intentionally limited to one or two per family. A restrained rare representative is allowed and currently present for all five families.
- Proc caps are authored by quality: rare chance/value/duration `0.20/12/2`, epic `0.30/20/2`, legendary `0.40/30/3`. Poison, bleed and weaken normally scale through chance/duration; internal injury, armor break and healing also use the value budget.
- Weapon procs share the hit-confirmed team-combat path. Supported runtime types are poison, bleed, weaken, internal injury, armor break, damage boost, guard and heal.

## 2026-08-21 Chapter-one pacing anchors

- First-chapter required sequence is tutorial thug → forest beast → cave alpha wolf → ruin guard → Zhao Wuji; caravan escort is the optional first two-target fight.
- Machine targets are 3–4 / 3–5 / 4–6 / 4–6 / 6–9 turns. Zhao remains a soft gate at recommended level 3–4 and must not gain a hard level requirement.
- `linxi_wild_beast.attack` changed 16→26 and `zhuwei_cave_wolf.attack` 22→30. Measured baseline incoming damage is now 6 and 10 respectively, versus Zhao's 26; measured player turns are 4, 6 and 7.
- Every future first-chapter enemy tuning must keep `validate_ch1_battle_pacing_20260821.gd` and `validate_chapters_1_4_balance.gd` green and preserve the rest/reward cadence.

_Last updated: 2026-08-21_

## 2026-08-24 Standard-person simulation contract

- `CombatBalanceSimulator` is the reusable Lv1-20 reference model. Base growth must stay derived from `CharacterStats`; gear is a separate editable profile and must never be silently folded into level growth.
- Expected damage reuses BattleFormula's non-critical and critical paths and weights them by live hit/crit caps. TKK/TTD remain strategy-light diagnostics; poison, bleed, healing, items and player decisions require runtime playtests.
- The previous chapter validator effectively used near-naked stats. With the actually obtainable Linxi sword, the current 19 anchors average 2.63 TKK versus 4.42 naked; 16 encounters fall below their old lower bound and all 19 are safety-easy.
- Under subtractive defense, do not repair difficulty by stacking enemy defense first. Prefer enemy attack/fixed skill damage for attrition, then elite/Boss HP for duration. Keep regular fights short and make the chapter difficult through encounter cadence and resource pressure.

_Last updated: 2026-08-24_

## 2026-09-12 · 后期绝学必须有“本体跨阶差 + 心法机制差”

- 开局低属性会暴露固定伤害档位问题：旧太极剑法在24攻击下仅比林西一式多44点，即使倍率看似高也无法体现橙色获取成本。高阶招式不能只依赖后期属性放大，本体固定伤害必须先形成可见跨阶差。
- 配套心法不能只加少量同区系数。代表性组合应至少拥有一个可感知机制：回血/回内、破防/易伤、暴击伤害、内伤或残血追击；仍以一个心法装备槽维持取舍。
- 心法状态在命中后施加并服务后续行动，残血追击在命中前判断；群攻回血回内每次施放只结算一次。未命中不得触发命中收益。
- 敌我共用招式不能为玩家体验直接批量抬本体，否则会同步制造敌方秒杀。优先把玩家专属成长放进装备心法协同。

_Last updated: 2026-09-12_

## 2026-08-30 · 第七章首个正式战斗锚点

- 调整理由：外院互证需要一个“阻止扣押原册”的实际阻力，但不能把烈云强硬派个体冲突做成章末Boss。
- 期望体验：Lv11同期装备下，两人编队形成约6～8回合压力；巡守承担耐久，寻迹手承担速度与毒/暗器压力。
- 实测对比：巡守单体TKK4、TTD9；寻迹手TKK3、TTD11。两者均非Boss，章节成长快照记录1个锚点但继续保留“战斗覆盖未完成”。

_Last updated: 2026-08-30_

## 2026-08-30 · 薛影后殿条件Boss

- `ch8_xueying_last_guard`为Lv15单体条件Boss：1850气血、280内力、攻击158、防御35、速度48，目标8～10回合。
- 战斗只在玩家主动选择死战或证据/撤离条件不完整时发生；伏法和作证路线不强塞战斗，避免战斗覆盖剧情选择。
- 专属`mingwu_sanctum`战场与Boss BGM已接入，五状态各4帧；胜利对白完成`q_ch8_main_10_xueying_resolution`并开放苏雾笙终局门。

## 2026-08-30 · 苏雾笙终局Boss基线

- `ch8_su_wusheng_final`为Lv16最终Boss：2650气血、480内力、攻击112、防御44、速度43；2026-09-09按完整队伍矩阵调整为满队约13回合、独行约16回合。
- 专属“壶雨封脉”为三段内功茶劲，固定38、攻击系数138%、58%茶毒3回合；Boss仍混用雾隐三式与隐影夺命形成节奏变化。
- Boss不掉金币，战利品通过任务奖励交付紫砂暗器；战后按剧情活捉，不用普通敌人死亡语义直接宣告终局。

## 2026-08-24 · 伪旗统领章末战接入

- 伪旗统领三人编队正式接入营地校场：Lv9统领620生命、82攻击，搭配两名Lv8突袭手；2026-09-09完整队伍矩阵目标为8～13回合，以群攻频率和减员压力控制节奏。
- 统领拥有独立约300px战斗尺度、四帧双手挥刀动作、负伤受击/倒地形态与及时刀击音效；不复用赵无忌或普通镖师。
- 章末奖励不再增加新的橙装或绝学，避免第五章末尾一次性堆叠成长；奖励集中在补给、证据与方法选择，为第六章保留成长空间。

_Last updated: 2026-08-24_

## 2026-08-24 · 第五章Lv7～9保底成长

- 雪岭双人战保底紫色金刚斩马刀与紫色《断雪回锋》：固定28+外功×128%，94%命中，60%概率流血3回合；身份是窄路回身单体刀法，不额外叠暴击与破防。
- 矿道证词保底紫色《寒岭守元诀》：常驻生命/内功/防御，主动守势20点、2回合；装备效果仅给温和系数，不与协同、暴击和内伤同时堆成高风险心法。
- Chapter 5正式战斗锚点仍为24场模拟中的5场；下一批只接入伪旗统领三人Boss，不重新提高雪岭/矿道单体生命拖时长。

_Last updated: 2026-08-24_

## 2026-08-24 Mainline reward diversification

- Chapter 2 now guarantees `zhuwei_bamboo_guard_art` at the Lingyue report; the former side-quest copy was removed.
- Chapter 4 now guarantees `luoshui_canal_staff` plus `rolling_cloud_staff_storm`. The staff is blue quality, 30 attack, +10 staff scaling, and a 20%/2-turn weaken proc.
- `q_ch4_side_06_canal_grudge` keeps its palm-gauntlet identity and no longer teaches a staff art. Reward packages must align weapon and technique semantics.
- Both mainline arts now own project-local four-frame VFX: Bamboo Vitality Art uses self-cast bamboo guard energy; Rolling Cloud Staff Formation uses a large teal-gold staff sweep.
- The chapter snapshot now marks chapter 4 complete. Chapter 2 still needs a guaranteed equipment and non-sword attack step before its progression package is complete.

## 2026-08-24 Chapter-two hidden-weapon transition

- `q_ch2_main_02_rescue_yue` guarantees `zhuwei_bamboo_sleeve_crossbow` and `bamboo_rain_piercing_shot`; chapter two is now complete across equipment, attack art and internal art.
- The sleeve crossbow is deliberately focused: 22 attack, +3 speed, +2 agility, +10 hidden-technique scaling and a 12%/2-turn poison proc. It has no extra crit or hit bonus.
- Bamboo Rain Piercing Shot is a 96%-accuracy single-target external technique with a 45%/2-turn poison application and a hard hidden-weapon requirement.
- Both the weapon and technique own project-local semantic icons; the technique owns a dedicated projectile VFX. The 58-skill semantic icon audit is current again.

## 2026-08-24 Chapter-five combat anchors

- Chapter 5 now has five formal unit anchors and five story formations: relief road 2-unit, grain convoy 3-unit, snow pass 2-unit, mine hunt 2-unit, and false-banner captain 3-unit.
- New enemies occupy Lv7-9 with 260/320/350/420/620 HP and 68/76/82/86/82 attack. Their individual TKK remains lower than whole-formation encounter duration.
- Unit-anchor TKK is intentionally lower than whole-formation target rounds. Multi-enemy composition, status pressure and target selection create encounter duration; do not inflate every unit into a miniboss.
- The simulator now owns 40 chapter-one-to-eight anchors; chapter five formations are reachable from authored scenes and quest actions.

## 2026-08-24 Chapter-five relief vertical slice

- The relief road now runs the formal two-raider formation; the convoy camp runs two raiders plus one false-Lieyun striker. Both have authored pre-battle and victory dialogue.
- Road victory grants a purple defensive item before the three-unit convoy fight. Convoy victory grants supplies, while quest completion waits for false-banner evidence inspection.
- The new raider uses the complete mountain-bandit animation set; the striker keeps a consistent masked silhouette and authored attack frames instead of swapping to the global thug fallback mid-action.
- `xingyi_grain_convoy_saved` is written only after the three-unit fight, preserving the long-form Canghai legendary-art milestone.

_Last updated: 2026-08-24_

## 2026-08-24 Chapter progression snapshot contract

- Balance profiles now reference `chapter-progression-snapshot-v1.json`. Guaranteed main rewards, one required faction branch and optional rewards are separate populations.
- Chapter 2 carries the Linxi early set because no guaranteed equipment/martial/internal-art reward exists. Chapter 3 uses exactly one faction transition set. Chapter 4 carries that set because its main path only guarantees an internal art.
- Lv7+ gear profiles are planning assumptions until chapters 5-8 own reachable tasks and battle anchors. Never use optional orange/purple shop or side-quest rewards as the default TKK baseline.
- Any reward change must rebuild the snapshot and rerun the standard simulator before enemy tuning.

_Last updated: 2026-08-24_
# 2026-08-13 - Weapon identity and crit integration

- Weapon power budget now uses quality attack floors 10/14/22/34/50 for common through legendary; the legendary sword ceiling is 66 attack.
- Swords and daggers gain real speed/agility/crit chance, blades and axes gain attack/defense/guard, and staves are balanced. Insight is a learning attribute, so only selected rare armor/accessories and a few signature weapons may carry it.
- `crit_chance_bonus` must be aggregated by Inventory and passed into the single BattleFormula entry used by all four controller paths. Do not add crit only as catalog/UI copy.
- Chapter 1-4 balance validation remains at 15 encounters, zero warnings and zero failures after the weapon pass.
- Every weapon also carries a quality-tier `weapon_skill_bonus_scaling` (4/6/10/15/22). This is independent from and additive with `skill_bonus_scaling`: e.g. an epic school weapon grants both +15 weapon-style scaling and its authored school bonus.

## 2026-08-13 Actor motion contract

- `Skill.motion_style` owns body staging independently of `animation_id`, which continues to select impact/projectile VFX.
- `DASH_THROUGH` crosses the target once; `SHADOW_FLURRY` performs several fast passes with afterimages. Both resolve the strike beat before recovery to the formation home position.
- Current displacement roster: canglong_three_turns, huashan_poyun, huashan_jianduan_qianshan, qinghe_swallow_sword, mingwu_saofeng, mingwu_wuyin_sanshi, and mingwu_yinying_duoming.

## 2026-08-13 Unique skill VFX contract

- Every `Skill.animation_id` must equal its `skill_id`; this makes duplicate ownership visible and keeps resource, registry and catalogue naming aligned.
- Dedicated VFX is not limited to damaging attacks. Team and legacy HEAL/BUFF paths must play the skill effect on the actual recipient before returning, while attack paths continue to resolve source motion and target impact separately.
- `validate_skill_vfx_motion.gd` locks registration, source-sheet existence and 42 unique IDs. `validate_battle_vfx_unique_playback.gd` exercises representative defense, heal, ward and multi-slash effects through the runtime player.

## 2026-09-09 · 第五至八章队伍节奏基线

- 全章确定性矩阵现覆盖27场×1/2/3人队。后期标准配置只使用散修稳定可得的进阶武学、预期装备倍率和两枚应急大还丹；橙色绝学与门派技能不得成为通关假设。
- 第五章伪旗统领目标8～13回合；薛影9～11回合；苏雾笙13～16回合。终局用耐久、状态与药品压力，禁止恢复到158/178攻击的单击秒杀模型。
- 后期普通追兵不能挂玩家橙色终极招式。敌方模拟需复现`aggression`概率、招式轮换与分散选人，队友必须复用运行时×3属性伤害公式。
- 第五至八章7张危险地图在各自剧情战清除后开放低频2/3敌随机池；触发距离720～880像素、概率8%～12%，Boss不重复刷出。

_Last updated: 2026-09-09_
