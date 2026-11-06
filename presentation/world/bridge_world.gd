class_name BridgeWorld
extends Node3D
## Replaceable primitive scenery and projections of the current logical bridge slots.

signal impact_reached

@export_group("Artist scenes (empty uses blockout)")
@export var column_art: PackedScene
@export var environment_art: PackedScene
@export var card_art: PackedScene
@export var card_illustrations: Dictionary[String, Texture2D] = {}

@export_group("Board framing")
@export var fit_board_to_camera: bool = true
@export var board_overscan: float = 6.0

@export_group("Hand fan")
@export_range(5, 30) var fan_half_angle: float = 18.0
@export_range(0.1, 1.5) var fan_drop: float = 0.8
@export_range(0.4, 0.8) var fan_width_fraction: float = 0.68
@export_range(0.2, 0.5) var fan_depth_step: float = 0.24

var _authored_camera_size: float
var _bank_decks: Array[MeshInstance3D] = []
var _terrain_banks: Array[Node3D] = []
var slots: Array[BridgeSlot] = []
var cards: Array[WorldCard] = []
var materials: Dictionary = {}
var _bridge: Node3D
var _rack: Node3D
var _shake: Tween

@onready var foundation: Node3D = $BridgeFoundation
@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	_authored_camera_size = camera.size
	materials = {
		"stone": BlockoutGeometry.material(Color(0.68, 0.61, 0.46)),
		"cap": BlockoutGeometry.material(Color(0.87, 0.79, 0.61)),
		"deck": BlockoutGeometry.material(Color(0.65, 0.47, 0.30)),
		"red": BlockoutGeometry.material(Color(0.44, 0.12, 0.08)),
		"outline": BlockoutGeometry.material(Color(0.61, 0.74, 0.72), true),
		"gold": BlockoutGeometry.material(Color(1.0, 0.73, 0.20), true),
		"frame": BlockoutGeometry.material(Color(0.16, 0.15, 0.14), true),
		"paper": BlockoutGeometry.material(Color(0.96, 0.86, 0.65), true),
		"muted_paper": BlockoutGeometry.material(Color(0.66, 0.64, 0.54), true),
	}
	if environment_art != null:
		add_child(environment_art.instantiate())
	else:
		_build_terrain()
	_bridge = Node3D.new()
	_bridge.name = "Bridge"
	add_child(_bridge)
	# One level datum controls all feet; deck height never samples uneven artwork.
	var slot_height: float = foundation.position.y - BridgeSlot.FOOT_Y
	for index in range(5):
		var slot := BridgeSlot.new()
		slot.name = "Slot%d" % (index + 1)
		_bridge.add_child(slot)
		slot.position = Vector3((index - 2) * BridgeSlot.MODULE_WIDTH, slot_height, 0)
		slot.build(index, materials)
		if column_art != null:
			slot.replace_column_art(column_art)
		slots.append(slot)
	for side: float in [-1, 1]:
		_bank_decks.append(BlockoutGeometry.box(_bridge, Vector3(3.0, 0.35, 2.4), Vector3(side * 14.5, slot_height + BridgeSlot.DECK_TOP_Y - 0.175, 0), materials.deck))
	_rack = Node3D.new()
	_rack.name = "WorldCards"
	add_child(_rack)
	# Fixed world transform, not a CanvasLayer or a child following the camera.
	get_viewport().size_changed.connect(_frame_cards)
	_frame_cards()


func _frame_cards() -> void:
	if _rack == null: return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var height: float = camera.size * viewport_size.y / viewport_size.x
	var scale_factor: float = camera.size / _authored_camera_size
	var center := Vector3(0, -height * 0.5 + 3.9 * scale_factor, -13)
	_rack.global_transform = Transform3D(camera.global_basis.scaled(Vector3.ONE * scale_factor), camera.global_position + camera.global_basis * center)
	_layout_fan()


func arrange_cards(count: int) -> void:
	while cards.size() < count:
		var card := WorldCard.new()
		card.name = "Card%d" % (cards.size() + 1)
		_rack.add_child(card)
		card.artwork = card_illustrations
		card.build(materials)
		if card_art != null: card.replace_card_art(card_art)
		cards.append(card)
	for index in range(cards.size()):
		cards[index].visible = index < count
		cards[index].collision_layer = 1 if index < count else 0
	_layout_fan()


