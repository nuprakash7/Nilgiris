# Minimal Construct cards

Shared ivory face, thin brass rule, dark outline and blue Integrity / brass Gold circles follow the supplied Iron Spike reference. Numbers and rules remain live game data. Owned cards never display purchase prices. Hand cards remain 3D meshes with the same fan, hover lift, picking and dragging.

- `face.svg`: shared frame and badge icons. Coordinates use a 315 × 470 portrait canvas; keep badge centres at (65,403) and (250,403) when changing the backing.
- `illustrations/`: transparent SVG line-art placeholders (spike, pier and brace), not finished individual illustrations. PNG/WebP textures also work.
- `presentation/instruments/card_visuals.gd`: shared fallback selection and texture references. No per-card SubViewport or baked text.
- Gameplay scene → BridgeWorld → **Card Illustrations**: assign textures by card ID for hand artwork.
- HUD → Market → **Artwork**: assign the same textures by card ID for offers and previews. Illustration overrides need transparent backgrounds, generous margins and roughly 1.3:1 landscape bounds. They are fitted without stretching in the market; hand art uses the same landscape frame.
- The existing **Card Art** PackedScene hook still replaces the whole hand backing. Use Card Illustrations when replacing only the drawing; the shared circles/frame and live text then remain intact.

Ability-free cards show CONSTRUCT. Other cards use that space for effects and Flair. Long hand abilities shrink the illustration to reserve text space; compact offers have the full ability in their hover/focus preview. Market previews still dismiss when dragging starts. Paid placement Gold remains shown as zero on replay.

Verification: import/compile, wide and small layouts, drag visuals, and a combined long-ability/purchase/drag-placement case. No broad gameplay suite was run.

Market offers now sit in independent dark/brass outer frames. Their purchase price is a larger, single-line BUY + coin amount in the frame footer, outside the ivory card. Inspection previews use the same separation. Card artwork and owned-card values remain unchanged.
