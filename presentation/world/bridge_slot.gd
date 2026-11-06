class_name BridgeSlot
extends Area3D
## Logical-slot projection. Meshes can be replaced without changing game rules.

const FOOT_Y: float = -6.6
const DECK_TOP_Y: float = 0.35
const MODULE_WIDTH: float = 5.2

var slot_index: int
var occupied: bool = false
var flair_available: bool = false
var _column: Node3D
var _ghost: Node3D
var _outline: Node3D
var _number: Label3D
var _caption: Label3D


func build(index: int, materials: Dictionary) -> void:
	slot_index = index
	collision_layer = 1
	collision_mask = 0
	_collision(Vector3(4.8, 0.8, 2.5), Vector3.ZERO)
	_collision(Vector3(2.1, 6.4, 2.1), Vector3(0, -3.2, 0))
	_column = Node3D.new()
	_column.name = "Column"
	add_child(_column)
	BlockoutGeometry.box(_column, Vector3(1.65, 6.1, 1.8), Vector3(0, -3.25, 0), materials.stone)
	var base := BlockoutGeometry.box(_column, Vector3(2.15, 0.5, 2.25), Vector3(0, -6.35, 0), materials.stone)
	base.name = "Base"
	BlockoutGeometry.box(_column, Vector3(2.2, 0.38, 2.3), Vector3(0, -0.1, 0), materials.cap)
	var deck := BlockoutGeometry.box(_column, Vector3(MODULE_WIDTH, 0.22, 2.3), Vector3(0, 0.24, 0), materials.deck)
	deck.name = "Deck"
	for side: float in [-1.1, 1.1]:
		BlockoutGeometry.box(_column, Vector3(MODULE_WIDTH, 0.48, 0.18), Vector3(0, -0.38, side), materials.red)
		BlockoutGeometry.box(_column, Vector3(MODULE_WIDTH, 0.10, 0.10), Vector3(0, 0.97, side), materials.red)
		for x: float in [-2.3, 0, 2.3]:
			BlockoutGeometry.box(_column, Vector3(0.10, 0.85, 0.10), Vector3(x, 0.60, side), materials.red)
	_outline = Node3D.new()
	_outline.name = "Footprint"
	add_child(_outline)
	for side: float in [-1.13, 1.13]:
		BlockoutGeometry.box(_outline, Vector3(4.8, 0.045, 0.045), Vector3(0, 0.25, side), materials.outline)
	for x: float in [-2.4, 2.4]:
		BlockoutGeometry.box(_outline, Vector3(0.045, 0.045, 2.3), Vector3(x, 0.25, 0), materials.outline)
	_ghost = Node3D.new()
	_ghost.name = "Ghost"
	add_child(_ghost)
	for x: float in [-0.85, 0.85]:
		for z: float in [-0.95, 0.95]:
			BlockoutGeometry.box(_ghost, Vector3(0.035, 6.72, 0.035), Vector3(x, -3.24, z), materials.gold)
	for y: float in [-6.6, -3.0, 0.12]:
		for z: float in [-0.95, 0.95]:
			BlockoutGeometry.box(_ghost, Vector3(1.7, 0.035, 0.035), Vector3(0, y, z), materials.gold)
	_number = BlockoutGeometry.label(self, str(index + 1), Vector3(0, 2.2, 0), 64, 200, Color(1, 0.91, 0.63))
	_caption = BlockoutGeometry.label(self, "", Vector3(0, 1.3, 0), 28, 350, Color(1, 0.95, 0.80))
	for label: Label3D in [_number, _caption]:
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.outline_size = 8
		label.outline_modulate = Color(0.08, 0.12, 0.12)
	present(null, "", false)


func replace_column_art(scene: PackedScene) -> void:
	# Keep the animated root, picking, labels and rules projection intact.
	for child in _column.get_children():
		_column.remove_child(child)
		child.queue_free()
	_column.add_child(scene.instantiate())


func present(placed: PlacedConstruct, definition_name: String, usable_flair: bool) -> void:
	occupied = placed != null
	flair_available = usable_flair
	_column.visible = occupied and placed.card_id != "debris"
	_outline.visible = not occupied or placed.card_id == "debris"
	_ghost.visible = false
	if occupied:
		_caption.text = definition_name
	else:
		_caption.text = ""


func preview(gain: int, highlighted: bool) -> void:
	_ghost.visible = highlighted and not occupied
	if not occupied:
		_caption.text = "+%d INTEGRITY" % gain if gain >= 0 else ""
		_caption.modulate = Color(1, 0.87, 0.42) if highlighted else Color(1, 0.95, 0.80)


func show_placement(card: CardInstance, definition: Dictionary, gain: int) -> void:
	present(PlacedConstruct.new(card, int(definition.baseIntegrity), gain), definition.name, false)

func _collision(size: Vector3, center: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = center
	add_child(collider)
