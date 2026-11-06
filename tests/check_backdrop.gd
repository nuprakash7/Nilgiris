extends SceneTree
## Determinism/coverage checks plus native multi-seed camera captures.
const Snapshot = preload("res://tests/state_snapshot.gd")
var failures := 0
var output := ""

func _initialize() -> void:
	Engine.max_fps = 60
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output = args[0]
	call_deferred("_run")

func _run() -> void:
	var screen = load("res://presentation/main.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await physics_frame
	var forest: ForestBackdrop = screen.world.get_node("ForestBackdrop")
	var original: Dictionary = forest.configuration.duplicate(true)
	var state: Dictionary = Snapshot.capture(screen.rules.state)
	_check(forest.pool.size() == 16, "Sixteen reusable variants")
	var profiles: Array[PackedFloat32Array] = []
	var geometry: Array[PackedVector3Array] = []
	for scene in forest.pool:
		var chunk: Node3D = scene.instantiate()
		var mesh: Mesh = chunk.get_node("Terrain").mesh
		var bounds: AABB = mesh.get_aabb()
		_check(bounds.size.x >= 48 and bounds.size.y > 10 and bounds.size.z >= 6, "Every variant has real width, height and depth")
		_check(not geometry.has(mesh.get_faces()), "Sixteen distinct mesh variants")
		geometry.append(mesh.get_faces())
		profiles.append(_ridge_profile(mesh, forest.camera))
		chunk.free()
	var seen: Dictionary = {}
	for sample in range(64):
		forest.seed = sample
		forest.enter_room(0, 42)
		var selected: Array = forest.configuration.variants
		var distinct: Dictionary = {}
		for variant in selected:
			distinct[variant] = true
			seen[variant] = true
		_check(distinct.size() == 4, "Sampling without replacement")
		var before: Dictionary = forest.configuration.duplicate(true)
		forest.enter_room(0, 42)
		_check(forest.configuration == before, "Room rendering never rerolls")
		# Check each ridge at every visible X, including horizontal offsets.
		for x in range(101):
			var previous := -1000.0
			for layer in range(4):
				var spec: BackdropLayer = forest.layers[layer]
				var offset: Vector2 = forest.configuration.offsets[layer]
				var chunk: Node3D = forest.get_child(layer)
				var width: float = 48 * chunk.scale.x
				var local_x: float = (lerpf(-forest.camera.size * 0.5, forest.camera.size * 0.5, x / 100.0) - spec.position.x - offset.x) / chunk.scale.x
				_check(absf(local_x) < width * 0.5, "Terrain overscan covers both screen edges")
				var lookup: float = clampf((local_x + 24) * 10, 0, 479.99)
				var low: int = int(lookup)
				var profile: PackedFloat32Array = profiles[selected[layer]]
				var ridge: float = spec.position.y + offset.y + lerpf(profile[low], profile[low + 1], lookup - low)
				_check(ridge > previous + 0.15, "Each ridge remains visible above its nearer neighbour")
				previous = ridge
		if sample in [0, 7, 42]:
			screen.hud.get_node("%RewardPopup").hide()
			await _capture("forest-seed-%d" % sample)
	_check(seen.size() == 16, "All variants reachable across seeds")
	forest.seed = 1881
	forest.enter_room(0, 42)
	_check(forest.configuration == original, "Same seed and room reconstruct identical configuration")
	forest.enter_room(1, 42)
	_check(forest.configuration != original, "Room transition selects its own composition")
	forest.enter_room(0, 42)
	_check(forest.configuration == original, "Re-entering room restores arrangement")
	forest.regenerate_preview()
	_check(forest.configuration != original, "Development regeneration changes only presentation")
	_check(Snapshot.capture(screen.rules.state) == state, "Backdrop never mutates gameplay/RNG")
	var clone: ForestBackdrop = load("res://presentation/backdrop/forest_backdrop.tscn").instantiate()
	clone.camera = forest.camera
	root.add_child(clone)
	clone.enter_room(0, 42)
	_check(clone.configuration == original, "Reloading backdrop restores same room appearance")
	clone.queue_free()
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960, 600)
	forest.enter_room(1, 42)
	await process_frame
	await _capture("forest-compact")
	if not output.is_empty():
		screen.world.hide()
		screen.world.get_node("WorldEnvironment").environment = null
		screen.hud.hide()
		var preview: Node3D = load("res://art/backdrops/preview.tscn").instantiate()
		root.add_child(preview)
		await process_frame
		await _capture("terrain-volume-preview")
		preview.queue_free()
	if failures == 0:
		print("Backdrop checks passed: 64 seeds, unique sampling, volumetric meshes, ridge visibility/overscan, room/reload stability, dev regeneration and gameplay isolation.")
	screen.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

func _ridge_profile(mesh: Mesh, camera: Camera3D) -> PackedFloat32Array:
	var profile := PackedFloat32Array()
	profile.resize(481)
	profile.fill(-1000)
	var faces: PackedVector3Array = mesh.get_faces()
	for triangle in range(0, faces.size(), 3):
		for edge in range(3):
			var a: Vector3 = camera.global_basis.inverse() * faces[triangle + edge]
			var b: Vector3 = camera.global_basis.inverse() * faces[triangle + (edge + 1) % 3]
			if is_equal_approx(a.x, b.x):
				continue
			var first: int = maxi(0, int(ceil((minf(a.x, b.x) + 24) * 10)))
			var last: int = mini(480, int(floor((maxf(a.x, b.x) + 24) * 10)))
			for sample in range(first, last + 1):
				var x: float = sample / 10.0 - 24
				var height: float = lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))
				profile[sample] = maxf(profile[sample], height)
	return profile

func _capture(label: String) -> void:
	if output.is_empty():
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))

func _check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		if failures < 12:
			printerr(description)
