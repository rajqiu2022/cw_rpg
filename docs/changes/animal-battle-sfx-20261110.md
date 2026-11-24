# 狼、虎、熊战斗音效

2026-11-10。每种动物各两条独立音效，分别是攻击发声和受击反应。使用项目本地 Stable Audio 3 Small-SFX 合成，按实际短音事件截取、加短淡入淡出并控制峰值。[原始六段、提示词和制作参数](../../assets/raw/audio/animal_battle_20261110/manifest.json)

| 动物 | 攻击 | 受击 |
|---|---|---|
| 狼 | [0.53 秒扑咬低吼](../../game/art/audio/animals/sfx_wolf_attack_20261110.wav) | [0.41 秒短嗥](../../game/art/audio/animals/sfx_wolf_hit_20261110.wav) |
| 虎 | [1.11 秒扑击吼声](../../game/art/audio/animals/sfx_tiger_attack_20261110.wav) | [0.58 秒短促喉声](../../game/art/audio/animals/sfx_tiger_hit_20261110.wav) |
| 熊 | [0.83 秒低沉吼声](../../game/art/audio/animals/sfx_bear_attack_20261110.wav) | [0.50 秒粗短闷哼](../../game/art/audio/animals/sfx_bear_hit_20261110.wav) |

狼音效接入八个现有狼类敌人，包括林西躁动野兽、竹尾洞穴头狼和野外练级狼。普通攻击和「裂创扑咬」播放攻击声，实际承伤时叠加狼的受击声，竹尾头狼已有的开场狼嚎保留。虎、熊已有战斗精灵，暂无正式敌人定义。新增敌人时将表中的路径填入 EnemyDef 的 attack_sfx_path 和 hit_sfx_path 即可使用。

桌面核对覆盖六条资源加载、八处狼音效绑定、幼狼普攻和头狼「裂创扑咬」，两次实际战斗确认受击声后正常结算，32 项通过。双狼测试用正式战斗中的两个演员核对群体受击表现，20 项通过。闪避无受击声，同一瞬间的相同音效合并播放。双狼测试直接进战并构造两条受击表现记录。
