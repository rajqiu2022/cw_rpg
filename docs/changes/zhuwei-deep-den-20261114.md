# 后山洞窟 · 头狼深窟

两条火把照明的洞道分别接废弃矿道与地下水道，在洞内会合。月光落在后部低岩台，灰毛狼王站在岩台脚下。新版走区沿干燥石地描画，岩壁、岩台和两洞道之间的岩堆都在走区外。到达大厅会自动播放头狼对白并接战。胜利后仍需调查货筒才能推进到城西废宅。

地图狼王使用已有灰狼图集的四帧待机，四张切帧共用等宽画布和脚点。战斗也使用同一灰狼图集的五组动作，体型大于洞穴野狼。敌方倒地动作停在最后一帧，血条和状态图标收起，场上保留倒地精灵直到转场。原退场音效继续使用。

- [游戏底图](../../game/art/backgrounds/bg_ch1_cave_deep_den_v2.png)
- [地图布局](../../game/data/maps/ch1_s4_cave_deep_den_layout_v2.tres)
- [狼王地图待机](../../game/art/sprites/battle/zhuwei_deep_den_20261114/field_idle.tres)
- [矿道侧剧情](../audits/evidence/zhuwei-deep-den-20261114/mine-approach.png)
- [水道侧剧情](../audits/evidence/zhuwei-deep-den-20261114/water-approach.png)
- [第一只倒地](../audits/evidence/zhuwei-deep-den-20261114/first-wolf-down.png)
- [两只同时留场](../audits/evidence/zhuwei-deep-den-20261114/both-wolves-down.png)
- [桌面运行日志](../audits/evidence/zhuwei-deep-den-20261114/stdout-v6.log)

桌面 49 项通过。两侧走入触发使用实际方向键，四次双向门户转场用定点站位后按空格。两只狼用普通攻击先后击败，测试用隔离任务状态和低敌血量。结算后播放原胜利对白，调查货筒完成原任务并接取后续。

底图由内置 ImageGen 生成，1536×1024，无改像素接入。[底图原件](../../assets/raw/zhuwei_deep_den_20261114/deep_den.png)

> Create a production 2.5D Chinese wuxia RPG cave environment background, wide landscape exact 3:2 composition, high-detail realistic pre-rendered 3D style, three-quarter overhead fixed camera tilted down strongly, no horizon. The attached game screenshot is a style reference only. Redesign as a natural wolf alpha lair. Map art must expose connected simple walking topology: entrances at normalized x .25 and .75 near bottom y .84 are two separate, short warm-lit tunnel breaks between bulky foreground rocks, each with broad open walkable dry stone from y .84 up to the central arena at y .64, connected across middle. Main arena is broad, legible dry dark grey gravel from x .20 to .80 and y .36 to .68. Huge jagged layered wet limestone walls enclose top and sides; a cool moonbeam from a natural high crack illuminates a low grounded rough ledge at back center around x .5, y .32 with enough space for wolf sprite added by game later. Sparse old crates at back right x .65 y .29, rope there, a few bones and scratchmarks near side recesses, subdued reeds; no regular fortress walls or symmetric stairs. Columns at far edges beyond walking ground. Distant wall pockets dramatic cool blue, foreground two sparse amber torches placed near actual tunnel walls. Floor medium dark but readable with clear paths, stone size matched to a human sprite about 130 pixels tall in a 1536x1024 picture. Full map visible, exact 3:2, no characters, no wolves, no HUD, no text, no arrows, no inset or frame, near-black void outside natural rock. Render the two exits at lower left and lower right as obvious openings, not black paths detached from floor. Native 1536x1024.
