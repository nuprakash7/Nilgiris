# Bridge foundation and level deck — artist handoff

`foundation.tscn` is the replaceable 3D floor beneath the bridge, instanced as
**World/BridgeFoundation** in `presentation/main.tscn`. It is independent of the
four random background chunks and the bridge column artwork.

## Replace the floor

1. Open `foundation.tscn`. The root, SupportDatum marker and GroundCollision are
   structural; **Visuals** holds the placeholder mesh.
2. Model a replacement in Blender and export GLB into a named asset subfolder
   under `art/bridge/`. Replace **Visuals/Ground** with the GLB instance inside
   Visuals. Keep the scene root and Visuals at identity rotation/scale.
3. Use local **Y=0** as the support surface. Root origin is the centre of the
   floor. Current floor is 38 wide (X), 14 deep (Z), and extends downward 0.7.
   Ground cover must continue under all five column bases.
4. Keep level support patches at **X=-10.4,-5.2,0,5.2,10.4; Z=0; Y=0**.
   Each foot is 2.15 wide by 2.25 deep. Sculpt elsewhere freely, but don't add
   holes, raised rocks or slopes under those footprints. Update the floor
   collider separately if you change its physical envelope; it is on layer 2,
   separate from card/slot picking on layer 1.
5. Save and restart the game; inspect all five placed columns. Re-export later
   GLB revisions to the same path for automatic reimport.

The main scene places the floor root at world Y=-3.6. The bridge derives every
slot's height from this common support datum, not from per-column terrain ray
sampling. Moving the floor root's Y in the saved scene moves the whole bridge
vertically on next launch; leave X/Z=0 and rotation/scale at identity. Retune
bank scenery if changing the overall height. Arbitrary uneven replacement art
is not automatically surveyed: preserve the level support patches above.

## Column/deck replacement contract

World's **Column Art** slot still replaces the whole column/deck visual scene.
Keep local base bottom **Y=-6.6** and deck top **Y=0.35** relative to the slot
origin. With the default floor, these become world Y=-3.6 and Y=3.35 respectively.
The five slots share one Y and Z, spaced **5.2** apart along X. Deck modules
must span **X=-2.6 to +2.6** and keep their top flat so adjacent sections meet.
Match the original cap/rail depths when replacing artwork; stable picking and
labels remain outside the model. See `art/README.md` for the general GLB workflow.

Columns appear immediately at their seated transform. The old vertical rise
was removed so placement does not temporarily bend/step the bridge or move its
feet through the floor. End-of-round horizontal visual feedback remains.
No physical bridge simulation or gameplay rule changes are introduced.

Verification: native world UI checks assert all feet touch the actual placeholder
mesh top, all deck tops share a height, slots share a straight Z centreline and
adjacent deck ends meet, alongside existing click/drag/Flair/round checks.


### Five-slot and seven-slot boards

Pool 5 uses seven slots. The same column scene is instanced for every slot;
keep the existing module dimensions and origin. BridgeWorld preserves the
floor datum and 5.2-unit spacing, moving the bank stubs to the current ends.
The current foundation is 38 units wide and covers all seven feet. Replacement
floors should cover at least that width without changing the SupportDatum.

World → Board framing → `Fit Board To Camera` widens the orthographic camera
only when required. `Board Overscan` controls the extra horizontal margin.
Camera3D's authored size remains the minimum width, with its position and
rotation left intact. Disable automatic fitting to own the framing entirely;
check both five- and seven-slot boards when editing camera or environment art.
