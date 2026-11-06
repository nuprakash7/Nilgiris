# Nilgiris migration roadmap

This is the persistent build plan and progress record. Read this file and
`README.md` before starting work. Update the status, verification evidence,
and next action at each completed milestone. Do not treat a planned step as
authorization to implement it: complete one agreed scope, verify it, and stop
for user review before advancing.

## Current checkpoint

- Last completed: **all five pools, all 75 animals and gameplay follow-up fixes**, 2026-11-02.
- Current scope: all 80 card definitions (75 rewards, four starters and Debris), 75 attacks and 75 animals.
- Next proposed scope: **Step 11 — the placeholder village**, in its planned small substeps, after review.
- Latest direction: implement gameplay pool by pool before any art work. Use
  placeholders for every new mechanic. All art/UI styling/audio polish moves to
  the end; only functional UI needed to play and test rules is added earlier.
- Next action: user tests the full roster and run flow. Stop before the village until approved.
- Stack: Godot **4.7.2 stable standard**, typed GDScript, **Forward+**.
- Direction: painterly stylised 3D forest and bridge, elevated camera, readable
  **cards in the 3D world**. Placing a card creates a **3D bridge column in that
  slot**. This user clarification supersedes the original screen-overlay card
  direction. The earlier 2D test interface has been replaced by the 3D blockout.
  Preserve existing gameplay and the original milestone order.
- Visual reference: [Step 5 composition](references/README.md), with the user's
  unchanged sample saved in `references/step-5-composition.png`. Backgrounds are
  provisional; the first pass uses simple bridge shapes and irregular terrain
  planes. Trees, rocks, water, and environmental detailing are not required.
- Steam setup and integration are deferred at the user's request.

## Step 5 playtest follow-up — reward popup and window size

Reward selection is now a modal HUD popup with four readable options. The
3D hand is hidden until selection, and world clicks cannot pass through it.
Reward rules and the deliberately bounded slice are unchanged. The standalone
game starts maximized to fit the available desktop; editor embedded-game size
is controlled by Godot's editor rather than project window settings.

Verification: native interaction suite covers popup selection every round,
blocked world clicks, dismissal, existing 3D interactions and the small-window
layout. Native maximized layout was visually inspected on the Mac display.

Action for user: stop with F8 and restart with F5. If Godot embeds the game in
its editor, disable Embed Game on Play in the Game workspace to use the
standalone maximized window. No further downloads or progression changes.

## Step 5 playtest follow-up — drag and drop

Hand cards support both click-to-place and drag-to-place. A small movement
threshold distinguishes clicks from drags. The existing card visual follows the
pointer; valid slots retain the golden column preview. Release on an empty slot
submits the same play action as click placement. Occupied/outside/HUD drops and
Escape return the visual without mutating gameplay or RNG. Window focus loss
also cancels a pending drag. Reward selection remains modal.

Verification: headless and native UI checks passed, including real pointer
press/move/release, valid placement, invalid/occupied drops, Escape, restored
picking and the previous round/Flair/Draw/closure checks. Native drag preview
was visually inspected. Rules files unchanged.

Action for user: F8 then F5; hold a hand card, move over an empty slot and release.
Try dropping outside the board or Escape; click-to-place remains available.

## Authorized placeholder visual follow-up — layered forest backdrop

Completed at the user's explicit request, independently of the remaining
pool-by-pool plan. This narrowly scoped placeholder iteration supersedes the
art deferral only for this system; final art/audio and the village remain planned.

- [x] Separate four-layer camera-facing backdrop scene with 16 distinct reusable
      transparent-sky/opaque-forest placeholder variants.
- [x] Independent seeded, without-replacement selection at room entry; repeated
      rounds/render calls retain the arrangement, and reload reconstructs it.
- [x] Explicit depth/size/height settings, width overscan, restrained offsets,
      progressive tint/contrast/haze, and lightweight static inter-layer mist.
- [x] Artist-editable texture pool and four layer resources; debug F7 previews.
- [x] Remove superseded far ridges/floor which occluded the new background;
      retain valley banks, bridge, HUD, gameplay rules and artist scene hooks.
- [x] Native multi-seed/compact captures and 64-seed checks for distinct variants,
      ridge visibility across the view, overscan, room/reload stability and no
      gameplay/RNG changes. Existing world input/round checks pass natively.

Artist guide: `art/backdrops/README.md`. Settings: World/ForestBackdrop in
`presentation/main.tscn`. The saved scene seed recreates room appearance; no save
system is introduced. Current slice room boundaries remain unchanged.

Action for user: F8 then F5; choose a reward to inspect the bridge and four ridges.
Press F7 (or fn+F7 on Mac) in a debug run for alternative arrangements. Final
illustrations can replace pool textures later without changing assembly logic.

## Backdrop conversion follow-up — real 3D chunks

The user clarified that the final target is volumetric Blender terrain, rather
than image planes, and authorized conversion now. This supersedes the earlier
texture-pool implementation and its artist handoff instructions.

- [x] Replace texture pool with 16 individual PackedScene terrain wrappers, each
      with an imported editable OBJ placeholder: sloped top, canopy volumes,
      walls/base, real width/height/depth. Retire old SVG plane assets.
- [x] Retain seeded selection, four depth positions, safe offsets, per-layer
      atmosphere, room/reload stability, F7 preview and gameplay RNG separation.
- [x] Keep chunks upright in world space and expose Vector3 size. Apply surface
      atmosphere per instance without modifying source materials or meshes.
- [x] Add an independent lit `art/backdrops/preview.tscn` for artist F6 inspection.
- [x] Update `art/backdrops/README.md` with Blender/GLB replacement, coordinate
      contract, camera/settings and material adapter limitations.
- [x] Verify actual mesh volume/distinct variants, 64-seed projected ridge
      separation/overscan, room/reload stability, native captures and world input.

Action for user: F8 then F5 for the assembled terrain. F7/fn+F7 previews another
selection. Open any `art/backdrops/chunks/terrain_XX.tscn` to work on it separately;
use the preview scene for an angled, lit view. Final art remains deferred.

## Bridge foundation follow-up — seated columns and level crossing

Completed at the user's request. A separate artist-replaceable 3D floor is
instanced as World/BridgeFoundation (`art/bridge/foundation.tscn`). Every column
base rests on its common support level. Decks and rails span the exact 5.2-metre
slot spacing, with matching bank deck height; no small module gaps remain.
The vertical placement rise was removed to preserve level geometry at placement.

Native UI checks passed for actual mesh-top/base contact, common deck elevation,
straight slot centreline, adjoining deck endpoints and all existing interactions.
Rules unchanged. Replacement art must preserve the flat local-Y=0 support patches;
uneven terrain is not automatically ray-sampled. See `art/bridge/README.md`.

Action for user: F8 then F5; fill the slots and inspect the seated bases and
straight deck. Artists replace only foundation Visuals and preserve its datum.

## Working principles

Artist handoff follow-up: replaceable `Column Art`, `Environment Art` and
`Card Art` PackedScene slots are exposed on World. Empty slots retain blockout.
Camera rotation now comes directly from the saved scene, with no runtime look-at
override. See `art/README.md` for folder ownership, Blender/GLB workflow,
coordinate envelopes, camera editing and current limits. This is preparation
within Step 5, not authorization for Step 6 or final art production.

- Build part by part. No complete-game implementation in one pass.
- Apply SOLID pragmatically: focused responsibilities, explicit dependencies,
  composition, narrow contracts, and interchangeable implementations only where
  a concrete need exists. Avoid speculative interfaces and inheritance trees.
- Keep the code lean, maintainable, reusable, and efficient. Avoid duplicated
  rules, unnecessary allocations/work, per-frame gameplay polling, global event
  buses, dependency-injection frameworks, and unused systems or plugins.
- Measure performance before introducing optimization complexity. Record the
  device, workload, and findings when profiling becomes relevant.
- Gameplay is a deterministic model independent of scenes, frame time, input,
  and animation. Presentation submits actions and displays model results.
- Keep definitions separate from individual instances and their mutable history.
- Add types, folders, tests, and abstractions as their actual consumers arrive.
- For each scope: inspect the reference, implement the smallest coherent change,
  run appropriate checks, record results here, and stop for review.
- After every step, report **Action for you**: specific manual actions or an
  explicit statement that none are required. Do not leave setup/testing duties
  implicit.

## Rules and reference implementation

The adjacent `../nilgiris-webtest/README.md` and its linked `docs/` describe the
game. Executable rules/content are in:

- `../nilgiris-webtest/lib/game/integrity/engine.ts`
- `../nilgiris-webtest/lib/game/integrity/types.ts`
- `../nilgiris-webtest/lib/game/integrity/catalog.ts`
- `../nilgiris-webtest/lib/game/integrity/wildlife.ts`
- The four active `../nilgiris-webtest/data/integrity_*.json` files.
- `../nilgiris-webtest/scripts/check-*.cjs` regression suites.

