# Pool 2 revision

Current Classic definitions. No Flair remains on cards 16–30. Only listed effects are retained; Integrity/Gold/price follow the designer table.

| # | Card | Integrity | Gold | Price | Effect |
|---:|---|---:|---:|---:|---|
| 16 | Riveted Girder | 13 | 2 | 11 | — |
| 17 | Seasoned Pier | 8 | 5 | 8 | Reinforce 1. |
| 18 | Tempered Beam | 7 | 4 | 9 | Reinforce 2. |
| 19 | Practised Footing | 8 | 4 | 9 | +3 in either edge slot. |
| 20 | Fitted Span | 8 | 5 | 9 | +3 if both neighbours are occupied. |
| 21 | Bolted Brace | 8 | 4 | 9 | Support one adjacent Construct by 3. |
| 22 | Cross Bracing | 7 | 4 | 9 | Support each adjacent Construct by 2. |
| 23 | Balancing Frame | 7 | 4 | 10 | Support the lowest-power other Construct by 4. Choose if tied. |
| 24 | Long-Reach Crane | 5 | 5 | 10 | Support any other Construct by 5. |
| 25 | Seasoned Assembly | 7 | 5 | 9 | Support the Construct to the left by 4. |
| 26 | Training Scaffold | 7 | 3 | 11 | Support another Construct in either edge slot by 6. |
| 27 | Shared Foundation | 8 | 3 | 12 | Reinforce 3. |
| 28 | Inspection Gantry | 7 | 4 | 10 | You may Bounce one adjacent Construct. |
| 29 | Travelling Derrick | 5 | 3 | 11 | You may Bounce any other Construct. |
| 30 | Finishing Crew | 8 | 2 | 10 | Draw 2 cards. |

Support retains its existing “other Construct” semantics. Training Scaffold offers occupied edge slots, excluding itself; if only one target exists, Support resolves automatically. Missing targets skip Support. Gold pays once per physical copy per round, including after Bounce/replay.

Removed old mechanics: Riveted Girder/Fitted Span/Inspection Gantry/Travelling Derrick Flair; Reinforce on Practised Footing, Fitted Span and Seasoned Assembly; Training Scaffold’s Reinforce-dependent amount; Shared Foundation’s adjacent-Reinforce formula; Derrick’s draw-on-Bounce; Finishing Crew’s Support requirement.

No Forest attacks, starter cards or other pools changed.

Verification: one exact data/scope comparison and two focused rule cases passed. Checked edge-only/left-only Support, invalid interior targeting, Reinforce 3, replay Gold protection, unconditional Draw 2 and removal of Derrick’s draw-on-Bounce. No broad suite was run.

Action: F8 → F5 reloads definitions. New Pool 2 offers use these prices when reached.
