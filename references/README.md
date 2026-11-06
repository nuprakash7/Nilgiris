# Visual reference — Step 5 onward

User supplied on 2026-11-02. [Reference image](step-5-composition.png) is an
unchanged copy of `Low-poly Nilgiris bridge in mist.png` from Downloads.
It guides composition and presentation; it is not a gameplay specification or
a requirement to reproduce every depicted asset. Do not ship the reference
itself as a runtime background or build gameplay UI into a flat screenshot.

## Direction to carry forward

- A wide bridge crossing occupies the middle of the view. The elevated camera
  shows the deck's top and the height of the columns, with clear separation
  between foreground cards, playable bridge slots, and distant terrain.
- Cards are actual world-space objects in the foreground, arranged for readable
  selection and placement. The reference's apparent flat card row does not
  supersede the user's explicit requirement for cards in the 3D world.
- Five numbered placement locations read from left to right. A valid hovered or
  selected location can show a simple highlighted/ghost column. Placing a card
  creates a 3D bridge column at that logical slot.
- Keep status and Forest Intent legible, in approximately the reference's upper
  band and upper-right area. Card text and slot identification take priority
  over decoration. Final typography, textures, and framing remain open.

## Step 5 blockout limits

Use simple boxes or tapered shapes for columns, caps, and bridge components.
Use simple irregular planes/faceted surfaces to suggest valley sides and
distant hills. Backgrounds are not finalized. **Trees, rocks, water, and other
environmental detail are not required.** Establish composition, scale, depth,
readability, and working interaction before producing polished assets.

## Preserve the game

The reference's card names, powers, progress target, round budget, attack wording,
slot labels (Anchor/Span/Vantage), and animal portraits are illustrative. Keep
the existing catalog and rules. In particular, the pictured **End Round** button
does not authorize a manual End Round action: rounds still close automatically.
Animal UI remains deferred until its gameplay is implemented.

Placement, hit, and cleanup feedback must present outcomes from the existing
model. Let the final column/Forest impact be visible through presentation
sequencing without moving game resolution into animation callbacks or changing
the model's synchronous closure rules.

This reference was recorded before implementation. The user authorized Step 5
on 2026-11-02; its working primitive blockout now awaits visual review. Follow
the current approval checkpoint in `../README-ROADMAP.md` before further work.
