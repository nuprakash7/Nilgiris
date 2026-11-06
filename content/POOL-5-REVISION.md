# Pool 5 revision

| # | Card | Integrity | Gold | Price | Effects | Flair |
|---:|---|---:|---:|---:|---|---|
| 61 | Monolithic Pier | 25 | 4 | 23 | — | Gain 2 Integrity |
| 62 | Mountain Abutment | 30 | 3 | 27 | — | — |
| 63 | First Foundation | 13 | 8 | 21 | Reinforce 2. +6 when placed first this round. | — |
| 64 | Tempered Arch | 11 | 7 | 22 | Reinforce 2. +10 if both neighbours are occupied. | Gain 2 Integrity |
| 65 | Final Keystone | 11 | 6 | 24 | Reinforce 2. +16 on the seventh Construct placement this round. | — |
| 66 | Great Counterbrace | 10 | 7 | 22 | Support the Construct immediately left by 12. | — |
| 67 | Crossed Steelwork | 9 | 6 | 23 | Support each adjacent Construct by 8. | — |
| 68 | Grand Load Distributor | 8 | 5 | 25 | Support any other Construct by 5. | Support all other Constructs by 5 |
| 69 | Master Assembly | 9 | 5 | 25 | Support another Construct by 8, or by 16 if that Construct has been placed at least twice this round. | — |
| 70 | Seasoned Framework | 11 | 7 | 23 | Reinforce 1. Support one adjacent Construct by 6, or by 10 if it already received Support this round. | — |
| 71 | Return Gantry | 8 | 5 | 23 | May Bounce one adjacent Construct. Draw 2 if you do. This card cannot be Bounced. | Bounce 2 adjacent instead |
| 72 | Supply Convoy | 10 | 7 | 22 | Draw 3 if Support was used earlier this round. | Draw 2 |
| 73 | Survey Platform | 11 | 8 | 20 | Draw 2 if an adjacent Construct has Reinforce. | — |
| 74 | Reconstruction Crane | 8 | 4 | 25 | May Bounce up to two other Constructs. Draw 1 per Construct returned. This card cannot be Bounced. | — |
| 75 | Crowning Truss | 13 | 5 | 26 | Support each adjacent Construct by 4, or by 12 on the seventh Construct placement this round. | — |

Seasoned Framework checks whether the target copy received Support earlier in this round, before applying its own Support. The stronger amount replaces the base amount. History survives Bounce and clears for the next round.

Return Gantry and Reconstruction Crane cannot be Bounced by Constructs, Flair or animals. Reconstruction Crane uses the existing sequential optional Bounce flow and draws one per returned Construct, subject to the existing hand limit. Return Gantry’s Flair replaces the one-target Bounce with two adjacent targets and retains its single Draw 2 reward.

Seventh-placement bonuses count successful Construct placements this round, including replays, rather than physical slot numbers. Placement Gold remains once per copy per round.

Verification: three focused runtime cases and one exact 15-card data/scope check passed. Earlier pools, starters and Forest attacks are unchanged.

Action: F8 → F5. Newly generated Pool 5 market offers use the revised prices.
