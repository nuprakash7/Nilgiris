# Classic: permanent four-card market

The starter deck and Pools 1–5 now use the designer revisions. This guide contains the starter/Pool 1 table; see [POOL-2-REVISION.md](POOL-2-REVISION.md) for cards 16–30. See [POOL-3-REVISION.md](POOL-3-REVISION.md) for cards 31–45. See [POOL-4-REVISION.md](POOL-4-REVISION.md) for cards 46–60. See [POOL-5-REVISION.md](POOL-5-REVISION.md) for cards 61–75. All five pools now use the designer revisions.

## Play loop

- Start directly on the bridge, with 20 starter cards (five of each), seven in the opening hand and the existing 3 starting Gold. Later rounds still draw five, with a 12-card hand cap.
- Four small full-card offers remain visible across the top, replacing the old horizontal Progress ruler. Hover or keyboard-focus a tile for a temporary full-card preview, including unaffordable offers. Click to buy.
- Successful placement pays the card’s explicit `placementGold`. Playing a card does not charge its market price.
- A purchased copy is owned immediately and enters the hand if space exists, otherwise discard. Its price is not displayed on the owned card. Market purchases never trigger Forest attacks or depend on surviving a trial.
- Buying refills only that offer with a new ID/card from the current pool. The other three stay put. There is no per-round purchase limit. Prices are recorded on offers and stay fixed until replacement.
- Offers remain across rounds and animal trials. A progress-based change of active pool replaces all four offers with that pool’s cards.
- Paid draws use the same wallet and still cost 1, 3, 5, 7… each round.
- **There is no end-of-round or room-clear Gold payout. Unspent Gold carries between rounds and rooms.** Fresh runs (including Restart after victory/defeat) start with 3 Gold; the wallet is not permanent across runs.
- Gold from the final placement is retained for spending next round. Buying now versus saving is optional.

## First-pass balance

All starter, Pool 1 and Pool 2 Flair is removed. Pool 1 base Integrity, positional/formula bonuses, permanent adjacent upgrade and next-hit drawback are preserved. Staging Deck’s old Gold effect is represented only by the new placement-Gold field, so it does not pay twice. Only starter Timber Mount changes base Integrity, from 4 to 2, making it the clear labour-to-wallet tradeoff.

### Starter deck

| Card (5 copies each) | Integrity | Gold on placement | Market price | Effect / change |
|---|---:|---:|---|---|
| Timber Mount | 2 | 3 | Not sold | Reduced from 4 Integrity to 2; Gold-focused. No Flair. |
| Iron Spike | 5 | 0 | Not sold | Draw Flair removed. |
| Span Support | 3 | 1 | Not sold | +3 in the middle slot. No Flair. |
| Even Bearing | 4 | 1 | Not sold | +2 in an even-numbered slot. No Flair. |

### Pool 1

| Card | Integrity | Gold on placement | Price | Effect / drawback (no Flair) |
|---|---:|---:|---:|---|
| Enhanced Timber Mount | 4 | 3 | 6 | Straightforward Gold-focused upgrade. Permanent Flair removed. |
| Enhanced Iron Spike | 5 | 1 | 3 | Affordable general-purpose card; Draw Flair removed. |
| Stone Footing | 6 | 1 | 4 | Unconditional Integrity. |
| Steel Girder | 7 | 1 | 5 | Unconditional Integrity; borrowing Flair removed. |
| Left Brace | 4 | 2 | 4 | +2 if the left neighbour is occupied. |
| Right Brace | 4 | 2 | 4 | +2 if the right neighbour is occupied. |
| Cross Tie | 5 | 1 | 5 | +1 per occupied neighbour; Draw Flair removed. |
| Lone Pier | 4 | 2 | 5 | +3 with no occupied neighbours; discard/Draw Flair removed. |
| First Footing | 5 | 1 | 6 | +3 when placed first this round. |
| Hefty Pier | 10 | 2 | 7 | Next Forest hit this round gains +4 total damage, even in the best placement order. |
| Closing Keystone | 4 | 1 | 6 | +4 on the round’s final placement; its placement Gold is zero. |
| Layered Support | 4 | 1 | 7 | +2 per consecutive adjacent-placement link, including this placement. |
| Guide Beam | 4 | 1 | 7 | The next adjacent Construct permanently gains +1 on its own copy. |
| Staging Deck | 5 | 2 | 6 | Only the explicit 2 placement Gold; old 3-Gold effect removed. |
| Edge Clasps | 4 | 1 | 6 | +3 in an edge slot; discard recovery Flair removed. |

These are tuning values for the first playable pass. High Gold generally accompanies lower Integrity; Hefty Pier is the deliberate strong-at-both exception, with a +4 next-hit drawback that still fires when placed last. Every Pool 1 purchase costs more than its immediate placement Gold. Starter cards are not market offers.

No Gold advantage is canceled by a round/room payout because those payouts have now been removed. Gold earners also keep their payment on the round-ending placement; the earlier wallet-reset instruction has been reversed.

## Replay and encounter policy

A physical copy pays `placementGold` at most once per construction round. Invalid plays pay nothing. Bounce, replay, discard and reshuffle do not reset that allowance. A second, separately purchased copy can pay its own bounty. Eligibility resets for the next round. A returned copy shows G 0 and a “GOLD PAID THIS ROUND” status because replaying it does not pay twice. Pools 2–5 now use the same placement-Gold field and replay guard as Pool 1. Pool 3 retains its listed Flair. Pool 4 adds conditional placement Gold and retains its listed Flair; see its revision guide. Pool 5 also retains its listed Flair and uses the revised placement Gold.

