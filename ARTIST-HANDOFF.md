# Nilgiris: artist Git handoff

This repository is the standalone Godot project. The TypeScript prototype is not required to open or play it.

## First checkout

1. Install the same standard Godot build used by the project: **Godot 4.7.2 stable**, GDScript, Forward+. Blender is needed only for modelling; export `.glb` files so other teammates can run without Blender.
2. Clone `https://github.com/nuprakash7/Nilgiris.git` using GitHub Desktop or `git clone https://github.com/nuprakash7/Nilgiris.git`.
3. Import the repository's `project.godot` into Godot. Wait for initial asset imports; `.godot/` is generated locally and must not be committed.
4. Press F5 to play, F8 to stop. The game uses a fanned 3D hand and a permanent four-card market. Click/drag cards onto slots; rounds advance automatically. Escape opens pause/settings.

## Replace models

Read [art/README.md](art/README.md) for dimensions, origins, scene hooks and camera controls. Detailed guides:

- [Bridge and foundation](art/bridge/README.md): keep common flat deck heights, column origins and floor support datum; check both five- and seven-slot boards.
- [Independent forest terrain chunks](art/backdrops/README.md): replace one chunk at a time through its existing `.tscn` wrapper. Keep the wrapper path/root stable so the random pool continues to work.
- [Card illustrations](art/cards/README.md): separate transparent artwork from live titles, ability text, numbers and purchase-price frames.

Put each production asset in a named folder under `art/`, with its `.blend` source, `.glb` export and textures together. Keep the existing Godot wrapper scene, changing only its visual children or the documented art slot. Re-export to the same `.glb` path for revisions. Do not edit generated imported resources or add gameplay colliders/scripts to visual replacements.

The gameplay camera is `presentation/main.tscn` → **World/Camera3D**. Use the editor's camera preview, then edit its transform and orthographic Size. World → Board framing controls automatic widening for seven slots. Keep orthographic projection; restart play after changes. See the art guides for environment lighting and haze controls.

## Daily Git workflow

1. Pull `main` before starting and create an art branch, e.g. `art/bridge-column`.
2. Work on one asset at a time; coordinate before editing shared scenes or camera settings concurrently.
3. Save Blender and Godot scenes explicitly. Check the model in the gameplay camera, in both window sizes and all applicable board sizes.
4. Commit source assets, exports, textures, wrapper scenes, `.import` sidecars and `.uid` files. Do not commit `.godot/`, exports/builds, secrets or backup files.
5. Push the branch and open a pull request to `main`. Include a screenshot, the changed asset paths, dimensions and texture sizes. The project owner reviews and merges it; others then pull `main`.

GitHub access is required for a private repository: the owner must invite the artist as a collaborator. Authenticate through GitHub Desktop or your configured Git credential manager; never put access tokens in files or remote URLs.

## Large assets

The initial project has no large binaries requiring Git LFS. Before committing production `.blend` files or large textures, agree on Git LFS with the project owner and install it on every contributor's machine. Enable tracking before the first large binary commit; GitHub rejects regular Git files over 100 MiB. Keep runtime exports and sources separate and avoid committing automatic Blender backups.

## Project ownership

`gameplay/` and `content/` own rules and data. `presentation/` owns input, scene assembly and HUD. `art/` owns replaceable visuals. Artist changes should stay in art assets and the necessary wrapper/Inspector assignments. Current gameplay scope and remaining milestones are in [README-ROADMAP.md](README-ROADMAP.md); the current economy is in [content/CLASSIC-MARKET.md](content/CLASSIC-MARKET.md).
