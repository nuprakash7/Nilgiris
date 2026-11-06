# Nilgiris — Godot

**Current build:** Classic uses one animated circular progress/Integrity meter
and four small full market cards across the top, with 20 starters
and a seven-card opening hand. Placement Gold funds purchases and paid draws;
unspent Gold carries between rounds, with no round payout. Fresh runs start with 3 Gold. Starter/Pool 1/Pool 2 Flair is removed. Pools 2 and 3 use the designer’s revised cards: [Pool 2](content/POOL-2-REVISION.md), [Pool 3](content/POOL-3-REVISION.md). Pools 3–5 retain their listed Flair. [Pool 4](content/POOL-4-REVISION.md) and [Pool 5](content/POOL-5-REVISION.md) use the revised Integrity, Gold, prices and conditional effects.
See [CLASSIC-MARKET.md](content/CLASSIC-MARKET.md) for current balance, controls,
prices, replay policy, artist settings and verification limits. Earlier checkpoint
notes below are historical. MH Construction remains removed.


For cloning, artist access, model replacement and collaboration, read [ARTIST-HANDOFF.md](ARTIST-HANDOFF.md).

The current playable Classic build includes all five card pools and animal pools. Older checkpoint notes below are historical; use the current market guide and roadmap for rules and remaining work.

## Open and play

Use Godot 4.7.2 stable standard, typed GDScript, Forward+. Open `project.godot`,
press F5; F8 stops an older run. The standalone window starts maximized. Disable
Godot's Embed Game on Play if it opens inside the editor's small Game panel.
No extra downloads/plugins are needed.

1. Drag a hand card onto an empty numbered slot, or click the card and slot. Hover lifts the card; Escape cancels selection or dragging.
2. Placements earn the card's Gold once per physical copy per round. Purchase any affordable market offer; only that slot refills. Purchased cards enter the hand if space exists, otherwise discard. Inspect offers on hover/focus.
3. Paid draws cost 1, 3, 5, 7… within a round. Gold carries between rounds; a fresh run starts with 3 Gold. There is no round-end Gold payout.
4. The round resolves automatically, with a short rain transition. Forest checkpoints show damage, placement penalties and non-damage effects; hover/focus for detail.
5. Animal trials and targeted abilities use the existing acquisition/choice flow. Ready animal icons activate abilities; optional choices can be declined. Selected later-pool cards retain once-per-copy Flair, exposed by selecting a placed Construct without a hand card selected.
6. Escape opens pause/settings, including restart and window mode. All hand cards remain in the overlapping fan; there is no pagination.

The default seed is 42, editable on Main's Run Seed for development. Native loop
checks use seeds 1 and 42; both reach a common-animal trial and later activation
with the tested legal action sequence. A run's outcome still depends on play.
Restart slice resets the run and its owned animals. There is no saved/permanent
collection or save/resume system.

## Supported content and boundaries

- All **15 Pool 1 cards**, the four starter definitions, and **15 Pool 1 attacks**.
- Placement conditions/formula, Guide Beam's consumed next-adjacent bonus, Draw,
  Gold, Integrity/Draw Flair, slot/play-count penalties, intermediate/full-board
  hits, conditional hit reductions and weather increments on full survival.
- All **20 common animals**: immediate Integrity/Draw/Gold, per-occupied Integrity,
  queued/conditional placement bonuses, next-hit Block, hand-power targeting,
  Bounce with conditional Draw, Retain/next-round power, deck-top choice/bottom
  ordering, and draw-then-discard sequences.
- Weighted distinct animal offers, stable habitats, non-overlapping successful
  three-pick batches, failed/incomplete trial behaviour, suspended Construct
  offers, acquisition/capacity decisions, and per-copy cooldowns.

`PoolOne` deliberately filters the active wildlife roster to the 20 common
sightings. This is a bounded development scenario, **not** the prototype's full
75-animal rarity distribution. Weights/affinities and definitions are unchanged;
the four JSON files remain byte-identical to webtest. Weighted sampling runs
against that explicit common-only roster. All current authored affinities are
neutral, but non-neutral weighting is tested too.

