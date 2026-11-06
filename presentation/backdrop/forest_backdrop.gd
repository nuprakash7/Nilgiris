class_name ForestBackdrop
extends Node3D
## View-only round composition, with its own RNG; never consumes the rules RNG.
const SURFACE = preload("res://presentation/backdrop/forest.gdshader")
@export var camera: Camera3D
@export var pool: Array[PackedScene] = []
@export var layers: Array[BackdropLayer] = []
@export var seed: int = 1881
@export var safe_offsets := Vector2(0.65, 0.16)
@export var mist_colour := Color(0.64, 0.76, 0.79)
@export_range(0, 0.5) var mist_intensity: float = 0.16
@export var development_regeneration: bool = true

var configuration: Dictionary = {}
var _room_key: String = ""
var _preview: int = 0
var _chunks: Array[Node3D] = []

func _ready() -> void:
	get_viewport().size_changed.connect(_layout)

func enter_room(room_index: int, run_seed: int, round_number: int = 1) -> void:
	var key := "%d:%d:%d:%d" % [seed, run_seed, room_index, round_number]
	if key == _room_key:
		return
	_room_key = key
	_preview = 0
	_assemble(key.hash())

func _unhandled_key_input(event: InputEvent) -> void:
	if OS.is_debug_build() and development_regeneration and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F7:
		regenerate_preview()
		get_viewport().set_input_as_handled()

func regenerate_preview() -> void:
	if not OS.is_debug_build() or not development_regeneration or _room_key.is_empty():
		return
	_preview += 1
	_assemble(("%s:preview:%d" % [_room_key, _preview]).hash())
	print("Backdrop preview: ", configuration)

func _assemble(arrangement_seed: int) -> void:
	if camera == null or pool.size() < 4 or layers.size() != 4:
		push_error("Forest backdrop needs a camera, four layers and at least four unique terrain scenes.")
		return
	var unique: Array[PackedScene] = []
	for scene in pool:
		if scene != null and not unique.has(scene):
			unique.append(scene)
	if unique.size() < 4:
		push_error("Forest backdrop pool needs four distinct non-null terrain scenes.")
		return
	for chunk in _chunks:
		remove_child(chunk)
		chunk.queue_free()
	_chunks.clear()
	var random := RandomNumberGenerator.new()
	random.seed = arrangement_seed
	var remaining: Array[int] = []
	for index in range(unique.size()):
		remaining.append(index)
	var chosen: Array[int] = []
	var offsets: Array[Vector2] = []
	for index in range(4):
		var pick_index: int = random.randi_range(0, remaining.size() - 1)
		var variant: int = remaining.pop_at(pick_index)
		chosen.append(variant)
		# Hard safety limits preserve visible ridge bands for the supplied assets.
		offsets.append(Vector2(random.randf_range(-minf(absf(safe_offsets.x), 1.5), minf(absf(safe_offsets.x), 1.5)), random.randf_range(-minf(absf(safe_offsets.y), 0.22), minf(absf(safe_offsets.y), 0.22))))
		var chunk := unique[variant].instantiate() as Node3D
		if chunk == null:
			push_error("Terrain scenes must have a Node3D root.")
			return
		chunk.name = ["A_Near", "B_MiddleNear", "C_MiddleFar", "D_Far"][index]
		add_child(chunk)
		_tint_meshes(chunk, layers[index])
		_chunks.append(chunk)
	configuration = {"room_key": _room_key, "seed": arrangement_seed, "variants": chosen, "offsets": offsets}
	_layout()

func _layout() -> void:
	if camera == null or configuration.is_empty():
		return
	for index in range(_chunks.size()):
		var spec: BackdropLayer = layers[index]
		var offset: Vector2 = configuration.offsets[index]
		var width: float = maxf(spec.size.x, camera.size + 2 * absf(spec.position.x + offset.x) + 4)
		_chunks[index].scale = Vector3(width / 48.0, spec.size.y / 16.0, spec.size.z / 6.0)
		var center := Vector3(spec.position.x + offset.x, spec.position.y + offset.y, -spec.position.z)
		# Terrain stays upright in world space; it is not a camera-facing billboard.
		_chunks[index].global_position = camera.to_global(center)


func _tint_meshes(node: Node, spec: BackdropLayer) -> void:
	if node is MeshInstance3D and node.mesh != null:
		for surface in range(node.mesh.get_surface_count()):
			var source: Material = node.get_active_material(surface)
			if source != null and not source is StandardMaterial3D:
				push_warning("Custom terrain shaders retain their own atmosphere: " + node.name)
				continue
			var material := ShaderMaterial.new()
			material.shader = SURFACE
			if source is StandardMaterial3D:
				material.set_shader_parameter("base_colour", source.albedo_color)
				if source.albedo_texture != null:
					material.set_shader_parameter("artwork", source.albedo_texture)
				material.set_shader_parameter("roughness_value", source.roughness)
			material.set_shader_parameter("metallic_value", source.metallic)
			if source.normal_enabled and source.normal_texture != null:
				material.set_shader_parameter("normal_texture", source.normal_texture)
				material.set_shader_parameter("use_normal_map", true)
				material.set_shader_parameter("normal_strength", source.normal_scale)
			material.set_shader_parameter("layer_colour", spec.colour)
			material.set_shader_parameter("contrast", spec.contrast)
			material.set_shader_parameter("haze", spec.haze)
			material.set_shader_parameter("mist_colour", mist_colour)
			material.set_shader_parameter("mist_intensity", mist_intensity)
			# Per-instance surface override: imported mesh/material resources stay intact.
			node.set_surface_override_material(surface, material)
		if node.material_override is StandardMaterial3D:
			node.material_override = null
	for child in node.get_children():
		_tint_meshes(child, spec)