Preserve stable IDs, exact-copy history, RNG consumption, shuffle ordering,
rounding, and state lifetimes. Use the TypeScript engine as the parity reference;
do not replace its RNG with Godot's built-in generator. Compare normalized state
after identical seeds, content, and actions as each mechanic is ported.

Card effects and choices finish before existing rain ticks, Forest hits,
Forest effects, and round cleanup. Full-board closure is latched on insertion.
Empty-hand closure has no later rescue-draw window. Animations never schedule
these rules. Do not restore retired mechanics or apply balance multipliers a
second time. Save/resume is an unresolved product decision, not an authorized
feature; the prototype has no persistence or permanent progression.

## Step 1 — Project foundation

**Status: complete.**

- [x] Create sibling `nilgiris-godot` project.
- [x] Configure Forward+, resizable window, and interface scaling.
- [x] Add a minimal entry scene displaying the title.
- [x] Add Git exclusions, formatting conventions, and architecture guidance.
- [x] Verify editor import and native project launch.

Acceptance: opens and runs without errors; no gameplay or plugins.

Evidence: Godot 4.7.2 imported the project successfully and the native run exited
successfully with no reported errors. Renderer reported Metal 4.0 / Forward+ on
Apple M5. This initial scene required no scripts.

## Step 2 — Deterministic gameplay foundation

**Status: complete.**

- [x] Load and validate the relevant existing JSON content.
- [x] Introduce only the run-state and card-instance types needed for setup.
- [x] Reproduce the prototype's unsigned 32-bit RNG and Fisher–Yates shuffle.
- [x] Keep the model runnable without a 3D scene.
- [x] Compare starter decks and initial setup against fixed-seed TypeScript runs.

Acceptance: matching supported initial-state fields for fixed seeds; no gameplay
UI expansion. Explicitly record deferred initial-state fields instead of claiming
full parity before their systems exist.

Implemented: `SetupCatalog`, `CardInstance`, `RunRandom`, `RunState`, and
`RunSetup`. The four active JSON files are copied unchanged into `content/data`.
Validation is explicitly scoped to initial setup; unimplemented effect and
animal semantics are neither validated nor executed by Godot yet.

Verified with `node tests/check-setup.cjs <Godot executable>`:

- 456 initial-state comparisons against the actual TypeScript engine, across
  six scenarios and 76 seed inputs each.
- 24 fields per state: phase; room/round/deadline; Integrity/progress/Gold and
  purchased draw count; weather; ownership/hand/draw/discard; ID counters;
  reward pool IDs/queue/offers/type; Intent; cells; final RNG seed.
- 1,200 LCG rolls, including signed/wrapped seed boundaries.
- 26 invalid setup catalogs; missing/malformed files; shuffle source isolation;
  independent run objects; separate ownership metadata and live card objects.
- Local JSON matches the prototype byte for byte. Reference scenarios also
  pass the TypeScript full content validator.
- Final headless editor import and native title-scene launch completed without
  reported errors; the native renderer remains Metal / Forward+ on Apple M5.

Deferred at the Step 2 checkpoint: placement/play histories, exiled cards, pending choices and
resolutions, selected rewards/results, mitigation and temporary effects, rain,
slot history, animals/capacity/cooldowns, habitat batches/history, frozen offers,
room payout ledger/events, logs/impact events, loss reasons, and meta hooks.
Step 2 claimed initial-state parity only for the 24 fields above and left the
title scene independent of the model. Step 3 below records the subsequently
implemented actions and state; next-round transitions remain deferred.

## Step 3 — One playable round

**Status: complete.**

- [x] Basic 2D hand and five logical slots.
- [x] Reward selection and click-to-place input.
- [x] Starter effects, Integrity, and one existing Forest attack.
- [x] Correct automatic closure and cleanup.
- [x] Verify survival, defeat, and incomplete-round cases against the prototype.

Acceptance: one complete controlled test round matches the prototype. The
scenario bounds development scope without redesigning production progression.

Implemented:

- `scenarios/first_round.gd` creates an isolated catalog view with the real
  starter deck, five unchanged reward definitions (Timber Plank, Iron Spike,
  Stone Footing, Steel Girder, Left Brace), and First Drizzle. Seed 42 makes
  replay repeatable. The four authored JSON files remain unchanged.
- `RoundRules` owns synchronous reward and placement actions. Invalid actions
  do not change state or RNG. The controller reads state and dispatches actions;
  it does not implement gameplay. Actions mutate the owned run rather than
  deep-cloning it on every click.
- Starter adjacency/even-slot effects and Left Brace use pre-placement state.
  Placed live power and historical contribution remain separate. No Flair is
  activated in this milestone; that is Step 4.
- Full-board hits, excessive-damage defeat, exact-zero survival, provisional
  ownership, incomplete reward removal, cleanup, progress, and successful
  habitat credit match the prototype in this bounded scenario.
- Reusable `CardView` serves offers and hand cards. Selection shows slot-specific
  contribution previews. Controls update on actions and are reused on replay;
  no per-frame gameplay polling, autoloads, plugins, or animation-driven rules.
- Scoped rule validation rejects unsupported active card/attack mechanics and
  content that could reach a room boundary. The first-round scenario does not
  silently simulate room progression or other unimplemented systems.

Verification:

- `node tests/check-round.cjs <Godot executable>`: **267 rounds / 1,889 state and
  action frames**, comparing 36 state fields plus contribution previews and
  action legality against the actual TypeScript engine. Coverage includes 260
  survived rounds (3 with exactly zero remainder), 3 defeats, 4 incomplete rounds,
  unplayed earned rewards, and no-op invalid actions. Eight unsupported-content
  cases are rejected before play.
- Step 2 regression suite: 456 initial states, 26 invalid catalogs, and 1,200
  RNG rolls remain part of the required checks.
- Native `tests/check_round_ui.gd`: actual control signals cover reward gating,
  selection, five placements, cleanup, ten replays without node accumulation,
  and narrow-window layout. Rendered screenshots were visually inspected at
  1280×720 and 960×540 using Metal / Forward+ on Apple M5.

Still deferred: next-round/room transitions, draw/reshuffle actions, bought
draws, Flair, richer cards, scheduled checkpoints/penalties/weather, protection,
destruction, animals, full progression, 3D, animation, and persistence. The
normal-play scenario cannot empty its six-card hand before filling five slots;
short-hand incomplete cases are verified headlessly using legal starter configs.

**Action for the user:** open the project and press F5. Choose a reward, select
a hand card, and click an empty slot. Try Even Bearing in slot 2/4 and Cross Tie
beside occupied slots; previews should reflect the bonuses. Fill the board and
check the automatic result/cleanup. Replay round resets the same scenario.
No downloads or export templates are required for this playtest. Report any
readability/input issues before approving Step 4.

## Step 4 — Repeated rounds and a small playable slice

**Status: complete.**

- [x] Draw/discard cycling and earned reward ownership.
- [x] Progress, Gold purchases, and starter Flair.
- [x] A small selection of actual Pool 1 cards and attacks.
- [x] Introduce targeting infrastructure only where selected effects require it:
  none was needed for these effects, so none was added.
- [x] Focused regression checks for successive rounds and action windows.

Acceptance: several consecutive rounds work correctly with preserved timing,
instance identity, and deterministic outcomes.

Implemented:

- Active `EarlySlice` uses the existing five simple rewards plus Staging Deck,
  and the authored First Drizzle / Passing Shower attacks. `FirstRound` remains
  a regression scenario. All four JSON files still match the prototype.
- Shared `CardZones` draws from the front, reshuffles discard with the run RNG,
  respects the 12-card cap without burning cards, and never draws from ownership
  metadata. Setup, normal Draw, Flair, and paid draws all use it.
- Integrity/Draw Flair is tracked on exact copies across zones, discard, earned
  provisional ownership, and reshuffling. It never resets on replay. Normal
  card effects do not consume Flair. Final-slot Draw/Gold finishes before Forest
  checks and automatic cleanup; Flair cannot be activated after closure.
- Purchased draws cost 1/3/5/7… per successful purchase; free draws do not alter
  the price. Invalid purchases change nothing. Each next round resets the price.
- `ConstructOffers` centralizes initial offers, immediate refill, distinct offer
  recycling, rightmost-out rotation, habitat assignment, and pool synchronization.
- Next Round resets round-local data, draws five additional cards, selects fresh
  independent Intent, and preserves deck/copies, Flair usage, Gold, and history.
- Round settlement preserves progress, deadline defeat, win precedence, and
  per-cleared-room Gold payout/idempotency, including overflow. The slice pauses
  at room completion or a pending animal reward. It does not activate the next
  room/pool or substitute a Construct round when an animal round is due.
- `RoundContent` now owns the active mechanic validation contract separately
  from action resolution. Unsupported active effects are rejected.