The build still stops at first-room completion / transition into Pool 2, defeat,
or the deadline. Later rooms/pools, non-common animals, Support/Reinforce and
later Forest effects remain future checkpoints. No unsupported content is played
through with simplified rules. The village lobby is planned, not implemented.

## Architecture

| Component | Responsibility |
|---|---|
| `content/data/` | Unchanged prototype definitions/configuration |
| `SetupCatalog`, `RoundContent`, `CommonWildlife` | Setup indexing and active mechanic validation |
| `PoolOne` | Explicit complete Pool 1/common-only scenario |
| `FirstRound`, `EarlySlice` | Older bounded fixtures retained for regression |
| `RunState`, `CardInstance`, `PlacedConstruct` | Owned mutable state and exact-copy history/marks |
| `RunRandom`, `CardZones`, `ConstructOffers` | Exact LCG/shuffle, draw/reshuffle, offer queue/suspension |
| `RunSetup`, `RoundRules` | Run initialization and synchronous public actions/round settlement |
| `AnimalRules` | Common-animal rewards, weighted sampling, cooldowns, acquisition and targeting |
| `presentation/main.tscn` | Fixed editable camera, scene composition, foundation, lighting and HUD |
| `world_screen.gd` | Actions → model → view, paging/selection and visual-only feedback |
| `WorldCard`, `BridgeSlot`, `WorldPicker` | 3D views, slot projection, ray picking and drag gestures |
| `reward_popup.gd` | Reusable reward/roster/target/capacity modal with no game rules |
| `ForestBackdrop` | Independent seeded 3D terrain assembly; no gameplay RNG |

No plugins/autoloads or external runtime packages. Gameplay has no scene or frame
callback dependencies. Definitions are read-only; rendering never rolls gameplay.
Animations display already-settled outcomes and cannot change the result. Views
reuse six hand cards and five slots. No per-card viewport passes. Physical picking
runs on input; layout runs on resize. The old 2D runtime interface is removed.

Public actions on RoundRules return an empty string on success or an error:
`choose_reward`, `choose_animal_reward`, `play_card`, `activate_flair`,
`purchase_draw`, `start_next_round`, `activate_animal`, `resolve_choice`, and
`resolve_animal_acquisition`. Invalid actions preserve state/RNG/usage. Readiness
helpers and `hand_power`/`card_power`/`contribution` keep calculations out of views.

The animal helper shares its owning model and content, rather than duplicating a
run or reset flow. Active-content validation rejects unsupported definitions.
No speculative event bus, dependency framework or inheritance tree is introduced.

## Artist handoff and development views

- [General artist guide](art/README.md): independent visual roots and GLB wrappers.
- [Bridge/floor guide](art/bridge/README.md): common support datum and level deck.
- [3D terrain guide](art/backdrops/README.md): 16 individually editable scene
  variants, four depth/atmosphere resources and Blender replacement contracts.
- `art/backdrops/preview.tscn`: F6 lit single-chunk inspection.
- World/Camera3D: editable position, rotation and orthographic Size. No runtime
  look-at override. Stop/restart after camera edits.
- F7/fn+F7: debug-only backdrop regeneration, independent of gameplay.

Animal panels currently use names/text/buttons with no final artwork dependency.
They can later be styled or illustrated separately from effects/state. Newly
added functional UI does not start the final art milestone.

## Verification

Node plus the adjacent webtest npm dependencies are needed only for the developer
oracle. Runtime uses only the Godot project. From the workspace root:

```sh
node nilgiris-godot/tests/check-setup.cjs /Users/anupprakash/Downloads/Godot.app/Contents/MacOS/Godot
node nilgiris-godot/tests/check-round.cjs /Users/anupprakash/Downloads/Godot.app/Contents/MacOS/Godot
node nilgiris-godot/tests/check-slice.cjs /Users/anupprakash/Downloads/Godot.app/Contents/MacOS/Godot
node nilgiris-godot/tests/check-pool-one.cjs /Users/anupprakash/Downloads/Godot.app/Contents/MacOS/Godot
```

Elsewhere supply the Godot path, GODOT_BIN, or put `godot` on PATH. Runners import
first, use temporary fixtures, compare with the actual TypeScript engine and
remove temporary files. They reject JSON content drift.

Recorded checkpoints:

