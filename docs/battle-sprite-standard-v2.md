# Battle Sprite Standard V2

## Goal

Battle actors use compact 2.5D game sprites derived from their field identity.
Dialogue portraits and single static illustrations are not valid battle actors.

## Required states

Every combatant owns five independent sequences:

- ready: 4 frames, subtle breathing and cloth movement, planted feet.
- move: 4 frames, played while approaching and returning from a target.
- attack: 4 frames, played only after reaching contact distance.
- hit: 4 frames, readable recoil without changing identity or scale.
- defeat: 4 frames, ending prone and holding the final frame.

No combatant may borrow action frames from another character.

## Runtime frame contract

- Canvas: 512 x 384, transparent PNG.
- Normal human effective standing height: 300 px in the source frame.
- Boss effective standing height: at most 330 px (1.10x).
- Bottom margin: 12 px.
- Horizontal anchor: center.
- Allies are authored facing right; enemies are authored facing left.
- All frames from one atlas use one uniform scale.

The generated source atlas is 4 columns x 5 rows. Process it with
scripts/process_battle_sprite_atlas.py. The processor removes the chroma
background, drops disconnected debris, normalizes the canvas, and preserves
one scale across every state.

## Configuration

EnemyDef requires battle_actor_path plus ready, move, attack, hit and defeat
frame path arrays. Each first-chapter sequence contains exactly four files.

Party dictionaries use battle_sprite_root and battle_sprite_prefix; the
controller resolves the same five sequences without character-specific code.

Run `python scripts/validate_battle_sprite_sets.py` before accepting a new
first-chapter combatant. Godot scene parsing remains a separate required
check.

## Current coverage

The first chapter has independent sets for Leng Guyun, Yue Wuxing, lone
thug, mountain bandit, Zhuwei bandit, dojo disciple, dojo senior, masked
killer, wild wolf, and Zhao Wuji. Later chapter enemies still using legacy
single-frame artwork must be regenerated character by character; reusing a
V2 set from another id is prohibited.

Leng Guyun uses `standard_v4/lengguyun`. Ready and attack were regenerated
together as one reviewed 4x2 two-handed sword mini-atlas so the grip remains
continuous from guard through recovery. Move, hit and defeat retain the
reviewed V3 frames. All runtime frames remain normalized to the 512x384 /
300px contract. Do not restore the oversized portrait-derived `standard_v2`
ready frames or the hand-switching V3 attack sequence.