- Temporary UI adds per-slot Flair actions, draw price/readiness, round budget,
  Next Round, and Restart Slice. It remains action-driven and reuses controls.

Verification:

- Multi-round oracle: **71 traces / 2,571 state/action frames**, comparing 40
  state fields and legality to TypeScript. Coverage includes 108 successful
  purchases, 193 Flair uses (58 provisional rewards), 63 replays of spent copies,
  157 Staging Deck placements, 24 draw-triggered reshuffles, 136 next-round
  transitions, 66 pending-animal stops, room/overflow payouts, incomplete rounds,
  deadline defeat and deadline victory, and 826 rejected actions.
- The 267-trace single-round and 456-state setup suites remain regression gates.
- Native UI checks cover both Flair types, price/affordability, second and third
  rounds, slice boundaries, cleanup, reuse on ten restarts, and narrow layout.
  Native previews are inspected at 1280×720 and 960×540 on Metal / Forward+.

Deferred: animal play/rewards, next-room transitions and later playable pools,
Support/Bounce/Retain, checkpoint/penalty/weather effects, protection/destruction,
3D presentation, animation, and persistence. Payout and progression-boundary
bookkeeping are present to preserve outcomes, not to enable these systems early.

**Action for the user:** stop any older game with F8, then F5. Place Timber Plank
and use its Flair before the final placement; try Cross Tie's Draw Flair and the
paid Draw button. Select Staging Deck to test its normal Draw/Gold. Use Next Round
and check the purchase price resets and spent copies stay spent when redrawn.
The slice should stop when an animal reward is due or a room is cleared.
No downloads are needed. Share the reference image before approving Step 5.

## Step 5 — Connect the 3D bridge and world-space cards

**Status: complete; awaiting user review of the blockout.**

- [x] Review and persist the user's reference image and explicit scope constraints.
- [x] Confirm the camera/card/bridge composition: user authorized the recorded
  reference direction on 2026-11-02.
- [x] Elevated camera, simple bridge pieces, and irregular valley/background planes;
  no trees, rocks, water, or detailed forest assets are required for this blockout.
- [x] Place readable cards in the 3D world, rather than a screen-space hand.
- [x] Placing a card creates a 3D bridge column in the chosen logical slot.
- [x] Map visual pieces and picking to existing logical slot IDs.
- [x] Placement and damage feedback consume model results.
- [x] Verify presentation timing cannot alter gameplay outcomes.

Acceptance: the same rules work through the 3D presentation independently of
animation speed and frame rate.

Reference received 2026-11-02: wide bridge across the central view, a foreground
row of world-space cards, numbered slots, visible column height, and readable
upper status/Intent. See `references/README.md` for interpretation and blockout
limits. Example values/names and Anchor/Span/Vantage labels do not change game
rules. The sample's End Round button is illustrative: automatic closure remains.
Animal portraits do not bring animal gameplay forward.

Implemented:

- `presentation/main.tscn` now opens a real 3D scene: orthographic elevated camera,
  directional light/shadows, sky/fog, simple valley planes and layered silhouettes.
  There are no trees, rocks, water, external art assets, or generated backplates.
- Six reusable `WorldCard` Area3D views use solid meshes, thickness, native
  Label3D text, hover lift, selection borders, and physics picking. Cards have a
  world transform, not a screen-space card Control or per-card SubViewport.
  Four reward cards are shown for choice; the row then shows the live hand.
  Larger hands are paged six at a time without changing model state or order.
- Five `BridgeSlot` areas preserve logical slot IDs. A selected card shows
  contribution captions; hovering a valid empty slot shows a gold wire column.
  Placement reveals a solid column, cap, short deck, and simple red railing.
  Clicking an occupied column with no card selected activates available Flair.
- `WorldPicker` centralizes event-driven ray casting. `BridgeWorld` owns the
  replaceable primitive scenery/materials and visual shake. `world_screen.gd`
  adapts input to the unchanged rules and updates the views/HUD.
- Final placement is displayed before cleanup feedback even though model
  resolution remains synchronous. Input is blocked during this visual sequence.
  After the recorded impact, the view reconciles to the already-settled state.
  Animation callbacks never resolve rules; incomplete trials do not invent a hit.
- Camera framing and card layout respond to resize events, not per-frame polling.
  Shadow casting is disabled for unlit cards/preview outlines; rendering uses
  2× MSAA. No per-card viewport render passes, plugins, or autoloads were added.
- The old 2D card/controller files were deleted. The reference is preserved but
  excluded from Godot resource import through `references/.gdignore`.

Verification:

- Native and headless world UI checks use camera-projected mouse events to test
  actual ray hits, reward choice, logical slot placement, solid-column visibility,
  Integrity/Draw Flair, paid draws, page-two access, next rounds, and the slice stop.
- Tests assert that all five columns remain visible during final feedback, the
  model is already closed, actions cannot reopen it, and feedback never mutates
  the settled state. Zero/slow feedback under 30/120 FPS caps yields identical
  complete snapshots. Picking is also exercised after resizing to 960×600.
- Native opening, ghost preview, column, bridge-in-progress, final placement,
  cleanup, boundary, and compact views are visually inspected. The 3D input
  checks run using Metal / Forward+ on Apple M5.
- Existing gameplay oracle gates remain required: 456 setup states / 1,200 RNG
  rolls; 267 single-round traces / 1,889 frames / 13 content guards; 71 multi-round
  traces / 2,571 frames. Catalog values remain byte-identical to TypeScript.
- An initial native compact-view sample reported 137 draw calls / 449 rendered
  objects after removing decorative shadow casting. This is a diagnostic
  snapshot, not an FPS benchmark or a promise for minimum hardware. Profile the
  approved representative scene before expanding assets in Step 6.

Still deferred: final art/typography/card illustrations, richer terrain,
environmental details, animals, later mechanics, and the full run. This is the
working spatial blockout to review before investing in polish.

**Action for the user:** F8 to stop an older run, then F5 (accept external scene
reload if Godot asks). Choose a foreground reward card, select a hand card, and
hover/click a numbered pad. Check that a column appears at that slot. Deselect
with Escape or by clicking the selected card again; click the occupied column
for Flair. Test Draw, paging arrows/wheel, the final placement/Forest feedback,
and Next Round. Review camera angle, card size/readability, and overall spacing
against the reference before approving Step 6. No downloads are needed.

## Revised remaining plan — gameplay first, pool by pool

User direction: 2026-11-02. This replaces the earlier art-first Step 6 and
mechanic-family expansion order. Today is documentation only. Coding resumes on
the user's next instruction, intended for tomorrow. Do not treat a desired
completion date as permission to implement everything in one pass or skip checks.
Keep each scope small, reviewable, and lean. Continue reporting **Action for you**
at every checkpoint.

All art-related changes happen at the end. Retain simple placeholder cards,
columns, terrain and animal representations throughout gameplay development.
Add only the functional UI/feedback needed for new choices, targeting, rules and
testing; defer visual redesign, final typography, illustrations, models,
materials, lighting polish, environmental details, animations and audio production.
Preserve the artist replacement contracts in `art/README.md`.

Pool membership comes from `content/data/integrity_config.json`, not filenames
or invented groupings. Each reward pool has 15 cards and 15 attacks. Pool 0 is
the four starter cards and has no attacks. Existing content and balance remain
unchanged; loading JSON is not the same as implementing every definition.

## Step 6 — Complete Pool 1 (Early) and common animals

**Status: complete, awaiting user playtest/review.**

The user authorized Pool 1 plus common animals and explicitly requested careful
reference review. Read the active README/framework, `wildlife.ts`, animal reward,
activation, choice, acquisition and cleanup paths in `engine.ts`, and the actual
JSON definitions. The live common roster is 20 sightings, not the five legacy
fixture animals. No prototype files or authored numbers were changed.

- [x] Implement every Pool 1 card: all position conditions, prior-placement
      formula, consumed next-adjacent bonus, normal Draw/Gold and supported Flair.
- [x] Implement all 15 attacks: intermediate/full-board hit milestones, penalties,
      conditional historical-contribution reductions and weather gain on survival.
- [x] Explicit common-only roster with weighted distinct offers, affinity batches,
      stable habitats and frozen/resumed Construct offers. Original full-roster
      probabilities are not claimed for this bounded scenario.
- [x] Trial acquisition, independent per-copy cooldowns, next-round readiness,
      full-capacity replace/decline and incomplete trial retries.
- [x] All 20 common effects, including targeted hand power, Bounce/conditional
      Draw, Retain/next-round power, top-of-deck selection and draw/discard sequence.
- [x] Reusable placeholder modals for animal rewards, roster, choices and capacity;
      locked action windows, optional Done/Escape, live power and hit schedule UI.
- [x] TypeScript parity: 395 traces / 22,690 frames, all 19 starter/reward card
      definitions, 15 attacks and 20 common animals. Coverage includes non-neutral
      affinities, cancellation, repeat activation rejection, replacement/decline,
      20 incomplete trial retries and exact RNG/zone/mark/offer state. Nine invalid
      wildlife fixtures reject actions without mutation.
