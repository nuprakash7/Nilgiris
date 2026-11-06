# 3D terrain chunks — artist and designer handoff

The backdrop now uses **real 3D mesh scenes**, not textured planes. Sixteen
independent variants live in `chunks/terrain_01.tscn` through `terrain_16.tscn`.
Each wrapper contains an editable placeholder OBJ terrain with a sloped top,
side walls, bottom and low-poly canopy volumes. The old SVG plane pool is removed.
Any four variants are selected without replacement for A/B/C/D depth positions.

## Work on one terrain independently

1. Open one `chunks/terrain_XX.tscn` in Godot and orbit its meshes in the 3D editor.
   For a lit standalone view, open `art/backdrops/preview.tscn` and press F6.
   Its Terrain child initially instances terrain_01; replace that instance to
   preview any other wrapper. This preview camera is separate from gameplay.
2. Import its matching `terrain_XX.obj` into Blender as an optional starting mesh,
   or model a replacement from scratch. Keep source `.blend`, exported `.glb`
   and textures together in a named asset subfolder as production assets grow.
3. Export a GLB with meshes/materials, without cameras/lights/collision/scripts.
   Create a Godot Node3D wrapper, drag the GLB inside, and save as `.tscn`.
   Use the child transform for import corrections; keep the wrapper root identity.
4. Replace the old Terrain mesh child inside the existing wrapper with the GLB
   instance, **or** assign your new wrapper into the relevant Pool slot. Nothing
   in randomisation/room/gameplay code needs changing. Separate child meshes for
   trees, rocks and ground are supported: material processing walks descendants.
5. Re-export to the same GLB path for revisions; Godot reimports the model while
   the wrapper retains its settings. Do not edit generated import resources.

GLB workflow reference: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html

## Coordinate/asset contract

Godot units are metres, Y up, X across the view. Chunks stay upright in world
space; they do **not** rotate to face the camera. Front is +Z, back is -Z.
Blender's glTF export converts its Z-up coordinate convention.

The supplied reference footprint is **48 wide x 6 deep**, centred on X/Z=0.
Root Y=0 is the reference terrain crest, with low slopes/canopies around it.
An approximately 16-metre downward skirt hides the base from the gameplay camera.
These are blockout dimensions, not final architecture or geography. Real tops,
slopes, trees and rocks can be individually modelled. Retain an extended skirt
or another opaque lower fill so random combinations do not reveal floating bases.
Keep the outer side faces outside the visible camera width.

The layer Size setting is Vector3(width, skirt-height, depth), relative to the
48x16x6 reference; it scales the complete scene, including decorations. Keep a
consistent footprint/crest envelope across all variants. Larger ridgeline peaks
require extra vertical spacing between A–D; deeper chunks require extra depth
spacing. Do not include tall mountains/trees outside the tested envelope without
rechecking combinations. Pool entries should remain visual-only, with no gameplay
colliders, cameras, lights or active scripts. No scenery occludes player picking.

## Main scene settings

Open `presentation/main.tscn`, select **World/ForestBackdrop**:

- **Pool:** Array of 16 PackedScenes. Each entry is a whole 3D terrain wrapper,
  independently replaceable. At least four distinct Node3D scenes are required.
- **Layers:** four resources in A–D order (`presentation/backdrop/layer_a.tres`
  through `layer_d.tres`). Expand Position, Size, Colour, Contrast and Haze.
- **Position:** anchor relative to the gameplay camera, X right, Y up, positive
  Z depth away. Defaults: depths 48/58/68/78, vertical anchors -1.8/0.4/2.6/4.8.
  Camera-relative anchors simplify composition; the chunks themselves stay Y-up.
- **Size:** defaults 48x16x6. Orthographic projection never shrinks distant terrain.
  Width expands automatically to cover the view plus four metres and offsets.
- **Safe Offsets:** defaults +/-0.65 horizontal, +/-0.16 vertical metres; hard
  limits +/-1.5 and +/-0.22 protect the supplied placeholder crest envelope.
- **Seed:** saved visual seed, independent of gameplay. Same seed, initial run
  seed, room index, pool order and settings recreate the arrangement on reload.
- **Mist Colour / Intensity:** shared static atmosphere. Farther layers have more
  haze and lower contrast. Surface shading supplies low-lying mist without extra
  transparent planes or volumetric fog passes.
- **Development Regeneration:** F7 (possibly fn+F7 on Mac) previews another seeded
  arrangement and prints its configuration. Debug only; never changes gameplay
  or the saved seed. Reload restores the saved arrangement.

Save settings and restart play. There is no per-frame assembly or rerolling.
The gameplay camera remains **World/Camera3D**: edit its transform/orthographic
size directly, then restart. The defaults are tested for 16:9 and 16:10. Changing
camera yaw, crest envelope, height/depth or aspect ratio may require adjusting
spacing/overscan so no chunk faces/base edges become visible.

## Materials and current limitations

Lighting responds to real surface normals. Runtime uses independent atmospheric
surface materials while leaving imported meshes and source materials intact.
Supported StandardMaterial3D inputs: base colour/albedo texture, roughness and
metallic scalar values, and normal texture/strength. Set layer Colour to white
for the original base colours. Current haze uses emission to keep distant terrain
near the shared mist colour; it is static and illustrative, not volumetric mist.

Special PBR maps, vertex painting, UV transforms, original emission, multi-pass
materials and animation-driven material changes are not replicated by this basic
material adapter. Custom shaders are retained as authored and produce a warning;
they need compatible atmosphere support before a final-art handoff. Agree the
material contract with the developer before building complex production shaders.
Opaque geometry and alpha-cutout foliage are supported; soft blended fog should
not be embedded in terrain materials. Test final foliage edge quality separately.

## Stability and verification

The scene stores the visual seed. `enter_room` uses the room index, initial run
seed and round number. Every new round selects four distinct chunks without
replacement and assigns them to A–D. Repeated renders within that round retain
the arrangement; reloading the same seed/room/round reproduces it. This uses a
separate visual RNG and never advances the gameplay RNG. Future save integration
must retain the initial run seed and round, or the selected configuration.

`tests/check_backdrop.gd` checks all 16 meshes have volume and distinct geometry,
64 seeded selections, projected ridge visibility across 101 horizontal samples,
overscan, room/reload stability, regeneration and unchanged gameplay/RNG. Native
captures cover several seeds, compact layout and an angled single-chunk preview.
`tests/check_round_ui.gd` covers the existing bridge controls/round flow.

Before handoff, inspect multiple F7 combinations, full/empty bridge slots, drag
preview, foreground cards, reward popup, small windows, custom materials and
performance. Final terrain/art production remains a later milestone.