- Setup: 456 states, 26 invalid catalogs, 1,200 RNG rolls and independent copies.
- Original rounds: 267 traces / 1,889 frames / 13 active-content guards. Guards
  were updated where a formerly deferred mechanic is now supported.
- Original slice: 71 traces / 2,571 frames.
- Pool 1/common: 395 traces / **22,690 state/action frames**, all 19 starter/reward
  card definitions, all 15 attacks and all 20 common animals. Includes 148 choice
  resolutions, 487 animal-trial entries, 373 completed acquisitions continued
  into another round, 1,981 rejected actions, and 20 incomplete-trial retries.
  Nine additional invalid-wildlife fixtures check fail-closed actions. Test-only
  boundary/owned-animal fixtures are not injected into normal gameplay.

World/input checks (native or `--headless`):

```sh
/Users/anupprakash/Downloads/Godot.app/Contents/MacOS/Godot --path nilgiris-godot --script res://tests/check_round_ui.gd
/Users/anupprakash/Downloads/Godot.app/Contents/MacOS/Godot --path nilgiris-godot --script res://tests/check_pool_one_ui.gd
/Users/anupprakash/Downloads/Godot.app/Contents/MacOS/Godot --path nilgiris-godot --script res://tests/check_backdrop.gd
```

For screenshots append `-- /absolute/existing/output/directory`. The Pool 1 UI
runner accepts a second user argument for seed (default 1; also verified 42).
Native Metal/Forward+ checks cover reward selection, real mouse/drag placement,
Flair, Draw, paging, modal blocking, end feedback, frame-rate independence,
foundation/straight deck, resize, and the natural animal-trial-to-activation loop. Native fixtures also exercise
all six common targeting UI cases and capacity replacement.
Backdrop checks cover 64 seeds, actual mesh volume, ridge visibility/overscan,
room/reload stability and gameplay isolation. Rendering counts are diagnostics,
not minimum-hardware performance claims. The reference PNG is not a runtime asset.

## Working conventions

Typed GDScript; tabs; snake_case files/functions/variables; PascalCase classes.
Focused responsibilities, composition and explicit dependencies. Preserve IDs,
exact-copy history, RNG consumption, rounding, zones and resolution order. No
balance changes, retired mechanics or new persistence. Profile before adding
optimization complexity. Build one approved checkpoint, verify, document and
report **Action for you**, then stop for review.

## Current Gold rule

Every completed round awards **floor(net remaining Integrity / 5) Gold**,
including ordinary rounds and incomplete trials. Use the remaining Integrity
after round effects/Forest damage, before any Progress multiplier. Room clears
and overflow do not grant additional Gold. Card/Flair/animal Gold is unchanged.
For example, 95 Integrity added minus 68 damage awards 5 Gold. Defeat during
a Forest hit does not complete a round. The end-of-round prompt shows the reward.
This user-directed rule supersedes webtest's old room-clear `/ 2` economy.

## Current gameplay checkpoint: all content enabled

The default run now enables **80 card definitions** (75 rewards, four starter
definitions and Debris), **75 Forest attacks and all 75 animals**, with original
rarity weights. All five exceedingly rare animals are available through normal
habitat trials and the Animals menu. Pools unlock at the existing progress
thresholds; Pool 5 starts at 200 total progress with seven bridge slots.

Panther marks one physical card with a permanent 1.5 Integrity multiplier for
the run. Rani prevents destruction for the round and arms Grace 1. The Martens
and Rusty-spotted Cat use the existing targeting/sequence UI. Permanent marks
survive card-zone transitions; new runs reset them and owned animals.

Final target choices now play the same end-of-round feedback as direct
placements. Victory explicitly offers New run, and cumulative Progress remains
stable during late-room feedback. Hand details identify permanent/temporary
multipliers. Art assets and camera remain replaceable as documented in `art/`.

`scenarios/full_run.gd` selects all content. WorldScreen's Playable Pool setting
still allows earlier progression boundaries for development. The individual
pool scenarios are retained as focused development fixtures.

**F8 → F5** restarts with these changes. See README-ROADMAP.md for the nine-check
verification record. No exhaustive parity suites were run.

Remaining coding: the planned village, desktop options/accessibility and an
agreed save/resume scope, plus representative full-run validation/performance.
Those are separate from the completed content port. Final art/UI styling/audio
and packaging remain later milestones; Steam is deferred.