- [x] Original 267-trace round and 71-trace slice regressions passed. Native
      pointer-driven trial → acquisition → next-round activation passed at seeds
      1 and 42; all six targeted-animal UI cases and capacity replacement passed
      through native pointer input. Existing drag/click/Flair/foundation/closure
      checks passed.

Acceptance: the requested Pool 1/common checkpoint works with placeholders.
The current build still stops at first-room completion/Pool 2 transition. Later
rarities, mechanics, room transitions and the village remain separate scopes.
See current `README.md` for supported content, controls, architecture and tests.

**Action for user:** F8 then F5. Play three successful Construct trials; choose
and survive an animal trial, then use Animals during the next playing round.
Try targeted effects/Done/Escape and cooldowns. Review before approving Pool 2.
No downloads are needed. All final art/audio remains deferred.

## Step 7 — Complete Pool 2 (Developing)

**Status: implemented; user authorized progression to Pool 3.**

- [x] All 15 cards and 15 attacks, shared Reinforce/Support/Bounce mechanics.
- [x] Functional choices, progression and bounded verification (see checkpoint).
- Exhaustive parity was deliberately deferred under the user's test cap.

## Step 8 — Complete Pool 3 (Strong)

**Status: implemented; awaiting user playtest/review.**

- [x] All 15 Pool 3 cards and 15 attacks from unchanged prototype content.
- [x] Persistent Rain, Elephant Charge/Debris, Shaky Ground and protection.
- [x] Support-all Flair, two-Bounce cards, replay-only Support and conditional Draw.
- [x] All 20 uncommon animals alongside the 20 common animals.
- [x] Functional search/recovery/protection choices and scrollable target popup.
- [x] Focused rule and native progression/UI checks within the ten-check cap.
- [ ] User playtest/review. Stop before Pool 4.

## Step 9 — Complete Pool 4 (Advanced)

**Status: implemented; awaiting user playtest/review.**

- [x] All 15 Pool 4 cards and 15 attacks; existing narrow mechanics reused.
- [x] All 20 rare animals alongside common and uncommon animals.
- [x] Shared protection, limited-hit protection, Grace, escalating placement
      bonuses, permanent Debris removal and final-progress bonuses.
- [x] Focused mechanics and native progression/UI verification within ten checks.
- [ ] User playtest/review. Stop before Pool 5.

## Step 10 — Complete Pool 5 (Late/boss)

**Status: implemented; awaiting user playtest/review.**

- [x] All 15 Pool 5 cards and 15 attacks from unchanged prototype content.
- [x] Seven-slot board, seventh-placement bonuses, left/replay Support,
      adjacent-Reinforce Draw and final Lightning Strike destruction.
- [x] All 10 very rare animals, bringing the enabled roster to 70.
- [x] Focused late-run mechanics, terminal win and native board-framing checks.
- [ ] User playtest/review.
- [x] Follow-up checkpoint: all five exceedingly rare animals enabled (see below).

## Step 11 — Playable village lobby between runs

**Status: planned; not implemented. Next large coding milestone after full-roster review.**

Added at the user's request after the pool-by-pool plan. This is a coding
milestone before final art. It does not change the next checkpoint (Pool 1).
Build in the small substeps below; do not build the whole hub in one pass.

### Context and boundaries

Nilgiri hills, India, 1881. Parth is an engineer building a railway bridge. He
returns between forest runs to a compact, reusable village hub, similar in role
to the House of Hades: walk, speak to characters, and leave for the next run.
Use primitives/basic materials and placeholder dialogue. Defer shops,
relationships, quests, minigames, cinematic sequences and final art/audio.

### 11.1 — Inspect integration and block out the village

- [ ] Inspect the project conventions, gameplay entry point, run reset owner and
      terminal-state flow as they exist at implementation time.
- [ ] Create a separate 3D village scene: ground/collision, dummy buildings,
      clear walking paths, village square, temple, construction outpost and
      forest exit. Keep the layout compact and traversable.
- [ ] Use a fixed elevated orthographic camera consistent with the bridge view;
      keep the playable area visible and camera editing simple for artists.

### 11.2 — Controllable Parth

- [ ] Reuse an existing suitable humanoid model if available; otherwise use a
      simple placeholder human figure. No new final-art dependency.
- [ ] Add reusable player movement with camera-relative WASD and a run modifier
      (Shift), plus collision against buildings, boundaries and scenery.
- [ ] Verify movement direction, speed, corners/collision and camera framing.

### 11.3 — NPCs, interaction and dialogue

- [ ] Place distinct stationary placeholder figures with visible names:
      **Kamla**, village schoolteacher; **Mahadeva**, ranger and village guard;
      **Rishi**, village priest; **Harry Cartwright**, Parth's British supervisor;
      **Keshava**, mysterious cowherd near the forest exit.
- [ ] Add reusable proximity interaction. Show `E — Talk to [Name]` near an NPC;
      resolve overlapping candidates to one clear, stable target.
- [ ] Press E to open dialogue with the speaker's name and text. Provide each
      NPC a short, distinct placeholder conversation suited to their role.
- [ ] Support advancing and closing dialogue; disable movement while talking
      and restore it on exit. Document the exact dialogue keys when implemented.
- [ ] Keep dialogue content separate from player, interaction and panel logic.
      Allow conversations to be swapped on later visits through a simple content
      contract, without building branching narrative or relationship systems now.

### 11.4 — Village/run transitions

- [ ] Make the village the normal pre-run entry scene. Preserve convenient
      direct access to the gameplay scene for development (including F6/tests).
- [ ] Add an interactable forest exit that enters the existing gameplay entry
      point and invokes its existing run initialization/reset owner. Do not
      duplicate setup logic, reseed from the hub or alter gameplay rules.
- [ ] Return Parth to the village after defeat or full-run completion through
      the existing run-ending flow. Intermediate round/room completion must not
      be mistaken for a finished run. Restore movement/interaction on return.
- [ ] Verify repeated departures and returns create fresh runs without stale
      selection, dialogue, nodes, input handlers or state leaks. Do not add
      persistent progression or save files as part of this milestone.

### Artist handoff

- [ ] Partition village layout, player, reusable NPCs, interaction and dialogue
      views into focused scenes/components, following existing conventions.
- [ ] Separate visual roots from collision and interaction so Blender/GLB models
      can replace placeholders without changing code or gameplay hit areas.
- [ ] Use clearly named village/environment, character and shared-material art
      folders. Keep sources, GLB exports and wrapper scenes organised by asset.
- [ ] Document origins, scale, facing direction, scene replacement slots and
      camera controls in the artist guide. No art polish at this stage.

### Acceptance and handoff

- [ ] Launch into the village; walk/run around dummy buildings and reach every
      landmark and all five NPCs.
- [ ] Talk to each NPC, advance/close dialogue, confirm movement is locked only
      during conversations, and verify a single target when ranges overlap.
- [ ] Enter the forest, play the existing game, return after defeat and after
      completion, and start another fresh run. Verify direct gameplay launch too.
- [ ] Report controls, changed scenes/files, full-loop verification evidence and
      remaining limitations. Stop for user review and state **Action for you**.

Done means the entire village → run → village loop is playable with placeholders,
not just a village scene preview. Earlier pool checkpoints keep their own tests;
this milestone adds hub/transition coverage without replacing rules parity tests.

## Step 12 — Full gameplay completeness and desktop behaviour

**Status: authored content implemented; desktop work and wider validation remain.**

- [x] Audit and enable all 80 card definitions (including starters/Debris),
      75 attacks and 75 animals; validate the full supported content contract.
- [x] Implement authored animal/habitat effects, reward rounds, cooldowns,
      permanent marks and capacity through the pool/rarity milestones.
- [ ] Verify all rooms, seven-slot boards, overflow, deadlines, pool transitions,
      protection/destruction, Debris and full win/loss paths against the prototype.
- [ ] Remove slice-only restrictions only when their replacement paths are ready.
- [ ] Finish functional desktop options/accessibility and resolve save/resume
      scope with the user before implementing persistence.
- [ ] Validate the full playable run and measure performance with placeholders.

Acceptance: complete gameplay code and content coverage, deterministic regression
checks and user playtest approval. No missing rule is disguised with a placeholder;
placeholders apply to presentation assets only.

## Step 13 — Art, visual UI, animation and audio (last)

**Status: deferred until gameplay coding is complete.**

- [ ] Approve one representative bridge section/card visual sample first.
- [ ] Replace placeholders with artist assets through the documented Blender/GLB
      workflow; retain editable camera and independent gameplay/picking.
- [ ] Finalise card/UI styling, typography, environments, lighting, animation
      and audio in separate small review checkpoints.
- [ ] Profile representative final assets, tune quality/performance and test
      readability, accessibility and different desktop resolutions.
