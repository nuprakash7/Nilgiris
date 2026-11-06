# Artist handoff

Gameplay lives outside this directory. Art scenes need no gameplay scripts.
Use these folders:

- `bridge/`: bridge module `.blend` sources, exported `.glb`, and Godot wrapper `.tscn`.
- `environment/`: valley/background scene, sources and exports.
- `cards/`: reusable card backing scene and its textures/sources.
- `materials/`: shared Godot materials and textures.
- `backdrops/`: independent 3D terrain scenes and their designer/artist guide. See
  `backdrops/README.md` for GLB scene replacement and four-layer settings.

Keep source, export and wrapper together under a named asset subfolder when an
asset gains several files. Use lowercase snake_case names. Do not rename imported
files casually after scenes reference them. No Blender installation is required
to run the game; use exported GLB files as the runtime import source.

## Replace a placeholder

1. Model in Blender at metre scale, apply object rotation/scale, and export glTF
   Binary (`.glb`) into the relevant art folder. Export meshes/materials; do not
   export cameras, lights, or collision for these visual-only assets.
2. In Godot create a Node3D wrapper scene and drag the imported GLB into it.
   Correct any visual offset/scale on that child; save the wrapper as `.tscn`.
   Keep the wrapper root at identity. Do not edit generated imported resources.
3. Open `presentation/main.tscn`. Select **World**. In the Inspector assign the
   wrapper to **Column Art**, **Environment Art**, or **Card Art**. Empty means
   the original procedural blockout. These slots are shared visual replacements,
   not card-specific art mappings.
4. Run with F5. Re-export to the same GLB path for later revisions; Godot reimports
   it and the wrapper keeps its settings. No GDScript changes required.

### Coordinate contracts

Godot units here are metres; Y is up. Check the imported result, since Blender
uses Z up and its glTF exporter converts axes.

- **Column Art:** repeated once per occupied slot. Root origin is the slot centre
  at world Y=3. Deck runs along X. Slot spacing is 5.2. Existing module envelope:
  deck width X=5.2, depth Z=2.3; deck top local Y=0.35; rails to Y=1.03;
  pier/base down to Y=-6.6. Keep adjacent deck ends aligned. This scene replaces
  the whole column/deck module, not the labels, footprint, ghost or hit areas.
- **Environment Art:** world origin (0,0,0), bridge centred across X, bridge slots
  at X=-10.4,-5.2,0,5.2,10.4 and Y=3, Z=0. Banks near X=+/-13.4. Replaces valley-bank terrain. The layered forest backdrop is independent;
  edit World/ForestBackdrop or hide that node for an alternative environment.
  Bank deck stubs, sky, sun and fog remain separate.
- **Card Art:** reusable backing centred at (0,0,0), XY plane facing +Z, size
  3.15 by 4.7. Keep its front at or behind Z=0.10: live text is at Z=0.19–0.20.
  Replaces paper only; selection border, dynamic labels, picking and hover lift
  remain managed by the view. Don't bake gameplay text into textures. Card-specific transparent illustrations are configured separately through World → Card Illustrations and HUD → Market → Artwork; see `cards/README.md`.

Visual replacements deliberately have no physics bodies or scripts. Picking uses
stable gameplay hit areas. If a silhouette exceeds these envelopes, coordinate a
hit-area/ghost/layout adjustment with the developer rather than adding collisions.

## Camera and lighting

Open `presentation/main.tscn`, select **World/Camera3D**, and enable camera preview
in the 3D viewport. Adjust Transform Position/Rotation and orthographic **Size**
(smaller zooms in). Save the scene. Nothing overwrites camera rotation at runtime.
Keep orthographic projection and Keep Width for the current card layout; changing
projection requires developer coordination. Cards are framed from the camera at
startup and window resize. Stop/restart play after camera edits. Check both
1280x720 and 960x600 for HUD/card overlap and ray picking.

Edit **World/Sun** for lighting and **World/WorldEnvironment** for sky/fog. Make
shared Environment resources unique before creating separate lighting variants.

## Handoff check

Check all five adjacent modules, empty-slot preview, hover/selection, readable
live labels, both window sizes, and final-placement animation. Verify imported
materials and texture paths, apply sensible mesh/texture budgets, and report the
asset's dimensions and texture sizes. Test first; don't change gameplay files.

## Bridge floor and straightness

The bridge now sits on `art/bridge/foundation.tscn`, instanced as
World/BridgeFoundation. Replace its Visuals child with floor artwork and preserve
local Y=0 support patches. All five feet use that shared level, and deck modules
are 5.2 metres wide with a common top height. See `bridge/README.md` for exact
footprints, Blender replacement and the distinction between flat support patches
and arbitrary uneven terrain.


### Full-hand fan

World's Hand fan group controls angle, arc drop, available viewport width and
per-card depth spacing. Card Art remains one interchangeable scene instanced
for all hand copies, with the same centered 3.15 × 4.7 × 0.12 envelope. Preserve
the face's local origin so automatic fanning, hover straightening and dragging
remain aligned. Increase Fan Depth Step if replacement art has greater depth;
check twelve-card hands at both five- and seven-slot camera widths. No authored
card scene needs to know its hand index or implement input/gameplay logic.