func _layout_fan() -> void:
	var count: int = 0
	for card: WorldCard in cards:
		count += int(card.visible)
	if count == 0: return
	var half_angle: float = deg_to_rad(minf(fan_half_angle, (count - 1) * 3.5))
	var edge_width: float = WorldCard.SIZE.x * cos(half_angle) + WorldCard.SIZE.y * sin(half_angle)
	var span: float = _authored_camera_size * fan_width_fraction - edge_width
	var spacing: float = minf(WorldCard.SIZE.x * 0.8, span / maxf(1, count - 1))
	for index in range(count):
		var offset: float = index - (count - 1) * 0.5
		var fraction: float = offset / maxf(1, (count - 1) * 0.5)
		cards[index].set_fan_pose(Vector3(offset * spacing, -fraction * fraction * fan_drop, index * fan_depth_step), -fraction * half_angle, count * fan_depth_step + 1.0)


func play_end_feedback(duration: float, has_hit: bool) -> void:
	# Visual-only sequence. The model has already resolved damage and cleanup.
	if _shake != null:
		_shake.kill()
	_shake = create_tween()
	_shake.tween_interval(duration * 0.45)
	if has_hit:
		_shake.tween_callback(impact_reached.emit)
		for offset: float in [0.10, -0.08, 0.05, 0]:
			_shake.tween_property(_bridge, "position:x", offset, maxf(0.001, duration * 0.10))
	else:
		_shake.tween_interval(duration * 0.40)
	_shake.tween_interval(duration * 0.15)
	await _shake.finished


func _build_terrain() -> void:
	var green := BlockoutGeometry.material(Color(0.42, 0.51, 0.31))
	green.vertex_color_use_as_albedo = true
	# Each surface is a few deliberately irregular, flat-shaded triangles.
	for side: float in [-1, 1]:
		var bank := Node3D.new()
		bank.name = "LeftBank" if side < 0 else "RightBank"
		add_child(bank)
		_terrain_banks.append(bank)
		var top: Array[Vector3] = [
			Vector3(side * 13.4, 2.9, 4), Vector3(side * 15.3, 3.3, -6),
			Vector3(side * 25, 5.1, -11), Vector3(side * 33, 4.4, 6),
			Vector3(side * 24, 3.8, 13),
		]
		_surface(top, [0, 1, 2, 0, 2, 3, 0, 3, 4], green, side < 0, bank)
		var face: Array[Vector3] = [top[0], top[1], Vector3(side * 11.9, -6.8, -3), Vector3(side * 13, -7.5, 10), top[4]]
		_surface(face, [0, 1, 2, 0, 2, 3, 0, 3, 4], BlockoutGeometry.material(Color(0.48, 0.49, 0.43)), side > 0, bank)


func _surface(points: Array[Vector3], indices: Array, surface: StandardMaterial3D, reverse: bool, parent: Node3D) -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle in range(0, indices.size(), 3):
		var shade: float = 0.88 + (triangle % 4) * 0.035
		for vertex in range(3):
			builder.set_color(Color(shade, shade, shade))
			var offset: int = 2 - vertex if reverse else vertex
			builder.add_vertex(points[int(indices[triangle + offset])])
	builder.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = builder.commit()
	# Blockout planes should be visible from both sides while composition evolves.
	surface.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = surface
	parent.add_child(mesh)


func configure_slots(count: int) -> void:
	if count == slots.size(): return
	while slots.size() > count:
		var slot: BridgeSlot = slots.pop_back()
		_bridge.remove_child(slot)
		slot.queue_free()
	while slots.size() < count:
		var slot := BridgeSlot.new()
		slot.name = "Slot%d" % (slots.size() + 1)
		_bridge.add_child(slot)
		slot.build(slots.size(), materials)
		if column_art != null: slot.replace_column_art(column_art)
		slots.append(slot)
	var slot_height: float = foundation.position.y - BridgeSlot.FOOT_Y
	for index in range(count):
		slots[index].position = Vector3((index - (count - 1) * 0.5) * BridgeSlot.MODULE_WIDTH, slot_height, 0)
	for index in range(_bank_decks.size()):
		var side: float = -1.0 if index == 0 else 1.0
		_bank_decks[index].position.x = side * (count * BridgeSlot.MODULE_WIDTH * 0.5 + 1.5)
	for index in range(_terrain_banks.size()):
		_terrain_banks[index].position.x = (-1.0 if index == 0 else 1.0) * (count - 5) * BridgeSlot.MODULE_WIDTH * 0.5
	if fit_board_to_camera:
		camera.size = maxf(_authored_camera_size, count * BridgeSlot.MODULE_WIDTH + board_overscan)
	_frame_cards()