- [ ] Package and test desktop builds. Steam remains deferred unless requested.

The numbered plan is an ordering guide, not authorization to batch multiple
pools together. At each pool's start, inspect its concrete definitions, propose
the smallest achievable substep, implement/check it when authorized, record
coverage and remaining work here, and stop for review.

## Pool 2 checkpoint — 2026-11-02

Implemented all 15 Pool 2 cards and 15 attacks from unchanged prototype data.
Reinforce follows each physical copy's play history. Support increases live
power and Integrity while preserving historical Added. Support/Bounce targeting
pauses placement resolution before Forest hits. Normal Bounce is optional;
Derrick's once-per-copy Flair selects exactly two targets during that choice.
Bouncing preserves earned Integrity, and full-board insertion remains latched.
Pool 2 conditional attacks, one-use slot penalties and conditional Draw are
supported. Room progression retains overflow; total progress includes prior
rooms. Pool 3 remains deliberately locked. Common animals remain unchanged.

Run F5 as usual; Pool 2 unlocks at 50 cumulative progress. WorldScreen's
`Playable Pool` inspector setting defaults to 2 (set 1 for the prior boundary).
No art assets or prototype data were changed.

Verification budget: **at most 10 checks/tests per task, including failed
attempts and retries**. Do not run exhaustive parity, seed sweeps or broad
regressions by default. This is the user's explicit speed preference.
This task used ten checks: one import/compile attempt, seven focused cases,
one corrected Bounce/replay retry and one short native Forward+ launch.
The first import exposed a typo (fixed). The seven-case run hit a guessed
attack-ID error in its fixture, so its assertions alone are not clean parity
evidence. The fixture was corrected; only Bounce/replay was rerun and passed.
Other cases remain available but were not rerun to respect the cap.

Action for user: stop/restart with F8/F5 and play into Pool 2. Test Support
selection, optional Bounce and Derrick's two-target Flair. No downloads or
asset setup are needed. Review before approving Pool 3.

## Pool 3 / uncommon animals checkpoint — 2026-11-02

Default scope is Pools 1–3 and common/uncommon wildlife, preserving the original
6:3 rarity weights among the enabled animals. Uncommon animals join the normal
habitat-trial offer pool; later rarities remain disabled. Pool 3 starts at 100
cumulative progress; Pool 4 stays locked. The village remains a later milestone.

New card behavior includes Support-all Flair, Support on already-replayed
copies, Support-triggered Draw and sequential optional Bounce selections.
`ForestEffects` owns board hazards; `RoundRules` keeps resolution ordering:
card effects → existing Rain ticks → Forest hits → newly triggered hazards.
Events resolve once at their authored occupied-slot count. Elephant Charge
uses gameplay RNG, exiles the selected copy and replaces it with occupied,
zero-contribution Debris while keeping earned Integrity. Protect prevents one
attempt without retargeting. Destroyed provisional rewards are not resurrected
on successful cleanup. Shaky Ground weakens the current hand only, clearing at
round end. Artist assets and original JSON data remain unchanged.

Uncommon-specific support includes destruction protection, persistent per-hit
Block, capped half-next-hit, per-neighbor/empty-neighbor placement bonuses,
placement-triggered Block, discard recovery, unused-Flair search, Debris discard
with Draw, and Bounce granting an exact copy a one-placement Integrity bonus.
Existing animal sequencing, cooldowns, capacity and next-round acquisition apply.
The existing modal now scrolls large search lists and identifies card zones.
Destroyed slots show the existing footprint with a Debris label rather than an
intact bridge column; final rubble art is deferred.

Verification: **10 checks total**, including the initial failed compile attempt,
six passing focused mechanic scenarios, two native smoke attempts and a final
passing destroyed-provisional-reward cleanup scenario. No exhaustive parity,
seed sweeps or broad regressions were run. The first accelerated native smoke
emitted renderer material warnings; repeating with normal frame spacing passed
without those warnings. The native flow entered Pool 3 at 100 progress and
rendered its attack HUD and uncommon search popup. Not every card/animal
combination was individually simulated.

Changed gameplay files: `scenarios/pool_three.gd`, `gameplay/forest_effects.gd`,
`gameplay/round_rules.gd`, `gameplay/animal_rules.gd`, `gameplay/run_state.gd`,
`gameplay/card_instance.gd`, `gameplay/placed_construct.gd`, and the two rule
validators. Functional presentation changes are confined to WorldScreen,
BridgeSlot and RewardPopup. Focused verification lives in
`tests/check_pool_three.gd` and `tests/smoke_pool_three.gd`.

Action for user: restart with F8/F5. Play through 100 total progress into Pool 3;
watch the attack schedule for Rain, Charge and Shaky Ground. Uncommon animals
can appear in ordinary animal trials. Use the Animals button for their effects;
scroll search choices when necessary. No downloads or asset preparation needed.
Stop for review before Pool 4 / rare animals.

## Pool 4 / rare animals checkpoint — 2026-11-02

Default scope is Pools 1–4 and common/uncommon/rare wildlife: 60 reward cards,
60 Forest attacks and 60 animals. Pool 4 begins at 150 cumulative progress;
Pool 5 remains locked. Enabled animal rarities preserve prototype weights
6:3:1. Very rare/exceedingly rare animals, the village and final art remain later
work. No prototype JSON or artist assets were modified.

Pool 4 cards reuse Reinforce, positional contributions, Support, Support-all
Flair, optional sequential Bounce, Draw and Gold. Attacks reuse ordered hits,
Rain, Charge/Debris and Shaky Ground. No pool-specific resolver was introduced.
Rare effects extend the existing AnimalRules/RoundRules owners:

- Escalating bonuses apply +2, +4, +6... until round end; adjacency bonuses use
  the pre-placement board. Exact-copy next-placement bonuses leave power alone.
- Shared protection is consumed after half-hit/per-hit reductions, carrying its
  unused amount between hits. Counted per-hit wards consume one charge per hit.
- Grace is consumed only on an otherwise lethal hit and sets remaining Integrity
  to its authored value, including impact presentation metadata.
- Debris removal targets hand/discard and exiles that exact copy permanently,
  removing ownership without creating replacement Debris.
- Final-progress percentages add together and round upward. Full-board-only
  bonuses check the board before cleanup. Room Gold uses original remaining
  Integrity, not boosted Progress. Round-only protection/progress resets normally.
- Rare search/retain/look/Bounce effects use the existing scrollable choice UI.

Verification: **8 checks total**: one clean import/compile, six passing focused
scenarios and one clean native Forward+ smoke. Scenarios covered escalation,
shared/counted protection against Three Hammers, lethal-hit Grace, stacked
progress rounding/Gold payout, permanent Debris removal and exact-copy
search/retention bonuses. The native flow entered Pool 4 at 150 progress and
opened a rare-animal Debris removal popup. No exhaustive parity, seed sweep or
broad regression suites were run; not every individual combination was tested.

Changed files: `scenarios/pool_four.gd`, `content/common_wildlife.gd`,
`gameplay/animal_rules.gd`, `gameplay/round_rules.gd`, `gameplay/run_state.gd`,
`presentation/world/world_screen.gd`, and these docs. Focused checks are in
`tests/check_pool_four.gd` and `tests/smoke_pool_four.gd`. All visuals continue
using the existing replaceable placeholders.

Action for user: F8 then F5 to restart. Play into 150 total progress and try the
rare animals through the Animals menu. They can appear in ordinary habitat
trials alongside earlier rarities. No downloads or asset setup required.
Review before approving Pool 5 / the remaining animal rarities.

## Pool 5 / very rare animals checkpoint — 2026-11-02

Default scope now includes all five reward pools: 75 cards and 75 attacks.
Pool 5 begins at 200 cumulative progress and uses seven slots, as in webtest.
All 10 very rare animals join the existing 60 animals. Enabled-rarity weights
remain 6:3:1:0.25. The five exceedingly rare animals remain disabled; they are
the next separate checkpoint before the village. Final artwork stays deferred.

Pool 5 implements seventh-placement positional/Support bonuses, immediate-left
Support, replay-dependent Support and adjacent-Reinforce Draw. The final storm
resolves four hits and two Lightning Strike attempts; destruction uses the same
seeded/exile/Debris/protection path as Charge, with its own two-strike cap.
Normal win flow now works through the seven-slot final pool.

Very rare mechanics include queued and exact-copy placement multipliers,
neighbor-condition override on the next placement, searches restricted to
separate card definitions, uncapped half-next-hit, and Grace that draws cards
or queues a placement bonus when triggered. Multipliers apply after additive
bonuses and before slot/placement penalties; power remains separate from
contribution. Temporary copy modifiers are consumed on placement. Existing
optional recovery and sequences support the remaining very rare animals.