## Engineering-instrument HUD — 2026-11-03

The gameplay HUD now uses a calibrated whole-run Progress ruler (target derived
from room configuration), a separate uncapped Integrity readout, and compact
Forest checkpoints. Hover or keyboard-focus a checkpoint for its trigger,
conditional damage and non-damage effect details. Checkpoints represent the
attack's occupied-count timing, never a numbered physical slot; Bounce can make
that differ from total cards played. Trigger logic remains unchanged.

Owned animals appear as compact ability symbols with cooldowns; hover/focus
for the name and effect. Click one to use the existing activation/targeting flow.
Draw/discard counts sit beside the hand; the extra-draw control shows its price.
Contextual world hover replaces the old inspection panel. Brief notifications
replace persistent instructions, and pure base-value card descriptions are
removed from the view without editing their definitions.

**Esc / Ⅱ** opens Pause / Settings, containing Resume, fullscreen toggle and
New run. Escape first cancels an optional target/selected card when applicable.
Restart is no longer permanently on the playfield. The menu pauses processing;
resuming or restarting restores it. No save/settings persistence was added.

Visual tuning lives in `presentation/instruments/`: `instrument_hud.gd`
(`_layout` / `_theme`), reusable ruler/readout/symbol/checkpoint controls and
`card_text.gd`. Gameplay remains owned by the existing rule classes. Wide and
small captures are in `references/hud-instruments-wide.png` and
`references/hud-instruments-small.png`. Restart with F8/F5 to see the changes.

## Gold-diamond HUD and automatic rounds — 2026-11-03

The latest HUD follows the supplied visual reference: a circular uncapped
Integrity dial at upper left, a brass-edged whole-run ruler, compact clock/Gold
housings, settings gear and gold-diamond Forest checkpoints. Dark local
instrument faces and scored brass trim are generated vector placeholders;
card illustrations/textured artist artwork are still separate later work.
Existing exact numbers, tooltips, ability targeting and card dragging remain.

**There is no Next round or Next room button.** When a round finishes, a short
rain animation plays alongside the Forest feedback, surviving Integrity transfers
to Progress, and the next reward choice opens automatically. Room overflow and
Gold are handled by the same RoundRules transition owner as before. Required
Support/Bounce choices finish first. If animal capacity is full, the replacement
or decline decision appears after the rain; resolving it immediately continues
without replaying the rain. Victory and defeat remain terminal until New run.
The default full run advances through all enabled pools. Development-only
restricted pool boundaries still stop with their existing explanatory message.

Main → `Round Rain Duration` controls the brief rain (default 0.65 seconds).
`presentation/instruments/round_rain.gd` is view-only, tween-driven and does not
consume gameplay RNG. BrassTrim/BrassPanel and DiamondCheckpoint are reusable
skin components. The original reference and wide/small captures are under
`references/hud-gold-diamonds-*.png`.

Restart with F8/F5. Finish a round and let the rain take you to the next reward;
Esc / the gear still opens Pause / Settings. No project setup is required.

## Full-hand fan — 2026-11-03

The entire current hand is now one overlapping 3D fan. There are no pages,
paging arrows, hand-page labels or wheel-to-page actions. All actual hand
instances are rendered, including behind required reward/target modals; inactive
states still disable play as before. The existing 12-card gameplay cap remains.

Hover or select a card to raise it in front and straighten it for reading.
Exposed card strips use stable screen-space picking, so overlap does not hide
a physical copy from selection. Drag to a free slot, or click a card then a slot;
Escape cancels a drag/selection. Hover also dismisses notifications that would
obscure the raised card. Fan spacing compresses as the hand grows; resize and
seven-slot camera changes retain the full fan within the viewport.

Artists: World → Hand fan exposes Half Angle, Drop, Width Fraction and Depth
Step. Existing Card Art is reused for every copy. The shape/origin envelope is
unchanged; thicker art may need a larger Depth Step. `WorldCard` owns only face
lift/selection; `BridgeWorld` owns fan layout; `WorldPicker` owns overlap picking.
Card, draw, placement and reward rules are unchanged. Restart with F8/F5.