Animal encounter cadence is preserved independently of buying. Each Construct round receives a round habitat; surviving three completes the usual habitat batch and opens the existing animal trial/choice. Saving Gold or buying multiple cards neither prevents nor accelerates animal encounters. Animal selection, ability targeting and capacity decisions still use their existing popups; the free **Construct** reward popup is removed.

## Data and artist handoff

- `content/data/integrity_cards.json`: `baseIntegrity`, `placementGold`, `purchasePrice`, normal effects and selected later-pool Flair. Starter entries intentionally have no acquisition price.
- All marketable cards have explicit prices. Pools 2–5 have individually assigned prices from their revision tables. Debris has a nominal price but is never offered by the market.
- `content/data/integrity_config.json`: starter copy counts, `openingHandSize`, starting Gold, hand limit and paid-draw settings.
- `presentation/world/hud.tscn` → **Market** → **Artwork**: assign optional thumbnail textures by stable card ID. Artists can use a transparent PNG/WebP per card; the same texture is used on its tile and larger preview. Source Blender files can stay in their own artist folder; render/export a thumbnail and assign it here.
- `MarketArt` provides simple tower/beam construction thumbnails as placeholders. No per-card SubViewport or 3D render pass is allocated.
- `MarketStrip` owns only card/preview presentation; `InstrumentHud._layout` centres its row between the circular dial and threat display; `WorldScreen` submits purchase actions.
- `RoundRules.purchase_market` owns validation, the wallet charge and single refill. `CardZones.acquire` creates one owned/live copy and handles a full hand. Prices never enter `CardInstance` or hand text.

Preview controls ignore pointer events; starting a hand drag hides/locks market inspection and purchases. Market buttons capture their own clicks. Choices, pause and feedback lock purchasing while the four tiles remain visible.

## Corner readouts and current verification

Owned 3D cards follow the supplied corner sketch: a boxed **I value** at bottom
left and boxed **G value** at bottom right, including G 0 on non-earners. Title
stays at the top; effects occupy the centre, with copy status just above the
value boxes. Prices remain absent from owned cards. Market previews use the same
left/right I/G order at their bottom, with acquisition price beneath the title.
Badge meshes and text remain separate from replaceable artist card backing.

The latest pass used three focused checks/reviews: one wallet carry/Bounce
regression, one native market/card/round/restart case, and one visual review of
1920×1080 and 1280×720 captures. They passed. This also confirms the prior fixed
market tile layout now contains its art/prices correctly. Current captures:
`references/card-corner-values-wide.png` and
`references/card-corner-values-small.png`.

The native case verifies Integrity/Gold positions, hidden owned-card price,
market purchases/refill, drag preview dismissal, automatic round transition with
Gold retained, and Restart restoring 3 Gold. No broad suite or balance simulation
was run. Historical free-reward/payout fixtures remain obsolete.

Action: F8 → F5. Gold remains available next round; starting a fresh run restores
3 Gold. Hover a card to see its bottom-left Integrity and bottom-right Gold.

## Single circular meter and top market

The long Progress ruler and its transfer animation are removed. A single circular
Integrity dial displays **built whole-run Progress + current-round Integrity**,
against the target derived from the actual room totals (currently 250). Its arc
and outer needle move clockwise when this total increases and anticlockwise when
Forest damage subtracts live Integrity. A small **ROUND** readout keeps the
current round’s exact survival pool visible inside the same instrument. Built
Progress does not become protection; rules, attack timing and victory checks are
unchanged. Temporary gains reaching the target do not win before Forest/round
resolution. At cleanup, moving surviving Integrity into built Progress neither
zeros the dial nor counts the same amount twice. Progress bonuses apply through
the existing resolution, then the display reconciles to the resulting total.

The four market cards are arranged horizontally above the bridge. Each shows
its complete short ability copy, placeholder/artist art, I/G values and purchase
price. Longer names wrap; longer later-pool descriptions still have the enlarged
hover/focus preview. That preview opens below the selected offer and disappears
when a hand drag starts. Default face size is 160×245 logical pixels; fit_width
shrinks the row within the available space. HUD layout is the single owner of
its top position/available width. Artwork assignment remains HUD → Market →
Artwork; no artist asset or camera change is required.

Latest verification: eight bounded cases/reviews including UI refinements—two
native cases run initially and again after text fitting, one final layout-only
case for the long Enhanced name, plus three visual reviews. Clockwise gains,
anticlockwise subtraction, no double-counting at settlement, actual Forest/round
transition, Gold carry, top-row framing, full-card purchase/refill, enlarged
inspection and drag dismissal passed. Captures at 1920×1080 and 1280×720 are
`references/single-dial-market-wide.png` and
`references/single-dial-market-small.png`. No broad gameplay suite was run.
Older ruler/transfer-specific HUD fixtures need their superseded assertions
updated before reuse. Current focused check: `tests/check_single_dial.gd`.

Pool 1 economy update: cards 1–15 now use the designer’s revised Gold/price table. Integrity, normal effects, starter cards and later pools are unchanged.

Pool 1 Forest balance update (2026-11-06): restored the original prototype hit damage for all 15 attacks (scheduled totals 13–26), reversing the earlier 20–28 increase. Hit timings, reductions, weather and penalties are unchanged. Card balance and later attack pools are unchanged.