BridgeWorld adapts to five/seven slots at round entry, retaining the artist's
column scene, foundation-height datum and straight 5.2-unit module spacing.
Bank stubs/placeholder banks move to the current ends. The orthographic camera
widens only as needed; it returns to its authored width for five slots. The
inspector exposes `Fit Board To Camera` and `Board Overscan`, preserving direct
camera position/rotation/size editing for artists. Backdrop overscan follows the
updated camera width. Existing foundation artwork covers all seven feet.

Verification: **9 checks total**: one clean import/compile, seven passing focused
scenarios and one clean native Forward+ smoke. Scenarios covered seventh-play
bonuses, multiplier/penalty timing, neighbor override, distinct-definition
search, Grace follow-ups/halving, the final storm and win flow, and adjacent
Draw/left/replay Support. Native verification entered Pool 5 at 200 progress,
confirmed seven visual slots and projected deck edges within the camera width,
and opened a very rare search popup. No exhaustive parity, seed sweep or broad
regression suites were run; this is not evidence of every possible combination.

Changed files: `scenarios/pool_five.gd`, the existing wildlife/card validators,
CardInstance, AnimalRules, RoundRules, ForestEffects, BridgeWorld and WorldScreen.
Verification: `tests/check_pool_five.gd`, `tests/smoke_pool_five.gd`. Prototype
JSON and artist art files were not modified.

Action for user: F8 then F5. Play into 200 total progress and test the seven-slot
bridge and very rare animals through the Animals menu. The final storm is now
playable through victory. No downloads or asset preparation required. Review
before approving the exceedingly rare animal checkpoint.

## Full roster and gameplay follow-up — 2026-11-02

All five exceedingly rare animals are enabled through `FullRun.create_catalog`:
Nilgiri Marten, Nilgiri Marten Pair, Rusty-spotted Cat, Ghost of the Nilgiris —
Black Panther, and Rani with Her Cubs. The default game uses all original
wildlife definitions and weights (6:3:1:0.25:0.05), without filtering. Earlier
pool scenarios remain available for development. No prototype JSON or artist
assets were changed.

Marten/search, two-copy multipliers and Rusty's ordered Bounce/Search/Gold reuse
existing effects. Panther adds a once-per-run 1.5 permanent Integrity multiplier
to the selected physical copy; it survives placement, Bounce, discard, reshuffle
and round cleanup while leaving power separate. Its field is copied by both
CardInstance and PlacedConstruct. Rani adds round-long destruction prevention
plus Grace 1. Destruction still chooses its seeded target before prevention,
consuming the original RNG roll, and does not retarget. Protection expires at
round cleanup; Panther's mark does not.

Small remaining gameplay gaps completed in this pass:

- Special Debris is included in rule validation. Reinforce, replay amounts and
  nested placement Support bonuses reject invalid parameters.
- Direct placement and final Support/Bounce target resolution now share the
  same presentation-only end-feedback path. Done/Escape use that path too;
  the modal stays hidden during settling. Model rules never wait on animation.
- Feedback uses cumulative Progress across cleared rooms, avoiding a temporary
  HUD drop to room-local Progress during late-run hits.
- Victory explicitly says the bridge is complete and offers New run. Restart
  wording no longer calls the full game a slice. Hand details expose permanent
  and next-placement multipliers.

Verification: **9 checks total**: one clean import/compile, six passing focused
cases and two passing native lifecycle checks (the second followed the
cumulative-progress display fix). The cases cover all five final animals and
the 80-card / 75-attack / 75-animal content contract. The native lifecycle opens
a Panther target popup, resolves a final Support choice into feedback/victory,
then starts a fresh run with cleared animal state and a five-slot board. The
second native check confirms 200 cumulative Progress remains displayed while
the final-room feedback plays. No exhaustive parity or broad suites ran.

Changed: new `scenarios/full_run.gd`; CardInstance/PlacedConstruct, RunState,
AnimalRules, RoundRules, ForestEffects, content validators, WorldScreen and docs.
Checks: `tests/check_final_animals.gd`, `tests/smoke_full_roster.gd`.

Remaining coding is explicit: the village scene/player/NPC/dialogue/transition
milestone has not been built; desktop options/accessibility, a save/resume scope
decision before persistence, and representative full-run performance/validation
remain in Step 12. Content completion does not mark those tasks complete. Final
art/UI styling/audio and desktop packaging stay later; Steam remains deferred.

Action for user: restart with F8/F5 and play the full roster. All animals use
normal habitat trials and the Animals menu; the last rarity is deliberately
very uncommon at the unchanged prototype weight. No downloads or artist asset
preparation are needed. Review before the village's first layout substep.

## Gold correction — 2026-11-03 (supersedes earlier payout notes)

User direction: every round awards `(total Integrity added − Forest damage) / 5`
Gold. Implemented as `floor(net remaining Integrity / 5)` at round completion,
before resetting Integrity or applying Progress multipliers, with zero minimum.
This applies to ordinary rounds, animal rounds and incomplete trials. A hit
that defeats the player does not reach round completion. Deadline processing
continues after the completed-round payout. Card/Flair/animal Gold is unchanged.

Removed the former room-clear `/ 2` payout and its unused room payout ledger;
overflow through multiple rooms and entering the next round never pay again.
`round_result.goldPayout` is always set, including zero, and the round-end prompt
shows it. This intentionally overrides the prototype and all earlier room-payout
claims in this document. Updated the snapshot helper and the prior Pool 4 payout
expectation to reflect the new rule; old prototype-parity Gold expectations are
no longer the authority for this user-directed change.

Verification: four checks total: three passing focused cases (ordinary round
95−68=27 → 5 Gold, room overflow with boosted Progress, incomplete round with
fraction rounded down), plus a short native launch. No broad suites were run.

Action for user: F8/F5 to restart and test the new economy. No setup required.

## Minimal instrument HUD — 2026-11-03

Authorized visual follow-up, separate from the deferred village/art milestones.
User confirmed a **whole-run ruler**, derived from all room targets (currently
250), rather than a resetting per-room scale. Gameplay definitions, actions,
RNG, triggers, costs and Gold rules were not modified.

Removed the full-width header/footer, gameplay title, opaque status/inspection
panels, permanent Restart button, empty-slot wording and repeated base-value
card copy. The HUD now uses slim brass/ivory line work, small local backings,
outlined text and empty space. Mandatory reward/target choices remain modal,
with an ivory local panel and responsive scrolling instead of a large dark slab.

Reusable controls in `presentation/instruments/` provide:

- Whole-run calibrated ruler, unit/5/25 ticks and labelled target. Minor ticks
  thin at smaller physical pixel spacing; exact pointer value stays visible.
- Uncapped shared-Integrity readout, mechanical pulse and signed gain/damage
  indicators. A short visual transfer animates surviving Integrity into the
  Progress ruler. These tweens never resolve or modify gameplay.
- Forest checkpoint strip built from actual hit/effect timing, with dots for
  zero, numbers for damage and symbols for Rain, Shaky Ground, Charge and
  Lightning. Current and resolved checkpoints differ visually. Slot penalties
  have compact separate badges. Hover/focus explains every effect in plain text.
- Compact clock/round, coin/Gold, priced extra Draw, owned animal abilities and
  cooldowns, hand paging and pile counts. No capacity button when there are no
  animals. Animal clicks use the existing activation/targeting rules.
- Contextual world hover and fading notifications. Esc/Ⅱ opens a pausing menu
  with Resume, fullscreen toggle and New run. Restart closes the menu and uses
  the existing run initialization owner. Optional targeting/selection cancellation
  takes precedence over opening Pause.

WorldScreen still owns input-to-rule actions; InstrumentHud owns presentation
and menu state. Existing column art, floor alignment, camera and backdrop
systems remain separate. CardText edits presentation copy only. The HUD scene
is lean; `_layout` / `_theme` are the single layout/palette tuning locations.

Verification budget: **10 checks**, including one import/compile, six focused
native cases, visual review of the two captured resolutions, and one final
responsive-layout recheck. Native cases exercised actual pointer hover/drag,
correct slot placement, compact animal targeting, pause/resume, Integrity deltas,
Progress transfer, effect tooltips via keyboard focus, and 1920×1080/1280×720
layouts. The visual review corrected small-window header placement and removed
unnecessary decimal damage/boxed checkpoint styling. The final layout recheck
passed. Small public-facing tooltip/notification refinements followed by code
inspection only; no broad gameplay or parity suite was run.

Review captures: `references/hud-instruments-wide.png` and
`references/hud-instruments-small.png`. Focused native check:
`tests/check_instrument_hud.gd`. Earlier native tests tied to the retired HUD's
node paths/layout require updating before reusing those historical UI suites;
the gameplay checks remain separate. Village and save/resume scope are still
unimplemented; fullscreen is an in-session control only.

Action for user: F8/F5. Test the ruler, card drag/drop, ability icons and Esc/Ⅱ.
No downloads, asset replacement or manual project configuration are required.

## Gold-diamond reference / automatic advancement — 2026-11-03

