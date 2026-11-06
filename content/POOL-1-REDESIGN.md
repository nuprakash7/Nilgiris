# Starter deck and Pool 1 redesign

**Historical checkpoint:** superseded by [CLASSIC-MARKET.md](CLASSIC-MARKET.md). Starter/Pool 1 Flair is now removed, placement Gold/prices are explicit, and the market guide is the current balance reference.

Current Godot definitions; the TypeScript prototype is unchanged. Internal IDs are retained for references, despite renamed cards. Starter deck remains three copies of each of its four cards.

| Group | Card | Base Integrity | Effect | Flair (once per physical copy per run) |
|---|---|---:|---|---|
| Starter | Timber Mount | 4 | Adds 4 Integrity. | None |
| Starter | Iron Spike | 5 | Adds 5 Integrity. | Draw 1 card(s). |
| Starter | Span Support | 3 | Adds 3 Integrity. +3 in the middle slot. | None |
| Starter | Even Bearing | 4 | Adds 4 Integrity. +2 in an even-numbered slot. | None |
| Pool 1 | Enhanced Timber Mount | 4 | Adds 4 Integrity. | Permanently gain 2 Integrity on this copy (also +2 now). |
| Pool 1 | Enhanced Iron Spike | 5 | Adds 5 Integrity. | Draw 2 card(s). |
| Pool 1 | Stone Footing | 6 | Adds 6 Integrity. | None |
| Pool 1 | Steel Girder | 7 | Adds 7 Integrity. | Gain a random hand card’s current Integrity; that copy’s placement adds 0 this round. |
| Pool 1 | Left Brace | 4 | Adds 4 Integrity. +2 if its left neighbour is occupied. | None |
| Pool 1 | Right Brace | 4 | Adds 4 Integrity. +2 if its right neighbour is occupied. | None |
| Pool 1 | Cross Tie | 5 | Adds 5 Integrity, plus 1 per occupied neighbouring slot. | Draw 1 per occupied neighbour. |
| Pool 1 | Lone Pier | 4 | Adds 4 Integrity. +3 if neither neighbour is occupied. | Discard 1, then draw 2. |
| Pool 1 | First Footing | 5 | Adds 5 Integrity. +3 if placed first this round. | None |
| Pool 1 | Hefty Pier | 10 | Adds 10 Integrity. The next Forest hit this round deals +4 damage. | None |
| Pool 1 | Closing Keystone | 4 | Adds 4 Integrity. +4 if this is the last placement of the round. | None |
| Pool 1 | Layered Support | 4 | Adds 4 Integrity, plus 2 per link in the current consecutive adjacent-placement chain. | None |
| Pool 1 | Guide Beam | 4 | Adds 4 Integrity. The next Construct placed directly beside it permanently gains +1 Integrity. | None |
| Pool 1 | Staging Deck | 5 | Adds 5 Integrity. Gain 3 Gold. | None |
| Pool 1 | Edge Clasps | 4 | Adds 4 Integrity. +3 in either edge slot. | Return the last 2 discarded cards to hand. |

## Base Forest totals (historical increase; reverted 2026-11-06)

Current damage is restored to the **Previous total** column below. The New total column documents the superseded increase.

All original hit timings, hit counts, conditions, penalties and weather changes are retained. The 20–28 range is the scheduled base total, before reductions/protection and Hefty Pier.

| Attack | Previous total | New total |
|---|---:|---:|
| First Drizzle | 15 | 20 |
| Passing Shower | 18 | 20 |
| Gathering Clouds | 22 | 22 |
| Distant Thunder | 26 | 28 |
| Brief Squall | 20 | 20 |
| Slick Footing | 16 | 20 |
| Sideways Rain | 18 | 20 |
| Shaking Branches | 20 | 20 |
| Mist Between Piers | 15 | 20 |
| Rain on Fresh Timber | 16 | 20 |
| Last Gust | 18 | 20 |
| Wind Through the Gap | 24 | 24 |
| Sheltered Crossing | 26 | 28 |
| Lingering Rain | 13 | 20 |
| Rising Breeze | 15 | 20 |

## Effect conventions

- Flair remains optional and once per physical copy per run. Click an occupied
  column with no hand card selected to activate its exposed copy’s Flair.
- “Turn” means the existing construction round; there is no separate MH turn.
  Closing Keystone gains its bonus on the final board slot **or** the final hand
  card when hand exhaustion ends the round.
- Layered Support counts consecutive adjacent-placement links, including its own
  placement. Slots 1 → 2 → Layered Support in 3 gives +4; a non-adjacent placement
  breaks the chain. Merely having occupied neighbours does not build a chain.
- Steel Girder uses current hand power (including permanent/power modifiers and
  weakness, excluding hypothetical position bonuses), chooses with the run RNG,
  and zeros only the selected copy’s placement contribution until cleanup. Its
  abilities still work. The zero flag survives Bounce/discard/reshuffle during
  that round and expires at round cleanup.
- Enhanced Timber Mount’s Flair adds +2 to current shared Integrity/live power
  and permanently upgrades that copy by +2. Guide Beam’s next adjacent recipient
  gains +1 on that placement and permanently on its own copy. Repeated previews
  do not consume or apply the upgrade. Both survive Bounce and reshuffle.
- Hefty Pier adds +4 total to the next scheduled hit, even if it triggers on that
  same placement. Multiple Hefty Piers can accumulate before a hit. The bonus
  expires at round cleanup; it does not alter later schedules or static data.
  The HUD retains the applied bonus on the resolved checkpoint.
- Cross Tie counts occupied neighbours when its Flair is activated. Lone Pier
  opens a mandatory hand-card discard choice, then uses normal Draw/reshuffle.
  Edge Clasps recovers the newest discards first, up to two or available hand
  space. All Draw/recovery respects the 12-card limit.

## Verification

Ten bounded cases/reviews including retries: editor compile, one data-contract
check, five focused mechanic cases, one targeted Hefty fixture correction, one
native UI case and one wide/small visual review. The initial Hefty test expected
roundComplete despite its deliberately high starting Integrity clearing a room;
the corrected assertion passed on its targeted retry. The native check passed
new Flair targeting, random-copy zeroing, the next-hit forecast, actual scheduled
damage and card hover without a tooltip. Captures are under
`references/pool-one-redesign-*.png`. After that review, a small display-only
follow-up retains Hefty’s bonus on the resolved checkpoint; it was not rerun to
respect the cap. No broad parity suite or balance simulation was run.

Older prototype parity fixtures intentionally encode the superseded starter and
Pool 1 design and need updated expectations before reuse. Later-pool definitions
and all attack schedules were checked against the unchanged prototype data.
