# Five independent functional interiors — candidate source, not activation

Two exact old exterior room IDs select new resources only when the dedicated
candidate flag is enabled: shop → smithy; north_market_front → cloth shop.
The original R registry, old room TRES, city Scene/layout and published proof are
not modified. Market portal projection checks the original exact door ID, feet,
size and old room spawn, then changes only its local cloned label/target resource
path/target spawn. It does not mutate the proven source Scene or geometry.

Warehouse has an independently authored room but its external door is disabled.
Its source-aligned proposed feet [754,610] and bounded approach route require
original C full 875+17 and native Physics before opening. Pawnshop and mansion
have no matching exterior and remain unbound candidates, not playable doors.

All author JSON polygons and route coordinates are source-visible ground feet
at 1536×1024, not body origins. Player remains legacy actor_positions_are_feet=false
with unchanged native 34×24 collision and +42 child offset. For actual world W,
source feet F map to origin UV F/[1536,1024] − [0,42]/W exactly once. An explicit
remembered room origin is not transformed again. Existing matched outdoor feet
and actual remembered exterior return semantics are preserved.

Furniture uses the reviewed ground-contact polygons, not tall visual bounds.
The Field builds native CollisionPolygon2D only for this new exact room family.
Once per setup, verified geometry compiles source/world PackedVector2Arrays.
Frame queries check full rectangle/polygon overlap plus 17 points and ≤4px motion;
full875 audits are independent setup/test options, not frame-loop pixel scans.
NPCs reuse three existing role sprites (farmer as craftsman, waiter as cloth
assistant, merchant as warehouse clerk), not new specialist animations. Their
existing ground-anchor mode aligns final visible feet and native body; Player
is not switched to ground-anchor mode. Three daily dialogs are ROOT-approved,
with no choice/reward/flag/economy changes.

Raw image bytes are exact copies of the imagegen outputs; model undisclosed,
not CC0. Source-author v2 is independently pinned via raw_author_sha256. Separate
isolated import verification requires all 23 parameters, native CTEX and exact
full RGBA equality. An empty import_approval intentionally refuses room selection.
After ROOT import verification, only new import/proof leaves and the registry
hash may be bound before the limited real entrance/return test. FORMAL stays
false until ROOT explicitly authorizes activation. No engine has been run by
the SYSTEM author.