New user direction supersedes earlier manual Next round/Next room controls.
HUD composition now follows `references/hud-gold-diamonds-reference.png`:
round dark Integrity face with brass rim, framed calibrated Progress instrument,
clock/Gold housings at upper right, settings gear and diamond attack checkpoints.
Zero-damage checkpoints are small hollow gold diamonds; damage/effects occupy
larger diamonds and retain focus/hover explanations. Current/resolved indicators
remain. Typography and texture are procedural placeholders; final card artwork
was not part of this pass. There are no full-width header/footer bars.

Automatic transition sequence:

1. RoundRules settles the placement and all required effect choices.
2. The existing visual Forest feedback starts; a short rain plays concurrently
   for a completed round. Input stays locked during this presentation.
3. Surviving Integrity transfers visually to the whole-run Progress ruler.
4. WorldScreen calls the existing `RoundRules.start_next_round()` automatically,
   including room overflow. A mandatory capacity decision delays this call;
   replacement/decline resumes it without replaying rain or paying Gold again.
5. Victory/loss stay terminal. Restricted development pools preserve their
   intentional content boundary rather than bypassing the rule guard.

The Next round/Next room button and its signal were removed. No per-frame model
polling, new run-reset owner, rules RNG call or second progression implementation
was introduced. Rain is a lightweight, renderer-independent CanvasItem streak
pass with no input surface; it redraws only during its short tween. Main's
`Round Rain Duration` export defaults to 0.65 seconds. Card/floor/camera asset
replacement remains unchanged.

Verification: **10 checks total**: import/compile, six passing native scenarios,
visual review of wide and small captures, and a final passing Support-choice
transition scenario. Coverage includes ordinary automatic advancement, single
Gold payout, overflow into the next room, capacity replacement/decline gating,
terminal win/loss, actual hover/drag placement and 1920×1080 / 1280×720 layouts.
The final scenario confirms a full-board Support target must resolve before rain
and then advances exactly once, preserving 36 Progress and 7 earned Gold.
No broad parity suites were run.

New reusable components: `brass_trim.gd`, `brass_panel.gd`,
`diamond_checkpoint.gd`, `round_rain.gd` under `presentation/instruments/`.
Updated ruler/readout/sequence/HUD/symbol controls and WorldScreen orchestration.
Focused verification: `tests/check_auto_round_hud.gd`; review images:
`references/hud-gold-diamonds-wide.png` and `hud-gold-diamonds-small.png`.
The older instrument-layout assertion was adjusted to the new dial-first layout.

Action for user: F8/F5. Play a round; rain now takes you directly to the next
reward popup. Resolve animal replacement only when capacity requires it.
Esc / gear accesses Pause, fullscreen and New run. No downloads or art import
steps are needed. Village and save/resume remain separate pending milestones.

## Full-hand overlapping fan — 2026-11-03

User direction supersedes the earlier six-card rack/pagination presentation.
Every card in `RunState.hand` now has a visible 3D view in one fan, up to the
existing 12-card rules cap. Required modals may overlay the hand but no page or
six-card display limit exists. Pager controls, page state and wheel-to-page
signals were removed from the HUD, WorldScreen and WorldPicker.

BridgeWorld grows/reuses card views as needed and lays them out along an arc,
with opposite end rotations, overlapping spacing and deterministic depth order.
The hand scales against camera width so five/seven-slot framing and window
resizing preserve legible card sizes. All resting corners remain in view.
WorldCard raises, brings forward, slightly enlarges and straightens the hovered
or selected face. Compact copy uses smaller body typography to avoid crowding
its Integrity line. Notifications are dismissed when reading a hovered card.
WorldPicker checks resting fan polygons in depth order, then the raised face's
extra extent and existing world ray picking; gameplay is never polled per frame.
Drag/cancel/slot input still uses the original rule action owner.

Verification: **10 checks total**, including the initial compile, four focused
native cases, visual reviews, a focused hover retry and final hover/small-window
cases. Full-hand layout, accessibility of all twelve exposed copies, drag cancel,
exact-copy drag placement and 1280×720 seven-slot framing were exercised.
The initial combined run had hover assertions fail; the isolated retry passed.
Final hover verification synchronized the native pointer with injected events
and passed. Initial smaller twelve-card framing passed. The final small-window
case verified all corners in bounds but failed its count assertion because its
fixture injected a thirteenth card when run without the earlier drag. That test
fixture/count expectation was corrected; it was not rerun to honor the cap.
No broad gameplay or parity suite was run.

Changed: BridgeWorld, WorldCard, WorldPicker, WorldScreen and InstrumentHud.
Focused check: `tests/check_hand_fan.gd`. Captures:
`references/hand-fan-hover.png` and `references/hand-fan-small.png`.
Existing artist scenes/materials remain reusable; fan settings are exposed on
World. Earlier rack-specific UI tests need their obsolete six-view/page assertions
updated before reuse; gameplay-model tests remain independent.

Action for user: F8/F5. Draw more cards and move across the exposed fan strips;
hover lifts a card for reading and it can be dragged to a slot. No setup needed.

## Round-by-round forest shuffle — completed

Backdrop composition now includes the global round number in its visual seed.
Each new round picks four distinct terrain chunks without replacement and assigns
them to the existing A–D depth positions. Ordinary renders retain the arrangement;
the same run seed, room and round reproduce it. Gameplay RNG is untouched.
Artist asset wrappers, atmosphere and editable layer settings are unchanged.

Verification: three focused headless checks passed: repeated renders preserve
configuration/node instances, the next round in the same room changes selection
with four distinct variants, and restoring the same round reproduces its layout.
Godot's dummy renderer emitted a null-material warning at scene teardown.
No broad suite or visual seed sweep was run.

Action for user: F8 then F5; complete a round to see a fresh arrangement.

## MH Construction removed — 2026-11-03

Removed the experimental alternate rules, costs, tests, captures, mode chooser,
MH/stack HUD and run-state fields. Direct original-mode startup and Pause → New
run are restored. Removed the alternate-mode extension hooks from shared rules.
The full-hand fan, card hover lift without tooltip, drag/drop, round rain/automatic
advancement, corrected Gold payout and per-round terrain shuffle remain.

Action for user: F8 → F5. No mode selection or setup is required.

Removal verification: editor compilation, three focused Gold/round-transition
cases and one native launch/drag/no-tooltip/restart smoke check passed. No broad
suite was run. A source-reference scan found no remaining MH runtime references.

## Designer starter deck and Pool 1 revision — 2026-11-05

Implemented all four starter definitions (still three copies each) and all 15
redesigned Pool 1 rewards. Original internal IDs stay stable despite renamed
cards. The TypeScript prototype and later-pool definitions are unchanged.

New reusable mechanics: per-copy permanent additive Integrity upgrades; random
hand-power borrowing with round-only zero placement contribution; neighbour-count
Draw Flair; discard-then-draw choice; newest-discard recovery; consecutive
adjacent-placement chains; one-shot next-Forest-hit damage; permanent next-adjacent
upgrades. Card copy/cleanup paths preserve permanent upgrades and reset temporary
zero/chain/damage state. New Flair descriptions use existing card and choice UI.

Confirmed interpretations: Layered Support counts uninterrupted adjacent links,
including its own; Steel Girder borrows current hand Integrity while the chosen
copy keeps its other abilities; Hefty Pier adds only +4 total to the next hit.
“Turn” means the existing round. Closing Keystone also recognizes final-hand
placement. Full policies and readable card list: `content/POOL-1-REDESIGN.md`.

Pool 1 base scheduled attack totals now span 20–28. Only damage amounts changed;
stages, conditions, penalties and weather schedules are preserved. Reductions or
Hefty can produce actual damage outside that base range. Distant Thunder and
Sheltered Crossing increase from 26 to 28; existing 20/22/24 totals stay intact;
all lower totals increase to 20.

Verification: ten bounded cases/reviews including the corrected Hefty test
fixture. Focused mechanics and native UI checks passed; wide/small card text was
reviewed. A final small resolved-checkpoint history display fix was not rerun to
honor the cap. No broad suite or balance sweep. Old Pool 1/prototype parity
fixtures require refreshed expectations for this intentional redesign.

Action for user: F8 → F5 starts a fresh deck with the new definitions. Click an
occupied column (with no hand card selected) to use its Flair. Lone Pier opens
the discard popup. No new installation or artist asset changes are required.

## Permanent Classic market and placement Gold — 2026-11-06

Four compact left-edge offers replace the free Construct trial pick. Offers have
recorded fixed prices, hover/focus preview, optional artist thumbnail mappings
and independent single-slot refill. Any number of affordable purchases is allowed
between placements. One charge creates one owned/live copy immediately, to hand
or discard if full; stale offer IDs cannot charge/grant twice. Prices never show
on owned cards. Wallet remains shared with paid draws (1/3/5/7…).

Starter deck is five copies of four definitions (20), with a seven-card opening
hand. Starter Timber Mount is 2 Integrity/+3 Gold. Pool 1 Integrity mechanics stay
unchanged; all starter/Pool 1 Flair is removed. Placement Gold and prices are
explicit per card. Each physical copy's placement bounty pays once per round,
preventing Bounce/reshuffle farming. Later pools keep mechanics/Flair and receive
provisional data prices for their upcoming balance passes.

User overrides: no end-of-round payout and no separate room-clear payout; the
wallet is set to 0 immediately when any round ends, including defeat. Gold earned
on the final placement expires before it can be spent. Starting Gold stays 3 on
a fresh run. Offers carry between rounds, refreshing all four only at a pool
transition. Habitats are sampled per Construct round so animal progression stays
independent of buying; animal/target/capacity popups remain.

Current complete balance table, policies and artist handoff:
`content/CLASSIC-MARKET.md`. Core: ConstructOffers, RoundRules, CardZones,
RunSetup/RunState; UI: MarketStrip/MarketArt, InstrumentHud, WorldScreen, WorldCard.
Editable Market node lives in `presentation/world/hud.tscn`.

Verification: ten bounded checks/reviews including retries. Five rule cases and
functional native checks passed. Initial visual review found tile overflow;
the first recheck exposed preview attachment while the parent was setting up,
fixed with deferred attachment. Final recheck passed functional/attachment checks
but still failed price/art containment. Tile internals were replaced afterward
with fixed art/name/price regions; this final geometry change was not rerun to
honor the cap. Captures `references/market-*.png` precede that last adjustment.
Focused scripts: `tests/check_market.gd`, `tests/check_market_ui.gd`. No broad suite
or balance simulation. Earlier free-reward/payout/setup fixtures are superseded.

Action for user: F8 → F5. Inspect four compact tiles and their prices; place a
Gold-paying card, buy, and watch only its offer refill. Spend before the last
placement: the next round always starts with 0 Gold. No setup or art work needed.

## Gold carry restored and corner card values — 2026-11-06

User reversed round expiry: unspent Gold now carries across rounds and rooms,
including Gold earned by the final placement. There is still no round/room payout.
Confirmed: fresh runs start with 3 Gold; no wallet carry between separate runs.
Removed the defeat-snapshot wallet wipe too. Bounce's once-per-copy-per-round
placement bounty guard remains. Notifications and current market guide updated.

WorldCard now uses boxed I/value at bottom left and G/value at bottom right,
matching the supplied sketch. Non-earners show G 0; bounced copies already paid
show G 0 and a status above the badges. Title remains at top, effects central,
copy details above the corner boxes. Acquisition prices stay hidden on owned
cards. Market previews use matching bottom-left/right values, with price near
its title. Badge meshes/text remain separate from imported artist backing.

Verification: three focused checks/reviews passed: wallet carry/Bounce rule case,
native market/card/automatic-round/restart case, wide/small visual review.
Native check also confirms the previous market tile art/price containment fix.
Captures: `references/card-corner-values-wide.png` and
`references/card-corner-values-small.png`. No broad suite or balance simulation.

Action for user: F8 → F5. Gold persists next round; New run restores 3 Gold.
Hover cards to inspect the new bottom-corner readouts. No setup needed.

## Single circular meter and top-row full market — 2026-11-06

Removed the long ruler, obsolete ProgressRuler script and cross-widget transfer
animation. IntegrityReadout now animates a clockwise arc/outer needle for built
whole-run Progress + live round Integrity, against the actual room-summed target.
Forest damage moves it anticlockwise. Small ROUND text shows the exact survival
pool in the same dial. Round cleanup reconciles to committed Progress without
emptying the meter or double-counting. Model rules and Gold carry are unchanged.

Market is now an editable HBoxContainer with four small full-card faces centred
across the former ruler region. Names, placeholder/imported art, effects, I/G and
prices are visible; the enlarged focus/hover preview opens below the row. Long
Enhanced names wrap explicitly. Resize scales the shared card face and keeps it
above the bridge/hand. Purchases and drag locking use the existing owners/signals.
Artist texture assignments and camera remain unchanged.

Verification: eight bounded cases/reviews, including refinements. Two native
cases initially and after text-fit changes; one final layout-only case; three
visual reviews. Direction, settlement, actual Forest resolution/round advance,
Gold preservation, row layout, purchase/refill and drag preview dismissal passed.
Wide/small captures: `references/single-dial-market-*.png`.
Focused check: `tests/check_single_dial.gd`. No broad suite was run. Historical
ruler-specific tests retain obsolete assertions and are not current UI checks.

Action for user: F8 → F5. The top cards are the same priced market; click to buy.
The dial advances on gains and retreats on damage; ROUND is the current pool.

## Pool 1 Gold/price tuning — 2026-11-06

Applied the designer's 15-row Gold/price table to numbered cards 1–15.
Integrity, abilities, starter cards and later pools are unchanged. Market offer
prices are captured at creation; restart the run to load fresh offers/prices.
Updated the current balance table in content/CLASSIC-MARKET.md.
One bounded data comparison passed; no gameplay suite was run.

Action for user: F8 → F5 to load the revised data and fresh market prices.

## Pool 2 designer revision — 2026-11-06

Applied all 15 rows (cards 16–30), replacing previous Integrity, Gold, prices and
abilities with the supplied table. Removed unlisted Flair, Reinforce/formulas,
conditional Draw and draw-on-Bounce. Shared Foundation is now Reinforce 3;
Seasoned Assembly supports left by 4; Training Scaffold supports one other
occupied edge Construct by 6 through reusable edge targeting. Placement Gold
uses the existing once-per-copy-per-round guard. Market prices remain hidden
on owned cards. Starters, other pools and Forest attacks are unchanged.

Current readable table and changes: `content/POOL-2-REVISION.md`.
Verification: three bounded checks—exact data/scope comparison plus two focused
rule cases—passed. No broad suite. Older Pool 2/prototype parity expectations
encode superseded designs and were not run.

Action for user: F8 → F5. Pool 2 offers use the new definitions/prices when reached.

## Pool 3 designer revision — 2026-11-06

Applied all 15 rows (31–45) exactly: updated base Integrity, placement Gold and
individual market prices. Existing listed effects and Flair remain. Fresh
Supplies' old separate Gold effect is removed: it now pays 5 once-per-copy Gold
on placement, plus its unchanged Draw 2. Other pools, starters and Forest attacks
are unchanged. Readable table: `content/POOL-3-REVISION.md`.

Verification: two focused checks passed—exact data/scope comparison and one
runtime check for Fresh Supplies' single payout/replay guard, Draw 2, Heavy
Girder's retained Flair and Reinforce using the updated base. No broad suite.

Action for user: F8 → F5 reloads definitions; fresh Pool 3 offers use new prices.

## Pool 4 designer revision — 2026-11-06

Completed cards 46–60: revised Integrity/Gold/prices, conditional placement Gold, Reinforce adjacency, Support-sensitive closure, bounced-target Support and Bounce immunity for Construct/animal abilities. See [Pool 4 revision](content/POOL-4-REVISION.md). Pool 5 remains for its own balance pass. Artist assets unchanged.

## Pool 5 designer revision — 2026-11-06

Completed cards 61–75: revised Integrity, placement Gold, individual prices, prior-Support bonus and Bounce immunity. Existing seventh-placement and per-return Draw rules retained and checked. All five card pools now use the designer balance tables. See [Pool 5 revision](content/POOL-5-REVISION.md). Four focused checks passed. Action: F8 → F5.

## Minimal Construct card presentation — 2026-11-06

Applied the supplied Iron Spike layout to world hand cards, four market offers and inspection previews: ivory, fine brass border, simple line illustrations, blue Integrity and brass Gold circles with bridge/coin icons. Kept live values/effects, prices only on offers, fan and drag behaviour. Shared SVG assets and artist illustration overrides documented in [art/cards/README.md](art/cards/README.md). Placeholder drawings remain generic until artist replacement. Checked wide/small layouts, long text, purchase and drag placement within ten checks. Action: F8 → F5.

## Pool 1 attack damage rollback — 2026-11-06

Restored all 15 Pool 1 attacks to original web prototype damage (base scheduled totals 13–26). Only hit damage values changed; timing, other attack fields, later pools and card balance preserved. One focused data/scope check passed. Action: F8 → F5.

## Wallet and round counter placement — 2026-11-06

Gold is now a prominent right-side readout (48/58-point number) above the Forest attack display, with a scalable coin icon. Round/deadline moved directly below the Integrity dial. Checked layout at wide and small window sizes; wallet, threat and pause controls do not overlap. Gameplay unchanged. Action: F8 → F5.

## Market purchase-price frames — 2026-11-06

Added individual outer frames and high-contrast footer prices to the four market offers and inspection previews. Removed purchase prices from inside the card face; owned cards remain price-free. Verified wide/small layouts plus purchase and drag placement. Action: F8 → F5.
